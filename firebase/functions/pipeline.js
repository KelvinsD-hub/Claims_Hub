/**
 * The pipeline: every stage a lead or a claim can be in, and which moves
 * between them are allowed.
 *
 * This is the single definition. The app's copy
 * (lib/backend/services/pipeline.dart) and the website tracker read the same
 * names — change them together, never one alone. Stage changes by staff go
 * through the changeStage function, which is the only thing that applies this
 * table; the database rules stop the app writing a stage directly.
 *
 * Pure: no Firebase imports, so it can be tested with plain node.
 */

// ── Leads ────────────────────────────────────────────────────────────────────

const LEAD = {
  NEW: 'New lead',
  CONTACTED: 'Contacted',
  QUALIFIED: 'Qualified',
  REJECTED: 'Rejected',
};

/** Values written by earlier versions of the app, and what they meant. */
const LEAD_LEGACY = {
  'Under Review': LEAD.CONTACTED,
  'Not Qualified': LEAD.REJECTED,
  'Converted to Claim': LEAD.QUALIFIED,
};

// ── Claims ───────────────────────────────────────────────────────────────────

const CLAIM = {
  DETAILS_PENDING: 'Details Pending',   // waiting for the client's evidence
  TERMS_PENDING: 'Terms Pending',       // evidence in; client still to sign
  READY_FOR_REVIEW: 'Ready For Review', // client has finished; nobody has picked it up
  UNDER_REVIEW: 'Under Review',         // staff are checking it
  DEMAND_PENDING: 'Demand Pending',     // approved; the letter to the airline has not gone
  AWAITING_REPLY: 'Awaiting Reply',     // the airline has our demand
  WITH_SOLICITOR: 'With Solicitor',     // escalated to the legal team
  WON: 'Won',
  LOST: 'Lost',
  WITHDRAWN: 'Withdrawn',               // closed without an outcome: cancelled or not pursued
  PAID: 'Paid',                         // the client has been paid out
};

const CLAIM_LEGACY = {
  'Submit to Solicitor': CLAIM.DEMAND_PENDING,
  'Submitted to Solicitors': CLAIM.DEMAND_PENDING,
  'Submitted': CLAIM.READY_FOR_REVIEW,
  'Claim Won': CLAIM.WON,
  'Claim Lost': CLAIM.LOST,
};

/** Stages a claim can sit in with nothing left to do. */
const CLAIM_CLOSED = [CLAIM.WON, CLAIM.LOST, CLAIM.WITHDRAWN, CLAIM.PAID];

const ROLE = {
  AGENT: 'Agent',
  SOLICITOR: 'Solicitor',
  MANAGER: 'Manager',
  ADMIN: 'Admin',
  SUPER_ADMIN: 'Super Admin',
};
const MANAGERS = [ROLE.MANAGER, ROLE.ADMIN, ROLE.SUPER_ADMIN];

/**
 * Allowed moves. `to: [...]` is open to any approved staff member;
 * `managerOnly: [...]` reopens something that was closed, or records money
 * leaving, and needs a Manager or above.
 */
const LEAD_MOVES = {
  [LEAD.NEW]: { to: [LEAD.CONTACTED, LEAD.QUALIFIED, LEAD.REJECTED] },
  [LEAD.CONTACTED]: { to: [LEAD.QUALIFIED, LEAD.REJECTED] },
  // A qualified lead has a claim; what happens next happens to the claim.
  [LEAD.QUALIFIED]: { to: [] },
  [LEAD.REJECTED]: { to: [], managerOnly: [LEAD.NEW] },
};

