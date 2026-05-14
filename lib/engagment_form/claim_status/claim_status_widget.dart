import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'claim_status_model.dart';
export 'claim_status_model.dart';

class ClaimStatusWidget extends StatefulWidget {
  const ClaimStatusWidget({
    super.key,
    this.claimRef,
    this.token,
  });

  final DocumentReference? claimRef;
  final String? token;

  static String routeName = 'ClaimStatus';
  static String routePath = '/claimStatus';

  @override
  State<ClaimStatusWidget> createState() => _ClaimStatusWidgetState();
}

class _ClaimStatusWidgetState extends State<ClaimStatusWidget> {
  late ClaimStatusModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ClaimStatusModel());
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  // Maps a claim_status string to a 0-based step index for the timeline.
  int _stepIndex(String status) {
    switch (status) {
      case 'Details Pending':
        return 0;
      case 'Submitted':
        return 1;
      case 'Under Review':
        return 2;
      case 'Awaiting Reply':
      case 'Submit to Solicitor':
        return 3;
      case 'Won':
      case 'Lost':
        return 4;
      default:
        return 0;
    }
  }

  String _statusMessage(String status) {
    switch (status) {
      case 'Details Pending':
        return 'We are waiting for you to submit your flight evidence. Please check your email for the submission link.';
      case 'Submitted':
        return 'We have received your evidence. Our team will begin reviewing your claim shortly.';
      case 'Under Review':
        return 'Our team is actively reviewing your evidence and preparing your formal demand letter.';
      case 'Awaiting Reply':
        return 'A formal demand letter has been sent to the airline. We are awaiting their response — airlines have up to 14 days to reply.';
      case 'Submit to Solicitor':
        return 'Your claim has been escalated to our legal team for further action against the airline.';
      case 'Won':
        return 'Congratulations! Your claim has been approved. Our team will contact you to arrange your compensation payment.';
      case 'Lost':
        return 'The airline has not agreed to settle at this stage. Our team will contact you to discuss escalation options at no upfront cost.';
      default:
        return 'Your claim is being processed. We will send you an email update shortly.';
    }
  }

  String _nextStepsTitle(String status) {
    switch (status) {
      case 'Details Pending':
        return 'Action Required';
      case 'Won':
        return 'Next Steps';
      case 'Lost':
        return 'Your Options';
      default:
        return 'What Happens Next';
    }
  }

  String _nextStepsBody(String status) {
    switch (status) {
      case 'Details Pending':
        return 'Please submit your flight evidence using the link sent to your email. Without evidence we cannot proceed with your claim.';
      case 'Submitted':
      case 'Under Review':
        return 'Our team will review your documents and prepare a formal demand to the airline. This typically takes 1–3 business days. No action is needed from you.';
      case 'Awaiting Reply':
        return 'We are waiting for the airline to respond. We will notify you immediately when we hear back. No action is needed from you right now.';
      case 'Submit to Solicitor':
        return 'A solicitor will review your case. They may contact you for additional information. We will keep you updated throughout the process.';
      case 'Won':
        return 'Claims Assist will contact you within 3–5 business days to arrange payment after our success fee is deducted. Thank you for trusting us.';
      case 'Lost':
        return 'Our team will review the airline\'s response and discuss whether to escalate to the NCAA or pursue legal proceedings — at no upfront cost to you.';
      default:
        return 'Our team is processing your claim. We will send you an email update shortly.';
    }
  }

  IconData _nextStepsIcon(String status) {
    switch (status) {
      case 'Details Pending':
        return Icons.mail_outline_rounded;
      case 'Won':
        return Icons.celebration_rounded;
      case 'Lost':
        return Icons.support_agent_rounded;
      case 'Awaiting Reply':
        return Icons.hourglass_bottom_rounded;
      default:
        return Icons.access_time_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.claimRef == null) {
      return _buildInvalidPage(context);
    }

    return StreamBuilder<ClaimsRecord>(
      stream: ClaimsRecord.getDocument(widget.claimRef!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  FlutterFlowTheme.of(context).primary,
                ),
              ),
            ),
          );
        }

        final claim = snapshot.data!;

        if (widget.token == null ||
            widget.token!.isEmpty ||
            widget.token != claim.secureToken) {
          return _buildInvalidPage(context);
        }

        final status = claim.claimStatus;
        final step = _stepIndex(status);
        final isWon = status == 'Won';
        final isLost = status == 'Lost';

        return Title(
          title: 'Claim Status | Claims Assist',
          color: FlutterFlowTheme.of(context).primary.withAlpha(0xFF),
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Scaffold(
              key: scaffoldKey,
              backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
              body: SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStatusBanner(
                                context, status, isWon, isLost),
                            const SizedBox(height: 20),
                            _buildClaimInfoCard(context, claim),
                            const SizedBox(height: 20),
                            _buildTimeline(
                                context, step, isWon, isLost),
                            const SizedBox(height: 20),
                            _buildNextSteps(context, status),
                            const SizedBox(height: 20),
                            _buildContactSection(context),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Sub-widgets ──────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF002855),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
      child: Row(
        children: [
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'Claims ',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                TextSpan(
                  text: 'Assist',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE6B011),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(
      BuildContext context, String status, bool isWon, bool isLost) {
    Color bg;
    IconData icon;
    if (isWon) {
      bg = FlutterFlowTheme.of(context).success;
      icon = Icons.check_circle_rounded;
    } else if (isLost) {
      bg = FlutterFlowTheme.of(context).error;
      icon = Icons.cancel_rounded;
    } else {
      bg = FlutterFlowTheme.of(context).primary;
      icon = Icons.hourglass_top_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(
                'Current Status',
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            status.isEmpty ? 'Processing' : status,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _statusMessage(status),
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClaimInfoCard(BuildContext context, ClaimsRecord claim) {
    final route = (claim.departure.isNotEmpty && claim.destination.isNotEmpty)
        ? '${claim.departure} → ${claim.destination}'
        : 'N/A';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: FlutterFlowTheme.of(context).alternate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Claim Details',
            style: GoogleFonts.inter(
              color: FlutterFlowTheme.of(context).primaryText,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          _infoRow(context, 'Passenger', claim.fullName),
          _infoRow(context, 'Airline', claim.airlineName),
          _infoRow(context, 'Flight No.', claim.flightNumber),
          _infoRow(context, 'Date', claim.flightDate),
          _infoRow(context, 'Route', route),
          _infoRow(context, 'Delay', claim.durationOfDelay),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: FlutterFlowTheme.of(context).secondaryText,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'N/A' : value,
              style: GoogleFonts.inter(
                color: FlutterFlowTheme.of(context).primaryText,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(
      BuildContext context, int currentStep, bool isWon, bool isLost) {
    final steps = [
      'Claim Registered',
      'Evidence Submitted',
      'Under Review',
      'Airline Contacted',
      isWon ? 'Claim Won 🎉' : isLost ? 'Claim Outcome' : 'Resolution',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progress',
          style: GoogleFonts.inter(
            color: FlutterFlowTheme.of(context).primaryText,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        for (int i = 0; i < steps.length; i++)
          _buildTimelineStep(
            context,
            label: steps[i],
            index: i,
            currentStep: currentStep,
            isLast: i == steps.length - 1,
            isWon: isWon,
            isLost: isLost,
          ),
      ],
    );
  }

  Widget _buildTimelineStep(
    BuildContext context, {
    required String label,
    required int index,
    required int currentStep,
    required bool isLast,
    required bool isWon,
    required bool isLost,
  }) {
    final isComplete = index < currentStep;
    final isCurrent = index == currentStep;

    Color dotColor;
    if (isComplete) {
      dotColor = FlutterFlowTheme.of(context).success;
    } else if (isCurrent && isWon) {
      dotColor = FlutterFlowTheme.of(context).success;
    } else if (isCurrent && isLost) {
      dotColor = FlutterFlowTheme.of(context).error;
    } else if (isCurrent) {
      dotColor = FlutterFlowTheme.of(context).primary;
    } else {
      dotColor = FlutterFlowTheme.of(context).alternate;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration:
                  BoxDecoration(color: dotColor, shape: BoxShape.circle),
              child: Center(
                child: isComplete
                    ? const Icon(Icons.check, color: Colors.white, size: 13)
                    : isCurrent
                        ? const Icon(Icons.circle, color: Colors.white,
                            size: 8)
                        : null,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 34,
                color: isComplete
                    ? FlutterFlowTheme.of(context).success
                    : FlutterFlowTheme.of(context).alternate,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Padding(
          padding: EdgeInsets.only(top: 3, bottom: isLast ? 0 : 34),
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: (isComplete || isCurrent)
                  ? FlutterFlowTheme.of(context).primaryText
                  : FlutterFlowTheme.of(context).secondaryText,
              fontSize: 14,
              fontWeight:
                  isCurrent ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNextSteps(BuildContext context, String status) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: FlutterFlowTheme.of(context).primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_nextStepsIcon(status),
              color: FlutterFlowTheme.of(context).primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nextStepsTitle(status),
                  style: GoogleFonts.inter(
                    color: FlutterFlowTheme.of(context).primaryText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _nextStepsBody(status),
                  style: GoogleFonts.inter(
                    color: FlutterFlowTheme.of(context).secondaryText,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Text(
            'Have questions about your claim?',
            style: GoogleFonts.inter(
              color: FlutterFlowTheme.of(context).secondaryText,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            'info@claimshub.online',
            style: GoogleFonts.inter(
              color: FlutterFlowTheme.of(context).primary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvalidPage(BuildContext context) {
    return Scaffold(
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.link_off_rounded,
                        size: 60,
                        color: FlutterFlowTheme.of(context).secondaryText,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Invalid or expired link',
                        style: GoogleFonts.inter(
                          color: FlutterFlowTheme.of(context).primaryText,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This claim status link is not valid. Please check your email for the correct link or contact us.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: FlutterFlowTheme.of(context).secondaryText,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SelectableText(
                        'info@claimshub.online',
                        style: GoogleFonts.inter(
                          color: FlutterFlowTheme.of(context).primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
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
    );
  }
}
