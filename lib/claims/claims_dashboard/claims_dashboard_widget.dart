import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/menus_file/claims_menu/claims_menu_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'claims_dashboard_model.dart';
export 'claims_dashboard_model.dart';

const _kNavy = Color(0xFF002855);
const _kGold = Color(0xFFE6B011);

// Status badge colours
Color _statusColor(String? s) {
  switch (s) {
    case 'Won':
    case 'Claim Won':
      return const Color(0xFF15AA47);
    case 'Lost':
    case 'Claim Lost':
      return const Color(0xFFE53935);
    case 'Under Review':
    case 'Ready For Review':
      return const Color(0xFF0C519B);
    case 'Submit to Solicitor':
      return const Color(0xFF7C3AED);
    default:
      return const Color(0xFFF08156);
  }
}

class ClaimsDashboardWidget extends StatefulWidget {
  const ClaimsDashboardWidget({super.key});

  static String routeName = 'ClaimsDashboard';
  static String routePath = '/claimsDashboard';

  @override
  State<ClaimsDashboardWidget> createState() => _ClaimsDashboardWidgetState();
}

class _ClaimsDashboardWidgetState extends State<ClaimsDashboardWidget>
    with TickerProviderStateMixin {
  late ClaimsDashboardModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final animationsMap = <String, AnimationInfo>{};

  String _searchQuery = '';
  String? _statusFilter;
  final _searchController = TextEditingController();

  static const _statusOptions = [
    'All Statuses',
    'Details Pending',
    'Under Review',
    'Ready For Review',
    'Awaiting Reply',
    'Email Sent',
    'Submit to Solicitor',
    'Won',
    'Claim Won',
    'Lost',
    'Claim Lost',
  ];

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ClaimsDashboardModel());

    animationsMap.addAll({
      'rowOnPageLoadAnimation1': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 50.0.ms,
            begin: const Offset(0.0, 50.0),
            end: Offset.zero,
          ),
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 50.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
        ],
      ),
      'containerOnActionTriggerAnimation': AnimationInfo(
        trigger: AnimationTrigger.onActionTrigger,
        applyInitialState: true,
        effectsBuilder: () => [
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 300.0.ms,
            begin: const Offset(-40.0, 0.0),
            end: Offset.zero,
          ),
        ],
      ),
      'tableAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
              curve: Curves.easeOut, delay: 80.0.ms, duration: 250.0.ms,
              begin: 0.0, end: 1.0),
          MoveEffect(
              curve: Curves.easeOut, delay: 80.0.ms, duration: 250.0.ms,
              begin: const Offset(0, 24), end: Offset.zero),
        ],
      ),
    });

    setupAnimations(
      animationsMap.values.where((a) =>
          a.trigger == AnimationTrigger.onActionTrigger || !a.applyInitialState),
      this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Title(
      title: 'Claims Dashboard',
      color: FlutterFlowTheme.of(context).primary.withAlpha(0xFF),
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
                // Sidebar
                wrapWithModel(
                  model: _model.claimsMenuModel,
                  updateCallback: () => safeSetState(() {}),
                  child: const ClaimsMenuWidget(selectedPage: 1),
                ),

                // Main content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(context),
                      Expanded(
                        child: _buildTable(context).animateOnPageLoad(
                            animationsMap['tableAnimation']!),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        border: Border(
          bottom: BorderSide(
              color: FlutterFlowTheme.of(context).alternate, width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Title
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C519B),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: FaIcon(FontAwesomeIcons.listCheck,
                        color: _kGold, size: 22.0),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Claims Dashboard',
                        style: GoogleFonts.interTight(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: _kNavy)),
                    Text('Manage and track all claims',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: FlutterFlowTheme.of(context).secondaryText)),
                  ],
                ),
              ],
            ).animateOnPageLoad(animationsMap['rowOnPageLoadAnimation1']!),

            // Controls: search + status filter + theme toggle
            Row(
              children: [
                // Search box
                SizedBox(
                  width: 260,
                  height: 44,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) =>
                        setState(() => _searchQuery = v.trim().toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Search by name, airline, PNR…',
                      hintStyle: GoogleFonts.inter(
                          fontSize: 13,
                          color:
                              FlutterFlowTheme.of(context).secondaryText),
                      prefixIcon: Icon(Icons.search,
                          size: 20,
                          color: FlutterFlowTheme.of(context).secondaryText),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              })
                          : null,
                      filled: true,
                      fillColor:
                          FlutterFlowTheme.of(context).primaryBackground,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none),
                    ),
                    style: GoogleFonts.inter(fontSize: 13),
                  ),
                ),
                const SizedBox(width: 12),
                // Status filter dropdown
                Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).primaryBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _statusFilter,
                      hint: Text('All Statuses',
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              color: FlutterFlowTheme.of(context)
                                  .secondaryText)),
                      items: _statusOptions.map((s) {
                        final val = s == 'All Statuses' ? null : s;
                        return DropdownMenuItem<String?>(
                            value: val,
                            child: Text(s,
                                style: GoogleFonts.inter(fontSize: 13)));
                      }).toList(),
                      onChanged: (v) => setState(() => _statusFilter = v),
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          color: FlutterFlowTheme.of(context).primaryText),
                      icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Theme toggle
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () async {
                    final isLight =
                        Theme.of(context).brightness == Brightness.light;
                    setDarkModeSetting(
                        context, isLight ? ThemeMode.dark : ThemeMode.light);
                    final anim = animationsMap[
                        'containerOnActionTriggerAnimation'];
                    if (anim != null) {
                      isLight
                          ? anim.controller.forward(from: 0.0)
                          : anim.controller.reverse();
                    }
                  },
                  child: Container(
                    width: 76,
                    height: 40,
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).alternate,
                      boxShadow: const [
                        BoxShadow(
                            blurRadius: 3, color: Color(0x33000000))
                      ],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Align(
                            alignment:
                                const AlignmentDirectional(-0.9, 0),
                            child: Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Icon(Icons.wb_sunny_outlined,
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryText,
                                  size: 22),
                            ),
                          ),
                          Align(
                            alignment:
                                const AlignmentDirectional(1.0, 0),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: FaIcon(FontAwesomeIcons.moon,
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryText,
                                  size: 18),
                            ),
                          ),
                          Align(
                            alignment:
                                const AlignmentDirectional(1.0, 0),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context)
                                    .secondaryBackground,
                                boxShadow: const [
                                  BoxShadow(
                                      blurRadius: 4,
                                      color: Color(0x430B0D0F),
                                      offset: Offset(0, 2))
                                ],
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ).animateOnActionTrigger(
                              animationsMap[
                                  'containerOnActionTriggerAnimation']!,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // User badge
                AuthUserStreamWidget(
                  builder: (context) => Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context).accent2,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color:
                                  FlutterFlowTheme.of(context).secondary,
                              width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                              getCORSProxyUrl(currentUserPhoto),
                              fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(currentUserDisplayName,
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                          Text(
                              '@${valueOrDefault(currentUserDocument?.role, '')}',
                              style: FlutterFlowTheme.of(context)
                                  .bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Table ────────────────────────────────────────────────────────────────────

  Widget _buildTable(BuildContext context) {
    return StreamBuilder<List<ClaimsRecord>>(
      stream: queryClaimsRecord(
        queryBuilder: (q) => q.orderBy('createdAt', descending: true),
      ),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Center(
              child: CircularProgressIndicator(color: _kNavy));
        }

        var claims = snap.data ?? [];

        // Apply status filter
        if (_statusFilter != null) {
          claims = claims
              .where((c) => c.claimStatus == _statusFilter)
              .toList();
        }

        if (claims.isEmpty) {
          return _emptyState();
        }

        return Column(
          children: [
            _tableHeader(context),
            Expanded(
              child: ListView.builder(
                itemCount: claims.length,
                itemBuilder: (context, i) =>
                    _ClaimsTableRow(
                  claim: claims[i],
                  searchQuery: _searchQuery,
                  isEven: i.isEven,
                ),
              ),
            ),
            _tableFooter(context, claims.length),
          ],
        );
      },
    );
  }

  Widget _tableHeader(BuildContext context) {
    final style = GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: FlutterFlowTheme.of(context).secondaryText,
        letterSpacing: 0.8);

    return Container(
      color: FlutterFlowTheme.of(context).secondaryBackground,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('CLIENT', style: style)),
          Expanded(flex: 2, child: Text('AIRLINE', style: style)),
          Expanded(flex: 2, child: Text('PNR / REF', style: style)),
          Expanded(flex: 2, child: Text('AMOUNT', style: style)),
          Expanded(flex: 2, child: Text('STATUS', style: style)),
          Expanded(flex: 2, child: Text('CREATED', style: style)),
          const SizedBox(width: 40), // action column
        ],
      ),
    );
  }

  Widget _tableFooter(BuildContext context, int count) {
    return Container(
      color: FlutterFlowTheme.of(context).secondaryBackground,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Text('$count claim${count == 1 ? '' : 's'} total',
              style: GoogleFonts.inter(
                  fontSize: 12,
                  color: FlutterFlowTheme.of(context).secondaryText)),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined,
              size: 56,
              color: FlutterFlowTheme.of(context).alternate),
          const SizedBox(height: 16),
          Text(
            _statusFilter != null || _searchQuery.isNotEmpty
                ? 'No claims match the current filter'
                : 'No claims yet',
            style: GoogleFonts.inter(
                fontSize: 15,
                color: FlutterFlowTheme.of(context).secondaryText),
          ),
          if (_statusFilter != null || _searchQuery.isNotEmpty) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _statusFilter = null;
                });
              },
              child: const Text('Clear filters'),
            ),
          ],
        ],
      ),
    );
  }
}

