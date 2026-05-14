import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/custom_code/widgets/claim_status_card.dart';
import '/custom_code/widgets/weekly_leads_chart.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/leads/add_lead/add_lead_widget.dart';
import '/menus_file/menn_pro/menn_pro_widget.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'home_page_model.dart';
export 'home_page_model.dart';

// ── Brand constants ───────────────────────────────────────────────────────────
const _kNavy = Color(0xFF002855);
const _kGold = Color(0xFFE6B011);

// ── claim_status → pipeline stage (0–3) ──────────────────────────────────────
int _stageFromStatus(String? s) {
  switch (s) {
    case 'Details Pending':
      return 0;
    case 'Under Review':
    case 'Ready For Review':
      return 1;
    case 'Awaiting Reply':
    case 'Email Sent':
      return 2;
    case 'Won':
    case 'Claim Won':
    case 'Submit to Solicitor':
    case 'Lost':
    case 'Claim Lost':
      return 3;
    default:
      return 0;
  }
}

class HomePageWidget extends StatefulWidget {
  const HomePageWidget({super.key});

  static String routeName = 'HomePage';
  static String routePath = '/homePage';

  @override
  State<HomePageWidget> createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget>
    with TickerProviderStateMixin {
  late HomePageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final animationsMap = <String, AnimationInfo>{};

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HomePageModel());

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
      'containerOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 100.0.ms,
            begin: const Offset(0.0, 50.0),
            end: Offset.zero,
          ),
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 100.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
        ],
      ),
      'chartsRowAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
              curve: Curves.easeOut, delay: 120.0.ms, duration: 250.0.ms,
              begin: 0.0, end: 1.0),
          MoveEffect(
              curve: Curves.easeOut, delay: 120.0.ms, duration: 250.0.ms,
              begin: const Offset(0, 24), end: Offset.zero),
        ],
      ),
      'recentListAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
              curve: Curves.easeOut, delay: 220.0.ms, duration: 250.0.ms,
              begin: 0.0, end: 1.0),
          MoveEffect(
              curve: Curves.easeOut, delay: 220.0.ms, duration: 250.0.ms,
              begin: const Offset(0, 24), end: Offset.zero),
        ],
      ),
    });
    setupAnimations(
      animationsMap.values.where((anim) =>
          anim.trigger == AnimationTrigger.onActionTrigger ||
          !anim.applyInitialState),
      this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return Title(
      title: 'Analytics Hub',
      color: FlutterFlowTheme.of(context).primary.withAlpha(0xFF),
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Scaffold(
          key: scaffoldKey,
          backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
          body: SafeArea(
            top: true,
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                wrapWithModel(
                  model: _model.mennProModel,
                  updateCallback: () => safeSetState(() {}),
                  child: const MennProWidget(selectedPage: 1),
                ),
                if (responsiveVisibility(context: context, phone: false))
                  Expanded(
                    child: Container(
                      height: MediaQuery.sizeOf(context).height * 1.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).tertiary,
                      ),
                      child: Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                            20.0, 16.0, 16.0, 0.0),
                        child: SingleChildScrollView(
                          primary: false,
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              // ── Header ──────────────────────────────────
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF0C519B),
                                                borderRadius:
                                                    BorderRadius.circular(15.0),
                                              ),
                                              child: const Padding(
                                                padding: EdgeInsets.all(8.0),
                                                child: FaIcon(
                                                  FontAwesomeIcons.paperPlane,
                                                  color: Color(0xFFE6B011),
                                                  size: 24.0,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              'CLAIMS',
                                              style: FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .override(
                                                    font: GoogleFonts.inter(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontStyle),
                                                    color:
                                                        const Color(0xFF0C519B),
                                                    fontSize: 35.0,
                                                    letterSpacing: 0.0,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            Text(
                                              'ASSIST',
                                              style: FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .override(
                                                    font: GoogleFonts.inter(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontStyle),
                                                    color: const Color(
                                                        0xFFE6B011),
                                                    fontSize: 35.0,
                                                    letterSpacing: 0.0,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ].divide(const SizedBox(width: 7.0)),
                                        ),
                                        AuthUserStreamWidget(
                                          builder: (context) => Text(
                                            'Hello, ${currentUserDisplayName} — Analytics overview',
                                            style: FlutterFlowTheme.of(context)
                                                .bodyLarge
                                                .override(
                                                  font: GoogleFonts.roboto(
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyLarge
                                                              .fontStyle),
                                                  color:
                                                      FlutterFlowTheme.of(context)
                                                          .primaryText,
                                                  fontSize: 15.0,
                                                  letterSpacing: 0.0,
                                                  fontWeight: FontWeight.normal,
                                                  lineHeight: 1.5,
                                                ),
                                          ),
                                        ),
                                      ].divide(const SizedBox(height: 4.0)),
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: FlutterFlowDropDown<String>(
                                          controller: _model
                                                  .dropDownValueController ??=
                                              FormFieldController<String>(null),
                                          options: const <String>[],
                                          onChanged: (val) => safeSetState(
                                              () =>
                                                  _model.dropDownValue = val),
                                          width: 280.0,
                                          height: 45.0,
                                          textStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .override(
                                                    font: GoogleFonts.inter(
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontStyle),
                                                    letterSpacing: 0.0,
                                                  ),
                                          hintText:
                                              'Filter by Date, Staff, or Type',
                                          icon: Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText,
                                            size: 24.0,
                                          ),
                                          fillColor:
                                              FlutterFlowTheme.of(context)
                                                  .primaryBackground,
                                          elevation: 2.0,
                                          borderColor: Colors.transparent,
                                          borderWidth: 0.0,
                                          borderRadius: 16.0,
                                          margin: const EdgeInsetsDirectional
                                              .fromSTEB(12.0, 0.0, 12.0, 0.0),
                                          hidesUnderline: true,
                                          isOverButton: false,
                                          isSearchable: false,
                                          isMultiSelect: false,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Container(
                                            width: 48.0,
                                            height: 48.0,
                                            decoration: BoxDecoration(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .accent2,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .secondary,
                                                width: 2.0,
                                              ),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsetsDirectional
                                                      .fromSTEB(
                                                      2.0, 2.0, 2.0, 2.0),
                                              child: AuthUserStreamWidget(
                                                builder: (context) => ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          24.0),
                                                  child: Image.network(
                                                    getCORSProxyUrl(
                                                      valueOrDefault<String>(
                                                        currentUserPhoto,
                                                        'https://images.unsplash.com/photo-1587019158091-1a103c5dd17f?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w0NTYyMDF8MHwxfHNlYXJjaHwyfHxmbGlnaHR8ZW58MHx8fHwxNzcyNzQzMzE0fDA&ixlib=rb-4.1.0&q=80&w=400',
                                                      ),
                                                    ),
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsetsDirectional
                                                .fromSTEB(0.0, 0.0, 8.0, 0.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                AuthUserStreamWidget(
                                                  builder: (context) => Text(
                                                    currentUserDisplayName,
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMedium
                                                        .override(
                                                          font: GoogleFonts.inter(
                                                              fontWeight:
                                                                  FontWeight.w600,
                                                              fontStyle: FlutterFlowTheme
                                                                      .of(context)
                                                                  .bodyMedium
                                                                  .fontStyle),
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                ),
                                                AuthUserStreamWidget(
                                                  builder: (context) => Text(
                                                    '@${valueOrDefault(currentUserDocument?.role, '')}',
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMedium
                                                        .override(
                                                          font: GoogleFonts.inter(
                                                              fontWeight: FlutterFlowTheme
                                                                      .of(context)
                                                                  .bodyMedium
                                                                  .fontWeight,
                                                              fontStyle: FlutterFlowTheme
                                                                      .of(context)
                                                                  .bodyMedium
                                                                  .fontStyle),
                                                          letterSpacing: 0.0,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (responsiveVisibility(
                                              context: context, phone: false))
                                            Padding(
                                              padding:
                                                  const EdgeInsetsDirectional
                                                      .fromSTEB(
                                                      0.0, 0.0, 12.0, 0.0),
                                              child: InkWell(
                                                splashColor: Colors.transparent,
                                                focusColor: Colors.transparent,
                                                hoverColor: Colors.transparent,
                                                highlightColor:
                                                    Colors.transparent,
                                                onTap: () async {
                                                  if (Theme.of(context)
                                                          .brightness ==
                                                      Brightness.light) {
                                                    setDarkModeSetting(
                                                        context, ThemeMode.dark);
                                                    animationsMap[
                                                            'containerOnActionTriggerAnimation']
                                                        ?.controller
                                                        .forward(from: 0.0);
                                                  } else {
                                                    setDarkModeSetting(context,
                                                        ThemeMode.light);
                                                    animationsMap[
                                                            'containerOnActionTriggerAnimation']
                                                        ?.controller
                                                        .reverse();
                                                  }
                                                },
                                                child: Container(
                                                  width: 80.0,
                                                  height: 40.0,
                                                  decoration: BoxDecoration(
                                                    color:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .alternate,
                                                    boxShadow: const [
                                                      BoxShadow(
                                                          blurRadius: 3.0,
                                                          color:
                                                              Color(0x33000000),
                                                          offset: Offset(0, 1))
                                                    ],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20.0),
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            2.0),
                                                    child: Stack(
                                                      alignment:
                                                          AlignmentDirectional(
                                                              0.0, 0.0),
                                                      children: [
                                                        Align(
                                                          alignment:
                                                              const AlignmentDirectional(
                                                                  -0.9, 0.0),
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                    6.0,
                                                                    0.0,
                                                                    0.0,
                                                                    0.0),
                                                            child: Icon(
                                                              Icons
                                                                  .wb_sunny_outlined,
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .secondaryText,
                                                              size: 24.0,
                                                            ),
                                                          ),
                                                        ),
                                                        Align(
                                                          alignment:
                                                              const AlignmentDirectional(
                                                                  1.0, 0.0),
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                    0.0,
                                                                    0.0,
                                                                    6.0,
                                                                    0.0),
                                                            child: FaIcon(
                                                              FontAwesomeIcons
                                                                  .moon,
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .secondaryText,
                                                              size: 24.0,
                                                            ),
                                                          ),
                                                        ),
                                                        Align(
                                                          alignment:
                                                              const AlignmentDirectional(
                                                                  1.0, 0.0),
                                                          child: Container(
                                                            width: 36.0,
                                                            height: 36.0,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .secondaryBackground,
                                                              boxShadow: const [
                                                                BoxShadow(
                                                                    blurRadius:
                                                                        4.0,
                                                                    color: Color(
                                                                        0x430B0D0F),
                                                                    offset: Offset(
                                                                        0, 2))
                                                              ],
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          30.0),
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
                                            ),
                                        ].divide(const SizedBox(width: 8.0)),
                                      ),
                                      FFButtonWidget(
                                        onPressed: () async {
                                          showModalBottomSheet(
                                            isScrollControlled: true,
                                            backgroundColor: Colors.transparent,
                                            useSafeArea: true,
                                            context: context,
                                            builder: (context) {
                                              return GestureDetector(
                                                onTap: () {
                                                  FocusScope.of(context)
                                                      .unfocus();
                                                  FocusManager
                                                      .instance.primaryFocus
                                                      ?.unfocus();
                                                },
                                                child: Padding(
                                                  padding:
                                                      MediaQuery.viewInsetsOf(
                                                          context),
                                                  child: const AddLeadWidget(),
                                                ),
                                              );
                                            },
                                          ).then(
                                              (value) => safeSetState(() {}));
                                        },
                                        text: 'Quick Add Lead',
                                        icon: const Icon(Icons.add, size: 15.0),
                                        options: FFButtonOptions(
                                          height: 44.0,
                                          padding: const EdgeInsetsDirectional
                                              .fromSTEB(10.0, 0.0, 10.0, 0.0),
                                          iconPadding:
                                              const EdgeInsetsDirectional
                                                  .fromSTEB(0, 0, 0, 0),
                                          iconColor:
                                              FlutterFlowTheme.of(context)
                                                  .primaryBackground,
                                          color:
                                              FlutterFlowTheme.of(context)
                                                  .primary,
                                          textStyle: TextStyle(
                                            color: FlutterFlowTheme.of(context)
                                                .info,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14.0,
                                          ),
                                          elevation: 0.0,
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                      ),
                                    ].divide(const SizedBox(width: 20.0)),
                                  ),
                                ].divide(const SizedBox(width: 8.0)),
                              ).animateOnPageLoad(
                                  animationsMap['rowOnPageLoadAnimation1']!),

                              // ── Stats cards ─────────────────────────────
                              Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    0.0, 20.0, 0.0, 0.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                        child: _StatCard(
                                      label: 'Total Leads',
                                      icon: Icons.people_alt_rounded,
                                      accentColor: _kNavy,
                                      future: queryLeadsRecordCount(),
                                    )),
                                    const SizedBox(width: 16),
                                    Expanded(
                                        child: _StatCard(
                                      label: 'Awaiting Evidence',
                                      icon: Icons.folder_open_rounded,
                                      accentColor: const Color(0xFF0C519B),
                                      future: queryLeadsRecordCount(
                                        queryBuilder: (q) => q.where('status',
                                            isEqualTo: 'Awaiting Client'),
                                      ),
                                    )),
                                    const SizedBox(width: 16),
                                    Expanded(
                                        child: _StatCard(
                                      label: 'Under Review',
                                      icon: Icons.rate_review_rounded,
                                      accentColor: const Color(0xFF4A6741),
                                      future: queryClaimsRecordCount(
                                        queryBuilder: (q) => q.where(
                                            'claim_status',
                                            isEqualTo: 'Under Review'),
                                      ),
                                    )),
                                    const SizedBox(width: 16),
                                    Expanded(
                                        child: _StatCard(
                                      label: 'Total Claims',
                                      icon: Icons.assignment_rounded,
                                      accentColor: const Color(0xFF7C3AED),
                                      future: queryClaimsRecordCount(),
                                    )),
                                  ],
                                ),
                              ).animateOnPageLoad(
                                  animationsMap['containerOnPageLoadAnimation']!),

                              // ── Charts ───────────────────────────────────
                              const SizedBox(height: 20),
                              _buildChartsSection(context).animateOnPageLoad(
                                  animationsMap['chartsRowAnimation']!),

                              // ── Recent Claims ────────────────────────────
                              const SizedBox(height: 20),
                              _buildRecentSection(context).animateOnPageLoad(
                                  animationsMap['recentListAnimation']!),
                            ].addToEnd(const SizedBox(height: 60.0)),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Charts section (direct leads query — no pre-aggregation dependency) ─────

  Widget _buildChartsSection(BuildContext context) {
    return StreamBuilder<List<LeadsRecord>>(
      stream: queryLeadsRecord(
        queryBuilder: (q) => q.orderBy('created_at', descending: true),
      ),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting &&
            !snap.hasData) {
          return const SizedBox(
            height: 300,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final leads = snap.data ?? [];

        // ── Weekly lead counts (slots 0=Sun … 6=Sat, matching JS getDay()) ──
        final now = DateTime.now();
        // DateTime.weekday: Mon=1 … Sun=7. We want days-since-Sunday:
        // Mon=1→1, Tue=2→2, … Sat=6→6, Sun=7→0
        final daysSinceSunday = now.weekday % 7;
        final weekStart = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: daysSinceSunday));

        final weekly = List<int>.filled(7, 0);
        for (final lead in leads) {
          final createdAt = lead.createdAt;
          if (createdAt == null) continue;
          final day =
              DateTime(createdAt.year, createdAt.month, createdAt.day);
          if (!day.isBefore(weekStart)) {
            // weekday % 7 maps Mon=1→1 … Sat=6→6, Sun=7→0
            weekly[createdAt.weekday % 7]++;
          }
        }

        // ── Status distribution (all leads, all time) ─────────────────────
        final statusCounts = <String, int>{};
        for (final lead in leads) {
          final s = lead.status;
          if (s.isNotEmpty) {
            statusCounts[s] = (statusCounts[s] ?? 0) + 1;
          }
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Weekly line chart (70%)
            Expanded(
              flex: 7,
              child: _ChartCard(
                title: 'Weekly Leads',
                subtitle: 'Leads created this week (Sun – Sat)',
                child: SizedBox(
                  height: 280,
                  child: WeeklyLeadsChart(
                    width: double.infinity,
                    height: 280,
                    leadCounts: weekly,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Lead status donut (30%)
            Expanded(
              flex: 3,
              child: _ChartCard(
                title: 'Lead Status',
                subtitle: 'All-time by status',
                child: SizedBox(
                  height: 280,
                  child: statusCounts.isEmpty
                      ? const _EmptyChart(label: 'No lead data yet')
                      : _DonutChart(sources: statusCounts),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Recent Claims section ─────────────────────────────────────────────────

  Widget _buildRecentSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Claims',
              style: GoogleFonts.interTight(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: FlutterFlowTheme.of(context).primaryText,
              ),
            ),
            TextButton(
              onPressed: () => context.pushNamed('ClaimsDashboard'),
              child: Text('View all claims',
                  style: GoogleFonts.inter(
                      color: _kNavy, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<ClaimsRecord>>(
          stream: queryClaimsRecord(
            queryBuilder: (q) =>
                q.orderBy('createdAt', descending: true),
            limit: 5,
          ),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: _kNavy),
                ),
              );
            }
            final claims = snap.data ?? [];
            if (claims.isEmpty) {
              return _emptyState('No claims yet', Icons.inbox_outlined);
            }
            return Column(
              children: claims
                  .map((claim) => _ClaimCardWrapper(claim: claim))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _emptyState(String msg, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FlutterFlowTheme.of(context).alternate),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: FlutterFlowTheme.of(context).secondaryText),
          const SizedBox(height: 12),
          Text(msg,
              style: TextStyle(
                  color: FlutterFlowTheme.of(context).secondaryText,
                  fontSize: 14)),
        ],
      ),
    );
  }
}

// ── _ClaimCardWrapper ─────────────────────────────────────────────────────────

class _ClaimCardWrapper extends StatelessWidget {
  const _ClaimCardWrapper({required this.claim});
  final ClaimsRecord claim;

  @override
  Widget build(BuildContext context) {
    if (claim.leadRef == null) {
      return _card(context, clientName: 'Unknown Client');
    }
    return StreamBuilder<LeadsRecord>(
      stream: LeadsRecord.getDocument(claim.leadRef!),
      builder: (context, snap) {
        final name = snap.data?.fullName ?? '';
        return _card(context, clientName: name);
      },
    );
  }

  Widget _card(BuildContext context, {required String clientName}) {
    return ClaimStatusCard(
      width: double.infinity,
      clientName: clientName.isNotEmpty ? clientName : 'Unknown Client',
      airlineName: claim.airlineName,
      pnrNumber: claim.pnrNumber,
      claimStage: _stageFromStatus(claim.claimStatus),
      onTap: () async {},
    );
  }
}

// ── _StatCard ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.future,
  });

  final String label;
  final IconData icon;
  final Color accentColor;
  final Future<int> future;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: FlutterFlowTheme.of(context).alternate, width: 1),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FutureBuilder<int>(
                  future: future,
                  builder: (context, snap) => Text(
                    snap.hasData ? snap.data.toString() : '—',
                    style: GoogleFonts.interTight(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: FlutterFlowTheme.of(context).secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── _ChartCard ────────────────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  const _ChartCard(
      {required this.title, required this.subtitle, required this.child});

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.alternate, width: 1),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.interTight(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: theme.primaryText)),
          const SizedBox(height: 2),
          Text(subtitle,
              style:
                  GoogleFonts.inter(fontSize: 11, color: theme.secondaryText)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ── _DonutChart ───────────────────────────────────────────────────────────────

class _DonutChart extends StatefulWidget {
  const _DonutChart({required this.sources});
  final Map<String, int> sources;

  @override
  State<_DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<_DonutChart> {
  int? _touchedIndex;

  static const _palette = [
    _kNavy,
    _kGold,
    Color(0xFF4A6741),
    Color(0xFF7C9CB4),
    Color(0xFFC4836A),
    Color(0xFF57636C),
    Color(0xFF39D2C0),
  ];

  @override
  Widget build(BuildContext context) {
    final entries = widget.sources.entries.toList();
    final total = entries.fold<int>(0, (s, e) => s + e.value);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 190,
          child: PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 52,
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    _touchedIndex = (event is FlPointerHoverEvent &&
                            response?.touchedSection != null)
                        ? response!.touchedSection!.touchedSectionIndex
                        : null;
                  });
                },
              ),
              sections: List.generate(entries.length, (i) {
                final isTouched = i == _touchedIndex;
                final color = _palette[i % _palette.length];
                final pct = total > 0
                    ? (entries[i].value / total * 100).toStringAsFixed(1)
                    : '0';
                return PieChartSectionData(
                  color: color,
                  value: entries[i].value.toDouble(),
                  title: isTouched ? '$pct%' : '',
                  radius: isTouched ? 52 : 44,
                  titleStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Legend
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: List.generate(entries.length, (i) {
            final color = _palette[i % _palette.length];
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 10,
                    height: 10,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(
                  '${entries[i].key} (${entries[i].value})',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: FlutterFlowTheme.of(context).secondaryText,
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}

// ── _EmptyChart ───────────────────────────────────────────────────────────────

class _EmptyChart extends StatelessWidget {
  const _EmptyChart({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_rounded,
              size: 48, color: FlutterFlowTheme.of(context).alternate),
          const SizedBox(height: 12),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  color: FlutterFlowTheme.of(context).secondaryText)),
        ],
      ),
    );
  }
}
