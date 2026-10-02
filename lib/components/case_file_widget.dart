import '/backend/services/documents.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/services/casework.dart';
import '/backend/services/compensation_calculator.dart';
import '/backend/services/pipeline.dart';
import '/backend/services/demand.dart';
import '/claims/component/download_p_d_f/download_p_d_f_widget.dart';
import '/claims/component/part19_calculator/part19_calculator_widget.dart';
import '/components/ai_assist_panel.dart';
import '/components/casework_panel_widget.dart';
import '/components/demand_send.dart';
import '/components/record_timeline.dart';
import '/components/stage_menu_widget.dart';
import '/components/work_ui.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A naira amount for display: "₦170,000".
String naira(num amount) =>
    '₦${NumberFormat.decimalPattern().format(amount.round())}';

/// Opens the case file for [claimRef] over the current page.
Future<void> showCaseFile(BuildContext context, DocumentReference claimRef) {
  return showDialog<void>(
    context: context,
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.all(20.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1240.0, maxHeight: 920.0),
        child: CaseFileWidget(claimRef: claimRef),
      ),
    ),
  );
}

/// Everything about one claim on one screen: the client, the flight, who owns
/// it and what is due, how far the legal team has taken it, the documents, and
/// the full history from the event log — with the actions staff take on it.
class CaseFileWidget extends StatefulWidget {
  const CaseFileWidget({super.key, required this.claimRef, this.onClose});

  final DocumentReference claimRef;

  /// What the close button does. Left out, it closes the dialog the file is
  /// shown in.
  final VoidCallback? onClose;

  @override
  State<CaseFileWidget> createState() => _CaseFileWidgetState();
}

class _CaseFileWidgetState extends State<CaseFileWidget> {
  bool _busy = false;

  /// The right-hand column shows the history, or the AI assistant.
  bool _showAssistant = false;

  Future<void> _run(
      Future<CaseActionResult> Function() action, String done) async {
    if (_busy) return;
    setState(() => _busy = true);
    final result = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    showCaseActionResult(context, result, done);
  }

