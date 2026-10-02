import '/backend/backend.dart';
import '/backend/services/compensation_calculator.dart';
import '/backend/services/demand.dart';
import '/backend/services/pipeline.dart';
import '/components/brand_colors.dart';
import '/components/casework_panel_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Opens the claim's details for editing. Takes the router, not a context,
/// so it can be called after the dialog that asked for it has closed.
void editClaimWith(GoRouter router, DocumentReference claimRef) {
  router.pushNamed(
    EditEvidenceFormWidget.routeName,
    queryParameters: {
      'claimRef': serializeParam(claimRef, ParamType.DocumentReference),
    }.withoutNulls,
  );
}

/// Shows what the demand letter for [claim] will say and where it will go,
/// and sends it when staff confirm. Returns true if it was sent.
Future<bool> showSendDemand(BuildContext context, ClaimsRecord claim) async {
  final sent = await showDialog<bool>(
    context: context,
    builder: (_) => _SendDemandDialog(claim: claim),
  );
  return sent == true;
}

class _SendDemandDialog extends StatefulWidget {
  const _SendDemandDialog({required this.claim});

  final ClaimsRecord claim;

  @override
  State<_SendDemandDialog> createState() => _SendDemandDialogState();
}

class _SendDemandDialogState extends State<_SendDemandDialog> {
  late final _address =
      TextEditingController(text: widget.claim.airlineEmailSelection);
  List<({String name, String email})> _directory = const [];
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDirectory();
  }

  Future<void> _loadDirectory() async {
    final airlines = await queryAirlinesDirectoryRecordOnce();
    if (!mounted) return;
    setState(() {
      _directory = [
        for (final a in airlines)
          if (isEmailAddress(a.legalEmail))
            (name: a.airlineName, email: a.legalEmail.trim()),
      ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      if (_address.text.trim().isEmpty) {
        _address.text =
            suggestedAirlineEmail(widget.claim.airlineName, _directory);
      }
    });
  }

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _address.text.trim();
    if (!isEmailAddress(email)) {
      setState(() => _error = 'Give one email address for the airline.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    final result = await sendDemandLetter(
        claimId: widget.claim.reference.id, email: email);
    if (!mounted) return;
    if (!result.succeeded) {
      setState(() {
        _sending = false;
        _error = result.error;
      });
      return;
    }
    showCaseActionResult(
        context, result, 'Demand letter on its way to $email.');
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final claim = widget.claim;
    final readiness = demandReadiness(claim.snapshotData);
    final resend = canonicalStage(RecordKind.claim, claim.claimStatus) ==
        ClaimStage.awaitingReply;
    final held = claim.inCancellationPeriod;
    final canSend = readiness.ready && !held && !_sending;

    Widget fact(String label, String value) => Padding(
          padding: const EdgeInsets.only(bottom: 6.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 110.0,
                child: Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 12.5, color: theme.secondaryText)),
              ),
              Expanded(
                child: Text(
                  value.trim().isEmpty ? '—' : value,
                  style: GoogleFonts.inter(
                    fontSize: 13.0,
                    fontWeight: FontWeight.w600,
                    color: value.trim().isEmpty
                        ? overdueRed(context)
                        : theme.primaryText,
                  ),
                ),
              ),
            ],
          ),
        );

    Widget notice(IconData icon, Color color, List<String> lines) => Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 12.0),
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(color: color.withValues(alpha: 0.45)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 17.0, color: color),
              const SizedBox(width: 10.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final line in lines)
                      Text(line,
                          style: GoogleFonts.inter(
                              fontSize: 12.5,
                              height: 1.45,
                              color: theme.primaryText)),
                  ],
                ),
              ),
            ],
          ),
        );

    return AlertDialog(
      title:
          Text(resend ? 'Resend the demand letter' : 'Send the demand letter'),
      content: SizedBox(
        width: 520.0,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              fact('Passenger', claim.fullName),
              fact('Airline', claim.airlineName),
              fact('Flight', claim.flightNumber),
              fact('Date', claim.flightDate),
              fact(
                  'Route',
                  claim.departure.isEmpty || claim.destination.isEmpty
                      ? ''
                      : '${claim.departure} → ${claim.destination}'),
              fact('Amount', displayClaimAmount(claim.claimsAmount, empty: '')),
              if (readiness.blockers.isNotEmpty)
                notice(Icons.error_outline, overdueRed(context), [
                  'The letter cannot go yet:',
                  for (final b in readiness.blockers) '•  $b',
                ]),
              if (held)
                notice(Icons.schedule, overdueRed(context), [
                  'This client can still cancel until '
                      '${dateTimeFormat('d MMM y', claim.workMayStartAt)} and did '
                      'not ask us to start before then. Nothing can go to the '
                      'airline until that date.',
                ]),
              if (readiness.warnings.isNotEmpty)
                notice(Icons.info_outline, theme.secondaryText, [
                  for (final w in readiness.warnings) w,
                ]),
              const SizedBox(height: 16.0),
              TextField(
                controller: _address,
                enabled: !_sending,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Send to (the airline\'s email address)',
                  errorText: _error,
                  errorMaxLines: 4,
                  border: const OutlineInputBorder(),
                  suffixIcon: _directory.isEmpty
                      ? null
                      : PopupMenuButton<String>(
                          tooltip: 'Choose from the airline directory',
                          icon: const Icon(Icons.arrow_drop_down),
                          onSelected: (email) =>
                              setState(() => _address.text = email),
                          itemBuilder: (_) => [
                            for (final a in _directory)
                              PopupMenuItem(
                                value: a.email,
                                child: Text('${a.name}  ·  ${a.email}',
                                    style: GoogleFonts.inter(fontSize: 13.0)),
                              ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 10.0),
              Text(
                'The letter goes from info@claimshub.online with the letter of '
                'authority attached, and gives the airline 14 days. Sending it '
                'moves the claim to Awaiting Reply.',
                style: GoogleFonts.inter(
                    fontSize: 12.0, height: 1.45, color: theme.secondaryText),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (!readiness.ready)
          TextButton(
            onPressed: () {
              final router = GoRouter.of(context);
              Navigator.pop(context, false);
              editClaimWith(router, claim.reference);
            },
            child: const Text('Edit the claim'),
          ),
        TextButton(
          onPressed: _sending ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: canSend ? _send : null,
          child: Text(_sending ? 'Sending…' : (resend ? 'Resend' : 'Send')),
        ),
      ],
    );
  }
}
