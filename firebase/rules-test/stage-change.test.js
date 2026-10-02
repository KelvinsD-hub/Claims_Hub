/**
 * Stage changes written to the database.
 *
 *   cd firebase
 *   firebase emulators:exec --only firestore --project demo-claims-hub "node rules-test/stage-change.test.js"
 *
 * Runs functions/stage-change.js against the Firestore emulator with the Admin
 * SDK, the way the changeStage function does.
 */
if (!process.env.FIRESTORE_EMULATOR_HOST) {
  console.error('Refusing to run: FIRESTORE_EMULATOR_HOST is not set. Use firebase emulators:exec.');
  process.exit(1);
}
const admin = require('../functions/node_modules/firebase-admin');
const { applyStageChange } = require('../functions/stage-change');
const { LEAD, CLAIM, StageError } = require('../functions/pipeline');

admin.initializeApp({ projectId: 'demo-claims-hub' });
const db = admin.firestore();

let passed = 0;
let failed = 0;
function check(name, ok) {
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}`);
  ok ? passed++ : failed++;
}
async function refused(promise) {
  try { await promise; return null; } catch (e) { return e instanceof StageError ? e : null; }
}

const agent = { uid: 'agent1', name: 'Ada Agent', role: 'Agent' };
const boss = { uid: 'boss1', name: 'Bola Boss', role: 'Super Admin' };

(async () => {
  // ── A lead, start to finish ────────────────────────────────────────────────
  await db.doc('leads/L1').set({ full_name: 'Tunde Client', email: 't@example.com', airline_name: 'Air Peace', status: 'New lead', is_qualified: false });

  let r = await applyStageChange(admin, { kind: 'lead', id: 'L1', to: LEAD.CONTACTED, note: 'Called, will send booking ref', staff: agent });
  let lead = (await db.doc('leads/L1').get()).data();
  check('contacting a lead sets the stage', lead.status === LEAD.CONTACTED && r.from === LEAD.NEW);
  check('contacting a lead ticks is_contacted', lead.is_contacted === true);
  check('the change records who made it', lead.stage_changed_by === 'agent1' && lead.stage_changed_by_name === 'Ada Agent');
  check('the change records when', !!lead.stage_changed_at);
  check('the change keeps the note', lead.stage_note === 'Called, will send booking ref');

  r = await applyStageChange(admin, { kind: 'lead', id: 'L1', to: LEAD.QUALIFIED, note: '', staff: agent });
  lead = (await db.doc('leads/L1').get()).data();
  check('qualifying a lead returns the new claim id', typeof r.claimId === 'string' && r.claimId.length > 5);
  check('the lead points at its claim', lead.claim_ref && lead.claim_ref.id === r.claimId && lead.is_qualified === true);
  const claim = (await db.doc(`claims/${r.claimId}`).get()).data();
  check('the claim starts at Details Pending', claim.claim_status === CLAIM.DETAILS_PENDING);
  check('the claim points back at the lead', claim.lead_ref.path === 'leads/L1');
  check('the claim has a client link token', typeof claim.secure_token === 'string' && claim.secure_token.length === 64);
  check('the claim carries the client email and name', claim.client_email === 't@example.com' && claim.full_name === 'Tunde Client');
  check('the claim records who opened it', claim.stage_changed_by === 'agent1');

  const again = await refused(applyStageChange(admin, { kind: 'lead', id: 'L1', to: LEAD.QUALIFIED, note: '', staff: agent }));
  check('a lead cannot be qualified twice', !!again);
  const claimCount = (await db.collection('claims').where('lead_ref', '==', db.doc('leads/L1')).get()).size;
  check('and no second claim was created', claimCount === 1);

  // ── Rejection ──────────────────────────────────────────────────────────────
  await db.doc('leads/L2').set({ full_name: 'No Claim', status: 'New lead' });
  check('rejecting without a reason is refused', !!(await refused(applyStageChange(admin, { kind: 'lead', id: 'L2', to: LEAD.REJECTED, note: '', staff: agent }))));
  await applyStageChange(admin, { kind: 'lead', id: 'L2', to: LEAD.REJECTED, note: 'Flight did not touch Nigeria', staff: agent });
  const rejected = (await db.doc('leads/L2').get()).data();
  check('a rejected lead keeps its reason', rejected.status === LEAD.REJECTED && rejected.rejection_reason === 'Flight did not touch Nigeria');
  check('rejecting creates no claim', !rejected.claim_ref);

  // ── A lead that already has a claim (old data) ─────────────────────────────
  await db.doc('leads/L3').set({ full_name: 'Old Data', status: 'New lead', claim_ref: db.doc('claims/existing') });
  check('a lead that already has a claim is not given another', !!(await refused(applyStageChange(admin, { kind: 'lead', id: 'L3', to: LEAD.QUALIFIED, note: '', staff: agent }))));

  // ── A claim through the pipeline ───────────────────────────────────────────
  const id = r.claimId;
  const step = (to, staff = agent, note = '') => applyStageChange(admin, { kind: 'claim', id, to, note, staff });
  await step(CLAIM.READY_FOR_REVIEW);
  await step(CLAIM.UNDER_REVIEW);
  await step(CLAIM.DEMAND_PENDING);
  let c = (await db.doc(`claims/${id}`).get()).data();
  check('approving for demand marks the airline email pending', c.airline_email_status === 'Pending');
  check('a claim not with the solicitor is not flagged escalated', c.is_escalated === false);
  await step(CLAIM.AWAITING_REPLY);
  await step(CLAIM.WITH_SOLICITOR);
  c = (await db.doc(`claims/${id}`).get()).data();
  check('escalating flags the claim for the legal team', c.claim_status === CLAIM.WITH_SOLICITOR && c.is_escalated === true);
  check('an open claim has no closed date', c.closed_at === undefined);
  await step(CLAIM.WON);
  c = (await db.doc(`claims/${id}`).get()).data();
  check('winning closes the claim and clears the flag', c.claim_status === CLAIM.WON && c.is_escalated === false && !!c.closed_at);
  check('an agent cannot mark it paid', !!(await refused(step(CLAIM.PAID))));
  await step(CLAIM.PAID, boss);
  c = (await db.doc(`claims/${id}`).get()).data();
  check('a super admin can mark it paid', c.claim_status === CLAIM.PAID && c.stage_changed_by === 'boss1');

  // ── Refusals leave the record untouched ────────────────────────────────────
  await db.doc('claims/C2').set({ claim_status: CLAIM.DETAILS_PENDING, full_name: 'Untouched' });
  const jump = await refused(applyStageChange(admin, { kind: 'claim', id: 'C2', to: CLAIM.WON, note: '', staff: boss }));
  const c2 = (await db.doc('claims/C2').get()).data();
  check('an impossible jump is refused even for a super admin', !!jump && jump.status === 409);
  check('and nothing was written', c2.claim_status === CLAIM.DETAILS_PENDING && c2.stage_changed_by === undefined);
  const missing = await refused(applyStageChange(admin, { kind: 'claim', id: 'nope', to: CLAIM.WON, note: '', staff: boss }));
  check('a missing record is reported as such', !!missing && missing.status === 404);

  // ── Records still carrying an old stage name ───────────────────────────────
  await db.doc('claims/C3').set({ claim_status: 'Submit to Solicitor', airline_email_status: 'Awaiting reply' });
  await applyStageChange(admin, { kind: 'claim', id: 'C3', to: CLAIM.AWAITING_REPLY, note: '', staff: agent });
  check('a claim with an old stage name can still be moved', (await db.doc('claims/C3').get()).data().claim_status === CLAIM.AWAITING_REPLY);

  console.log(`\n${passed} passed, ${failed} failed`);
  process.exit(failed ? 1 : 0);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
