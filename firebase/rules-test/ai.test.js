/**
 * The AI assistant's bookkeeping, with the model replaced by a stand-in.
 *
 *   cd firebase
 *   firebase emulators:exec --only firestore --project demo-claims-hub "node rules-test/ai.test.js"
 *
 * Runs functions/ai.js against the Firestore emulator the way the aiAssist
 * function does. No call leaves the machine: what the model would be sent is
 * captured, and a canned answer is returned.
 */
if (!process.env.FIRESTORE_EMULATOR_HOST) {
  console.error('Refusing to run: FIRESTORE_EMULATOR_HOST is not set. Use firebase emulators:exec.');
  process.exit(1);
}
const admin = require('../functions/node_modules/firebase-admin');
const { runAiAssist, reviewAiOutput, callModel } = require('../functions/ai');
const { StageError, LEAD } = require('../functions/pipeline');
const { applyCaseAction } = require('../functions/case-action');
const { applyStageChange } = require('../functions/stage-change');
const { estimateCost } = require('../functions/ai-tasks');

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

const ada = { uid: 'ada', name: 'Ada Agent', role: 'Agent' };
const sola = { uid: 'sola', name: 'Sola Solicitor', role: 'Solicitor' };
const boss = { uid: 'boss', name: 'Bola Boss', role: 'Manager' };

/** A model that records what it was sent and answers from a script. */
function standIn(answers) {
  const seen = [];
  return {
    seen,
    callModel: async (task, message) => {
      seen.push({ task, message });
      return { output: answers[task], usage: { input_tokens: 2000, output_tokens: 1000 }, model: 'stand-in' };
    },
  };
}

const answers = {
  lead_triage: { summary: 'Cancelled at the gate.', assessment: 'likely_eligible', reasons: ['Less than 24 hours\' notice'], missing_information: ['Ticket price'], suggested_next_step: 'Call the passenger', draft_message_to_client: 'Dear Ada…' },
  case_brief: { brief: 'Seven hour domestic delay.', strengths: ['Over six hours'], weaknesses: ['No boarding pass'], missing_evidence: ['Boarding pass'], suggested_next_step: 'Chase the airline' },
  classify_reply: { category: 'rejects_extraordinary_circumstances', summary: 'Blames weather.', amount_offered: null, defence_assessment: 'Unproven.', suggested_next_step: 'Ask for the weather report', draft_reply: 'Dear Sirs…' },
};

