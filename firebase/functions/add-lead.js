/**
 * A lead entered by staff: someone who phoned, sent a WhatsApp or a social
 * media message, or walked in.
 *
 * Staff either type in what the person told them, or take only a name and a
 * phone number or email and send the person the full claim form (an intake
 * request, info-requests.js) to fill in themselves, photos included.
 *
 * The lead records who entered it, from the signed-in account, so it cannot
 * be claimed for someone else. That is separate from who owns the lead: the
 * person entering it owns it unless they leave it for the team.
 */
const { StageError, LEAD } = require('./pipeline');
const { nextActionFor, dueIn } = require('./casework');
const { PROBLEMS } = require('./info-requests');
// Taken from the package, not from `admin`: the Functions emulator wraps
// admin.firestore and drops these from it.
const { FieldValue, Timestamp } = require('firebase-admin/firestore');

/** How the person got in touch, as the lead file shows it. */
const REACHED = ['Phone call', 'WhatsApp', 'Social media message', 'Walk-in', 'Email', 'Other'];

/**
 * Where they heard about us. Kept as the lead's source, which the Links page
 * counts beside the ad links.
 */
const HEARD = [
  'Facebook', 'Instagram', 'X', 'TikTok', 'WhatsApp', 'Google search',
  'Friend or family', 'Radio or TV', 'Other',
];
const NOT_ASKED = 'Entered by staff';

const text = (v) => (typeof v === 'string' ? v.trim() : '');
const oneLine = (v) => text(v).replace(/\s+/g, ' ');

/** A phone number with its country code. A Nigerian 0… number gets +234. */
function cleanPhone(v) {
  const digits = text(v).replace(/[^0-9+]/g, '');
  if (/^0[0-9]{10}$/.test(digits)) return `+234${digits.slice(1)}`;
  if (/^234[0-9]{10}$/.test(digits)) return `+${digits}`;
  return digits;
}

function isDate(v) {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(v)) return false;
  const d = new Date(`${v}T00:00:00Z`);
  return !Number.isNaN(d.getTime()) && d.toISOString().slice(0, 10) === v;
}

/**
 * Check what staff typed. `mode` is 'details' (they typed it all) or 'form'
 * (the client will). Returns the lead's fields; throws a StageError naming
 * the first problem.
 */
function planLead(input) {
  const given = input && typeof input === 'object' ? input : {};
  const mode = given.mode === 'form' ? 'form' : 'details';

  const fullName = oneLine(given.full_name);
  if (fullName.length < 2) throw new StageError(400, 'Give the person\'s name.');
  if (fullName.length > 120) throw new StageError(400, 'Keep the name under 120 characters.');

  const email = text(given.email).toLowerCase();
  if (email && !(/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email) && email.length <= 200)) {
    throw new StageError(400, 'That does not look like an email address.');
  }
  const phone = cleanPhone(given.phone);
  if (phone && !/^\+?[0-9]{7,15}$/.test(phone)) {
    throw new StageError(400, 'That does not look like a phone number. Include the country code, or start a Nigerian number with 0.');
  }
  if (!email && !phone) throw new StageError(400, 'Give a phone number or an email address, so we can reach them.');

  const reached = text(given.reached_via);
  if (!REACHED.includes(reached)) throw new StageError(400, 'Choose how they got in touch.');
  const heard = text(given.heard_from);
  if (heard && !HEARD.includes(heard)) throw new StageError(400, 'Choose where they heard about us from the list.');

  const lead = {
    full_name: fullName,
    email,
    phone,
    medium_of_contact: reached,
    utm_source: heard || NOT_ASKED,
  };
  if (mode === 'form') return { mode, lead, message: text(given.message).slice(0, 1000) };

  const problem = text(given.complaint_type);
  if (problem && !PROBLEMS.includes(problem)) throw new StageError(400, 'Choose what happened from the list.');
  const flightNumber = text(given.flight_number).toUpperCase().replace(/\s+/g, '');
  if (flightNumber && !/^[A-Z0-9]{3,8}$/.test(flightNumber)) throw new StageError(400, 'That does not look like a flight number.');
  const flightDate = text(given.flight_date);
  if (flightDate && (!isDate(flightDate) || flightDate < '2000-01-01' || new Date(`${flightDate}T00:00:00Z`) > new Date(Date.now() + 86400000))) {
    throw new StageError(400, 'That flight date is not possible.');
  }
  const bookingRef = text(given.booking_reference).toUpperCase().replace(/\s+/g, '');
  if (bookingRef && !/^[A-Z0-9]{4,12}$/.test(bookingRef)) throw new StageError(400, 'That does not look like a booking reference.');
  const note = text(given.note);
  if (note.length > 3000) throw new StageError(400, 'Keep the note under 3,000 characters.');
  const fields = {
    complaint_type: problem,
    airline_name: oneLine(given.airline_name).slice(0, 80),
    flight_number: flightNumber,
    flight_date: flightDate,
    route_from: oneLine(given.route_from).slice(0, 60),
    route_to: oneLine(given.route_to).slice(0, 60),
    booking_reference: bookingRef,
    initial_summary: note,
  };
  for (const [k, v] of Object.entries(fields)) if (v) lead[k] = v;
  return { mode, lead };
}

/**
 * Save a lead staff entered. `plan` is from planLead. Returns its id.
 * The confirmation email the website sends to its own leads is skipped:
 * staff have spoken to the person, or are sending them the form.
 */
async function createLead(admin, { staff, plan, own }) {
  const db = admin.firestore();
  const ref = db.collection('leads').doc();
  const ts = FieldValue.serverTimestamp();
  const next = nextActionFor('lead', LEAD.NEW);
  const batch = db.batch();
  batch.set(ref, {
    ...plan.lead,
    claim_type: 'Flight Compensation',
    status: LEAD.NEW,
    is_qualified: false,
    is_contacted: false,
    created_at: ts,
    skip_confirmation: true,
    entered_by_uid: staff.uid,
    entered_by_name: staff.name,
    entry_method: plan.mode === 'form' ? 'staff_form' : 'staff',
    // Older code reads who made a lead from here.
    agent_Ref: db.doc(`users/${staff.uid}`),
    ...(own ? {
      handler_uid: staff.uid,
      handler_name: staff.name,
      handler_assigned_at: ts,
      handler_assigned_by: staff.uid,
      handler_assigned_by_name: staff.name,
    } : {}),
    next_action: next.text,
    next_action_due: Timestamp.fromDate(dueIn(next.days)),
    next_action_set_by: 'system',
    next_action_set_by_name: 'System',
  });
  await batch.commit();
  return ref.id;
}

module.exports = { REACHED, HEARD, NOT_ASKED, cleanPhone, planLead, createLead };
