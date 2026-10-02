/**
 * Rename old stage values on leads and claims to the pipeline's names
 * (functions/pipeline.js).
 *
 *   firebase login                      # once; the script uses that sign-in
 *   node migrate-stages.js              # dry run: prints what would change
 *   node migrate-stages.js --apply      # writes the changes
 *
 * Safe to run more than once: a record already on a pipeline stage is left
 * alone. Each change is stamped stage_changed_by "migration", which the
 * status-email function checks so that no client is emailed about a stage
 * their claim reached long ago. The stage log records each one.
 *
 * "Submit to Solicitor" used to cover three different situations, so it is
 * split by what had actually happened to the claim:
 *   final legal notice sent            → With Solicitor
 *   demand letter sent to the airline  → Awaiting Reply
 *   neither                            → Demand Pending
 */
const fs = require('fs');
const os = require('os');
const path = require('path');
const https = require('https');
const { CLAIM, LEAD, CLAIM_LEGACY, LEAD_LEGACY } = require('../functions/pipeline');

const PROJECT = process.env.GOOGLE_CLOUD_PROJECT || 'msmcrm-g24k37';
const APPLY = process.argv.includes('--apply');
const BASE = `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents`;

function token() {
  const file = path.join(os.homedir(), '.config', 'configstore', 'firebase-tools.json');
  const tokens = JSON.parse(fs.readFileSync(file, 'utf8')).tokens || {};
  if (!tokens.access_token || tokens.expires_at < Date.now() + 60000) {
    throw new Error('No fresh Firebase sign-in found. Run "firebase projects:list" and try again.');
  }
  return tokens.access_token;
}

function request(method, url, body) {
  return new Promise((resolve, reject) => {
    const req = https.request(url, {
      method,
      headers: { Authorization: `Bearer ${token()}`, 'Content-Type': 'application/json' },
    }, (res) => {
      let text = '';
      res.on('data', (d) => (text += d));
      res.on('end', () => {
        const json = JSON.parse(text || '{}');
        if (res.statusCode >= 300) reject(new Error(`${res.statusCode} ${json.error ? json.error.message : text}`));
        else resolve(json);
      });
    });
    req.on('error', reject);
    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

async function listAll(collection, fields) {
  const docs = [];
  let pageToken = '';
  do {
    const mask = fields.map((f) => `&mask.fieldPaths=${f}`).join('');
    const page = await request('GET', `${BASE}/${collection}?pageSize=300${mask}${pageToken ? `&pageToken=${pageToken}` : ''}`);
    docs.push(...(page.documents || []));
    pageToken = page.nextPageToken || '';
  } while (pageToken);
  return docs;
}

const str = (doc, field) => ((doc.fields || {})[field] || {}).stringValue || '';

/** The pipeline stage an old claim value stands for, or null to leave it. */
function claimTarget(doc) {
  const status = str(doc, 'claim_status');
  if (Object.values(CLAIM).includes(status)) return null;
  if (status === 'Submit to Solicitor' || status === 'Submitted to Solicitors') {
    if (str(doc, 'solicitor_email_status') === 'Sent') return CLAIM.WITH_SOLICITOR;
    if (['Awaiting reply', 'Sent'].includes(str(doc, 'airline_email_status'))) return CLAIM.AWAITING_REPLY;
    return CLAIM.DEMAND_PENDING;
  }
  return CLAIM_LEGACY[status] || null;
}

function leadTarget(doc) {
  const status = str(doc, 'status');
  if (Object.values(LEAD).includes(status)) return null;
  return LEAD_LEGACY[status] || null;
}

async function migrate(collection, field, fields, targetOf, extra) {
  const docs = await listAll(collection, fields);
  const tally = {};
  const unknown = {};
  let changed = 0;
  for (const doc of docs) {
    const from = str(doc, field);
    const to = targetOf(doc);
    if (!to) {
      const known = Object.values(collection === 'claims' ? CLAIM : LEAD).includes(from);
      if (!known) unknown[from || '(empty)'] = (unknown[from || '(empty)'] || 0) + 1;
      continue;
    }
    tally[`${from} → ${to}`] = (tally[`${from} → ${to}`] || 0) + 1;
    if (!APPLY) continue;
    const update = {
      [field]: { stringValue: to },
      stage_changed_at: { timestampValue: new Date().toISOString() },
      stage_changed_by: { stringValue: 'migration' },
      stage_changed_by_name: { stringValue: 'Migration' },
      stage_note: { stringValue: `Stage renamed from "${from}"` },
      ...extra(to),
    };
    const mask = Object.keys(update).map((k) => `updateMask.fieldPaths=${k}`).join('&');
    await request('PATCH', `https://firestore.googleapis.com/v1/${doc.name}?${mask}&currentDocument.exists=true`, { fields: update });
    changed++;
  }
  console.log(`\n${collection}: ${docs.length} records`);
  const lines = Object.entries(tally);
  if (!lines.length) console.log('  nothing to rename');
  for (const [move, n] of lines) console.log(`  ${String(n).padStart(3)}  ${move}`);
  for (const [value, n] of Object.entries(unknown)) console.log(`  ${String(n).padStart(3)}  LEFT ALONE — unrecognised value "${value}"`);
  if (APPLY) console.log(`  ${changed} written`);
}

(async () => {
  console.log(APPLY ? `APPLYING to ${PROJECT}` : `Dry run against ${PROJECT} — nothing will be written. Add --apply to write.`);
  await migrate('claims', 'claim_status',
    ['claim_status', 'airline_email_status', 'solicitor_email_status'],
    claimTarget,
    (to) => ({ is_escalated: { booleanValue: to === CLAIM.WITH_SOLICITOR } }));
  await migrate('leads', 'status', ['status'], leadTarget, () => ({}));
})().catch((e) => {
  console.error(e.message);
  process.exit(1);
});
