// What a claim needs before its demand letter can go. Plain node:  node demand.test.js
const d = require('./demand');

let passed = 0;
let failed = 0;
function check(name, ok) {
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}`);
  ok ? passed++ : failed++;
}

const ready = {
  full_name: 'Tunde Client', airline_name: 'Air Peace', flight_number: 'P47120',
  flight_date: '2026-09-01', departure: 'Lagos', destination: 'Abuja',
  signature: 'iVBORw0KGgo', claims_amount: '₦21,250', pnr_number: 'ABC123',
  duration_of_delay: '7 hours',
};

check('a complete claim has nothing against it', d.demandReadiness(ready).blockers.length === 0 && d.demandReadiness(ready).warnings.length === 0);
for (const [field, what] of [
  ['full_name', 'name'], ['airline_name', 'airline'], ['flight_number', 'flight number'],
  ['flight_date', 'flight date'], ['departure', 'route'], ['destination', 'route'], ['signature', 'authority'],
]) {
  const r = d.demandReadiness({ ...ready, [field]: '  ' });
  check(`a claim without its ${field} cannot go (${what})`, r.blockers.length === 1 && new RegExp(what).test(r.blockers[0]));
}
check('an empty claim lists everything that is missing', d.demandReadiness({}).blockers.length === 6);
const thin = d.demandReadiness({ ...ready, claims_amount: '', pnr_number: '', duration_of_delay: '' });
check('a missing amount or booking reference is a warning, not a bar', thin.blockers.length === 0 && thin.warnings.length === 3);
check('a reason for the claim stands in for the length of delay', d.demandReadiness({ ...ready, duration_of_delay: '', claims_reason: 'Cancellation' }).warnings.length === 0);

const now = new Date('2026-10-02T12:00:00Z');
const later = { toDate: () => new Date('2026-10-10T00:00:00Z') };
const earlier = { toDate: () => new Date('2026-09-10T00:00:00Z') };
check('a client who can still cancel holds the letter', d.heldUntil({ work_may_start_at: later }, now) instanceof Date);
check('unless they asked us to start at once', d.heldUntil({ work_may_start_at: later, start_immediately: true }, now) === null);
check('a cancellation period that has run does not', d.heldUntil({ work_may_start_at: earlier }, now) === null);
check('a claim with no cancellation period does not', d.heldUntil({}, now) === null);

check('an ordinary address passes', d.EMAIL.test('legal@flyairpeace.com'));
check('two addresses in one do not', !d.EMAIL.test('a@b.com, c@d.com') && !d.EMAIL.test('a@b.com;c@d.com'));
check('a name with an address does not', !d.EMAIL.test('Legal <legal@air.com>'));

console.log(`\n${passed} passed, ${failed} failed`);
process.exit(failed ? 1 : 0);
