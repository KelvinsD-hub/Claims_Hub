/**
 * Staff invitations. Nobody signs themselves up to Claims Hub: an admin
 * invites a person by email address with a role, and the link they are sent
 * is the only way an account is approved without an admin opening it by hand.
 *
 * The link carries a random token. Only its SHA-256 is stored (as the invite's
 * document id), so a copy of the database cannot be turned back into working
 * links. A new invite to the same address cancels the earlier ones; an invite
 * lasts INVITE_DAYS and works once. The database rules refuse every client
 * read and write on `invites`: all of it goes through the staffInvite function.
 */
const crypto = require('crypto');
const { ROLE, StageError } = require('./pipeline');

const INVITE_DAYS = 7;
const APP_URL = 'https://claimshub.online';
const ROLES = [ROLE.AGENT, ROLE.SOLICITOR, ROLE.MANAGER, ROLE.ADMIN, ROLE.SUPER_ADMIN];
const ADMINS = [ROLE.ADMIN, ROLE.SUPER_ADMIN];
const EMAIL = /^[^\s@,;<>]+@[^\s@,;<>]+\.[^\s@,;<>]{2,}$/;

const normEmail = (value) => String(value || '').trim().toLowerCase();
const hashToken = (token) => crypto.createHash('sha256').update(String(token)).digest('hex');
const inviteLink = (token) => `${APP_URL}/authentication?invite=${token}`;

/** Where an invite stands: open, used, revoked, expired, or missing. */
function inviteStatus(invite, now = Date.now()) {
  if (!invite) return 'missing';
  if (invite.used_at) return 'used';
  if (invite.revoked_at) return 'revoked';
  const expires = invite.expires_at && invite.expires_at.toMillis ? invite.expires_at.toMillis() : 0;
  return expires < now ? 'expired' : 'open';
}

const CLOSED_MESSAGES = {
  missing: 'This invite link is not valid. Check you copied all of it, or ask an admin for a new one.',
  used: 'This invite has already been used. Sign in instead.',
  revoked: 'This invite was cancelled. Ask an admin for a new one.',
  expired: 'This invite has expired. Ask an admin for a new one.',
};

/** Check a request to invite someone. Returns the cleaned fields. */
function planInvite({ staff, email, name, role }) {
  if (!ADMINS.includes(staff.role)) throw new StageError(403, 'Only an admin can invite staff.');
  const to = normEmail(email);
  if (!EMAIL.test(to)) throw new StageError(400, 'Give one email address for the person you are inviting.');
  const who = String(name || '').trim().replace(/\s+/g, ' ');
  if (!who) throw new StageError(400, 'Give the name of the person you are inviting.');
  if (who.length > 80) throw new StageError(400, 'That name is too long.');
  if (!ROLES.includes(role)) throw new StageError(400, `Choose a role: ${ROLES.join(', ')}.`);
  if (role === ROLE.SUPER_ADMIN && staff.role !== ROLE.SUPER_ADMIN) {
    throw new StageError(403, 'Only a Super Admin can invite another Super Admin.');
  }
  return { email: to, name: who, role };
}

/** Users documents holding this (lower-case) address. */
async function usersWithEmail(db, email) {
  return (await db.collection('users').where('email', '==', email).get()).docs;
}

/**
 * Invite `email` as `role`. Cancels any open invite to the same address.
 * Returns { id, token, link, expiresAt }; the token is never stored.
 */
