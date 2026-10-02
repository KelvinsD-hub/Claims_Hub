/**
 * Casework written to the database: assigning a record, setting its next
 * action, moving an escalated claim between legal stages, and adding to the
 * case file.
 *
 * Separate from index.js so it can be run against the Firestore emulator.
 * casework.js decides what is allowed; this writes it and records it in the
 * event log, in the same transaction, so nothing changes without a log entry.
 */
const pipeline = require('./pipeline');
const casework = require('./casework');
const { CLAIM, StageError } = pipeline;
const { LEGAL, SLOT } = casework;

/**
 * The fields that say what a record at `stage` is waiting for. With nothing
 * left to do they are cleared. `forCreate` leaves cleared fields out, for a
 * document that does not exist yet.
 */
function nextActionFields(admin, kind, stage, legalStage, { forCreate = false, now = new Date() } = {}) {
  const next = casework.nextActionFor(kind, stage, legalStage);
  if (!next) {
    if (forCreate) return {};
    const gone = admin.firestore.FieldValue.delete();
    return { next_action: gone, next_action_due: gone, next_action_set_by: gone, next_action_set_by_name: gone };
  }
  return {
    next_action: next.text,
    next_action_due: admin.firestore.Timestamp.fromDate(casework.dueIn(next.days, now)),
    next_action_set_by: 'system',
    next_action_set_by_name: 'System',
  };
}

/** The fields that put `person` ({ uid, name }) in a slot on a record. */
function assignmentFields(admin, slot, person, by) {
  return {
    [`${slot}_uid`]: person.uid,
    [`${slot}_name`]: person.name,
    [`${slot}_assigned_at`]: admin.firestore.FieldValue.serverTimestamp(),
    [`${slot}_assigned_by`]: by.uid,
    [`${slot}_assigned_by_name`]: by.name,
  };
}

/** A new event-log entry made by a member of staff, as transaction data. */
function logEntry(admin, { kind, ref, data, staff, action, description, note, extra }) {
  const db = admin.firestore();
  return {
    entityType: kind === 'lead' ? 'Lead' : 'Claim',
    ...(kind === 'lead' ? { leadRef: ref } : { claims: ref, ...(data.lead_ref ? { leadRef: data.lead_ref } : {}) }),
    action,
    description,
    performedBy: db.doc(`users/${staff.uid}`),
    performedByName: staff.name,
    actor_type: 'staff',
    ...(note ? { note } : {}),
    ...(extra || {}),
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };
}

const NOTE_TYPES = {
  note: 'Note added',
  airline_reply: 'Airline reply recorded',
  offer: 'Settlement offer recorded',
};

/**
 * Apply one piece of casework. `staff` is { uid, name, role }.
 *
 *   { action: 'assign', kind, id, slot, to }          to: a uid, or '' to unassign
 *   { action: 'next_action', kind, id, text, due }    due: 'YYYY-MM-DD'; empty text clears it
 *   { action: 'legal_stage', id, to, note }
 *   { action: 'note', kind, id, type, text, amount }  type: note | airline_reply | offer
 *   { action: 'ai_opt_out', kind, id, on, note }      on: true stops the AI assistant
 *
 * Throws pipeline.StageError when it is not allowed, with a message fit to
 * show the person who asked.
 */
