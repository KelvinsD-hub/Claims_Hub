import '/auth/firebase_auth/auth_util.dart';
import '/backend/services/casework.dart';
import '/backend/services/pipeline.dart';
import '/components/brand_colors.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:page_transition/page_transition.dart';

/// The pieces the working pages share — Leads, Claims, Demand letters and the
/// Legal Workspace — so they look and behave as one area: the same sidebar,
/// the same header, the same way of showing a stage or a due date.

enum WorkPage { leads, claims, demands, legal }

/// Moving between the working pages swaps the page at once. Without this the
/// router plays its default page animation, which reads as the screen
/// jumping.
const _atOnce = <String, dynamic>{
  kTransitionInfoKey: TransitionInfo(
    hasTransition: true,
    transitionType: PageTransitionType.fade,
    duration: Duration.zero,
  ),
};

/// Whether the sidebar is folded down to its icons. Kept across pages.
final _sidebarFolded = ValueNotifier<bool>(false);

/// The sidebar for the working pages.
class WorkSidebar extends StatelessWidget {
  const WorkSidebar({super.key, required this.selected});

  final WorkPage selected;

  static const _items = <(WorkPage, IconData, String)>[
    (WorkPage.leads, Icons.person_search_outlined, 'Leads'),
    (WorkPage.claims, Icons.folder_copy_outlined, 'Claims'),
    (WorkPage.demands, Icons.outgoing_mail, 'Demand letters'),
    (WorkPage.legal, Icons.gavel_outlined, 'Legal Workspace'),
  ];

  static String _route(WorkPage page) => switch (page) {
        WorkPage.leads => LeadsWidget.routeName,
        WorkPage.claims => ClaimsDashboardWidget.routeName,
        WorkPage.demands => EmailAirlinesWidget.routeName,
        WorkPage.legal => SolicitorsWidget.routeName,
      };

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return ValueListenableBuilder<bool>(
      valueListenable: _sidebarFolded,
      builder: (context, folded, _) => AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: folded ? 68.0 : 212.0,
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          border: Border(right: BorderSide(color: theme.alternate)),
        ),
        padding: const EdgeInsets.fromLTRB(12.0, 18.0, 12.0, 14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Tooltip(
              message: 'Back to the home page',
              child: InkWell(
                borderRadius: BorderRadius.circular(10.0),
                onTap: () =>
                    context.goNamed(HomePageWidget.routeName, extra: _atOnce),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back,
                          size: 20.0, color: theme.primaryText),
                      if (!folded) ...[
                        const SizedBox(width: 10.0),
                        Text('Home',
                            style: GoogleFonts.inter(
                                fontSize: 13.5, color: theme.secondaryText)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18.0),
            for (final (page, icon, label) in _items)
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Tooltip(
                  message: folded ? label : '',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10.0),
                    onTap: page == selected
                        ? null
                        : () => context.goNamed(_route(page), extra: _atOnce),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 11.0),
                      decoration: BoxDecoration(
                        color: page == selected
                            ? brandBlue(context).withValues(alpha: 0.16)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Row(
                        children: [
                          Icon(icon,
                              size: 19.0,
                              color: page == selected
                                  ? brandBlue(context)
                                  : theme.secondaryText),
                          if (!folded) ...[
                            const SizedBox(width: 12.0),
                            Expanded(
                              child: Text(
                                label,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  fontWeight: page == selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: page == selected
                                      ? theme.primaryText
                                      : theme.secondaryText,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            const Spacer(),
            Tooltip(
              message: folded ? 'Show the menu' : 'Fold the menu',
              child: InkWell(
                borderRadius: BorderRadius.circular(10.0),
                onTap: () => _sidebarFolded.value = !folded,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Icon(
                    folded
                        ? Icons.keyboard_double_arrow_right
                        : Icons.keyboard_double_arrow_left,
                    size: 20.0,
                    color: theme.secondaryText,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.fromLTRB(28.0, 18.0, 24.0, 18.0),
                      decoration: BoxDecoration(
                        color: theme.secondaryBackground,
                        border:
                            Border(bottom: BorderSide(color: theme.alternate)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9.0),
                            decoration: BoxDecoration(
                              color: brandBlue(context).withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Icon(icon,
                                size: 22.0, color: brandBlue(context)),
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
                                      fontSize: 12.5,
                                      color: theme.secondaryText),
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
                    ),
                    Expanded(child: child),
                  ],
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
