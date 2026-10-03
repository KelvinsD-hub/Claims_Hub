import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/services/staff_access.dart';
import '/components/brand_colors.dart';
import '/components/work_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Inviting staff to Claims Hub, on the Staff page: the invite form, the
/// link to pass on by email or WhatsApp, and the invites still waiting.

/// Ask for a new invite. Returns true when one was made.
Future<bool> showInviteStaff(BuildContext context) async {
  final made = await showDialog<bool>(
    context: context,
    builder: (_) => const _InviteDialog(),
  );
  return made == true;
}

/// Show a link that was just made, with ways to pass it on.
Future<void> _showInviteLink(BuildContext context, NewInvite invite,
    {String phone = '', bool askedToEmail = true}) {
  return showDialog<void>(
    context: context,
    builder: (_) =>
        _LinkDialog(invite: invite, phone: phone, askedToEmail: askedToEmail),
  );
}

class _InviteDialog extends StatefulWidget {
  const _InviteDialog();

  @override
  State<_InviteDialog> createState() => _InviteDialogState();
}

class _InviteDialogState extends State<_InviteDialog> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  String _role = 'Agent';
  bool _sendEmail = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty || _email.text.trim().isEmpty) {
      setState(() => _error = 'Give their name and email address.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final (invite, error) = await createInvite(
      name: _name.text,
      email: _email.text,
      role: _role,
      phone: _phone.text,
      sendEmail: _sendEmail,
    );
    if (!mounted) return;
    if (invite == null) {
      setState(() {
        _busy = false;
        _error = error;
      });
      return;
    }
    final navigator = Navigator.of(context);
    final outer = navigator.context;
    navigator.pop(true);
    if (outer.mounted) {
      await _showInviteLink(outer, invite,
          phone: _phone.text, askedToEmail: _sendEmail);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final mine = valueOrDefault(currentUserDocument?.role, '');
    final roles = inviteRoles
        .where((r) => r != 'Super Admin' || mine == 'Super Admin')
        .toList();
    return AlertDialog(
      backgroundColor: theme.secondaryBackground,
      title: Text('Invite staff',
          style: GoogleFonts.interTight(
              fontWeight: FontWeight.w700, color: theme.primaryText)),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'They get a link that works once, for 7 days. Accepting it '
                'gives them access with the role you choose here.',
                style: GoogleFonts.inter(
                    fontSize: 13, height: 1.45, color: theme.secondaryText),
              ),
              const SizedBox(height: 16),
              _input(context, _name, 'Full name'),
              const SizedBox(height: 12),
              _input(context, _email, 'Email address',
                  keyboard: TextInputType.emailAddress),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _role,
                decoration: _decoration(context, 'Role'),
                dropdownColor: theme.secondaryBackground,
                style:
                    GoogleFonts.inter(fontSize: 14, color: theme.primaryText),
                items: [
                  for (final r in roles)
                    DropdownMenuItem(value: r, child: Text(r)),
                ],
                onChanged: (v) => setState(() => _role = v ?? 'Agent'),
              ),
              const SizedBox(height: 12),
              _input(context, _phone, 'WhatsApp number (optional)',
                  keyboard: TextInputType.phone),
              const SizedBox(height: 6),
              CheckboxListTile(
                value: _sendEmail,
                onChanged: (v) => setState(() => _sendEmail = v ?? true),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: brandBlue(context),
                title: Text('Email them the link now',
                    style: GoogleFonts.inter(
                        fontSize: 13.5, color: theme.primaryText)),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(_error!,
                      style: GoogleFonts.inter(
                          fontSize: 13, color: overdueRed(context))),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          style: FilledButton.styleFrom(backgroundColor: brandBlue(context)),
          child: Text(_busy ? 'Creating…' : 'Create invite'),
        ),
      ],
    );
  }
}

