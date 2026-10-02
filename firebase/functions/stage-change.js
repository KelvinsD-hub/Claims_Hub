/**
 * Applying a stage change to a lead or a claim.
 *
 * Separate from index.js so it can be run against the Firestore emulator
 * without loading every function. pipeline.js decides whether a move is
 * allowed; this writes it, with whatever has to happen alongside.
 */
const crypto = require('crypto');
const pipeline = require('./pipeline');
const { LEAD, CLAIM } = pipeline;

const SYSTEM_ACTOR = { uid: 'system', name: 'System' };

/** The fields that record a stage change, for either a lead or a claim. */
function stageStamp(admin, stage, actor, note, field = 'claim_status') {
  return {
    [field]: stage,
    stage_changed_at: admin.firestore.FieldValue.serverTimestamp(),
    stage_changed_by: actor.uid,
    stage_changed_by_name: actor.name,
    stage_note: note || '',
  };
}

/** A link token for the client's claim forms — 64 hex characters. */
function newSecureToken() {
  return crypto.randomBytes(32).toString('hex');
}

/**
 * Move one record. `staff` is { uid, name, role }.
 * Returns { from, to, claimId? }; throws pipeline.StageError when the move is
 * not allowed, with a message fit to show the person who asked.
 */
async function applyStageChange(admin, { kind, id, to, note, staff }) {
  const db = admin.firestore();
  const ref = db.doc(`${kind === 'lead' ? 'leads' : 'claims'}/${id}`);
  const field = kind === 'lead' ? 'status' : 'claim_status';

  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw new pipeline.StageError(404, `That ${kind} no longer exists.`);
    const data = snap.data();
    const move = pipeline.planMove({
      kind, current: data[field], to, role: staff.role, reason: note,
    });
    const update = stageStamp(admin, move.to, staff, note, field);
    const out = { from: move.from, to: move.to };

    if (kind === 'lead') {
      if (move.to === LEAD.CONTACTED) update.is_contacted = true;
      if (move.to === LEAD.REJECTED) {
        update.is_qualified = false;
        update.rejection_reason = note;
      }
      if (move.to === LEAD.QUALIFIED) {
        // Qualifying a lead opens its claim, in the same transaction, so there
        // is never a qualified lead without one, or two claims for one lead.
        if (data.claim_ref) {
          throw new pipeline.StageError(409, 'This lead already has a claim.');
        }
        const claimRef = db.collection('claims').doc();
        tx.set(claimRef, {
          lead_ref: ref,
          secure_token: newSecureToken(),
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          client_email: data.email || '',
          ...(data.full_name ? { full_name: data.full_name } : {}),
          ...(data.airline_name ? { airline_name: data.airline_name } : {}),
          ...stageStamp(admin, CLAIM.DETAILS_PENDING, staff, 'Opened from a qualified lead'),
        });
        update.is_qualified = true;
        update.claim_ref = claimRef;
        out.claimId = claimRef.id;
      }
    } else {
      // Kept in step with the stage for anything still reading them.
      update.is_escalated = move.to === CLAIM.WITH_SOLICITOR;
      if (move.to === CLAIM.DEMAND_PENDING && !data.airline_email_status) {
        update.airline_email_status = 'Pending';
      }
      if (pipeline.CLAIM_CLOSED.includes(move.to) && !pipeline.CLAIM_CLOSED.includes(move.from)) {
        update.closed_at = admin.firestore.FieldValue.serverTimestamp();
      }
    }

    tx.update(ref, update);
    return out;
  });
}

module.exports = { applyStageChange, stageStamp, newSecureToken, SYSTEM_ACTOR };
