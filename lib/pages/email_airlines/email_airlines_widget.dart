import '/backend/backend.dart';
import '/backend/services/casework.dart';
import '/backend/services/compensation_calculator.dart';
import '/backend/services/demand.dart';
import '/backend/services/pipeline.dart';
import '/components/brand_colors.dart';
import '/components/case_file_widget.dart';
import '/components/create_airline_widget.dart';
import '/components/demand_send.dart';
import '/components/work_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The demand letters: the claims ready for theirs, and the ones waiting for
/// the airline to answer.
///
/// "To send" is the work queue. Each claim says whether its letter can go and,
/// if not, what is missing. Send opens the letter's details and the airline's
/// address before anything leaves.
class EmailAirlinesWidget extends StatefulWidget {
  const EmailAirlinesWidget({super.key});

  static String routeName = 'Email_Airlines';
  static String routePath = '/emailAirlines';

  @override
  State<EmailAirlinesWidget> createState() => _EmailAirlinesWidgetState();
}

class _EmailAirlinesWidgetState extends State<EmailAirlinesWidget> {
  bool _showWaiting = false;
  String _search = '';
  final _searchController = TextEditingController();

  late final Stream<List<ClaimsRecord>> _claims = queryClaimsRecord(
    queryBuilder: (q) => q.where('claim_status',
        whereIn: [ClaimStage.demandPending, ClaimStage.awaitingReply]),
  );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static DateTime? _sentAt(ClaimsRecord claim) {
    final at = claim.snapshotData['demand_sent_at'];
    return at is Timestamp ? at.toDate() : null;
  }

  bool _matches(ClaimsRecord claim) =>
      _search.isEmpty ||
      '${claim.fullName} ${claim.airlineName} ${claim.flightNumber} ${claim.pnrNumber}'
          .toLowerCase()
          .contains(_search);

