/**
 * Sending the demand letter to the airline.
 *
 * The letter itself is built and emailed by onTriggerAirlineEmail (index.js),
 * which fires when a claim's `trigger_airline_email` turns true. This decides
 * whether that may happen: who is asking, whether the claim is at the right
 * stage, whether the file has what the letter states, and where it is going.
 * The database rules refuse the trigger written any other way, so a letter
 * cannot leave with "N/A" for the flight because someone pressed Send early.
 *
 * `demandReadiness` is pure; `requestDemandLetter` writes, and is run against
 * the Firestore emulator in rules-test/demand.test.js.
 */
const pipeline = require('./pipeline');
const { CLAIM, StageError } = pipeline;

const EMAIL = /^[^\s@,;<>]+@[^\s@,;<>]+\.[^\s@,;<>]{2,}$/;

const text = (v) => (v === undefined || v === null ? '' : String(v).trim());

/**
 * What stands between a claim and its demand letter.
 *
 *   blockers — the letter states these as fact, or cannot lawfully go without
 *              them. Sending is refused.
 *   warnings — the letter is weaker without them. Staff are told; it can go.
 *
 * lib/backend/services/demand.dart shows the same lists before staff press
 * Send; this copy is the one that is enforced.
 */
function demandReadiness(claim) {
  const blockers = [];
  const warnings = [];
  if (!text(claim.full_name)) blockers.push('The passenger\'s name is missing.');
  if (!text(claim.airline_name)) blockers.push('The airline is missing.');
  if (!text(claim.flight_number)) blockers.push('The flight number is missing.');
  if (!text(claim.flight_date)) blockers.push('The flight date is missing.');
  if (!text(claim.departure) || !text(claim.destination)) blockers.push('The route is missing.');
  if (!text(claim.signature)) blockers.push('The client has not signed the letter of authority.');
  if (!text(claim.claims_amount)) warnings.push('No amount is set: the letter will ask for "the applicable statutory amount".');
  if (!text(claim.pnr_number)) warnings.push('No booking reference.');
  if (!text(claim.duration_of_delay) && !text(claim.claims_reason)) warnings.push('Nothing says what went wrong with the flight.');
  return { blockers, warnings };
}

/** When work on this claim may start, if the client can still cancel. */
function heldUntil(claim, now = new Date()) {
  if (claim.start_immediately === true) return null;
  const at = claim.work_may_start_at;
  const date = at && typeof at.toDate === 'function' ? at.toDate() : (at instanceof Date ? at : null);
  return date && date.getTime() > now.getTime() ? date : null;
}

/**
 * Ask for the demand letter on claim `id` to go to `email`. `staff` is
 * { uid, name, role }. Sets the trigger the sending function watches, and
 * records who asked. Returns { email, resend }.
 */
async function requestDemandLetter(admin, { id, email, staff }) {
  const db = admin.firestore();
  const ref = db.doc(`claims/${id}`);
  const to = text(email).toLowerCase();
  if (!EMAIL.test(to)) throw new StageError(400, 'Choose the airline\'s email address first.');

  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw new StageError(404, 'That claim no longer exists.');
    const claim = snap.data();
    const stage = pipeline.canonical('claim', claim.claim_status);
    if (stage !== CLAIM.DEMAND_PENDING && stage !== CLAIM.AWAITING_REPLY) {
      throw new StageError(409, `A demand letter goes out at "${CLAIM.DEMAND_PENDING}". This claim is at "${stage}".`);
    }
    if (claim.trigger_airline_email === true) {
      throw new StageError(409, 'This letter is already being sent.');
    }
    const held = heldUntil(claim);
    if (held) {
      throw new StageError(409, `Not sent. This client can still cancel until ${held.toISOString().slice(0, 10)} and did not ask us to start before then.`);
    }
    const { blockers } = demandReadiness(claim);
    if (blockers.length) {
      throw new StageError(400, `The letter cannot go yet. ${blockers.join(' ')}`);
    }

    const resend = stage === CLAIM.AWAITING_REPLY;
    const who = claim.full_name || claim.client_email || 'this claim';
    tx.update(ref, {
      airline_email_selection: to,
      trigger_airline_email: true,
      letter_requested_by: staff.uid,
      letter_requested_by_name: staff.name,
    });
    tx.set(db.collection('activity_logs').doc(), {
      entityType: 'Claim',
      claims: ref,
      ...(claim.lead_ref ? { leadRef: claim.lead_ref } : {}),
      action: resend ? 'Demand letter resent' : 'Demand letter sent',
      description: `${who}: demand letter ${resend ? 're' : ''}sent to ${claim.airline_name} at ${to}`,
      performedBy: db.doc(`users/${staff.uid}`),
      performedByName: staff.name,
      actor_type: 'staff',
      sent_to: to,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return { email: to, resend };
  });
}

module.exports = { demandReadiness, heldUntil, requestDemandLetter, EMAIL };
