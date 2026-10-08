/**
 * Re-make every stored Letter of Authority with the current letterhead
 * (functions/index.js buildLoaPdf), so letters made before the move to
 * info@claimsassistltd.com show the new address.
 *
 *   firebase login                      # once; the script uses that sign-in
 *   node remake-loa.js                  # dry run: lists the letters it would re-make
 *   node remake-loa.js --apply          # re-makes them
 *
 * Each letter is written over the same storage file, so loa_url and every
 * link to it stay as they are. The signature and the signing date come from
 * the claim, so they are unchanged. Demand letters and final notices are left
 * alone: they went to airlines and stay as sent. Each claim re-made is stamped
 * loa_remade_at. Safe to run more than once.
 */
const fs = require('fs');
const os = require('os');
const path = require('path');
const https = require('https');

process.env.CLAIMS_HUB_SCRIPT = '1';
process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || 'msmcrm-g24k37';
const { buildLoaPdf } = require('../functions/index');
const { storagePathOf } = require('../functions/documents');

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

function request(method, url, body, contentType = 'application/json') {
  return new Promise((resolve, reject) => {
    const req = https.request(url, {
      method,
      headers: { Authorization: `Bearer ${token()}`, 'Content-Type': contentType },
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
    if (body) req.write(Buffer.isBuffer(body) ? body : JSON.stringify(body));
    req.end();
  });
}

async function listAll(collection) {
  const docs = [];
  let pageToken = '';
  do {
    const page = await request('GET', `${BASE}/${collection}?pageSize=300${pageToken ? `&pageToken=${pageToken}` : ''}`);
    docs.push(...(page.documents || []));
    pageToken = page.nextPageToken || '';
  } while (pageToken);
  return docs;
}

/** A Firestore REST value as plain JS, the shape the trigger code sees. */
function plain(v) {
  if (!v || typeof v !== 'object') return v;
  if ('stringValue' in v) return v.stringValue;
  if ('booleanValue' in v) return v.booleanValue;
  if ('integerValue' in v) return Number(v.integerValue);
  if ('doubleValue' in v) return v.doubleValue;
  if ('timestampValue' in v) return new Date(v.timestampValue);
  if ('nullValue' in v) return null;
  if ('arrayValue' in v) return (v.arrayValue.values || []).map(plain);
  if ('mapValue' in v) return fields(v.mapValue.fields);
  return null; // references and the like: the letter does not use them
}
function fields(f = {}) {
  return Object.fromEntries(Object.entries(f).map(([k, v]) => [k, plain(v)]));
}

/** Bucket and object path from a stored address. */
function bucketAndPath(address) {
  const m = /\/v0\/b\/([^/]+)\/o\//.exec(String(address));
  const objectPath = storagePathOf(address);
  return m && objectPath ? { bucket: m[1], objectPath } : null;
}

(async () => {
  console.log(APPLY ? `APPLYING to ${PROJECT}` : `Dry run against ${PROJECT} — nothing will be written. Add --apply to write.`);
  const claims = await listAll('claims');
  let found = 0;
  let written = 0;
  const skipped = [];
  for (const doc of claims) {
    const claim = fields(doc.fields);
    if (!claim.loa_url) continue;
    found++;
    const id = doc.name.split('/').pop();
    const where = bucketAndPath(claim.loa_url);
    const who = claim.full_name || '(no name)';
    if (!where) { skipped.push(`${id} ${who}: loa_url is not a storage address`); continue; }
    if (!claim.signature) { skipped.push(`${id} ${who}: no signature on the claim, so the letter cannot be re-made as signed`); continue; }
    console.log(`  ${id}  ${who}  →  ${where.objectPath}`);
    if (!APPLY) continue;
    const pdf = Buffer.from(await buildLoaPdf(claim, id));
    await request('POST',
      `https://storage.googleapis.com/upload/storage/v1/b/${where.bucket}/o?uploadType=media&name=${encodeURIComponent(where.objectPath)}`,
      pdf, 'application/pdf');
    await request('PATCH', `https://firestore.googleapis.com/v1/${doc.name}?updateMask.fieldPaths=loa_remade_at&currentDocument.exists=true`,
      { fields: { loa_remade_at: { timestampValue: new Date().toISOString() } } });
    written++;
  }
  console.log(`\n${claims.length} claims, ${found} with a stored Letter of Authority`);
  for (const s of skipped) console.log(`  LEFT ALONE — ${s}`);
  if (APPLY) console.log(`${written} re-made`);
})().catch((e) => {
  console.error(e.message);
  process.exit(1);
});
