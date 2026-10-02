import 'package:claims_hub/backend/services/casework.dart';
import 'package:claims_hub/backend/services/monitoring.dart';
import 'package:claims_hub/backend/services/pipeline.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.now();
  DateTime days(int n) => now.add(Duration(days: n));

  WorkItem claim(
    String id,
    String stage, {
    String handler = 'ada',
    String lawyer = '',
    int? dueIn,
    int inStage = 0,
    double claimed = 0,
    double? recovered,
    String airlineSend = '',
  }) =>
      WorkItem(
        kind: RecordKind.claim,
        id: id,
        name: 'Client $id',
        stage: stage,
        stageSince: days(-inStage),
        amountClaimed: claimed,
        airlineSendStatus: airlineSend,
        work: Casework.of({
          if (handler.isNotEmpty) 'handler_uid': handler,
          if (lawyer.isNotEmpty) 'lawyer_uid': lawyer,
          if (dueIn != null) 'next_action': 'Do the thing',
          if (dueIn != null) 'next_action_due': days(dueIn),
          if (recovered != null) 'amount_recovered': recovered,
        }),
      );

  WorkItem lead(String id, String stage, {String handler = '', int? dueIn}) =>
      WorkItem(
        kind: RecordKind.lead,
        id: id,
        name: 'Lead $id',
        stage: stage,
        work: Casework.of({
          if (handler.isNotEmpty) 'handler_uid': handler,
          if (dueIn != null) 'next_action': 'Contact the lead',
          if (dueIn != null) 'next_action_due': days(dueIn),
        }),
      );

  test('open and closed are told apart', () {
    expect(claim('a', ClaimStage.awaitingReply).isOpen, isTrue);
    expect(claim('b', ClaimStage.won).isOpen, isFalse);
    expect(claim('c', ClaimStage.paid).isWon, isTrue);
    expect(lead('d', LeadStage.contacted).isOpen, isTrue);
    expect(lead('e', LeadStage.qualified).isOpen, isFalse);
  });

  test('an old stage name is counted under its new one', () {
    expect(claim('a', 'Claim Won').stage, ClaimStage.won);
  });

  test('the pipeline counts open records per stage, in order', () {
    final items = [
      claim('a', ClaimStage.detailsPending, dueIn: -2, inStage: 9),
      claim('b', ClaimStage.detailsPending, dueIn: 3, inStage: 1),
      claim('c', ClaimStage.detailsPending, dueIn: 3, inStage: 4),
      claim('d', ClaimStage.awaitingReply, dueIn: 10),
      claim('e', ClaimStage.won),
      lead('f', LeadStage.newLead, dueIn: -1),
    ];
    final claims = pipelineCounts(RecordKind.claim, items, now);
    expect(claims.map((s) => s.stage), ClaimStage.open);
    final details = claims.first;
    expect(details.count, 3);
    expect(details.overdue, 1);
    expect(details.medianDays, 4);
    expect(claims.fold<int>(0, (t, s) => t + s.count), 4,
        reason: 'closed claims and leads are not in the claim pipeline');

    final leads = pipelineCounts(RecordKind.lead, items, now);
    expect(leads.map((s) => s.count), [1, 0]);
    expect(leads.first.overdue, 1);
  });

  test('attention: overdue first by how late, then the other reasons', () {
    final items = [
      claim('late', ClaimStage.underReview, dueIn: -1),
      claim('later', ClaimStage.underReview, dueIn: -6),
      claim('fine', ClaimStage.underReview, dueIn: 4),
      claim('nobody', ClaimStage.readyForReview, handler: '', dueIn: 2),
      claim('nolawyer', ClaimStage.withSolicitor, dueIn: 2),
      claim('haslawyer', ClaimStage.withSolicitor, lawyer: 'sola', dueIn: 2),
      claim('bounced', ClaimStage.demandPending,
          dueIn: 1, airlineSend: 'Send failed'),
      claim('idle', ClaimStage.termsPending),
      claim('closed', ClaimStage.lost, handler: ''),
    ];
    final list = attentionList(items);
    List<String> ids(Attention reason) =>
        list.where((a) => a.reason == reason).map((a) => a.item.id).toList();

    expect(ids(Attention.overdue), ['later', 'late']);
    expect(ids(Attention.unassigned), ['nobody', 'nolawyer']);
    expect(ids(Attention.sendFailed), ['bounced']);
    expect(ids(Attention.noNextAction), ['idle']);
    expect(list.any((a) => a.item.id == 'closed'), isFalse,
        reason: 'a closed claim needs nothing');
    expect(list.any((a) => a.item.id == 'fine' || a.item.id == 'haslawyer'),
        isFalse);
  });

  test('staff load counts open work, overdue work and recent activity', () {
    final items = [
      claim('a', ClaimStage.underReview, handler: 'ada', dueIn: -1),
      claim('b', ClaimStage.withSolicitor,
          handler: 'ada', lawyer: 'sola', dueIn: 3),
      claim('c', ClaimStage.won, handler: 'ada'),
      lead('d', LeadStage.newLead, handler: 'ada', dueIn: 1),
    ];
    final events = [
      LogEvent(action: 'Stage changed', description: '', actorUid: 'ada', actorName: 'Ada', at: days(-1)),
      LogEvent(action: 'Note added', description: '', actorUid: 'ada', actorName: 'Ada', at: days(-20)),
      LogEvent(action: 'Stage changed', description: '', actorUid: '', actorName: 'System', at: days(0)),
    ];
    final loads = staffLoads([
      (uid: 'sola', name: 'Sola', role: 'Solicitor'),
      (uid: 'ada', name: 'Ada', role: 'Agent'),
      (uid: 'idle', name: 'Idle', role: 'Agent'),
    ], items, events, now);

    expect(loads.map((l) => l.uid), ['ada', 'sola', 'idle'],
        reason: 'busiest first');
    final ada = loads.first;
    expect(ada.openClaims, 2);
    expect(ada.openLeads, 1);
    expect(ada.overdue, 1);
    expect(ada.actionsThisWeek, 1);
    expect(ada.lastActive!.isAfter(days(-2)), isTrue);
    expect(loads[1].openClaims, 1, reason: 'the lawyer on a claim carries it too');
    expect(loads[2].open, 0);
    expect(loads[2].lastActive, isNull);
  });

  test('money', () {
    final money = Money([
      claim('a', ClaimStage.awaitingReply, claimed: 100000),
      claim('b', ClaimStage.detailsPending, claimed: 50000),
      claim('c', ClaimStage.won, claimed: 80000, recovered: 80000),
      claim('d', ClaimStage.paid, claimed: 40000, recovered: 20000),
      claim('e', ClaimStage.won),
      claim('f', ClaimStage.lost, claimed: 99999),
    ]);
    expect(money.inPipeline, 150000);
    expect(money.wonCount, 3);
    expect(money.lostCount, 1);
    expect(money.recovered, 100000);
    expect(money.fees, 30000);
    expect(money.awaitingPayout, 2);
    expect(money.wonWithoutAmount, 1);
    expect(money.winRate, 0.75);
  });

  test('no decided claims means no win rate', () {
    expect(Money([claim('a', ClaimStage.underReview)]).winRate, isNull);
  });
}
