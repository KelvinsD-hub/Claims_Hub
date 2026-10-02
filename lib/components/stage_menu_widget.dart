import '/auth/firebase_auth/auth_util.dart';
import '/backend/services/pipeline.dart';
import '/backend/backend.dart';
import '/components/ai_assist_panel.dart';
import '/components/casework_panel_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The "move this record on" menu for a lead or a claim.
///
/// Shows who owns the record and what it is waiting for, then offers only the
/// moves allowed from its current stage for the signed-in person's role, asks
/// for a note (required when closing something without an outcome), and sends
/// the change to the server.
class StageMenuWidget extends StatefulWidget {
  const StageMenuWidget({
    super.key,
    required this.kind,
    required this.recordId,
    required this.currentStage,
    required this.subject,
    this.data,
    this.confirmBefore,
  });

  final RecordKind kind;
  final String recordId;
  final String currentStage;

  /// Who the record is about, for the dialogs: "Tunde Bello".
  final String subject;

  /// The record's document data. With it, the menu shows the owner and the
  /// next action.
  final Map<String, dynamic>? data;

  /// Extra check before a particular move goes ahead. Return false to stop it.
  final Future<bool> Function(BuildContext context, String to)? confirmBefore;

  @override
  State<StageMenuWidget> createState() => _StageMenuWidgetState();
}

class _StageMenuWidgetState extends State<StageMenuWidget> {
  String? _busy;

  IconData _icon(String to) {
    switch (to) {
      case LeadStage.contacted:
        return Icons.phone_in_talk_outlined;
      case LeadStage.qualified:
      case ClaimStage.won:
        return Icons.check_circle;
      case LeadStage.rejected:
      case ClaimStage.lost:
        return Icons.cancel_outlined;
      case ClaimStage.withdrawn:
        return Icons.block;
      case ClaimStage.withSolicitor:
        return Icons.gavel_rounded;
      case ClaimStage.demandPending:
        return Icons.mark_email_read_outlined;
      case ClaimStage.awaitingReply:
        return Icons.hourglass_bottom_rounded;
      case ClaimStage.paid:
        return Icons.payments_outlined;
      case ClaimStage.detailsPending:
        return Icons.undo_rounded;
      default:
        return Icons.arrow_forward_rounded;
    }
  }

  Color _color(BuildContext context, String to) {
    final theme = FlutterFlowTheme.of(context);
    switch (to) {
      case LeadStage.qualified:
      case ClaimStage.won:
      case ClaimStage.paid:
        return const Color(0xFF3BC111);
      case LeadStage.rejected:
      case ClaimStage.lost:
      case ClaimStage.withdrawn:
        return theme.error;
      default:
        return theme.primaryText;
    }
  }

