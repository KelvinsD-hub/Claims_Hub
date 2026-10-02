/**
 * Running an AI assist task and keeping a record of it.
 *
 * ai-tasks.js says what each task sends and what must come back. This loads
 * the record, makes the call, and writes the result to `ai_outputs` — every
 * run, with who asked, what it cost and, later, whether staff found it
 * useful. Nothing here changes a lead or a claim: the assistant advises and a
 * person acts.
 *
 * Separate from index.js so it can be run against the Firestore emulator
 * with the model call replaced (see rules-test/ai.test.js).
 */
const Anthropic = require('@anthropic-ai/sdk');
const { zodOutputFormat } = require('@anthropic-ai/sdk/helpers/zod');
const tasks = require('./ai-tasks');
const documents = require('./documents');
const { StageError } = require('./pipeline');

let client;
/** Reads ANTHROPIC_API_KEY from the environment (a function secret). */
function anthropic() {
  if (!client) client = new Anthropic();
  return client;
}

/**
 * Ask the model. Returns { output, usage, model }; throws StageError with a
 * message fit to show staff.
 */
async function callModel(task, message) {
  if (!process.env.ANTHROPIC_API_KEY) {
    throw new StageError(503, 'The AI assistant has not been switched on yet. Ask an admin.');
  }
  let response;
  try {
    response = await anthropic().beta.messages.parse({
      model: tasks.MODEL,
      max_tokens: 16000,
      // If the model's safety checks decline a request, the API re-runs it on
      // the recommended fallback model within the same call.
      betas: ['server-side-fallback-2026-07-01'],
      fallbacks: 'default',
      system: tasks.SYSTEM,
      messages: [message],
      output_config: {
        effort: 'medium',
        format: zodOutputFormat(tasks.TASKS[task].schema),
      },
    });
  } catch (e) {
    if (e instanceof Anthropic.AuthenticationError || e instanceof Anthropic.PermissionDeniedError) {
      console.error('[ai] the API key was refused:', e.message);
      throw new StageError(503, 'The AI assistant is not set up correctly. Ask an admin to check its key.');
    }
    if (e instanceof Anthropic.RateLimitError) {
      throw new StageError(429, 'The AI assistant is busy. Try again in a minute.');
    }
    if (e instanceof Anthropic.BadRequestError) {
      console.error('[ai] request rejected:', e.message);
      throw new StageError(500, 'The AI assistant could not read that request.');
    }
    if (e instanceof Anthropic.APIConnectionError) {
      throw new StageError(503, 'The AI assistant could not be reached. Try again.');
    }
    if (e instanceof Anthropic.APIError) {
      console.error(`[ai] API error ${e.status}:`, e.message);
      throw new StageError(503, 'The AI assistant is unavailable right now. Try again shortly.');
    }
    throw e;
  }
  if (response.stop_reason === 'refusal') {
    throw new StageError(422, 'The AI assistant declined to answer this one.');
  }
  if (response.stop_reason === 'max_tokens' || !response.parsed_output) {
    console.error('[ai] no usable answer; stop_reason:', response.stop_reason);
    throw new StageError(502, 'The AI assistant did not return a usable answer. Try again.');
  }
  return { output: response.parsed_output, usage: response.usage || {}, model: response.model || tasks.MODEL };
}

/** A client document as { contentType, base64 }, checked to belong to the claim. */
async function loadAttachment(admin, claimId, claim, address) {
  const filePath = documents.storagePathOf(address);
  const onClaim = filePath && (
    filePath.startsWith(`claims/${claimId}/`) ||
    (Array.isArray(claim.attached_document) &&
      claim.attached_document.some((a) => documents.storagePathOf(a) === filePath)));
  if (!onClaim || !documents.isClientDocument(filePath)) {
    throw new StageError(400, 'That document does not belong to this claim.');
  }
  const file = admin.storage().bucket().file(filePath);
  const [exists] = await file.exists();
  if (!exists) throw new StageError(404, 'That document is no longer on file.');
  const [meta] = await file.getMetadata();
  if (Number(meta.size) > documents.MAX_SERVED_BYTES) {
    throw new StageError(413, 'That document is too large for the AI assistant to read.');
  }
  const contentType = meta.contentType || '';
  if (contentType !== 'application/pdf' && !tasks.IMAGE_TYPES.includes(contentType)) {
    throw new StageError(400, 'The AI assistant reads photos (JPEG, PNG, WebP, GIF) and PDFs. This file is another type.');
  }
  const [bytes] = await file.download();
  return { contentType, base64: bytes.toString('base64'), path: filePath };
}

