import '/backend/services/documents.dart';
import '/backend/services/info_requests.dart';
import '/backend/services/pipeline.dart';
import '/components/brand_colors.dart';
import '/components/work_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Ask the client of a lead or claim for what is missing. The client is
/// emailed a link to a form on the website; the link is also shown here to
/// copy into WhatsApp.
Future<void> showInfoRequestDialog(
  BuildContext context, {
  required RecordKind kind,
  required String recordId,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _InfoRequestDialog(kind: kind, recordId: recordId),
  );
}

class _InfoRequestDialog extends StatefulWidget {
  const _InfoRequestDialog({required this.kind, required this.recordId});

  final RecordKind kind;
  final String recordId;

  @override
  State<_InfoRequestDialog> createState() => _InfoRequestDialogState();
}

class _InfoRequestDialogState extends State<_InfoRequestDialog> {
  final _picked = <String>{};
  final _questions = List.generate(3, (_) => TextEditingController());
  final _message = TextEditingController();
  bool _sendEmail = true;
  bool _busy = false;
  String? _error;
  InfoRequestResult? _sent;

  @override
  void dispose() {
    for (final c in _questions) {
      c.dispose();
    }
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await sendInfoRequest(
      kind: widget.kind,
      recordId: widget.recordId,
      items: infoRequestItems.keys.where(_picked.contains).toList(),
      questions: _questions
          .map((c) => c.text.trim())
          .where((q) => q.isNotEmpty)
          .toList(),
      message: _message.text.trim(),
      sendEmail: _sendEmail,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (result.succeeded) {
        _sent = result;
      } else {
        _error = result.error;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final label =
        GoogleFonts.inter(fontSize: 12.0, color: theme.secondaryText);
    final sent = _sent;
    if (sent != null) {
      return AlertDialog(
        title: const Text('Request sent'),
        content: SizedBox(
          width: 460.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _sendEmail
                    ? (sent.emailed
                        ? 'Emailed to ${sent.email}. You can also send the link below by WhatsApp or text.'
                        : 'The email to ${sent.email} did not go. Send the link below by WhatsApp or text instead.')
                    : 'No email was sent. Send the client this link by WhatsApp or text.',
                style: GoogleFonts.inter(
                    fontSize: 13.0,
                    color: _sendEmail && !sent.emailed
                        ? theme.error
                        : theme.primaryText),
              ),
              const SizedBox(height: 12.0),
              SelectableText(sent.link!,
                  style: GoogleFonts.inter(fontSize: 12.0)),
              const SizedBox(height: 8.0),
              Text('The link works once and lasts 14 days.', style: label),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 18.0),
            label: const Text('Copy link'),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: sent.link!));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link copied')));
            },
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      );
    }

    final nothing = _picked.isEmpty &&
        _questions.every((c) => c.text.trim().isEmpty);
    return AlertDialog(
      title: const Text('Request information from the client'),
      content: SizedBox(
        width: 520.0,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tick what is missing. Answers go straight onto this record; files go into its documents.',
                style: label,
              ),
              const SizedBox(height: 12.0),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: [
                  for (final entry in infoRequestItems.entries)
                    FilterChip(
                      label: Text(entry.value),
                      avatar: infoRequestFileItems.contains(entry.key)
                          ? const Icon(Icons.attach_file_rounded, size: 16.0)
                          : null,
                      selected: _picked.contains(entry.key),
                      onSelected: (on) => setState(() => on
                          ? _picked.add(entry.key)
                          : _picked.remove(entry.key)),
                    ),
                ],
              ),
              const SizedBox(height: 16.0),
              Text('Questions of your own (optional)', style: label),
              for (final (i, c) in _questions.indexed)
                Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: TextField(
                    controller: c,
                    maxLength: 300,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      isDense: true,
                      counterText: '',
                      hintText: i == 0
                          ? 'e.g. Did the airline give a reason at the gate?'
                          : 'Another question',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              const SizedBox(height: 16.0),
              Text('Note to the client (optional)', style: label),
              const SizedBox(height: 6.0),
              TextField(
                controller: _message,
                minLines: 2,
                maxLines: 4,
                maxLength: 1000,
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _sendEmail,
                onChanged: (v) => setState(() => _sendEmail = v ?? true),
                title: Text('Email the link to the client',
                    style: GoogleFonts.inter(fontSize: 13.0)),
                subtitle: Text(
                    'Untick to only make the link, for WhatsApp or text.',
                    style: label),
              ),
              if (_error != null)
                Text(_error!,
                    style:
                        GoogleFonts.inter(fontSize: 13.0, color: theme.error)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _busy || nothing ? null : _send,
          child: Text(_busy ? 'Sending…' : 'Send request'),
        ),
      ],
    );
  }
}