  void _addAirline() {
    showModalBottomSheet<void>(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      context: context,
      builder: (context) => Padding(
        padding: MediaQuery.viewInsetsOf(context),
        child: const CreateAirlineWidget(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return WorkScaffold(
      page: WorkPage.demands,
      title: 'Demand letters',
      subtitle: 'Claims ready for their letter to the airline, and the ones '
          'waiting for an answer',
      icon: Icons.outgoing_mail,
      actions: [
        WorkSearchBox(
          controller: _searchController,
          hint: 'Search name, airline, flight…',
          onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
        ),
        WorkButton(
          icon: Icons.add,
          label: 'Add an airline address',
          onTap: _addAirline,
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
          final all = snapshot.data!.where(_matches).toList();
          final toSend = all
              .where((c) => c.claimStatus == ClaimStage.demandPending)
              .toList()
            ..sort((a, b) => (a.createdAt ?? DateTime(2000))
                .compareTo(b.createdAt ?? DateTime(2000)));
          // Longest wait first.
          final waiting = all
              .where((c) => c.claimStatus == ClaimStage.awaitingReply)
              .toList()
            ..sort((a, b) => (_sentAt(a) ?? DateTime(2000))
                .compareTo(_sentAt(b) ?? DateTime(2000)));
          final ready = toSend
              .where((c) =>
                  demandReadiness(c.snapshotData).ready &&
                  !c.inCancellationPeriod)
              .length;
          final late = waiting
              .where((c) => Casework.of(c.snapshotData).isOverdue)
              .length;
          final shown = _showWaiting ? waiting : toSend;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 4.0),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    WorkChip(
                      label: 'To send',
                      count: toSend.length,
                      selected: !_showWaiting,
                      onTap: () => setState(() => _showWaiting = false),
                    ),
                    WorkChip(
                      label: 'Waiting for a reply',
                      count: waiting.length,
                      selected: _showWaiting,
                      onTap: () => setState(() => _showWaiting = true),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 10.0),
                child: Text(
                  _showWaiting
                      ? (late == 0
                          ? 'The airline has 14 days from the letter. None of these is past that.'
                          : '$late of these ${late == 1 ? 'is' : 'are'} past the 14 days the letter gave the airline.')
                      : (toSend.isEmpty
                          ? 'A claim appears here when it is moved to "Demand Pending".'
                          : '$ready of ${toSend.length} can go now. The others say what is missing.'),
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: _showWaiting && late > 0
                        ? overdueRed(context)
                        : theme.secondaryText,
                  ),
                ),
              ),
              Expanded(
                child: shown.isEmpty
                    ? WorkEmpty(_showWaiting
                        ? 'No letters are waiting for a reply.'
                        : 'No letters to send.')
                    : ListView.separated(
                        padding:
                            const EdgeInsets.fromLTRB(24.0, 4.0, 24.0, 28.0),
                        itemCount: shown.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10.0),
                        itemBuilder: (context, i) => _DemandCard(
                          claim: shown[i],
                          sentAt: _sentAt(shown[i]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DemandCard extends StatelessWidget {
  const _DemandCard({required this.claim, required this.sentAt});

  final ClaimsRecord claim;
  final DateTime? sentAt;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final waiting = claim.claimStatus == ClaimStage.awaitingReply;
    final work = Casework.of(claim.snapshotData);
    final readiness = demandReadiness(claim.snapshotData);
    final held = claim.inCancellationPeriod;
    final failed = claim.airlineEmailStatus == 'Send failed';
    final flight = [
      claim.airlineName,
      claim.flightNumber,
      claim.flightDate,
      if (claim.departure.isNotEmpty && claim.destination.isNotEmpty)
        '${claim.departure} → ${claim.destination}',
    ].where((s) => s.isNotEmpty).join('  ·  ');
    final small = GoogleFonts.inter(fontSize: 12.5, color: theme.secondaryText);

    // One line saying where this letter stands.
    final (IconData icon, Color color, String status) = waiting
        ? (
            work.isOverdue ? Icons.schedule : Icons.mark_email_read_outlined,
            work.isOverdue ? overdueRed(context) : theme.secondaryText,
            [
              if (sentAt != null)
                'Sent ${dateTimeFormat('d MMM y', sentAt)}'
              else
                'Sent',
              if (claim.airlineEmailSelection.isNotEmpty)
                'to ${claim.airlineEmailSelection}',
              if (work.dueLabel.isNotEmpty)
                '· reply ${work.dueLabel.toLowerCase()}',
            ].join(' ')
          )
        : held
            ? (
                Icons.schedule,
                overdueRed(context),
                'Held: the client can still cancel until '
                    '${dateTimeFormat('d MMM y', claim.workMayStartAt)}.'
              )
            : !readiness.ready
                ? (
                    Icons.error_outline,
                    overdueRed(context),
                    readiness.blockers.join(' ')
                  )
                : failed
                    ? (
                        Icons.error_outline,
                        overdueRed(context),
                        'The last attempt to send this failed. It can be sent again.'
                      )
                    : (
                        Icons.check_circle_outline,
                        stageColor(context, ClaimStage.won),
                        'Ready to send'
                      );

    return Container(
      padding: const EdgeInsets.fromLTRB(18.0, 14.0, 14.0, 14.0),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: theme.alternate),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        claim.fullName.isNotEmpty
                            ? claim.fullName
                            : 'Unnamed client',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 15.0,
                          fontWeight: FontWeight.w700,
                          color: theme.primaryText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Text(
                      displayClaimAmount(claim.claimsAmount,
                          empty: 'No amount set'),
                      style: GoogleFonts.inter(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w600,
                        color: theme.primaryText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3.0),
                Text(flight.isEmpty ? 'No flight details yet' : flight,
                    overflow: TextOverflow.ellipsis, style: small),
                const SizedBox(height: 8.0),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 15.0, color: color),
                    const SizedBox(width: 6.0),
                    Expanded(
                      child: Text(
                        status,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                if (!waiting &&
                    readiness.ready &&
                    readiness.warnings.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0, left: 21.0),
                    child: Text(readiness.warnings.join(' '), style: small),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16.0),
          WorkButton(
            icon: Icons.folder_open_outlined,
            label: 'Open file',
            onTap: () => showCaseFile(context, claim.reference),
          ),
          const SizedBox(width: 8.0),
          if (!waiting && !readiness.ready)
            WorkButton(
              icon: Icons.edit_outlined,
              label: 'Fix details',
              filled: true,
              onTap: () => editClaimWith(GoRouter.of(context), claim.reference),
            )
          else
            WorkButton(
              icon: Icons.send_rounded,
              label: waiting ? 'Resend' : 'Send',
              filled: !waiting,
              onTap: held ? null : () => showSendDemand(context, claim),
            ),
        ],
      ),
    );
  }
}
