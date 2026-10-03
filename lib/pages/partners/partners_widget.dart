import '/backend/backend.dart';
import '/backend/services/links.dart';
import '/backend/services/partners.dart';
import '/components/work_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Referral partners: who they are, their links, what they have brought in,
/// and inviting, suspending and restoring them. Admins only.
///
/// A partner signs in to their own page on the website with an emailed link,
/// and sees only first names and how far each referral has got
/// (functions/partners.js).
class PartnersWidget extends StatefulWidget {
  const PartnersWidget({super.key});

  static String routeName = 'Partners';
  static String routePath = '/partners';

  @override
  State<PartnersWidget> createState() => _PartnersWidgetState();
}

class _PartnersWidgetState extends State<PartnersWidget> {
  late final Stream<List<ReferralPartner>> _partners = referralPartners();
  late final Stream<List<CampaignLink>> _links = campaignLinks();
  late final Stream<List<LeadsRecord>> _leads = queryLeadsRecord();
  late final Stream<List<ClaimsRecord>> _claims = queryClaimsRecord();

  static String _text(Map<String, dynamic> d, String key) =>
      d[key] is String ? (d[key] as String).trim() : '';

  @override
  Widget build(BuildContext context) {
    return WorkScaffold(
      page: WorkPage.partners,
      title: 'Referral partners',
      subtitle: 'People who bring in clients through their own link',
      icon: Icons.handshake_outlined,
      actions: [
        WorkButton(
          icon: Icons.person_add_alt_1_outlined,
          label: 'Invite a partner',
          filled: true,
          onTap: () => showDialog<void>(
              context: context, builder: (_) => const _InviteDialog()),
        ),
      ],
      child: StreamBuilder<List<ReferralPartner>>(
        stream: _partners,
        builder: (context, partners) => StreamBuilder<List<CampaignLink>>(
          stream: _links,
          builder: (context, links) => StreamBuilder<List<LeadsRecord>>(
            stream: _leads,
            builder: (context, leads) => StreamBuilder<List<ClaimsRecord>>(
              stream: _claims,
              builder: (context, claims) {
                if (partners.hasError) {
                  return const WorkEmpty('The partners could not be loaded.');
                }
                if (!partners.hasData ||
                    !links.hasData ||
                    !leads.hasData ||
                    !claims.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final stats = linkStats(
                  links.data!.where((l) => l.channel == 'partner').toList(),
                  [
                    for (final l in leads.data!)
                      LeadFact(
                        sourceLink: _text(l.snapshotData, 'source_link'),
                        utmSource: l.utmSource,
                        signed: l.loaSigned,
                        qualified: l.claimRef != null,
                      ),
                  ],
                  [
                    for (final c in claims.data!)
                      ClaimFact(
                        sourceLink: _text(c.snapshotData, 'source_link'),
                        stage: c.claimStatus,
                        recovered:
                            (c.snapshotData['amount_recovered'] as num?)
                                    ?.toDouble() ??
                                0,
                      ),
                  ],
                ).links;
                final byCode = {for (final s in stats) s.link.code: s};
                return _content(context, partners.data!, byCode);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, List<ReferralPartner> partners,
      Map<String, LinkStats> stats) {
    final theme = FlutterFlowTheme.of(context);
    final small = GoogleFonts.inter(fontSize: 12.0, color: theme.secondaryText);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 24.0),
      children: [
        Text(
          'A partner shares their link; everyone who claims through it is '
          'credited to them. They sign in to claimsassistltd.com/partner with '
          'a link emailed to them and see first names and how far each claim '
          'has got. They never see contact details, documents or amounts, and '
          'cannot change anything.',
          style: small,
        ),
        const SizedBox(height: 16.0),
        const Row(
          children: [
            Expanded(flex: 4, child: WorkColumnHead('Partner')),
            Expanded(flex: 5, child: WorkColumnHead('Link')),
            Expanded(flex: 2, child: WorkColumnHead('Clicks')),
            Expanded(flex: 2, child: WorkColumnHead('Referred')),
            Expanded(flex: 2, child: WorkColumnHead('Signed')),
            Expanded(flex: 2, child: WorkColumnHead('Claims')),
            Expanded(flex: 2, child: WorkColumnHead('Won')),
            Expanded(flex: 3, child: WorkColumnHead('Status')),
            SizedBox(width: 40.0),
          ],
        ),
        const SizedBox(height: 6.0),
        if (partners.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32.0),
            child: WorkEmpty('No referral partners yet.'),
          ),
        for (final p in partners) ...[
          Divider(height: 1.0, color: theme.alternate),
          _PartnerRow(partner: p, stats: stats[p.code]),
        ],
      ],
    );
  }
}

class _PartnerRow extends StatelessWidget {
  const _PartnerRow({required this.partner, required this.stats});

  final ReferralPartner partner;
  final LinkStats? stats;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final main = GoogleFonts.inter(
        fontSize: 13.0,
        color: partner.suspended ? theme.secondaryText : theme.primaryText);
    final small = GoogleFonts.inter(fontSize: 12.0, color: theme.secondaryText);
    Widget n(int? v) => Text('${v ?? 0}',
        style: main.copyWith(fontWeight: FontWeight.w600));
    final (statusText, statusDetail) = switch (partner.status) {
      'active' => (
          'Active',
          partner.lastSeenAt != null
              ? 'last seen ${dateTimeFormat('relative', partner.lastSeenAt)}'
              : ''
        ),
      'suspended' => ('Suspended', ''),
      _ => ('Invited', 'has not signed in yet'),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(partner.name,
                    overflow: TextOverflow.ellipsis,
                    style: main.copyWith(fontWeight: FontWeight.w700)),
                Text(
                  [partner.email, partner.phone]
                      .where((s) => s.isNotEmpty)
                      .join('  ·  '),
                  overflow: TextOverflow.ellipsis,
                  style: small,
                ),
              ],
            ),
          ),
          Expanded(
            flex: 5,
            child: Row(
              children: [
                Flexible(
                  child: SelectableText(partner.link,
                      maxLines: 1, style: main.copyWith(fontSize: 12.5)),
                ),
                IconButton(
                  tooltip: 'Copy link',
                  icon: const Icon(Icons.copy_rounded, size: 17.0),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: partner.link));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('${partner.name}\'s link copied'),
                        duration: const Duration(seconds: 2)));
                  },
                ),
              ],
            ),
          ),
          Expanded(flex: 2, child: n(stats?.link.clicks)),
          Expanded(flex: 2, child: n(stats?.leads)),
          Expanded(flex: 2, child: n(stats?.signed)),
          Expanded(flex: 2, child: n(stats?.claims)),
          Expanded(flex: 2, child: n(stats?.won)),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(statusText, style: main),
                if (statusDetail.isNotEmpty) Text(statusDetail, style: small),
              ],
            ),
          ),
          SizedBox(
            width: 40.0,
            child: PopupMenuButton<String>(
              tooltip: 'More',
              icon: Icon(Icons.more_vert,
                  size: 19.0, color: theme.secondaryText),
              itemBuilder: (_) => [
                if (!partner.suspended)
                  const PopupMenuItem(
                      value: 'resend', child: Text('Send a sign-in link')),
                PopupMenuItem(
                  value: partner.suspended ? 'restore' : 'suspend',
                  child: Text(partner.suspended ? 'Restore' : 'Suspend'),
                ),
              ],
              onSelected: (action) => _act(context, action),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _act(BuildContext context, String action) async {
    final messenger = ScaffoldMessenger.of(context);
    if (action == 'resend') {
      final result = await resendPartnerLink(partner.id);
      if (!context.mounted) return;
      if (result.succeeded) {
        await showDialog<void>(
            context: context,
            builder: (_) => _SentDialog(result: result, name: partner.name));
      } else {
        messenger.showSnackBar(SnackBar(content: Text(result.error!)));
      }
      return;
    }
    final suspend = action == 'suspend';
    if (suspend) {
      final sure = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('Suspend ${partner.name}?'),
          content: const Text(
              'Their partner page closes and new clients through their link '
              'are no longer credited to them. Referrals already made stay '
              'credited. You can restore them later.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Suspend')),
          ],
        ),
      );
      if (sure != true) return;
    }
    final error = await setPartnerActive(partner.id, !suspend);
    messenger.showSnackBar(SnackBar(
        content: Text(error ??
            (suspend
                ? '${partner.name} is suspended.'
                : '${partner.name} is restored.'))));
  }
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

  Future<void> _send() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await invitePartner(
      name: _name.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      sendEmail: _sendEmail,
    );
    if (!mounted) return;
    if (result.succeeded) {
      final name = _name.text.trim();
      Navigator.pop(context);
      await showDialog<void>(
          context: context,
          builder: (_) => _SentDialog(result: result, name: name));
      return;
    }
    setState(() {
      _busy = false;
      _error = result.error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final label = GoogleFonts.inter(fontSize: 12.0, color: theme.secondaryText);
    InputDecoration box(String hint) => InputDecoration(
          isDense: true,
          hintText: hint,
          border: const OutlineInputBorder(),
        );
    final ready = _name.text.trim().isNotEmpty && _email.text.contains('@');
    return AlertDialog(
      title: const Text('Invite a referral partner'),
      content: SizedBox(
        width: 420.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name', style: label),
            const SizedBox(height: 6.0),
            TextField(
                controller: _name,
                decoration: box('e.g. Tunde Bakare'),
                onChanged: (_) => setState(() {})),
            const SizedBox(height: 12.0),
            Text('Email (they sign in with it)', style: label),
            const SizedBox(height: 6.0),
            TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: box('tunde@example.com'),
                onChanged: (_) => setState(() {})),
            const SizedBox(height: 12.0),
            Text('Phone (optional)', style: label),
            const SizedBox(height: 6.0),
            TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: box('+234 …')),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _sendEmail,
              onChanged: (v) => setState(() => _sendEmail = v ?? true),
              title: Text('Email them the invitation',
                  style: GoogleFonts.inter(fontSize: 13.0)),
            ),
            if (_error != null)
              Text(_error!,
                  style: GoogleFonts.inter(fontSize: 13.0, color: theme.error)),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: _busy || !ready ? null : _send,
          child: Text(_busy ? 'Inviting…' : 'Invite'),
        ),
      ],
    );
  }
}

