import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/services/casework.dart';
import '/backend/services/monitoring.dart';
import '/backend/services/pipeline.dart';
import '/components/brand_colors.dart';
import '/components/case_file_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/leads/leads_options/leads_options_widget.dart';
import '/menus_file/menn_pro/menn_pro_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'monitor_model.dart';
export 'monitor_model.dart';

/// The admins' view of the whole operation: where every lead and claim
/// stands, what needs attention, who is carrying what, what has been
/// happening, and the money.
///
/// Everything here is read live from the leads, claims, staff and event log;
/// the sums are in backend/services/monitoring.dart.
class MonitorWidget extends StatefulWidget {
  const MonitorWidget({super.key});

  static String routeName = 'Monitor';
  static String routePath = '/monitor';

  /// Who the page is for.
  static bool allows(String role) => role == 'Admin' || role == 'Super Admin';

  @override
  State<MonitorWidget> createState() => _MonitorWidgetState();
}

class _MonitorWidgetState extends State<MonitorWidget> {
  late MonitorModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  Attention _attention = Attention.overdue;

  // Heights of the two rows of panels.
  static const double _topRow = 470;
  static const double _bottomRow = 440;
  static const double _aiRow = 360;

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _ai = FirebaseFirestore
      .instance
      .collection('ai_outputs')
      .orderBy('created_at', descending: true)
      .limit(300)
      .snapshots();

  static AiRun? _aiRun(Map<String, dynamic> a) {
    final at = _date(a['created_at']);
    if (at == null) return null;
    return AiRun(
      taskLabel: a['task_label'] as String? ?? 'AI assist',
      subject: a['subject'] as String? ?? '',
      requestedBy: a['requested_by_name'] as String? ?? '',
      at: at,
      costUsd: (a['cost_usd'] as num?)?.toDouble() ?? 0,
      review: a['review_status'] as String? ?? 'pending',
    );
  }

