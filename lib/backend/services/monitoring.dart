import 'casework.dart';
import 'pipeline.dart';

/// The numbers behind the Monitor page: where every lead and claim stands,
/// what needs attention, who is carrying what, and the money.
///
/// Pure: works on plain values so it can be tested without Firebase. The page
/// (lib/pages/monitor) turns records into [WorkItem]s and draws the result.

/// The fee Claims Assist keeps from a recovery (terms of engagement).
const feeRate = 0.30;

/// One lead or claim, reduced to what monitoring needs.
class WorkItem {
  WorkItem({
    required this.kind,
    required this.id,
    required this.name,
    required String stage,
    required this.work,
    this.stageSince,
    this.amountClaimed = 0,
    this.airlineSendStatus = '',
    this.noticeSendStatus = '',
    this.source,
  }) : stage = canonicalStage(kind, stage);

  final RecordKind kind;
  final String id;

  /// Who it is about.
  final String name;
  final String stage;
  final Casework work;

  /// When it reached its stage; its creation date where that was not kept.
  final DateTime? stageSince;

  /// What the client is claiming, in naira; 0 where not known.
  final double amountClaimed;
  final String airlineSendStatus;
  final String noticeSendStatus;

  /// The record this came from, for the page to open.
  final Object? source;

  bool get isOpen => kind == RecordKind.lead
      ? stage == LeadStage.newLead || stage == LeadStage.contacted
      : ClaimStage.open.contains(stage);

  bool get isWon => stage == ClaimStage.won || stage == ClaimStage.paid;

  int daysInStage(DateTime now) =>
      stageSince == null ? 0 : now.difference(stageSince!).inDays;
}

/// One stage of the pipeline.
class StageCount {
  StageCount(this.stage, this.items, DateTime now)
      : overdue = items.where((i) => i.work.isOverdue).length,
        medianDays = _median(items.map((i) => i.daysInStage(now)).toList());

  final String stage;
  final List<WorkItem> items;
  final int overdue;

  /// The typical time a record has been sitting here.
  final int medianDays;

  int get count => items.length;

  static int _median(List<int> values) {
    if (values.isEmpty) return 0;
    values.sort();
    return values[values.length ~/ 2];
  }
}

/// Open records per stage, in pipeline order.
List<StageCount> pipelineCounts(
    RecordKind kind, List<WorkItem> items, DateTime now) {
  final stages = kind == RecordKind.lead
      ? const [LeadStage.newLead, LeadStage.contacted]
      : ClaimStage.open;
  return [
    for (final stage in stages)
      StageCount(stage,
          items.where((i) => i.kind == kind && i.stage == stage).toList(), now),
  ];
}

/// The reasons a record needs someone's attention.
enum Attention { overdue, unassigned, sendFailed, noNextAction }

class AttentionItem {
  const AttentionItem(this.item, this.reason, this.detail);
  final WorkItem item;
  final Attention reason;

  /// "Overdue by 3 days — Chase the client for evidence".
  final String detail;
}

/// Everything open that needs attention, most pressing first within each
/// reason. A record can appear under more than one reason.
List<AttentionItem> attentionList(List<WorkItem> items) {
  final open = items.where((i) => i.isOpen).toList();
  final overdue = open.where((i) => i.work.isOverdue).toList()
    ..sort((a, b) => a.work.nextActionDue!.compareTo(b.work.nextActionDue!));
  return [
    for (final i in overdue)
      AttentionItem(
          i, Attention.overdue, '${i.work.dueLabel} — ${i.work.nextAction}'),
    for (final i in open)
      if (!i.work.hasHandler)
        AttentionItem(i, Attention.unassigned, 'No handler · ${i.stage}')
      else if (i.stage == ClaimStage.withSolicitor && !i.work.hasLawyer)
        AttentionItem(i, Attention.unassigned, 'No lawyer · ${i.stage}'),
    for (final i in open)
      if (i.airlineSendStatus == 'Send failed')
        AttentionItem(
            i, Attention.sendFailed, 'The demand letter failed to send')
      else if (i.noticeSendStatus == 'Send failed')
        AttentionItem(
            i, Attention.sendFailed, 'The final notice failed to send'),
    for (final i in open)
      if (!i.work.hasNextAction)
        AttentionItem(
            i, Attention.noNextAction, 'Nothing scheduled · ${i.stage}'),
  ];
}

/// One event from the log, reduced to what monitoring needs.
class LogEvent {
  const LogEvent({
    required this.action,
    required this.description,
    required this.actorUid,
    required this.actorName,
    required this.at,
  });
  final String action;
  final String description;

  /// Empty for the system and for clients.
  final String actorUid;
  final String actorName;
  final DateTime at;
}

