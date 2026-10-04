/**
 * Asking a client for more information.
 *
 * Staff tick what is missing on a lead or a claim, and may add questions of
 * their own. The client is sent a link to a short form on the website that
 * asks for exactly that; what they send is written straight onto the record,
 * so nobody retypes it, and the record's next action becomes reviewing it.
 *
 * The link carries a random token. Only its SHA-256 is stored (as the
 * request's document id), the same as staff invites. A link lasts
 * REQUEST_DAYS, works until it is answered, and is closed when staff cancel
 * it or send a newer request on the same record. The database rules refuse
 * every client write on `info_requests`; staff read them.
 */
const crypto = require('crypto');
const { StageError } = require('./pipeline');
const { dueIn } = require('./casework');
// Taken from the package, not from `admin`: the Functions emulator wraps
// admin.firestore and drops these from it.
const { FieldValue, Timestamp } = require('firebase-admin/firestore');

const REQUEST_DAYS = 14;
const CHASE_DAYS = 5;
const SITE_URL = 'https://claimsassistltd.com';
const MAX_QUESTIONS = 3;
// Room for a whole intake: ID, boarding pass, ticket, messages and receipts.
const MAX_FILES = 12;
const MAX_FILE_BYTES = 6 * 1024 * 1024;
const FILE_TYPES = ['image/jpeg', 'image/png', 'image/webp', 'application/pdf'];
const CURRENCIES = ['NGN', 'USD', 'GBP', 'EUR', 'CAD'];

const hashToken = (token) => crypto.createHash('sha256').update(String(token)).digest('hex');
const requestLink = (token) => `${SITE_URL}/more-info?t=${token}`;
const text = (v) => (typeof v === 'string' ? v.trim() : '');
const upper = (v) => text(v).toUpperCase().replace(/\s+/g, '');

function isDate(v) {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(v)) return false;
  const d = new Date(`${v}T00:00:00Z`);
  return !Number.isNaN(d.getTime()) && d.toISOString().slice(0, 10) === v;
}

function pastDate(v, what) {
  if (!isDate(v)) return `Give the ${what} as a date.`;
  if (v < '1900-01-01' || new Date(`${v}T00:00:00Z`) > new Date()) return `That ${what} is not possible.`;
  return null;
}

/** What went wrong, in the website's words, so both kinds of lead read alike. */
const PROBLEMS = [
  'Flight delay', 'Flight cancellation', 'Denied boarding', 'Missed connection',
  'Downgrade', 'Baggage claim', 'Something else',
];

const place = (v) => text(v).replace(/\s+/g, ' ');
const checkPlace = (v) => (v.length >= 2 && v.length <= 60 ? null : 'Give the airport or city.');

/**
 * What staff can ask for. `fields` names where an answer goes on a lead and
 * on a claim; a file item stores files instead. `check` returns an error
 * message, or null when the answer will do. An `always` item cannot be
 * answered "I don't have this": the claim cannot start without it.
 */