  /// Asks for some text and, when [askAmount], a naira amount.
  Future<({String text, double? amount})?> _ask({
    required String title,
    required String label,
    String hint = '',
    bool textRequired = true,
    bool askAmount = false,
  }) {
    final text = TextEditingController();
    final amount = TextEditingController();
    return showDialog<({String text, double? amount})>(
      context: context,
      builder: (dialogContext) {
        String? error;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            title: Text(title),
            content: SizedBox(
              width: 420.0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (askAmount) ...[
                    TextField(
                      controller: amount,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Amount offered (naira)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12.0),
                  ],
                  TextField(
                    controller: text,
                    autofocus: !askAmount,
                    minLines: 3,
                    maxLines: 6,
                    maxLength: 2000,
                    decoration: InputDecoration(
                      labelText: label,
                      hintText: hint,
                      errorText: error,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final value = text.text.trim();
                  if (textRequired && value.isEmpty) {
                    setDialogState(() => error = 'This cannot be empty.');
                    return;
                  }
                  double? parsed;
                  if (askAmount) {
                    parsed = double.tryParse(
                        amount.text.replaceAll(RegExp(r'[^0-9.]'), ''));
                    if (parsed == null || parsed <= 0) {
                      setDialogState(() => error = 'Give the amount offered.');
                      return;
                    }
                  }
                  Navigator.pop(dialogContext, (text: value, amount: parsed));
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addNote(ClaimsRecord claim, CaseNoteType type) async {
    final answer = await _ask(
      title: switch (type) {
        CaseNoteType.note => 'Add a note',
        CaseNoteType.airlineReply => 'Record the airline\'s reply',
        CaseNoteType.offer => 'Record a settlement offer',
      },
      label: switch (type) {
        CaseNoteType.note => 'Note',
        CaseNoteType.airlineReply => 'What the airline said',
        CaseNoteType.offer => 'Terms of the offer',
      },
      hint: type == CaseNoteType.airlineReply
          ? 'Who replied, when, and their position'
          : '',
      askAmount: type == CaseNoteType.offer,
    );
    if (answer == null || !mounted) return;
    await _run(
      () => addCaseNote(
          kind: RecordKind.claim,
          id: claim.reference.id,
          text: answer.text,
          type: type,
          amount: answer.amount),
      'Added to the case file.',
    );
  }

  Future<void> _moveLegalStage(ClaimsRecord claim, String to) async {
    final court = to == LegalStage.court;
    final answer = await _ask(
      title: 'Move to "$to"',
      label: court
          ? 'Why this claim is going to court (required)'
          : 'Note (optional)',
      textRequired: court,
    );
    if (answer == null || !mounted) return;
    await _run(
      () =>
          setLegalStage(claimId: claim.reference.id, to: to, note: answer.text),
      'Legal stage: $to.',
    );
  }

  void _downloadPdf(ClaimsRecord claim) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        elevation: 0.0,
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        child: DownloadPDFWidget(claimRef: claim),
      ),
    );
  }

  void _calculator(ClaimsRecord claim) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620.0, maxHeight: 760.0),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Part19CalculatorWidget(claim: claim),
                const SizedBox(height: 8.0),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _changeStage(ClaimsRecord claim) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        child: StageMenuWidget(
          kind: RecordKind.claim,
          recordId: claim.reference.id,
          currentStage: claim.claimStatus,
          subject: claim.fullName.isNotEmpty ? claim.fullName : 'This claim',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return StreamBuilder<ClaimsRecord>(
      stream: ClaimsRecord.getDocument(widget.claimRef),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 240.0,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final claim = snapshot.data!;
        final work = Casework.of(claim.snapshotData);
        final stage = canonicalStage(RecordKind.claim, claim.claimStatus);
        final withLegal = stage == ClaimStage.withSolicitor;
        final role = valueOrDefault(currentUserDocument?.role, '');
        final canWorkLegal = withLegal && isLegalRole(role);
        final noticeStatus =
            claim.snapshotData['solicitor_email_status'] as String? ?? '';
        final noticeSent = noticeStatus == 'Sent';

        return Material(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(16.0),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(24.0, 16.0, 12.0, 16.0),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: theme.alternate)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            claim.fullName.isNotEmpty
                                ? claim.fullName
                                : 'Unnamed client',
                            style: GoogleFonts.inter(
                              fontSize: 20.0,
                              fontWeight: FontWeight.w700,
                              color: theme.primaryText,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            [
                              if (claim.airlineName.isNotEmpty)
                                claim.airlineName,
                              if (claim.leadRef != null)
                                'CA-${claim.leadRef!.id.substring(0, 8).toUpperCase()}',
                              claim.clientEmail,
                            ].where((s) => s.isNotEmpty).join('  ·  '),
                            style: GoogleFonts.inter(
                                fontSize: 13.0, color: theme.secondaryText),
                          ),
                        ],
                      ),
                    ),
                    StagePill(stage),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: widget.onClose ?? () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: theme.secondaryText),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // The file
                    Expanded(
                      flex: 3,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CaseworkPanelWidget(
                              kind: RecordKind.claim,
                              recordId: claim.reference.id,
                              data: claim.snapshotData,
                              stage: claim.claimStatus,
                            ),
                            if (withLegal || work.legalStage.isNotEmpty) ...[
                              const _SectionTitle('Legal stage'),
                              _LegalStageRow(
                                current: work.legalStage.isEmpty
                                    ? LegalStage.review
                                    : work.legalStage,
                                onMove: canWorkLegal && !_busy
                                    ? (to) => _moveLegalStage(claim, to)
                                    : null,
                              ),
                              if (withLegal && !isLegalRole(role))
                                Padding(
                                  padding: const EdgeInsets.only(top: 6.0),
                                  child: Text(
                                    'The legal stage is changed by the legal team.',
                                    style: GoogleFonts.inter(
                                        fontSize: 12.0,
                                        color: theme.secondaryText),
                                  ),
                                ),
                            ],
                            const _SectionTitle('Client'),
                            _ClientFacts(claim: claim),
                            const _SectionTitle('Flight'),
                            Wrap(
                              spacing: 28.0,
                              runSpacing: 12.0,
                              children: [
                                _Fact('Flight', claim.flightNumber),
                                _Fact('Route',
                                    '${claim.departure.isEmpty ? '?' : claim.departure} → ${claim.destination.isEmpty ? '?' : claim.destination}'),
                                _Fact('Date', claim.flightDate),
                                _Fact('Reason', claim.claimsReason),
                                _Fact('Delay', claim.durationOfDelay),
                                _Fact('Booking ref', claim.pnrNumber),
                                _Fact('Passengers', '${claim.passengerCount}'),
                                _Fact(
                                    'Ticket price',
                                    claim.farePaid == null
                                        ? ''
                                        : '${claim.fareCurrency} ${NumberFormat.decimalPattern().format(claim.farePaid)}'),
                                _Fact(
                                    'Amount claimed',
                                    displayClaimAmount(claim.claimsAmount,
                                        empty: '')),
                              ],
                            ),
                            if (claim.airlineResponse.trim().isNotEmpty) ...[
                              const _SectionTitle(
                                  'What the airline told the passenger'),
                              Text(
                                claim.airlineResponse,
                                style: GoogleFonts.inter(
                                    fontSize: 13.0,
                                    height: 1.45,
                                    color: theme.primaryText),
                              ),
                            ],
                            const _SectionTitle('Money'),
                            Wrap(
                              spacing: 28.0,
                              runSpacing: 12.0,
                              children: [
                                _Fact(
                                    'Latest offer',
                                    work.settlementOffer == null
                                        ? 'None recorded'
                                        : naira(work.settlementOffer!)),
                                _Fact(
                                    'Recovered',
                                    work.amountRecovered == null
                                        ? 'Nothing yet'
                                        : naira(work.amountRecovered!)),
                              ],
                            ),
                            if (work.airlineReplySummary.isNotEmpty) ...[
                              const _SectionTitle('Airline\'s last reply'),
                              Text(
                                '${work.airlineReplySummary}'
                                '${work.airlineReplyAt == null ? '' : '\n— recorded ${dateTimeFormat('d MMM y', work.airlineReplyAt)}'}',
                                style: GoogleFonts.inter(
                                    fontSize: 13.0, color: theme.primaryText),
                              ),
                            ],
                            const _SectionTitle('Documents'),
                            _Documents(claim: claim),
                            const _SectionTitle('Authority and payment'),
                            _AuthorityAndBank(claim: claim),
                            const _SectionTitle('Actions'),
                            Wrap(
                              spacing: 8.0,
                              runSpacing: 8.0,
                              children: [
                                if (stage == ClaimStage.demandPending ||
                                    stage == ClaimStage.awaitingReply)
                                  _ActionButton(
                                    icon: Icons.outgoing_mail,
                                    label: stage == ClaimStage.demandPending
                                        ? 'Send demand letter'
                                        : 'Resend demand letter',
                                    onTap: () => showSendDemand(context, claim),
                                  ),
                                if (canWorkLegal)
                                  _ActionButton(
                                    icon: Icons.send_outlined,
                                    label: noticeSent
                                        ? 'Resend final notice'
                                        : 'Send final notice',
                                    onTap: () => showSendDemand(context, claim,
                                        finalNotice: true),
                                  ),
                                _ActionButton(
                                  icon: Icons.reply_outlined,
                                  label: 'Record airline reply',
                                  onTap: _busy
                                      ? null
                                      : () => _addNote(
                                          claim, CaseNoteType.airlineReply),
                                ),
                                _ActionButton(
                                  icon: Icons.payments_outlined,
                                  label: 'Record offer',
                                  onTap: _busy
                                      ? null
                                      : () =>
                                          _addNote(claim, CaseNoteType.offer),
                                ),
                                _ActionButton(
                                  icon: Icons.note_add_outlined,
                                  label: 'Add note',
                                  onTap: _busy
                                      ? null
                                      : () =>
                                          _addNote(claim, CaseNoteType.note),
                                ),
                                _ActionButton(
                                  icon: Icons.swap_horiz_rounded,
                                  label: 'Change stage / close',
                                  onTap: () => _changeStage(claim),
                                ),
                                _ActionButton(
                                  icon: Icons.edit_outlined,
                                  label: 'Edit details',
                                  onTap: () {
                                    final router = GoRouter.of(context);
                                    if (widget.onClose == null) {
                                      Navigator.pop(context);
                                    }
                                    editClaimWith(router, claim.reference);
                                  },
                                ),
                                _ActionButton(
                                  icon: Icons.calculate_outlined,
                                  label: 'Part 19 calculator',
                                  onTap: () => _calculator(claim),
                                ),
                                _ActionButton(
                                  icon: Icons.download_outlined,
                                  label: 'Download PDF',
                                  onTap: () => _downloadPdf(claim),
                                ),
                              ],
                            ),
                            if (stage == ClaimStage.demandPending &&
                                !demandReadiness(claim.snapshotData).ready)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'The demand letter cannot go yet. '
                                  '${demandReadiness(claim.snapshotData).blockers.join(' ')}',
                                  style: GoogleFonts.inter(
                                      fontSize: 12.0,
                                      color: overdueRed(context)),
                                ),
                              ),
                            if ((claim.airlineEmailStatus == 'Send failed' ||
                                    claim.airlineEmailStatus
                                        .startsWith('Held')) &&
                                stage == ClaimStage.demandPending)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'Demand letter: ${claim.airlineEmailStatus}',
                                  style: GoogleFonts.inter(
                                      fontSize: 12.0,
                                      color: overdueRed(context)),
                                ),
                              ),
                            if (noticeStatus.isNotEmpty && !noticeSent)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'Final notice: $noticeStatus',
                                  style: GoogleFonts.inter(
                                      fontSize: 12.0,
                                      color: overdueRed(context)),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    // The history
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.primaryBackground,
                          border:
                              Border(left: BorderSide(color: theme.alternate)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  16.0, 14.0, 16.0, 0.0),
                              child: Row(
                                children: [
                                  _TabButton(
                                    label: 'History',
                                    selected: !_showAssistant,
                                    onTap: () =>
                                        setState(() => _showAssistant = false),
                                  ),
                                  const SizedBox(width: 6.0),
                                  _TabButton(
                                    label: 'AI assistant',
                                    selected: _showAssistant,
                                    onTap: () =>
                                        setState(() => _showAssistant = true),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: _showAssistant
                                  ? AiAssistPanel(
                                      kind: RecordKind.claim,
                                      recordRef: claim.reference,
                                      evidence: claim.attachedDocument,
                                    )
                                  : RecordTimeline(
                                      leadRef: claim.leadRef,
                                      claimRef: claim.reference,
                                    ),
                            ),
                          ],
                        ),
                      ),
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