  /// Returns the note (and, for a win, the amount recovered), or null if the
  /// person backed out.
  Future<({String note, double? amount})?> _askForNote(String to) {
    final required = moveNeedsReason(to);
    final askAmount = widget.kind == RecordKind.claim && to == ClaimStage.won;
    final controller = TextEditingController();
    final amountController = TextEditingController();
    return showDialog<({String note, double? amount})>(
      context: context,
      builder: (dialogContext) {
        String? error;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            title: Text(moveLabel(widget.kind, widget.currentStage, to)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.subject}: '
                  '${canonicalStage(widget.kind, widget.currentStage)} → $to',
                ),
                const SizedBox(height: 12.0),
                if (askAmount) ...[
                  TextField(
                    controller: amountController,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount recovered (naira)',
                      hintText: 'Leave blank if not known yet',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12.0),
                ],
                TextField(
                  controller: controller,
                  autofocus: !askAmount,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 1000,
                  decoration: InputDecoration(
                    labelText:
                        required ? 'Reason (required)' : 'Note (optional)',
                    hintText: required
                        ? 'Why is this being closed?'
                        : 'Anything the next person should know',
                    errorText: error,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final note = controller.text.trim();
                  if (required && note.isEmpty) {
                    setDialogState(() => error = 'Please give a reason.');
                    return;
                  }
                  final typed =
                      amountController.text.replaceAll(RegExp(r'[^0-9.]'), '');
                  final amount = typed.isEmpty ? null : double.tryParse(typed);
                  if (typed.isNotEmpty && (amount == null || amount <= 0)) {
                    setDialogState(
                        () => error = 'The amount recovered is not a number.');
                    return;
                  }
                  Navigator.pop(dialogContext, (note: note, amount: amount));
                },
                child: const Text('Confirm'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _move(String to) async {
    if (_busy != null) return;
    if (widget.confirmBefore != null &&
        !await widget.confirmBefore!(context, to)) {
      return;
    }
    if (!mounted) return;
    final answer = await _askForNote(to);
    if (answer == null || !mounted) return;

    setState(() => _busy = to);
    final result = await changeStage(
      kind: widget.kind,
      id: widget.recordId,
      to: to,
      note: answer.note,
      amount: answer.amount,
    );
    if (!mounted) return;
    setState(() => _busy = null);

    final theme = FlutterFlowTheme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.succeeded ? '${widget.subject} moved to $to.' : result.error!,
          style: TextStyle(color: theme.info),
        ),
        duration: Duration(milliseconds: result.succeeded ? 4000 : 7000),
        backgroundColor:
            result.succeeded ? const Color(0xFF3BA55D) : theme.error,
      ),
    );
    if (result.succeeded) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final role = valueOrDefault(currentUserDocument?.role, '');
    final stage = canonicalStage(widget.kind, widget.currentStage);
    final moves = allowedMoves(widget.kind, widget.currentStage, role);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        width: 340.0,
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          boxShadow: const [
            BoxShadow(
              blurRadius: 4.0,
              color: Color(0x33000000),
              offset: Offset(0.0, 2.0),
            )
          ],
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12.0, 4.0, 12.0, 0.0),
                child: Text(
                  widget.kind == RecordKind.lead
                      ? 'Update Lead Status'
                      : 'Update Claim Status',
                  style: theme.labelMedium.override(
                    font: GoogleFonts.inter(),
                    letterSpacing: 0.0,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12.0, 2.0, 12.0, 8.0),
                child: Text(
                  'Now: $stage',
                  style: theme.bodyMedium.override(
                    font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (widget.data != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: CaseworkPanelWidget(
                    kind: widget.kind,
                    recordId: widget.recordId,
                    data: widget.data!,
                    stage: widget.currentStage,
                  ),
                ),
              if (widget.kind == RecordKind.lead)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8.0),
                    onTap: () => showDialog<void>(
                      context: context,
                      builder: (_) => Dialog(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0)),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                              maxWidth: 560.0, maxHeight: 720.0),
                          child: AiAssistPanel(
                            kind: RecordKind.lead,
                            recordRef: FirebaseFirestore.instance
                                .doc('leads/${widget.recordId}'),
                          ),
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 10.0),
                      child: Row(
                        children: [
                          Icon(Icons.auto_awesome_outlined,
                              color: brandBlue(context), size: 20.0),
                          const SizedBox(width: 12.0),
                          Expanded(
                            child: Text(
                              'AI assistant — triage this lead',
                              style: theme.bodyMedium.override(
                                font: GoogleFonts.inter(),
                                letterSpacing: 0.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (moves.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12.0, 0.0, 12.0, 8.0),
                  child: Text(
                    widget.kind == RecordKind.lead &&
                            stage == LeadStage.qualified
                        ? 'This lead has a claim. Its progress is tracked on '
                            'the claim from here.'
                        : 'This is closed. A Manager or above can reopen it.',
                    style: theme.bodySmall.override(
                      font: GoogleFonts.inter(),
                      color: theme.secondaryText,
                      letterSpacing: 0.0,
                    ),
                  ),
                ),
              for (final to in moves)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8.0),
                    onTap: _busy == null ? () => _move(to) : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 10.0),
                      child: Row(
                        children: [
                          _busy == to
                              ? const SizedBox(
                                  width: 20.0,
                                  height: 20.0,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.0),
                                )
                              : Icon(_icon(to),
                                  color: _color(context, to), size: 20.0),
                          const SizedBox(width: 12.0),
                          Expanded(
                            child: Text(
                              moveLabel(widget.kind, widget.currentStage, to),
                              style: theme.bodyMedium.override(
                                font: GoogleFonts.inter(),
                                letterSpacing: 0.0,
                              ),
                            ),
                          ),
                        ],
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
}
