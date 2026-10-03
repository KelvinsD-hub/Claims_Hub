/**
 * Staff invitations, against the Firestore emulator.
 *
 *   cd firebase
 *   firebase emulators:exec --only firestore --project demo-claims-hub "node rules-test/invites.test.js"
 *
 * Runs functions/invites.js the way the staffInvite function does. Nothing is
 * emailed.
 */
if (!process.env.FIRESTORE_EMULATOR_HOST) {
  console.error('Refusing to run: FIRESTORE_EMULATOR_HOST is not set. Use firebase emulators:exec.');
  process.exit(1);
}
const admin = require('../functions/node_modules/firebase-admin');
const inv = require('../functions/invites');
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
const tokenOf = (link) => new URL(link).searchParams.get('invite');

const ada = { uid: 'ada', name: 'Ada Agent', role: 'Agent' };
const boss = { uid: 'boss', name: 'Bola Boss', role: 'Manager' };
const root = { uid: 'root', name: 'Rita Admin', role: 'Admin' };
const top = { uid: 'top', name: 'Sam Super', role: 'Super Admin' };

(async () => {
  await db.doc('users/kemi').set({ email: 'kemi@claimsassist.com', approved: true, role: 'Agent' });

  // Who may invite, and what
  check('an agent cannot invite', (await refused(inv.createInvite(admin, { staff: ada, email: 'x@y.com', name: 'X', role: 'Agent' })))?.status === 403);
  check('nor can a manager', (await refused(inv.createInvite(admin, { staff: boss, email: 'x@y.com', name: 'X', role: 'Agent' })))?.status === 403);
  check('an admin cannot invite a Super Admin', (await refused(inv.createInvite(admin, { staff: root, email: 'x@y.com', name: 'X', role: 'Super Admin' })))?.status === 403);
  check('a role must be a real one', (await refused(inv.createInvite(admin, { staff: root, email: 'x@y.com', name: 'X', role: 'Boss' })))?.status === 400);
  check('one email address is needed', (await refused(inv.createInvite(admin, { staff: root, email: 'a@b.com, c@d.com', name: 'X', role: 'Agent' })))?.status === 400);
  check('a name is needed', (await refused(inv.createInvite(admin, { staff: root, email: 'x@y.com', name: '  ', role: 'Agent' })))?.status === 400);
  check('someone who already has access is not invited again', (await refused(inv.createInvite(admin, { staff: root, email: 'KEMI@claimsassist.com', name: 'Kemi', role: 'Agent' })))?.status === 409);

  // Creating and reading
  const first = await inv.createInvite(admin, { staff: root, email: ' Tolu@Example.com ', name: 'Tolu  Lawyer', role: 'Solicitor', phone: '+234 803 000 1111' });
  const t1 = tokenOf(first.link);
  check('the link carries a token', /^[A-Za-z0-9_-]{30,}$/.test(t1 || ''));
  const stored = (await db.doc(`invites/${inv.hashToken(t1)}`).get()).data();
  check('only the token\'s hash is stored, with the address in lower case', stored.email === 'tolu@example.com' && !JSON.stringify(stored).includes(t1));
  check('the phone keeps only digits and +', stored.phone === '+2348030001111');
  let info = await inv.inviteInfo(admin, { token: t1 });
  check('the link says who it is for and as what', info.status === 'open' && info.email === 'tolu@example.com' && info.role === 'Solicitor' && info.name === 'Tolu Lawyer' && info.invitedBy === 'Rita Admin');
  check('a made-up link says so', (await inv.inviteInfo(admin, { token: 'nonsense' })).status === 'missing');

  // A second invite replaces the first
  const second = await inv.createInvite(admin, { staff: top, email: 'tolu@example.com', name: 'Tolu Lawyer', role: 'Solicitor' });
  const t2 = tokenOf(second.link);
  check('a new invite to the same address cancels the old link', (await inv.inviteInfo(admin, { token: t1 })).status === 'revoked');
  let open = await inv.listInvites(admin, { staff: root });
  check('admins see the one open invite', open.length === 1 && open[0].email === 'tolu@example.com');
  check('an agent cannot list invites', (await refused(inv.listInvites(admin, { staff: ada })))?.status === 403);

  // Accepting
  check('the wrong address cannot use it', (await refused(inv.acceptInvite(admin, { token: t2, user: { uid: 'mallory', email: 'mallory@example.com' } })))?.status === 403);
  check('nor can the old link', (await refused(inv.acceptInvite(admin, { token: t1, user: { uid: 'tolu', email: 'tolu@example.com' } })))?.status === 409);
  await db.doc('users/tolu').set({ email: 'tolu@example.com', approved: false, role: '', display_name: '' });
  const r = await inv.acceptInvite(admin, { token: t2, user: { uid: 'tolu', email: 'Tolu@Example.com' } });
  const tolu = (await db.doc('users/tolu').get()).data();
  check('accepting approves the account with the invited role', r.role === 'Solicitor' && tolu.approved === true && tolu.role === 'Solicitor');
  check('and fills in the name', tolu.display_name === 'Tolu Lawyer');
  check('the link then stops working', (await inv.inviteInfo(admin, { token: t2 })).status === 'used');
  check('and cannot be used twice', (await refused(inv.acceptInvite(admin, { token: t2, user: { uid: 'tolu', email: 'tolu@example.com' } })))?.status === 409);
  open = await inv.listInvites(admin, { staff: root });
  check('a used invite leaves the open list', open.length === 0);

  // A brand-new account with no users document yet (Google sign-in)
  const g = await inv.createInvite(admin, { staff: root, email: 'ngozi@gmail.com', name: 'Ngozi', role: 'Agent' });
  await inv.acceptInvite(admin, { token: tokenOf(g.link), user: { uid: 'ngozi', email: 'ngozi@gmail.com' } });
  const ngozi = (await db.doc('users/ngozi').get()).data();
  check('it creates the users document', ngozi.approved === true && ngozi.role === 'Agent' && ngozi.email === 'ngozi@gmail.com');

  // Expiry and cancelling
  const e = await inv.createInvite(admin, { staff: root, email: 'late@example.com', name: 'Late', role: 'Agent' });
  await db.doc(`invites/${inv.hashToken(tokenOf(e.link))}`).update({ expires_at: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 1000)) });
  check('an expired link is refused', (await refused(inv.acceptInvite(admin, { token: tokenOf(e.link), user: { uid: 'late', email: 'late@example.com' } })))?.status === 409);
  check('and shows as expired to admins', (await inv.listInvites(admin, { staff: root })).find((x) => x.email === 'late@example.com')?.expired === true);
  const c = await inv.createInvite(admin, { staff: root, email: 'gone@example.com', name: 'Gone', role: 'Agent' });
  check('an agent cannot cancel an invite', (await refused(inv.revokeInvite(admin, { staff: ada, id: inv.hashToken(tokenOf(c.link)) })))?.status === 403);
  await inv.revokeInvite(admin, { staff: root, id: inv.hashToken(tokenOf(c.link)) });
  check('a cancelled link is refused', (await refused(inv.acceptInvite(admin, { token: tokenOf(c.link), user: { uid: 'gone', email: 'gone@example.com' } })))?.status === 409);
  const sa = await inv.createInvite(admin, { staff: top, email: 'boss2@example.com', name: 'Boss Two', role: 'Super Admin' });
  check('an admin cannot cancel a Super Admin invite', (await refused(inv.revokeInvite(admin, { staff: root, id: inv.hashToken(tokenOf(sa.link)) })))?.status === 403);

  const logs = await db.collection('activity_logs').where('entityType', '==', 'Staff').get();
  check('invites, acceptances and cancellations are logged', logs.docs.some((d) => d.get('action') === 'Staff invited')
    && logs.docs.some((d) => d.get('action') === 'Invite accepted') && logs.docs.some((d) => d.get('action') === 'Invite cancelled'));

  const mail = inv.inviteEmail({ name: 'Tolu <b>', role: 'Solicitor', link: second.link, invitedBy: 'Rita', expiresAt: second.expiresAt }, (s) => String(s).replace(/</g, '&lt;'));
  check('the email escapes the name and carries the link', !mail.html.includes('<b>') && mail.html.includes(second.link) && mail.text.includes(second.link));

  console.log(`\n${passed} passed, ${failed} failed`);
  process.exit(failed ? 1 : 0);
})().catch((e) => { console.error(e); process.exit(1); });