/**
 * Run one task for a member of staff. `staff` is { uid, name, role }.
 * Returns { id, output }. `deps.callModel` replaces the model in tests.
 */
async function runAiAssist(admin, { task, id, text, address, staff }, deps = {}) {
  const spec = tasks.TASKS[task];
  if (!spec) throw new StageError(400, 'Unknown AI task.');
  const db = admin.firestore();
  const ref = db.doc(`${spec.kind === 'lead' ? 'leads' : 'claims'}/${id}`);
  const snap = await ref.get();
  if (!snap.exists) throw new StageError(404, `That ${spec.kind} no longer exists.`);
  const record = snap.data();

  const pasted = String(text || '').trim();
  if (spec.needsText && pasted.length < 20) {
    throw new StageError(400, 'Paste the airline\'s reply first.');
  }
  let attachment = null;
  if (spec.needsDocument) attachment = await loadAttachment(admin, id, record, address);

  let events = [];
  if (task === 'case_brief') {
    const logs = await db.collection('activity_logs').where('claims', '==', ref).limit(200).get();
    events = logs.docs.map((d) => d.data())
      .filter((e) => e.createdAt && typeof e.createdAt.toDate === 'function')
      .map((e) => ({ at: e.createdAt.toDate(), action: e.action || '', description: e.description || '', note: e.note || '' }));
  }

  const message = tasks.buildMessage(task, { record, pasted, events, attachment });
  const result = await (deps.callModel || callModel)(task, message);

  const who = record.full_name || record.client_email || record.email || `this ${spec.kind}`;
  const out = db.collection('ai_outputs').doc();
  const batch = db.batch();
  batch.set(out, {
    task,
    task_label: spec.label,
    kind: spec.kind,
    record: ref,
    ...(spec.kind === 'claim' && record.lead_ref ? { lead_ref: record.lead_ref } : {}),
    subject: who,
    model: result.model,
    output: result.output,
    ...(spec.needsText ? { pasted_text: pasted.slice(0, 6000) } : {}),
    ...(attachment ? { document_path: attachment.path } : {}),
    input_tokens: result.usage.input_tokens || 0,
    output_tokens: result.usage.output_tokens || 0,
    cost_usd: tasks.estimateCost(result.usage),
    requested_by: staff.uid,
    requested_by_name: staff.name,
    created_at: admin.firestore.FieldValue.serverTimestamp(),
    review_status: 'pending',
  });
  batch.set(db.collection('activity_logs').doc(), {
    entityType: spec.kind === 'lead' ? 'Lead' : 'Claim',
    ...(spec.kind === 'lead' ? { leadRef: ref } : { claims: ref, ...(record.lead_ref ? { leadRef: record.lead_ref } : {}) }),
    action: 'AI assist',
    description: `${spec.label} run for ${who}`,
    performedBy: db.doc(`users/${staff.uid}`),
    performedByName: staff.name,
    actor_type: 'staff',
    ai_output: out,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  await batch.commit();
  return { id: out.id, output: result.output };
}

const VERDICTS = ['useful', 'not_useful'];

/** Record whether staff found an answer useful. Anyone on staff may. */
async function reviewAiOutput(admin, { id, verdict, note, staff }) {
  if (!VERDICTS.includes(verdict)) throw new StageError(400, 'Unknown verdict.');
  const ref = admin.firestore().doc(`ai_outputs/${id}`);
  const snap = await ref.get();
  if (!snap.exists) throw new StageError(404, 'That AI answer no longer exists.');
  await ref.update({
    review_status: verdict,
    review_note: String(note || '').trim().slice(0, 500),
    reviewed_by: staff.uid,
    reviewed_by_name: staff.name,
    reviewed_at: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { id, verdict };
}

module.exports = { runAiAssist, reviewAiOutput, callModel };
