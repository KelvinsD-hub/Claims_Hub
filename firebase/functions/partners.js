/**
 * Referral partners: people outside Claims Assist who bring in clients.
 *
 * An admin invites a partner by email. The partner gets their own short link
 * (a campaign_links document with channel "partner", code "p-…"); every lead
 * that arrives through it is credited to them. They sign in to their own page
 * on the website (claimsassistltd.com/partner) with a link emailed to them —
 * no password — and see how their clients' claims are going.
 *
 * What a partner sees is decided here and nowhere else. They are not staff:
 * the database rules give them nothing, and this module hands them only the
 * client's first name and initial, the airline and route, and how far the
 * claim has got. Never the client's contact details, documents, bank details,
 * notes or money. They cannot change anything.
 */
const { FieldValue } = require('firebase-admin/firestore');
const { ROLE, StageError, LEAD, CLAIM, canonical } = require('./pipeline');

const ADMINS = [ROLE.ADMIN, ROLE.SUPER_ADMIN];
const EMAIL = /^[^\s@,;<>]+@[^\s@,;<>]+\.[^\s@,;<>]{2,}$/;
const PORTAL_URL = 'https://claimsassistltd.com/partner';
const LINK_BASE = 'https://claimsassistltd.com/go/';

const text = (v) => (typeof v === 'string' ? v.trim() : '');
const normEmail = (v) => text(v).toLowerCase();

/** Check an invitation. Returns the cleaned fields. */
function planPartner({ staff, name, email, phone }) {
  if (!ADMINS.includes(staff.role)) throw new StageError(403, 'Only an admin can invite a referral partner.');
  const who = text(name).replace(/\s+/g, ' ');
  if (!who) throw new StageError(400, 'Give the partner\'s name.');
  if (who.length > 80) throw new StageError(400, 'That name is too long.');
  const to = normEmail(email);
  if (!EMAIL.test(to)) throw new StageError(400, 'Give one email address for the partner.');
  return { name: who, email: to, phone: text(phone).replace(/[^0-9+]/g, '').slice(0, 20) };
}

/** The link code for a partner: "Ada Okafor" → "p-ada-okafor". */
function partnerCode(name, attempt = 0) {
  const base = name.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '').slice(0, 24).replace(/-+$/, '') || 'partner';
  return `p-${base}${attempt ? `-${attempt + 1}` : ''}`;
}

/** "Ada Okafor" → "Ada O." — all a partner is shown of a client's name. */
function shortName(fullName) {
  const parts = text(fullName).split(/\s+/).filter(Boolean);
  if (!parts.length) return 'Client';
  const first = parts[0][0].toUpperCase() + parts[0].slice(1).toLowerCase();
  return parts.length > 1 ? `${first} ${parts[parts.length - 1][0].toUpperCase()}.` : first;
}

/**
 * How far a referral has got, in words for the partner. `lead` and `claim`
 * are the stages; `claim` is empty until the lead is qualified.
 */
function progressOf(leadStage, claimStage) {
  if (claimStage) {
    switch (canonical('claim', claimStage)) {
      case CLAIM.DETAILS_PENDING:
      case CLAIM.TERMS_PENDING:
        return { step: 2, label: 'Collecting documents', done: false };
      case CLAIM.READY_FOR_REVIEW:
      case CLAIM.UNDER_REVIEW:
        return { step: 3, label: 'Under review', done: false };
      case CLAIM.DEMAND_PENDING:
      case CLAIM.AWAITING_REPLY:
        return { step: 4, label: 'With the airline', done: false };
      case CLAIM.WITH_SOLICITOR:
        return { step: 4, label: 'Escalated by our legal team', done: false };
      case CLAIM.WON:
      case CLAIM.PAID:
        return { step: 5, label: 'Won', done: true, outcome: 'won' };
      case CLAIM.LOST:
        return { step: 5, label: 'Not successful', done: true, outcome: 'lost' };
      case CLAIM.WITHDRAWN:
        return { step: 5, label: 'Withdrawn', done: true, outcome: 'withdrawn' };
      default:
        return { step: 2, label: 'In progress', done: false };
    }
  }
  switch (canonical('lead', leadStage)) {
    case LEAD.CONTACTED:
      return { step: 1, label: 'We are speaking to the client', done: false };
    case LEAD.QUALIFIED:
      return { step: 2, label: 'Collecting documents', done: false };
    case LEAD.REJECTED:
      return { step: 1, label: 'Not taken on', done: true, outcome: 'rejected' };
    default:
      return { step: 1, label: 'Received', done: false };
  }
}

