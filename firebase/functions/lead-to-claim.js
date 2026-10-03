/**
 * What a claim opened from a qualified lead starts with.
 *
 * Written into the claim in the same transaction that opens it, under the
 * claim's own field names, so the demand letter (which refuses to send
 * without flight number, date and route) and the flight counters see them
 * from the first moment. The website's onClaimCreatedCopyLoa trigger then adds
 * the signed authority and the rest; it never overwrites what is here.
 *
 * Pure: no Firestore, so it can be tested with plain node.
 */

function text(value) {
  return typeof value === 'string' ? value.trim() : '';
}

/** Claim fields from a lead's data. Empty values are left out, not blanked. */
function claimFieldsFromLead(lead) {
  const out = {};
  const put = (field, value) => { if (value) out[field] = value; };

  put('client_email', text(lead.email));
  put('full_name', text(lead.full_name));
  put('airline_name', text(lead.airline_name));
  put('flight_number', text(lead.flight_number).toUpperCase().replace(/\s+/g, ''));
  put('flight_date', text(lead.flight_date));
  put('departure', text(lead.route_from));
  put('destination', text(lead.route_to));
  put('pnr_number', text(lead.booking_reference).toUpperCase());
  put('claims_reason', text(lead.complaint_type));
  if (typeof lead.delay_hours === 'number' && lead.delay_hours > 0) {
    out.duration_of_delay = `${lead.delay_hours} hours`;
  }
  // Kept even when blank so a claim always has the field the CRM reads.
  if (!out.client_email) out.client_email = '';
  return out;
}

/**
 * Flight number and date from a website summary, for leads saved before the
 * website stored them as their own fields. The line reads
 * "Airline: Air Peace · Flight P47120 · 2026-09-30", either part optional.
 */
function flightFromSummary(summary) {
  const line = text(summary).split('\n').find((l) => l.startsWith('Airline:')) || '';
  const parts = line.split(' · ').slice(1).map((p) => p.trim());
  const flight = parts.find((p) => p.startsWith('Flight '));
  const date = parts.find((p) => /^\d{4}-\d{2}-\d{2}$/.test(p));
  return {
    flight_number: flight ? flight.slice(7).toUpperCase().replace(/\s+/g, '') : '',
    flight_date: date || '',
  };
}

module.exports = { claimFieldsFromLead, flightFromSummary };
