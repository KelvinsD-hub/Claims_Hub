// Notifications: when to tell whom, and what. Plain node:  node notifications.test.js
const n = require('./notifications');

let passed = 0;
let failed = 0;
function check(name, ok) {
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}`);
  ok ? passed++ : failed++;
}
const esc = (v) => String(v).replace(/&/g, '&amp;').replace(/</g, '&lt;');

// When a partner hears
check('a new referral is news', n.partnerNews(null, { lead: 'New lead', claim: '' }).news === 'new');
check('contacted is news', n.partnerNews({ lead: 'New lead', claim: '' }, { lead: 'Contacted', claim: '' }).label === 'We are speaking to the client');
check('qualified is news', n.partnerNews({ lead: 'Contacted', claim: '' }, { lead: 'Qualified', claim: '' }).label === 'Collecting documents');
check('details to terms pending is not news (same step)', n.partnerNews({ lead: 'Qualified', claim: 'Details Pending' }, { lead: 'Qualified', claim: 'Terms Pending' }) === null);
check('the claim opening is not news twice', n.partnerNews({ lead: 'Qualified', claim: '' }, { lead: 'Qualified', claim: 'Details Pending' }) === null);
check('demand pending to awaiting reply is not news', n.partnerNews({ lead: 'Qualified', claim: 'Demand Pending' }, { lead: 'Qualified', claim: 'Awaiting Reply' }) === null);
check('won is news with an outcome', n.partnerNews({ lead: 'Qualified', claim: 'Awaiting Reply' }, { lead: 'Qualified', claim: 'Won' }).outcome === 'won');
check('won to paid is not news', n.partnerNews({ lead: 'Qualified', claim: 'Won' }, { lead: 'Qualified', claim: 'Paid' }) === null);

// What a partner is told
const mail = n.partnerEmail({ partnerName: 'Tunde Bakare', clientName: 'Ada Obi', airline: 'Air Peace', news: { news: 'update', label: 'With the airline' } }, esc);
check('partner subject', mail.subject === 'Update on Ada O.\'s claim: With the airline');
check('partner email has no surname', !mail.html.includes('Obi') && !mail.text.includes('Obi'));
check('partner email links to their page', mail.text.includes('https://claimsassistltd.com/partner'));
check('a new referral reads so', n.partnerEmail({ partnerName: 'T', clientName: 'Ada Obi', airline: '', news: { news: 'new', label: 'Received' } }, esc).subject.startsWith('New referral: Ada O.'));
check('a win reads so', n.partnerEmail({ partnerName: 'T', clientName: 'Ada Obi', news: { news: 'update', label: 'Won', outcome: 'won' } }, esc).subject.includes('was won'));

// Clients
const tracker = n.trackerUrl('C1', 'tok&en');
check('tracker is on the website and escapes the token', tracker === 'https://claimsassistltd.com/track?claimRef=claims%2FC1&token=tok%26en');
const signed = n.claimOpenedEmail({ name: 'Ada Obi', airline: 'Air Peace', signedOnWebsite: true, tracker, evidenceUrl: 'https://claimshub.online/evidenceForm?x' }, esc);
check('a client who signed online is not asked again', !signed.text.includes('evidenceForm') && signed.subject.startsWith('Your claim is open'));
const unsigned = n.claimOpenedEmail({ name: 'Ada', airline: '', signedOnWebsite: false, tracker, evidenceUrl: 'https://claimshub.online/evidenceForm?x' }, esc);
check('a client who has not signed is sent the form', unsigned.text.includes('evidenceForm') && unsigned.subject.startsWith('Action needed'));
const paid = n.paidEmail({ name: '<b>Ada</b>', airline: 'Air Peace', tracker }, esc);
check('paid email escapes the name', !paid.html.includes('<b>'));
check('paid email links to the tracker', paid.html.includes('/track?claimRef='));

console.log(`\n${passed} passed, ${failed} failed`);
process.exit(failed ? 1 : 0);