  // Held so the streams are opened once, not on every rebuild.
  late final Stream<List<LeadsRecord>> _leads = queryLeadsRecord();
  late final Stream<List<ClaimsRecord>> _claims = queryClaimsRecord();
  late final Stream<List<UsersRecord>> _staff = queryUsersRecord(
      queryBuilder: (q) => q.where('approved', isEqualTo: true));
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _log =
      FirebaseFirestore.instance
          .collection('activity_logs')
          .orderBy('createdAt', descending: true)
          .limit(400)
          .snapshots();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MonitorModel());
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  static DateTime? _date(dynamic v) =>
      v is DateTime ? v : (v is Timestamp ? v.toDate() : null);

  static WorkItem _leadItem(LeadsRecord lead) => WorkItem(
        kind: RecordKind.lead,
        id: lead.reference.id,
        name: lead.fullName.isNotEmpty
            ? lead.fullName
            : (lead.email.isNotEmpty ? lead.email : 'Unnamed lead'),
        stage: lead.status,
        work: Casework.of(lead.snapshotData),
        stageSince:
            _date(lead.snapshotData['stage_changed_at']) ?? lead.createdAt,
        source: lead,
      );

  static WorkItem _claimItem(ClaimsRecord claim) => WorkItem(
        kind: RecordKind.claim,
        id: claim.reference.id,
        name: claim.fullName.isNotEmpty
            ? claim.fullName
            : (claim.clientEmail.isNotEmpty
                ? claim.clientEmail
                : 'Unnamed client'),
        stage: claim.claimStatus,
        work: Casework.of(claim.snapshotData),
        stageSince:
            _date(claim.snapshotData['stage_changed_at']) ?? claim.createdAt,
        amountClaimed: double.tryParse(
                claim.claimsAmount.replaceAll(RegExp(r'[^0-9.]'), '')) ??
            0,
        airlineSendStatus: claim.airlineEmailStatus,
        noticeSendStatus:
            claim.snapshotData['solicitor_email_status'] as String? ?? '',
        source: claim,
      );

  static LogEvent? _event(Map<String, dynamic> e) {
    final at = _date(e['createdAt']);
    if (at == null) return null;
    final actor = e['performedBy'];
    return LogEvent(
      action: e['action'] as String? ?? 'Event',
      description: e['description'] as String? ?? '',
      actorUid: actor is DocumentReference ? actor.id : '',
      actorName: e['performedByName'] as String? ?? 'System',
      at: at,
    );
  }

  void _open(WorkItem item) {
    final source = item.source;
    if (source is ClaimsRecord) {
      showCaseFile(context, source.reference);
    } else if (source is LeadsRecord) {
      showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0.0,
          child: LeadsOptionsWidget(leadRef: source),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    final theme = FlutterFlowTheme.of(context);

    return Title(
      title: 'Monitor',
      color: theme.primary.withAlpha(0XFF),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: theme.primaryBackground,
        body: SafeArea(
          top: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              wrapWithModel(
                model: _model.mennProModel,
                updateCallback: () => safeSetState(() {}),
                child: MennProWidget(selectedPage: 10),
              ),
              Expanded(
                child: AuthUserStreamWidget(
                  builder: (context) => MonitorWidget.allows(
                          valueOrDefault(currentUserDocument?.role, ''))
                      ? _content(context)
                      : Center(
                          child: Text(
                            'This page is for Admins and Super Admins.',
                            style: GoogleFonts.inter(
                                fontSize: 15, color: theme.secondaryText),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    return StreamBuilder<List<LeadsRecord>>(
      stream: _leads,
      builder: (context, leads) => StreamBuilder<List<ClaimsRecord>>(
        stream: _claims,
        builder: (context, claims) => StreamBuilder<List<UsersRecord>>(
          stream: _staff,
          builder: (context, staff) =>
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _log,
            builder: (context, log) {
              if (!leads.hasData || !claims.hasData || !staff.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final now = DateTime.now();
              final claimItems = claims.data!.map(_claimItem).toList();
              final items = [
                ...leads.data!.map(_leadItem),
                ...claimItems,
              ];
              final events = (log.data?.docs ?? [])
                  .map((d) => _event(d.data()))
                  .whereType<LogEvent>()
                  .toList();
              return _dashboard(
                context,
                now: now,
                items: items,
                attention: attentionList(items),
                money: Money(claimItems),
                loads: staffLoads(
                  [
                    for (final u in staff.data!)
                      (
                        uid: u.reference.id,
                        name:
                            u.displayName.isNotEmpty ? u.displayName : u.email,
                        role: u.role,
                      ),
                  ],
                  items,
                  events,
                  now,
                ),
                events: events,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _dashboard(
    BuildContext context, {
    required DateTime now,
    required List<WorkItem> items,
    required List<AttentionItem> attention,
    required Money money,
    required List<StaffLoad> loads,
    required List<LogEvent> events,
  }) {
    final theme = FlutterFlowTheme.of(context);
    final open = items.where((i) => i.isOpen).toList();
    final openLeads = open.where((i) => i.kind == RecordKind.lead).length;
    final openClaims = open.length - openLeads;
    int count(Attention reason) =>
        attention.where((a) => a.reason == reason).length;
    final overdue = count(Attention.overdue);
    final unassigned = count(Attention.unassigned);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monitor',
            style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.primaryText),
          ),
          const SizedBox(height: 2),
          Text(
            'Live · ${dateTimeFormat('EEE d MMM, HH:mm', now)}',
            style: GoogleFonts.inter(fontSize: 13, color: theme.secondaryText),
          ),
          const SizedBox(height: 20),

          // Headline figures
          Row(
            children: [
              _Tile(
                label: 'Open work',
                value: '${open.length}',
                note: '$openLeads leads · $openClaims claims',
              ),
              const SizedBox(width: 14),
              _Tile(
                label: 'Overdue',
                value: '$overdue',
                note: open.isEmpty
                    ? 'nothing open'
                    : '${(overdue * 100 / open.length).round()}% of open work',
                alert: overdue > 0,
              ),
              const SizedBox(width: 14),
              _Tile(
                label: 'Unassigned',
                value: '$unassigned',
                note: 'no handler, or no lawyer',
                alert: unassigned > 0,
              ),
              const SizedBox(width: 14),
              _Tile(
                label: 'Claimed, still open',
                value: naira(money.inPipeline),
                note: 'on $openClaims open claims',
              ),
              const SizedBox(width: 14),
              _Tile(
                label: 'Recovered',
                value: naira(money.recovered),
                note: '${naira(money.fees)} in fees at 30%'
                    '${money.wonWithoutAmount > 0 ? ' · ${money.wonWithoutAmount} won with no amount' : ''}',
              ),
              const SizedBox(width: 14),
              _Tile(
                label: 'Outcomes',
                value: '${money.wonCount} won · ${money.lostCount} lost',
                note: money.winRate == null
                    ? 'none decided yet'
                    : '${(money.winRate! * 100).round()}% won'
                        ' · ${money.awaitingPayout} awaiting payout',
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Pipeline and what needs attention
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: _Card(
                  title: 'Pipeline',
                  subtitle: 'Open records in each stage',
                  height: _topRow,
                  child: _Pipeline(
                    leads: pipelineCounts(RecordKind.lead, items, now),
                    claims: pipelineCounts(RecordKind.claim, items, now),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                flex: 6,
                child: _Card(
                  title: 'Needs attention',
                  subtitle: 'Select a row to open the record',
                  height: _topRow,
                  child: _AttentionPanel(
                    attention: attention,
                    selected: _attention,
                    onSelect: (r) => setState(() => _attention = r),
                    onOpen: _open,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // People and events
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: _Card(
                  title: 'Staff',
                  subtitle: 'Open work each person carries, busiest first',
                  height: _bottomRow,
                  child: _StaffTable(loads: loads, now: now),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                flex: 6,
                child: _Card(
                  title: 'Recent activity',
                  subtitle: 'The latest entries in the event log',
                  height: _bottomRow,
                  child: _ActivityFeed(events: events.take(40).toList()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // The AI assistant
          _Card(
            title: 'AI assistant',
            subtitle: 'What staff have asked it in the last 30 days, and '
                'whether they found the answers useful',
            height: _aiRow,
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _ai,
              builder: (context, snapshot) => _AiPanel(
                usage: AiUsage(
                  (snapshot.data?.docs ?? [])
                      .map((d) => _aiRun(d.data()))
                      .whereType<AiRun>()
                      .toList(),
                  now,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A titled panel of fixed [height], so the two panels in a row line up. The
/// body gets whatever is left under the title and scrolls if it needs more.
class _Card extends StatelessWidget {
  const _Card({
    required this.title,
    required this.subtitle,
    required this.height,
    required this.child,
  });

  final String title;
  final String subtitle;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      height: height,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.alternate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: theme.primaryText)),
          const SizedBox(height: 2),
          Text(subtitle,
              style:
                  GoogleFonts.inter(fontSize: 12, color: theme.secondaryText)),
          const SizedBox(height: 16),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// A headline figure. [alert] marks one that wants action: it gains a warning
/// icon as well as the colour, so it does not depend on colour alone.
class _Tile extends StatelessWidget {
  const _Tile({
    required this.label,
    required this.value,
    required this.note,
    this.alert = false,
  });

  final String label;
  final String value;
  final String note;
  final bool alert;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: alert
                  ? overdueRed(context).withValues(alpha: 0.6)
                  : theme.alternate),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (alert) ...[
                  Icon(Icons.warning_amber_rounded,
                      size: 15, color: overdueRed(context)),
                  const SizedBox(width: 5),
                ],
                Expanded(
                  child: Text(label,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: theme.secondaryText)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  style: GoogleFonts.inter(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryText)),
            ),
            const SizedBox(height: 3),
            Text(note,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                    fontSize: 11.5, color: theme.secondaryText)),
          ],
        ),
      ),
    );
  }
}

/// Open records per stage as horizontal bars: one hue for the count, with the
/// overdue part of each bar set apart in the alert colour. The numbers are
/// written beside every bar, so nothing is carried by colour alone.
class _Pipeline extends StatelessWidget {
  const _Pipeline({required this.leads, required this.claims});

  final List<StageCount> leads;
  final List<StageCount> claims;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final all = [...leads, ...claims];
    final largest = all.fold<int>(1, (m, s) => s.count > m ? s.count : m);

    Widget heading(String text) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            text.toUpperCase(),
            style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: theme.secondaryText),
          ),
        );

    Widget key(Color color, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 11.5, color: theme.secondaryText)),
          ],
        );

    return SingleChildScrollView(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            key(brandBlue(context), 'On time'),
            const SizedBox(width: 16),
            key(overdueRed(context), 'Overdue'),
          ],
        ),
        const SizedBox(height: 16),
        heading('Leads'),
        for (final s in leads) _StageBar(stage: s, largest: largest),
        const SizedBox(height: 14),
        heading('Claims'),
        for (final s in claims) _StageBar(stage: s, largest: largest),
      ],
    ));
  }
}

class _StageBar extends StatelessWidget {
  const _StageBar({required this.stage, required this.largest});

  final StageCount stage;
  final int largest;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final onTime = stage.count - stage.overdue;

    return Tooltip(
      message: stage.count == 0
          ? '${stage.stage}: none'
          : '${stage.stage}: ${stage.count} open'
              '${stage.overdue > 0 ? ', ${stage.overdue} overdue' : ''}'
              ' · typically ${stage.medianDays} '
              '${stage.medianDays == 1 ? 'day' : 'days'} in this stage',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 128,
              child: Text(stage.stage,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                      fontSize: 12.5, color: theme.primaryText)),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, box) {
                  // Leave room at the end of the longest bar for its label.
                  final unit =
                      ((box.maxWidth - 110) / largest).clamp(0.0, 400.0);
                  return Row(
                    children: [
                      if (onTime > 0)
                        Container(
                          width: unit * onTime,
                          height: 14,
                          decoration: BoxDecoration(
                            color: brandBlue(context),
                            // Square at the baseline, rounded at the data end.
                            borderRadius: BorderRadius.horizontal(
                              right: Radius.circular(stage.overdue > 0 ? 0 : 4),
                            ),
                          ),
                        ),
                      if (onTime > 0 && stage.overdue > 0)
                        const SizedBox(width: 2),
                      if (stage.overdue > 0)
                        Container(
                          width: unit * stage.overdue,
                          height: 14,
                          decoration: BoxDecoration(
                            color: overdueRed(context),
                            borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(4),
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Text(
                        stage.count == 0
                            ? '0'
                            : '${stage.count}'
                                '${stage.overdue > 0 ? '  ·  ${stage.overdue} overdue' : ''}',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: stage.count == 0
                                ? theme.secondaryText
                                : theme.primaryText),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttentionPanel extends StatelessWidget {
  const _AttentionPanel({
    required this.attention,
    required this.selected,
    required this.onSelect,
    required this.onOpen,
  });

  final List<AttentionItem> attention;
  final Attention selected;
  final void Function(Attention) onSelect;
  final void Function(WorkItem) onOpen;

  static const _labels = {
    Attention.overdue: 'Overdue',
    Attention.unassigned: 'Unassigned',
    Attention.sendFailed: 'Letter failed',
    Attention.noNextAction: 'Nothing scheduled',
  };

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final shown = attention.where((a) => a.reason == selected).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final reason in Attention.values)
              Builder(builder: (context) {
                final n = attention.where((a) => a.reason == reason).length;
                final on = reason == selected;
                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => onSelect(reason),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                    decoration: BoxDecoration(
                      color: on
                          ? brandBlue(context).withValues(alpha: 0.16)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: on ? brandBlue(context) : theme.alternate),
                    ),
                    child: Text(
                      '${_labels[reason]} ($n)',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                        color: on ? brandBlue(context) : theme.primaryText,
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: shown.isEmpty
              ? Center(
                  child: Text('Nothing here. Good.',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: theme.secondaryText)),
                )
              : ListView.separated(
                  itemCount: shown.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: theme.alternate),
                  itemBuilder: (context, i) {
                    final a = shown[i];
                    final owner = a.item.work.hasHandler
                        ? a.item.work.handlerName
                        : 'Unassigned';
                    return InkWell(
                      onTap: () => onOpen(a.item),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 9, horizontal: 4),
                        child: Row(
                          children: [
                            Icon(
                              a.item.kind == RecordKind.lead
                                  ? Icons.person_add_alt_1_outlined
                                  : Icons.description_outlined,
                              size: 16,
                              color: theme.secondaryText,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    a.item.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: theme.primaryText),
                                  ),
                                  Text(
                                    a.detail,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: theme.secondaryText),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              owner,
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: theme.secondaryText),
                            ),
                            Icon(Icons.chevron_right,
                                size: 18, color: theme.secondaryText),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _StaffTable extends StatelessWidget {
  const _StaffTable({required this.loads, required this.now});

  final List<StaffLoad> loads;
  final DateTime now;

  String _ago(DateTime? at) {
    if (at == null) return 'No activity';
    final d = now.difference(at);
    if (d.inMinutes < 60) return '${d.inMinutes < 1 ? 1 : d.inMinutes} min ago';
    if (d.inHours < 24) return '${d.inHours} h ago';
    return '${d.inDays} d ago';
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    TextStyle head() => GoogleFonts.inter(
        fontSize: 11, fontWeight: FontWeight.w700, color: theme.secondaryText);
    TextStyle cell({bool strong = false, Color? color}) => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: strong ? FontWeight.w600 : FontWeight.w400,
        color: color ?? theme.primaryText);

    Widget row(List<Widget> cells) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(flex: 5, child: cells[0]),
              Expanded(flex: 2, child: cells[1]),
              Expanded(flex: 2, child: cells[2]),
              Expanded(flex: 2, child: cells[3]),
              Expanded(flex: 2, child: cells[4]),
              Expanded(flex: 3, child: cells[5]),
            ],
          ),
        );

    if (loads.isEmpty) {
      return Text('No approved staff.',
          style: cell(color: theme.secondaryText));
    }
    return SingleChildScrollView(
        child: Column(
      children: [
        row([
          Text('NAME', style: head()),
          Text('LEADS', style: head()),
          Text('CLAIMS', style: head()),
          Text('OVERDUE', style: head()),
          Text('7 DAYS', style: head()),
          Text('LAST ACTIVE', style: head()),
        ]),
        Divider(height: 1, color: theme.alternate),
        for (final l in loads)
          row([
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.name,
                    overflow: TextOverflow.ellipsis, style: cell(strong: true)),
                Text(l.role.isEmpty ? 'No role' : l.role,
                    style: GoogleFonts.inter(
                        fontSize: 11.5, color: theme.secondaryText)),
              ],
            ),
            Text('${l.openLeads}', style: cell()),
            Text('${l.openClaims}', style: cell()),
            Row(
              children: [
                if (l.overdue > 0) ...[
                  Icon(Icons.warning_amber_rounded,
                      size: 14, color: overdueRed(context)),
                  const SizedBox(width: 4),
                ],
                Text('${l.overdue}', style: cell(strong: l.overdue > 0)),
              ],
            ),
            Tooltip(
              message: 'Entries in the event log in the last 7 days',
              child: Text('${l.actionsThisWeek}', style: cell()),
            ),
            Text(_ago(l.lastActive), style: cell(color: theme.secondaryText)),
          ]),
      ],
    ));
  }
}

class _ActivityFeed extends StatelessWidget {
  const _ActivityFeed({required this.events});

  final List<LogEvent> events;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    if (events.isEmpty) {
      return Text('Nothing recorded yet.',
          style: GoogleFonts.inter(fontSize: 13, color: theme.secondaryText));
    }
    return ListView.separated(
      itemCount: events.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: theme.alternate),
      itemBuilder: (context, i) {
        final e = events[i];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 92,
                child: Text(
                  dateTimeFormat('d MMM HH:mm', e.at),
                  style: GoogleFonts.inter(
                      fontSize: 11.5, color: theme.secondaryText),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${e.action} · ${e.actorName}',
                      style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: theme.primaryText),
                    ),
                    if (e.description.isNotEmpty)
                      Text(
                        e.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: theme.secondaryText),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AiPanel extends StatelessWidget {
  const _AiPanel({required this.usage});

  final AiUsage usage;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    if (usage.count == 0) {
      return Text(
        'Nothing asked in the last ${usage.days} days.',
        style: GoogleFonts.inter(fontSize: 13, color: theme.secondaryText),
      );
    }
    Widget figure(String label, String value, String note) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 11.5, color: theme.secondaryText)),
              Text(value,
                  style: GoogleFonts.inter(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryText)),
              Text(note,
                  style: GoogleFonts.inter(
                      fontSize: 11.5, color: theme.secondaryText)),
            ],
          ),
        );
    String verdict(String review) => switch (review) {
          'useful' => 'Useful',
          'not_useful' => 'Not useful',
          _ => 'Not reviewed',
        };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 250,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                figure(
                  'Answers given',
                  '${usage.count}',
                  usage.byTask.map((e) => '${e.value} ${e.key}').join(' · '),
                ),
                figure(
                  'Found useful',
                  usage.usefulRate == null
                      ? '—'
                      : '${(usage.usefulRate! * 100).round()}%',
                  '${usage.useful} useful · ${usage.notUseful} not · '
                      '${usage.unreviewed} not reviewed',
                ),
                figure(
                  'Estimated cost',
                  '\$${usage.costUsd.toStringAsFixed(2)}',
                  'at list price, in US dollars',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: ListView.separated(
            itemCount: usage.runs.length > 40 ? 40 : usage.runs.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: theme.alternate),
            itemBuilder: (context, i) {
              final r = usage.runs[i];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 92,
                      child: Text(dateTimeFormat('d MMM HH:mm', r.at),
                          style: GoogleFonts.inter(
                              fontSize: 11.5, color: theme.secondaryText)),
                    ),
                    Expanded(
                      child: Text(
                        '${r.taskLabel} · ${r.subject}',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: theme.primaryText),
                      ),
                    ),
                    SizedBox(
                      width: 150,
                      child: Text(r.requestedBy,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              fontSize: 12, color: theme.secondaryText)),
                    ),
                    SizedBox(
                      width: 100,
                      child: Row(
                        children: [
                          if (r.review == 'not_useful') ...[
                            Icon(Icons.thumb_down_alt_outlined,
                                size: 13, color: overdueRed(context)),
                            const SizedBox(width: 4),
                          ],
                          Text(verdict(r.review),
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: theme.secondaryText)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
