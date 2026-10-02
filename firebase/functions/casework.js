/**
 * Casework: who owns a record, what has to happen to it next and by when,
 * and how far the legal team has taken an escalated claim.
 *
 * pipeline.js says which stage a record is in. This says what that stage asks
 * of the people working it. The app's copy
 * (lib/backend/services/casework.dart) reads the same names — change them
 * together.
 *
 * Pure: no Firebase imports, so it can be tested with plain node.
 */
const { LEAD, CLAIM, ROLE, StageError } = require('./pipeline');

const MANAGERS = [ROLE.MANAGER, ROLE.ADMIN, ROLE.SUPER_ADMIN];
/** Who may hold or work the legal side of a claim. */
const LEGAL_ROLES = [ROLE.SOLICITOR, ...MANAGERS];

// ── Deadlines ────────────────────────────────────────────────────────────────
// The two letter periods are the ones the letters themselves give the airline
// (see the demand letter and the final legal notice in index.js). Change a
// number here and in the letter together.
const DAYS = {
  CONTACT_NEW_LEAD: 1,
  DECIDE_ON_LEAD: 3,
  CHASE_EVIDENCE: 3,
  CHASE_SIGNATURE: 2,
  START_REVIEW: 1,
  FINISH_REVIEW: 2,
  SEND_DEMAND: 1,
  AIRLINE_REPLY: 14,   // demand letter: "within FOURTEEN (14) DAYS"
  LEGAL_REVIEW: 2,
  FINAL_NOTICE: 7,     // final legal notice: "within SEVEN (7) DAYS"
  NCAA_CHECK: 14,
  COURT_UPDATE: 30,
  PAY_CLIENT: 7,
};

// ── Legal stages ─────────────────────────────────────────────────────────────
// Where an escalated claim (stage "With Solicitor") has got to. The order is
// the usual route; a lawyer may move between any of them.

const LEGAL = {
  REVIEW: 'Legal review',               // escalated; a lawyer is reading the file
  NOTICE_SENT: 'Final notice sent',     // the final legal notice has gone to the airline
  NCAA: 'NCAA complaint filed',         // complaint lodged with the NCAA consumer protection directorate
  COURT: 'Court proceedings',           // a case-by-case decision, never the automatic next step
};
const LEGAL_ORDER = [LEGAL.REVIEW, LEGAL.NOTICE_SENT, LEGAL.NCAA, LEGAL.COURT];

/**
 * What a record at this stage is waiting for: { text, days }, or null when
 * nothing is left to do. `legalStage` matters only for "With Solicitor".
 */
function nextActionFor(kind, stage, legalStage) {
  if (kind === 'lead') {
    switch (stage) {
      case LEAD.NEW: return { text: 'Contact the lead', days: DAYS.CONTACT_NEW_LEAD };
      case LEAD.CONTACTED: return { text: 'Decide: qualify or reject', days: DAYS.DECIDE_ON_LEAD };
      default: return null;
    }
  }
  switch (stage) {
    case CLAIM.DETAILS_PENDING: return { text: 'Chase the client for evidence', days: DAYS.CHASE_EVIDENCE };
    case CLAIM.TERMS_PENDING: return { text: 'Chase the client to sign', days: DAYS.CHASE_SIGNATURE };
    case CLAIM.READY_FOR_REVIEW: return { text: 'Start the review', days: DAYS.START_REVIEW };
    case CLAIM.UNDER_REVIEW: return { text: 'Finish the review', days: DAYS.FINISH_REVIEW };
    case CLAIM.DEMAND_PENDING: return { text: 'Send the demand letter', days: DAYS.SEND_DEMAND };
    case CLAIM.AWAITING_REPLY: return { text: 'Airline reply due — record it or escalate', days: DAYS.AIRLINE_REPLY };
    case CLAIM.WITH_SOLICITOR:
      switch (legalStage) {
        case LEGAL.NOTICE_SENT: return { text: 'Final notice period ends — record payment or escalate', days: DAYS.FINAL_NOTICE };
        case LEGAL.NCAA: return { text: 'Check on the NCAA complaint', days: DAYS.NCAA_CHECK };
        case LEGAL.COURT: return { text: 'Update on the proceedings', days: DAYS.COURT_UPDATE };
        default: return { text: 'Review the file and send the final notice', days: DAYS.LEGAL_REVIEW };
      }
    case CLAIM.WON: return { text: 'Pay the client their share', days: DAYS.PAY_CLIENT };
    default: return null;
  }
}