const millis = (v) => (v && typeof v.toMillis === 'function' ? v.toMillis() : 0);
const iso = (ms) => (ms ? new Date(ms).toISOString() : '');

/**
 * One referral as the partner sees it. Built from an explicit list of
 * fields, never by copying the record, so nothing else can leak.
 */
function referralView(lead, claim) {
  const progress = progressOf(lead.status, claim ? claim.claim_status : '');
  const route = [text(lead.route_from), text(lead.route_to)];
  const updated = Math.max(
    millis(lead.created_at), millis(lead.stage_changed_at),
    claim ? millis(claim.createdAt) : 0, claim ? millis(claim.stage_changed_at) : 0,
  );
  return {
    client: shortName(lead.full_name),
    airline: text(lead.airline_name),
    route: route.every(Boolean) ? `${route[0]} → ${route[1]}` : '',
    problem: text(lead.complaint_type),
    received: iso(millis(lead.created_at)),
    updated: iso(updated),
    signed: lead.loa_signed === true,
    ...progress,
  };
}

/** Totals for the partner's page. */
function summarise(referrals, clicks) {
  return {
    clicks,
    referrals: referrals.length,
    signed: referrals.filter((r) => r.signed).length,
    inProgress: referrals.filter((r) => !r.done && r.step >= 2).length,
    won: referrals.filter((r) => r.outcome === 'won').length,
  };
}

/** Invite a partner: their record and their link, together. */
async function createPartner(admin, { staff, name, email, phone }) {
  const plan = planPartner({ staff, name, email, phone });
  const db = admin.firestore();
  const taken = await db.collection('partners').where('email', '==', plan.email).limit(1).get();
  if (!taken.empty) throw new StageError(409, `${plan.email} is already a referral partner.`);

  const partnerRef = db.collection('partners').doc();
  return db.runTransaction(async (tx) => {
    let code = '';
    for (let attempt = 0; attempt < 20 && !code; attempt++) {
      const candidate = partnerCode(plan.name, attempt);
      if (!(await tx.get(db.doc(`campaign_links/${candidate}`))).exists) code = candidate;
    }
    if (!code) throw new StageError(409, 'Could not find a free link for that name.');
    const ts = FieldValue.serverTimestamp();
    tx.set(partnerRef, {
      ...plan,
      code,
      status: 'invited',
      uid: null,
      invited_by: staff.uid,
      invited_by_name: staff.name,
      created_at: ts,
    });
    tx.set(db.doc(`campaign_links/${code}`), {
      label: plan.name,
      channel: 'partner',
      partner_id: partnerRef.id,
      destination: '/',
      active: true,
      clicks: 0,
      created_at: ts,
      created_by: staff.uid,
      created_by_name: staff.name,
    });
    tx.set(db.collection('activity_logs').doc(), {
      entityType: 'Partner',
      action: 'Referral partner invited',
      description: `${staff.name} invited ${plan.name} (${plan.email}) as a referral partner, link ${LINK_BASE}${code}`,
      performedBy: db.doc(`users/${staff.uid}`),
      performedByName: staff.name,
      actor_type: 'staff',
      createdAt: ts,
    });
    return { id: partnerRef.id, code, link: `${LINK_BASE}${code}`, ...plan };
  });
}

