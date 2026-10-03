// Referral partners: what they may see. Plain node:  node partners.test.js
const p = require('./partners');
const { StageError } = require('./pipeline');

let passed = 0;
let failed = 0;
function check(name, ok) {
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}`);
  ok ? passed++ : failed++;
}
function refusal(fn) {
  try { fn(); return null; } catch (e) { return e instanceof StageError ? e : null; }
}

const admin = { uid: 'a', name: 'Ada Admin', role: 'Admin' };
const agent = { uid: 'g', name: 'Gbenga', role: 'Agent' };

// Inviting
const plan = p.planPartner({ staff: admin, name: '  Tunde   Bakare ', email: ' Tunde@Example.com ', phone: '+234 801 234 5678' });
check('name tidied', plan.name === 'Tunde Bakare');
check('email lower-cased', plan.email === 'tunde@example.com');
check('phone digits kept', plan.phone === '+2348012345678');
check('only admins invite', refusal(() => p.planPartner({ staff: agent, name: 'X', email: 'x@y.co' })).status === 403);
check('a bad email is refused', !!refusal(() => p.planPartner({ staff: admin, name: 'X', email: 'nope' })));

// Codes
check('code from name', p.partnerCode('Tunde Bakare') === 'p-tunde-bakare');
check('second try is numbered', p.partnerCode('Tunde Bakare', 1) === 'p-tunde-bakare-2');
check('code is a valid link code', /^[a-z0-9][a-z0-9-]{1,31}$/.test(p.partnerCode('A very long partner name that goes on and on', 9)));
check('code from symbols only', p.partnerCode('!!!') === 'p-partner');

// Names
check('first name and initial', p.shortName('ada obi-okafor') === 'Ada O.');
check('single name', p.shortName('Ada') === 'Ada');
check('no name', p.shortName('') === 'Client');

// Progress
check('new lead', p.progressOf('New lead', '').label === 'Received');
check('rejected lead is closed', p.progressOf('Rejected', '').done === true);
check('claim with the airline', p.progressOf('Qualified', 'Awaiting Reply').label === 'With the airline');
check('old stage names still read', p.progressOf('Qualified', 'Claim Won').outcome === 'won');
check('paid counts as won', p.progressOf('Qualified', 'Paid').outcome === 'won');

// What leaves the server
const ts = (ms) => ({ toMillis: () => ms });
const lead = {
  full_name: 'Ada Obi', email: 'ada@example.com', phone: '+2348000000000', address: '1 Road',
  date_of_birth: '1990-01-01', signature: 'BASE64', account_no: 'enc', booking_reference: 'ABC123',
  airline_name: 'Air Peace', route_from: 'LOS', route_to: 'ABV', complaint_type: 'Flight delay',
  fare_paid: 85000, estimate_value: '₦21,250', status: 'Qualified', loa_signed: true,
  created_at: ts(1000), stage_changed_at: ts(2000), initial_summary: 'secret notes',
};
const claim = { claim_status: 'Under Review', createdAt: ts(3000), stage_changed_at: ts(4000), amount_recovered: 21250, client_email: 'ada@example.com' };
const view = p.referralView(lead, claim);
const shown = JSON.stringify(view);
check('the partner sees first name and initial only', view.client === 'Ada O.' && !shown.includes('Obi'));
for (const secret of ['ada@example.com', '+2348000000000', '1 Road', '1990', 'BASE64', 'enc', 'ABC123', '85000', '21,250', '21250', 'secret notes']) {
  check(`nothing private leaks: ${secret}`, !shown.includes(secret));
}
check('the partner sees airline, route and stage', view.airline === 'Air Peace' && view.route === 'LOS → ABV' && view.label === 'Under review');
check('last update is the latest change', view.updated === new Date(4000).toISOString());

// Totals
const s = p.summarise([
  { signed: true, step: 2, done: false },
  { signed: false, step: 1, done: false },
  { signed: true, step: 5, done: true, outcome: 'won' },
], 40);
check('totals', s.clicks === 40 && s.referrals === 3 && s.signed === 2 && s.inProgress === 1 && s.won === 1);

// Credit
check('a partner link credits the partner', JSON.stringify(p.creditFields({ channel: 'partner', partner_id: 'P1', label: 'Tunde' }, { name: 'Tunde Bakare' })) === JSON.stringify({ partner_id: 'P1', partner_name: 'Tunde Bakare' }));
check('an ad link credits nobody', p.creditFields({ channel: 'facebook' }) === null);

// Emails
const esc = (v) => String(v).replace(/</g, '&lt;');
const mail = p.inviteEmail({ name: '<b>Tunde</b>', link: 'https://claimsassistltd.com/go/p-t', signIn: 'https://x/sign', invitedBy: 'Ada' }, esc);
check('invite escapes the name', !mail.html.includes('<b>'));
check('invite carries the link and sign-in', mail.text.includes('/go/p-t') && mail.text.includes('https://x/sign'));

console.log(`\n${passed} passed, ${failed} failed`);
process.exit(failed ? 1 : 0);
