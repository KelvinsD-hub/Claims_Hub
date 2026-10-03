import '/auth/firebase_auth/auth_util.dart';
import '/backend/services/access.dart';
import '/backend/services/casework.dart';
import '/backend/services/pipeline.dart';
import '/components/brand_colors.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/forms/log_out/log_out_widget.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:page_transition/page_transition.dart';

export '/backend/services/access.dart' show WorkPage, canSeePage;

/// The pieces the working pages share — Leads, Claims, Demand letters and the
/// Legal Workspace — so they look and behave as one area: the same sidebar,
/// the same header, the same way of showing a stage or a due date.

/// Moving between pages swaps the page at once. Without this the router plays
/// its default page animation, which reads as the screen jumping.
const _atOnce = <String, dynamic>{
  kTransitionInfoKey: TransitionInfo(
    hasTransition: true,
    transitionType: PageTransitionType.fade,
    duration: Duration.zero,
  ),
};

/// Whether the sidebar is folded down to its icons. Kept across pages.
final _sidebarFolded = ValueNotifier<bool>(false);

/// The sidebar: the same on every staff page.
class WorkSidebar extends StatelessWidget {
  const WorkSidebar({super.key, required this.selected});

  final WorkPage selected;

  /// The pages in the order shown; a null starts a new group.
  static const _items = <(WorkPage, IconData, String)?>[
    (WorkPage.dashboard, Icons.dashboard_outlined, 'Dashboard'),
    null,
    (WorkPage.leads, Icons.person_search_outlined, 'Leads'),
    (WorkPage.claims, Icons.folder_copy_outlined, 'Claims'),
    (WorkPage.demands, Icons.outgoing_mail, 'Demand letters'),
    (WorkPage.legal, Icons.gavel_outlined, 'Legal Workspace'),
    (WorkPage.evidence, Icons.lock_outline, 'Evidence Locker'),
    null,
    (WorkPage.monitor, Icons.monitor_heart_outlined, 'Monitor'),
    (WorkPage.links, Icons.link, 'Links'),
    (WorkPage.staff, Icons.groups_outlined, 'Staff'),
    null,
    (WorkPage.notifications, Icons.notifications_none, 'Notifications'),
    (WorkPage.support, Icons.support_agent, 'Support'),
    (WorkPage.settings, Icons.settings_outlined, 'Settings'),
  ];

  static String _route(WorkPage page) => switch (page) {
        WorkPage.dashboard => HomePageWidget.routeName,
        WorkPage.leads => LeadsWidget.routeName,
        WorkPage.claims => ClaimsDashboardWidget.routeName,
        WorkPage.demands => EmailAirlinesWidget.routeName,
        WorkPage.legal => SolicitorsWidget.routeName,
        WorkPage.evidence => EvidenceLockerWidget.routeName,
        WorkPage.monitor => MonitorWidget.routeName,
        WorkPage.links => LinksWidget.routeName,
        WorkPage.staff => StaffsWidget.routeName,
        WorkPage.notifications => NotificationsWidget.routeName,
        WorkPage.support => SupportsWidget.routeName,
        WorkPage.settings => SettingsWidget.routeName,
      };

