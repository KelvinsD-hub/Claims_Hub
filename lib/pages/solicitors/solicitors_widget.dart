import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/services/casework.dart';
import '/backend/services/compensation_calculator.dart';
import '/backend/services/pipeline.dart';
import '/components/case_file_widget.dart';
import '/components/casework_panel_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/components/work_ui.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'solicitors_model.dart';
export 'solicitors_model.dart';

/// The legal team's workspace: the claims escalated to them, whose they are,
/// what is due, and how the team is doing.
///
/// Each card opens the case file (CaseFileWidget), where the work is done.
class SolicitorsWidget extends StatefulWidget {
  const SolicitorsWidget({super.key});

  static String routeName = 'Solicitors';
  static String routePath = '/solicitors';

  @override
  State<SolicitorsWidget> createState() => _SolicitorsWidgetState();
}

enum _View { mine, queue, open, closed }

class _SolicitorsWidgetState extends State<SolicitorsWidget> {
  late SolicitorsModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  _View _view = _View.mine;

  /// A legal stage to narrow the open lists to, or null for all of them.
  String? _legalStage;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SolicitorsModel());
    _model.searchController ??= TextEditingController();
    _model.searchFocusNode ??= FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  /// "₦21,250" → 21250. Amounts are stored as the text staff typed.
  static double _amountClaimed(ClaimsRecord claim) =>
      double.tryParse(claim.claimsAmount.replaceAll(RegExp(r'[^0-9.]'), '')) ??
      0.0;

  static String _legalStageOf(ClaimsRecord claim) {
    final stage = Casework.of(claim.snapshotData).legalStage;
    return stage.isEmpty ? LegalStage.review : stage;
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    final theme = FlutterFlowTheme.of(context);

    return Title(
      title: 'Legal Workspace',
      color: theme.primary.withAlpha(0XFF),
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Scaffold(
          key: scaffoldKey,
          backgroundColor: theme.primaryBackground,
          body: SafeArea(
            top: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const WorkSidebar(selected: WorkPage.legal),
                Expanded(
                  child: StreamBuilder<List<ClaimsRecord>>(
                    // Everything with the legal team now, and everything
                    // closed, from which the ones they handled are picked out.
                    stream: queryClaimsRecord(
                      queryBuilder: (q) => q.where('claim_status', whereIn: [
                        ClaimStage.withSolicitor,
                        ClaimStage.won,
                        ClaimStage.lost,
                        ClaimStage.paid,
                        ClaimStage.withdrawn,
                      ]),
                    ),
                    builder: (context, snapshot) {
                      final all = snapshot.data ?? [];
                      final open = all
                          .where(
                              (c) => c.claimStatus == ClaimStage.withSolicitor)
                          .toList();
                      // A closed claim counts as the legal team's if it ever
                      // reached them.
                      final closed = all
                          .where((c) =>
                              c.claimStatus != ClaimStage.withSolicitor &&
                              Casework.of(c.snapshotData).legalStage.isNotEmpty)
                          .toList();
                      final mine = open
                          .where((c) =>
                              Casework.of(c.snapshotData).lawyerUid ==
                              currentUserUid)
                          .toList();
                      final queue = open
                          .where((c) => !Casework.of(c.snapshotData).hasLawyer)
                          .toList();
                      final overdue = open
                          .where((c) => Casework.of(c.snapshotData).isOverdue)
                          .length;
                      final atStake = open.fold<double>(
                          0, (total, c) => total + _amountClaimed(c));
                      final won = closed
                          .where((c) =>
                              c.claimStatus == ClaimStage.won ||
                              c.claimStatus == ClaimStage.paid)
                          .toList();
                      final lost = closed
                          .where((c) => c.claimStatus == ClaimStage.lost)
                          .length;
                      final recovered = won.fold<double>(
                          0,
                          (total, c) =>
                              total +
                              (Casework.of(c.snapshotData).amountRecovered ??
                                  0));

                      final search =
                          _model.searchController?.text.toLowerCase() ?? '';
                      var shown = switch (_view) {
                        _View.mine => mine,
                        _View.queue => queue,
                        _View.open => open,
                        _View.closed => closed,
                      };
                      if (_legalStage != null && _view != _View.closed) {
                        shown = shown
                            .where((c) => _legalStageOf(c) == _legalStage)
                            .toList();
                      }
                      if (search.isNotEmpty) {
                        shown = shown
                            .where((c) =>
                                c.fullName.toLowerCase().contains(search) ||
                                c.airlineName.toLowerCase().contains(search) ||
                                c.pnrNumber.toLowerCase().contains(search) ||
                                c.flightNumber.toLowerCase().contains(search))
                            .toList();
                      }
                      // Most urgent first; anything with no date last.
                      shown.sort((a, b) =>
                          (Casework.of(a.snapshotData).nextActionDue ??
                                  DateTime(2100))
                              .compareTo(
                                  Casework.of(b.snapshotData).nextActionDue ??
                                      DateTime(2100)));

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          WorkHeader(
                            title: 'Legal Workspace',
                            subtitle:
                                'Claims with the legal team: whose they are, and what is due',
                            icon: Icons.gavel_outlined,
                            actions: [
                              WorkSearchBox(
                                controller: _model.searchController!,
                                hint: 'Search client, airline, PNR…',
                                onChanged: (_) => safeSetState(() {}),
                              ),
                            ],
                          ),

                          // Dashboard
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                            child: Row(
                              children: [
                                _StatCard(
                                  label: 'Open cases',
                                  value: '${open.length}',
                                  note: '${mine.length} yours',
                                  color: brandBlue(context),
                                  icon: Icons.folder_open_outlined,
                                ),
                                const SizedBox(width: 16),
                                _StatCard(
                                  label: 'Waiting for a lawyer',
                                  value: '${queue.length}',
                                  note: 'in the legal queue',
                                  color: queue.isEmpty
                                      ? theme.secondaryText
                                      : const Color(0xFFF08156),
                                  icon: Icons.inbox_outlined,
                                ),
                                const SizedBox(width: 16),
                                _StatCard(
                                  label: 'Overdue',
                                  value: '$overdue',
                                  note: 'past their due date',
                                  color: overdue == 0
                                      ? theme.secondaryText
                                      : overdueRed(context),
                                  icon: Icons.schedule_outlined,
                                ),
                                const SizedBox(width: 16),
                                _StatCard(
                                  label: 'Value at stake',
                                  value: naira(atStake),
                                  note: 'claimed on open cases',
                                  color: const Color(0xFFE6B011),
                                  icon: Icons.account_balance_wallet_outlined,
                                ),
                                const SizedBox(width: 16),
                                _StatCard(
                                  label: 'Outcomes',
                                  value: '${won.length} won · $lost lost',
                                  note: '${naira(recovered)} recovered',
                                  color: const Color(0xFF3BA55D),
                                  icon: Icons.emoji_events_outlined,
                                ),
                              ],
                            ),
                          ),

                          // Views and the legal stage filter
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 18, 24, 12),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                _Chip(
                                  label: 'My cases (${mine.length})',
                                  selected: _view == _View.mine,
                                  onTap: () =>
                                      setState(() => _view = _View.mine),
                                ),
                                _Chip(
                                  label: 'Legal queue (${queue.length})',
                                  selected: _view == _View.queue,
                                  onTap: () =>
                                      setState(() => _view = _View.queue),
                                ),
                                _Chip(
                                  label: 'All open (${open.length})',
                                  selected: _view == _View.open,
                                  onTap: () =>
                                      setState(() => _view = _View.open),
                                ),
                                _Chip(
                                  label: 'Closed (${closed.length})',
                                  selected: _view == _View.closed,
                                  onTap: () =>
                                      setState(() => _view = _View.closed),
                                ),
                                if (_view != _View.closed) ...[
                                  Container(
                                    width: 1,
                                    height: 22,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 6),
                                    color: theme.alternate,
                                  ),
                                  for (final stage in LegalStage.all)
                                    _Chip(
                                      label:
                                          '$stage (${open.where((c) => _legalStageOf(c) == stage).length})',
                                      selected: _legalStage == stage,
                                      quiet: true,
                                      onTap: () => setState(() => _legalStage =
                                          _legalStage == stage ? null : stage),
                                    ),
                                ],
                              ],
                            ),
                          ),

                          // Cases
                          Expanded(
                            child: snapshot.connectionState ==
                                    ConnectionState.waiting
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : shown.isEmpty
                                    ? _EmptyState(
                                        message: search.isNotEmpty ||
                                                _legalStage != null
                                            ? 'No cases match.'
                                            : switch (_view) {
                                                _View.mine =>
                                                  'You have no cases. Take one from the legal queue.',
                                                _View.queue =>
                                                  'The legal queue is empty.',
                                                _View.open =>
                                                  'No claims are with the legal team.',
                                                _View.closed =>
                                                  'No closed cases yet.',
                                              },
                                      )
                                    : ListView.separated(
                                        padding: const EdgeInsets.fromLTRB(
                                            24, 0, 24, 24),
                                        itemCount: shown.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(height: 10),
                                        itemBuilder: (context, i) => _CaseCard(
                                          claim: shown[i],
                                          legalStage: _legalStageOf(shown[i]),
                                          amountClaimed: displayClaimAmount(
                                              shown[i].claimsAmount,
                                              empty: ''),
                                        ),
                                      ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.note,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final String note;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.alternate),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: theme.secondaryText),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: GoogleFonts.inter(
                    fontSize: 20, fontWeight: FontWeight.bold, color: color),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              note,
              overflow: TextOverflow.ellipsis,
              style:
                  GoogleFonts.inter(fontSize: 11.5, color: theme.secondaryText),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.quiet = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// A filter, not a view: drawn lighter.
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final accent = quiet ? const Color(0xFF9B6BF2) : brandBlue(context);
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.16) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? accent : theme.alternate),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: quiet ? 12 : 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? accent : theme.primaryText,
          ),
        ),
      ),
    );
  }
}

