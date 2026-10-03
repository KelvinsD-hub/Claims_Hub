import '/backend/services/staff_access.dart';
import '/components/brand_colors.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
export 'authentication_model.dart';

/// The way in to Claims Hub.
///
/// Three views: signing in (email and password, or Google), resetting a
/// password, and joining from an invite link (`?invite=…`). There is no
/// sign-up: accounts are made only through an admin's invite
/// (lib/backend/services/staff_access.dart).
class AuthenticationWidget extends StatefulWidget {
  const AuthenticationWidget({super.key});

  static String routeName = 'Authentication';
  static String routePath = '/authentication';

  @override
  State<AuthenticationWidget> createState() => _AuthenticationWidgetState();
}

enum _View { signIn, reset, join }

class _AuthenticationWidgetState extends State<AuthenticationWidget> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _showPassword = false;
  bool _busy = false;
  String? _error;
  String? _notice;

  _View _view = _View.signIn;
  String _token = '';
  InviteInfo? _invite;
  bool _inviteLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_token.isNotEmpty) return;
    String? token;
    try {
      token = GoRouterState.of(context).uri.queryParameters['invite'];
    } catch (_) {}
    token ??= Uri.base.queryParameters['invite'];
    if (token != null && token.trim().isNotEmpty) {
      _token = token.trim();
      _view = _View.join;
      _loadInvite();
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _loadInvite() async {
    setState(() => _inviteLoading = true);
    final info = await fetchInvite(_token);
    if (!mounted) return;
    setState(() {
      _invite = info;
      _inviteLoading = false;
      if (info.isOpen) _email.text = info.email;
    });
  }

  void _show(String? error, {String? notice}) {
    if (!mounted) return;
    setState(() {
      _error = error;
      _notice = notice;
      _busy = false;
    });
  }

  void _goHome() {
    if (!mounted) return;
    context.goNamedAuth(HomePageWidget.routeName, context.mounted);
  }

  /// After any sign-in: stay only with approved access.
  Future<void> _admit({bool justJoined = false}) async {
    final refused = await admitSignedInUser(justJoined: justJoined);
    if (refused != null) return _show(refused);
    _goHome();
  }

  // ── Signing in ──────────────────────────────────────────────────────────

  Future<void> _signInWithPassword() async {
    final email = _email.text.trim();
    if (email.isEmpty || _password.text.isEmpty) {
      return _show('Enter your email and password.');
    }
    setState(() => _busy = true);
    GoRouter.of(context).prepareAuthEvent();
    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: _password.text);
    } catch (e) {
      return _show(signInError(e));
    }
    await _admit();
  }

  Future<void> _signInWithGoogle() async {
    GoRouter.of(context).prepareAuthEvent();
    // The pop-up must open before anything else is awaited.
    final pending = googleSignInPopup();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await pending;
    } catch (e) {
      return _show(signInError(e));
    }
    if (_view == _View.join) return _finishJoin(google: true);
    await _admit();
  }

  Future<void> _sendReset() async {
    final email = _email.text.trim();
    if (email.isEmpty)
      return _show('Enter the email address you sign in with.');
    setState(() => _busy = true);
    final error = await sendPasswordReset(email);
    if (error != null) return _show(error);
    _show(null,
        notice: 'If $email has a Claims Hub account, a link to reset its '
            'password is on its way. Check your inbox and spam folder.');
  }

  // ── Joining from an invite ──────────────────────────────────────────────

  Future<void> _joinWithPassword() async {
    final invite = _invite!;
    if (_password.text.length < 8) {
      return _show('Choose a password of at least 8 characters.');
    }
    if (_password.text != _confirm.text) {
      return _show('The two passwords do not match.');
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    GoRouter.of(context).prepareAuthEvent();
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: invite.email, password: _password.text);
    } on FirebaseAuthException catch (e) {
      if (e.code != 'email-already-in-use') return _show(signInError(e));
      // They already have an account at this address: sign in to it instead.
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: invite.email, password: _password.text);
      } catch (_) {
        return _show('You already have an account with ${invite.email}. '
            'Enter its password, or use "Forgot password?" on the sign-in '
            'page and then open this link again.');
      }
    } catch (e) {
      return _show(signInError(e));
    }
    await _finishJoin(google: false);
  }

  Future<void> _finishJoin({required bool google}) async {
    final invite = _invite!;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return _show('Sign-in failed. Please try again.');
    if ((user.email ?? '').toLowerCase() != invite.email) {
      final used = user.email ?? 'that account';
      await dropSignIn();
      return _show('This invite is for ${invite.email}, but you chose $used. '
          '${google ? 'Choose the Google account for ${invite.email}.' : ''}');
    }
    final error = await acceptInvite(_token);
    if (error != null) {
      await dropSignIn();
      return _show(error);
    }
    await _admit(justJoined: true);
  }

  // ── Layout ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Title(
      title: 'Sign in · Claims Hub',
      color: theme.primary.withAlpha(0xFF),
      child: Scaffold(
        backgroundColor: theme.primaryBackground,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Brand(),
                    const SizedBox(height: 22),
                    Container(
                      padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                      decoration: BoxDecoration(
                        color: theme.secondaryBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.alternate),
                      ),
                      child: AutofillGroup(
                        child: switch (_view) {
                          _View.signIn => _signInView(theme),
                          _View.reset => _resetView(theme),
                          _View.join => _joinView(theme),
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _view == _View.join
                          ? 'Claims Assist Limited'
                          : 'New to the team? Accounts are by invitation only. '
                              'Ask an admin to send you an invite link.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          fontSize: 12.5,
                          height: 1.5,
                          color: theme.secondaryText),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _signInView(FlutterFlowTheme theme) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Heading('Sign in', 'For Claims Assist staff.'),
          _GoogleButton(onTap: _busy ? null : _signInWithGoogle),
          const _OrDivider(),
          _Field(
            controller: _email,
            label: 'Email',
            keyboard: TextInputType.emailAddress,
            autofill: const [AutofillHints.email],
            onSubmit: (_) => _signInWithPassword(),
          ),
          const SizedBox(height: 12),
          _Field(
            controller: _password,
            label: 'Password',
            obscure: !_showPassword,
            autofill: const [AutofillHints.password],
            onToggle: () => setState(() => _showPassword = !_showPassword),
            onSubmit: (_) => _signInWithPassword(),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _busy
                  ? null
                  : () => setState(() {
                        _view = _View.reset;
                        _error = null;
                        _notice = null;
                      }),
              style: TextButton.styleFrom(foregroundColor: brandBlue(context)),
              child: Text('Forgot password?',
                  style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
          _Messages(error: _error, notice: _notice),
          _PrimaryButton(
              label: 'Sign in', busy: _busy, onTap: _signInWithPassword),
        ],
      );

  Widget _resetView(FlutterFlowTheme theme) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Heading('Reset your password',
              'We will email you a link to choose a new one.'),
          _Field(
            controller: _email,
            label: 'Email',
            keyboard: TextInputType.emailAddress,
            autofill: const [AutofillHints.email],
            onSubmit: (_) => _sendReset(),
          ),
          const SizedBox(height: 16),
          _Messages(error: _error, notice: _notice),
          _PrimaryButton(
              label: 'Send reset link', busy: _busy, onTap: _sendReset),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() {
              _view = _View.signIn;
              _error = null;
              _notice = null;
            }),
            style: TextButton.styleFrom(foregroundColor: brandBlue(context)),
            child: Text('Back to sign in',
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          Text(
            'Signed up with Google? You have no Claims Hub password: use '
            '"Continue with Google" instead.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 12, height: 1.45, color: theme.secondaryText),
          ),
        ],
      );

  Widget _joinView(FlutterFlowTheme theme) {
    final invite = _invite;
    if (_inviteLoading || invite == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (!invite.isOpen) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Heading('This invite cannot be used', invite.message),
          _PrimaryButton(
            label: 'Go to sign in',
            busy: false,
            onTap: () => setState(() {
              _view = _View.signIn;
              _token = '';
            }),
          ),
        ],
      );
    }
    final until = invite.expiresAt == null
        ? ''
        : ' The link expires on ${dateTimeFormat('d MMMM y', invite.expiresAt)}.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Heading(
          'Join Claims Hub',
          '${invite.invitedBy.isEmpty ? 'You have been' : '${invite.invitedBy} has'} '
              'invited ${invite.name.split(' ').first} to join as '
              '${invite.role}.$until',
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: theme.primaryBackground,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(Icons.mail_outline, size: 18, color: theme.secondaryText),
              const SizedBox(width: 10),
              Expanded(
                child: Text(invite.email,
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.primaryText)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _GoogleButton(onTap: _busy ? null : _signInWithGoogle),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            'Use the Google account for ${invite.email}.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 12, color: theme.secondaryText),
          ),
        ),
        const _OrDivider(label: 'or choose a password'),
        _Field(
          controller: _password,
          label: 'Password (at least 8 characters)',
          obscure: !_showPassword,
          autofill: const [AutofillHints.newPassword],
          onToggle: () => setState(() => _showPassword = !_showPassword),
        ),
        const SizedBox(height: 12),
        _Field(
          controller: _confirm,
          label: 'Type it again',
          obscure: !_showPassword,
          autofill: const [AutofillHints.newPassword],
          onSubmit: (_) => _joinWithPassword(),
        ),
        const SizedBox(height: 16),
        _Messages(error: _error, notice: _notice),
        _PrimaryButton(
            label: 'Create my account', busy: _busy, onTap: _joinWithPassword),
      ],
    );
  }
}