  void _logOut(BuildContext context) {
    showModalBottomSheet<void>(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      context: context,
      builder: (context) => Padding(
        padding: MediaQuery.viewInsetsOf(context),
        child: const LogOutWidget(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    Widget entry({
      required IconData icon,
      required String label,
      required bool folded,
      required VoidCallback? onTap,
      bool current = false,
      Color? color,
    }) {
      final tint =
          color ?? (current ? brandBlue(context) : theme.secondaryText);
      return Padding(
        padding: const EdgeInsets.only(bottom: 3.0),
        child: Tooltip(
          message: folded ? label : '',
          child: InkWell(
            borderRadius: BorderRadius.circular(10.0),
            onTap: onTap,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: current
                    ? brandBlue(context).withValues(alpha: 0.16)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 19.0, color: tint),
                  if (!folded) ...[
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight:
                              current ? FontWeight.w700 : FontWeight.w500,
                          color: color ??
                              (current
                                  ? theme.primaryText
                                  : theme.secondaryText),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    return ValueListenableBuilder<bool>(
      valueListenable: _sidebarFolded,
      builder: (context, folded, _) => AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: folded ? 68.0 : 216.0,
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          border: Border(right: BorderSide(color: theme.alternate)),
        ),
        padding: const EdgeInsets.fromLTRB(12.0, 18.0, 12.0, 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10.0, 4.0, 4.0, 18.0),
              child: folded
                  ? Text('CA',
                      style: GoogleFonts.interTight(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w800,
                          color: brandBlue(context)))
                  : Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                              text: 'Claims ',
                              style: TextStyle(color: brandBlue(context))),
                          const TextSpan(
                              text: 'Assist',
                              style: TextStyle(color: Color(0xFFD99A00))),
                        ],
                      ),
                      style: GoogleFonts.interTight(
                          fontSize: 18.0, fontWeight: FontWeight.w800),
                    ),
            ),
            Expanded(
              child: SingleChildScrollView(
                // Each person sees the pages their role may open; the role
                // comes with the signed-in person's record.
                child: AuthUserStreamWidget(
                  builder: (context) => Column(
                    children: [
                      for (final item in _items)
                        if (item == null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 7.0),
                            child: Divider(height: 1.0, color: theme.alternate),
                          )
                        else if (canSeePage(item.$1,
                            valueOrDefault(currentUserDocument?.role, '')))
                          entry(
                            icon: item.$2,
                            label: item.$3,
                            folded: folded,
                            current: item.$1 == selected,
                            onTap: item.$1 == selected
                                ? null
                                : () => context.goNamed(_route(item.$1),
                                    extra: _atOnce),
                          ),
                    ],
                  ),
                ),
              ),
            ),
            Divider(height: 14.0, color: theme.alternate),
            entry(
              icon: folded
                  ? Icons.keyboard_double_arrow_right
                  : Icons.keyboard_double_arrow_left,
              label: folded ? 'Show the menu' : 'Fold the menu',
              folded: folded,
              onTap: () => _sidebarFolded.value = !folded,
            ),
            entry(
              icon: Icons.logout_rounded,
              label: 'Log out',
              folded: folded,
              color: overdueRed(context),
              onTap: () => _logOut(context),
            ),
          ],
        ),
      ),
    );
  }
}

/// The bar across the top of a page: what the page is, its controls, the
/// theme switch and who is signed in.
class WorkHeader extends StatelessWidget {
  const WorkHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.actions = const [],
  });

  final String title;
  final String subtitle;
  final IconData icon;

  /// Controls on the right: search, buttons.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(28.0, 18.0, 24.0, 18.0),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        border: Border(bottom: BorderSide(color: theme.alternate)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9.0),
            decoration: BoxDecoration(
              color: brandBlue(context).withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Icon(icon, size: 22.0, color: brandBlue(context)),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.interTight(
                    fontSize: 21.0,
                    fontWeight: FontWeight.w700,
                    color: theme.primaryText,
                  ),
                ),
                Text(
                  subtitle,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                      fontSize: 12.5, color: theme.secondaryText),
                ),
              ],
            ),
          ),
          for (final action in actions) ...[
            const SizedBox(width: 10.0),
            action,
          ],
          const SizedBox(width: 14.0),
          const _ThemeButton(),
          const SizedBox(width: 10.0),
          const _WhoAmI(),
        ],
      ),
    );
  }
}

/// A page's header over its content, for a page that builds its own
/// scaffold. Goes beside a [WorkSidebar].
class WorkBody extends StatelessWidget {
  const WorkBody({
    super.key,
    this.page,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    this.actions = const [],
  });

