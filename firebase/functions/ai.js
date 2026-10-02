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
const tasks = require('./ai-tasks');
const documents = require('./documents');
const { StageError } = require('./pipeline');

const GEMINI_URL = `https://generativelanguage.googleapis.com/v1beta/models/${tasks.MODEL}:generateContent`;

/** Under the function's own time limit, so staff get an answer either way. */
const CALL_TIMEOUT_MS = 150000;

/** The ways the model ends an answer without giving one. */
const DECLINED = ['SAFETY', 'RECITATION', 'BLOCKLIST', 'PROHIBITED_CONTENT', 'SPII'];

const pause = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

/**
 * Ask the model. Returns { output, usage, model }; throws StageError with a
 * message fit to show staff. The key is GEMINI_API_KEY (a function secret).
 */
async function callModel(task, message) {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey || apiKey === 'PLACEHOLDER') {
    throw new StageError(503, 'The AI assistant has not been switched on yet. Ask an admin.');
  }
  const schema = tasks.TASKS[task].schema;
  const post = () => fetch(GEMINI_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'x-goog-api-key': apiKey },
    signal: AbortSignal.timeout(CALL_TIMEOUT_MS),
    body: JSON.stringify({
      systemInstruction: { parts: [{ text: tasks.SYSTEM }] },
      contents: [message],
      generationConfig: {
        // The model's thinking counts against this, so it is set well above
        // the length of any answer.
        maxOutputTokens: 16000,
        responseMimeType: 'application/json',
        responseJsonSchema: tasks.answerSchema(task),
      },
    }),
  });

  let r;
  try {
    r = await post();
    // Google answers 500 or 503 when the model is briefly overloaded.
    if (r.status === 500 || r.status === 503) {
      await pause(2000);
      r = await post();
    }
  } catch (e) {
    console.error('[ai] the model could not be reached:', e && e.message);
    throw new StageError(503, 'The AI assistant could not be reached. Try again.');
  }
  if (!r.ok) {
    const body = (await r.text()).slice(0, 500);
    console.error(`[ai] API error ${r.status}:`, body);
    if (r.status === 429) throw new StageError(429, 'The AI assistant is busy. Try again in a minute.');
    if (r.status === 401 || r.status === 403 || /API key/i.test(body)) {
      throw new StageError(503, 'The AI assistant is not set up correctly. Ask an admin to check its key.');
    }
    if (r.status === 400) throw new StageError(500, 'The AI assistant could not read that request.');
    throw new StageError(503, 'The AI assistant is unavailable right now. Try again shortly.');
  }

  const data = await r.json();
  const candidate = data.candidates && data.candidates[0];
  const finish = candidate && candidate.finishReason;
  if ((data.promptFeedback && data.promptFeedback.blockReason) || DECLINED.includes(finish)) {
    console.error('[ai] declined:', (data.promptFeedback && data.promptFeedback.blockReason) || finish);
    throw new StageError(422, 'The AI assistant declined to answer this one.');
  }
  const answer = ((candidate && candidate.content && candidate.content.parts) || [])
    .filter((p) => !p.thought)
    .map((p) => p.text || '')
    .join('');
  let parsed = null;
  try { parsed = schema.safeParse(JSON.parse(answer)); } catch (_) { /* not JSON */ }
  if (finish !== 'STOP' || !parsed || !parsed.success) {
    console.error('[ai] no usable answer; finishReason:', finish, parsed && parsed.error ? parsed.error.message.slice(0, 300) : '');
    throw new StageError(502, 'The AI assistant did not return a usable answer. Try again.');
  }
  const used = data.usageMetadata || {};
  return {
    output: parsed.data,
    usage: {
      input_tokens: used.promptTokenCount || 0,
      // Thinking is billed as output.
      output_tokens: (used.candidatesTokenCount || 0) + (used.thoughtsTokenCount || 0),
    },
    model: data.modelVersion || tasks.MODEL,
  };
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
    throw new StageError(400, 'The AI assistant reads photos (JPEG, PNG, WebP, HEIC) and PDFs. This file is another type.');
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
