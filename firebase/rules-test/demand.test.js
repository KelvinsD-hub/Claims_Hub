/**
 * Asking for a demand letter, against the Firestore emulator.
 *
 *   cd firebase
 *   firebase emulators:exec --only firestore --project demo-claims-hub "node rules-test/demand.test.js"
 *
 * Runs functions/demand.js the way the sendDemand function does. Nothing is
 * emailed: this only covers whether the trigger is set and what is recorded.
 */
if (!process.env.FIRESTORE_EMULATOR_HOST) {
  console.error('Refusing to run: FIRESTORE_EMULATOR_HOST is not set. Use firebase emulators:exec.');
  process.exit(1);
}
const admin = require('../functions/node_modules/firebase-admin');
const { requestDemandLetter } = require('../functions/demand');
const { StageError, CLAIM } = require('../functions/pipeline');

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
const ready = {
  full_name: 'Tunde Client', airline_name: 'Air Peace', flight_number: 'P47120',
  flight_date: '2026-09-01', departure: 'Lagos', destination: 'Abuja',
  signature: 'iVBORw0KGgo', claims_amount: '₦21,250', lead_ref: db.doc('leads/L1'),
};
const send = (id, email = 'legal@flyairpeace.com') => requestDemandLetter(admin, { id, email, staff: ada });
const get = async (id) => (await db.doc(`claims/${id}`).get()).data();

(async () => {
  await db.doc('claims/ready').set({ ...ready, claim_status: CLAIM.DEMAND_PENDING });
  await db.doc('claims/early').set({ ...ready, claim_status: CLAIM.UNDER_REVIEW });
  await db.doc('claims/thin').set({ ...ready, flight_number: '', signature: '', claim_status: CLAIM.DEMAND_PENDING });
  await db.doc('claims/sent').set({ ...ready, claim_status: CLAIM.AWAITING_REPLY });
  await db.doc('claims/closed').set({ ...ready, claim_status: CLAIM.LOST });
  await db.doc('claims/held').set({
    ...ready, claim_status: CLAIM.DEMAND_PENDING,
    work_may_start_at: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 5 * 86400000)),
  });
  await db.doc('claims/eager').set({
    ...ready, claim_status: CLAIM.DEMAND_PENDING, start_immediately: true,
    work_may_start_at: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 5 * 86400000)),
  });

  check('an address is needed', (await refused(send('ready', '')))?.status === 400);
  check('and it must be one address', (await refused(send('ready', 'a@b.com, c@d.com')))?.status === 400);
  check('a claim that is gone is reported as such', (await refused(send('nope')))?.status === 404);
  check('a claim not yet at Demand Pending is refused', (await refused(send('early')))?.status === 409);
  check('a closed claim is refused', (await refused(send('closed')))?.status === 409);
  const thin = await refused(send('thin'));
  check('a claim missing what the letter states is refused, saying what', thin?.status === 400 && /flight number/.test(thin.message) && /authority/.test(thin.message));
  check('a client who can still cancel holds the letter', (await refused(send('held')))?.status === 409);
  check('and none of those set the trigger', !(await get('early')).trigger_airline_email && !(await get('thin')).trigger_airline_email && !(await get('held')).trigger_airline_email);

  let r = await send('ready', ' Legal@FlyAirPeace.com ');
  let claim = await get('ready');
  check('a ready claim is sent to the address chosen', r.resend === false && claim.trigger_airline_email === true && claim.airline_email_selection === 'legal@flyairpeace.com');
  check('with who asked', claim.letter_requested_by === 'ada' && claim.letter_requested_by_name === 'Ada Agent');
  check('the stage is left for the sending function to move', claim.claim_status === CLAIM.DEMAND_PENDING);
  let logs = (await db.collection('activity_logs').where('claims', '==', db.doc('claims/ready')).get()).docs.map((x) => x.data());
  check('it is in the event log, against the claim and its lead', logs.length === 1 && logs[0].action === 'Demand letter sent' && logs[0].leadRef.path === 'leads/L1' && logs[0].sent_to === 'legal@flyairpeace.com' && logs[0].performedByName === 'Ada Agent');
  check('a second press while it is going is refused', (await refused(send('ready')))?.status === 409);

  r = await send('sent');
  logs = (await db.collection('activity_logs').where('claims', '==', db.doc('claims/sent')).get()).docs.map((x) => x.data());
  check('a letter already sent can be sent again, and is logged as that', r.resend === true && logs[0].action === 'Demand letter resent');
  r = await send('eager');
  check('a client who asked us to start at once is not held', (await get('eager')).trigger_airline_email === true);

  console.log(`\n${passed} passed, ${failed} failed`);
  process.exit(failed ? 1 : 0);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
