import '/backend/backend.dart';
import '/backend/services/casework.dart';
import '/backend/services/pipeline.dart';
import '/components/brand_colors.dart';
import '/components/case_file_widget.dart';
import '/components/lead_file_widget.dart';
import '/components/work_ui.dart';
import '/custom_code/widgets/weekly_leads_chart.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/leads/add_lead/add_lead_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The dashboard: where the leads and the claims stand today, what came in
/// this week, and the newest of each.
class HomePageWidget extends StatefulWidget {
  const HomePageWidget({super.key});

  static String routeName = 'HomePage';
  static String routePath = '/homePage';

  @override
  State<HomePageWidget> createState() => _HomePageWidgetState();
}

/// Claim stages, grouped by who the claim is waiting on.
const _claimGroups = <(String, List<String>)>[
  ('With the client', [ClaimStage.detailsPending, ClaimStage.termsPending]),
  ('In review', [ClaimStage.readyForReview, ClaimStage.underReview]),
  ('With the airline', [ClaimStage.demandPending, ClaimStage.awaitingReply]),
  ('With legal', [ClaimStage.withSolicitor]),
  ('Won', [ClaimStage.won, ClaimStage.paid]),
  ('Lost or withdrawn', [ClaimStage.lost, ClaimStage.withdrawn]),
];

const _leadStages = [
  LeadStage.newLead,
  LeadStage.contacted,
  LeadStage.qualified,
  LeadStage.rejected,
];

class _HomePageWidgetState extends State<HomePageWidget> {
  /// The charts show leads, or claims.
  bool _chartClaims = false;

  late final Stream<List<LeadsRecord>> _leads = queryLeadsRecord(
    queryBuilder: (q) => q.orderBy('created_at', descending: true),
  );
  late final Stream<List<ClaimsRecord>> _claims = queryClaimsRecord(
    queryBuilder: (q) => q.orderBy('createdAt', descending: true),
  );

  static String _leadStage(LeadsRecord l) =>
      canonicalStage(RecordKind.lead, l.status);
  static String _claimStage(ClaimsRecord c) =>
      canonicalStage(RecordKind.claim, c.claimStatus);