/** Suspend a partner (their link stops crediting, their page closes) or restore them. */
async function setPartnerActive(admin, { staff, id, active }) {
  if (!ADMINS.includes(staff.role)) throw new StageError(403, 'Only an admin can change a referral partner.');
  if (!/^[A-Za-z0-9]{1,64}$/.test(String(id || ''))) throw new StageError(400, 'Invalid partner.');
  const db = admin.firestore();
  const ref = db.doc(`partners/${id}`);
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw new StageError(404, 'That partner no longer exists.');
    const partner = snap.data();
    const status = active ? (partner.uid ? 'active' : 'invited') : 'suspended';
    tx.update(ref, { status, status_changed_at: FieldValue.serverTimestamp(), status_changed_by: staff.uid });
    tx.update(db.doc(`campaign_links/${partner.code}`), { active: !!active });
    tx.set(db.collection('activity_logs').doc(), {
      entityType: 'Partner',
      action: active ? 'Referral partner restored' : 'Referral partner suspended',
      description: `${staff.name} ${active ? 'restored' : 'suspended'} ${partner.name}`,
      performedBy: db.doc(`users/${staff.uid}`),
      performedByName: staff.name,
      actor_type: 'staff',
      createdAt: FieldValue.serverTimestamp(),
    });
    return { status };
  });
}

/** The partner a sign-in link may be sent to, or null. Suspended partners get none. */
async function partnerForEmail(db, email) {
  const snap = await db.collection('partners').where('email', '==', normEmail(email)).limit(1).get();
  if (snap.empty) return null;
  const partner = snap.docs[0].data();
  return partner.status === 'suspended' ? null : { id: snap.docs[0].id, ...partner };
}

/** A one-click sign-in link for the partner's page. */
function signInLink(admin, email) {
  return admin.auth().generateSignInWithEmailLink(normEmail(email), { url: PORTAL_URL, handleCodeInApp: true });
}

/**
 * Everything the partner's page shows. `user` is the signed-in account
 * { uid, email }, whose address was proved by the emailed link. The first
 * sign-in ties the account to the partner record.
 */
async function portal(admin, { user }) {
  const db = admin.firestore();
  let snap = await db.collection('partners').where('uid', '==', user.uid).limit(1).get();
  if (snap.empty && user.email) {
    snap = await db.collection('partners').where('email', '==', normEmail(user.email)).where('uid', '==', null).limit(1).get();
  }
  if (snap.empty) throw new StageError(403, 'This address is not registered as a Claims Assist referral partner.');
  const doc = snap.docs[0];
  const partner = doc.data();
  if (partner.status === 'suspended') throw new StageError(403, 'Your partner page is closed. Contact Claims Assist if you think this is wrong.');

  if (!partner.uid) {
    await doc.ref.update({ uid: user.uid, status: 'active', joined_at: FieldValue.serverTimestamp() });
    await admin.auth().setCustomUserClaims(user.uid, { partner: true }).catch(() => {});
    await db.collection('activity_logs').add({
      entityType: 'Partner',
      action: 'Referral partner joined',
      description: `${partner.name} opened their partner page for the first time`,
      performedByName: partner.name,
      actor_type: 'partner',
      createdAt: FieldValue.serverTimestamp(),
    });
  } else {
    await doc.ref.update({ last_seen_at: FieldValue.serverTimestamp() });
  }

  const [linkSnap, leadsSnap, claimsSnap] = await Promise.all([
    db.doc(`campaign_links/${partner.code}`).get(),
    db.collection('leads').where('source_link', '==', partner.code).get(),
    db.collection('claims').where('source_link', '==', partner.code).get(),
  ]);
  const claimByLead = new Map();
  claimsSnap.forEach((c) => {
    const lr = c.get('lead_ref');
    if (lr && lr.path) claimByLead.set(lr.path, c.data());
  });
  const referrals = leadsSnap.docs
    .map((l) => referralView(l.data(), claimByLead.get(l.ref.path) || null))
    .sort((a, b) => b.received.localeCompare(a.received));
  const clicks = linkSnap.exists ? Number(linkSnap.get('clicks') || 0) : 0;
  return {
    name: partner.name,
    link: `${LINK_BASE}${partner.code}`,
    summary: summarise(referrals, clicks),
    referrals,
  };
}

