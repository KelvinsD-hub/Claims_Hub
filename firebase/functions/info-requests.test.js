// Requests for information: the checks. Plain node:  node info-requests.test.js
const r = require('./info-requests');
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

// Asking
const plan = r.planRequest({ items: ['flight_number', 'boarding_pass', 'flight_number'], questions: [' Who told you? ', ''], message: ' Thanks ' });
check('items deduplicated', plan.items.join() === 'flight_number,boarding_pass');
check('blank questions dropped, others trimmed', plan.questions.length === 1 && plan.questions[0] === 'Who told you?');
check('message trimmed', plan.message === 'Thanks');
check('asking for nothing is refused', !!refusal(() => r.planRequest({ items: [], questions: [] })));
check('an unknown item is refused', !!refusal(() => r.planRequest({ items: ['bank_pin'] })));
check('four questions are refused', !!refusal(() => r.planRequest({ questions: ['a', 'b', 'c', 'd'] })));

// Answering
const request = { items: ['flight_number', 'flight_date', 'booking_reference', 'fare', 'boarding_pass'], questions: ['Who told you?'] };
const good = {
  answers: {
    flight_number: 'p4 7120', flight_date: '2026-09-30', booking_reference: 'abc123',
    fare: { amount: '85000', currency: 'ngn' },
  },
  replies: ['The gate agent'],
};
const files = [{ item: 'boarding_pass', name: 'bp.jpg' }];
const out = r.checkAnswers(request, good, files);
check('flight number cleaned', out.values.flight_number === 'P47120');
check('booking reference cleaned', out.values.booking_reference === 'ABC123');
check('fare as number and currency', out.values.fare.amount === 85000 && out.values.fare.currency === 'NGN');
check('replies kept in order', out.replies[0] === 'The gate agent');
check('a missing file is refused', !!refusal(() => r.checkAnswers(request, good, [])));
check('a file item can be marked as not held', (() => {
  const x = r.checkAnswers(request, { ...good, answers: { ...good.answers, boarding_pass: { unavailable: true, reason: 'Lost it' } } }, []);
  return x.unavailable.boarding_pass === 'Lost it';
})());
check('an unanswered question is refused', !!refusal(() => r.checkAnswers(request, { ...good, replies: [] }, files)));
check('a bad flight number is refused', !!refusal(() => r.checkAnswers(request, { ...good, answers: { ...good.answers, flight_number: '!' } }, files)));
check('an impossible date is refused', !!refusal(() => r.checkAnswers(request, { ...good, answers: { ...good.answers, flight_date: '2026-02-30' } }, files)));
check('a future flight date is refused', !!refusal(() => r.checkAnswers(request, { ...good, answers: { ...good.answers, flight_date: '2999-01-01' } }, files)));
check('a zero fare is refused', !!refusal(() => r.checkAnswers(request, { ...good, answers: { ...good.answers, fare: { amount: 0, currency: 'NGN' } } }, files)));
check('an unknown currency is refused', !!refusal(() => r.checkAnswers(request, { ...good, answers: { ...good.answers, fare: { amount: 5, currency: 'XYZ' } } }, files)));

// Where answers go
const onClaim = r.recordUpdates('claim', { booking_reference: 'ABC123', phone: '+2348000000000', fare: { amount: 5, currency: 'NGN' } });
check('a claim keeps the booking reference in pnr_number', onClaim.record.pnr_number === 'ABC123');
check('a claim\'s phone number goes to its lead', onClaim.lead.phone === '+2348000000000' && !('phone' in onClaim.record));
check('the fare goes in two fields', onClaim.record.fare_paid === 5 && onClaim.record.fare_currency === 'NGN');
const onLead = r.recordUpdates('lead', { booking_reference: 'ABC123', phone: '+2348000000000' });
check('a lead keeps its own fields', onLead.record.booking_reference === 'ABC123' && onLead.record.phone === '+2348000000000');

// Files
check('storage name is safe', r.storageName('abcdef0123456789', 2, '../my pass?.JPG', 'image/jpeg', 'x') === 'request-abcdef0123-2x-my-pass.jpg');
check('two names for the same slot differ', r.storageName('a', 1, 'f', 'image/png') !== r.storageName('a', 1, 'f', 'image/png'));
check('extension follows the type, not the name', r.storageName('abcdef0123456789', 1, 'x.exe', 'application/pdf').endsWith('.pdf'));

// Status
const later = { toMillis: () => Date.now() + 1000 };
const past = { toMillis: () => Date.now() - 1000 };
check('open', r.requestStatus({ status: 'open', expires_at: later }) === 'open');
check('expired', r.requestStatus({ status: 'open', expires_at: past }) === 'expired');
check('answered stays answered', r.requestStatus({ status: 'answered', expires_at: later }) === 'answered');
check('missing', r.requestStatus(null) === 'missing');

