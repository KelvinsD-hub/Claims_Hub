import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/components/work_ui.dart';
import '/components/brand_colors.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:math';
import 'dart:ui';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'settings_model.dart';
export 'settings_model.dart';

class SettingsWidget extends StatefulWidget {
  const SettingsWidget({super.key});

  static String routeName = 'Settings';
  static String routePath = '/settings';

  @override
  State<SettingsWidget> createState() => _SettingsWidgetState();
}

class _SettingsWidgetState extends State<SettingsWidget>
    with TickerProviderStateMixin {
  late SettingsModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final animationsMap = <String, AnimationInfo>{};

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SettingsModel());

    animationsMap.addAll({
      'rowOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 50.0.ms,
            begin: Offset(0.0, 50.0),
            end: Offset(0.0, 0.0),
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
            begin: Offset(-40.0, 0.0),
            end: Offset(0.0, 0.0),
          ),
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

  void _snack(String msg, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    GoRouter.of(context).prepareAuthEvent();
    await authManager.signOut();
    GoRouter.of(context).clearRedirectLocation();
    if (mounted) {
      context.goNamedAuth(AuthenticationWidget.routeName, context.mounted);
    }
  }

  Future<void> _resetPassword() async {
    final email = currentUserEmail;
    if (email.isEmpty) {
      _snack('No email on file for this account.',
          color: Colors.orange.shade700);
      return;
    }
    await authManager.resetPassword(email: email, context: context);
    _snack('Password reset email sent to $email', color: Colors.green.shade700);
  }

  Future<void> _changePassword() async {
    final controller = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final newPassword = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Change password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: controller,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New password'),
                validator: (v) => (v == null || v.length < 6)
                    ? 'At least 6 characters'
                    : null,
              ),
              TextFormField(
                controller: confirmController,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'Confirm password'),
                validator: (v) =>
                    v != controller.text ? 'Passwords do not match' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF002855)),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, controller.text);
              }
            },
            child: const Text('Update', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (newPassword == null) return;
    try {
      await authManager.updatePassword(
          newPassword: newPassword, context: context);
      _snack('Password updated.', color: Colors.green.shade700);
    } catch (e) {
      _snack('Could not update password: $e', color: Colors.red.shade700);
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete account'),
        content: const Text(
            'This permanently deletes your account and you will be signed out. This cannot be undone. Continue?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await authManager.deleteUser(context);
      if (mounted) {
        context.goNamedAuth(AuthenticationWidget.routeName, context.mounted);
      }
    } catch (e) {
      _snack('Could not delete account: $e', color: Colors.red.shade700);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Title(
        title: 'Settings',
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
                mainAxisSize: MainAxisSize.max,
                children: [
                  const WorkSidebar(selected: WorkPage.settings),
                  Expanded(
                    child: WorkBody(
                      page: WorkPage.settings,
                      title: 'Settings',
                      subtitle: 'Your profile, the theme and your account',
                      icon: Icons.settings_outlined,
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              child: _buildSettingsBody(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
  }

  Widget _buildSettingsBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -- Profile -------------------------------------------------
          _SettingsSection(
            title: 'Profile',
            icon: Icons.person_outline,
            children: [
              AuthUserStreamWidget(
                builder: (context) => _SettingsTile(
                  icon: Icons.badge_outlined,
                  title: currentUserDisplayName.isNotEmpty
                      ? currentUserDisplayName
                      : 'Your profile',
                  subtitle: [
                    if (currentUserEmail.isNotEmpty) currentUserEmail,
                    if ((currentUserDocument?.role ?? '').isNotEmpty)
                      '@${currentUserDocument!.role}',
                  ].join('  -  '),
                  actionLabel: 'Edit',
                  onTap: () => context.pushNamed(EditProfileWidget.routeName),
                ),
              ),
            ],
          ),

          // -- Appearance ----------------------------------------------
          _SettingsSection(
            title: 'Appearance',
            icon: Icons.palette_outlined,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.brightness_6_outlined,
                        color: brandBlue(context), size: 20),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text('Theme',
                          style: GoogleFonts.inter(
                              fontSize: 14, fontWeight: FontWeight.w500)),
                    ),
                    _ThemeToggle(
                      current: Theme.of(context).brightness == Brightness.dark
                          ? ThemeMode.dark
                          : ThemeMode.light,
                      onChanged: (mode) => setDarkModeSetting(context, mode),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // -- Security ------------------------------------------------
          _SettingsSection(
            title: 'Security',
            icon: Icons.lock_outline,
            children: [
              _SettingsTile(
                icon: Icons.password_outlined,
                title: 'Change password',
                subtitle: 'Set a new password for your account',
                onTap: _changePassword,
              ),
              _SettingsTile(
                icon: Icons.mark_email_read_outlined,
                title: 'Send password reset email',
                subtitle: 'We\'ll email you a reset link',
                onTap: _resetPassword,
              ),
            ],
          ),

          // -- Support / About -----------------------------------------
          _SettingsSection(
            title: 'About & Support',
            icon: Icons.info_outline,
            children: [
              _SettingsTile(
                icon: Icons.support_agent_outlined,
                title: 'Help & Support',
                subtitle: 'FAQs and ways to reach us',
                onTap: () => context.pushNamed(SupportsWidget.routeName),
              ),
              const _SettingsTile(
                icon: Icons.verified_outlined,
                title: 'App version',
                subtitle: 'Claims Assist  -  v1.0.0',
              ),
            ],
          ),

          // -- Account / danger zone -----------------------------------
          _SettingsSection(
            title: 'Account',
            icon: Icons.manage_accounts_outlined,
            children: [
              _SettingsTile(
                icon: Icons.logout,
                title: 'Log out',
                subtitle: 'Sign out of this device',
                iconColor: Colors.orange.shade800,
                onTap: _signOut,
              ),
              _SettingsTile(
                icon: Icons.delete_forever_outlined,
                title: 'Delete account',
                subtitle: 'Permanently delete your account',
                iconColor: Colors.red.shade600,
                titleColor: Colors.red.shade600,
                onTap: _deleteAccount,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

const Color _kNavy = Color(0xFF002855);

// -- Settings section card ----------------------------------------------------

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Row(
              children: [
                Icon(icon, size: 18, color: brandBlue(context)),
                const SizedBox(width: 8),
                Text(title,
                    style: GoogleFonts.interTight(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: brandBlue(context))),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).secondaryBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: FlutterFlowTheme.of(context).alternate),
            ),
            child: Column(children: _withDividers(children, context)),
          ),
        ],
      ),
    );
  }

  List<Widget> _withDividers(List<Widget> items, BuildContext context) {
    final out = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      out.add(items[i]);
      if (i != items.length - 1) {
        out.add(
            Divider(height: 1, color: FlutterFlowTheme.of(context).alternate));
      }
    }
    return out;
  }
}

// -- Settings tile ------------------------------------------------------------

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.actionLabel,
    this.iconColor,
    this.titleColor,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final String? actionLabel;
  final Color? iconColor;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor ?? brandBlue(context)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: titleColor)),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: Colors.grey)),
                  ],
                ],
              ),
            ),
            if (actionLabel != null)
              Text(actionLabel!,
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: brandBlue(context)))
            else if (onTap != null)
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

// -- Theme segmented toggle ---------------------------------------------------

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle({required this.current, required this.onChanged});
  final ThemeMode current;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget seg(ThemeMode mode, IconData icon, String label) {
      final selected = current == mode;
      return InkWell(
        onTap: () => onChanged(mode),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? _kNavy : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: 16,
                  color: selected ? Colors.white : Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : Colors.grey.shade600)),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).primaryBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          seg(ThemeMode.light, Icons.wb_sunny_outlined, 'Light'),
          seg(ThemeMode.dark, Icons.dark_mode_outlined, 'Dark'),
        ],
      ),
    );
  }
}