class _LinkDialog extends StatelessWidget {
  const _LinkDialog(
      {required this.invite, required this.phone, required this.askedToEmail});
  final NewInvite invite;
  final String phone;
  final bool askedToEmail;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final emailLine = invite.emailed
        ? 'We emailed the link to ${invite.email}.'
        : askedToEmail
            ? 'The email could not be sent. Copy the link or send it on WhatsApp.'
            : 'Nothing has been sent yet. Copy the link or send it on WhatsApp.';
    final message = inviteWhatsAppText(
        name: invite.name, role: invite.role, link: invite.link);
    return AlertDialog(
      backgroundColor: theme.secondaryBackground,
      title: Text('Invite ready for ${invite.name}',
          style: GoogleFonts.interTight(
              fontWeight: FontWeight.w700, color: theme.primaryText)),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('${invite.role} · ${invite.email}',
                style: GoogleFonts.inter(
                    fontSize: 13, color: theme.secondaryText)),
            const SizedBox(height: 10),
            Text(emailLine,
                style: GoogleFonts.inter(
                    fontSize: 13.5,
                    color: invite.emailed || !askedToEmail
                        ? theme.primaryText
                        : overdueRed(context))),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.primaryBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.alternate),
              ),
              child: SelectableText(invite.link,
                  style: GoogleFonts.robotoMono(
                      fontSize: 12, color: theme.primaryText)),
            ),
            const SizedBox(height: 10),
            Text(
              'Anyone with this link can join as ${invite.role} if they sign '
              'in with ${invite.email}. Send it only to them.',
              style: GoogleFonts.inter(
                  fontSize: 12, height: 1.45, color: theme.secondaryText),
            ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: invite.link));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invite link copied')));
            }
          },
          icon: const Icon(Icons.copy_rounded, size: 16),
          label: const Text('Copy link'),
        ),
        TextButton.icon(
          onPressed: () => launchURL(whatsAppLink(message, phone: phone)),
          icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 16),
          label: const Text('Send on WhatsApp'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          style: FilledButton.styleFrom(backgroundColor: brandBlue(context)),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

InputDecoration _decoration(BuildContext context, String label) {
  final theme = FlutterFlowTheme.of(context);
  OutlineInputBorder border(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: c, width: 1.5));
  return InputDecoration(
    labelText: label,
    labelStyle: GoogleFonts.inter(fontSize: 13.5, color: theme.secondaryText),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    enabledBorder: border(theme.alternate),
    focusedBorder: border(brandBlue(context)),
  );
}

Widget _input(BuildContext context, TextEditingController c, String label,
        {TextInputType? keyboard}) =>
    TextField(
      controller: c,
      keyboardType: keyboard,
      style: GoogleFonts.inter(
          fontSize: 14, color: FlutterFlowTheme.of(context).primaryText),
      decoration: _decoration(context, label),
    );

/// The invites not yet used, with a new link or a cancel for each.
class PendingInvitesPanel extends StatefulWidget {
  const PendingInvitesPanel({super.key});

  @override
  State<PendingInvitesPanel> createState() => PendingInvitesPanelState();
}

class PendingInvitesPanelState extends State<PendingInvitesPanel> {
  List<PendingInvite> _invites = const [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    setState(() => _loading = true);
    final (list, error) = await listInvites();
    if (!mounted) return;
    setState(() {
      _invites = list;
      _error = error;
      _loading = false;
    });
  }

  Future<void> _newLink(PendingInvite x) async {
    final (invite, error) = await createInvite(
        name: x.name,
        email: x.email,
        role: x.role,
        phone: x.phone,
        sendEmail: false);
    if (!mounted) return;
    if (invite == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error ?? 'Failed.')));
      return;
    }
    await _showInviteLink(context, invite, phone: x.phone, askedToEmail: false);
    reload();
  }

  Future<void> _cancel(PendingInvite x) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Cancel the invite to ${x.name}?'),
        content: const Text('Their link will stop working.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Keep it')),
          FilledButton(
              onPressed: () => Navigator.pop(c, true),
              style:
                  FilledButton.styleFrom(backgroundColor: overdueRed(context)),
              child: const Text('Cancel invite')),
        ],
      ),
    );
    if (sure != true) return;
    final error = await revokeInvite(x.id);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
    reload();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    if (_loading && _invites.isEmpty) return const SizedBox.shrink();
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Text('Invites could not be loaded: $_error',
            style: GoogleFonts.inter(fontSize: 13, color: overdueRed(context))),
      );
    }
    if (_invites.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 28),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.alternate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
            child: Text('Waiting to join (${_invites.length})',
                style: GoogleFonts.interTight(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: theme.primaryText)),
          ),
          for (final x in _invites)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: theme.alternate))),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${x.name} · ${x.role}',
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: theme.primaryText)),
                        const SizedBox(height: 2),
                        Text(
                          '${x.email}'
                          '${x.invitedBy.isEmpty ? '' : ' · invited by ${x.invitedBy}'}'
                          ' · ${x.expired ? 'link expired' : 'expires ${dateTimeFormat('d MMM', x.expiresAt)}'}',
                          style: GoogleFonts.inter(
                              fontSize: 12.5,
                              color: x.expired
                                  ? overdueRed(context)
                                  : theme.secondaryText),
                        ),
                      ],
                    ),
                  ),
                  WorkButton(
                      label: 'New link',
                      icon: Icons.link_rounded,
                      onTap: () => _newLink(x)),
                  const SizedBox(width: 8),
                  WorkButton(
                      label: 'Cancel',
                      icon: Icons.close_rounded,
                      onTap: () => _cancel(x)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