/** Lead fields that credit a partner, from the link the lead came through. */
function creditFields(link, partner) {
  if (!link || link.channel !== 'partner' || !link.partner_id) return null;
  return { partner_id: link.partner_id, partner_name: (partner && partner.name) || link.label || '' };
}

/** The invitation email, carrying a sign-in link. */
function inviteEmail({ name, link, signIn, invitedBy }, escapeHtml) {
  const first = text(name).split(' ')[0] || 'there';
  const subject = 'You are invited to be a Claims Assist referral partner';
  const html = `
    <div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;color:#1f2937">
      <div style="background:#0f1a33;padding:22px 28px;border-radius:8px 8px 0 0">
        <h1 style="color:#fff;margin:0;font-size:20px">Claims Assist</h1>
      </div>
      <div style="padding:28px;border:1px solid #e5e7eb;border-top:none;border-radius:0 0 8px 8px">
        <p>Hello ${escapeHtml(first)},</p>
        <p>${escapeHtml(invitedBy || 'Claims Assist')} has set you up as a referral partner. Share your personal link with passengers whose flights were delayed, cancelled or overbooked. Everyone who claims through it is credited to you, and you can follow how their claims are going.</p>
        <p style="background:#f8f5ee;padding:12px 14px;border-radius:6px;font-family:monospace">${escapeHtml(link)}</p>
        <p style="text-align:center;margin:28px 0">
          <a href="${signIn}" style="background:#0f1a33;color:#fff;padding:13px 26px;border-radius:6px;text-decoration:none;font-weight:bold">Open my partner page</a>
        </p>
        <p style="font-size:13px;color:#6b7280">That button signs you in; there is no password. If it has expired, go to ${PORTAL_URL} and ask for a new sign-in link.</p>
        <p style="font-size:13px;color:#6b7280">Each passenger fills in and signs their own claim through your link. Please do not fill it in for them.</p>
      </div>
    </div>`;
  const textBody = [
    `Hello ${first},`,
    '',
    `${invitedBy || 'Claims Assist'} has set you up as a Claims Assist referral partner.`,
    `Your link to share: ${link}`,
    '',
    `Open your partner page (signs you in, no password): ${signIn}`,
    `If that has expired, go to ${PORTAL_URL} and ask for a new sign-in link.`,
    '',
    'Each passenger fills in and signs their own claim through your link.',
  ].join('\n');
  return { subject, html, text: textBody };
}

/** The email carrying a fresh sign-in link. */
function signInEmail({ name, signIn }, escapeHtml) {
  const first = text(name).split(' ')[0] || 'there';
  return {
    subject: 'Your Claims Assist partner sign-in link',
    html: `<div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;color:#1f2937">
      <p>Hello ${escapeHtml(first)},</p>
      <p><a href="${signIn}" style="background:#0f1a33;color:#fff;padding:12px 24px;border-radius:6px;text-decoration:none;font-weight:bold;display:inline-block">Open my partner page</a></p>
      <p style="font-size:13px;color:#6b7280">If you did not ask for this, ignore it; nobody can sign in without this email.</p></div>`,
    text: `Hello ${first},\n\nOpen your partner page: ${signIn}\n\nIf you did not ask for this, ignore it.`,
  };
}

module.exports = {
  PORTAL_URL, LINK_BASE,
  planPartner, partnerCode, shortName, progressOf, referralView, summarise, creditFields,
  createPartner, setPartnerActive, partnerForEmail, signInLink, portal, inviteEmail, signInEmail,
};
