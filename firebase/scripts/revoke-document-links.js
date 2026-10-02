/**
 * Switch off the permanent links on client documents already in storage.
 *
 * Until now every generated letter and uploaded file was stored with a
 * download token, and the link carrying it (…?alt=media&token=…) was saved on
 * the claim. That link opens the file for anyone who has it, signed in or
 * not. New documents are stored without one (functions/documents.js); this
 * removes the token from the old ones, so their saved links stop working.
 *
 *   firebase login                            # once; the script uses that sign-in
 *   node revoke-document-links.js             # dry run: prints what would change
 *   node revoke-document-links.js --apply     # removes the tokens
 *
 * Covers everything under claims/, plus client evidence that the first
 * evidence form stored under users/…/uploads (found through the claims that
 * point at it — profile photos in the same folders are left alone, since the
 * app shows those by link).
 *
 * The files themselves are untouched, and the CRM keeps opening them: it
 * asks the staffDocument function, which does not use the token. Deploy that
 * function and the app BEFORE running this with --apply, or staff lose
 * access to the documents until they are.
 *
 * Safe to run more than once. Not reversible, and not meant to be.
 */
const fs = require('fs');
const os = require('os');
const path = require('path');
const https = require('https');
const { storagePathOf } = require('../functions/documents');

const PROJECT = process.env.GOOGLE_CLOUD_PROJECT || 'msmcrm-g24k37';
const BUCKET = process.env.STORAGE_BUCKET || `${PROJECT}.firebasestorage.app`;
const APPLY = process.argv.includes('--apply');
const FIRESTORE = `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents`;
const STORAGE = `https://storage.googleapis.com/storage/v1/b/${BUCKET}/o`;

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

/** Every object under `prefix`, as { name, hasToken }. */
async function listObjects(prefix) {
  const out = [];
  let pageToken = '';
  do {
    const page = await request('GET',
      `${STORAGE}?prefix=${encodeURIComponent(prefix)}&maxResults=500&fields=items(name,metadata),nextPageToken` +
      (pageToken ? `&pageToken=${encodeURIComponent(pageToken)}` : ''));
    for (const o of page.items || []) {
      out.push({ name: o.name, hasToken: Boolean((o.metadata || {}).firebaseStorageDownloadTokens) });
    }
    pageToken = page.nextPageToken || '';
  } while (pageToken);
  return out;
}

/** Storage paths of client evidence that sits outside claims/. */
async function legacyEvidencePaths() {
  const paths = new Set();
  let pageToken = '';
  do {
    const page = await request('GET',
      `${FIRESTORE}/claims?pageSize=300&mask.fieldPaths=attached_document${pageToken ? `&pageToken=${pageToken}` : ''}`);
    for (const doc of page.documents || []) {
      const values = (((doc.fields || {}).attached_document || {}).arrayValue || {}).values || [];
      for (const v of values) {
        const p = storagePathOf(v.stringValue);
        if (p && /^users\/[^/]+\/uploads\//.test(p)) paths.add(p);
      }
    }
    pageToken = page.nextPageToken || '';
  } while (pageToken);
  return [...paths];
}

(async () => {
  console.log(APPLY ? `APPLYING to ${BUCKET}` : `Dry run against ${BUCKET} — nothing will be changed. Add --apply to change.`);

  const objects = await listObjects('claims/');
  for (const p of await legacyEvidencePaths()) {
    const found = await listObjects(p);
    objects.push(...found.filter((o) => o.name === p));
  }

  const linked = objects.filter((o) => o.hasToken);
  console.log(`\n${objects.length} client documents in storage`);
  console.log(`  ${String(linked.length).padStart(3)}  have a permanent link`);
  console.log(`  ${String(objects.length - linked.length).padStart(3)}  already have none`);
  if (!APPLY) {
    for (const o of linked.slice(0, 40)) console.log(`       ${o.name}`);
    if (linked.length > 40) console.log(`       … and ${linked.length - 40} more`);
    return;
  }

  let changed = 0;
  for (const o of linked) {
    await request('PATCH', `${STORAGE}/${encodeURIComponent(o.name)}`,
      { metadata: { firebaseStorageDownloadTokens: null } });
    changed++;
  }
  console.log(`  ${changed} links switched off`);
})().catch((e) => {
  console.error(e.message);
  process.exit(1);
});