// Email
const mail = r.requestEmail({ name: 'Ada <b>Obi</b>', link: 'https://claimsassistltd.com/more-info?t=x', items: ['boarding_pass'], questions: ['q'], message: '<script>', expiresAt: '2026-10-17T00:00:00Z' },
  (v) => String(v).replace(/</g, '&lt;'));
check('email escapes the client name and message', !mail.html.includes('<b>') && !mail.html.includes('<script>'));
check('email lists what is asked', mail.text.includes('- Boarding pass') && mail.text.includes('answers to 1 question'));

// The full claim form, sent with a new lead
const known = r.intakeItems({ email: 'a@b.co', phone: '' });
check('intake skips what the lead has', !known.includes('email') && known.includes('phone'));
check('intake asks for photos of ID and boarding pass', known.includes('id_document') && known.includes('boarding_pass'));
check('intake items are all known', r.planRequest({ items: r.INTAKE_ITEMS }).items.length === r.INTAKE_ITEMS.length);
const intake = { items: ['what_happened', 'airline', 'route_from', 'route_to', 'story', 'email'], questions: [] };
const told = {
  what_happened: 'Flight cancellation', airline: ' Air  Peace ', route_from: 'Lagos', route_to: 'Abuja',
  story: 'Cancelled at the gate, no food or hotel offered.', email: ' Ada@Example.COM ',
};
const took = r.checkAnswers(intake, { answers: told }, []);
check('intake answers cleaned', took.values.airline === 'Air Peace' && took.values.email === 'ada@example.com');
check('a problem not on the list is refused', !!refusal(() => r.checkAnswers(intake, { answers: { ...told, what_happened: 'Lost my hat' } }, [])));
check('what happened cannot be skipped', !!refusal(() => r.checkAnswers(intake, { answers: { ...told, what_happened: { unavailable: true } } }, [])));
check('a missing airline says so', /airline/.test((refusal(() => r.checkAnswers(intake, { answers: { ...told, airline: '' } }, [])) || {}).message));
const intoLead = r.recordUpdates('lead', took.values);
check('intake answers land on the lead fields', intoLead.record.complaint_type === 'Flight cancellation' && intoLead.record.route_to === 'Abuja' && intoLead.record.disruption_details.startsWith('Cancelled'));
const intakeMail = r.requestEmail({ name: 'Ada', link: 'https://x', items: r.INTAKE_ITEMS, questions: [], message: '', expiresAt: '2026-10-17T00:00:00Z', intake: true }, (v) => v);
check('intake email starts a claim', intakeMail.subject.startsWith('Start your flight claim') && intakeMail.html.includes('Start my claim'));

// Bank details
const askBank = { items: ['bank_details'], questions: [] };
const bankIn = { answers: { bank_details: { bank_name: ' Zenith  Bank ', account_name: 'Ada Obi', account_number: '01234 56789' } } };
const bankOut = r.checkAnswers(askBank, bankIn, []);
check('bank details cleaned', bankOut.values.bank_details.bank_name === 'Zenith Bank' && bankOut.values.bank_details.account_number === '0123456789');
check('a 9-digit account number is refused', /10 digits/.test((refusal(() => r.checkAnswers(askBank, { answers: { bank_details: { bank_name: 'Zenith Bank', account_name: 'Ada Obi', account_number: '012345678' } } }, [])) || {}).message));
check('part of an account is refused', !!refusal(() => r.checkAnswers(askBank, { answers: { bank_details: { bank_name: 'Zenith Bank', account_name: '', account_number: '0123456789' } } }, [])));
check('bank details can be marked as not held', r.checkAnswers(askBank, { answers: { bank_details: { unavailable: true, reason: 'Later' } } }, []).unavailable.bank_details === 'Later');
const bankRecord = r.recordUpdates('claim', { bank_details: { bank_name: 'Zenith Bank', account_name: 'Ada Obi', account_no: 'iv:cipher' } });
check('bank details land on the CRM fields', bankRecord.record.bank_name === 'Zenith Bank' && bankRecord.record.account_name === 'Ada Obi' && bankRecord.record.account_no === 'iv:cipher' && bankRecord.record.bank_details_pending === false);
check('the full claim form asks for bank details', r.INTAKE_ITEMS.includes('bank_details'));

const pii = require('./pii');
const KEY = '0123456789abcdef0123456789abcdef';
const sealed = pii.encryptPii('0123456789', KEY);
check('account number encrypts in the app format', /^[A-Za-z0-9+/=]+:[A-Za-z0-9+/=]+$/.test(sealed) && !sealed.includes('0123456789'));
check('and opens again with the same key', pii.decryptPii(sealed, KEY) === '0123456789');
check('no key, no ciphertext', pii.encryptPii('0123456789', '') === '');

console.log(`\n${passed} passed, ${failed} failed`);
process.exit(failed ? 1 : 0);