const ITEMS = {
  what_happened: {
    label: 'What happened',
    ask: 'What went wrong with your flight?',
    type: 'choice',
    options: PROBLEMS,
    always: true,
    fields: { lead: 'complaint_type', claim: 'claims_reason' },
    clean: text,
    check: (v) => (PROBLEMS.includes(v) ? null : 'Choose what happened.'),
  },
  airline: {
    label: 'Airline',
    ask: 'The airline you flew with, or were booked with.',
    type: 'text',
    always: true,
    fields: { lead: 'airline_name', claim: 'airline_name' },
    clean: place,
    check: (v) => (v.length >= 2 && v.length <= 80 ? null : 'Give the airline\'s name.'),
  },
  route_from: {
    label: 'Flying from',
    ask: 'The airport or city the flight left from (for example Lagos).',
    type: 'text',
    always: true,
    fields: { lead: 'route_from', claim: 'departure' },
    clean: place,
    check: checkPlace,
  },
  route_to: {
    label: 'Flying to',
    ask: 'Where the flight was going (for example Abuja).',
    type: 'text',
    always: true,
    fields: { lead: 'route_to', claim: 'destination' },
    clean: place,
    check: checkPlace,
  },
  flight_number: {
    label: 'Flight number',
    ask: 'Your flight number, as it appears on your ticket or boarding pass (for example P4 7120).',
    type: 'text',
    fields: { lead: 'flight_number', claim: 'flight_number' },
    clean: upper,
    check: (v) => (/^[A-Z0-9]{3,8}$/.test(v) ? null : 'That does not look like a flight number.'),
  },
  flight_date: {
    label: 'Flight date',
    ask: 'The date the flight was due to leave.',
    type: 'date',
    fields: { lead: 'flight_date', claim: 'flight_date' },
    clean: text,
    check: (v) => pastDate(v, 'flight date'),
  },
  booking_reference: {
    label: 'Booking reference',
    ask: 'Your booking reference (also called PNR), usually 6 letters and numbers.',
    type: 'text',
    fields: { lead: 'booking_reference', claim: 'pnr_number' },
    clean: upper,
    check: (v) => (/^[A-Z0-9]{4,12}$/.test(v) ? null : 'That does not look like a booking reference.'),
  },
  fare: {
    label: 'Ticket price',
    ask: 'What you paid for this flight, for one passenger, as on your ticket or receipt.',
    type: 'money',
    fields: { lead: 'fare_paid', claim: 'fare_paid' },
  },
  date_of_birth: {
    label: 'Date of birth',
    ask: 'Your date of birth.',
    type: 'date',
    fields: { lead: 'date_of_birth', claim: 'date_of_birth' },
    clean: text,
    check: (v) => pastDate(v, 'date of birth'),
  },
  address: {
    label: 'Home address',
    ask: 'Your home address, including town or city.',
    type: 'text',
    fields: { lead: 'address', claim: 'address' },
    clean: (v) => text(v).replace(/\s+/g, ' '),
    check: (v) => (v.length >= 8 && v.length <= 300 ? null : 'Give your full address.'),
  },
  phone: {
    label: 'Phone number',
    ask: 'A phone number we can reach you on, with the country code.',
    type: 'text',
    // A claim reads the phone number from its lead, so it is written there.
    fields: { lead: 'phone', claim: 'lead:phone' },
    clean: (v) => text(v).replace(/[^0-9+]/g, ''),
    check: (v) => (/^\+?[0-9]{7,15}$/.test(v) ? null : 'That does not look like a phone number.'),
  },
  email: {
    label: 'Email address',
    ask: 'An email address for updates on your claim.',
    type: 'text',
    fields: { lead: 'email', claim: 'client_email' },
    clean: (v) => text(v).toLowerCase(),
    check: (v) => (/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(v) && v.length <= 200 ? null : 'That does not look like an email address.'),
  },
  story: {
    label: 'In your words',
    ask: 'Tell us what happened: how long you waited, what the airline said, and anything you had to pay for.',
    type: 'long',
    always: true,
    fields: { lead: 'disruption_details', claim: 'lead:disruption_details' },
    clean: (v) => text(v).replace(/\r\n/g, '\n'),
    check: (v) => (v.length >= 10 ? (v.length <= 3000 ? null : 'Keep it under 3,000 characters.') : 'Tell us a little more about what happened.'),
  },
  boarding_pass: {
    label: 'Boarding pass',
    ask: 'A photo or PDF of your boarding pass.',
    type: 'file',
  },
  ticket_receipt: {
    label: 'Ticket or receipt',
    ask: 'Your e-ticket, booking confirmation or payment receipt.',
    type: 'file',
  },
  id_document: {
    label: 'Photo ID',
    ask: 'A clear photo of your passport, national ID card (NIN) or driver\'s licence.',
    type: 'file',
  },
  airline_message: {
    label: 'Airline message',
    ask: 'Any email, text or letter the airline sent you about the disruption.',
    type: 'file',
  },
  expense_receipts: {
    label: 'Expense receipts',
    ask: 'Receipts for anything you had to pay for because of the disruption (food, hotel, transport).',
    type: 'file',
  },
};

/**
 * Everything a claim needs, for a lead staff have only a name and a number
 * for: the client fills in the whole form themselves. In the order the form
 * asks; what the lead already has (email, phone) is left out.
 */
const INTAKE_ITEMS = [
  'what_happened', 'airline', 'route_from', 'route_to', 'flight_number', 'flight_date',
  'booking_reference', 'story', 'fare', 'email', 'phone', 'date_of_birth', 'address',
  'id_document', 'boarding_pass', 'ticket_receipt', 'airline_message', 'expense_receipts',
];