  /// The page this is. With it, someone whose role may not open the page
  /// sees a notice instead of its content.
  final WorkPage? page;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> actions;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AuthUserStreamWidget(
      builder: (context) {
        final allowed = page == null ||
            canSeePage(page!, valueOrDefault(currentUserDocument?.role, ''));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WorkHeader(
              title: title,
              subtitle: subtitle,
              icon: icon,
              actions: allowed ? actions : const [],
            ),
            Expanded(
              child: allowed
                  ? child
                  : const WorkEmpty(
                      'This page is not available for your role.\n'
                      'Ask an admin if you need it.'),
            ),
          ],
        );
      },
    );
  }
}

/// A working page: the sidebar, a header and the page's own content.
class WorkScaffold extends StatelessWidget {
  const WorkScaffold({
    super.key,
    required this.page,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    this.actions = const [],
  });

  final WorkPage page;
  final String title;
  final String subtitle;
  final IconData icon;

  /// Controls on the right of the header: search, buttons.
  final List<Widget> actions;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Title(
      title: title,
      color: theme.primary.withAlpha(0xFF),
      child: Scaffold(
        backgroundColor: theme.primaryBackground,
        body: SafeArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WorkSidebar(selected: page),
              Expanded(
                child: WorkBody(
                  page: page,
                  title: title,
                  subtitle: subtitle,
                  icon: icon,
                  actions: actions,
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeButton extends StatelessWidget {
  const _ThemeButton();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      tooltip: dark ? 'Light theme' : 'Dark theme',
      onPressed: () =>
          setDarkModeSetting(context, dark ? ThemeMode.light : ThemeMode.dark),
      icon: Icon(
        dark ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined,
        size: 20.0,
        color: FlutterFlowTheme.of(context).secondaryText,
      ),
    );
  }
}

class _WhoAmI extends StatelessWidget {
  const _WhoAmI();

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return AuthUserStreamWidget(
      builder: (context) {
        final name = currentUserDisplayName.isNotEmpty
            ? currentUserDisplayName
            : currentUserEmail;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 17.0,
              backgroundColor: brandBlue(context).withValues(alpha: 0.2),
              child: Text(
                name.isEmpty ? '?' : name[0].toUpperCase(),
                style: GoogleFonts.inter(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w700,
                    color: brandBlue(context)),
              ),
            ),
            const SizedBox(width: 8.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(name,
                    style: GoogleFonts.inter(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w600,
                        color: theme.primaryText)),
                Text(valueOrDefault(currentUserDocument?.role, ''),
                    style: GoogleFonts.inter(
                        fontSize: 11.5, color: theme.secondaryText)),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// The colour a stage is shown in, readable on either theme.
Color stageColor(BuildContext context, String stage) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  switch (stage) {
    case ClaimStage.won:
    case ClaimStage.paid:
    case LeadStage.qualified:
      return dark ? const Color(0xFF6FCF97) : const Color(0xFF1B7F3B);
    case ClaimStage.lost:
    case LeadStage.rejected:
      return overdueRed(context);
    case ClaimStage.withdrawn:
      return FlutterFlowTheme.of(context).secondaryText;
    case ClaimStage.withSolicitor:
      return dark ? const Color(0xFFB79BF5) : const Color(0xFF6D3BD1);
    case ClaimStage.detailsPending:
    case ClaimStage.termsPending:
    case LeadStage.newLead:
      return dark ? const Color(0xFFF2B36B) : const Color(0xFFB45F06);
    default:
      return brandBlue(context);
  }
}

/// A stage, as a small coloured label.
class StagePill extends StatelessWidget {
  const StagePill(this.stage, {super.key});

  final String stage;

  @override
  Widget build(BuildContext context) {
    final color = stageColor(context, stage);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(7.0),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        stage.isEmpty ? 'No stage' : stage,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
            fontSize: 11.5, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

/// A filter along the top of a list: "New 5".
class WorkChip extends StatelessWidget {
  const WorkChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
    this.alert = false,
  });

  final String label;
  final int? count;
  final bool selected;

  /// Shows the count in the alert colour: something here is late.
  final bool alert;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(20.0),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13.0, vertical: 7.0),
        decoration: BoxDecoration(
          color: selected
              ? brandBlue(context).withValues(alpha: 0.16)
              : theme.secondaryBackground,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(
              color: selected ? brandBlue(context) : theme.alternate),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? brandBlue(context) : theme.primaryText,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 7.0),
              Text(
                '$count',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: alert && count! > 0
                      ? overdueRed(context)
                      : theme.secondaryText,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The search box in a page header.
class WorkSearchBox extends StatelessWidget {
  const WorkSearchBox({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return SizedBox(
      width: 250.0,
      height: 42.0,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: GoogleFonts.inter(fontSize: 13.0, color: theme.primaryText),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              GoogleFonts.inter(fontSize: 13.0, color: theme.secondaryText),
          prefixIcon:
              Icon(Icons.search, size: 19.0, color: theme.secondaryText),
          filled: true,
          fillColor: theme.primaryBackground,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

/// A button in a page header or on a row.
class WorkButton extends StatelessWidget {
  const WorkButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  /// The main action on the page or row.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final blue = brandBlue(context);
    final style =
        GoogleFonts.inter(fontSize: 13.0, fontWeight: FontWeight.w600);
    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0));
    const padding = EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0);
    if (filled) {
      return FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16.0),
        label: Text(label, style: style),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF0C519B),
          foregroundColor: Colors.white,
          disabledBackgroundColor: theme.alternate,
          disabledForegroundColor: theme.secondaryText,
          padding: padding,
          shape: shape,
        ),
      );
    }
    final color = onTap == null ? theme.secondaryText : blue;
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16.0, color: color),
      label: Text(label, style: style.copyWith(color: color)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        padding: padding,
        shape: shape,
      ),
    );
  }
}

