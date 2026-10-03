/**
 * Emails that tell people outside the firm how a lead or claim is going.
 *
 * Clients: the existing stage emails (onClaimStatusChanged) plus a "your
 * claim is open" email for someone who already signed on the website, and a
 * "payment sent" email. Every client email links to the tracker on the
 * website.
 *
 * Referral partners: an email when someone arrives through their link, and
 * another each time that person's progress changes, in the words of their
 * partner page (partners.js progressOf). A partner is told the client's first
 * name and initial and how far the claim has got; nothing else.
 *
 * Pure: builds and decides, sends nothing, so it can be tested with plain node.
 */
const { progressOf, shortName } = require('./partners');

const SITE = 'https://claimsassistltd.com';
const text = (v) => (typeof v === 'string' ? v.trim() : '');

/** The client's tracker page for a claim. */
function trackerUrl(claimId, token) {
  return `${SITE}/track?claimRef=${encodeURIComponent(`claims/${claimId}`)}&token=${encodeURIComponent(token || '')}`;
}

/**
 * Whether a partner should hear about a change, and what to say. `before`
 * and `after` are { lead, claim } stage pairs; `before` null means the
 * referral is new to them. Returns { label, news } or null.
 */
function partnerNews(before, after) {
  const now = progressOf(after.lead, after.claim);
  if (!before) return { label: now.label, news: 'new' };
  const was = progressOf(before.lead, before.claim);
  if (was.label === now.label) return null;
  return { label: now.label, news: 'update', outcome: now.outcome || '' };
}

function layout(title, bodyHtml, escapeHtml, button) {
  return `
    <div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;color:#1f2937">
      <div style="background:#0f1a33;padding:22px 28px;border-radius:8px 8px 0 0">
        <h1 style="color:#fff;margin:0;font-size:20px">Claims Assist</h1>
      </div>
      <div style="padding:28px;border:1px solid #e5e7eb;border-top:none;border-radius:0 0 8px 8px">
        <h2 style="margin-top:0;font-size:18px">${escapeHtml(title)}</h2>
        ${bodyHtml}
        ${button ? `<p style="text-align:center;margin:28px 0"><a href="${button.href}" style="background:#0f1a33;color:#fff;padding:13px 26px;border-radius:6px;text-decoration:none;font-weight:bold">${escapeHtml(button.label)}</a></p>` : ''}
        <p style="font-size:13px;color:#6b7280">Questions? Just reply to this email.</p>
      </div>
    </div>`;
}

/** The email to a partner about one referral. */
function partnerEmail({ partnerName, clientName, airline, news }, escapeHtml) {
  const first = text(partnerName).split(' ')[0] || 'there';
  const client = shortName(clientName);
  const flight = text(airline) ? ` (${text(airline)})` : '';
  const isNew = news.news === 'new';
  const subject = isNew
    ? `New referral: ${client} came through your link`
    : news.outcome === 'won'
      ? `Good news: ${client}'s claim was won`
      : `Update on ${client}'s claim: ${news.label}`;
  const line = isNew
    ? `${client}${flight} has started a claim through your Claims Assist link.`
    : `${client}'s claim${flight} is now at: ${news.label}.`;
  const html = layout(subject, `<p>Hello ${escapeHtml(first)},</p><p>${escapeHtml(line)}</p>`, escapeHtml,
    { href: `${SITE}/partner`, label: 'See all my referrals' });
  return {
    subject,
    html,
    text: `Hello ${first},\n\n${line}\n\nSee all your referrals: ${SITE}/partner\n\nClaims Assist`,
  };
}

/**
 * The email for a newly opened claim. A client who signed the authority on
 * the website has already given what the old evidence form asks for; they
 * are told the claim is open, not asked again.
 */
function claimOpenedEmail({ name, airline, signedOnWebsite, tracker, evidenceUrl }, escapeHtml) {
  const first = text(name).split(' ')[0] || 'there';
  if (signedOnWebsite) {
    const subject = 'Your claim is open — Claims Assist';
    const body = [
      `We have reviewed your details and opened your claim against ${text(airline) || 'the airline'}.`,
      'You have already signed your authority, so there is nothing you need to do now. If we need anything else, we will email you a short form.',
      'You can follow every step of your claim on your tracker.',
    ];
    return {
      subject,
      html: layout(subject, `<p>Hello ${escapeHtml(first)},</p>${body.map((b) => `<p>${escapeHtml(b)}</p>`).join('')}`, escapeHtml,
        { href: tracker, label: 'Track my claim' }),
      text: `Hello ${first},\n\n${body.join('\n\n')}\n\nTrack your claim: ${tracker}\n\nClaims Assist`,
    };
  }
  const subject = 'Action needed: send us your flight details — Claims Assist';
  const body = [
    `We have opened your claim against ${text(airline) || 'the airline'}.`,
    'To go further we need your flight details, your evidence and your signed authority. It takes a few minutes.',
  ];
  return {
    subject,
    html: layout(subject, `<p>Hello ${escapeHtml(first)},</p>${body.map((b) => `<p>${escapeHtml(b)}</p>`).join('')}<p style="font-size:13px;color:#6b7280">You can follow your claim here: <a href="${tracker}">${tracker}</a></p>`, escapeHtml,
      { href: evidenceUrl, label: 'Send my details' }),
    text: `Hello ${first},\n\n${body.join('\n\n')}\n\nSend your details: ${evidenceUrl}\nTrack your claim: ${tracker}\n\nClaims Assist`,
  };
}

/** The email when a claim is marked Paid. */
function paidEmail({ name, airline, tracker }, escapeHtml) {
  const first = text(name).split(' ')[0] || 'there';
  const subject = 'Your compensation has been paid — Claims Assist';
  const body = [
    `The money recovered from ${text(airline) || 'the airline'} has been paid to the account you gave us, after our success fee.`,
    'Bank transfers can take a day or two to show. If it has not arrived within three working days, reply to this email and we will check.',
    'Thank you for trusting Claims Assist.',
  ];
  return {
    subject,
    html: layout(subject, `<p>Hello ${escapeHtml(first)},</p>${body.map((b) => `<p>${escapeHtml(b)}</p>`).join('')}`, escapeHtml,
      { href: tracker, label: 'View my claim' }),
    text: `Hello ${first},\n\n${body.join('\n\n')}\n\nYour claim: ${tracker}\n\nClaims Assist`,
  };
}

module.exports = { SITE, trackerUrl, partnerNews, partnerEmail, claimOpenedEmail, paidEmail };