const CLAIM_MOVES = {
  [CLAIM.DETAILS_PENDING]: { to: [CLAIM.TERMS_PENDING, CLAIM.READY_FOR_REVIEW, CLAIM.WITHDRAWN] },
  [CLAIM.TERMS_PENDING]: { to: [CLAIM.DETAILS_PENDING, CLAIM.READY_FOR_REVIEW, CLAIM.WITHDRAWN] },
  [CLAIM.READY_FOR_REVIEW]: { to: [CLAIM.UNDER_REVIEW, CLAIM.DEMAND_PENDING, CLAIM.DETAILS_PENDING, CLAIM.WITHDRAWN] },
  [CLAIM.UNDER_REVIEW]: { to: [CLAIM.DEMAND_PENDING, CLAIM.DETAILS_PENDING, CLAIM.WITHDRAWN] },
  [CLAIM.DEMAND_PENDING]: { to: [CLAIM.AWAITING_REPLY, CLAIM.UNDER_REVIEW, CLAIM.WITHDRAWN] },
  [CLAIM.AWAITING_REPLY]: { to: [CLAIM.WON, CLAIM.LOST, CLAIM.WITH_SOLICITOR, CLAIM.WITHDRAWN] },
  [CLAIM.WITH_SOLICITOR]: { to: [CLAIM.WON, CLAIM.LOST, CLAIM.AWAITING_REPLY, CLAIM.WITHDRAWN] },
  [CLAIM.WON]: { to: [], managerOnly: [CLAIM.PAID, CLAIM.AWAITING_REPLY] },
  [CLAIM.LOST]: { to: [CLAIM.WITH_SOLICITOR], managerOnly: [CLAIM.AWAITING_REPLY] },
  [CLAIM.WITHDRAWN]: { to: [], managerOnly: [CLAIM.UNDER_REVIEW] },
  [CLAIM.PAID]: { to: [], managerOnly: [CLAIM.WON] },
};

/** The stage as the table knows it, whatever an older record calls it. */
function canonical(kind, stage) {
  const legacy = kind === 'lead' ? LEAD_LEGACY : CLAIM_LEGACY;
  const value = String(stage == null ? '' : stage).trim();
  if (legacy[value]) return legacy[value];
  if (!value) return kind === 'lead' ? LEAD.NEW : CLAIM.DETAILS_PENDING;
  return value;
}

/** Every stage `role` may move a record to from `stage`. */
function allowedMoves(kind, stage, role) {
  const moves = (kind === 'lead' ? LEAD_MOVES : CLAIM_MOVES)[canonical(kind, stage)];
  if (!moves) return [];
  return MANAGERS.includes(role) ? [...moves.to, ...(moves.managerOnly || [])] : [...moves.to];
}

class StageError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

/**
 * Decide a move. Returns { from, to } or throws a StageError explaining why
 * not, in words fit to show the person who asked.
 */
function planMove({ kind, current, to, role, reason }) {
  if (kind !== 'lead' && kind !== 'claim') throw new StageError(400, 'Unknown record type.');
  const known = Object.values(kind === 'lead' ? LEAD : CLAIM);
  if (!known.includes(to)) throw new StageError(400, `"${to}" is not a stage.`);

  const from = canonical(kind, current);
  if (from === to) throw new StageError(409, `This ${kind} is already at "${to}".`);

  const table = (kind === 'lead' ? LEAD_MOVES : CLAIM_MOVES)[from];
  if (!table) {
    throw new StageError(409, `This ${kind} is at "${current}", which is not a stage this system knows. Ask an admin to correct it.`);
  }
  if (!table.to.includes(to)) {
    if ((table.managerOnly || []).includes(to)) {
      if (!MANAGERS.includes(role)) {
        throw new StageError(403, `Moving a ${kind} from "${from}" to "${to}" needs a Manager or above.`);
      }
    } else {
      const options = allowedMoves(kind, from, role);
      throw new StageError(409,
        `A ${kind} cannot go from "${from}" to "${to}".` +
        (options.length ? ` From here it can go to: ${options.join(', ')}.` : ' It is closed.'));
    }
  }

  // Closing something without an outcome is the move most worth explaining
  // later, so it is the one that cannot be made silently.
  const needsReason = to === LEAD.REJECTED || to === CLAIM.WITHDRAWN;
  if (needsReason && !String(reason || '').trim()) {
    throw new StageError(400, `Give a reason for moving this ${kind} to "${to}".`);
  }
  return { from, to };
}

module.exports = {
  LEAD, CLAIM, ROLE, LEAD_LEGACY, CLAIM_LEGACY, CLAIM_CLOSED, LEAD_MOVES, CLAIM_MOVES,
  canonical, allowedMoves, planMove, StageError,
};