/// What one member of staff is carrying and has been doing.
class StaffLoad {
  StaffLoad({
    required this.uid,
    required this.name,
    required this.role,
    required this.openLeads,
    required this.openClaims,
    required this.overdue,
    required this.actionsThisWeek,
    required this.lastActive,
  });
  final String uid;
  final String name;
  final String role;
  final int openLeads;
  final int openClaims;
  final int overdue;

  /// Entries they put in the event log in the last seven days.
  final int actionsThisWeek;
  final DateTime? lastActive;

  int get open => openLeads + openClaims;
}

/// The load on each of [staff] (uid, name, role), busiest first.
List<StaffLoad> staffLoads(
  List<({String uid, String name, String role})> staff,
  List<WorkItem> items,
  List<LogEvent> events,
  DateTime now,
) {
  final weekAgo = now.subtract(const Duration(days: 7));
  final loads = [
    for (final person in staff)
      () {
        final mine = items
            .where((i) =>
                i.isOpen &&
                (i.work.handlerUid == person.uid ||
                    i.work.lawyerUid == person.uid))
            .toList();
        final theirs = events.where((e) => e.actorUid == person.uid).toList();
        return StaffLoad(
          uid: person.uid,
          name: person.name,
          role: person.role,
          openLeads: mine.where((i) => i.kind == RecordKind.lead).length,
          openClaims: mine.where((i) => i.kind == RecordKind.claim).length,
          overdue: mine.where((i) => i.work.isOverdue).length,
          actionsThisWeek: theirs.where((e) => e.at.isAfter(weekAgo)).length,
          lastActive: theirs.isEmpty
              ? null
              : theirs.map((e) => e.at).reduce((a, b) => a.isAfter(b) ? a : b),
        );
      }(),
  ]..sort((a, b) => b.open.compareTo(a.open));
  return loads;
}

/// The money: what is being claimed, what has come in, what is owed out.
class Money {
  Money(List<WorkItem> claims)
      : inPipeline = claims
            .where((c) => c.isOpen)
            .fold(0.0, (total, c) => total + c.amountClaimed),
        wonCount = claims.where((c) => c.isWon).length,
        lostCount = claims.where((c) => c.stage == ClaimStage.lost).length,
        recovered = claims
            .where((c) => c.isWon)
            .fold(0.0, (total, c) => total + (c.work.amountRecovered ?? 0)),
        awaitingPayout = claims.where((c) => c.stage == ClaimStage.won).length,
        wonWithoutAmount = claims
            .where((c) => c.isWon && c.work.amountRecovered == null)
            .length;

  /// Claimed on claims still open.
  final double inPipeline;
  final int wonCount;
  final int lostCount;

  /// Received from airlines on claims won.
  final double recovered;

  /// Won, and the client has not yet been paid their share.
  final int awaitingPayout;

  /// Won with no amount recorded, so missing from [recovered].
  final int wonWithoutAmount;

  double get fees => recovered * feeRate;

  /// Share of decided claims that were won, or null with none decided.
  double? get winRate =>
      wonCount + lostCount == 0 ? null : wonCount / (wonCount + lostCount);
}

/// One answer the AI assistant gave.
class AiRun {
  const AiRun({
    required this.taskLabel,
    required this.subject,
    required this.requestedBy,
    required this.at,
    required this.costUsd,
    required this.review,
  });

  /// "Case brief", "Lead triage", ...
  final String taskLabel;

  /// Who the lead or claim is about.
  final String subject;
  final String requestedBy;
  final DateTime at;

  /// The run's estimated cost in US dollars.
  final double costUsd;

  /// 'pending', 'useful' or 'not_useful'.
  final String review;
}

/// How the AI assistant has been used over the last [days] days.
class AiUsage {
  AiUsage(List<AiRun> all, DateTime now, {this.days = 30})
      : runs = all
            .where((r) => r.at.isAfter(now.subtract(Duration(days: days))))
            .toList()
          ..sort((a, b) => b.at.compareTo(a.at));

  final int days;

  /// Runs in the period, newest first.
  final List<AiRun> runs;

  int get count => runs.length;
  int get useful => runs.where((r) => r.review == 'useful').length;
  int get notUseful => runs.where((r) => r.review == 'not_useful').length;
  int get unreviewed => count - useful - notUseful;
  double get costUsd => runs.fold(0.0, (total, r) => total + r.costUsd);

  /// Share of reviewed answers staff found useful, or null with none reviewed.
  double? get usefulRate =>
      useful + notUseful == 0 ? null : useful / (useful + notUseful);

  /// Runs per task, most used first.
  List<MapEntry<String, int>> get byTask {
    final counts = <String, int>{};
    for (final r in runs) {
      counts[r.taskLabel] = (counts[r.taskLabel] ?? 0) + 1;
    }
    return counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  }
}
