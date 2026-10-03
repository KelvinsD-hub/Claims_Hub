/**
 * Referral partners, written to the database.
 *
 *   cd firebase
 *   firebase emulators:exec --only firestore --project demo-claims-hub "node rules-test/partners.test.js"
 *
 * Runs functions/partners.js against the Firestore emulator with the Admin
 * SDK, the way partnerAdmin and partnerPortal do. Sign-in links and custom
 * claims need the Auth emulator and are not exercised here.
 */
if (!process.env.FIRESTORE_EMULATOR_HOST) {
  console.error('Refusing to run: FIRESTORE_EMULATOR_HOST is not set. Use firebase emulators:exec.');
  process.exit(1);
}
const admin = require('../functions/node_modules/firebase-admin');
const p = require('../functions/partners');
const { claimFieldsFromLead } = require('../functions/lead-to-claim');
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

const boss = { uid: 'boss1', name: 'Bola Admin', role: 'Admin' };
const agent = { uid: 'agent1', name: 'Ada Agent', role: 'Agent' };

(async () => {
  // ── Inviting ────────────────────────────────────────────────────────────────
  await db.doc('campaign_links/p-tunde-bakare').set({ label: 'Someone else', channel: 'partner', clicks: 0 });
  const made = await p.createPartner(admin, { staff: boss, name: 'Tunde Bakare', email: 'Tunde@Example.com', phone: '0801' });
  check('a taken code is skipped', made.code === 'p-tunde-bakare-2');
  check('the link is on the website', made.link === 'https://claimsassistltd.com/go/p-tunde-bakare-2');
  const partner = (await db.doc(`partners/${made.id}`).get()).data();
  check('the partner starts invited', partner.status === 'invited' && partner.uid === null);
  const link = (await db.doc(`campaign_links/${made.code}`).get()).data();
  check('their link is a partner link', link.channel === 'partner' && link.partner_id === made.id && link.active === true);
  check('the same email cannot be invited twice', (await refused(p.createPartner(admin, { staff: boss, name: 'T', email: 'tunde@example.com' }))).status === 409);
  check('an agent cannot invite', (await refused(p.createPartner(admin, { staff: agent, name: 'X', email: 'x@example.com' }))).status === 403);

  // ── Leads through the link ──────────────────────────────────────────────────
  const leadA = db.doc('leads/PT-A');
  await leadA.set({ full_name: 'Ada Obi', email: 'ada@example.com', phone: '+234', airline_name: 'Air Peace', route_from: 'LOS', route_to: 'ABV', status: 'Qualified', loa_signed: true, source_link: made.code, created_at: admin.firestore.Timestamp.fromMillis(1000) });
  await db.doc('leads/PT-B').set({ full_name: 'Bisi Ade', status: 'New lead', source_link: made.code, created_at: admin.firestore.Timestamp.fromMillis(2000) });
  await db.doc('leads/PT-C').set({ full_name: 'Not Theirs', status: 'New lead', source_link: 'fb' });
  const credit = p.creditFields(link, partner);
  check('credit names the partner', credit.partner_id === made.id && credit.partner_name === 'Tunde Bakare');
  const claimFields = claimFieldsFromLead({ ...(await leadA.get()).data(), ...credit });
  check('a claim keeps the credit', claimFields.partner_id === made.id && claimFields.source_link === made.code);
  await db.doc('claims/PT-A').set({ lead_ref: leadA, claim_status: 'Won', source_link: made.code, amount_recovered: 21250 });

  // ── The partner's page ──────────────────────────────────────────────────────
  check('a stranger gets nothing', (await refused(p.portal(admin, { user: { uid: 'u-x', email: 'x@example.com' } }))).status === 403);
  const page = await p.portal(admin, { user: { uid: 'u-tunde', email: 'tunde@example.com' } });
  check('first sign-in ties the account', (await db.doc(`partners/${made.id}`).get()).data().uid === 'u-tunde');
  check('and makes them active', (await db.doc(`partners/${made.id}`).get()).data().status === 'active');
  check('only their own referrals', page.referrals.length === 2);
  check('newest first', page.referrals[0].client === 'Bisi A.');
  check('a won claim reads as won', page.referrals[1].outcome === 'won');
  check('totals', page.summary.referrals === 2 && page.summary.signed === 1 && page.summary.won === 1);
  const all = JSON.stringify(page);
  check('no contact details, amounts or full names', !all.includes('ada@example.com') && !all.includes('+234') && !all.includes('21250') && !all.includes('Obi') && !all.includes('Not Theirs'));
  const again = await p.portal(admin, { user: { uid: 'u-tunde', email: 'tunde@example.com' } });
  check('later sign-ins find them by account', again.name === 'Tunde Bakare');
  check('another account with the same email cannot take over', (await refused(p.portal(admin, { user: { uid: 'u-thief', email: 'tunde@example.com' } }))).status === 403);

  // ── Suspending ──────────────────────────────────────────────────────────────
  await p.setPartnerActive(admin, { staff: boss, id: made.id, active: false });
  check('a suspended partner\'s page is closed', (await refused(p.portal(admin, { user: { uid: 'u-tunde', email: 'tunde@example.com' } }))).status === 403);
  check('and their link stops crediting', (await db.doc(`campaign_links/${made.code}`).get()).data().active === false);
  check('and gets no sign-in link', (await p.partnerForEmail(db, 'tunde@example.com')) === null);
  await p.setPartnerActive(admin, { staff: boss, id: made.id, active: true });
  check('restoring reopens it', (await p.portal(admin, { user: { uid: 'u-tunde', email: 'tunde@example.com' } })).name === 'Tunde Bakare');
  check('an agent cannot suspend', (await refused(p.setPartnerActive(admin, { staff: agent, id: made.id, active: false }))).status === 403);

  const log = await db.collection('activity_logs').where('entityType', '==', 'Partner').get();
  check('invites, joins and suspensions are logged', log.size === 4);

  console.log(`\n${passed} passed, ${failed} failed`);
  process.exit(failed ? 1 : 0);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
