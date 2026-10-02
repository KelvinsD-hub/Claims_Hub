import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/services/casework.dart';
import '/backend/services/compensation_calculator.dart';
import '/backend/services/pipeline.dart';
import '/components/case_file_widget.dart';
import '/components/work_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Every claim, in one list. The chips along the top group the stages by who
/// the claim is waiting on; "Mine" and "Overdue" narrow any of them. A row
/// opens the claim's file.
class ClaimsDashboardWidget extends StatefulWidget {
  const ClaimsDashboardWidget({super.key});

  static String routeName = 'ClaimsDashboard';
  static String routePath = '/claimsDashboard';

  @override
  State<ClaimsDashboardWidget> createState() => _ClaimsDashboardWidgetState();
}

/// The stages, grouped by who a claim is waiting on.
const _groups = <(String, List<String>)>[
  ('With the client', [ClaimStage.detailsPending, ClaimStage.termsPending]),
  ('In review', [ClaimStage.readyForReview, ClaimStage.underReview]),
  ('With the airline', [ClaimStage.demandPending, ClaimStage.awaitingReply]),
  ('With legal', [ClaimStage.withSolicitor]),
  ('Won', [ClaimStage.won, ClaimStage.paid]),
  ('Lost or withdrawn', [ClaimStage.lost, ClaimStage.withdrawn]),
];

class _ClaimsDashboardWidgetState extends State<ClaimsDashboardWidget> {
  /// The group shown; null for every claim.
  String? _group;
  bool _mineOnly = false;
  bool _overdueOnly = false;
  String _search = '';
  final _searchController = TextEditingController();

  late final Stream<List<ClaimsRecord>> _claims = queryClaimsRecord(
    queryBuilder: (q) => q.orderBy('createdAt', descending: true),
  );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static String _stageOf(ClaimsRecord claim) =>
      canonicalStage(RecordKind.claim, claim.claimStatus);

