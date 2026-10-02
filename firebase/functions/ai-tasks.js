/**
 * What the AI assistant is asked to do, and with what.
 *
 * Four tasks: triage a lead, brief a lawyer on a claim, read an airline's
 * reply, and read a piece of client evidence. Each has a fixed shape for its
 * answer (a schema), so the app can lay it out and the Monitor page can count
 * it. ai.js makes the call; this file says what goes in and what must come
 * back.
 *
 * Three rules hold for every task:
 *   - The assistant advises; a person decides. Nothing it returns changes a
 *     record. Its drafts are for staff to read, edit and send themselves.
 *   - It is never asked for an amount of compensation. That comes from the
 *     Part 19 calculator, which is tested; a model's arithmetic is not.
 *   - It is sent only what the task needs. Bank details, BVN, NIN, passport
 *     numbers, the client's email and phone, and their signature are never
 *     included (see `claimFacts` and `leadFacts`: fields are picked, not
 *     removed, so a new sensitive field stays out by default).
 *
 * Pure: no Firebase or network imports, so it can be tested with plain node.
 */
const { z } = require('zod/v4');

const MODEL = 'claude-opus-5-5';
/** US dollars per million tokens for MODEL, for the Monitor page's estimate. */
const PRICE = { input: 4, output: 20 };

// ── What the assistant is told about the work ────────────────────────────────

const SYSTEM = `You assist the staff of Claims Assist Limited, a Nigerian firm that recovers compensation from airlines for passengers under Part 19 (Consumer Protection) of the Nigeria Civil Aviation Regulations 2023. The firm acts only on flights within Nigeria and flights to or from Nigeria. Your reader is a member of staff — a claims agent or one of the firm's in-house lawyers — who will check what you say against the file and decide what to do. You are not writing to the passenger or the airline unless asked for a draft, and a draft is always edited by a person before it goes anywhere.

What Part 19 provides, as the firm applies it:

Compensation is a share of the ticket price: at least 25% on a domestic flight and 30% on an international one (19.8.1.1). It is separate from the right to care (refreshments, meals, accommodation) and the right to a refund or re-routing; each has its own trigger.

Delay, domestic: under two hours, nothing. From two hours, refreshments and communication. Beyond three hours, the choice of a refund or re-routing. Compensation only where departure is more than six hours late (19.6.1.1(d)).

Delay, international: 19.6.2.1(a) attaches compensation to a delay of between two and four hours. Beyond four hours the text lists meals and accommodation and does not restate compensation, so an airline may dispute it. Treat a longer international delay as arguable, not certain.

Cancellation: no compensation where the passenger was told at least 24 hours ahead (domestic) or seven days ahead (international); a refund or re-routing is still due. With less notice, compensation is due.

Denied boarding against the passenger's will: compensation is due.

Downgrade (19.11): the fare difference back, plus 30% of the ticket price domestic or 50% international.

Extraordinary circumstances: an airline avoids compensation if it proves the disruption was caused by something outside its control that it could not have avoided — weather, air traffic control restrictions, security. The burden is on the airline. A bare assertion is not proof; technical faults and crew or operational problems are ordinarily within the airline's control.

Escalation: the claim goes to the airline first. If it stays unresolved, the firm can complain to the NCAA's consumer protection directorate on the passenger's written authority.

How to work:

Say what the file supports and where it is thin. If a fact you need is missing, name it; do not assume it. If the regulation leaves room for dispute, say so plainly rather than rounding it to yes or no.

Do not state an amount of compensation. The firm calculates that separately from the ticket price.

In any draft message: write plainly and courteously, promise no outcome and no timescale, do not threaten court proceedings, and do not say the firm will pay court fees or any other cost. The firm's fee is 30% of what is recovered and nothing if nothing is recovered; mention it only if the draft needs it.

Write in plain British English. Be brief: the reader has the file open.`;

// ── The four tasks ───────────────────────────────────────────────────────────

