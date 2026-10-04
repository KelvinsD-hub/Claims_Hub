// Staff entering a lead: the checks. Plain node:  node add-lead.test.js
const a = require('./add-lead');
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

const base = { full_name: '  Ada   Obi ', phone: '0803 123 4567', reached_via: 'Phone call' };

// Phone numbers
check('Nigerian 0 number gets +234', a.cleanPhone('0803 123 4567') === '+2348031234567');
check('234 without plus gets one', a.cleanPhone('2348031234567') === '+2348031234567');
check('other numbers kept', a.cleanPhone('+44 7700 900123') === '+447700900123');

// Typed in by staff
const typed = a.planLead({
  ...base, email: ' Ada@Example.com ', heard_from: 'Instagram', complaint_type: 'Flight delay',
  airline_name: ' Air Peace ', flight_number: 'p4 7120', flight_date: '2026-09-30', route_from: 'Lagos', route_to: 'Abuja',
  booking_reference: 'abc123', note: 'Waited 7 hours.',
});
check('details mode by default', typed.mode === 'details');
check('name tidied', typed.lead.full_name === 'Ada Obi');
check('email lower-cased', typed.lead.email === 'ada@example.com');
check('source is where they heard', typed.lead.utm_source === 'Instagram');
check('how they reached us kept', typed.lead.medium_of_contact === 'Phone call');
check('flight tidied', typed.lead.flight_number === 'P47120' && typed.lead.booking_reference === 'ABC123');
check('note kept as the summary', typed.lead.initial_summary === 'Waited 7 hours.');
check('blank fields left out', !('complaint_type' in a.planLead(base).lead));
check('source not asked is marked', a.planLead(base).lead.utm_source === a.NOT_ASKED);

// Refusals
check('no name refused', !!refusal(() => a.planLead({ ...base, full_name: ' ' })));
check('no way to reach them refused', !!refusal(() => a.planLead({ ...base, phone: '' })));
check('bad email refused', !!refusal(() => a.planLead({ ...base, email: 'nope' })));
check('bad phone refused', !!refusal(() => a.planLead({ ...base, phone: '12' })));
check('how they reached us is required', !!refusal(() => a.planLead({ ...base, reached_via: '' })));
check('unknown source refused', !!refusal(() => a.planLead({ ...base, heard_from: 'Billboard' })));
check('unknown problem refused', !!refusal(() => a.planLead({ ...base, complaint_type: 'Bad food' })));
check('future flight refused', !!refusal(() => a.planLead({ ...base, flight_date: '2099-01-01' })));
check('impossible date refused', !!refusal(() => a.planLead({ ...base, flight_date: '2026-02-30' })));

// Form mode
const form = a.planLead({ ...base, mode: 'form', airline_name: 'Ignored', message: ' Call me ' });
check('form mode keeps contact only', form.mode === 'form' && !('airline_name' in form.lead));
check('form message trimmed', form.message === 'Call me');

console.log(`\n${passed} passed, ${failed} failed`);
process.exit(failed ? 1 : 0);
