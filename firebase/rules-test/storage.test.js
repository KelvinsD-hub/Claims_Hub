/**
 * Storage security rules tests.
 *
 * storage.rules restricts client documents to approved staff by looking the
 * caller up in Firestore. That lookup needs Cloud Storage to hold permission
 * to read Firestore (roles/firebaserules.firestoreServiceAgent), which the
 * production project has had since the rules were published from the console.
 *
 *   cd firebase
 *   firebase emulators:exec --only firestore,storage --project demo-claims-hub "node rules-test/storage.test.js"
 *
 * The storage rules look the caller up in Firestore, so both emulators run.
 */
const fs = require('fs');
const path = require('path');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const { doc, setDoc } = require('firebase/firestore');
const { ref, uploadString, getBytes } = require('firebase/storage');

let passed = 0;
let failed = 0;
async function check(name, promise) {
  try {
    await promise;
    passed++;
    console.log(`PASS  ${name}`);
  } catch (e) {
    failed++;
    console.log(`FAIL  ${name}\n      ${String(e.message).split('\n')[0]}`);
  }
}

(async () => {
  const read = (f) => fs.readFileSync(path.join(__dirname, '..', f), 'utf8');
  const env = await initializeTestEnvironment({
    projectId: 'demo-claims-hub',
    firestore: { rules: read('firestore.rules') },
    storage: { rules: read('storage.rules') },
  });

  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    const bucket = ctx.storage();
    await setDoc(doc(db, 'users/agent'), { role: 'Agent', approved: true });
    await setDoc(doc(db, 'users/pending'), { role: 'Agent', approved: false });
    await uploadString(ref(bucket, 'claims/claim1/boarding-pass.pdf'), 'pdf', 'raw', { contentType: 'application/pdf' });
    await uploadString(ref(bucket, 'claims/claim1/LOA_claim1.pdf'), 'letter', 'raw', { contentType: 'application/pdf' });
    await uploadString(ref(bucket, 'claims/claim1/evidence/existing.jpg'), 'jpg', 'raw', { contentType: 'image/jpeg' });
    await uploadString(ref(bucket, 'solicitor_exports/export.csv'), 'csv', 'raw', { contentType: 'text/csv' });
  });

  const agent = env.authenticatedContext('agent').storage();
  const pending = env.authenticatedContext('pending').storage();
  const stranger = env.authenticatedContext('stranger').storage();
  const breakGlass = env.authenticatedContext('claimonly', { admin: true }).storage();
  const anon = env.unauthenticatedContext().storage();
  const pdf = { contentType: 'application/pdf' };

  await check('staff can read a client document', assertSucceeds(getBytes(ref(agent, 'claims/claim1/boarding-pass.pdf'))));
  await check('staff can upload a client document', assertSucceeds(uploadString(ref(agent, 'claims/claim1/letter.pdf'), 'x', 'raw', pdf)));
  await check('staff can read a solicitor export', assertSucceeds(getBytes(ref(agent, 'solicitor_exports/export.csv'))));
  await check('break-glass admin claim can read a client document', assertSucceeds(getBytes(ref(breakGlass, 'claims/claim1/boarding-pass.pdf'))));

  await check('an unapproved account cannot read a client document', assertFails(getBytes(ref(pending, 'claims/claim1/boarding-pass.pdf'))));
  await check('an account with no users document cannot read a client document', assertFails(getBytes(ref(stranger, 'claims/claim1/boarding-pass.pdf'))));
  await check('an unapproved account cannot read a solicitor export', assertFails(getBytes(ref(pending, 'solicitor_exports/export.csv'))));
  await check('the public cannot read a client document', assertFails(getBytes(ref(anon, 'claims/claim1/boarding-pass.pdf'))));

  await check('a client can add a PDF as evidence', assertSucceeds(uploadString(ref(anon, 'claims/claim1/evidence/ticket.pdf'), 'x', 'raw', pdf)));
  await check('a client can add a photo as evidence', assertSucceeds(uploadString(ref(anon, 'claims/claim1/evidence/pass.jpg'), 'x', 'raw', { contentType: 'image/jpeg' })));
  await check('a client cannot add another kind of file', assertFails(uploadString(ref(anon, 'claims/claim1/evidence/run.exe'), 'x', 'raw', { contentType: 'application/octet-stream' })));
  await check('a client cannot replace evidence already on file', assertFails(uploadString(ref(anon, 'claims/claim1/evidence/existing.jpg'), 'y', 'raw', { contentType: 'image/jpeg' })));
  await check('a client cannot read evidence back', assertFails(getBytes(ref(anon, 'claims/claim1/evidence/existing.jpg'))));
  await check('a client cannot write outside the evidence folder', assertFails(uploadString(ref(anon, 'claims/claim1/ticket.pdf'), 'x', 'raw', pdf)));
  await check('a client cannot overwrite a generated letter', assertFails(uploadString(ref(anon, 'claims/claim1/LOA_claim1.pdf'), 'forged', 'raw', pdf)));
  await check('a client cannot write into a subfolder of evidence', assertFails(uploadString(ref(anon, 'claims/claim1/evidence/deep/x.pdf'), 'x', 'raw', pdf)));
  await check('staff can read client evidence', assertSucceeds(getBytes(ref(agent, 'claims/claim1/evidence/existing.jpg'))));
  await check('an unapproved account cannot read client evidence', assertFails(getBytes(ref(pending, 'claims/claim1/evidence/existing.jpg'))));
  await check('a person can upload their own profile photo', assertSucceeds(uploadString(ref(pending, 'users/pending/photo.png'), 'x', 'raw', { contentType: 'image/png' })));

  await env.cleanup();
  console.log(`\n${passed} passed, ${failed} failed`);
  process.exit(failed ? 1 : 0);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