/// After an invite or a fresh sign-in link: what went out, and both links to
/// copy into WhatsApp.
class _SentDialog extends StatelessWidget {
  const _SentDialog({required this.result, required this.name});

  final PartnerInviteResult result;
  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final label = GoogleFonts.inter(fontSize: 12.0, color: theme.secondaryText);
    Widget copy(String title, String value, String note) => Padding(
          padding: const EdgeInsets.only(top: 14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.inter(
                      fontSize: 13.0, fontWeight: FontWeight.w600)),
              Row(
                children: [
                  Expanded(
                    child: SelectableText(value,
                        maxLines: 2, style: GoogleFonts.inter(fontSize: 12.0)),
                  ),
                  IconButton(
                    tooltip: 'Copy',
                    icon: const Icon(Icons.copy_rounded, size: 17.0),
                    onPressed: () =>
                        Clipboard.setData(ClipboardData(text: value)),
                  ),
                ],
              ),
              Text(note, style: label),
            ],
          ),
        );
    return AlertDialog(
      title: Text(result.emailed ? 'Sent to $name' : 'Ready for $name'),
      content: SizedBox(
        width: 480.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.emailed
                  ? 'Emailed to ${result.email}. You can also send these by WhatsApp.'
                  : 'No email went to ${result.email}. Send these by WhatsApp or text.',
              style: GoogleFonts.inter(fontSize: 13.0),
            ),
            copy('Their referral link', result.link!,
                'For passengers. Everyone who claims through it is credited to $name.'),
            copy('Their sign-in link', result.signIn!,
                'For $name only: opens their partner page. Works once, for a limited time.'),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('Done')),
      ],
    );
  }
}