function intakeItems(lead) {
  return INTAKE_ITEMS.filter((k) => !(k === 'email' && text(lead.email)) && !(k === 'phone' && text(lead.phone)));
}

/** Where a request stands: open, answered, cancelled, replaced, expired, or missing. */
function requestStatus(request, now = Date.now()) {
  if (!request) return 'missing';
  if (request.status && request.status !== 'open') return request.status;
  const expires = request.expires_at && request.expires_at.toMillis ? request.expires_at.toMillis() : 0;
  return expires < now ? 'expired' : 'open';
}

const CLOSED_MESSAGES = {
  missing: 'This link is not valid. Check you copied all of it, or reply to our email and we will send a new one.',
  answered: 'Thank you, we already have your answers. We will be in touch if we need anything else.',
  cancelled: 'This request was withdrawn, so there is nothing to send. Reply to our email if you have a question.',
  replaced: 'We sent you a newer link for this claim. Please use the most recent email from us.',
  expired: 'This link has expired. Reply to our email and we will send you a new one.',
};

/** Check what staff want to ask. Returns the cleaned request. */
function planRequest({ items, questions, message }) {
  const keys = [...new Set((Array.isArray(items) ? items : []).map(String))];
  const unknown = keys.filter((k) => !ITEMS[k]);
  if (unknown.length) throw new StageError(400, `Unknown item: ${unknown.join(', ')}.`);
  const asked = (Array.isArray(questions) ? questions : []).map(text).filter(Boolean);
  if (asked.length > MAX_QUESTIONS) throw new StageError(400, `Ask at most ${MAX_QUESTIONS} questions of your own.`);
  if (asked.some((q) => q.length > 300)) throw new StageError(400, 'Keep each question under 300 characters.');
  if (!keys.length && !asked.length) throw new StageError(400, 'Tick at least one thing to ask for, or write a question.');
  const note = text(message);
  if (note.length > 1000) throw new StageError(400, 'Keep the message under 1,000 characters.');
  return { items: keys, questions: asked, message: note };
}

/**
 * Check a client's answers against what was asked. `answers` is
 * { [item]: value | { amount, currency } | { unavailable: true, reason } },
 * `replies` the answers to staff questions in order. `files` is what was
 * uploaded already. Returns { values, unavailable, replies } with values
 * cleaned; throws a StageError naming the first problem.
 */
function checkAnswers(request, { answers, replies }, files) {
  const given = answers && typeof answers === 'object' ? answers : {};
  const values = {};
  const unavailable = {};
  for (const key of request.items) {
    const item = ITEMS[key];
    const answer = given[key];
    if (answer && typeof answer === 'object' && answer.unavailable === true) {
      if (item.always) throw new StageError(400, `We need the ${item.label.toLowerCase()} to start your claim.`);
      const reason = text(answer.reason);
      if (reason.length > 500) throw new StageError(400, `Keep the note about the ${item.label.toLowerCase()} short.`);
      unavailable[key] = reason;
      continue;
    }
    if (item.type === 'file') {
      if (!files.some((f) => f.item === key)) {
        throw new StageError(400, `Add your ${item.label.toLowerCase()}, or tick that you do not have it.`);
      }
      continue;
    }
    if (item.type === 'money') {
      const amount = Number(answer && answer.amount);
      const currency = text(answer && answer.currency).toUpperCase();
      if (!(amount > 0 && amount < 1e9)) throw new StageError(400, 'Give the ticket price as a number.');
      if (!CURRENCIES.includes(currency)) throw new StageError(400, 'Choose the currency you paid in.');
      values[key] = { amount: Math.round(amount * 100) / 100, currency };
      continue;
    }
    const value = item.clean(answer);
    if (!value) {
      // An `always` item's own check says what is missing.
      throw new StageError(400, item.always
        ? item.check(value)
        : `Give your ${item.label.toLowerCase()}, or tick that you do not have it.`);
    }
    const problem = item.check(value);
    if (problem) throw new StageError(400, problem);
    values[key] = value;
  }
  const said = (Array.isArray(replies) ? replies : []).map(text);
  const answered = request.questions.map((_, i) => said[i] || '');
  if (answered.some((a) => !a)) throw new StageError(400, 'Answer each of our questions. "I don\'t know" is fine.');
  if (answered.some((a) => a.length > 2000)) throw new StageError(400, 'Keep each answer under 2,000 characters.');
  return { values, unavailable, replies: answered };
}

