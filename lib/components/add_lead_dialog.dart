import '/backend/schema/leads_record.dart';
import '/backend/services/add_lead.dart';
import '/components/lead_file_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

/// Add a lead for someone who phoned, sent a WhatsApp or a social media
/// message, or walked in. Staff either type in what they were told, or take
/// a name and a number and send the person the full claim form. The lead
/// records who entered it (functions/add-lead.js).
///
/// Closes with ✕, Cancel, Esc or a click outside; anything typed is only
/// thrown away after asking.
Future<void> showAddLeadDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => _AddLeadDialog(host: context),
  );
}

class _AddLeadDialog extends StatefulWidget {
  const _AddLeadDialog({required this.host});

  /// The page that opened the dialog, to open the new lead from.
  final BuildContext host;

  @override
  State<_AddLeadDialog> createState() => _AddLeadDialogState();
}

class _AddLeadDialogState extends State<_AddLeadDialog> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _airline = TextEditingController();
  final _flightNumber = TextEditingController();
  final _from = TextEditingController();
  final _to = TextEditingController();
  final _bookingRef = TextEditingController();
  final _note = TextEditingController();
  final _message = TextEditingController();
  late final _all = [
    _name, _phone, _email, _airline, _flightNumber, _from, _to, _bookingRef,
    _note, _message,
  ];

  bool _sendForm = false;
  String? _reached;
  String? _heard;
  String? _problem;
  DateTime? _flightDate;
  bool _own = true;
  bool _sendEmail = true;
  bool _busy = false;
  bool _discard = false;
  String? _error;
  AddLeadResult? _done;

  @override
  void dispose() {
    for (final c in _all) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _typedAnything =>
      _all.any((c) => c.text.trim().isNotEmpty) ||
      _reached != null ||
      _heard != null ||
      _problem != null ||
      _flightDate != null;

  bool get _ready =>
      _name.text.trim().length >= 2 &&
      (_phone.text.trim().isNotEmpty || _email.text.trim().isNotEmpty) &&
      _reached != null;

  Future<void> _askToDiscard() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard this lead?'),
        content: const Text('What you have typed will not be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (leave != true || !mounted) return;
    setState(() => _discard = true);
    // Closed after the rebuild, once the dialog lets itself be closed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(widget.host);
    final host = widget.host;
    setState(() {
      _busy = true;
      _error = null;
    });
    final fields = <String, String>{
      'full_name': _name.text.trim(),
      'phone': _phone.text.trim(),
      'email': _email.text.trim(),
      'reached_via': _reached ?? '',
      'heard_from': _heard ?? '',
      if (_sendForm) 'message': _message.text.trim(),
      if (!_sendForm) ...{
        'complaint_type': _problem ?? '',
        'airline_name': _airline.text.trim(),
        'flight_number': _flightNumber.text.trim(),
        'flight_date': _flightDate == null
            ? ''
            : DateFormat('yyyy-MM-dd').format(_flightDate!),
        'route_from': _from.text.trim(),
        'route_to': _to.text.trim(),
        'booking_reference': _bookingRef.text.trim(),
        'note': _note.text.trim(),
      },
    };
    final result = await addLead(
      fields: fields,
      sendForm: _sendForm,
      own: _own,
      sendEmail: _sendEmail && _email.text.trim().isNotEmpty,
    );
    if (!mounted) return;
    if (!result.saved) {
      setState(() {
        _busy = false;
        _error = result.error;
      });
      return;
    }
    if (!_sendForm && result.error == null) {
      // Typed in: done. Say so on the page, with a way in.
      setState(() => _discard = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
        messenger.showSnackBar(SnackBar(
          content: Text('Lead saved: ${fields['full_name']}'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () {
              if (host.mounted) {
                showLeadFile(host, LeadsRecord.collection.doc(result.id));
              }
            },
          ),
        ));
      });
      return;
    }
    setState(() {
      _busy = false;
      _done = result;
    });
  }

  void _openLead(String id) {
    final host = widget.host;
    Navigator.of(context).pop();
    if (host.mounted) showLeadFile(host, LeadsRecord.collection.doc(id));
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _flightDate ?? now,
      firstDate: DateTime(2000),
      lastDate: now.add(const Duration(days: 1)),
      helpText: 'Flight date',
    );
    if (picked != null) setState(() => _flightDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _discard || _done != null || !_typedAnything,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_busy) _askToDiscard();
      },
      child: _done != null ? _sentView(_done!) : _formView(),
    );
  }

  Widget _title(String text, String sub) {
    final theme = FlutterFlowTheme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text),
              const SizedBox(height: 4.0),
              Text(sub,
                  style: GoogleFonts.inter(
                      fontSize: 12.5, color: theme.secondaryText)),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close_rounded),
          onPressed: _busy ? null : () => Navigator.maybePop(context),
        ),
      ],
    );
  }

  Widget _formView() {
    final theme = FlutterFlowTheme.of(context);
    final label = GoogleFonts.inter(fontSize: 12.0, color: theme.secondaryText);
    final hasEmail = _email.text.trim().isNotEmpty;

    Widget box(String text, TextEditingController c,
        {String? hint,
        double width = 270.0,
        TextInputType? keyboard,
        int lines = 1,
        int? max}) {
      return SizedBox(
        width: width,
        child: TextField(
          controller: c,
          keyboardType: keyboard,
          minLines: lines,
          maxLines: lines == 1 ? 1 : lines + 3,
          maxLength: max,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: text,
            hintText: hint,
            isDense: true,
            counterText: '',
            border: const OutlineInputBorder(),
          ),
        ),
      );
    }

    Widget pick(String text, String? value, List<String> options,
        ValueChanged<String?> onChanged,
        {double width = 270.0}) {
      return SizedBox(
        width: width,
        child: DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: text,
            isDense: true,
            border: const OutlineInputBorder(),
          ),
          items: [
            for (final o in options)
              DropdownMenuItem(value: o, child: Text(o)),
          ],
          onChanged: _busy ? null : (v) => setState(() => onChanged(v)),
        ),
      );
    }

    return AlertDialog(
      title: _title(
        'Add a lead',
        'For someone who phoned, sent a message or walked in. '
            'The lead records that you entered it.',
      ),
      content: SizedBox(
        width: 580.0,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    icon: Icon(Icons.edit_note_rounded),
                    label: Text('I\'ll type their details'),
                  ),
                  ButtonSegment(
                    value: true,
                    icon: Icon(Icons.send_rounded),
                    label: Text('Send them the claim form'),
                  ),
                ],
                selected: {_sendForm},
                onSelectionChanged: _busy
                    ? null
                    : (s) => setState(() => _sendForm = s.first),
              ),
              const SizedBox(height: 10.0),
              Text(
                _sendForm
                    ? 'They get a link to the full claim form on our website: '
                        'what happened, their flight, date of birth and address, '
                        'and photos of their ID, boarding pass and ticket. '
                        'What they send fills in this lead.'
                    : 'Fill in what they told you. Anything missing can be '
                        'asked for later with Request information.',
                style: label,
              ),
              const SizedBox(height: 16.0),
              Wrap(
                spacing: 12.0,
                runSpacing: 12.0,
                children: [
                  box('Full name *', _name, width: 552.0),
                  box('Phone', _phone,
                      hint: '0803 123 4567 or +44…',
                      keyboard: TextInputType.phone),
                  box('Email', _email, keyboard: TextInputType.emailAddress),
                  pick('How did they get in touch? *', _reached,
                      leadReachedVia, (v) => _reached = v),
                  pick('Where did they hear about us?', _heard, leadHeardFrom,
                      (v) => _heard = v),
                ],
              ),
              const SizedBox(height: 6.0),
              Text('A phone number or an email is needed to reach them.',
                  style: label),
              if (!_sendForm) ...[
                const SizedBox(height: 18.0),
                Text('Their flight', style: label),
                const SizedBox(height: 8.0),
                Wrap(
                  spacing: 12.0,
                  runSpacing: 12.0,
                  children: [
                    pick('What happened', _problem, leadProblems,
                        (v) => _problem = v),
                    box('Airline', _airline),
                    box('Flight number', _flightNumber, hint: 'e.g. P4 7120'),
                    SizedBox(
                      width: 270.0,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(46.0),
                          alignment: Alignment.centerLeft,
                        ),
                        icon: const Icon(Icons.event_outlined, size: 18.0),
                        label: Text(_flightDate == null
                            ? 'Flight date'
                            : DateFormat('d MMM y').format(_flightDate!)),
                        onPressed: _busy ? null : _pickDate,
                      ),
                    ),
                    box('Flying from', _from, hint: 'e.g. Lagos'),
                    box('Flying to', _to, hint: 'e.g. Abuja'),
                    box('Booking reference', _bookingRef),
                    box('What they told you', _note,
                        width: 552.0, lines: 3, max: 3000),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 16.0),
                box('Note to them (optional)', _message,
                    width: 552.0, lines: 2, max: 1000,
                    hint: 'e.g. Thanks for calling. Here is the form we mentioned.'),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: hasEmail && _sendEmail,
                  onChanged: hasEmail
                      ? (v) => setState(() => _sendEmail = v ?? true)
                      : null,
                  title: Text('Email them the link',
                      style: GoogleFonts.inter(fontSize: 13.0)),
                  subtitle: Text(
                      hasEmail
                          ? 'You can also send it by WhatsApp on the next screen.'
                          : 'No email: send the link by WhatsApp or text on the next screen.',
                      style: label),
                ),
              ],
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _own,
                onChanged: _busy ? null : (v) => setState(() => _own = v ?? true),
                title: Text('Make me the owner',
                    style: GoogleFonts.inter(fontSize: 13.0)),
                subtitle: Text(
                    'Untick to leave it unassigned for the team to take.',
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
          onPressed: _busy ? null : () => Navigator.maybePop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _busy || !_ready ? null : _save,
          child: Text(_busy
              ? 'Saving…'
              : _sendForm
                  ? 'Save and send the form'
                  : 'Save lead'),
        ),
      ],
    );
  }

  Widget _sentView(AddLeadResult done) {
    final theme = FlutterFlowTheme.of(context);
    final label = GoogleFonts.inter(fontSize: 12.0, color: theme.secondaryText);
    final link = done.link;
    final first = _name.text.trim().split(' ').first;
    final whatsApp = link == null
        ? null
        : whatsAppLink(
            done.phone,
            'Hello $first, this is Claims Assist. To start your flight claim, '
            'please fill in this form: $link');
    final String status;
    if (done.error != null) {
      status = 'The lead was saved, but the form was not sent: ${done.error} '
          'Open the lead and use Request information.';
    } else if (done.emailed) {
      status = 'Emailed to ${done.email}. You can also send the link by '
          'WhatsApp or text.';
    } else if (done.email.isNotEmpty && _sendEmail) {
      status = 'The email to ${done.email} did not go. Send the link by '
          'WhatsApp or text instead.';
    } else {
      status = 'No email was sent. Send them the link by WhatsApp or text.';
    }
    return AlertDialog(
      title: _title(done.error == null ? 'Lead saved, form ready' : 'Lead saved',
          _name.text.trim()),
      content: SizedBox(
        width: 480.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(status,
                style: GoogleFonts.inter(
                    fontSize: 13.0,
                    color: done.error != null ||
                            (done.email.isNotEmpty && _sendEmail && !done.emailed)
                        ? theme.error
                        : theme.primaryText)),
            if (link != null) ...[
              const SizedBox(height: 12.0),
              SelectableText(link, style: GoogleFonts.inter(fontSize: 12.0)),
              const SizedBox(height: 8.0),
              Text(
                  'The link works once and lasts 14 days. You are emailed '
                  'when they fill it in.',
                  style: label),
            ],
          ],
        ),
      ),
      actions: [
        if (link != null)
          TextButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 18.0),
            label: const Text('Copy link'),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(widget.host);
              await Clipboard.setData(ClipboardData(text: link));
              messenger.showSnackBar(
                  const SnackBar(content: Text('Link copied')));
            },
          ),
        if (whatsApp != null)
          TextButton.icon(
            icon: const Icon(Icons.chat_outlined, size: 18.0),
            label: const Text('Send by WhatsApp'),
            onPressed: () => launchUrl(whatsApp),
          ),
        TextButton(
          onPressed: () => _openLead(done.id!),
          child: const Text('Open the lead'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