// ── Pieces ─────────────────────────────────────────────────────────────────

class _Brand extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: brandBlue(context),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.flight_takeoff_rounded,
              color: Colors.white, size: 26),
        ),
        const SizedBox(height: 12),
        Text('Claims Hub',
            style: GoogleFonts.interTight(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: theme.primaryText)),
        const SizedBox(height: 2),
        Text('Claims Assist',
            style: GoogleFonts.inter(fontSize: 13, color: theme.secondaryText)),
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.title, this.subtitle);
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.interTight(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: theme.primaryText)),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(subtitle,
                style: GoogleFonts.inter(
                    fontSize: 13.5, height: 1.45, color: theme.secondaryText)),
          ],
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.obscure = false,
    this.keyboard,
    this.autofill = const [],
    this.onToggle,
    this.onSubmit,
  });

  final TextEditingController controller;
  final String label;
  final bool obscure;
  final TextInputType? keyboard;
  final List<String> autofill;
  final VoidCallback? onToggle;
  final ValueChanged<String>? onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    OutlineInputBorder border(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c, width: 1.5),
        );
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      autofillHints: autofill,
      onSubmitted: onSubmit,
      style: GoogleFonts.inter(fontSize: 14.5, color: theme.primaryText),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(fontSize: 14, color: theme.secondaryText),
        filled: true,
        fillColor: theme.secondaryBackground,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: border(theme.alternate),
        focusedBorder: border(brandBlue(context)),
        suffixIcon: onToggle == null
            ? null
            : IconButton(
                tooltip: obscure ? 'Show password' : 'Hide password',
                onPressed: onToggle,
                icon: Icon(
                    obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                    color: theme.secondaryText),
              ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton(
      {required this.label, required this.busy, required this.onTap});
  final String label;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: FilledButton(
        onPressed: busy ? null : onTap,
        style: FilledButton.styleFrom(
          backgroundColor: brandBlue(context),
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2.2, color: Colors.white))
            : Text(label,
                style: GoogleFonts.inter(
                    fontSize: 14.5, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.primaryText,
          side: BorderSide(color: theme.alternate, width: 1.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        icon: const FaIcon(FontAwesomeIcons.google, size: 17),
        label: Text('Continue with Google',
            style:
                GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider({this.label = 'or'});
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        children: [
          Expanded(child: Divider(color: theme.alternate)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(label,
                style: GoogleFonts.inter(
                    fontSize: 12.5, color: theme.secondaryText)),
          ),
          Expanded(child: Divider(color: theme.alternate)),
        ],
      ),
    );
  }
}

class _Messages extends StatelessWidget {
  const _Messages({this.error, this.notice});
  final String? error;
  final String? notice;

  @override
  Widget build(BuildContext context) {
    final text = error ?? notice;
    if (text == null || text.isEmpty) return const SizedBox.shrink();
    final isError = error != null;
    final color = isError ? overdueRed(context) : brandBlue(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(isError ? Icons.error_outline : Icons.mark_email_read_outlined,
              size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.45,
                    color: FlutterFlowTheme.of(context).primaryText)),
          ),
        ],
      ),
    );
  }
}