/**
 * What the answers change. Returns { record, lead } field updates; `lead` is
 * for a claim's lead, where the phone number lives.
 */
function recordUpdates(kind, values) {
  const record = {};
  const lead = {};
  for (const [key, value] of Object.entries(values)) {
    const field = ITEMS[key].fields[kind];
    if (key === 'fare') {
      record.fare_paid = value.amount;
      record.fare_currency = value.currency;
    } else if (field.startsWith('lead:')) {
      lead[field.slice(5)] = value;
    } else {
      record[field] = value;
    }
  }
  return { record, lead };
}

/** A safe storage file name for an upload. */
function storageName(requestId, n, name, type, unique = crypto.randomBytes(3).toString('hex')) {
  const ext = { 'image/jpeg': 'jpg', 'image/png': 'png', 'image/webp': 'webp', 'application/pdf': 'pdf' }[type];
  const base = String(name || 'file').replace(/\.[^.]*$/, '').replace(/[^A-Za-z0-9_]+/g, '-').replace(/^-+|-+$/g, '').slice(0, 40) || 'file';
  // `unique` keeps two uploads at the same moment from taking the same name.
  return `request-${requestId.slice(0, 10)}-${n}${unique}-${base}.${ext}`;
}

/** The record a request is about, as { ref, data, kind }. */
async function loadRecord(db, tx, kind, id) {
  if (kind !== 'lead' && kind !== 'claim') throw new StageError(400, 'Unknown record type.');
  if (!/^[A-Za-z0-9_-]{1,128}$/.test(String(id || ''))) throw new StageError(400, 'Invalid record id.');
  const ref = db.doc(`${kind === 'lead' ? 'leads' : 'claims'}/${id}`);
  const snap = await tx.get(ref);
  if (!snap.exists) throw new StageError(404, `That ${kind} no longer exists.`);
  return { ref, data: snap.data() };
}

const clientEmailOf = (kind, data) => text(kind === 'lead' ? data.email : (data.client_email || data.email));

/**
 * Ask the client of a lead or claim for more information. Closes any open
 * request on the same record. Returns { id, token, link, expiresAt, email,
 * name, items, questions, message }; the token is never stored.
 */
async function createRequest(admin, { staff, kind, id, items, questions, message, intake = false, emailOptional = false }) {
  if (intake && kind !== 'lead') throw new StageError(400, 'Only a lead can be sent the full form.');
  // An intake's items depend on what the lead already has, so it is planned
  // once the lead is read.
  let plan = intake ? null : planRequest({ items, questions, message });
  const db = admin.firestore();
  const token = crypto.randomBytes(24).toString('base64url');
  const requestId = hashToken(token);
  const expiresAt = new Date(Date.now() + REQUEST_DAYS * 86400000);
  const ts = FieldValue.serverTimestamp();

  return db.runTransaction(async (tx) => {
    const { ref, data } = await loadRecord(db, tx, kind, id);
    const email = clientEmailOf(kind, data);
    // Without an email the link can still go by WhatsApp or text.
    if (!email && !emailOptional) throw new StageError(409, 'This record has no email address for the client. Add one first.');
    if (intake) plan = planRequest({ items: intakeItems(data), questions: [], message });
    const open = await tx.get(db.collection('info_requests')
      .where('record', '==', ref).where('status', '==', 'open'));

    open.forEach((d) => tx.update(d.ref, { status: 'replaced', closed_at: ts, closed_by: staff.uid }));
    tx.set(db.doc(`info_requests/${requestId}`), {
      kind,
      record: ref,
      ...(kind === 'claim' && data.lead_ref ? { lead_ref: data.lead_ref } : {}),
      client_email: email,
      client_name: text(data.full_name),
      items: plan.items,
      questions: plan.questions,
      message: plan.message,
      ...(intake ? { intake: true } : {}),
      created_by: staff.uid,
      created_by_name: staff.name,
      created_at: ts,
      expires_at: Timestamp.fromDate(expiresAt),
      status: 'open',
      files: [],
    });
    const asked = [...plan.items.map((k) => ITEMS[k].label), ...plan.questions.map((q) => `"${q}"`)];
    tx.update(ref, {
      info_request_open: true,
      info_request_sent_at: ts,
      next_action: intake ? 'Chase the client to fill in the claim form' : 'Chase the client for the information asked for',
      next_action_due: Timestamp.fromDate(dueIn(CHASE_DAYS)),
      next_action_set_by: 'system',
      next_action_set_by_name: 'System',
    });
    tx.set(db.collection('activity_logs').doc(), {
      entityType: kind === 'lead' ? 'Lead' : 'Claim',
      ...(kind === 'lead' ? { leadRef: ref } : { claims: ref, ...(data.lead_ref ? { leadRef: data.lead_ref } : {}) }),
      action: intake ? 'Claim form sent' : 'Information requested',
      description: intake
        ? `${staff.name} sent the client the full claim form`
        : `${staff.name} asked the client for: ${asked.join(', ')}`,
      performedBy: db.doc(`users/${staff.uid}`),
      performedByName: staff.name,
      actor_type: 'staff',
      createdAt: ts,
    });
    return {
      id: requestId,
      token,
      link: requestLink(token),
      expiresAt: expiresAt.toISOString(),
      email,
      name: text(data.full_name),
      intake,
      ...plan,
    };
  });
}