async function applyCaseAction(admin, input) {
  const db = admin.firestore();
  const { action, staff } = input;
  const kind = action === 'legal_stage' ? 'claim' : input.kind;
  if (kind !== 'lead' && kind !== 'claim') throw new StageError(400, 'Unknown record type.');
  const ref = db.doc(`${kind === 'lead' ? 'leads' : 'claims'}/${input.id}`);
  const stageField = kind === 'lead' ? 'status' : 'claim_status';

  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw new StageError(404, `That ${kind} no longer exists.`);
    const data = snap.data();
    const who = data.full_name || data.client_email || data.email || `this ${kind}`;
    const log = (entry) => tx.set(db.collection('activity_logs').doc(),
      logEntry(admin, { kind, ref, data, staff, ...entry }));

    if (action === 'assign') {
      const slot = input.slot;
      const toUid = String(input.to || '');
      let toUser = null;
      if (toUid) {
        const userSnap = await tx.get(db.doc(`users/${toUid}`));
        toUser = userSnap.exists ? userSnap.data() : null;
      }
      const plan = casework.planAssignment({
        kind, slot, currentUid: data[`${slot}_uid`], toUid, toUser, staff,
      });
      const label = slot === SLOT.LAWYER ? 'lawyer' : 'handler';
      if (!plan.to) {
        const gone = admin.firestore.FieldValue.delete();
        tx.update(ref, {
          [`${slot}_uid`]: gone, [`${slot}_name`]: gone, [`${slot}_assigned_at`]: gone,
          [`${slot}_assigned_by`]: gone, [`${slot}_assigned_by_name`]: gone,
        });
        log({ action: 'Unassigned', description: `${who}: ${label} removed (was ${data[`${slot}_name`] || 'assigned'})` });
        return { slot, to: '' };
      }
      const name = toUser.display_name || toUser.email || 'Staff';
      tx.update(ref, assignmentFields(admin, slot, { uid: plan.to, name }, staff));
      log({
        action: 'Assigned',
        description: plan.to === staff.uid
          ? `${who}: taken by ${name} as ${label}`
          : `${who}: ${label} set to ${name}`,
        extra: { assigned_to: plan.to, assigned_slot: slot },
      });
      return { slot, to: plan.to, name };
    }

    if (action === 'next_action') {
      const text = String(input.text || '').trim().slice(0, 200);
      if (!text) {
        const gone = admin.firestore.FieldValue.delete();
        tx.update(ref, { next_action: gone, next_action_due: gone, next_action_set_by: gone, next_action_set_by_name: gone });
        log({ action: 'Next action cleared', description: `${who}: next action cleared (was "${data.next_action || ''}")` });
        return { cleared: true };
      }
      const due = casework.dueOn(input.due);
      if (!due) throw new StageError(400, 'Give the date this is due.');
      tx.update(ref, {
        next_action: text,
        next_action_due: admin.firestore.Timestamp.fromDate(due),
        next_action_set_by: staff.uid,
        next_action_set_by_name: staff.name,
      });
      log({ action: 'Next action set', description: `${who}: "${text}" due ${input.due}` });
      return { text, due: input.due };
    }

    if (action === 'legal_stage') {
      const note = String(input.note || '').trim().slice(0, 1000);
      const plan = casework.planLegalStage({
        claimStage: pipeline.canonical('claim', data[stageField]),
        current: data.legal_stage, to: input.to, role: staff.role, note,
      });
      tx.update(ref, {
        legal_stage: plan.to,
        legal_stage_changed_at: admin.firestore.FieldValue.serverTimestamp(),
        legal_stage_changed_by: staff.uid,
        legal_stage_changed_by_name: staff.name,
        ...nextActionFields(admin, 'claim', CLAIM.WITH_SOLICITOR, plan.to),
      });
      log({
        action: 'Legal stage changed',
        description: `${who}: ${plan.from} → ${plan.to}`,
        note,
        extra: { from_legal_stage: plan.from, to_legal_stage: plan.to },
      });
      return plan;
    }

    if (action === 'note') {
      const type = NOTE_TYPES[input.type] ? input.type : 'note';
      const text = String(input.text || '').trim().slice(0, 2000);
      if (type !== 'note' && kind !== 'claim') throw new StageError(400, 'That can only be recorded on a claim.');
      if (!text) throw new StageError(400, 'Write the note first.');
      const update = {};
      const extra = { note_type: type };
      if (type === 'airline_reply') {
        update.airline_reply_at = admin.firestore.FieldValue.serverTimestamp();
        update.airline_reply_summary = text.slice(0, 500);
      }
      if (type === 'offer') {
        const amount = Number(input.amount);
        if (!Number.isFinite(amount) || amount <= 0) throw new StageError(400, 'Give the amount offered, in naira.');
        update.settlement_offer_amount = amount;
        update.settlement_offer_at = admin.firestore.FieldValue.serverTimestamp();
        extra.amount = amount;
      }
      if (Object.keys(update).length) tx.update(ref, update);
      log({ action: NOTE_TYPES[type], description: `${who}: ${text.slice(0, 140)}`, note: text, extra });
      return { type };
    }

    if (action === 'ai_opt_out') {
      // The privacy policy lets a client ask that AI is not used on their
      // claim. Any member of staff can record that; only a manager can lift
      // it. A lead and its claim are one client's matter, so both are marked.
      const on = input.on === true;
      const note = String(input.note || '').trim().slice(0, 500);
      if (!on && !casework.MANAGERS.includes(staff.role)) {
        throw new StageError(403, 'Only a manager can allow AI again once a client has objected.');
      }
      const linked = kind === 'lead' ? data.claim_ref : data.lead_ref;
      const hasLinked = linked && typeof linked.path === 'string' && (await tx.get(linked)).exists;
      const gone = admin.firestore.FieldValue.delete();
      const fields = on
        ? {
          ai_opt_out: true,
          ai_opt_out_at: admin.firestore.FieldValue.serverTimestamp(),
          ai_opt_out_by: staff.uid,
          ai_opt_out_by_name: staff.name,
        }
        : { ai_opt_out: gone, ai_opt_out_at: gone, ai_opt_out_by: gone, ai_opt_out_by_name: gone };
      tx.update(ref, fields);
      if (hasLinked) tx.update(linked, fields);
      log({
        action: on ? 'AI use stopped' : 'AI use allowed',
        description: on
          ? `${who}: the client asked that AI is not used on their claim`
          : `${who}: AI may be used again`,
        note,
      });
      return { ai_opt_out: on };
    }

    throw new StageError(400, 'Unknown action.');
  });
}

module.exports = { applyCaseAction, nextActionFields, assignmentFields, LEGAL };