/** The end of the day (Lagos time, UTC+1) `days` from `now`. */
function dueIn(days, now = new Date()) {
  const lagos = new Date(now.getTime() + 60 * 60 * 1000);
  return new Date(Date.UTC(
    lagos.getUTCFullYear(), lagos.getUTCMonth(), lagos.getUTCDate() + days, 22, 59, 59));
}

/** The end of the day (Lagos time) named by a "YYYY-MM-DD" string, or null. */
function dueOn(dateString) {
  const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(String(dateString || ''));
  if (!m) return null;
  const due = new Date(Date.UTC(+m[1], +m[2] - 1, +m[3], 22, 59, 59));
  return due.getUTCMonth() === +m[2] - 1 ? due : null;
}

// ── Ownership ────────────────────────────────────────────────────────────────

const SLOT = { HANDLER: 'handler', LAWYER: 'lawyer' };

/**
 * Decide an assignment. `staff` is who is asking; `toUser` is the users
 * document of the person being given the record (null to unassign).
 *
 * Anyone may take an unassigned record or hand back their own. Giving a
 * record to someone else, or taking it off someone, needs a Manager or above.
 * The lawyer on a claim has to be on the legal team.
 */
function planAssignment({ kind, slot, currentUid, toUid, toUser, staff }) {
  if (slot !== SLOT.HANDLER && slot !== SLOT.LAWYER) throw new StageError(400, 'Unknown assignment.');
  if (slot === SLOT.LAWYER && kind !== 'claim') throw new StageError(400, 'Only a claim has a lawyer.');
  const current = currentUid || '';
  const to = toUid || '';
  if (current === to) {
    throw new StageError(409, to ? 'It is already assigned to that person.' : 'It is already unassigned.');
  }

  const manager = MANAGERS.includes(staff.role);
  const takingFree = to === staff.uid && !current;
  const handingBack = !to && current === staff.uid;
  if (!takingFree && !handingBack && !manager) {
    throw new StageError(403, current && to === staff.uid
      ? 'This is already assigned to someone else. A Manager or above can reassign it.'
      : 'Assigning work to someone else needs a Manager or above.');
  }

  if (to) {
    if (!toUser || toUser.approved !== true) {
      throw new StageError(400, 'That person is not an approved member of staff.');
    }
    if (slot === SLOT.LAWYER && !LEGAL_ROLES.includes(toUser.role)) {
      throw new StageError(400, 'The lawyer on a claim has to be a Solicitor, or a Manager or above.');
    }
  }
  return { from: current, to };
}

/** Decide a move between legal stages. Returns { from, to }. */
function planLegalStage({ claimStage, current, to, role, note }) {
  if (!LEGAL_ROLES.includes(role)) {
    throw new StageError(403, 'Only the legal team, or a Manager or above, can change the legal stage.');
  }
  if (claimStage !== CLAIM.WITH_SOLICITOR) {
    throw new StageError(409, 'Only a claim that is with the legal team has a legal stage.');
  }
  if (!LEGAL_ORDER.includes(to)) throw new StageError(400, `"${to}" is not a legal stage.`);
  const from = LEGAL_ORDER.includes(current) ? current : LEGAL.REVIEW;
  if (from === to) throw new StageError(409, `This claim is already at "${to}".`);
  // Going to court is decided claim by claim, so it is never recorded silently.
  if (to === LEGAL.COURT && !String(note || '').trim()) {
    throw new StageError(400, 'Record why this claim is going to court.');
  }
  return { from, to };
}

module.exports = {
  DAYS, LEGAL, LEGAL_ORDER, LEGAL_ROLES, MANAGERS, SLOT,
  nextActionFor, dueIn, dueOn, planAssignment, planLegalStage,
};