/** Withdraw an open request so its link stops working. */
async function cancelRequest(admin, { staff, id }) {
  if (!/^[0-9a-f]{64}$/.test(String(id || ''))) throw new StageError(400, 'Invalid request.');
  const db = admin.firestore();
  const ref = db.doc(`info_requests/${id}`);
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const request = snap.exists ? snap.data() : null;
    const status = requestStatus(request);
    if (status === 'missing') throw new StageError(404, 'That request no longer exists.');
    if (status !== 'open' && status !== 'expired') throw new StageError(409, 'That request is already closed.');
    const ts = FieldValue.serverTimestamp();
    tx.update(ref, { status: 'cancelled', closed_at: ts, closed_by: staff.uid });
    tx.update(request.record, { info_request_open: false });
    tx.set(db.collection('activity_logs').doc(), {
      entityType: request.kind === 'lead' ? 'Lead' : 'Claim',
      ...(request.kind === 'lead' ? { leadRef: request.record } : { claims: request.record }),
      action: 'Information request withdrawn',
      description: `${staff.name} withdrew the request for information`,
      performedBy: db.doc(`users/${staff.uid}`),
      performedByName: staff.name,
      actor_type: 'staff',
      createdAt: ts,
    });
    return { cancelled: true };
  });
}

/** What the website form shows for a link. Details only while it is open. */
async function requestInfo(admin, { token }) {
  const db = admin.firestore();
  const snap = await db.doc(`info_requests/${hashToken(token)}`).get();
  const request = snap.exists ? snap.data() : null;
  const status = requestStatus(request);
  if (status !== 'open') return { status, message: CLOSED_MESSAGES[status] };
  const record = (await request.record.get()).data() || {};
  const route = [text(record.route_from || record.departure), text(record.route_to || record.destination)];
  return {
    status,
    intake: request.intake === true,
    firstName: text(request.client_name).split(' ')[0] || '',
    flight: {
      airline: text(record.airline_name),
      route: route.every(Boolean) ? `${route[0]} to ${route[1]}` : '',
      number: text(record.flight_number),
      date: text(record.flight_date),
    },
    items: request.items.map((key) => ({
      key,
      label: ITEMS[key].label,
      ask: ITEMS[key].ask,
      type: ITEMS[key].type,
      ...(ITEMS[key].options ? { options: ITEMS[key].options } : {}),
      ...(ITEMS[key].always ? { always: true } : {}),
    })),
    questions: request.questions,
    message: request.message,
    askedBy: request.created_by_name || '',
    expiresAt: request.expires_at.toDate().toISOString(),
    files: (request.files || []).map((f) => ({ item: f.item, name: f.name })),
    currencies: CURRENCIES,
    maxFiles: MAX_FILES,
    maxFileBytes: MAX_FILE_BYTES,
    fileTypes: FILE_TYPES,
  };
}

/**
 * Store one file for an open request. `data` is base64. The file is saved
 * beside the record's other documents, with no download token: staff open
 * it through staffDocument.
 */
