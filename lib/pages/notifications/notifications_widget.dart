import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/menus_file/menn_pro/menn_pro_widget.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'notifications_model.dart';
export 'notifications_model.dart';

const Color _kNavy = Color(0xFF002855);

class NotificationsWidget extends StatefulWidget {
  const NotificationsWidget({super.key});

  static String routeName = 'Notifications';
  static String routePath = '/notifications';

  @override
  State<NotificationsWidget> createState() => _NotificationsWidgetState();
}

class _NotificationsWidgetState extends State<NotificationsWidget> {
  late NotificationsModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  // Active entity-type filter ('All' shows everything).
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => NotificationsModel());
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
      title: 'Notifications',
      color: FlutterFlowTheme.of(context).primary.withAlpha(0XFF),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                wrapWithModel(
                  model: _model.mennProModel,
                  updateCallback: () => safeSetState(() {}),
                  child: MennProWidget(selectedPage: 7),
                ),
                Expanded(
                  child: StreamBuilder<List<ActivityLogsRecord>>(
                    stream: queryActivityLogsRecord(
                      queryBuilder: (q) =>
                          q.orderBy('createdAt', descending: true),
                      limit: 200,
                    ),
                    builder: (context, snapshot) {
                      final logs = snapshot.data ?? [];

                      // Distinct entity types present, for the filter row.
                      final types = <String>{
                        for (final l in logs)
                          if (l.entityType.trim().isNotEmpty)
                            _titleCase(l.entityType.trim())
                      }.toList()
                        ..sort();

                      final filtered = _filter == 'All'
                          ? logs
                          : logs
                              .where((l) =>
                                  _titleCase(l.entityType.trim()) == _filter)
                              .toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // -- Header ----------------------------------------
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: _kNavy.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.notifications_active_rounded,
                                        color: _kNavy, size: 22),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Notifications',
                                      style: FlutterFlowTheme.of(context)
                                          .headlineSmall
                                          .override(
                                            font: GoogleFonts.interTight(
                                                fontWeight: FontWeight.bold),
                                            color: _kNavy,
                                            letterSpacing: 0,
                                          ),
                                    ),
                                    Text(
                                      'Recent activity and updates',
                                      style: GoogleFonts.inter(
                                          fontSize: 13, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                FlutterFlowIconButton(
                                  borderColor:
                                      FlutterFlowTheme.of(context).alternate,
                                  borderRadius: 8,
                                  borderWidth: 1,
                                  buttonSize: 40,
                                  fillColor: FlutterFlowTheme.of(context)
                                      .primaryBackground,
                                  icon: const Icon(Icons.refresh_rounded,
                                      color: _kNavy, size: 20),
                                  onPressed: () => safeSetState(() {}),
                                ),
                              ],
                            ),
                          ),

                          // -- Filter chips ----------------------------------
                          if (types.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _FilterChip(
                                    label: 'All',
                                    count: logs.length,
                                    selected: _filter == 'All',
                                    onTap: () =>
                                        safeSetState(() => _filter = 'All'),
                                  ),
                                  for (final t in types)
                                    _FilterChip(
                                      label: t,
                                      count: logs
                                          .where((l) =>
                                              _titleCase(l.entityType.trim()) ==
                                              t)
                                          .length,
                                      selected: _filter == t,
                                      onTap: () =>
                                          safeSetState(() => _filter = t),
                                    ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 16),

                          // -- Activity feed ---------------------------------
                          Expanded(
                            child: snapshot.connectionState ==
                                    ConnectionState.waiting
                                ? const Center(
                                    child: CircularProgressIndicator(
                                        color: _kNavy))
                                : filtered.isEmpty
                                    ? _EmptyState(filtered: _filter != 'All')
                                    : ListView.separated(
                                        padding: const EdgeInsets.fromLTRB(
                                            24, 0, 24, 24),
                                        itemCount: filtered.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(height: 10),
                                        itemBuilder: (context, i) =>
                                            _ActivityTile(log: filtered[i]),
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

// -- Helpers ------------------------------------------------------------------

String _titleCase(String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1).toLowerCase();
}

String _timeAgo(DateTime? dt) {
  if (dt == null) return '';
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
  return dateTimeFormat('MMM d, yyyy', dt);
}

/// Picks an icon + color from the action / entity type.
({IconData icon, Color color}) _visualFor(ActivityLogsRecord log) {
  final a = log.action.toLowerCase();
  final e = log.entityType.toLowerCase();

  if (a.contains('delete') || a.contains('remove') || a.contains('reject') ||
      a.contains('lost')) {
    return (icon: Icons.delete_outline, color: Colors.red.shade600);
  }
  if (a.contains('create') || a.contains('add') || a.contains('new')) {
    return (icon: Icons.add_circle_outline, color: Colors.green.shade700);
  }
  if (a.contains('won') || a.contains('approve') || a.contains('paid') ||
      a.contains('success')) {
    return (icon: Icons.check_circle_outline, color: Colors.green.shade700);
  }
  if (a.contains('submit') || a.contains('sent') || a.contains('email')) {
    return (icon: Icons.send_outlined, color: _kNavy);
  }
  if (a.contains('update') || a.contains('edit') || a.contains('change')) {
    return (icon: Icons.edit_outlined, color: Colors.blue.shade600);
  }
  // Fall back on entity type.
  if (e.contains('claim')) {
    return (icon: Icons.gavel_outlined, color: _kNavy);
  }
  if (e.contains('lead')) {
    return (icon: Icons.person_add_alt_1_outlined, color: Colors.teal.shade600);
  }
  return (icon: Icons.notifications_none_rounded, color: Colors.blueGrey);
}

// -- Activity tile ------------------------------------------------------------

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.log});
  final ActivityLogsRecord log;

  @override
  Widget build(BuildContext context) {
    final v = _visualFor(log);
    final title = log.description.isNotEmpty
        ? log.description
        : (log.action.isNotEmpty ? log.action : 'Activity');

    return Container(
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).primaryBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: FlutterFlowTheme.of(context).alternate),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: v.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(child: Icon(v.icon, color: v.color, size: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.inter(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _timeAgo(log.createdAt),
                      style:
                          GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (log.action.isNotEmpty && log.description.isNotEmpty) ...[
                      Text(
                        log.action,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: FlutterFlowTheme.of(context).secondaryText),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (log.performedByName.isNotEmpty) ...[
                      const Icon(Icons.person_outline,
                          size: 13, color: Colors.grey),
                      const SizedBox(width: 3),
                      Text(
                        log.performedByName,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: Colors.grey),
                      ),
                    ],
                    const Spacer(),
                    if (log.entityType.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: v.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _titleCase(log.entityType),
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: v.color),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -- Filter chip --------------------------------------------------------------

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _kNavy : FlutterFlowTheme.of(context).primaryBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? _kNavy : FlutterFlowTheme.of(context).alternate),
        ),
        child: Text(
          '$label ($count)',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : FlutterFlowTheme.of(context).primaryText,
          ),
        ),
      ),
    );
  }
}

// -- Empty state --------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filtered});
  final bool filtered;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(FontAwesomeIcons.bellSlash,
              size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            filtered ? 'Nothing in this category' : 'No activity yet',
            style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600),
          ),
          const SizedBox(height: 6),
          Text(
            filtered
                ? 'Try a different filter above.'
                : 'Actions across leads and claims will show up here.',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