// ── _ClaimsTableRow ───────────────────────────────────────────────────────────

class _ClaimsTableRow extends StatelessWidget {
  const _ClaimsTableRow({
    required this.claim,
    required this.searchQuery,
    required this.isEven,
  });

  final ClaimsRecord claim;
  final String searchQuery;
  final bool isEven;

  @override
  Widget build(BuildContext context) {
    // Load the lead for client name
    if (claim.leadRef != null) {
      return StreamBuilder<LeadsRecord>(
        stream: LeadsRecord.getDocument(claim.leadRef!),
        builder: (context, snap) {
          final name = snap.data?.fullName ?? '';
          return _row(context, clientName: name);
        },
      );
    }
    return _row(context, clientName: '');
  }

  Widget _row(BuildContext context, {required String clientName}) {
    // Filter check
    if (searchQuery.isNotEmpty) {
      final haystack =
          '${clientName.toLowerCase()} ${claim.airlineName?.toLowerCase() ?? ''} ${(claim.snapshotData['pnr'] ?? claim.snapshotData['booking_reference'] ?? '').toString().toLowerCase()}';
      if (!haystack.contains(searchQuery)) return const SizedBox.shrink();
    }

    final theme = FlutterFlowTheme.of(context);
    final bgColor = isEven
        ? theme.secondaryBackground
        : theme.primaryBackground;
    final pnr = claim.pnrNumber.isNotEmpty ? claim.pnrNumber : '—';
    final amount =
        claim.claimsAmount.isNotEmpty ? '£${claim.claimsAmount}' : '—';
    final created = claim.createdAt != null
        ? dateTimeFormat('d MMM y', claim.createdAt)
        : '—';

    return InkWell(
      onTap: () => context.pushNamed(
        'ClaimsDetails',
        queryParameters: {
          'claimsRef': serializeParam(
            claim.reference,
            ParamType.DocumentReference,
          ),
        }.withoutNulls,
      ),
      hoverColor: theme.accent2.withOpacity(0.08),
      child: Container(
        color: bgColor,
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            // Client
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _kNavy,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        clientName.isNotEmpty
                            ? clientName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      clientName.isNotEmpty ? clientName : 'Unknown',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Airline
            Expanded(
              flex: 2,
              child: Text(
                claim.airlineName.isNotEmpty ? claim.airlineName : '—',
                style: GoogleFonts.inter(fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // PNR
            Expanded(
              flex: 2,
              child: Text(
                pnr,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    color: theme.secondaryText),
              ),
            ),
            // Amount
            Expanded(
              flex: 2,
              child: Text(
                amount,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2A880C)),
              ),
            ),
            // Status badge
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _StatusBadge(status: claim.claimStatus),
              ),
            ),
            // Created
            Expanded(
              flex: 2,
              child: Text(
                created,
                style: GoogleFonts.inter(
                    fontSize: 12, color: theme.secondaryText),
              ),
            ),
            // Arrow
            SizedBox(
              width: 40,
              child: Icon(Icons.chevron_right,
                  color: theme.secondaryText, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

// ── _StatusBadge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String? status;

  @override
  Widget build(BuildContext context) {
    final label = status ?? 'Unknown';
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
