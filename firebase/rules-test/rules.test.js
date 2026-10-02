/**
 * Firestore security rules tests.
 *
 *   cd firebase
 *   firebase emulators:exec --only firestore --project demo-claims-hub "node rules-test/rules.test.js"
 *
 * Runs entirely against the local emulator. Each case names who is acting and
 * what they should or should not be able to do.
 */
const fs = require('fs');
const path = require('path');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const {
  doc, getDoc, getDocs, setDoc, updateDoc, deleteDoc, addDoc, collection,
} = require('firebase/firestore');

const TOKEN = 'a-long-secure-token-value';

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
  const env = await initializeTestEnvironment({
    projectId: 'demo-claims-hub',
    firestore: {
      rules: fs.readFileSync(path.join(__dirname, '..', 'firestore.rules'), 'utf8'),
    },
  });

  // Seed with rules off, the way production data already exists.
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'users/super'), { display_name: 'Super', role: 'Super Admin', approved: true });
    await setDoc(doc(db, 'users/admin'), { display_name: 'Admin', role: 'Admin', approved: true });
    await setDoc(doc(db, 'users/manager'), { display_name: 'Manager', role: 'Manager', approved: true });
    await setDoc(doc(db, 'users/lawyer'), { display_name: 'Lawyer', role: 'Solicitor', approved: true });
    await setDoc(doc(db, 'users/agent'), { display_name: 'Agent', role: 'Agent', approved: true });
    // Signed up, never approved. One has given themselves a role label.
    await setDoc(doc(db, 'users/pending'), { display_name: 'Pending', role: 'Agent', approved: false });
    await setDoc(doc(db, 'users/blank'), { display_name: 'Blank' });
    await setDoc(doc(db, 'leads/lead1'), { full_name: 'A Client', status: 'New lead' });
    await setDoc(doc(db, 'claims/claim1'), { full_name: 'A Client', claim_status: 'Details Pending', secure_token: TOKEN });
    await setDoc(doc(db, 'claims/notoken'), { full_name: 'B Client', claim_status: 'Details Pending' });
    await setDoc(doc(db, 'activity_logs/log1'), { action: 'Lead created' });
    await setDoc(doc(db, 'solicitor_exports/exp1'), { status: 'sent' });
    await setDoc(doc(db, 'airlines_directory/air1'), { airline_name: 'Air Peace' });
    await setDoc(doc(db, 'stats/dashboard'), { weekly_lead_counts: [0, 0, 0, 0, 0, 0, 0] });
    await setDoc(doc(db, 'watchlist/w1'), { email: 'x@example.com' });
    await setDoc(doc(db, 'flight_stats/P47101_2026-09-20'), { claim_count: 3 });
    await setDoc(doc(db, 'blog_posts/post1'), { title: 'Hello' });
  });

  const as = (uid, claims) => env.authenticatedContext(uid, claims).firestore();
  const anon = env.unauthenticatedContext().firestore();
  const superAdmin = as('super');
  const admin = as('admin');
  const manager = as('manager');
  const lawyer = as('lawyer');
  const agent = as('agent');
  const pending = as('pending');
  const blank = as('blank');
  const stranger = as('stranger'); // signed in, no users document at all
  const breakGlass = as('claimonly', { admin: true }); // custom claim, no users document

  console.log('\n— The hole being closed: a signed-in account that nobody approved —');
  for (const [who, db] of [['unapproved account', pending], ['account with no approval field', blank], ['account with no users document', stranger]]) {
    await check(`${who} cannot read a lead`, assertFails(getDoc(doc(db, 'leads/lead1'))));
    await check(`${who} cannot list leads`, assertFails(getDocs(collection(db, 'leads'))));
    await check(`${who} cannot list claims`, assertFails(getDocs(collection(db, 'claims'))));
    // Staff-only fields. (The evidence fields stay open to anyone holding the
    // claim's link — that is the client's own route in, tested further down.)
    await check(`${who} cannot change a claim's status or trigger a letter`, assertFails(updateDoc(doc(db, 'claims/claim1'), { claim_status: 'Claim Won', trigger_airline_email: true })));
    await check(`${who} cannot touch a claim that has no client link`, assertFails(updateDoc(doc(db, 'claims/notoken'), { claims_amount: '1' })));
    await check(`${who} cannot list staff`, assertFails(getDocs(collection(db, 'users'))));
    await check(`${who} cannot read the activity log`, assertFails(getDoc(doc(db, 'activity_logs/log1'))));
  }
  await check('unapproved account cannot approve itself', assertFails(updateDoc(doc(pending, 'users/pending'), { approved: true })));
  await check('unapproved account cannot give itself a role', assertFails(updateDoc(doc(pending, 'users/pending'), { role: 'Admin' })));
  await check('account with no approval field cannot approve itself', assertFails(updateDoc(doc(blank, 'users/blank'), { approved: true })));
  await check('unapproved account cannot approve someone else', assertFails(updateDoc(doc(pending, 'users/blank'), { approved: true })));

  console.log('\n— Sign-up still works —');
  await check('a new person can create their own users document', assertSucceeds(setDoc(doc(as('newbie'), 'users/newbie'), { email: 'n@example.com', uid: 'newbie' })));
  await check('they cannot create it already approved', assertFails(setDoc(doc(as('newbie2'), 'users/newbie2'), { email: 'n@example.com', approved: true })));
  await check('they cannot create it with a role', assertFails(setDoc(doc(as('newbie3'), 'users/newbie3'), { email: 'n@example.com', role: 'Admin' })));
  await check('they cannot create a document for someone else', assertFails(setDoc(doc(as('newbie4'), 'users/other'), { email: 'n@example.com' })));
  await check('nobody signed out can create a users document', assertFails(setDoc(doc(anon, 'users/ghost'), { email: 'g@example.com' })));
  await check('an unapproved person can read their own document', assertSucceeds(getDoc(doc(pending, 'users/pending'))));
  await check('an unapproved person can fill in their own profile', assertSucceeds(updateDoc(doc(blank, 'users/blank'), { display_name: 'Named', city: 'Lagos' })));

  console.log('\n— Staff keep working —');
  for (const [who, db] of [['agent', agent], ['solicitor', lawyer], ['manager', manager], ['admin', admin], ['super admin', superAdmin]]) {
    await check(`${who} can list leads`, assertSucceeds(getDocs(collection(db, 'leads'))));
    await check(`${who} can list claims`, assertSucceeds(getDocs(collection(db, 'claims'))));
    await check(`${who} can edit a lead`, assertSucceeds(updateDoc(doc(db, 'leads/lead1'), { phone: '+2348000000000' })));
    await check(`${who} can update a claim`, assertSucceeds(updateDoc(doc(db, 'claims/claim1'), { claims_amount: '₦21,250' })));
    await check(`${who} can list staff`, assertSucceeds(getDocs(collection(db, 'users'))));
    await check(`${who} can read dashboard stats`, assertSucceeds(getDoc(doc(db, 'stats/dashboard'))));
  }
  await check('agent can ask for a demand letter to be sent', assertSucceeds(updateDoc(doc(agent, 'claims/notoken'), { airline_email_selection: 'legal@example.com', trigger_airline_email: true })));

  console.log('\n— Stages are changed by the server, not the app —');
  for (const [who, db] of [['agent', agent], ['solicitor', lawyer], ['super admin', superAdmin]]) {
    await check(`${who} cannot write a lead's stage directly`, assertFails(updateDoc(doc(db, 'leads/lead1'), { status: 'Qualified' })));
    await check(`${who} cannot mark a lead qualified directly`, assertFails(updateDoc(doc(db, 'leads/lead1'), { is_qualified: true })));
    await check(`${who} cannot write a claim's stage directly`, assertFails(updateDoc(doc(db, 'claims/notoken'), { claim_status: 'Won' })));
    await check(`${who} cannot forge who changed a stage`, assertFails(updateDoc(doc(db, 'claims/notoken'), { stage_changed_by: 'someone-else' })));
    await check(`${who} cannot create a claim directly`, assertFails(setDoc(doc(db, 'claims/new1'), { claim_status: 'Details Pending', secure_token: TOKEN })));
    await check(`${who} cannot change a claim's client link`, assertFails(updateDoc(doc(db, 'claims/claim1'), { secure_token: 'another-long-token-value' })));
  }
  await check('agent can edit their own profile', assertSucceeds(updateDoc(doc(agent, 'users/agent'), { city: 'Abuja' })));
  await check('agent can write an activity log entry', assertSucceeds(addDoc(collection(agent, 'activity_logs'), { action: 'Lead qualified' })));
  await check('agent can use the airlines directory', assertSucceeds(updateDoc(doc(agent, 'airlines_directory/air1'), { legal_email: 'legal@example.com' })));
  await check('agent can read and write blog posts', assertSucceeds(updateDoc(doc(agent, 'blog_posts/post1'), { title: 'Edited' })));

  console.log('\n— Limits on ordinary staff —');
  await check('agent cannot promote themselves', assertFails(updateDoc(doc(agent, 'users/agent'), { role: 'Admin' })));
  await check('agent cannot approve another account', assertFails(updateDoc(doc(agent, 'users/pending'), { approved: true })));
  await check('agent cannot edit another person\'s profile', assertFails(updateDoc(doc(agent, 'users/lawyer'), { city: 'X' })));
  await check('agent cannot delete a lead', assertFails(deleteDoc(doc(agent, 'leads/lead1'))));
  await check('agent cannot delete a claim', assertFails(deleteDoc(doc(agent, 'claims/notoken'))));
  await check('agent cannot read solicitor exports', assertFails(getDoc(doc(agent, 'solicitor_exports/exp1'))));
  await check('solicitor can read solicitor exports', assertSucceeds(getDoc(doc(lawyer, 'solicitor_exports/exp1'))));
  await check('nobody can edit an activity log entry', assertFails(updateDoc(doc(superAdmin, 'activity_logs/log1'), { action: 'changed' })));
  await check('nobody can delete an activity log entry', assertFails(deleteDoc(doc(superAdmin, 'activity_logs/log1'))));
  await check('staff cannot write dashboard stats', assertFails(setDoc(doc(admin, 'stats/dashboard'), { x: 1 })));

  console.log('\n— Admins manage staff —');
  await check('admin can approve an account', assertSucceeds(updateDoc(doc(admin, 'users/pending'), { approved: true })));
  await check('admin can set a role', assertSucceeds(updateDoc(doc(admin, 'users/pending'), { role: 'Solicitor' })));
  await check('admin cannot grant Super Admin', assertFails(updateDoc(doc(admin, 'users/pending'), { role: 'Super Admin' })));
  await check('admin cannot demote a Super Admin', assertFails(updateDoc(doc(admin, 'users/super'), { role: 'Agent' })));
  await check('admin cannot delete a Super Admin', assertFails(deleteDoc(doc(admin, 'users/super'))));
  await check('super admin can grant Super Admin', assertSucceeds(updateDoc(doc(superAdmin, 'users/manager'), { role: 'Super Admin' })));
  await check('super admin can take it away again', assertSucceeds(updateDoc(doc(superAdmin, 'users/manager'), { role: 'Manager' })));
  await check('manager can delete a lead', assertSucceeds(deleteDoc(doc(manager, 'leads/lead1'))));
  await check('admin can delete a staff account', assertSucceeds(deleteDoc(doc(admin, 'users/blank'))));
  await check('break-glass admin claim works without a users document', assertSucceeds(getDocs(collection(breakGlass, 'claims'))));
  await check('break-glass admin claim can approve an account', assertSucceeds(updateDoc(doc(breakGlass, 'users/agent'), { approved: true })));

  console.log('\n— The public and clients —');
  await check('the website can create a lead without signing in', assertSucceeds(addDoc(collection(anon, 'leads'), { full_name: 'Web Lead', status: 'New lead' })));
  await check('the public cannot read leads', assertFails(getDocs(collection(anon, 'leads'))));
  await check('the website can add a watchlist entry', assertSucceeds(addDoc(collection(anon, 'watchlist'), { email: 'w@example.com' })));
  await check('the public cannot read the watchlist', assertFails(getDoc(doc(anon, 'watchlist/w1'))));
  await check('the website can read a flight counter by id', assertSucceeds(getDoc(doc(anon, 'flight_stats/P47101_2026-09-20'))));
  await check('the public cannot list flight counters', assertFails(getDocs(collection(anon, 'flight_stats'))));
  await check('a client can open their claim from its link', assertSucceeds(getDoc(doc(anon, 'claims/claim1'))));
  await check('a claim with no token cannot be opened by the public', assertFails(getDoc(doc(anon, 'claims/notoken'))));
  await check('the public cannot list claims', assertFails(getDocs(collection(anon, 'claims'))));
  await check('a client can submit their evidence', assertSucceeds(updateDoc(doc(anon, 'claims/claim1'), { pnr_number: 'ABC123', claim_status: 'Terms Pending' })));
  await check('a client cannot mark their own claim as won', assertFails(updateDoc(doc(anon, 'claims/claim1'), { claim_status: 'Claim Won' })));
  await check('a client cannot trigger the airline email', assertFails(updateDoc(doc(anon, 'claims/claim1'), { trigger_airline_email: true })));
  await check('a client cannot change the token', assertFails(updateDoc(doc(anon, 'claims/claim1'), { secure_token: 'another-long-token-value' })));
  await check('the public cannot read staff records', assertFails(getDoc(doc(anon, 'users/agent'))));

  await env.cleanup();
  console.log(`\n${passed} passed, ${failed} failed`);
  process.exit(failed ? 1 : 0);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