const TASKS = {
  lead_triage: {
    label: 'Lead triage',
    kind: 'lead',
    schema: z.object({
      summary: z.string().describe('Two or three sentences: who, which flight, what happened.'),
      assessment: z.enum(['likely_eligible', 'arguable', 'likely_not_eligible', 'need_more_information']),
      reasons: z.array(z.string()).describe('Why, citing the Part 19 rule each reason rests on.'),
      missing_information: z.array(z.string()).describe('Facts needed before this can be decided. Empty if none.'),
      suggested_next_step: z.string().describe('The one thing the agent should do next.'),
      draft_message_to_client: z.string().describe('A short first message to the passenger, for the agent to edit. Empty if contacting them is not the next step.'),
    }),
    instruction: 'Triage this lead. Decide whether Part 19 supports a claim on the facts given, say what is missing, and suggest what the agent should do next.',
  },

  case_brief: {
    label: 'Case brief',
    kind: 'claim',
    schema: z.object({
      brief: z.string().describe('A short paragraph a lawyer can read in under a minute: the facts, where the claim stands, and what is in dispute.'),
      strengths: z.array(z.string()),
      weaknesses: z.array(z.string()).describe('Where the airline could resist, or the file is thin.'),
      missing_evidence: z.array(z.string()).describe('Documents or facts the file should have and does not. Empty if none.'),
      suggested_next_step: z.string(),
    }),
    instruction: 'Brief a lawyer on this claim from the file and its history. Be candid about its weaknesses.',
  },

  classify_reply: {
    label: 'Airline reply',
    kind: 'claim',
    needsText: true,
    schema: z.object({
      category: z.enum([
        'accepts_in_full', 'offers_partial', 'rejects_extraordinary_circumstances',
        'rejects_other_reason', 'asks_for_information', 'acknowledgement_only', 'unclear',
      ]),
      summary: z.string().describe('What the airline said, in one or two sentences.'),
      amount_offered: z.number().nullable().describe('The amount offered in naira, if the reply states one; otherwise null.'),
      defence_assessment: z.string().describe('If the airline resists: whether its reason holds under Part 19, and what it would have to prove. Empty if it does not resist.'),
      suggested_next_step: z.string(),
      draft_reply: z.string().describe('A reply to the airline for a member of staff to edit. Empty if no reply is called for.'),
    }),
    instruction: 'Staff have pasted the airline\'s reply to this claim below. Classify it, assess any defence against Part 19, and suggest the next step.',
  },

  read_evidence: {
    label: 'Evidence check',
    kind: 'claim',
    needsDocument: true,
    schema: z.object({
      document_type: z.string().describe('What this is: boarding pass, e-ticket, booking confirmation, receipt, ID, other.'),
      legible: z.boolean().describe('False if key details cannot be read.'),
      passenger_name: z.string().describe('As printed. Empty if not shown.'),
      booking_reference: z.string(),
      flight_number: z.string(),
      flight_date: z.string().describe('As printed.'),
      route: z.string().describe('From and to, as printed.'),
      ticket_price: z.string().describe('With currency, as printed. Empty if not shown.'),
      mismatches: z.array(z.string()).describe('Each place this document disagrees with the claim as recorded. Empty if it agrees.'),
      notes: z.string().describe('Anything else staff should know: a cropped edge, a different passenger, signs of alteration.'),
    }),
    instruction: 'Read the attached document, which the client sent as evidence for this claim. Record what it shows and every place it disagrees with the claim as recorded. Report only what is printed on it; leave a field empty rather than infer it.',
  },
};

// ── What is sent ─────────────────────────────────────────────────────────────

const text = (v) => (v === undefined || v === null ? '' : String(v).trim());
const pick = (pairs) => Object.fromEntries(pairs.filter(([, v]) => v !== '' && v !== undefined && v !== null));

/** The facts of a lead that bear on eligibility. Nothing else is sent. */
function leadFacts(lead) {
  return pick([
    ['passenger', text(lead.full_name)],
    ['airline', text(lead.airline_name)],
    ['what_happened', text(lead.claim_type || lead.complaint_type)],
    ['their_account', text(lead.initial_summary)],
    ['disruption_details', text(lead.disruption_details)],
    ['delay_hours', lead.delay_hours],
    ['ticket_price', lead.fare_paid ? `${text(lead.fare_currency) || 'NGN'} ${lead.fare_paid}` : ''],
    ['passengers_on_booking', lead.passenger_count],
    ['country', text(lead.country)],
    ['website_routing', text(lead.handler)],
    ['website_routing_reason', text(lead.handler_reason)],
    ['stage', text(lead.status)],
  ]);
}

