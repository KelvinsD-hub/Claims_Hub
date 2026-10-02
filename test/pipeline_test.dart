// The app's copy of the stage table. The server's copy
// (firebase/functions/pipeline.js, tested by pipeline.test.js) is the one
// that is enforced; these cases are the same ones, so a difference between
// the two shows up as a failure on one side.

import 'package:flutter_test/flutter_test.dart';

import 'package:claims_hub/backend/services/pipeline.dart';

void main() {
  const lead = RecordKind.lead;
  const claim = RecordKind.claim;

  test('lead moves', () {
    expect(allowedMoves(lead, LeadStage.newLead, 'Agent'),
        [LeadStage.contacted, LeadStage.qualified, LeadStage.rejected]);
    expect(allowedMoves(lead, LeadStage.contacted, 'Agent'),
        [LeadStage.qualified, LeadStage.rejected]);
    expect(allowedMoves(lead, LeadStage.qualified, 'Super Admin'), isEmpty);
    expect(allowedMoves(lead, LeadStage.rejected, 'Agent'), isEmpty);
    expect(allowedMoves(lead, LeadStage.rejected, 'Manager'),
        [LeadStage.newLead]);
  });

  test('claim moves along the normal road', () {
    const road = [
      ClaimStage.detailsPending,
      ClaimStage.termsPending,
      ClaimStage.readyForReview,
      ClaimStage.underReview,
      ClaimStage.demandPending,
      ClaimStage.awaitingReply,
      ClaimStage.withSolicitor,
      ClaimStage.won,
    ];
    for (var i = 0; i < road.length - 1; i++) {
      expect(allowedMoves(claim, road[i], 'Agent'), contains(road[i + 1]),
          reason: '${road[i]} → ${road[i + 1]}');
    }
  });

  test('claim moves that must not be offered', () {
    expect(allowedMoves(claim, ClaimStage.detailsPending, 'Super Admin'),
        isNot(contains(ClaimStage.won)));
    expect(allowedMoves(claim, ClaimStage.readyForReview, 'Agent'),
        isNot(contains(ClaimStage.withSolicitor)));
    expect(allowedMoves(claim, ClaimStage.won, 'Agent'), isEmpty);
    expect(allowedMoves(claim, ClaimStage.won, 'Admin'),
        contains(ClaimStage.paid));
    expect(allowedMoves(claim, ClaimStage.withdrawn, 'Solicitor'), isEmpty);
  });

  test('old stage names are understood', () {
    expect(canonicalStage(claim, 'Claim Won'), ClaimStage.won);
    expect(canonicalStage(claim, 'Submit to Solicitor'),
        ClaimStage.demandPending);
    expect(canonicalStage(lead, 'Not Qualified'), LeadStage.rejected);
    expect(canonicalStage(lead, ''), LeadStage.newLead);
    expect(allowedMoves(claim, 'Submit to Solicitor', 'Agent'),
        contains(ClaimStage.awaitingReply));
  });

  test('closing without an outcome needs a reason', () {
    expect(moveNeedsReason(LeadStage.rejected), isTrue);
    expect(moveNeedsReason(ClaimStage.withdrawn), isTrue);
    expect(moveNeedsReason(ClaimStage.won), isFalse);
  });

  test('every claim stage is reachable or a starting point', () {
    final reachable = <String>{ClaimStage.detailsPending};
    for (final stage in ClaimStage.all) {
      reachable.addAll(allowedMoves(claim, stage, 'Super Admin'));
    }
    expect(reachable, containsAll(ClaimStage.all));
  });
}
