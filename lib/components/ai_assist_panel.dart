import '/backend/backend.dart';
import '/backend/services/ai_assist.dart';
import '/backend/services/casework.dart';
import '/backend/services/pipeline.dart';
import '/components/brand_colors.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// The AI assistant for one lead or claim: buttons to ask it for something,
/// and every answer it has given on this record, newest first.
///
/// The assistant only advises. Where an answer suggests recording something
/// (an airline's reply), a button offers to do it — the person presses it.
class AiAssistPanel extends StatefulWidget {
  const AiAssistPanel({
    super.key,
    required this.kind,
    required this.recordRef,
    this.evidence = const [],
  });

  final RecordKind kind;
  final DocumentReference recordRef;

  /// Addresses of the client's evidence, for "Check a document".
  final List<String> evidence;

  @override
  State<AiAssistPanel> createState() => _AiAssistPanelState();
}

class _AiAssistPanelState extends State<AiAssistPanel> {
  AiTask? _running;

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _answers =
      FirebaseFirestore.instance
          .collection('ai_outputs')
          .where('record', isEqualTo: widget.recordRef)
          .snapshots();

  void _say(String message, {bool error = false}) {
    final theme = FlutterFlowTheme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: TextStyle(color: theme.info)),
      backgroundColor: error ? theme.error : const Color(0xFF3BA55D),
      duration: Duration(seconds: error ? 7 : 3),
    ));
  }

  Future<String?> _askForReply() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        String? error;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            title: const Text('Read an airline reply'),
            content: SizedBox(
              width: 520.0,
              child: TextField(
                controller: controller,
                autofocus: true,
                minLines: 8,
                maxLines: 14,
                decoration: InputDecoration(
                  labelText: 'Paste the airline\'s reply',
                  alignLabelWithHint: true,
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
                  final text = controller.text.trim();
                  if (text.length < 20) {
                    setDialogState(() => error = 'Paste the reply first.');
                    return;
                  }
                  Navigator.pop(dialogContext, text);
                },
                child: const Text('Read it'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String?> _chooseDocument() {
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Check which document?'),
        children: [
          for (var i = 0; i < widget.evidence.length; i++)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, widget.evidence[i]),
              child: Text('Client evidence ${i + 1}'),
            ),
        ],
      ),
    );
  }

  Future<void> _run(AiTask task) async {
    if (_running != null) return;
    String? text;
    String? address;
    if (task == AiTask.classifyReply) {
      text = await _askForReply();
      if (text == null) return;
    }
    if (task == AiTask.readEvidence) {
      address = widget.evidence.length == 1
          ? widget.evidence.first
          : await _chooseDocument();
      if (address == null) return;
    }
    if (!mounted) return;
    setState(() => _running = task);
    final result = await runAiTask(
      task: task,
      recordId: widget.recordRef.id,
      text: text,
      address: address,
    );
    if (!mounted) return;
    setState(() => _running = null);
    if (!result.succeeded) _say(result.error!, error: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final tasks = AiTask.values
        .where((t) => t.kind == widget.kind)
        .where((t) => t != AiTask.readEvidence || widget.evidence.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 4.0),
          child: Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              for (final task in tasks)
                OutlinedButton.icon(
                  onPressed: _running == null ? () => _run(task) : null,
                  icon: _running == task
                      ? const SizedBox(
                          width: 14.0,
                          height: 14.0,
                          child: CircularProgressIndicator(strokeWidth: 2.0),
                        )
                      : Icon(Icons.auto_awesome_outlined,
                          size: 15.0, color: brandBlue(context)),
                  label: Text(
                    _running == task ? 'Working…' : task.label,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: brandBlue(context),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: brandBlue(context).withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 10.0),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0)),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 6.0, 20.0, 8.0),
          child: Text(
            _running != null
                ? 'This usually takes under a minute.'
                : 'The assistant advises; you decide. Check what it says '
                    'against the file before acting on it.',
            style: GoogleFonts.inter(fontSize: 11.5, color: theme.secondaryText),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _answers,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text('The answers could not be loaded.',
                      style: GoogleFonts.inter(
                          fontSize: 13.0, color: theme.secondaryText)),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              DateTime when(Map<String, dynamic> a) {
                final t = a['created_at'];
                return t is Timestamp ? t.toDate() : DateTime.now();
              }

              final answers = snapshot.data!.docs.toList()
                ..sort((a, b) => when(b.data()).compareTo(when(a.data())));
              if (answers.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text('Nothing asked yet.',
                      style: GoogleFonts.inter(
                          fontSize: 13.0, color: theme.secondaryText)),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20.0, 4.0, 20.0, 20.0),
                itemCount: answers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12.0),
                itemBuilder: (context, i) => _AnswerCard(
                  id: answers[i].id,
                  answer: answers[i].data(),
                  at: when(answers[i].data()),
                  recordRef: widget.recordRef,
                  onMessage: _say,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AnswerCard extends StatefulWidget {
  const _AnswerCard({
    required this.id,
    required this.answer,
    required this.at,
    required this.recordRef,
    required this.onMessage,
  });

  final String id;
  final Map<String, dynamic> answer;
  final DateTime at;
  final DocumentReference recordRef;
  final void Function(String message, {bool error}) onMessage;

  @override
  State<_AnswerCard> createState() => _AnswerCardState();
}

class _AnswerCardState extends State<_AnswerCard> {
  bool _busy = false;

  Future<void> _review(bool useful) async {
    setState(() => _busy = true);
    final result = await reviewAiAnswer(outputId: widget.id, useful: useful);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!result.succeeded) widget.onMessage(result.error!, error: true);
  }

  /// Put the airline's reply, as the assistant summarised it, on the claim.
  Future<void> _recordReply(Map<String, dynamic> output) async {
    setState(() => _busy = true);
    final summary = '${aiCodeLabel(output['category'] as String? ?? '')}. '
        '${output['summary'] ?? ''}';
    var result = await addCaseNote(
      kind: RecordKind.claim,
      id: widget.recordRef.id,
      text: summary,
      type: CaseNoteType.airlineReply,
    );
    final offered = output['amount_offered'];
    if (result.succeeded && offered is num && offered > 0) {
      result = await addCaseNote(
        kind: RecordKind.claim,
        id: widget.recordRef.id,
        text: 'Offer stated in the airline\'s reply.',
        type: CaseNoteType.offer,
        amount: offered.toDouble(),
      );
    }
    if (!mounted) return;
    setState(() => _busy = false);
    widget.onMessage(
      result.succeeded ? 'Recorded on the claim.' : result.error!,
      error: !result.succeeded,
    );
  }

  String _format(dynamic value) {
    if (value is bool) return value ? 'Yes' : 'No';
    if (value is num) return '₦${formatNumber(value, formatType: FormatType.decimal, decimalType: DecimalType.automatic)}';
    if (value is String) return aiCodeLabel(value);
    return '$value';
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final answer = widget.answer;
    final task = answer['task'] as String? ?? '';
    final output =
        (answer['output'] as Map?)?.cast<String, dynamic>() ?? const {};
    final status = answer['review_status'] as String? ?? 'pending';

    TextStyle body() =>
        GoogleFonts.inter(fontSize: 13.0, color: theme.primaryText, height: 1.4);

    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: theme.alternate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_outlined,
                  size: 15.0, color: brandBlue(context)),
              const SizedBox(width: 6.0),
              Expanded(
                child: Text(
                  answer['task_label'] as String? ?? 'AI assistant',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: theme.primaryText,
                  ),
                ),
              ),
              Text(
                '${answer['requested_by_name'] ?? ''} · '
                '${dateTimeFormat('d MMM, HH:mm', widget.at)}',
                style: GoogleFonts.inter(
                    fontSize: 11.5, color: theme.secondaryText),
              ),
            ],
          ),
          for (final field in aiAnswerFields[task] ?? const <AiField>[])
            Builder(builder: (context) {
              final value = output[field.key];
              final empty = value == null ||
                  (value is String && value.trim().isEmpty) ||
                  (value is List && value.isEmpty);
              // An empty list of problems is worth saying; other blanks are not.
              if (empty && field.key != 'mismatches') {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            field.label.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: theme.secondaryText,
                            ),
                          ),
                        ),
                        if (field.isDraft)
                          InkWell(
                            onTap: () async {
                              await Clipboard.setData(
                                  ClipboardData(text: '$value'));
                              widget.onMessage('Draft copied.');
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: Text(
                                'Copy',
                                style: GoogleFonts.inter(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w600,
                                  color: brandBlue(context),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3.0),
                    if (empty)
                      Text('Nothing found.', style: body())
                    else if (value is List)
                      for (final item in value)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('•  ', style: body()),
                              Expanded(
                                  child:
                                      SelectableText('$item', style: body())),
                            ],
                          ),
                        )
                    else if (field.isDraft)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: theme.primaryBackground,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: SelectableText('$value', style: body()),
                      )
                    else
                      SelectableText(_format(value), style: body()),
                  ],
                ),
              );
            }),
          const SizedBox(height: 12.0),
          Wrap(
            spacing: 6.0,
            runSpacing: 6.0,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (status == 'pending') ...[
                Text('Was this useful?',
                    style: GoogleFonts.inter(
                        fontSize: 12.0, color: theme.secondaryText)),
                TextButton(
                  onPressed: _busy ? null : () => _review(true),
                  child: const Text('Yes'),
                ),
                TextButton(
                  onPressed: _busy ? null : () => _review(false),
                  child: const Text('No'),
                ),
              ] else
                Text(
                  status == 'useful'
                      ? 'Marked useful by ${answer['reviewed_by_name'] ?? 'staff'}'
                      : 'Marked not useful by ${answer['reviewed_by_name'] ?? 'staff'}',
                  style: GoogleFonts.inter(
                      fontSize: 12.0, color: theme.secondaryText),
                ),
              if (task == 'classify_reply')
                TextButton.icon(
                  onPressed: _busy ? null : () => _recordReply(output),
                  icon: const Icon(Icons.reply_outlined, size: 15.0),
                  label: const Text('Record this reply on the claim'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