(async () => {
  await db.doc('leads/L1').set({ full_name: 'Ada Lead', email: 'ada@example.com', claim_type: 'Flight cancelled', status: 'New lead' });
  await db.doc('claims/C1').set({
    full_name: 'Tunde Client', client_email: 'tunde@example.com', airline_name: 'Air Peace',
    claim_status: 'Awaiting Reply', lead_ref: db.doc('leads/L0'), account_no: '0123456789', bvn_number: '22222222222',
  });
  await db.collection('activity_logs').add({ claims: db.doc('claims/C1'), action: 'Claim opened', description: 'Opened', createdAt: admin.firestore.Timestamp.fromDate(new Date('2026-09-03')) });

  // ── A lead triage ──────────────────────────────────────────────────────────
  let model = standIn(answers);
  let r = await runAiAssist(admin, { task: 'lead_triage', id: 'L1', staff: ada }, model);
  check('the answer comes back to the caller', r.output.assessment === 'likely_eligible' && typeof r.id === 'string');
  let out = (await db.doc(`ai_outputs/${r.id}`).get()).data();
  check('the answer is kept', out.output.suggested_next_step === 'Call the passenger');
  check('with the task and the record it was about', out.task === 'lead_triage' && out.kind === 'lead' && out.record.path === 'leads/L1');
  check('who asked, and when', out.requested_by === 'ada' && out.requested_by_name === 'Ada Agent' && !!out.created_at);
  check('which model answered and what it cost', out.model === 'stand-in' && out.input_tokens === 2000 && out.output_tokens === 1000 && out.cost_usd === estimateCost({ input_tokens: 2000, output_tokens: 1000 }) && out.cost_usd > 0);
  check('and starts unreviewed', out.review_status === 'pending');
  check('the lead itself is untouched', JSON.stringify((await db.doc('leads/L1').get()).data()) === JSON.stringify({ full_name: 'Ada Lead', email: 'ada@example.com', claim_type: 'Flight cancelled', status: 'New lead' }));
  let logs = (await db.collection('activity_logs').where('action', '==', 'AI assist').get()).docs.map((d) => d.data());
  check('the run is in the event log', logs.length === 1 && logs[0].leadRef.path === 'leads/L1' && logs[0].performedByName === 'Ada Agent' && logs[0].ai_output.id === r.id);
  check('the model was not sent the lead\'s email', !JSON.stringify(model.seen[0].message).includes('ada@example.com'));

  // ── A case brief ───────────────────────────────────────────────────────────
  model = standIn(answers);
  r = await runAiAssist(admin, { task: 'case_brief', id: 'C1', staff: sola }, model);
  out = (await db.doc(`ai_outputs/${r.id}`).get()).data();
  const sentBrief = JSON.stringify(model.seen[0].message);
  check('a brief is sent the claim\'s history', sentBrief.includes('Claim opened'));
  check('a brief is not sent bank details or BVN', !sentBrief.includes('0123456789') && !sentBrief.includes('22222222222'));
  check('a claim\'s answer points at its lead too', out.lead_ref.path === 'leads/L0' && out.subject === 'Tunde Client');
  check('the claim itself is untouched', (await db.doc('claims/C1').get()).data().claim_status === 'Awaiting Reply');

  // ── An airline reply ───────────────────────────────────────────────────────
  model = standIn(answers);
  check('classifying needs the reply pasted in', (await refused(runAiAssist(admin, { task: 'classify_reply', id: 'C1', text: 'ok', staff: ada }, model)))?.status === 400);
  check('and the model is not called without it', model.seen.length === 0);
  r = await runAiAssist(admin, { task: 'classify_reply', id: 'C1', text: 'We regret the delay, which was caused by adverse weather at Abuja.', staff: ada }, model);
  out = (await db.doc(`ai_outputs/${r.id}`).get()).data();
  check('the pasted reply is kept with the answer', out.pasted_text.includes('adverse weather') && out.output.category === 'rejects_extraordinary_circumstances');
  check('classifying does not record the reply on the claim by itself', (await db.doc('claims/C1').get()).data().airline_reply_summary === undefined);

  // ── Evidence that is not this claim's ──────────────────────────────────────
  check('a document from another claim is refused', (await refused(runAiAssist(admin, { task: 'read_evidence', id: 'C1', address: 'claims/OTHER/evidence/1.jpg', staff: ada }, model)))?.status === 400);
  check('a path outside client documents is refused', (await refused(runAiAssist(admin, { task: 'read_evidence', id: 'C1', address: 'blog_images/x.png', staff: ada }, model)))?.status === 400);

  // ── Refusals ───────────────────────────────────────────────────────────────
  check('an unknown task is refused', (await refused(runAiAssist(admin, { task: 'write_judgment', id: 'C1', staff: ada }, model)))?.status === 400);
  check('a missing record is reported as such', (await refused(runAiAssist(admin, { task: 'case_brief', id: 'nope', staff: ada }, model)))?.status === 404);
  const failing = { callModel: async () => { throw new StageError(429, 'The AI assistant is busy. Try again in a minute.'); } };
  const before = (await db.collection('ai_outputs').get()).size;
  check('a failed call is reported to the caller', (await refused(runAiAssist(admin, { task: 'case_brief', id: 'C1', staff: ada }, failing)))?.status === 429);
  check('and leaves no answer behind', (await db.collection('ai_outputs').get()).size === before);

  // ── With no key, the real call says so without leaving the machine ─────────
  delete process.env.GEMINI_API_KEY;
  check('with no key set, staff are told it is not switched on', (await refused(callModel('case_brief', { role: 'user', parts: [{ text: 'x' }] })))?.status === 503);

  // ── Review ─────────────────────────────────────────────────────────────────
  await reviewAiOutput(admin, { id: r.id, verdict: 'not_useful', note: 'Missed that the weather report was attached', staff: sola });
  out = (await db.doc(`ai_outputs/${r.id}`).get()).data();
  check('staff can mark an answer not useful, with why', out.review_status === 'not_useful' && out.reviewed_by === 'sola' && /weather report/.test(out.review_note) && !!out.reviewed_at);
  check('a made-up verdict is refused', (await refused(reviewAiOutput(admin, { id: r.id, verdict: 'brilliant', staff: sola })))?.status === 400);
  check('reviewing a missing answer is refused', (await refused(reviewAiOutput(admin, { id: 'nope', verdict: 'useful', staff: sola })))?.status === 404);

  // ── A client who objects to AI ─────────────────────────────────────────────
  const optOut = (staff, kind, id, on, note) => applyCaseAction(admin, { action: 'ai_opt_out', kind, id, on, note, staff });
  await db.doc('leads/L2').set({ full_name: 'Chi Client', email: 'chi@example.com', status: 'Contacted', claim_ref: db.doc('claims/C2') });
  await db.doc('claims/C2').set({ full_name: 'Chi Client', claim_status: 'Under Review', lead_ref: db.doc('leads/L2') });
  await optOut(ada, 'claim', 'C2', true, 'Asked by email on 2 October');
  let c2 = (await db.doc('claims/C2').get()).data();
  check('any member of staff can record the objection', c2.ai_opt_out === true && c2.ai_opt_out_by === 'ada' && !!c2.ai_opt_out_at);
  check('the lead it came from is marked too', (await db.doc('leads/L2').get()).data().ai_opt_out === true);
  logs = (await db.collection('activity_logs').where('action', '==', 'AI use stopped').get()).docs.map((d) => d.data());
  check('the objection is in the event log with the note', logs.length === 1 && logs[0].claims.path === 'claims/C2' && /2 October/.test(logs[0].note));
  model = standIn(answers);
  check('the assistant then refuses the claim', (await refused(runAiAssist(admin, { task: 'case_brief', id: 'C2', staff: sola }, model)))?.status === 403);
  check('and refuses its lead', (await refused(runAiAssist(admin, { task: 'lead_triage', id: 'L2', staff: ada }, model)))?.status === 403);
  check('nothing is sent to the model', model.seen.length === 0);
  check('an agent cannot lift the objection', (await refused(optOut(ada, 'claim', 'C2', false)))?.status === 403);
  check('nor can a lawyer', (await refused(optOut(sola, 'lead', 'L2', false)))?.status === 403);
  await optOut(boss, 'lead', 'L2', false, 'Client changed their mind');
  c2 = (await db.doc('claims/C2').get()).data();
  check('a manager can lift it, on both records', c2.ai_opt_out === undefined && (await db.doc('leads/L2').get()).data().ai_opt_out === undefined);
  r = await runAiAssist(admin, { task: 'case_brief', id: 'C2', staff: sola }, model);
  check('and the assistant works on it again', !!r.id);
  await optOut(ada, 'claim', 'C1', true);
  check('a claim whose lead is gone can still be marked', (await db.doc('claims/C1').get()).data().ai_opt_out === true);
  await db.doc('leads/L3').set({ full_name: 'Dayo Lead', email: 'dayo@example.com', status: 'Contacted' });
  await optOut(ada, 'lead', 'L3', true);
  const opened = await applyStageChange(admin, { kind: 'lead', id: 'L3', to: LEAD.QUALIFIED, note: '', staff: ada });
  check('a claim opened from an objecting lead carries the objection', (await db.doc(`claims/${opened.claimId}`).get()).data().ai_opt_out === true);

  console.log(`\n${passed} passed, ${failed} failed`);
  process.exit(failed ? 1 : 0);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