async function uploadFile(admin, { token, item, name, type, data }) {
  const db = admin.firestore();
  const requestId = hashToken(token);
  const ref = db.doc(`info_requests/${requestId}`);
  const snap = await ref.get();
  const request = snap.exists ? snap.data() : null;
  const status = requestStatus(request);
  if (status !== 'open') throw new StageError(status === 'missing' ? 404 : 409, CLOSED_MESSAGES[status]);
  if (!request.items.includes(item) || ITEMS[item].type !== 'file') throw new StageError(400, 'We did not ask for a file there.');
  if (!FILE_TYPES.includes(type)) throw new StageError(400, 'Send a photo (JPEG, PNG or WebP) or a PDF.');
  const bytes = Buffer.from(String(data || ''), 'base64');
  if (!bytes.length) throw new StageError(400, 'That file is empty.');
  if (bytes.length > MAX_FILE_BYTES) throw new StageError(413, 'That file is too large. Send one under 6 MB.');
  if ((request.files || []).length >= MAX_FILES) throw new StageError(409, `You can send up to ${MAX_FILES} files. Email us if you have more.`);

  const folder = `${request.kind === 'lead' ? 'leads' : 'claims'}/${request.record.id}/evidence`;
  const path = `${folder}/${storageName(requestId, (request.files || []).length + 1, name, type)}`;
  await admin.storage().bucket().file(path).save(bytes, {
    contentType: type,
    resumable: false,
    metadata: { metadata: { info_request: requestId, item } },
  });
  const entry = {
    item,
    name: String(name || 'file').slice(0, 120),
    path,
    type,
    size: bytes.length,
    at: new Date(),
  };
  await ref.update({ files: FieldValue.arrayUnion(entry) });
  return { name: entry.name, item };
}

/**
 * Take the client's answers. Writes them onto the record (and a claim's lead
 * for the phone number), adds the files to the record's documents, closes
 * the request and makes reviewing it the record's next action, together.
 * Returns what the staff email needs.
 */
async function submitAnswers(admin, { token, answers, replies, bucketName, storedAddress }) {
  const db = admin.firestore();
  const ref = db.doc(`info_requests/${hashToken(token)}`);
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const request = snap.exists ? snap.data() : null;
    const status = requestStatus(request);
    if (status !== 'open') throw new StageError(status === 'missing' ? 404 : 409, CLOSED_MESSAGES[status]);
    const files = request.files || [];
    const checked = checkAnswers(request, { answers, replies }, files);
    const recordSnap = await tx.get(request.record);
    if (!recordSnap.exists) throw new StageError(404, 'This claim is no longer open. Reply to our email if you have a question.');
    const record = recordSnap.data();
    const leadRef = request.kind === 'claim' ? record.lead_ref : null;
    const { record: recordUpdate, lead: leadUpdate } = recordUpdates(request.kind, checked.values);
    // A claim opened by hand has no lead to hold the phone number.
    if (!leadRef && leadUpdate.phone) recordUpdate.client_phone = leadUpdate.phone;

    const previous = {};
    for (const field of Object.keys(recordUpdate)) previous[field] = record[field] === undefined ? null : record[field];
    const ts = FieldValue.serverTimestamp();
    const documents = files.map((f) => storedAddress(bucketName, f.path));

    tx.update(request.record, {
      ...recordUpdate,
      ...(documents.length ? { attached_document: FieldValue.arrayUnion(...documents) } : {}),
      info_request_open: false,
      info_request_answered_at: ts,
      next_action: 'Review the information the client sent',
      next_action_due: Timestamp.fromDate(dueIn(0)),
      next_action_set_by: 'system',
      next_action_set_by_name: 'System',
    });
    if (leadRef && Object.keys(leadUpdate).length) tx.update(leadRef, leadUpdate);
    tx.update(ref, {
      status: 'answered',
      answered_at: ts,
      answers: checked.values,
      unavailable: checked.unavailable,
      replies: checked.replies,
      previous,
    });
    const sent = [
      ...Object.keys(checked.values).map((k) => ITEMS[k].label),
      ...[...new Set(files.map((f) => f.item))].map((k) => `${ITEMS[k].label} (${files.filter((f) => f.item === k).length} file${files.filter((f) => f.item === k).length === 1 ? '' : 's'})`),
      ...(checked.replies.length ? [`answers to ${checked.replies.length} question${checked.replies.length === 1 ? '' : 's'}`] : []),
    ];
    const missing = Object.keys(checked.unavailable).map((k) => ITEMS[k].label);
    tx.set(db.collection('activity_logs').doc(), {
      entityType: request.kind === 'lead' ? 'Lead' : 'Claim',
      ...(request.kind === 'lead' ? { leadRef: request.record } : { claims: request.record, ...(leadRef ? { leadRef } : {}) }),
      action: request.intake ? 'Client filled in the claim form' : 'Client sent information',
      description: `Client sent: ${sent.join(', ') || 'nothing'}${missing.length ? `. Does not have: ${missing.join(', ')}` : ''}`,
      performedByName: request.client_name || 'Client',
      actor_type: 'client',
      createdAt: ts,
    });
    return {
      kind: request.kind,
      intake: request.intake === true,
      recordId: request.record.id,
      clientName: request.client_name || 'The client',
      handlerUid: text(record.handler_uid),
      askedByUid: request.created_by,
      sent,
      missing,
    };
  });
}