async function createInvite(admin, { staff, email, name, role, phone }) {
  const plan = planInvite({ staff, email, name, role });
  const db = admin.firestore();
  const existing = await usersWithEmail(db, plan.email);
  if (existing.some((d) => d.get('approved') === true)) {
    throw new StageError(409, `${plan.email} already has access to Claims Hub.`);
  }

  const token = crypto.randomBytes(24).toString('base64url');
  const id = hashToken(token);
  const expiresAt = new Date(Date.now() + INVITE_DAYS * 86400000);
  const ts = admin.firestore.FieldValue.serverTimestamp();
  const open = await db.collection('invites')
    .where('email', '==', plan.email).where('used_at', '==', null).where('revoked_at', '==', null).get();

  const batch = db.batch();
  open.forEach((d) => batch.update(d.ref, { revoked_at: ts, revoked_by: staff.uid, revoked_reason: 'replaced' }));
  batch.set(db.doc(`invites/${id}`), {
    email: plan.email,
    name: plan.name,
    role: plan.role,
    phone: String(phone || '').replace(/[^0-9+]/g, '').slice(0, 20),
    created_by: staff.uid,
    created_by_name: staff.name,
    created_at: ts,
    expires_at: admin.firestore.Timestamp.fromDate(expiresAt),
    used_at: null,
    revoked_at: null,
  });
  batch.set(db.collection('activity_logs').doc(), {
    entityType: 'Staff',
    action: 'Staff invited',
    description: `${staff.name} invited ${plan.name} (${plan.email}) as ${plan.role}`,
    performedBy: db.doc(`users/${staff.uid}`),
    performedByName: staff.name,
    actor_type: 'staff',
    createdAt: ts,
  });
  await batch.commit();
  return { id, token, link: inviteLink(token), expiresAt: expiresAt.toISOString(), ...plan };
}

/** What the join page shows for a link. Details only while it is open. */
async function inviteInfo(admin, { token }) {
  const snap = await admin.firestore().doc(`invites/${hashToken(token)}`).get();
  const invite = snap.exists ? snap.data() : null;
  const status = inviteStatus(invite);
  if (status !== 'open') return { status, message: CLOSED_MESSAGES[status] };
  return {
    status,
    email: invite.email,
    name: invite.name,
    role: invite.role,
    invitedBy: invite.created_by_name || '',
    expiresAt: invite.expires_at.toDate().toISOString(),
  };
}

/**
 * Use an invite. `user` is the signed-in account { uid, email }: it must be
 * the address the invite was sent to. Approves the account with the invite's
 * role and closes the invite, together.
 */
async function acceptInvite(admin, { token, user }) {
  const db = admin.firestore();
  const ref = db.doc(`invites/${hashToken(token)}`);
  const userRef = db.doc(`users/${user.uid}`);
  return db.runTransaction(async (tx) => {
    const [snap, userSnap] = await Promise.all([tx.get(ref), tx.get(userRef)]);
    const invite = snap.exists ? snap.data() : null;
    const status = inviteStatus(invite);
    if (status !== 'open') throw new StageError(status === 'missing' ? 404 : 409, CLOSED_MESSAGES[status]);
    if (normEmail(user.email) !== invite.email) {
      throw new StageError(403, `This invite is for ${invite.email}. Sign in with that address.`);
    }
    const current = userSnap.exists ? userSnap.data() : {};
    if (current.approved === true) throw new StageError(409, 'This account already has access. Sign in instead.');

    const ts = admin.firestore.FieldValue.serverTimestamp();
    tx.set(userRef, {
      uid: user.uid,
      email: invite.email,
      display_name: String(current.display_name || '').trim() || invite.name,
      approved: true,
      role: invite.role,
      approved_at: ts,
      approved_by: invite.created_by,
      invited_by_name: invite.created_by_name || '',
      ...(invite.phone && !current.phone_number ? { phone_number: invite.phone } : {}),
      ...(userSnap.exists ? {} : { created_time: ts }),
    }, { merge: true });
    tx.update(ref, { used_at: ts, used_by: user.uid });
    tx.set(db.collection('activity_logs').doc(), {
      entityType: 'Staff',
      action: 'Invite accepted',
      description: `${invite.name} (${invite.email}) joined as ${invite.role}`,
      performedBy: userRef,
      performedByName: invite.name,
      actor_type: 'staff',
      createdAt: ts,
    });
    return { role: invite.role, name: invite.name };
  });
}

