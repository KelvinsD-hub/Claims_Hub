/**
 * Give records that existed before casework a next action and due date, and
 * give claims already with the legal team a legal stage
 * (functions/casework.js).
 *
 *   firebase login                        # once; the script uses that sign-in
 *   node backfill-casework.js             # dry run: prints what would change
 *   node backfill-casework.js --apply     # writes the changes
 *
 * Safe to run more than once: a record that already has a next action is left
 * alone, as is one with nothing left to do. Due dates count from the day the
 * script runs, not from when the record reached its stage, so old records do
 * not all arrive overdue. Nobody is assigned: existing records start in the
 * shared queue.
 */
const fs = require('fs');
const os = require('os');
const path = require('path');
const https = require('https');
const { CLAIM, canonical } = require('../functions/pipeline');
const { LEGAL, nextActionFor, dueIn } = require('../functions/casework');

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

async function backfill(kind, collection, stageField, fields) {
  const docs = await listAll(collection, fields);
  const tally = {};
  let changed = 0;
  for (const doc of docs) {
    if (str(doc, 'next_action')) continue;
    const stage = canonical(kind, str(doc, stageField));
    const update = {};
    let legalStage = str(doc, 'legal_stage');
    if (kind === 'claim' && stage === CLAIM.WITH_SOLICITOR && !legalStage) {
      // The final notice either went or it did not.
      legalStage = str(doc, 'solicitor_email_status') === 'Sent' ? LEGAL.NOTICE_SENT : LEGAL.REVIEW;
      update.legal_stage = { stringValue: legalStage };
    }
    const next = nextActionFor(kind, stage, legalStage);
    if (!next) continue;
    update.next_action = { stringValue: next.text };
    update.next_action_due = { timestampValue: dueIn(next.days).toISOString() };
    update.next_action_set_by = { stringValue: 'system' };
    update.next_action_set_by_name = { stringValue: 'System' };

    const label = `${stage}${update.legal_stage ? ` (${legalStage})` : ''} → "${next.text}", due in ${next.days} day${next.days === 1 ? '' : 's'}`;
    tally[label] = (tally[label] || 0) + 1;
    if (!APPLY) continue;
    const mask = Object.keys(update).map((k) => `updateMask.fieldPaths=${k}`).join('&');
    await request('PATCH', `https://firestore.googleapis.com/v1/${doc.name}?${mask}&currentDocument.exists=true`, { fields: update });
    changed++;
  }
  console.log(`\n${collection}: ${docs.length} records`);
  const lines = Object.entries(tally);
  if (!lines.length) console.log('  nothing to fill in');
  for (const [what, n] of lines) console.log(`  ${String(n).padStart(3)}  ${what}`);
  if (APPLY) console.log(`  ${changed} written`);
}

(async () => {
  console.log(APPLY ? `APPLYING to ${PROJECT}` : `Dry run against ${PROJECT} — nothing will be written. Add --apply to write.`);
  await backfill('claim', 'claims', 'claim_status', ['claim_status', 'next_action', 'legal_stage', 'solicitor_email_status']);
  await backfill('lead', 'leads', 'status', ['status', 'next_action']);
})().catch((e) => {
  console.error(e.message);
  process.exit(1);
});