  /// How many of [dates] fall on each day of this week, Sunday first.
  static List<int> _thisWeek(Iterable<DateTime?> dates) {
    final now = DateTime.now();
    // DateTime.weekday is Mon=1 … Sun=7; % 7 gives days since Sunday.
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday % 7));
    final weekly = List<int>.filled(7, 0);
    for (final at in dates) {
      if (at == null) continue;
      if (!DateTime(at.year, at.month, at.day).isBefore(weekStart)) {
        weekly[at.weekday % 7]++;
      }
    }
    return weekly;
  }

  static String _clientName(ClaimsRecord claim, Map<String, String> leadNames) {
    if (claim.fullName.isNotEmpty) return claim.fullName;
    final fromLead = leadNames[claim.leadRef?.id] ?? '';
    if (fromLead.isNotEmpty) return fromLead;
    return claim.clientEmail.isNotEmpty ? claim.clientEmail : 'Unnamed client';
  }

  void _addLead() {
    showModalBottomSheet<void>(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) => Padding(
        padding: MediaQuery.viewInsetsOf(context),
        child: const AddLeadWidget(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WorkScaffold(
      page: WorkPage.dashboard,
      title: 'Dashboard',
      subtitle: 'Where the leads and the claims stand today',
      icon: Icons.dashboard_outlined,
      actions: [
        WorkButton(
          icon: Icons.person_add_alt_1_outlined,
          label: 'Add a lead',
          filled: true,
          onTap: _addLead,
        ),
      ],
      child: StreamBuilder<List<LeadsRecord>>(
        stream: _leads,
        builder: (context, leadSnap) => StreamBuilder<List<ClaimsRecord>>(
          stream: _claims,
          builder: (context, claimSnap) {
            if (leadSnap.hasError || claimSnap.hasError) {
              return const WorkEmpty('The dashboard could not be loaded.');
            }
            if (!leadSnap.hasData || !claimSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return _content(context, leadSnap.data!, claimSnap.data!);
          },
        ),
      ),
    );
  }

  Widget _content(BuildContext context, List<LeadsRecord> leads,
      List<ClaimsRecord> claims) {
    final newLeads =
        leads.where((l) => _leadStage(l) == LeadStage.newLead).length;
    final openClaims =
        claims.where((c) => ClaimStage.open.contains(_claimStage(c))).toList();
    final openLeads = leads.where((l) =>
        _leadStage(l) == LeadStage.newLead ||
        _leadStage(l) == LeadStage.contacted);
    final overdue = openLeads
            .where((l) => Casework.of(l.snapshotData).isOverdue)
            .length +
        openClaims.where((c) => Casework.of(c.snapshotData).isOverdue).length;
    final won = claims
        .where((c) =>
            _claimStage(c) == ClaimStage.won ||
            _claimStage(c) == ClaimStage.paid)
        .toList();
    final recovered = won.fold<double>(
        0, (t, c) => t + (Casework.of(c.snapshotData).amountRecovered ?? 0));

    final stageCounts = _chartClaims
        ? [
            for (final (label, stages) in _claimGroups)
              (
                label,
                claims.where((c) => stages.contains(_claimStage(c))).length
              ),
          ]
        : [
            for (final stage in _leadStages)
              (stage, leads.where((l) => _leadStage(l) == stage).length),
          ];
    final weekly = _chartClaims
        ? _thisWeek(claims.map((c) => c.createdAt))
        : _thisWeek(leads.map((l) => l.createdAt));
    final what = _chartClaims ? 'claims' : 'leads';
    // Older claims kept the client's name on the lead only.
    final leadNames = {for (final l in leads) l.reference.id: l.fullName};

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _Tile(
                  label: 'New leads',
                  value: '$newLeads',
                  note: '${leads.length} leads in all',
                  onTap: () => context.goNamed(LeadsWidget.routeName),
                ),
              ),
              const SizedBox(width: 14.0),
              Expanded(
                child: _Tile(
                  label: 'Open claims',
                  value: '${openClaims.length}',
                  note: '${claims.length} claims in all',
                  onTap: () => context.goNamed(ClaimsDashboardWidget.routeName),
                ),
              ),
              const SizedBox(width: 14.0),
              Expanded(
                child: _Tile(
                  label: 'Overdue',
                  value: '$overdue',
                  note: 'next actions past their date',
                  alert: overdue > 0,
                  onTap: () => context.goNamed(ClaimsDashboardWidget.routeName),
                ),
              ),
              const SizedBox(width: 14.0),
              Expanded(
                child: _Tile(
                  label: 'Claims won',
                  value: '${won.length}',
                  note: recovered > 0
                      ? '${naira(recovered)} recovered'
                      : 'nothing recorded as recovered yet',
                  onTap: () => context.goNamed(ClaimsDashboardWidget.routeName),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22.0),
          Row(
            children: [
              WorkChip(
                label: 'Leads',
                selected: !_chartClaims,
                onTap: () => setState(() => _chartClaims = false),
              ),
              const SizedBox(width: 8.0),
              WorkChip(
                label: 'Claims',
                selected: _chartClaims,
                onTap: () => setState(() => _chartClaims = true),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Panel(
                  title: _chartClaims
                      ? 'Claims opened this week'
                      : 'Leads received this week',
                  subtitle: 'Sunday to Saturday',
                  height: 330.0,
                  child: WeeklyLeadsChart(
                    width: double.infinity,
                    height: 250.0,
                    leadCounts: weekly,
                  ),
                ),
              ),
              const SizedBox(width: 14.0),
              Expanded(
                child: _Panel(
                  title: _chartClaims
                      ? 'Claims by who they are waiting on'
                      : 'Leads by stage',
                  subtitle: 'Every one of the $what on file',
                  height: 330.0,
                  child: _StageBars(counts: stageCounts),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14.0),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Panel(
                  title: 'Newest leads',
                  subtitle: 'The last five to come in',
                  height: 356.0,
                  action: TextButton(
                    onPressed: () => context.goNamed(LeadsWidget.routeName),
                    child: const Text('All leads'),
                  ),
                  child: Column(
                    children: [
                      if (leads.isEmpty) const _None('No leads yet.'),
                      for (final lead in leads.take(5))
                        _RecentRow(
                          name: lead.fullName.isNotEmpty
                              ? lead.fullName
                              : 'Unnamed lead',
                          detail: [
                            lead.complaintType.isNotEmpty
                                ? lead.complaintType
                                : lead.claimType,
                            lead.airlineName,
                          ].where((s) => s.isNotEmpty).join('  ·  '),
                          stage: _leadStage(lead),
                          at: lead.createdAt,
                          onTap: () => showLeadFile(context, lead.reference),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14.0),
              Expanded(
                child: _Panel(
                  title: 'Newest claims',
                  subtitle: 'The last five to be opened',
                  height: 356.0,
                  action: TextButton(
                    onPressed: () =>
                        context.goNamed(ClaimsDashboardWidget.routeName),
                    child: const Text('All claims'),
                  ),
                  child: Column(
                    children: [
                      if (claims.isEmpty) const _None('No claims yet.'),
                      for (final claim in claims.take(5))
                        _RecentRow(
                          name: _clientName(claim, leadNames),
                          detail: [claim.airlineName, claim.flightNumber]
                              .where((s) => s.isNotEmpty)
                              .join('  ·  '),
                          stage: _claimStage(claim),
                          at: claim.createdAt,
                          onTap: () => showCaseFile(context, claim.reference),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One headline number. Tapping it opens the list behind it.
class _Tile extends StatelessWidget {
  const _Tile({
    required this.label,
    required this.value,
    required this.note,
    required this.onTap,
    this.alert = false,
  });

  final String label;
  final String value;
  final String note;
  final VoidCallback onTap;

  /// Shows the number in the alert colour: something is late.
  final bool alert;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(14.0),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(color: theme.alternate),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (alert) ...[
                  Icon(Icons.schedule, size: 14.0, color: overdueRed(context)),
                  const SizedBox(width: 5.0),
                ],
                Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: theme.secondaryText)),
              ],
            ),
            const SizedBox(height: 4.0),
            Text(
              value,
              style: GoogleFonts.interTight(
                fontSize: 28.0,
                fontWeight: FontWeight.w700,
                color: alert ? overdueRed(context) : theme.primaryText,
              ),
            ),
            Text(note,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                    fontSize: 12.0, color: theme.secondaryText)),
          ],
        ),
      ),
    );
  }
}

/// A titled card. With [height] it is that tall, so cards in a row line up.
class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.subtitle,
    required this.child,
    this.height,
    this.action,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final double? height;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(18.0, 16.0, 18.0, 16.0),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: theme.alternate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: height == null ? MainAxisSize.min : MainAxisSize.max,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.interTight(
                            fontSize: 15.0,
                            fontWeight: FontWeight.w700,
                            color: theme.primaryText)),
                    Text(subtitle,
                        style: GoogleFonts.inter(
                            fontSize: 12.0, color: theme.secondaryText)),
                  ],
                ),
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 14.0),
          if (height == null) child else Expanded(child: child),
        ],
      ),
    );
  }
}