/** Invites not yet used or cancelled, newest first. Admins only. */
async function listInvites(admin, { staff }) {
  if (!ADMINS.includes(staff.role)) throw new StageError(403, 'Only an admin can see invites.');
  const snap = await admin.firestore().collection('invites')
    .where('used_at', '==', null).where('revoked_at', '==', null).get();
  return snap.docs
    .map((d) => {
      const x = d.data();
      return {
        id: d.id, email: x.email, name: x.name, role: x.role, phone: x.phone || '',
        invitedBy: x.created_by_name || '',
        createdAt: x.created_at ? x.created_at.toDate().toISOString() : '',
        expiresAt: x.expires_at.toDate().toISOString(),
        expired: inviteStatus(x) === 'expired',
      };
    })
    .sort((a, b) => b.createdAt.localeCompare(a.createdAt));
}

/** Cancel an invite so its link stops working. Admins only. */
async function revokeInvite(admin, { staff, id }) {
  if (!ADMINS.includes(staff.role)) throw new StageError(403, 'Only an admin can cancel an invite.');
  if (!/^[0-9a-f]{64}$/.test(String(id || ''))) throw new StageError(400, 'Invalid invite.');
  const db = admin.firestore();
  const ref = db.doc(`invites/${id}`);
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw new StageError(404, 'That invite no longer exists.');
    const invite = snap.data();
    if (invite.used_at) throw new StageError(409, 'That invite has already been used.');
    if (invite.role === ROLE.SUPER_ADMIN && staff.role !== ROLE.SUPER_ADMIN) {
      throw new StageError(403, 'Only a Super Admin can cancel a Super Admin invite.');
    }
    const ts = admin.firestore.FieldValue.serverTimestamp();
    tx.update(ref, { revoked_at: ts, revoked_by: staff.uid, revoked_reason: 'cancelled' });
    tx.set(db.collection('activity_logs').doc(), {
      entityType: 'Staff',
      action: 'Invite cancelled',
      description: `${staff.name} cancelled the invite to ${invite.name} (${invite.email})`,
      performedBy: db.doc(`users/${staff.uid}`),
      performedByName: staff.name,
      actor_type: 'staff',
      createdAt: ts,
    });
    return { email: invite.email };
  });
}

/** The invitation email: subject, html and text. */
function inviteEmail({ name, role, link, invitedBy, expiresAt }, escapeHtml) {
  const first = String(name).split(' ')[0] || 'there';
  const until = new Date(expiresAt).toLocaleDateString('en-GB', { day: 'numeric', month: 'long', year: 'numeric', timeZone: 'Africa/Lagos' });
  const subject = 'Your invitation to Claims Hub';
  const text = [
    `Hello ${first},`,
    '',
    `${invitedBy || 'Claims Assist'} has invited you to join Claims Hub, the Claims Assist case system, as ${role}.`,
    '',
    `Set up your account here: ${link}`,
    '',
    `The link works once and expires on ${until}. You can sign in with Google or choose a password.`,
    'If you were not expecting this, ignore this email.',
  ].join('\n');
  const html = `
    <div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;color:#333">
      <div style="background:#002855;padding:20px 28px;border-radius:8px 8px 0 0">
        <h2 style="color:#fff;margin:0;font-size:20px">Claims Hub</h2>
      </div>
      <div style="padding:28px;border:1px solid #e0e0e0;border-top:none;border-radius:0 0 8px 8px">
        <p>Hello ${escapeHtml(first)},</p>
        <p>${escapeHtml(invitedBy || 'Claims Assist')} has invited you to join <strong>Claims Hub</strong>,
           the Claims Assist case system, as <strong>${escapeHtml(role)}</strong>.</p>
        <p style="text-align:center;margin:28px 0">
          <a href="${link}" style="background:#002855;color:#fff;padding:13px 26px;border-radius:6px;
             text-decoration:none;font-weight:bold;font-size:15px">Set up my account</a>
        </p>
        <p style="font-size:13px;color:#666">The link works once and expires on ${escapeHtml(until)}.
           You can sign in with Google or choose a password.</p>
        <p style="font-size:13px;color:#999">If you were not expecting this, ignore this email.</p>
      </div>
    </div>`;
  return { subject, html, text };
}

module.exports = {
  INVITE_DAYS, ROLES, normEmail, hashToken, inviteLink, inviteStatus, planInvite,
  createInvite, inviteInfo, acceptInvite, listInvites, revokeInvite, inviteEmail,
};
