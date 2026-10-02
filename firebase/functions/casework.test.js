// Casework rules. Plain node:  node casework.test.js
const c = require('./casework');
const { LEAD, CLAIM, StageError } = require('./pipeline');
const { LEGAL } = c;

let passed = 0;
let failed = 0;
function check(name, ok) {
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}`);
  ok ? passed++ : failed++;
}
function refusal(fn) {
  try { fn(); return null; } catch (e) { return e instanceof StageError ? e : null; }
}

const agent = { uid: 'a1', name: 'Ada', role: 'Agent' };
const lawyer = { uid: 's1', name: 'Sola', role: 'Solicitor' };
const boss = { uid: 'm1', name: 'Musa', role: 'Manager' };
const approvedAgent = { approved: true, role: 'Agent' };
const approvedLawyer = { approved: true, role: 'Solicitor' };

// Next actions
check('a new lead is due for contact within a day', c.nextActionFor('lead', LEAD.NEW).days === 1);
check('a qualified lead has nothing left to do', c.nextActionFor('lead', LEAD.QUALIFIED) === null);
check('the airline gets 14 days to answer a demand', c.nextActionFor('claim', CLAIM.AWAITING_REPLY).days === 14);
check('the final notice gives 7 days', c.nextActionFor('claim', CLAIM.WITH_SOLICITOR, LEGAL.NOTICE_SENT).days === 7);
check('a fresh escalation asks for a legal review', /final notice/.test(c.nextActionFor('claim', CLAIM.WITH_SOLICITOR).text));
check('a won claim asks for the client to be paid', /Pay the client/.test(c.nextActionFor('claim', CLAIM.WON).text));
check('a paid claim has nothing left to do', c.nextActionFor('claim', CLAIM.PAID) === null);
check('a lost claim has nothing left to do', c.nextActionFor('claim', CLAIM.LOST) === null);
check('every open claim stage has a next action', [
  CLAIM.DETAILS_PENDING, CLAIM.TERMS_PENDING, CLAIM.READY_FOR_REVIEW, CLAIM.UNDER_REVIEW,
  CLAIM.DEMAND_PENDING, CLAIM.AWAITING_REPLY, CLAIM.WITH_SOLICITOR,
].every((s) => c.nextActionFor('claim', s)));
check('every legal stage has a next action', c.LEGAL_ORDER.every((s) => c.nextActionFor('claim', CLAIM.WITH_SOLICITOR, s)));

// Dates: end of day in Lagos (UTC+1)
const noon = new Date('2026-10-02T12:00:00Z');
check('due in 14 days lands on the 16th', c.dueIn(14, noon).toISOString() === '2026-10-16T22:59:59.000Z');
check('late evening UTC is already tomorrow in Lagos', c.dueIn(0, new Date('2026-10-02T23:30:00Z')).toISOString() === '2026-10-03T22:59:59.000Z');
check('a typed date becomes the end of that day', c.dueOn('2026-10-09').toISOString() === '2026-10-09T22:59:59.000Z');
check('a nonsense date is refused', c.dueOn('2026-02-31') === null && c.dueOn('next week') === null);

// Assignment
const plan = (o) => () => c.planAssignment({ kind: 'lead', slot: 'handler', ...o });
check('anyone can take an unassigned record', !refusal(plan({ currentUid: '', toUid: 'a1', toUser: approvedAgent, staff: agent })));
check('an agent cannot take a record from someone else', refusal(plan({ currentUid: 'a2', toUid: 'a1', toUser: approvedAgent, staff: agent }))?.status === 403);
check('an agent cannot assign to someone else', refusal(plan({ currentUid: '', toUid: 'a2', toUser: approvedAgent, staff: agent }))?.status === 403);
check('an agent can hand back their own record', !refusal(plan({ currentUid: 'a1', toUid: '', toUser: null, staff: agent })));
check('an agent cannot unassign someone else', refusal(plan({ currentUid: 'a2', toUid: '', toUser: null, staff: agent }))?.status === 403);
check('a manager can assign to anyone', !refusal(plan({ currentUid: '', toUid: 'a2', toUser: approvedAgent, staff: boss })));
check('a manager can reassign', !refusal(plan({ currentUid: 'a1', toUid: 'a2', toUser: approvedAgent, staff: boss })));
check('nobody can assign to an unapproved account', refusal(plan({ currentUid: '', toUid: 'x', toUser: { approved: false, role: 'Agent' }, staff: boss }))?.status === 400);
check('nobody can assign to an account that does not exist', refusal(plan({ currentUid: '', toUid: 'x', toUser: null, staff: boss }))?.status === 400);
check('assigning to the current owner is refused', refusal(plan({ currentUid: 'a1', toUid: 'a1', toUser: approvedAgent, staff: agent }))?.status === 409);
check('a lead has no lawyer', refusal(() => c.planAssignment({ kind: 'lead', slot: 'lawyer', currentUid: '', toUid: 's1', toUser: approvedLawyer, staff: lawyer }))?.status === 400);
check('a solicitor can take a claim as its lawyer', !refusal(() => c.planAssignment({ kind: 'claim', slot: 'lawyer', currentUid: '', toUid: 's1', toUser: approvedLawyer, staff: lawyer })));
check('an agent cannot be the lawyer on a claim', refusal(() => c.planAssignment({ kind: 'claim', slot: 'lawyer', currentUid: '', toUid: 'a1', toUser: approvedAgent, staff: agent }))?.status === 400);
check('a manager can be the lawyer on a claim', !refusal(() => c.planAssignment({ kind: 'claim', slot: 'lawyer', currentUid: '', toUid: 'm1', toUser: { approved: true, role: 'Manager' }, staff: boss })));

// Legal stages
const legal = (o) => () => c.planLegalStage({ claimStage: CLAIM.WITH_SOLICITOR, role: 'Solicitor', ...o });
check('a lawyer can record the NCAA complaint', !refusal(legal({ current: LEGAL.NOTICE_SENT, to: LEGAL.NCAA })));
check('a claim with no legal stage counts as in review', c.planLegalStage({ claimStage: CLAIM.WITH_SOLICITOR, role: 'Solicitor', current: undefined, to: LEGAL.NOTICE_SENT }).from === LEGAL.REVIEW);
check('an agent cannot change the legal stage', refusal(legal({ role: 'Agent', current: LEGAL.REVIEW, to: LEGAL.NCAA }))?.status === 403);
check('a manager can change the legal stage', !refusal(legal({ role: 'Manager', current: LEGAL.REVIEW, to: LEGAL.NCAA })));
check('going to court needs a reason', refusal(legal({ current: LEGAL.NCAA, to: LEGAL.COURT }))?.status === 400);
check('going to court with a reason is recorded', !refusal(legal({ current: LEGAL.NCAA, to: LEGAL.COURT, note: 'NCAA directive ignored; client instructs us to sue' })));
check('a claim not with the legal team has no legal stage', refusal(() => c.planLegalStage({ claimStage: CLAIM.AWAITING_REPLY, role: 'Solicitor', current: '', to: LEGAL.NCAA }))?.status === 409);
check('a made-up legal stage is refused', refusal(legal({ current: LEGAL.REVIEW, to: 'Arbitration' }))?.status === 400);
check('moving to the same legal stage is refused', refusal(legal({ current: LEGAL.NCAA, to: LEGAL.NCAA }))?.status === 409);

// The app keeps its own copy of the legal stages and the deadlines it shows.
{
  const fs = require('fs');
  const path = require('path');
  const dart = fs.readFileSync(
    path.join(__dirname, '..', '..', 'lib', 'backend', 'services', 'casework.dart'), 'utf8');
  const body = dart.match(/abstract final class LegalStage \{([\s\S]*?)\n\}/)[1];
  const stages = [...body.matchAll(/static const \w+ = '([^']+)';/g)].map((m) => m[1]);
  check('app and server list the same legal stages, in the same order',
    JSON.stringify(stages) === JSON.stringify(c.LEGAL_ORDER));
}

console.log(`\n${passed} passed, ${failed} failed`);
process.exit(failed ? 1 : 0);
