import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/menus_file/claims_menu/claims_menu_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'solicitors_model.dart';
export 'solicitors_model.dart';

class SolicitorsWidget extends StatefulWidget {
  const SolicitorsWidget({super.key});

  static String routeName = 'Solicitors';
  static String routePath = '/solicitors';

  @override
  State<SolicitorsWidget> createState() => _SolicitorsWidgetState();
}

class _SolicitorsWidgetState extends State<SolicitorsWidget> {
  late SolicitorsModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SolicitorsModel());
    _model.searchController ??= TextEditingController();
    _model.searchFocusNode ??= FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty && parts[0].isNotEmpty) return parts[0][0].toUpperCase();
    return '?';
  }

  int _daysSince(DateTime? dt) {
    if (dt == null) return 0;
    return DateTime.now().difference(dt).inDays;
  }

  Future<void> _sendLegalLetter(ClaimsRecord claim) async {
    if (claim.airlineEmailSelection.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'No airline email set for this claim. Use the Email Airlines page to select the target email first.'),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Send Legal Letter'),
        content: Text(
          'Send a Final Legal Notice to ${claim.airlineName.isNotEmpty ? claim.airlineName : "the airline"} '
          'at ${claim.airlineEmailSelection} '
          'on behalf of ${claim.fullName}?\n\nThis will set a 7-day deadline before court proceedings commence.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF002855)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Send', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await claim.reference.update({
        'trigger_solicitor_email': true,
        'solicitor_email_status': 'Sent',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Legal letter queued - it will be sent within seconds.'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _updateOutcome(ClaimsRecord claim, String status) async {
    final label = status == 'Won' ? 'Won' : 'Lost';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Mark as $label'),
        content: Text('Mark ${claim.fullName}\'s claim as "$label"? This will notify the client.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: status == 'Won' ? Colors.green.shade700 : Colors.red.shade700,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(label, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await claim.reference.update({
        'claim_status': status,
        'is_escalated': false,
        'settlement_date': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Claim marked as $label.'),
            backgroundColor: status == 'Won' ? Colors.green.shade700 : Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red.shade700),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return Title(
      title: 'Solicitors Workspace',
      color: FlutterFlowTheme.of(context).primary.withAlpha(0XFF),
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Scaffold(
          key: scaffoldKey,
          backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
          body: SafeArea(
            top: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                wrapWithModel(
                  model: _model.claimsMenuModel,
                  updateCallback: () => safeSetState(() {}),
                  child: ClaimsMenuWidget(selectedPage: 5),
                ),
                Expanded(
                  child: StreamBuilder<List<ClaimsRecord>>(
                    stream: queryClaimsRecord(
                      queryBuilder: (q) =>
                          q.where('is_escalated', isEqualTo: true),
                    ),
                    builder: (context, snapshot) {
                      final claims = snapshot.data ?? [];
                      final search = _model.searchController?.text.toLowerCase() ?? '';
                      final filtered = search.isEmpty
                          ? claims
                          : claims.where((c) {
                              return c.fullName.toLowerCase().contains(search) ||
                                  c.airlineName.toLowerCase().contains(search) ||
                                  c.pnrNumber.toLowerCase().contains(search) ||
                                  c.flightNumber.toLowerCase().contains(search);
                            }).toList();

                      final letterSent = claims
                          .where((c) =>
                              (c.snapshotData['solicitor_email_status'] as String? ?? '') ==
                              'Sent')
                          .length;
                      final pending = claims.length - letterSent;

                      return Column(
                        children: [
                          // 鈹€鈹€ Top bar 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
                          Container(
                            color: FlutterFlowTheme.of(context).secondaryBackground,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 16),
                            child: Row(
                              children: [
                                const FaIcon(
                                  FontAwesomeIcons.paperPlane,
                                  color: Color(0xFF002855),
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Solicitors Workspace',
                                  style: FlutterFlowTheme.of(context)
                                      .headlineSmall
                                      .override(
                                        font: GoogleFonts.inter(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        color: const Color(0xFF002855),
                                        letterSpacing: 0,
                                      ),
                                ),
                                const Spacer(),
                                // Search
                                SizedBox(
                                  width: 260,
                                  height: 40,
                                  child: TextField(
                                    controller: _model.searchController,
                                    focusNode: _model.searchFocusNode,
                                    onChanged: (_) => safeSetState(() {}),
                                    decoration: InputDecoration(
                                      hintText: 'Search client, airline, PNR...',
                                      hintStyle: const TextStyle(
                                          fontSize: 13, color: Colors.grey),
                                      prefixIcon: const Icon(Icons.search,
                                          size: 18, color: Colors.grey),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                            color: Colors.grey.shade300),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                            color: Colors.grey.shade300),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // 鈹€鈹€ Stats row 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                            child: Row(
                              children: [
                                _StatCard(
                                  label: 'Total Escalated',
                                  value: claims.length,
                                  color: const Color(0xFF002855),
                                  icon: FontAwesomeIcons.fileAlt,
                                ),
                                const SizedBox(width: 16),
                                _StatCard(
                                  label: 'Letter Sent',
                                  value: letterSent,
                                  color: Colors.orange.shade700,
                                  icon: FontAwesomeIcons.paperPlane,
                                ),
                                const SizedBox(width: 16),
                                _StatCard(
                                  label: 'Awaiting Response',
                                  value: pending,
                                  color: Colors.red.shade600,
                                  icon: FontAwesomeIcons.clock,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // 鈹€鈹€ Claims list 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
                          Expanded(
                            child: snapshot.connectionState ==
                                    ConnectionState.waiting
                                ? const Center(
                                    child: CircularProgressIndicator(
                                        color: Color(0xFF002855)))
                                : filtered.isEmpty
                                    ? _EmptyState(
                                        hasSearch: search.isNotEmpty)
                                    : ListView.separated(
                                        padding: const EdgeInsets.fromLTRB(
                                            24, 0, 24, 24),
                                        itemCount: filtered.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(height: 12),
                                        itemBuilder: (context, i) =>
                                            _ClaimCard(
                                          claim: filtered[i],
                                          initials: _initials(
                                              filtered[i].fullName),
                                          daysSince: _daysSince(
                                              filtered[i].createdAt),
                                          onSendLetter: () =>
                                              _sendLegalLetter(filtered[i]),
                                          onMarkWon: () => _updateOutcome(
                                              filtered[i], 'Won'),
                                          onMarkLost: () => _updateOutcome(
                                              filtered[i], 'Lost'),
                                        ),
                                      ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 鈹€鈹€ Stat card 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final int value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: FaIcon(icon, size: 18, color: color),
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// 鈹€鈹€ Claim card 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€

class _ClaimCard extends StatelessWidget {
  const _ClaimCard({
    required this.claim,
    required this.initials,
    required this.daysSince,
    required this.onSendLetter,
    required this.onMarkWon,
    required this.onMarkLost,
  });

  final ClaimsRecord claim;
  final String initials;
  final int daysSince;
  final VoidCallback onSendLetter;
  final VoidCallback onMarkWon;
  final VoidCallback onMarkLost;

  @override
  Widget build(BuildContext context) {
    final solicitorStatus =
        claim.snapshotData['solicitor_email_status'] as String? ?? '';
    final letterSent = solicitorStatus == 'Sent';
    final loaUrl = claim.loaUrl;
    final demandUrl = claim.snapshotData['demand_letter_url'] as String? ?? '';
    final solicitorUrl =
        claim.snapshotData['solicitor_letter_url'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 鈹€鈹€ Top row 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFF002855).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF002855),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Client info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      claim.fullName.isNotEmpty ? claim.fullName : 'Unknown',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: FlutterFlowTheme.of(context).primaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      claim.clientEmail,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _InfoChip(
                          label:
                              'PNR: ${claim.pnrNumber.isNotEmpty ? claim.pnrNumber : "N/A"}',
                          color: Colors.grey.shade100,
                        ),
                        const SizedBox(width: 6),
                        _InfoChip(
                          label: claim.airlineName.isNotEmpty
                              ? claim.airlineName
                              : 'Airline N/A',
                          color: const Color(0xFF002855).withOpacity(0.08),
                          textColor: const Color(0xFF002855),
                        ),
                        const SizedBox(width: 6),
                        _InfoChip(
                          label: claim.leadRef != null
                              ? 'CA-${claim.leadRef!.id.substring(0, 8).toUpperCase()}'
                              : 'Ref N/A',
                          color: const Color(0xFFE6B011).withOpacity(0.15),
                          textColor: const Color(0xFF7A5800),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Right: days badge + letter status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: daysSince > 14
                          ? Colors.red.shade50
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: daysSince > 14
                            ? Colors.red.shade200
                            : Colors.orange.shade200,
                      ),
                    ),
                    child: Text(
                      '${daysSince}d escalated',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: daysSince > 14
                            ? Colors.red.shade700
                            : Colors.orange.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: letterSent
                          ? Colors.green.shade50
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          letterSent ? Icons.mark_email_read : Icons.mail_outline,
                          size: 13,
                          color: letterSent
                              ? Colors.green.shade700
                              : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          letterSent ? 'Letter Sent' : 'Not Sent',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: letterSent
                                ? Colors.green.shade700
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),
          Divider(color: Colors.grey.shade200, height: 1),
          const SizedBox(height: 14),

          // 鈹€鈹€ Flight details row 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
          Wrap(
            spacing: 20,
            runSpacing: 8,
            children: [
              _DetailItem(
                icon: Icons.flight,
                label: 'Flight',
                value: claim.flightNumber.isNotEmpty
                    ? claim.flightNumber
                    : 'N/A',
              ),
              _DetailItem(
                icon: Icons.route,
                label: 'Route',
                value:
                    '${claim.departure.isNotEmpty ? claim.departure : "?"} 鈫?${claim.destination.isNotEmpty ? claim.destination : "?"}',
              ),
              _DetailItem(
                icon: Icons.calendar_today,
                label: 'Date',
                value:
                    claim.flightDate.isNotEmpty ? claim.flightDate : 'N/A',
              ),
              _DetailItem(
                icon: Icons.timer,
                label: 'Delay',
                value: claim.durationOfDelay.isNotEmpty
                    ? claim.durationOfDelay
                    : 'N/A',
              ),
              _DetailItem(
                icon: Icons.attach_money,
                label: 'Amount',
                value: claim.claimsAmount.isNotEmpty
                    ? '鈧?{claim.claimsAmount}'
                    : 'N/A',
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 鈹€鈹€ Document links 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
          // Airline email target — set by the Email Airlines page
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: claim.airlineEmailSelection.isNotEmpty
                  ? const Color(0xFF7C3AED).withOpacity(0.07)
                  : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: claim.airlineEmailSelection.isNotEmpty
                    ? const Color(0xFF7C3AED).withOpacity(0.25)
                    : Colors.orange.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  claim.airlineEmailSelection.isNotEmpty
                      ? Icons.email_outlined
                      : Icons.warning_amber_outlined,
                  size: 14,
                  color: claim.airlineEmailSelection.isNotEmpty
                      ? const Color(0xFF7C3AED)
                      : Colors.orange.shade700,
                ),
                const SizedBox(width: 6),
                Text(
                  claim.airlineEmailSelection.isNotEmpty
                      ? 'Airline email target: '
                      : 'No airline email set — ',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: claim.airlineEmailSelection.isNotEmpty
                        ? Colors.grey.shade600
                        : Colors.orange.shade700,
                  ),
                ),
                Flexible(
                  child: Text(
                    claim.airlineEmailSelection.isNotEmpty
                        ? claim.airlineEmailSelection
                        : 'visit Email Airlines page first',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: claim.airlineEmailSelection.isNotEmpty
                          ? const Color(0xFF7C3AED)
                          : Colors.orange.shade700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          if (loaUrl.isNotEmpty || demandUrl.isNotEmpty || solicitorUrl.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (loaUrl.isNotEmpty)
                  _DocLink(label: 'LOA', url: loaUrl),
                if (demandUrl.isNotEmpty)
                  _DocLink(label: '1st Demand', url: demandUrl),
                if (solicitorUrl.isNotEmpty)
                  _DocLink(label: 'Legal Notice', url: solicitorUrl),
              ],
            ),

          if (loaUrl.isNotEmpty || demandUrl.isNotEmpty || solicitorUrl.isNotEmpty)
            const SizedBox(height: 14),

          // 鈹€鈹€ Action buttons 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
          Row(
            children: [
              // Send / Resend legal letter
              ElevatedButton.icon(
                onPressed: claim.airlineEmailSelection.isNotEmpty ? onSendLetter : null,
                icon: FaIcon(
                  FontAwesomeIcons.paperPlane,
                  size: 13,
                  color: Colors.white,
                ),
                label: Text(
                  letterSent ? 'Resend Legal Letter' : 'Send Legal Letter',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF002855),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
              const SizedBox(width: 10),

              // Mark Won
              OutlinedButton.icon(
                onPressed: onMarkWon,
                icon: const Icon(Icons.check_circle_outline,
                    size: 15, color: Colors.green),
                label: const Text('Mark Won',
                    style: TextStyle(
                        color: Colors.green,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  side: BorderSide(color: Colors.green.shade400),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 10),

              // Mark Lost
              OutlinedButton.icon(
                onPressed: onMarkLost,
                icon: const Icon(Icons.cancel_outlined,
                    size: 15, color: Colors.red),
                label: const Text('Mark Lost',
                    style: TextStyle(
                        color: Colors.red,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  side: BorderSide(color: Colors.red.shade400),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 鈹€鈹€ Small helpers 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€

class _InfoChip extends StatelessWidget {
  const _InfoChip(
      {required this.label, required this.color, this.textColor});

  final String label;
  final Color color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          color: textColor ?? Colors.grey.shade700,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem(
      {required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: GoogleFonts.inter(
              fontSize: 12, color: Colors.grey.shade500),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800),
        ),
      ],
    );
  }
}

class _DocLink extends StatelessWidget {
  const _DocLink({required this.label, required this.url});

  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => launchURL(url),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF002855).withOpacity(0.07),
          borderRadius: BorderRadius.circular(6),
          border:
              Border.all(color: const Color(0xFF002855).withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.picture_as_pdf,
                size: 13, color: Color(0xFF002855)),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF002855),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasSearch});

  final bool hasSearch;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(FontAwesomeIcons.paperPlane,
              size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            hasSearch
                ? 'No claims match your search.'
                : 'No claims escalated to solicitors yet.',
            style: GoogleFonts.inter(
                fontSize: 15, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