/// The requests made on a record: what was asked, and what came back.
class InfoRequestsPanel extends StatelessWidget {
  const InfoRequestsPanel({super.key, required this.record});

  final DocumentReference record;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DocumentSnapshot<Map<String, dynamic>>>>(
      stream: infoRequestsFor(record),
      builder: (context, snapshot) {
        final requests = snapshot.data ?? const [];
        if (requests.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FileSection('Requests to the client'),
            for (final r in requests) _RequestCard(request: r),
          ],
        );
      },
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});

  final DocumentSnapshot<Map<String, dynamic>> request;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final d = request.data() ?? const {};
    final items = List<String>.from(d['items'] ?? const []);
    final questions = List<String>.from(d['questions'] ?? const []);
    final replies = List<String>.from(d['replies'] ?? const []);
    final answers = Map<String, dynamic>.from(d['answers'] ?? const {});
    final unavailable = Map<String, dynamic>.from(d['unavailable'] ?? const {});
    final files = List<Map>.from(d['files'] ?? const []);
    final createdAt = (d['created_at'] as Timestamp?)?.toDate();
    final expiresAt = (d['expires_at'] as Timestamp?)?.toDate();
    var status = d['status'] as String? ?? 'open';
    if (status == 'open' &&
        expiresAt != null &&
        expiresAt.isBefore(DateTime.now())) {
      status = 'expired';
    }
    const statusText = {
      'open': 'Waiting for the client',
      'answered': 'Answered',
      'cancelled': 'Withdrawn',
      'replaced': 'Replaced by a newer request',
      'expired': 'Expired, not answered',
    };
    final small = GoogleFonts.inter(fontSize: 12.0, color: theme.secondaryText);
    final body = GoogleFonts.inter(fontSize: 13.0, color: theme.primaryText);

    String answerText(String key) {
      final v = answers[key];
      if (v is Map) return '${v['currency'] ?? ''} ${v['amount'] ?? ''}'.trim();
      return v?.toString() ?? '';
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: theme.alternate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  [
                    statusText[status] ?? status,
                    if (createdAt != null)
                      'asked ${dateTimeFormat('d MMM y', createdAt)}',
                    if ((d['created_by_name'] ?? '').toString().isNotEmpty)
                      'by ${d['created_by_name']}',
                  ].join('  ·  '),
                  style: GoogleFonts.inter(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w600,
                      color: status == 'answered'
                          ? brandBlue(context)
                          : theme.primaryText),
                ),
              ),
              if (status == 'open')
                TextButton(
                  onPressed: () => _withdraw(context),
                  child: const Text('Withdraw'),
                ),
            ],
          ),
          const SizedBox(height: 6.0),
          for (final key in items)
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Text.rich(TextSpan(children: [
                TextSpan(
                    text: '${infoRequestItems[key] ?? key}: ', style: small),
                TextSpan(
                  text: unavailable.containsKey(key)
                      ? 'does not have it${(unavailable[key] ?? '').toString().isEmpty ? '' : ' (${unavailable[key]})'}'
                      : infoRequestFileItems.contains(key)
                          ? (files.any((f) => f['item'] == key)
                              ? ''
                              : (status == 'answered' ? 'no file' : '—'))
                          : (answerText(key).isEmpty ? '—' : answerText(key)),
                  style: body,
                ),
              ])),
            ),
          for (final f in files)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0)),
                icon: const Icon(Icons.attach_file_rounded, size: 16.0),
                label: Text(
                    '${infoRequestItems[f['item']] ?? f['item']}: ${f['name']}'),
                onPressed: () =>
                    openStoredDocument(context, f['path'].toString()),
              ),
            ),
          for (final (i, q) in questions.indexed)
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(q, style: small),
                  Text(i < replies.length ? replies[i] : '—', style: body),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _withdraw(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final error = await cancelInfoRequest(request.id);
    messenger.showSnackBar(SnackBar(
        content: Text(error ?? 'Request withdrawn. Its link no longer works.')));
  }
}

/// The button that opens [showInfoRequestDialog], for a record's actions.
class InfoRequestButton extends StatelessWidget {
  const InfoRequestButton(
      {super.key, required this.kind, required this.recordId});

  final RecordKind kind;
  final String recordId;

  @override
  Widget build(BuildContext context) {
    return WorkButton(
      icon: Icons.mark_email_unread_outlined,
      label: 'Request information',
      onTap: () =>
          showInfoRequestDialog(context, kind: kind, recordId: recordId),
    );
  }
}
