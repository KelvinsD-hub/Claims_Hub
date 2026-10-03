// Lead to claim fields. Plain node:  node lead-to-claim.test.js
const { claimFieldsFromLead, flightFromSummary } = require('./lead-to-claim');

let passed = 0;
let failed = 0;
function check(name, ok) {
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}`);
  ok ? passed++ : failed++;
}

const website = {
  email: 'ada@example.com', full_name: 'Ada Obi', airline_name: 'Air Peace',
  flight_number: 'p4 7120', flight_date: '2026-09-30',
  route_from: 'LOS', route_to: 'ABV', booking_reference: 'abc123',
  complaint_type: 'Flight delay', delay_hours: 7, source_link: 'fb-oct',
};
const out = claimFieldsFromLead(website);
check('flight number tidied', out.flight_number === 'P47120');
check('flight date as given', out.flight_date === '2026-09-30');
check('route onto the fields the demand letter reads',
  out.departure === 'LOS' && out.destination === 'ABV');
check('booking reference onto pnr_number', out.pnr_number === 'ABC123');
check('delay as text', out.duration_of_delay === '7 hours');
check('reason', out.claims_reason === 'Flight delay');
check('the link that brought them', out.source_link === 'fb-oct');
check('email, name, airline', out.client_email === 'ada@example.com'
  && out.full_name === 'Ada Obi' && out.airline_name === 'Air Peace');

const bare = claimFieldsFromLead({ full_name: '  ', delay_hours: 0, flight_number: 42 });
check('nothing invented for a bare lead',
  JSON.stringify(bare) === JSON.stringify({ client_email: '' }));

const summary = 'Route: LOS (Lagos) → ABV (Abuja)\nAirline: Air Peace · Flight P4 7120 · 2026-09-30\nDisruption: Flight delayed';
const f = flightFromSummary(summary);
check('summary: flight and date', f.flight_number === 'P47120' && f.flight_date === '2026-09-30');
const onlyDate = flightFromSummary('Airline: Air Peace · 2026-09-30');
check('summary: date without flight', onlyDate.flight_number === '' && onlyDate.flight_date === '2026-09-30');
const none = flightFromSummary('Airline: Not specified');
check('summary: neither', none.flight_number === '' && none.flight_date === '');
check('summary: missing', flightFromSummary(undefined).flight_number === '');

console.log(`\n${passed} passed, ${failed} failed`);
process.exit(failed ? 1 : 0);