/** The email that carries the link to the client. */
function requestEmail({ name, link, items, questions, message, expiresAt, intake = false }, escapeHtml) {
  const first = text(name).split(' ')[0] || 'there';
  // The full form asks for too much to list; it is described instead.
  const asked = intake
    ? ['What happened, and your flight details', 'Your date of birth and address', 'Photos of your ID, boarding pass and ticket, if you have them']
    : [...items.map((k) => ITEMS[k].label), ...(questions.length ? [`answers to ${questions.length} question${questions.length === 1 ? '' : 's'}`] : [])];
  const intro = intake
    ? 'Thank you for speaking with us. To start your claim, please fill in our short form. It asks for:'
    : 'To move your claim forward we need a few more details from you:';
  const until = new Date(expiresAt).toLocaleDateString('en-GB', { day: 'numeric', month: 'long', year: 'numeric', timeZone: 'Africa/Lagos' });
  const subject = intake ? 'Start your flight claim with Claims Assist' : 'Your flight claim: we need a little more information';
  const html = `
    <div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;color:#1f2937">
      <div style="background:#0f1a33;padding:22px 28px;border-radius:8px 8px 0 0">
        <h1 style="color:#fff;margin:0;font-size:20px">Claims Assist</h1>
      </div>
      <div style="padding:28px;border:1px solid #e5e7eb;border-top:none;border-radius:0 0 8px 8px">
        <p>Hello ${escapeHtml(first)},</p>
        <p>${intro}</p>
        <ul>${asked.map((a) => `<li>${escapeHtml(a)}</li>`).join('')}</ul>
        ${message ? `<p style="background:#f8f5ee;padding:12px 14px;border-radius:6px">${escapeHtml(message).replace(/\n/g, '<br/>')}</p>` : ''}
        <p style="text-align:center;margin:28px 0">
          <a href="${link}" style="background:#0f1a33;color:#fff;padding:13px 26px;border-radius:6px;text-decoration:none;font-weight:bold">${intake ? 'Start my claim' : 'Send my details'}</a>
        </p>
        <p style="font-size:13px;color:#6b7280">It takes ${intake ? 'about ten minutes' : 'a couple of minutes'}. You can add photos straight from your phone. This link is personal to you and works until ${escapeHtml(until)}.</p>
        <p style="font-size:13px;color:#6b7280">If the button does not work, copy this address into your browser:<br/><a href="${link}">${link}</a></p>
        <p style="font-size:13px;color:#6b7280">Questions? Just reply to this email.</p>
      </div>
    </div>`;
  const textBody = [
    `Hello ${first},`,
    '',
    intro,
    ...asked.map((a) => `- ${a}`),
    ...(message ? ['', message] : []),
    '',
    `Send them here: ${link}`,
    `The link is personal to you and works until ${until}.`,
    '',
    'Questions? Just reply to this email.',
    'Claims Assist',
  ].join('\n');
  return { subject, html, text: textBody };
}

module.exports = {
  ITEMS, PROBLEMS, INTAKE_ITEMS, REQUEST_DAYS, MAX_FILES, MAX_FILE_BYTES, FILE_TYPES, CURRENCIES,
  hashToken, requestStatus, intakeItems, planRequest, checkAnswers, recordUpdates, storageName,
  createRequest, cancelRequest, requestInfo, uploadFile, submitAnswers, requestEmail,
};