/** The facts of a claim that bear on its merits. Nothing else is sent. */
function claimFacts(claim) {
  return pick([
    ['passenger', text(claim.full_name)],
    ['airline', text(claim.airline_name)],
    ['flight_number', text(claim.flight_number)],
    ['flight_date', text(claim.flight_date)],
    ['from', text(claim.departure)],
    ['to', text(claim.destination)],
    ['from_country', text(claim.route_from_country)],
    ['to_country', text(claim.route_to_country)],
    ['reason_for_claim', text(claim.claims_reason)],
    ['length_of_delay', text(claim.duration_of_delay)],
    ['booking_reference', text(claim.pnr_number)],
    ['ticket_price', claim.fare_paid ? `${text(claim.fare_currency) || 'NGN'} ${claim.fare_paid}` : ''],
    ['passengers_on_booking', claim.passenger_count],
    ['what_the_airline_told_the_passenger', text(claim.airline_response)],
    ['stage', text(claim.claim_status)],
    ['legal_stage', text(claim.legal_stage)],
    ['airline_reply_on_file', text(claim.airline_reply_summary)],
    ['settlement_offer_naira', claim.settlement_offer_amount],
    ['documents_on_file', [
      claim.loa_url ? 'letter of authority' : '',
      claim.demand_letter_url ? 'demand letter sent' : '',
      claim.solicitor_letter_url ? 'final legal notice sent' : '',
      Array.isArray(claim.attached_document) && claim.attached_document.length
        ? `${claim.attached_document.length} item(s) of client evidence` : '',
    ].filter(Boolean).join(', ')],
  ]);
}

/** The event log as short lines, oldest first, for the case brief. */
function historyLines(events) {
  return events
    .slice()
    .sort((a, b) => a.at - b.at)
    .slice(-40)
    .map((e) => `${e.at.toISOString().slice(0, 10)}  ${e.action}${e.description ? `: ${e.description}` : ''}${e.note ? ` — "${e.note}"` : ''}`.slice(0, 400));
}

const IMAGE_TYPES = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];

/** The attachment as a content block, or null if the type cannot be read. */
function documentBlock(contentType, base64) {
  if (contentType === 'application/pdf') {
    return { type: 'document', source: { type: 'base64', media_type: 'application/pdf', data: base64 } };
  }
  if (IMAGE_TYPES.includes(contentType)) {
    return { type: 'image', source: { type: 'base64', media_type: contentType, data: base64 } };
  }
  return null;
}

/**
 * The user message for a task. `record` is the lead's or claim's data;
 * `pasted` is text staff supplied; `events` the claim's history; `attachment`
 * a { contentType, base64 } document.
 */
function buildMessage(task, { record, pasted, events, attachment }) {
  const spec = TASKS[task];
  const facts = spec.kind === 'lead' ? leadFacts(record) : claimFacts(record);
  const parts = [
    spec.instruction,
    `<${spec.kind}>\n${JSON.stringify(facts, null, 1)}\n</${spec.kind}>`,
  ];
  if (task === 'case_brief' && events && events.length) {
    parts.push(`<history>\n${historyLines(events).join('\n')}\n</history>`);
  }
  if (spec.needsText) {
    parts.push(`<airline_reply>\n${text(pasted).slice(0, 12000)}\n</airline_reply>`);
  }
  const content = [];
  if (spec.needsDocument) content.push(documentBlock(attachment.contentType, attachment.base64));
  content.push({ type: 'text', text: parts.join('\n\n') });
  return { role: 'user', content };
}

/** What a run cost, in US dollars, at MODEL's list price. An estimate. */
function estimateCost(usage) {
  const input = (usage.input_tokens || 0) + (usage.cache_creation_input_tokens || 0) + (usage.cache_read_input_tokens || 0);
  return Number(((input * PRICE.input + (usage.output_tokens || 0) * PRICE.output) / 1e6).toFixed(5));
}

module.exports = {
  MODEL, PRICE, SYSTEM, TASKS, IMAGE_TYPES,
  leadFacts, claimFacts, historyLines, documentBlock, buildMessage, estimateCost,
};
