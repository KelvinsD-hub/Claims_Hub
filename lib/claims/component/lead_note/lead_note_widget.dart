import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'lead_note_model.dart';
export 'lead_note_model.dart';

/// Create a component that read a simple note queried from document
class LeadNoteWidget extends StatefulWidget {
  const LeadNoteWidget({
    super.key,
    required this.leadRef,
  });

  final LeadsRecord? leadRef;

  @override
  State<LeadNoteWidget> createState() => _LeadNoteWidgetState();
}

class _LeadNoteWidgetState extends State<LeadNoteWidget> {
  late LeadNoteModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LeadNoteModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  /// What the website checker recorded about this lead: who acts on it, and
  /// the facts a Part 19 claim is valued from.
  Widget _websiteDetails(BuildContext context, LeadsRecord lead) {
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

    String money(double value) {
      final symbol = lead.fareCurrency.isEmpty || lead.fareCurrency == 'NGN'
          ? '₦'
          : '${lead.fareCurrency} ';
      return '$symbol${NumberFormat('#,##0.##').format(value)}';
    }

    final rows = <(String, String)>[
      if (lead.regime.isNotEmpty) ('Rules', lead.regime),
      if (lead.estimateValue.isNotEmpty) ('Estimate', lead.estimateValue),
      if (lead.farePaid != null) ('Ticket price', money(lead.farePaid!)),
      if (lead.delayHours != null)
        ('Delay', '${NumberFormat('0.##').format(lead.delayHours)} hours'),
      if (lead.passengerCount > 1)
        ('Passengers', '${lead.passengerCount} on this booking'),
      if (lead.bookingReference.isNotEmpty)
        ('Booking ref', lead.bookingReference),
      (
        'Authority',
        lead.loaSigned ? 'Signed on the website' : 'Not signed yet'
      ),
      if (lead.loaSigned && lead.workMayStartAt != null)
        (
          'Work may start',
          lead.workMayStartAt!.isAfter(DateTime.now())
              ? '${dateTimeFormat("d MMM y", lead.workMayStartAt)} — '
                  'cancellation period still running'
              : 'Now'
        ),
      if (lead.bankDetailsPending) ('Bank details', 'Still to be collected'),
    ];

    final bodySmall = theme.bodySmall.override(
      font: GoogleFonts.inter(),
      letterSpacing: 0.0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: color),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: bodySmall.override(
                  font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  color: theme.primaryText,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (lead.handlerReason.isNotEmpty)
                Text(
                  lead.handlerReason,
                  style: bodySmall.override(
                    font: GoogleFonts.inter(),
                    color: theme.secondaryText,
                    letterSpacing: 0.0,
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: 10.0),
        for (final (name, value) in rows)
          Padding(
            padding: EdgeInsets.only(bottom: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 104.0,
                  child: Text(
                    name,
                    style: bodySmall.override(
                      font: GoogleFonts.inter(),
                      color: theme.secondaryText,
                      letterSpacing: 0.0,
                    ),
                  ),
                ),
                Expanded(child: Text(value, style: bodySmall)),
              ],
            ),
          ),
        if (lead.disruptionDetails.isNotEmpty) ...[
          SizedBox(height: 6.0),
          Text(
            'In their words',
            style: bodySmall.override(
              font: GoogleFonts.inter(),
              color: theme.secondaryText,
              letterSpacing: 0.0,
            ),
          ),
          Text(lead.disruptionDetails, style: bodySmall),
        ],
        Divider(thickness: 1.0, color: theme.alternate),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 370.0,
              // Website leads carry enough detail to outgrow a short screen.
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.85,
              ),
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).secondaryBackground,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 8.0,
                    color: Color(0x1A000000),
                    offset: Offset(
                      0.0,
                      2.0,
                    ),
                    spreadRadius: 0.0,
                  )
                ],
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(20.0, 20.0, 20.0, 20.0),
                child: SingleChildScrollView(
                    child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Icon(
                              Icons.sticky_note_2,
                              color: FlutterFlowTheme.of(context).primary,
                              size: 20.0,
                            ),
                            Text(
                              'Note',
                              style: FlutterFlowTheme.of(context)
                                  .labelMedium
                                  .override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context).primary,
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .fontStyle,
                                  ),
                            ),
                          ].divide(SizedBox(width: 8.0)),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              color: FlutterFlowTheme.of(context).secondaryText,
                              size: 16.0,
                            ),
                            Text(
                              dateTimeFormat(
                                  "d/M/y", widget!.leadRef!.createdAt!),
                              style: FlutterFlowTheme.of(context)
                                  .labelSmall
                                  .override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelSmall
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelSmall
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .labelSmall
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .labelSmall
                                        .fontStyle,
                                  ),
                            ),
                          ].divide(SizedBox(width: 8.0)),
                        ),
                      ],
                    ),
                    Text(
                      'Claim Note',
                      style: FlutterFlowTheme.of(context).titleMedium.override(
                            font: GoogleFonts.interTight(
                              fontWeight: FlutterFlowTheme.of(context)
                                  .titleMedium
                                  .fontWeight,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .titleMedium
                                  .fontStyle,
                            ),
                            letterSpacing: 0.0,
                            fontWeight: FlutterFlowTheme.of(context)
                                .titleMedium
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .titleMedium
                                .fontStyle,
                          ),
                    ),
                    if (widget!.leadRef?.hasHandler() ?? false)
                      _websiteDetails(context, widget!.leadRef!),
                    Text(
                      valueOrDefault<String>(
                        widget!.leadRef?.initialSummary,
                        'lead Note',
                      ),
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            font: GoogleFonts.inter(
                              fontWeight: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontWeight,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontStyle,
                            ),
                            color: FlutterFlowTheme.of(context).secondaryText,
                            letterSpacing: 0.0,
                            fontWeight: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                          ),
                    ),
                    Divider(
                      thickness: 1.0,
                      color: FlutterFlowTheme.of(context).alternate,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Icon(
                              Icons.bookmark_border_rounded,
                              color: FlutterFlowTheme.of(context).secondaryText,
                              size: 22.0,
                            ),
                            InkWell(
                              splashColor: Colors.transparent,
                              focusColor: Colors.transparent,
                              hoverColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              onTap: () async {
                                Navigator.pop(context);
                              },
                              child: Icon(
                                Icons.close,
                                color:
                                    FlutterFlowTheme.of(context).secondaryText,
                                size: 22.0,
                              ),
                            ),
                          ].divide(SizedBox(width: 16.0)),
                        ),
                      ],
                    ),
                  ].divide(SizedBox(height: 12.0)),
                )),
              ),
            ),
          ].divide(SizedBox(height: 12.0)),
        ),
      ),
    );
  }
}
