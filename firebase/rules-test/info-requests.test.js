/**
 * Requests to a client for more information, written to the database.
 *
 *   cd firebase
 *   firebase emulators:exec --only firestore --project demo-claims-hub "node rules-test/info-requests.test.js"
 *
 * Runs functions/info-requests.js against the Firestore emulator with the
 * Admin SDK, the way the infoRequest and clientInfoRequest functions do. File
 * uploads need Storage, so files are put on the request directly here.
 */
if (!process.env.FIRESTORE_EMULATOR_HOST) {
  console.error('Refusing to run: FIRESTORE_EMULATOR_HOST is not set. Use firebase emulators:exec.');
  process.exit(1);
}
const admin = require('../functions/node_modules/firebase-admin');
const r = require('../functions/info-requests');
const { storedAddress } = require('../functions/documents');
const { StageError } = require('../functions/pipeline');

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
const submit = (token, body) => r.submitAnswers(admin, {
  token, ...body, bucketName: 'demo-bucket', storedAddress,
});

(async () => {
  // ── A claim, asked and answered ─────────────────────────────────────────────
  await db.doc('leads/IR-L1').set({ full_name: 'Tunde Client', email: 't@example.com', phone: '0800' });
  await db.doc('claims/IR-C1').set({
    full_name: 'Tunde Client', client_email: 't@example.com', lead_ref: db.doc('leads/IR-L1'),
    airline_name: 'Air Peace', departure: 'LOS', destination: 'ABV', handler_uid: 'agent1',
  });

  const first = await r.createRequest(admin, { staff: agent, kind: 'claim', id: 'IR-C1', items: ['flight_number'], questions: [], message: '' });
  const sent = await r.createRequest(admin, {
    staff: agent, kind: 'claim', id: 'IR-C1',
    items: ['flight_number', 'booking_reference', 'phone', 'boarding_pass', 'id_document'],
    questions: ['What did the gate agent say?'], message: 'Thank you',
  });
  check('the link points at the website form', sent.link.startsWith('https://claimsassistltd.com/more-info?t='));
  check('the token is not stored', !(await db.doc(`info_requests/${sent.token}`).get()).exists);
  const stored = (await db.doc(`info_requests/${sent.id}`).get()).data();
  check('the request is stored under the token hash', stored.status === 'open' && stored.items.length === 5);
  check('the request remembers the claim\'s lead', stored.lead_ref.path === 'leads/IR-L1');
  check('a newer request replaces the open one', (await db.doc(`info_requests/${first.id}`).get()).data().status === 'replaced');
  check('the old link says to use the newer one', (await r.requestInfo(admin, { token: first.token })).status === 'replaced');
  let claim = (await db.doc('claims/IR-C1').get()).data();
  check('the claim shows a request is out', claim.info_request_open === true);
  check('chasing becomes the next action', claim.next_action === 'Chase the client for the information asked for');

  const info = await r.requestInfo(admin, { token: sent.token });
  check('the form gets the first name only', info.firstName === 'Tunde');
  check('the form gets what was asked', info.items.map((i) => i.key).join() === 'flight_number,booking_reference,phone,boarding_pass,id_document');
  check('the form gets the route for context', info.flight.route === 'LOS to ABV' && info.flight.airline === 'Air Peace');
  check('the form is not given the email address', !JSON.stringify(info).includes('t@example.com'));

  const answers = {
    flight_number: 'p4 7120', booking_reference: 'abc123', phone: '+234 800 000 0000',
    id_document: { unavailable: true, reason: 'Renewing my passport' },
  };
  const noFile = await refused(submit(sent.token, { answers, replies: ['Technical fault'] }));
  check('answers without the boarding pass are refused', !!noFile && noFile.status === 400);

  await db.doc(`info_requests/${sent.id}`).update({
    files: [{ item: 'boarding_pass', name: 'bp.jpg', path: 'claims/IR-C1/evidence/request-x-1-bp.jpg', type: 'image/jpeg', size: 10 }],
  });
  const done = await submit(sent.token, { answers, replies: ['Technical fault'] });
  check('the handler is told', done.handlerUid === 'agent1');
  check('what was sent is listed', done.sent.includes('Flight number') && done.sent.some((s) => s.startsWith('Boarding pass')));
  check('what the client does not have is listed', done.missing.join() === 'Photo ID');

  claim = (await db.doc('claims/IR-C1').get()).data();
  check('the flight number is on the claim', claim.flight_number === 'P47120');
  check('the booking reference is on the claim', claim.pnr_number === 'ABC123');
  check('the boarding pass is among the claim\'s documents', (claim.attached_document || []).some((d) => d.includes('request-x-1-bp.jpg')));
  check('the request is no longer out', claim.info_request_open === false);
  check('reviewing becomes the next action', claim.next_action === 'Review the information the client sent');
  check('the phone number went to the lead', (await db.doc('leads/IR-L1').get()).data().phone === '+2348000000000');

  const answered = (await db.doc(`info_requests/${sent.id}`).get()).data();
  check('the request is answered', answered.status === 'answered');
  check('the reply is kept', answered.replies[0] === 'Technical fault');
  check('the earlier value is kept', answered.previous.flight_number === null);
  check('a second answer is refused', (await refused(submit(sent.token, { answers, replies: ['x'] }))).status === 409);

  const log = await db.collection('activity_logs').where('claims', '==', db.doc('claims/IR-C1')).get();
  const actions = log.docs.map((d) => d.data().action);
  check('asking is logged', actions.filter((a) => a === 'Information requested').length === 2);
  check('the answer is logged as the client', log.docs.some((d) => d.data().action === 'Client sent information' && d.data().actor_type === 'client'));

  // ── A lead, withdrawn ───────────────────────────────────────────────────────
  await db.doc('leads/IR-L2').set({ full_name: 'Bisi', email: 'b@example.com' });
  const withdrawn = await r.createRequest(admin, { staff: agent, kind: 'lead', id: 'IR-L2', items: [], questions: ['Which airport?'], message: '' });
  await r.cancelRequest(admin, { staff: agent, id: withdrawn.id });
  check('a withdrawn link says so', (await r.requestInfo(admin, { token: withdrawn.token })).status === 'cancelled');
  check('a withdrawn request cannot be answered', (await refused(submit(withdrawn.token, { replies: ['Lagos'] }))).status === 409);
  check('the lead no longer shows a request out', (await db.doc('leads/IR-L2').get()).data().info_request_open === false);

  // ── Refusals ────────────────────────────────────────────────────────────────
  await db.doc('leads/IR-L3').set({ full_name: 'No Email' });
  check('a record with no email is refused', (await refused(r.createRequest(admin, { staff: agent, kind: 'lead', id: 'IR-L3', items: ['address'] }))).status === 409);
  check('a missing record is refused', (await refused(r.createRequest(admin, { staff: agent, kind: 'claim', id: 'nope', items: ['address'] }))).status === 404);
  check('a made-up token finds nothing', (await r.requestInfo(admin, { token: 'made-up' })).status === 'missing');

  const expiring = await r.createRequest(admin, { staff: agent, kind: 'lead', id: 'IR-L2', items: ['address'] });
  await db.doc(`info_requests/${expiring.id}`).update({ expires_at: admin.firestore.Timestamp.fromMillis(Date.now() - 1000) });
  check('an expired link says so', (await r.requestInfo(admin, { token: expiring.token })).status === 'expired');
  check('an expired request cannot be answered', (await refused(submit(expiring.token, { answers: { address: '1 Test Street, Lagos' } }))).status === 409);

  console.log(`\n${passed} passed, ${failed} failed`);
  process.exit(failed ? 1 : 0);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
