// What the AI assistant is sent. Plain node:  node ai-tasks.test.js
const t = require('./ai-tasks');

let passed = 0;
let failed = 0;
function check(name, ok) {
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}`);
  ok ? passed++ : failed++;
}

const claim = {
  full_name: 'Tunde Client', airline_name: 'Air Peace', flight_number: 'P47120',
  flight_date: '2026-09-01', departure: 'Lagos', destination: 'Abuja',
  claims_reason: 'Delay', duration_of_delay: '7 hours', pnr_number: 'ABC123',
  fare_paid: 85000, fare_currency: 'NGN', claim_status: 'Awaiting Reply',
  // Everything below must never leave the building.
  bvn_number: '22222222222', NIN: '11111111111', Passport: 'A01234567',
  bank_name: 'GTBank', account_no: '0123456789', account_name: 'Tunde Client',
  client_email: 'tunde@example.com', signature: 'iVBORw0KGgoAAAANSUhEUg', secure_token: 'f'.repeat(64),
  attached_document: ['https://firebasestorage.googleapis.com/v0/b/x/o/claims%2Fc1%2Fevidence%2F1.jpg?alt=media'],
  loa_url: 'https://firebasestorage.googleapis.com/v0/b/x/o/claims%2Fc1%2FLOA.pdf?alt=media',
};
const lead = {
  full_name: 'Ada Lead', email: 'ada@example.com', phone: '+2348000000000',
  airline_name: 'Arik', claim_type: 'Flight cancelled', initial_summary: 'Cancelled at the gate',
  delay_hours: 0, fare_paid: 60000, status: 'New lead',
};

const sent = (task, extra = {}) => JSON.stringify(t.buildMessage(task, { record: task === 'lead_triage' ? lead : claim, ...extra }));

// Nothing sensitive is sent
const brief = sent('case_brief', { events: [] });
for (const [what, value] of [
  ['BVN', '22222222222'], ['NIN', '11111111111'], ['passport number', 'A01234567'],
  ['bank account number', '0123456789'], ['bank name', 'GTBank'], ['email', 'tunde@example.com'],
  ['signature', 'iVBORw0KGgo'], ['client link token', 'ffffffff'], ['document address', 'firebasestorage'],
]) {
  check(`a claim's ${what} is not sent`, !brief.includes(value));
}
const triage = sent('lead_triage');
check('a lead\'s email is not sent', !triage.includes('ada@example.com'));
check('a lead\'s phone number is not sent', !triage.includes('+2348000000000'));

// What is needed is sent
check('the flight facts are sent', brief.includes('P47120') && brief.includes('7 hours') && brief.includes('Air Peace'));
check('the ticket price is sent with its currency', brief.includes('NGN 85000'));
check('documents are described, not linked', brief.includes('1 item(s) of client evidence') && brief.includes('letter of authority'));
check('a lead\'s own account is sent', triage.includes('Cancelled at the gate'));
check('empty facts are left out rather than sent blank', !brief.includes('legal_stage'));

// History
const events = [
  { at: new Date('2026-09-10'), action: 'Stage changed', description: 'Tunde: Demand Pending → Awaiting Reply', note: '' },
  { at: new Date('2026-09-03'), action: 'Claim opened', description: 'Claim opened for Tunde', note: '' },
  { at: new Date('2026-09-20'), action: 'Airline reply recorded', description: '', note: 'Blames weather' },
];
const lines = t.historyLines(events);
check('history is oldest first', lines[0].startsWith('2026-09-03') && lines[2].startsWith('2026-09-20'));
check('history keeps the notes', lines[2].includes('Blames weather'));
check('the brief carries the history', sent('case_brief', { events }).includes('Blames weather'));
check('only the brief carries the history', !sent('classify_reply', { events, pasted: 'We regret the delay was due to weather.' }).includes('Claim opened'));

// Pasted reply and attachments
const reply = t.buildMessage('classify_reply', { record: claim, pasted: 'We regret the delay, which was caused by adverse weather.' });
check('the airline\'s reply is sent as pasted', reply.parts[0].text.includes('adverse weather'));
const withPdf = t.buildMessage('read_evidence', { record: claim, attachment: { contentType: 'application/pdf', base64: 'AAAA' } });
check('a PDF goes as a document, before the text', withPdf.parts[0].inlineData.mimeType === 'application/pdf' && withPdf.parts[0].inlineData.data === 'AAAA' && typeof withPdf.parts[1].text === 'string');
const withPhoto = t.buildMessage('read_evidence', { record: claim, attachment: { contentType: 'image/jpeg', base64: 'AAAA' } });
check('a photo goes as an image', withPhoto.parts[0].inlineData.mimeType === 'image/jpeg');
check('an iPhone photo can be read', t.documentBlock('image/heic', 'AAAA') !== null);
check('a file type that cannot be read is refused', t.documentBlock('video/mp4', 'AAAA') === null && t.documentBlock('image/gif', 'AAAA') === null);

// Shapes
for (const [name, spec] of Object.entries(t.TASKS)) {
  const schema = t.answerSchema(name);
  check(`${name} has a schema the model can be given`,
    schema.type === 'object' && !('$schema' in schema) &&
    JSON.stringify(schema.required) === JSON.stringify(Object.keys(spec.schema.shape)));
}
check('a triage answer in the right shape passes', t.TASKS.lead_triage.schema.safeParse({
  summary: 's', assessment: 'arguable', reasons: [], missing_information: [], suggested_next_step: 'n', draft_message_to_client: '',
}).success);
check('a triage answer with an invented verdict fails', !t.TASKS.lead_triage.schema.safeParse({
  summary: 's', assessment: 'definitely', reasons: [], missing_information: [], suggested_next_step: 'n', draft_message_to_client: '',
}).success);

// The standing instructions
check('the assistant is told not to state amounts', /Do not state an amount of compensation/.test(t.SYSTEM));
check('the assistant is told not to threaten court or promise fees', /do not threaten court proceedings/.test(t.SYSTEM) && /will pay court fees/.test(t.SYSTEM));
check('the rates match the calculator', /25% on a domestic flight and 30% on an international/.test(t.SYSTEM) && /30% of the ticket price domestic or 50% international/.test(t.SYSTEM));

// Cost
const in2026 = new Date('2026-10-02');
check('cost is input and output at list price', t.estimateCost({ input_tokens: 1000000, output_tokens: 1000000 }, in2026) === 4.5);
check('a typical run costs under a cent', t.estimateCost({ input_tokens: 2500, output_tokens: 1500 }, in2026) === 0.0075);
check('the price rise on 1 January 2027 is applied', t.estimateCost({ input_tokens: 1000000, output_tokens: 1000000 }, new Date('2027-01-01T00:00:00Z')) === 9);

console.log(`\n${passed} passed, ${failed} failed`);
process.exit(failed ? 1 : 0);