class _TabButton extends StatelessWidget {
  const _TabButton(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(8.0),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 7.0),
        decoration: BoxDecoration(
          color: selected
              ? brandBlue(context).withValues(alpha: 0.16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? brandBlue(context) : theme.secondaryText,
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22.0, bottom: 10.0),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11.0,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: FlutterFlowTheme.of(context).secondaryText,
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style:
                GoogleFonts.inter(fontSize: 11.0, color: theme.secondaryText)),
        const SizedBox(height: 2.0),
        Text(
          value.trim().isEmpty ? '—' : value,
          style: GoogleFonts.inter(
            fontSize: 14.0,
            fontWeight: FontWeight.w600,
            color: theme.primaryText,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton(
      {required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = onTap == null
        ? FlutterFlowTheme.of(context).secondaryText
        : brandBlue(context);
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16.0, color: color),
      label: Text(label,
          style: GoogleFonts.inter(
              fontSize: 13.0, fontWeight: FontWeight.w600, color: color)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      ),
    );
  }
}

/// The four legal stages in order, the current one marked. With [onMove],
/// the others can be tapped to move the claim there.
class _LegalStageRow extends StatelessWidget {
  const _LegalStageRow({required this.current, required this.onMove});

  final String current;
  final void Function(String to)? onMove;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final reached = LegalStage.all.indexOf(current);
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: [
        for (var i = 0; i < LegalStage.all.length; i++)
          Builder(builder: (context) {
            final stage = LegalStage.all[i];
            final isCurrent = stage == current;
            final color = isCurrent
                ? const Color(0xFF9B6BF2)
                : (i < reached ? theme.secondaryText : theme.secondaryText);
            return InkWell(
              borderRadius: BorderRadius.circular(10.0),
              onTap: isCurrent || onMove == null ? null : () => onMove!(stage),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? color.withValues(alpha: 0.16)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(
                      color: isCurrent ? color : theme.alternate,
                      width: isCurrent ? 1.5 : 1.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      i < reached
                          ? Icons.check_circle
                          : (isCurrent
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked),
                      size: 15.0,
                      color: color,
                    ),
                    const SizedBox(width: 6.0),
                    Text(
                      stage,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight:
                            isCurrent ? FontWeight.w700 : FontWeight.w500,
                        color: isCurrent ? color : theme.primaryText,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _Documents extends StatelessWidget {
  const _Documents({required this.claim});

  final ClaimsRecord claim;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final demandUrl = claim.snapshotData['demand_letter_url'] as String? ?? '';
    final noticeUrl =
        claim.snapshotData['solicitor_letter_url'] as String? ?? '';
    final docs = <(String, String)>[
      if (claim.loaUrl.isNotEmpty) ('Letter of authority', claim.loaUrl),
      if (demandUrl.isNotEmpty) ('Demand letter', demandUrl),
      if (noticeUrl.isNotEmpty) ('Final legal notice', noticeUrl),
      for (var i = 0; i < claim.attachedDocument.length; i++)
        ('Client evidence ${i + 1}', claim.attachedDocument[i]),
    ];
    if (docs.isEmpty) {
      return Text('Nothing on file yet.',
          style: GoogleFonts.inter(fontSize: 13.0, color: theme.secondaryText));
    }
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: [
        for (final (label, url) in docs)
          InkWell(
            borderRadius: BorderRadius.circular(8.0),
            onTap: () => openStoredDocument(context, url),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 7.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: theme.alternate),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.description_outlined,
                      size: 15.0, color: brandBlue(context)),
                  const SizedBox(width: 6.0),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: theme.primaryText,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Who the client is and how to reach them. The phone number lives on the
/// lead, so it is read from there.
class _ClientFacts extends StatelessWidget {
  const _ClientFacts({required this.claim});

  final ClaimsRecord claim;

  @override
  Widget build(BuildContext context) {
    Widget facts(LeadsRecord? lead) => Wrap(
          spacing: 28.0,
          runSpacing: 12.0,
          children: [
            _Fact(
                'Email',
                claim.clientEmail.isNotEmpty
                    ? claim.clientEmail
                    : (lead?.email ?? '')),
            _Fact('Phone', lead?.phone ?? ''),
            _Fact('Country', lead?.country ?? ''),
            _Fact('Came in through', lead?.utmSource ?? ''),
            _Fact('NIN', claim.nin),
            _Fact('Passport', claim.passport),
            _Fact('BVN', claim.bvnNumber),
          ],
        );
    if (claim.leadRef == null) return facts(null);
    return StreamBuilder<LeadsRecord>(
      stream: LeadsRecord.getDocument(claim.leadRef!),
      builder: (context, snapshot) => facts(snapshot.data),
    );
  }
}

/// The client's signed authority and where their share is to be paid.
class _AuthorityAndBank extends StatelessWidget {
  const _AuthorityAndBank({required this.claim});

  final ClaimsRecord claim;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final signed = claim.signature.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 28.0,
          runSpacing: 12.0,
          children: [
            _Fact(
                'Letter of authority',
                signed
                    ? 'Signed${claim.signedAt == null ? '' : ' ${dateTimeFormat('d MMM y', claim.signedAt)}'}'
                    : 'Not signed'),
            _Fact('Terms', claim.termsAccepted ? 'Accepted' : 'Not accepted'),
            _Fact('Bank', claim.bankName),
            _Fact('Account name', claim.accountName),
            _Fact('Account number', claim.accountNo),
          ],
        ),
        if (signed) ...[
          const SizedBox(height: 12.0),
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: theme.alternate),
            ),
            child: custom_widgets.SignatureDisplayWidget(
              width: 200.0,
              height: 90.0,
              base64String: claim.signature,
            ),
          ),
        ],
      ],
    );
  }
}
