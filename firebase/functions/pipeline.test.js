// The stage table. Plain node:  node pipeline.test.js
const p = require('./pipeline');
const { LEAD, CLAIM } = p;

let passed = 0;
let failed = 0;
function check(name, ok) {
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}`);
  ok ? passed++ : failed++;
}
function allowed(args) {
  try { p.planMove(args); return true; } catch (e) { return false; }
}
function refusal(args) {
  try { p.planMove(args); return null; } catch (e) { return e; }
}
const agent = (kind, current, to, reason) => ({ kind, current, to, role: 'Agent', reason });
const manager = (kind, current, to, reason) => ({ kind, current, to, role: 'Manager', reason });

// Leads
check('new lead can be contacted', allowed(agent('lead', LEAD.NEW, LEAD.CONTACTED)));
check('new lead can be qualified directly', allowed(agent('lead', LEAD.NEW, LEAD.QUALIFIED)));
check('contacted lead can be qualified', allowed(agent('lead', LEAD.CONTACTED, LEAD.QUALIFIED)));
check('rejecting a lead needs a reason', !allowed(agent('lead', LEAD.NEW, LEAD.REJECTED)));
check('rejecting a lead with a reason works', allowed(agent('lead', LEAD.NEW, LEAD.REJECTED, 'Flight did not touch Nigeria')));
check('a qualified lead cannot be moved again', !allowed(manager('lead', LEAD.QUALIFIED, LEAD.NEW)));
check('an agent cannot reopen a rejected lead', !allowed(agent('lead', LEAD.REJECTED, LEAD.NEW)));
check('a manager can reopen a rejected lead', allowed(manager('lead', LEAD.REJECTED, LEAD.NEW)));
check('a lead with no status counts as new', allowed(agent('lead', undefined, LEAD.CONTACTED)));
check('legacy "Under Review" lead is treated as contacted', allowed(agent('lead', 'Under Review', LEAD.QUALIFIED)));
check('a lead cannot take a claim stage', !allowed(agent('lead', LEAD.NEW, CLAIM.WON)));

// Claims: the normal road
const road = [
  CLAIM.DETAILS_PENDING, CLAIM.TERMS_PENDING, CLAIM.READY_FOR_REVIEW, CLAIM.UNDER_REVIEW,
  CLAIM.DEMAND_PENDING, CLAIM.AWAITING_REPLY, CLAIM.WITH_SOLICITOR, CLAIM.WON,
];
for (let i = 0; i < road.length - 1; i++) {
  check(`claim: ${road[i]} → ${road[i + 1]}`, allowed(agent('claim', road[i], road[i + 1])));
}
check('claim: airline pays without a solicitor', allowed(agent('claim', CLAIM.AWAITING_REPLY, CLAIM.WON)));
check('claim: airline refuses', allowed(agent('claim', CLAIM.AWAITING_REPLY, CLAIM.LOST)));
check('claim: a refusal can be escalated to the legal team', allowed(agent('claim', CLAIM.LOST, CLAIM.WITH_SOLICITOR)));
check('claim: review can send it back for more evidence', allowed(agent('claim', CLAIM.UNDER_REVIEW, CLAIM.DETAILS_PENDING)));

// Claims: what must not happen
check('claim cannot jump from evidence straight to won', !allowed(agent('claim', CLAIM.DETAILS_PENDING, CLAIM.WON)));
check('claim cannot go to the solicitor before a demand', !allowed(agent('claim', CLAIM.READY_FOR_REVIEW, CLAIM.WITH_SOLICITOR)));
check('claim cannot move to the stage it is already at', !allowed(agent('claim', CLAIM.WON, CLAIM.WON)));
check('withdrawing a claim needs a reason', !allowed(agent('claim', CLAIM.UNDER_REVIEW, CLAIM.WITHDRAWN)));
check('withdrawing a claim with a reason works', allowed(agent('claim', CLAIM.UNDER_REVIEW, CLAIM.WITHDRAWN, 'Client cancelled')));
check('an agent cannot mark a claim paid', !allowed(agent('claim', CLAIM.WON, CLAIM.PAID)));
check('a manager can mark a won claim paid', allowed(manager('claim', CLAIM.WON, CLAIM.PAID)));
check('an agent cannot reopen a withdrawn claim', !allowed(agent('claim', CLAIM.WITHDRAWN, CLAIM.UNDER_REVIEW)));
check('a manager can reopen a withdrawn claim', allowed(manager('claim', CLAIM.WITHDRAWN, CLAIM.UNDER_REVIEW)));
check('a made-up stage is refused', !allowed(manager('claim', CLAIM.UNDER_REVIEW, 'Sorted')));

// Legacy values still on old records
check('legacy "Claim Won" is treated as Won', p.canonical('claim', 'Claim Won') === CLAIM.WON);
check('legacy "Submit to Solicitor" is treated as Demand Pending', p.canonical('claim', 'Submit to Solicitor') === CLAIM.DEMAND_PENDING);
check('a legacy claim can still be moved', allowed(agent('claim', 'Submit to Solicitor', CLAIM.AWAITING_REPLY)));

// Messages are for people
const e1 = refusal(agent('claim', CLAIM.DETAILS_PENDING, CLAIM.WON));
check('a refused move says where the claim can go', e1 && e1.status === 409 && e1.message.includes('Terms Pending'));
const e2 = refusal(agent('claim', CLAIM.WON, CLAIM.PAID));
check('a manager-only move says so', e2 && e2.status === 403 && e2.message.includes('Manager'));

// allowedMoves drives the menus
check('agent menu for a won claim is empty', p.allowedMoves('claim', CLAIM.WON, 'Agent').length === 0);
check('manager menu for a won claim offers Paid', p.allowedMoves('claim', CLAIM.WON, 'Super Admin').includes(CLAIM.PAID));

// Every stage named in a move exists, and every stage has a row
const claimStages = Object.values(CLAIM);
check('every claim stage has a row in the table', claimStages.every((s) => p.CLAIM_MOVES[s]));
check('every claim move points at a real stage', Object.values(p.CLAIM_MOVES)
  .every((m) => [...m.to, ...(m.managerOnly || [])].every((s) => claimStages.includes(s))));
check('every legacy claim value maps to a real stage', Object.values(p.CLAIM_LEGACY).every((s) => claimStages.includes(s)));
check('every legacy lead value maps to a real stage', Object.values(p.LEAD_LEGACY).every((s) => Object.values(LEAD).includes(s)));

// The app keeps its own copy of the table for its menus. Same stages, same moves.
{
  const fs = require('fs');
  const path = require('path');
  const dart = fs.readFileSync(
    path.join(__dirname, '..', '..', 'lib', 'backend', 'services', 'pipeline.dart'), 'utf8');
  const constants = {};
  for (const [, cls, body] of dart.matchAll(/abstract final class (LeadStage|ClaimStage) \{([\s\S]*?)\n\}/g)) {
    for (const [, name, value] of body.matchAll(/static const (\w+) = '([^']+)';/g)) {
      constants[`${cls}.${name}`] = value;
    }
  }
  const dartStages = (cls) => Object.entries(constants)
    .filter(([k]) => k.startsWith(cls)).map(([, v]) => v).sort();
  check('app and server list the same lead stages',
    JSON.stringify(dartStages('LeadStage')) === JSON.stringify(Object.values(LEAD).sort()));
  check('app and server list the same claim stages',
    JSON.stringify(dartStages('ClaimStage')) === JSON.stringify(Object.values(CLAIM).sort()));

  const parseMoves = (name) => {
    const block = dart.replace(/\r\n/g, '\n')
      .match(new RegExp(`const Map<String, _Moves> ${name} = \\{([\\s\\S]*?)\\n\\};`))[1];
    const out = {};
    for (const [, from, args] of block.matchAll(/((?:Lead|Claim)Stage\.\w+):\s*_Moves\(([\s\S]*?)\),(?:\n|$)/g)) {
      const lists = [...args.matchAll(/\[([\s\S]*?)\]/g)].map((m) =>
        [...m[1].matchAll(/(?:Lead|Claim)Stage\.\w+/g)].map((x) => constants[x[0]]));
      out[constants[from]] = { to: lists[0] || [], managerOnly: lists[1] || [] };
    }
    return out;
  };
  const same = (js, dartTable) =>
    Object.keys(js).length === Object.keys(dartTable).length &&
    Object.entries(js).every(([from, m]) => dartTable[from] &&
      JSON.stringify(m.to) === JSON.stringify(dartTable[from].to) &&
      JSON.stringify(m.managerOnly || []) === JSON.stringify(dartTable[from].managerOnly));
  check('app and server allow the same lead moves', same(p.LEAD_MOVES, parseMoves('_leadMoves')));
  check('app and server allow the same claim moves', same(p.CLAIM_MOVES, parseMoves('_claimMoves')));
}

console.log(`\n${passed} passed, ${failed} failed`);
process.exit(failed ? 1 : 0);
