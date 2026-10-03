import '/backend/backend.dart';
import '/backend/services/casework.dart';
import '/backend/services/pipeline.dart';
import '/components/ai_assist_panel.dart';
import '/components/case_file_widget.dart';
import '/components/casework_panel_widget.dart';
import '/components/info_request_widget.dart';
import '/components/record_timeline.dart';
import '/components/work_ui.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/leads/leads_options/leads_options_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Opens the file for [leadRef] over the current page.
Future<void> showLeadFile(BuildContext context, DocumentReference leadRef) {
  return showDialog<void>(
    context: context,
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.all(20.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1160.0, maxHeight: 860.0),
        child: LeadFileWidget(leadRef: leadRef),
      ),
    ),
  );
}

/// Everything about one lead on one screen: who they are, what happened to
/// their flight, what the website made of it, who owns it and what is due,
/// and its history — with the actions an agent takes on it.
class LeadFileWidget extends StatefulWidget {
  const LeadFileWidget({super.key, required this.leadRef});

  final DocumentReference leadRef;

  @override
  State<LeadFileWidget> createState() => _LeadFileWidgetState();
}

class _LeadFileWidgetState extends State<LeadFileWidget> {
  bool _busy = false;
  bool _showAssistant = false;

  Future<void> _addNote(LeadsRecord lead) async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        String? error;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            title: const Text('Add a note'),
            content: SizedBox(
              width: 420.0,
              child: TextField(
                controller: controller,
                autofocus: true,
                minLines: 3,
                maxLines: 6,
                maxLength: 2000,
                decoration: InputDecoration(
                  labelText: 'Note',
                  hintText: 'What was said, and what happens next',
                  errorText: error,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final value = controller.text.trim();
                  if (value.isEmpty) {
                    setDialogState(() => error = 'This cannot be empty.');
                    return;
                  }
                  Navigator.pop(dialogContext, value);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
    if (text == null || !mounted) return;
    setState(() => _busy = true);
    final result = await addCaseNote(
        kind: RecordKind.lead, id: lead.reference.id, text: text);
    if (!mounted) return;
    setState(() => _busy = false);
    showCaseActionResult(context, result, 'Note added.');
  }

  void _changeStage(LeadsRecord lead) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        child: LeadsOptionsWidget(leadRef: lead),
      ),
    );
  }

  /// What the website made of this lead when it came in.
  Widget _routing(LeadsRecord lead) {
    final theme = FlutterFlowTheme.of(context);
    final (String label, Color color) = switch (lead.handler) {
      'claims_assist' => ('In house — we act on this claim', theme.success),
      'register_interest' => (
          'Interest only — not a claim we are taking on',
          theme.warning
        ),
      'decline' => ('Declined — no scheme we pursue', theme.error),
      'reclaims4u' => (
          'Referred to partner — referral now closed',
          theme.warning
        ),
      _ => (lead.handler, theme.secondaryText),
    };
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14.0),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 9.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w700,
                  color: theme.primaryText)),
          if (lead.handlerReason.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Text(lead.handlerReason,
                  style: GoogleFonts.inter(
                      fontSize: 12.5, color: theme.secondaryText)),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return StreamBuilder<LeadsRecord>(
      stream: LeadsRecord.getDocument(widget.leadRef),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 240.0,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final lead = snapshot.data!;
        final stage = canonicalStage(RecordKind.lead, lead.status);
        final what =
            lead.complaintType.isNotEmpty ? lead.complaintType : lead.claimType;

        String money(double value) {
          final symbol = lead.fareCurrency.isEmpty || lead.fareCurrency == 'NGN'
              ? '₦'
              : '${lead.fareCurrency} ';
          return '$symbol${NumberFormat('#,##0.##').format(value)}';
        }

        return Material(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(16.0),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
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
                            lead.fullName.isNotEmpty
                                ? lead.fullName
                                : 'Unnamed lead',
                            style: GoogleFonts.inter(
                              fontSize: 20.0,
                              fontWeight: FontWeight.w700,
                              color: theme.primaryText,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            [
                              what,
                              lead.airlineName,
                              if (lead.createdAt != null)
                                'received ${dateTimeFormat('d MMM y', lead.createdAt)}',
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
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: theme.secondaryText),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CaseworkPanelWidget(
                              kind: RecordKind.lead,
                              recordId: lead.reference.id,
                              data: lead.snapshotData,
                              stage: lead.status,
                            ),
                            if (lead.handler.isNotEmpty) _routing(lead),
                            const FileSection('Contact'),
                            Wrap(
                              spacing: 28.0,
                              runSpacing: 12.0,
                              children: [
                                FileFact('Email', lead.email),
                                FileFact('Phone', lead.phone),
                                FileFact('Prefers', lead.mediumOfContact),
                                FileFact('Country', lead.country),
                                FileFact('Came in through', lead.utmSource),
                              ],
                            ),
                            const FileSection('What happened'),
                            Wrap(
                              spacing: 28.0,
                              runSpacing: 12.0,
                              children: [
                                FileFact('Problem', what),
                                FileFact('Airline', lead.airlineName),
                                FileFact('Flight', lead.flightNumber),
                                FileFact(
                                    'Flight date', _dateText(lead.flightDate)),
                                FileFact(
                                    'Delay',
                                    lead.delayHours == null
                                        ? ''
                                        : '${NumberFormat('0.##').format(lead.delayHours)} hours'),
                                FileFact(
                                    'Ticket price',
                                    lead.farePaid == null
                                        ? ''
                                        : money(lead.farePaid!)),
                                FileFact(
                                    'Passengers', '${lead.passengerCount}'),
                                FileFact('Booking ref', lead.bookingReference),
                                FileFact('Rules', lead.regime),
                                FileFact(
                                    'Website estimate', lead.estimateValue),
                                FileFact(
                                    'Authority',
                                    lead.loaSigned
                                        ? 'Signed on the website'
                                        : 'Not signed yet'),
                                if (lead.loaSigned &&
                                    lead.workMayStartAt != null)
                                  FileFact(
                                      'Work may start',
                                      lead.workMayStartAt!
                                              .isAfter(DateTime.now())
                                          ? '${dateTimeFormat('d MMM y', lead.workMayStartAt)} (can still cancel)'
                                          : 'Now'),
                                if (lead.bankDetailsPending)
                                  const FileFact(
                                      'Bank details', 'Still to be collected'),
                              ],
                            ),
                            if (lead.loaSigned) _SignedAuthority(lead: lead),
                            InfoRequestsPanel(record: lead.reference),
                            if (lead.initialSummary.trim().isNotEmpty ||
                                lead.disruptionDetails.trim().isNotEmpty) ...[
                              const FileSection('In their words'),
                              for (final words in [
                                lead.initialSummary.trim(),
                                lead.disruptionDetails.trim(),
                              ])
                                if (words.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: SelectableText(
                                      words,
                                      style: GoogleFonts.inter(
                                          fontSize: 13.0,
                                          height: 1.45,
                                          color: theme.primaryText),
                                    ),
                                  ),
                            ],
                            const FileSection('Actions'),
                            Wrap(
                              spacing: 8.0,
                              runSpacing: 8.0,
                              children: [
                                WorkButton(
                                  icon: Icons.swap_horiz_rounded,
                                  label: 'Change stage',
                                  onTap: () => _changeStage(lead),
                                ),
                                WorkButton(
                                  icon: Icons.note_add_outlined,
                                  label: 'Add note',
                                  onTap: _busy ? null : () => _addNote(lead),
                                ),
                                InfoRequestButton(
                                  kind: RecordKind.lead,
                                  recordId: lead.reference.id,
                                ),
                                if (lead.claimRef != null)
                                  WorkButton(
                                    icon: Icons.folder_open_outlined,
                                    label: 'Open the claim',
                                    onTap: () {
                                      final navigator = Navigator.of(context);
                                      final root = navigator.context;
                                      navigator.pop();
                                      showCaseFile(root, lead.claimRef!);
                                    },
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
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
                                  WorkTab(
                                    label: 'History',
                                    selected: !_showAssistant,
                                    onTap: () =>
                                        setState(() => _showAssistant = false),
                                  ),
                                  const SizedBox(width: 6.0),
                                  WorkTab(
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
                                      kind: RecordKind.lead,
                                      recordRef: lead.reference,
                                    )
                                  : RecordTimeline(leadRef: lead.reference),
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

/// "2026-09-30" as "30 Sep 2026"; anything else as it came.
String _dateText(String ymd) {
  final d = DateTime.tryParse(ymd);
  return d == null ? ymd : dateTimeFormat('d MMM y', d);
}

/// What the claimant gave when they signed the letter of authority on the
/// website: who signed, their details, everyone on the booking, and the
/// signature itself.
class _SignedAuthority extends StatelessWidget {
  const _SignedAuthority({required this.lead});

  final LeadsRecord lead;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FileSection('Signed authority'),
        Wrap(
          spacing: 28.0,
          runSpacing: 12.0,
          children: [
            FileFact('Signed as', lead.signedName),
            FileFact(
                'Signed on',
                lead.signedAt == null
                    ? ''
                    : dateTimeFormat('d MMM y, HH:mm', lead.signedAt)),
            FileFact('Date of birth', _dateText(lead.dateOfBirth)),
            FileFact('Address', lead.address),
          ],
        ),
        if (lead.passengers.isNotEmpty) ...[
          const SizedBox(height: 12.0),
          Text(
            'Also on the booking',
            style: GoogleFonts.inter(
                fontSize: 12.0, color: theme.secondaryText),
          ),
          const SizedBox(height: 4.0),
          for (final p in lead.passengers)
            Text(
              [
                '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'.trim(),
                if ((p['date_of_birth'] ?? '').toString().isNotEmpty)
                  'born ${_dateText(p['date_of_birth'].toString())}',
                if (p['is_minor'] == true) 'under 18',
              ].join('  ·  '),
              style:
                  GoogleFonts.inter(fontSize: 13.0, color: theme.primaryText),
            ),
        ],
        if (lead.signature.isNotEmpty) ...[
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
              base64String: lead.signature,
            ),
          ),
        ],
      ],
    );
  }
}