/// What a list shows when it has nothing in it.
class WorkEmpty extends StatelessWidget {
  const WorkEmpty(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 48.0, color: theme.alternate),
          const SizedBox(height: 12.0),
          Text(message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 14.0, color: theme.secondaryText)),
        ],
      ),
    );
  }
}

/// Who owns a record and when its next action is due, for a list row.
class OwnerAndDue extends StatelessWidget {
  const OwnerAndDue(this.work, {super.key, this.lawyer = false});

  final Casework work;

  /// Show the lawyer on the claim, not its handler.
  final bool lawyer;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final owner = lawyer ? work.lawyerName : work.handlerName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          owner.isEmpty ? 'Unassigned' : owner,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            color: owner.isEmpty ? overdueRed(context) : theme.primaryText,
          ),
        ),
        if (work.hasNextAction)
          Text(
            work.dueLabel.isEmpty ? work.nextAction : work.dueLabel,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: work.isOverdue ? FontWeight.w700 : FontWeight.w400,
              color: work.isOverdue ? overdueRed(context) : theme.secondaryText,
            ),
          ),
      ],
    );
  }
}

/// A column heading in a list.
class WorkColumnHead extends StatelessWidget {
  const WorkColumnHead(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.7,
        color: FlutterFlowTheme.of(context).secondaryText,
      ),
    );
  }
}

/// A heading inside a lead's or claim's file.
class FileSection extends StatelessWidget {
  const FileSection(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22.0, bottom: 10.0),
      child: WorkColumnHead(text),
    );
  }
}

/// One labelled fact in a file. An empty [value] shows as a dash.
class FileFact extends StatelessWidget {
  const FileFact(this.label, this.value, {super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style:
                GoogleFonts.inter(fontSize: 11.0, color: theme.secondaryText)),
        const SizedBox(height: 2.0),
        SelectableText(
          value.trim().isEmpty ? '—' : value,
          style: GoogleFonts.inter(
            fontSize: 14.0,
            fontWeight: FontWeight.w600,
            color: theme.primaryText,
          ),
        ),
      ],
    );
  }
}

/// One of the tabs over a file's right-hand column.
class WorkTab extends StatelessWidget {
  const WorkTab({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(8.0),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 7.0),
        decoration: BoxDecoration(
          color: selected
              ? brandBlue(context).withValues(alpha: 0.16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? brandBlue(context) : theme.secondaryText,
          ),
        ),
      ),
    );
  }
}