/// A count per stage as bars on one scale: one colour, the number beside it.
class _StageBars extends StatelessWidget {
  const _StageBars({required this.counts});

  final List<(String, int)> counts;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final most = counts.fold<int>(0, (m, c) => c.$2 > m ? c.$2 : m);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final (label, count) in counts)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7.0),
            child: Row(
              children: [
                SizedBox(
                  width: 128.0,
                  child: Text(label,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          fontSize: 12.5, color: theme.primaryText)),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, box) => Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        height: 14.0,
                        // A stage with something in it always shows a sliver.
                        width: most == 0 || count == 0
                            ? 0.0
                            : (box.maxWidth * count / most)
                                .clamp(3.0, box.maxWidth),
                        decoration: BoxDecoration(
                          color: brandBlue(context),
                          borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(4.0)),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 40.0,
                  child: Text('$count',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: theme.primaryText)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({
    required this.name,
    required this.detail,
    required this.stage,
    required this.at,
    required this.onTap,
  });

  final String name;
  final String detail;
  final String stage;
  final DateTime? at;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(8.0),
      onTap: onTap,
      child: Container(
        height: 50.0,
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(name,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          fontSize: 13.0,
                          fontWeight: FontWeight.w700,
                          color: theme.primaryText)),
                  if (detail.isNotEmpty)
                    Text(detail,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                            fontSize: 12.0, color: theme.secondaryText)),
                ],
              ),
            ),
            const SizedBox(width: 10.0),
            StagePill(stage),
            SizedBox(
              width: 86.0,
              child: Text(
                at == null ? '' : dateTimeFormat('d MMM y', at),
                textAlign: TextAlign.right,
                style: GoogleFonts.inter(
                    fontSize: 12.0, color: theme.secondaryText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _None extends StatelessWidget {
  const _None(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Text(text,
          style: GoogleFonts.inter(
              fontSize: 13.0,
              color: FlutterFlowTheme.of(context).secondaryText)),
    );
  }
}