  bool _matches(ClaimsRecord claim) {
    final work = Casework.of(claim.snapshotData);
    if (_mineOnly &&
        work.handlerUid != currentUserUid &&
        work.lawyerUid != currentUserUid) {
      return false;
    }
    if (_overdueOnly &&
        !(work.isOverdue && ClaimStage.open.contains(_stageOf(claim)))) {
      return false;
    }
    if (_search.isEmpty) return true;
    return '${claim.fullName} ${claim.clientEmail} ${claim.airlineName} '
            '${claim.pnrNumber} ${claim.flightNumber}'
        .toLowerCase()
        .contains(_search);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return WorkScaffold(
      page: WorkPage.claims,
      title: 'Claims',
      subtitle: 'Every claim, from the client\'s details to the money paid out',
      icon: Icons.folder_copy_outlined,
      actions: [
        WorkSearchBox(
          controller: _searchController,
          hint: 'Search name, airline, flight, booking ref…',
          onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
        ),
      ],
      child: StreamBuilder<List<ClaimsRecord>>(
        stream: _claims,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const WorkEmpty('The claims could not be loaded.');
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final matching = snapshot.data!.where(_matches).toList();
          final stages = _group == null
              ? null
              : _groups.firstWhere((g) => g.$1 == _group).$2;
          final shown = stages == null
              ? matching
              : matching.where((c) => stages.contains(_stageOf(c))).toList();
          if (_mineOnly || _overdueOnly) {
            // Most urgent first; anything with no date last.
            shown.sort((a, b) =>
                (Casework.of(a.snapshotData).nextActionDue ?? DateTime(2100))
                    .compareTo(Casework.of(b.snapshotData).nextActionDue ??
                        DateTime(2100)));
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 12.0),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    WorkChip(
                      label: 'All',
                      count: matching.length,
                      selected: _group == null,
                      onTap: () => setState(() => _group = null),
                    ),
                    for (final (label, groupStages) in _groups)
                      WorkChip(
                        label: label,
                        count: matching
                            .where((c) => groupStages.contains(_stageOf(c)))
                            .length,
                        selected: _group == label,
                        onTap: () => setState(() => _group = label),
                      ),
                    Container(width: 1.0, height: 22.0, color: theme.alternate),
                    WorkChip(
                      label: 'Mine',
                      selected: _mineOnly,
                      onTap: () => setState(() => _mineOnly = !_mineOnly),
                    ),
                    WorkChip(
                      label: 'Overdue',
                      selected: _overdueOnly,
                      onTap: () => setState(() => _overdueOnly = !_overdueOnly),
                    ),
                  ],
                ),
              ),
              Container(
                color: theme.secondaryBackground,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 11.0),
                child: const Row(
                  children: [
                    Expanded(flex: 4, child: WorkColumnHead('Client')),
                    Expanded(flex: 4, child: WorkColumnHead('Flight')),
                    Expanded(flex: 3, child: WorkColumnHead('Stage')),
                    Expanded(flex: 3, child: WorkColumnHead('Owner and due')),
                    Expanded(flex: 2, child: WorkColumnHead('Amount')),
                    Expanded(flex: 2, child: WorkColumnHead('Opened')),
                    SizedBox(width: 28.0),
                  ],
                ),
              ),
              Expanded(
                child: shown.isEmpty
                    ? WorkEmpty(_search.isNotEmpty || _mineOnly || _overdueOnly
                        ? 'No claims match.'
                        : 'No claims here.')
                    : ListView.separated(
                        itemCount: shown.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1.0, color: theme.alternate),
                        itemBuilder: (context, i) => _ClaimRow(claim: shown[i]),
                      ),
              ),
              Container(
                color: theme.secondaryBackground,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 10.0),
                child: Text(
                  '${shown.length} claim${shown.length == 1 ? '' : 's'}',
                  style: GoogleFonts.inter(
                      fontSize: 12.0, color: theme.secondaryText),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ClaimRow extends StatelessWidget {
  const _ClaimRow({required this.claim});

  final ClaimsRecord claim;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final work = Casework.of(claim.snapshotData);
    final stage = canonicalStage(RecordKind.claim, claim.claimStatus);
    final small = GoogleFonts.inter(fontSize: 12.0, color: theme.secondaryText);
    final main = GoogleFonts.inter(fontSize: 13.0, color: theme.primaryText);
    final flight = [claim.flightNumber, claim.flightDate]
        .where((s) => s.isNotEmpty)
        .join('  ·  ');

    Widget name(String value) => Text(
          value.isNotEmpty ? value : 'Unnamed client',
          overflow: TextOverflow.ellipsis,
          style: main.copyWith(fontWeight: FontWeight.w700),
        );

    return InkWell(
      onTap: () => showCaseFile(context, claim.reference),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Older claims kept the client's name on the lead only.
                  if (claim.fullName.isEmpty && claim.leadRef != null)
                    StreamBuilder<LeadsRecord>(
                      stream: LeadsRecord.getDocument(claim.leadRef!),
                      builder: (context, snapshot) =>
                          name(snapshot.data?.fullName ?? ''),
                    )
                  else
                    name(claim.fullName),
                  if (claim.clientEmail.isNotEmpty)
                    Text(claim.clientEmail,
                        overflow: TextOverflow.ellipsis, style: small),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(claim.airlineName.isEmpty ? '—' : claim.airlineName,
                      overflow: TextOverflow.ellipsis, style: main),
                  if (flight.isNotEmpty)
                    Text(flight, overflow: TextOverflow.ellipsis, style: small),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Align(
                alignment: Alignment.centerLeft,
                child: StagePill(stage),
              ),
            ),
            Expanded(
              flex: 3,
              child: ClaimStage.open.contains(stage)
                  ? OwnerAndDue(work)
                  : Text(work.handlerName.isEmpty ? '—' : work.handlerName,
                      overflow: TextOverflow.ellipsis,
                      style: main.copyWith(fontSize: 12.5)),
            ),
            Expanded(
              flex: 2,
              child: Text(
                work.amountRecovered != null
                    ? '${naira(work.amountRecovered!)} in'
                    : displayClaimAmount(claim.claimsAmount),
                overflow: TextOverflow.ellipsis,
                style: main.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                claim.createdAt == null
                    ? '—'
                    : dateTimeFormat('d MMM y', claim.createdAt),
                style: small,
              ),
            ),
            SizedBox(
              width: 28.0,
              child: Icon(Icons.chevron_right,
                  size: 18.0, color: theme.secondaryText),
            ),
          ],
        ),
      ),
    );
  }
}
