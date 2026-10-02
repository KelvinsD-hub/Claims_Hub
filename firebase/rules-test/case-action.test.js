/**
 * Casework written to the database.
 *
 *   cd firebase
 *   firebase emulators:exec --only firestore --project demo-claims-hub "node rules-test/case-action.test.js"
 *
 * Runs functions/case-action.js and functions/stage-change.js against the
 * Firestore emulator with the Admin SDK, the way the caseAction and
 * changeStage functions do.
 */
if (!process.env.FIRESTORE_EMULATOR_HOST) {
  console.error('Refusing to run: FIRESTORE_EMULATOR_HOST is not set. Use firebase emulators:exec.');
  process.exit(1);
}
const admin = require('../functions/node_modules/firebase-admin');
const { applyCaseAction } = require('../functions/case-action');
const { applyStageChange } = require('../functions/stage-change');
const { LEAD, CLAIM, StageError } = require('../functions/pipeline');
const { LEGAL } = require('../functions/casework');

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
const get = async (path) => (await db.doc(path).get()).data();
const logs = async (action) => (await db.collection('activity_logs').where('action', '==', action).get()).docs.map((d) => d.data());
const daysAway = (ts) => Math.round((ts.toDate().getTime() - Date.now()) / 86400000);

const ada = { uid: 'ada', name: 'Ada Agent', role: 'Agent' };
const ben = { uid: 'ben', name: 'Ben Agent', role: 'Agent' };
const sola = { uid: 'sola', name: 'Sola Solicitor', role: 'Solicitor' };
const boss = { uid: 'boss', name: 'Bola Boss', role: 'Manager' };