class _CaseCard extends StatefulWidget {
  const _CaseCard({
    required this.claim,
    required this.legalStage,
    required this.amountClaimed,
  });

  final ClaimsRecord claim;
  final String legalStage;
  final String amountClaimed;

  @override
  State<_CaseCard> createState() => _CaseCardState();
}

class _CaseCardState extends State<_CaseCard> {
  bool _taking = false;

  Future<void> _take() async {
    setState(() => _taking = true);
    final result = await assignRecord(
      kind: RecordKind.claim,
      id: widget.claim.reference.id,
      toUid: currentUserUid,
      lawyer: true,
    );
    if (!mounted) return;
    setState(() => _taking = false);
    showCaseActionResult(context, result, 'The case is yours.');
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final claim = widget.claim;
    final work = Casework.of(claim.snapshotData);
    final open = claim.claimStatus == ClaimStage.withSolicitor;
    final role = valueOrDefault(currentUserDocument?.role, '');
    final days = work.escalatedAt == null
        ? null
        : DateTime.now().difference(work.escalatedAt!).inDays;
    const purple = Color(0xFF9B6BF2);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => showCaseFile(context, claim.reference),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: work.isOverdue && open
                  ? overdueRed(context).withValues(alpha: 0.6)
                  : theme.alternate),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    claim.fullName.isNotEmpty
                        ? claim.fullName
                        : 'Unnamed client',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: theme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    [
                      if (claim.airlineName.isNotEmpty) claim.airlineName,
                      if (claim.flightNumber.isNotEmpty) claim.flightNumber,
                      if (widget.amountClaimed.isNotEmpty) widget.amountClaimed,
                    ].join('  ·  '),
                    style: GoogleFonts.inter(
                        fontSize: 12.5, color: theme.secondaryText),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: purple.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      open ? widget.legalStage : claim.claimStatus,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: open
                            ? purple
                            : (claim.claimStatus == ClaimStage.lost
                                ? overdueRed(context)
                                : const Color(0xFF3BA55D)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    open
                        ? (days == null
                            ? 'Escalated before dates were kept'
                            : 'Escalated ${days == 0 ? 'today' : '$days days ago'}')
                        : (work.amountRecovered == null
                            ? 'Reached: ${widget.legalStage}'
                            : '${naira(work.amountRecovered!)} recovered'),
                    style: GoogleFonts.inter(
                        fontSize: 12, color: theme.secondaryText),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: open
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          work.hasNextAction
                              ? work.nextAction
                              : 'No next action',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              fontSize: 12.5, color: theme.primaryText),
                        ),
                        if (work.dueLabel.isNotEmpty)
                          Text(
                            work.dueLabel,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: work.isOverdue
                                  ? overdueRed(context)
                                  : theme.secondaryText,
                            ),
                          ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
            SizedBox(
              width: 170,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    work.hasLawyer
                        ? (work.lawyerUid == currentUserUid
                            ? 'Yours'
                            : work.lawyerName)
                        : (open ? 'No lawyer yet' : ''),
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: work.hasLawyer || !open
                          ? theme.primaryText
                          : const Color(0xFFF08156),
                    ),
                  ),
                  if (open && !work.hasLawyer && isLegalRole(role))
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: OutlinedButton(
                        onPressed: _taking ? null : _take,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: brandBlue(context)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          _taking ? 'Taking…' : 'Take this case',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: brandBlue(context),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, color: theme.secondaryText),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.gavel_rounded, size: 44, color: theme.alternate),
          const SizedBox(height: 14),
          Text(
            message,
            style: GoogleFonts.inter(fontSize: 15, color: theme.secondaryText),
          ),
        ],
      ),
    );
  }
}
