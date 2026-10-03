/**
 * Fill in what older website leads and their claims are missing.
 *
 *   firebase login                          # once; the script uses that sign-in
 *   node backfill-lead-facts.js             # dry run: prints what would change
 *   node backfill-lead-facts.js --apply     # writes the changes
 *
 * Leads: until October 2026 the website kept the flight number and date only
 * inside initial_summary. They are read from there into flight_number and
 * flight_date.
 *
 * Claims: a claim opened from a lead was given only the email, name and
 * airline. It now gets the flight, date, route, booking reference, delay and
 * reason from its lead (functions/lead-to-claim.js), which the demand letter
 * needs before it can be sent.
 *
 * Only empty fields are filled; nothing a person has typed is overwritten.
 * Safe to run more than once.
 */
const fs = require('fs');
const os = require('os');
const path = require('path');
const https = require('https');
const { claimFieldsFromLead, flightFromSummary } = require('../functions/lead-to-claim');

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

/** The plain strings and numbers of a REST document; other types are skipped. */
function plain(doc) {
  const out = {};
  for (const [k, v] of Object.entries(doc.fields || {})) {
    if ('stringValue' in v) out[k] = v.stringValue;
    else if ('integerValue' in v) out[k] = Number(v.integerValue);
    else if ('doubleValue' in v) out[k] = v.doubleValue;
    else if ('referenceValue' in v) out[k] = v.referenceValue;
  }
  return out;
}

async function patch(doc, update) {
  const fields = {};
  for (const [k, v] of Object.entries(update)) fields[k] = { stringValue: v };
  const mask = Object.keys(fields).map((k) => `updateMask.fieldPaths=${k}`).join('&');
  await request('PATCH', `https://firestore.googleapis.com/v1/${doc.name}?${mask}&currentDocument.exists=true`, { fields });
}

(async () => {
  console.log(APPLY ? `APPLYING to ${PROJECT}` : `Dry run against ${PROJECT} — nothing will be written. Add --apply to write.`);

  const leads = await listAll('leads');
  const leadByName = new Map();
  let leadsChanged = 0;
  for (const doc of leads) {
    const lead = plain(doc);
    const found = flightFromSummary(lead.initial_summary);
    const update = {};
    if (!lead.flight_number && found.flight_number) update.flight_number = found.flight_number;
    if (!lead.flight_date && found.flight_date) update.flight_date = found.flight_date;
    leadByName.set(doc.name, { ...lead, ...update });
    if (!Object.keys(update).length) continue;
    leadsChanged++;
    console.log(`  lead  ${doc.name.split('/').pop()}  ${JSON.stringify(update)}`);
    if (APPLY) await patch(doc, update);
  }

  const claims = await listAll('claims');
  let claimsChanged = 0;
  for (const doc of claims) {
    const claim = plain(doc);
    const lead = leadByName.get(claim.lead_ref);
    if (!lead) continue;
    const update = {};
    for (const [k, v] of Object.entries(claimFieldsFromLead(lead))) {
      if (v && !claim[k]) update[k] = v;
    }
    if (!Object.keys(update).length) continue;
    claimsChanged++;
    console.log(`  claim ${doc.name.split('/').pop()}  ${JSON.stringify(update)}`);
    if (APPLY) await patch(doc, update);
  }

  console.log(`\nleads: ${leads.length} records, ${leadsChanged} to fill in`);
  console.log(`claims: ${claims.length} records, ${claimsChanged} to fill in`);
  if (APPLY) console.log('Written.');
})().catch((e) => {
  console.error(e.message);
  process.exit(1);
});