(async () => {
  await db.doc('users/ada').set({ display_name: 'Ada Agent', approved: true, role: 'Agent' });
  await db.doc('users/ben').set({ display_name: 'Ben Agent', approved: true, role: 'Agent' });
  await db.doc('users/sola').set({ display_name: 'Sola Solicitor', approved: true, role: 'Solicitor' });
  await db.doc('users/boss').set({ display_name: 'Bola Boss', approved: true, role: 'Manager' });
  await db.doc('users/ghost').set({ display_name: 'Not Approved', approved: false, role: 'Agent' });

  // ── Taking and assigning a lead ────────────────────────────────────────────
  await db.doc('leads/L1').set({ full_name: 'Tunde Client', email: 't@example.com', status: LEAD.NEW });
  const assign = (staff, to, extra = {}) => applyCaseAction(admin, { action: 'assign', kind: 'lead', id: 'L1', slot: 'handler', to, staff, ...extra });

  await assign(ada, 'ada');
  let lead = await get('leads/L1');
  check('an agent can take an unassigned lead', lead.handler_uid === 'ada' && lead.handler_name === 'Ada Agent');
  check('the assignment records who made it and when', lead.handler_assigned_by === 'ada' && !!lead.handler_assigned_at);
  check('another agent cannot take it off them', (await refused(assign(ben, 'ben')))?.status === 403);
  check('an agent cannot give it to someone else', (await refused(assign(ada, 'ben')))?.status === 403);
  await assign(boss, 'ben');
  lead = await get('leads/L1');
  check('a manager can reassign it', lead.handler_uid === 'ben' && lead.handler_assigned_by === 'boss');
  check('nobody can assign to an unapproved account', (await refused(assign(boss, 'ghost')))?.status === 400);
  check('nobody can assign to an account that does not exist', (await refused(assign(boss, 'nobody')))?.status === 400);
  await assign(ben, '');
  lead = await get('leads/L1');
  check('the owner can hand it back to the queue', lead.handler_uid === undefined && lead.handler_name === undefined);
  check('every assignment is in the event log', (await logs('Assigned')).length === 2 && (await logs('Unassigned')).length === 1);
  const entry = (await logs('Assigned')).find((l) => l.assigned_to === 'ben');
  check('the log entry names the actor and the record', entry.performedByName === 'Bola Boss' && entry.leadRef.path === 'leads/L1' && entry.actor_type === 'staff');
  check('a refused assignment writes no log entry', (await logs('Assigned')).length === 2);

  // ── Whoever works an unowned record takes it ───────────────────────────────
  await applyStageChange(admin, { kind: 'lead', id: 'L1', to: LEAD.CONTACTED, note: '', staff: ada });
  lead = await get('leads/L1');
  check('contacting an unassigned lead makes you its handler', lead.handler_uid === 'ada');
  check('a contacted lead is due a decision in 3 days', lead.next_action === 'Decide: qualify or reject' && daysAway(lead.next_action_due) >= 2 && daysAway(lead.next_action_due) <= 4);
  await db.doc('leads/L9').set({ full_name: 'Owned Lead', status: LEAD.NEW, handler_uid: 'ben', handler_name: 'Ben Agent' });
  await applyStageChange(admin, { kind: 'lead', id: 'L9', to: LEAD.CONTACTED, note: '', staff: ada });
  check('working someone else\'s lead does not take it from them', (await get('leads/L9')).handler_uid === 'ben');

  // ── Qualifying carries the handler to the claim ────────────────────────────
  const q = await applyStageChange(admin, { kind: 'lead', id: 'L9', to: LEAD.QUALIFIED, note: '', staff: ada });
  let claim = await get(`claims/${q.claimId}`);
  check('the claim stays with the lead\'s handler', claim.handler_uid === 'ben' && claim.handler_name === 'Ben Agent');
  check('a new claim is due an evidence chase', claim.next_action === 'Chase the client for evidence' && !!claim.next_action_due);
  check('a qualified lead has no next action left', (await get('leads/L9')).next_action === undefined);

  // ── Next action ────────────────────────────────────────────────────────────
  const C = q.claimId;
  await applyCaseAction(admin, { action: 'next_action', kind: 'claim', id: C, text: 'Call client about boarding pass', due: '2026-12-01', staff: ada });
  claim = await get(`claims/${C}`);
  check('anyone on staff can set the next action', claim.next_action === 'Call client about boarding pass' && claim.next_action_set_by === 'ada');
  check('the due date is the end of that day in Lagos', claim.next_action_due.toDate().toISOString() === '2026-12-01T22:59:59.000Z');
  check('a next action needs a date', (await refused(applyCaseAction(admin, { action: 'next_action', kind: 'claim', id: C, text: 'Something', due: '', staff: ada })))?.status === 400);
  await applyStageChange(admin, { kind: 'claim', id: C, to: CLAIM.READY_FOR_REVIEW, note: '', staff: ada });
  claim = await get(`claims/${C}`);
  check('a stage change replaces the next action', claim.next_action === 'Start the review' && claim.next_action_set_by === 'system');
  await applyCaseAction(admin, { action: 'next_action', kind: 'claim', id: C, text: '', staff: ada });
  check('an empty next action clears it', (await get(`claims/${C}`)).next_action === undefined);

  // ── Escalation and the legal stages ────────────────────────────────────────
  const step = (to, staff = ada, extra = {}) => applyStageChange(admin, { kind: 'claim', id: C, to, note: '', staff, ...extra });
  const legal = (to, staff = sola, note = '') => applyCaseAction(admin, { action: 'legal_stage', id: C, to, note, staff });
  await step(CLAIM.DEMAND_PENDING);
  await step(CLAIM.AWAITING_REPLY);
  claim = await get(`claims/${C}`);
  check('a claim with the airline is due in 14 days', daysAway(claim.next_action_due) >= 13 && daysAway(claim.next_action_due) <= 15);
  check('a claim not yet escalated has no legal stage to change', (await refused(legal(LEGAL.NCAA)))?.status === 409);
  await step(CLAIM.WITH_SOLICITOR);
  claim = await get(`claims/${C}`);
  check('escalating starts at legal review', claim.legal_stage === LEGAL.REVIEW && !!claim.escalated_at);
  check('an agent escalating does not become the lawyer', claim.lawyer_uid === undefined);
  check('the legal team is due to review within 2 days', /final notice/.test(claim.next_action) && daysAway(claim.next_action_due) <= 3);

  check('an agent cannot take a claim as its lawyer', (await refused(applyCaseAction(admin, { action: 'assign', kind: 'claim', id: C, slot: 'lawyer', to: 'ada', staff: ada })))?.status === 400);
  await applyCaseAction(admin, { action: 'assign', kind: 'claim', id: C, slot: 'lawyer', to: 'sola', staff: sola });
  claim = await get(`claims/${C}`);
  check('a solicitor can take it from the legal queue', claim.lawyer_uid === 'sola' && claim.handler_uid === 'ben');

  check('an agent cannot change the legal stage', (await refused(legal(LEGAL.NCAA, ada)))?.status === 403);
  await legal(LEGAL.NOTICE_SENT);
  claim = await get(`claims/${C}`);
  check('the final notice starts a 7 day clock', claim.legal_stage === LEGAL.NOTICE_SENT && daysAway(claim.next_action_due) >= 6 && daysAway(claim.next_action_due) <= 8);
  await legal(LEGAL.NCAA);
  check('going to court without a reason is refused', (await refused(legal(LEGAL.COURT)))?.status === 400);
  await legal(LEGAL.COURT, sola, 'NCAA directive ignored; client instructs us to sue');
  claim = await get(`claims/${C}`);
  check('going to court with a reason is recorded', claim.legal_stage === LEGAL.COURT && claim.legal_stage_changed_by === 'sola');
  const legalLogs = await logs('Legal stage changed');
  check('each legal move is in the event log', legalLogs.length === 3 && legalLogs.some((l) => l.to_legal_stage === LEGAL.COURT && /instructs us to sue/.test(l.note)));

  // ── The case file ──────────────────────────────────────────────────────────
  const note = (staff, extra) => applyCaseAction(admin, { action: 'note', kind: 'claim', id: C, staff, ...extra });
  await note(sola, { type: 'note', text: 'Spoke to the airline\'s counsel.' });
  await note(sola, { type: 'airline_reply', text: 'Airline blames weather; no evidence attached.' });
  claim = await get(`claims/${C}`);
  check('an airline reply is dated on the claim', !!claim.airline_reply_at && /weather/.test(claim.airline_reply_summary));
  check('an offer needs an amount', (await refused(note(sola, { type: 'offer', text: 'Offered half' })))?.status === 400);
  await note(sola, { type: 'offer', text: 'Offered half in settlement', amount: 85000 });
  claim = await get(`claims/${C}`);
  check('an offer is kept on the claim', claim.settlement_offer_amount === 85000 && !!claim.settlement_offer_at);
  check('an empty note is refused', (await refused(note(sola, { type: 'note', text: '  ' })))?.status === 400);
  check('notes are in the event log with their full text', (await logs('Note added')).some((l) => /counsel/.test(l.note) && l.claims.id === C));
  check('a lead cannot take an airline reply', (await refused(applyCaseAction(admin, { action: 'note', kind: 'lead', id: 'L1', type: 'airline_reply', text: 'x', staff: ada })))?.status === 400);

  // ── Closing ────────────────────────────────────────────────────────────────
  check('a nonsense amount recovered is refused', (await refused(step(CLAIM.WON, sola, { amount: 'lots' })))?.status === 400);
  check('and the claim is still open', (await get(`claims/${C}`)).claim_status === CLAIM.WITH_SOLICITOR);
  await step(CLAIM.WON, sola, { amount: 170000 });
  claim = await get(`claims/${C}`);
  check('winning records the amount recovered', claim.amount_recovered === 170000 && !!claim.settlement_date);
  check('a won claim is due a payout within 7 days', claim.next_action === 'Pay the client their share' && daysAway(claim.next_action_due) <= 8);
  check('the legal stage it reached is kept', claim.legal_stage === LEGAL.COURT);
  await step(CLAIM.PAID, boss);
  check('a paid claim has nothing left to do', (await get(`claims/${C}`)).next_action === undefined);

  // ── A solicitor escalating takes the claim ─────────────────────────────────
  await db.doc('claims/C5').set({ claim_status: CLAIM.AWAITING_REPLY, full_name: 'Second Claim' });
  await applyStageChange(admin, { kind: 'claim', id: 'C5', to: CLAIM.WITH_SOLICITOR, note: '', staff: sola });
  const c5 = await get('claims/C5');
  check('a solicitor who escalates a claim becomes its lawyer', c5.lawyer_uid === 'sola');

  check('a missing record is reported as such', (await refused(applyCaseAction(admin, { action: 'assign', kind: 'claim', id: 'nope', slot: 'handler', to: 'ada', staff: ada })))?.status === 404);
  check('an unknown action is refused', (await refused(applyCaseAction(admin, { action: 'explode', kind: 'claim', id: 'C5', staff: ada })))?.status === 400);

  console.log(`\n${passed} passed, ${failed} failed`);
  process.exit(failed ? 1 : 0);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
