import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/services/links.dart';
import '/components/case_file_widget.dart' show naira;
import '/components/work_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Short links for ads and posts, and what each one has brought in: clicks,
/// leads, signed authorities, claims, claims won and money recovered.
///
/// Counted live from the links, leads and claims (services/links.dart).
class LinksWidget extends StatefulWidget {
  const LinksWidget({super.key});

  static String routeName = 'Links';
  static String routePath = '/links';

  @override
  State<LinksWidget> createState() => _LinksWidgetState();
}

class _LinksWidgetState extends State<LinksWidget> {
  late final Stream<List<CampaignLink>> _links = campaignLinks();
  late final Stream<List<LeadsRecord>> _leads = queryLeadsRecord();
  late final Stream<List<ClaimsRecord>> _claims = queryClaimsRecord();

  static String _text(Map<String, dynamic> d, String key) =>
      d[key] is String ? (d[key] as String).trim() : '';

  @override
  Widget build(BuildContext context) {
    return WorkScaffold(
      page: WorkPage.links,
      title: 'Links',
      subtitle: 'Short links for ads and posts, and what each one brings in',
      icon: Icons.link,
      actions: [
        WorkButton(
          icon: Icons.add_link,
          label: 'New link',
          filled: true,
          onTap: () => showDialog<void>(
              context: context, builder: (_) => const _NewLinkDialog()),
        ),
      ],
      child: StreamBuilder<List<CampaignLink>>(
        stream: _links,
        builder: (context, links) => StreamBuilder<List<LeadsRecord>>(
          stream: _leads,
          builder: (context, leads) => StreamBuilder<List<ClaimsRecord>>(
            stream: _claims,
            builder: (context, claims) {
              if (links.hasError || leads.hasError || claims.hasError) {
                return const WorkEmpty('The links could not be loaded.');
              }
              if (!links.hasData || !leads.hasData || !claims.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final stats = linkStats(
                links.data!,
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
              );
              return _content(context, stats);
            },
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context,
      ({List<LinkStats> links, List<OtherSource> others}) stats) {
    final theme = FlutterFlowTheme.of(context);
    final small = GoogleFonts.inter(fontSize: 12.0, color: theme.secondaryText);
    final existing = {for (final s in stats.links) s.link.code};
    final missingStandard = _standard.keys.where((c) => !existing.contains(c));

    return ListView(
      padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 24.0),
      children: [
        Text(
          'Copy a link into an ad or post. A click is counted when a person '
          'opens it (not when Facebook, WhatsApp or X draws a preview), and '
          'anyone who claims within 30 days is credited to the link.',
          style: small,
        ),
        if (missingStandard.isNotEmpty) ...[
          const SizedBox(height: 12.0),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Quick start:', style: small),
              WorkButton(
                icon: Icons.bolt_outlined,
                label: stats.links.isEmpty
                    ? 'Make a link for each social network'
                    : 'Add the missing networks (${missingStandard.map((c) => _standard[c]!.$1).join(', ')})',
                onTap: () => _makeStandard(context, missingStandard.toList()),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16.0),
        const Row(
          children: [
            Expanded(flex: 4, child: WorkColumnHead('Link')),
            Expanded(flex: 5, child: WorkColumnHead('Address')),
            Expanded(flex: 2, child: WorkColumnHead('Clicks')),
            Expanded(flex: 2, child: WorkColumnHead('Leads')),
            Expanded(flex: 2, child: WorkColumnHead('Signed')),
            Expanded(flex: 2, child: WorkColumnHead('Claims')),
            Expanded(flex: 2, child: WorkColumnHead('Won')),
            Expanded(flex: 3, child: WorkColumnHead('Recovered')),
            SizedBox(width: 56.0),
          ],
        ),
        const SizedBox(height: 6.0),
        if (stats.links.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32.0),
            child: WorkEmpty('No links yet. Make one for each place you advertise.'),
          ),
        for (final s in stats.links) ...[
          Divider(height: 1.0, color: theme.alternate),
          _LinkRow(stats: s),
        ],
        if (stats.links.isNotEmpty) ...[
          Divider(height: 1.0, color: theme.alternate),
          _TotalRow(stats.links),
        ],
        if (stats.others.isNotEmpty) ...[
          const FileSection('Leads that came another way'),
          Text(
            'Leads from before links existed, from people who found the site '
            'themselves, and from hand-made ?source= addresses.',
            style: small,
          ),
          const SizedBox(height: 8.0),
          for (final o in stats.others)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Expanded(
                      flex: 4,
                      child: Text(o.name,
                          style: GoogleFonts.inter(
                              fontSize: 13.0, color: theme.primaryText))),
                  Expanded(
                      flex: 2,
                      child: Text('${o.leads} lead${o.leads == 1 ? '' : 's'}',
                          style: small)),
                  Expanded(flex: 2, child: Text('${o.signed} signed', style: small)),
                  const Spacer(flex: 10),
                ],
              ),
            ),
        ],
      ],
    );
  }

  /// One link for each main network, named the same way every time.
  static const _standard = <String, (String, String)>{
    'fb': ('Facebook', 'facebook'),
    'ig': ('Instagram', 'instagram'),
    'x': ('X', 'x'),
    'tt': ('TikTok', 'tiktok'),
    'wa': ('WhatsApp', 'whatsapp'),
  };

  Future<void> _makeStandard(BuildContext context, List<String> codes) async {
    final messenger = ScaffoldMessenger.of(context);
    final errors = <String>[];
    for (final code in codes) {
      final (label, channel) = _standard[code]!;
      final error = await createCampaignLink(
        code: code,
        label: label,
        channel: channel,
        destination: '/',
        uid: currentUserUid,
        name: currentUserDisplayName,
      );
      if (error != null) errors.add('$label: $error');
    }
    messenger.showSnackBar(SnackBar(
        content: Text(errors.isEmpty
            ? 'Links made. Copy each one into that network\'s ads and posts.'
            : errors.join('\n'))));
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({required this.stats});

  final LinkStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final link = stats.link;
    final main = GoogleFonts.inter(
        fontSize: 13.0,
        color: link.active ? theme.primaryText : theme.secondaryText);
    final small = GoogleFonts.inter(fontSize: 12.0, color: theme.secondaryText);
    final rate = stats.leadRate;
    final isPartner = link.channel == 'partner';

    Widget number(int n, [String? under]) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$n', style: main.copyWith(fontWeight: FontWeight.w600)),
            if (under != null) Text(under, style: small),
          ],
        );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(link.label,
                    overflow: TextOverflow.ellipsis,
                    style: main.copyWith(fontWeight: FontWeight.w700)),
                Text(
                  [
                    channelName(link.channel),
                    if (link.destination == '/check') 'opens the claim check',
                    if (!link.active) 'switched off',
                  ].join('  ·  '),
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
                  child: SelectableText(link.url,
                      maxLines: 1, style: main.copyWith(fontSize: 12.5)),
                ),
                IconButton(
                  tooltip: 'Copy link',
                  icon: const Icon(Icons.copy_rounded, size: 17.0),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: link.url));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('${link.label} link copied'),
                        duration: const Duration(seconds: 2)));
                  },
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: number(
                link.clicks,
                link.lastClickAt == null
                    ? 'never'
                    : 'last ${dateTimeFormat('relative', link.lastClickAt)}'),
          ),
          Expanded(
            flex: 2,
            child: number(stats.leads,
                rate == null ? null : '${(rate * 100).toStringAsFixed(rate < 0.1 ? 1 : 0)}% of clicks'),
          ),
          Expanded(flex: 2, child: number(stats.signed)),
          Expanded(flex: 2, child: number(stats.claims)),
          Expanded(flex: 2, child: number(stats.won)),
          Expanded(
            flex: 3,
            child: Text(stats.recovered == 0 ? '—' : naira(stats.recovered),
                style: main),
          ),
          SizedBox(
            width: 56.0,
            child: isPartner
                ? const SizedBox.shrink()
                : Switch(
                    value: link.active,
                    onChanged: (on) async {
                      final messenger = ScaffoldMessenger.of(context);
                      final error = await setCampaignLinkActive(link.code, on);
                      messenger.showSnackBar(SnackBar(
                          content: Text(error ??
                              (on
                                  ? 'Link switched on.'
                                  : 'Link switched off. It now goes to the home page and credits nobody.'))));
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow(this.all);

  final List<LinkStats> all;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final bold = GoogleFonts.inter(
        fontSize: 13.0, fontWeight: FontWeight.w700, color: theme.primaryText);
    int sum(int Function(LinkStats) f) => all.fold(0, (t, s) => t + f(s));
    final recovered = all.fold<double>(0, (t, s) => t + s.recovered);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text('All links', style: bold)),
          const Spacer(flex: 5),
          Expanded(flex: 2, child: Text('${sum((s) => s.link.clicks)}', style: bold)),
          Expanded(flex: 2, child: Text('${sum((s) => s.leads)}', style: bold)),
          Expanded(flex: 2, child: Text('${sum((s) => s.signed)}', style: bold)),
          Expanded(flex: 2, child: Text('${sum((s) => s.claims)}', style: bold)),
          Expanded(flex: 2, child: Text('${sum((s) => s.won)}', style: bold)),
          Expanded(
              flex: 3,
              child: Text(recovered == 0 ? '—' : naira(recovered), style: bold)),
          const SizedBox(width: 56.0),
        ],
      ),
    );
  }
}

class _NewLinkDialog extends StatefulWidget {
  const _NewLinkDialog();

  @override
  State<_NewLinkDialog> createState() => _NewLinkDialogState();
}

class _NewLinkDialogState extends State<_NewLinkDialog> {
  final _label = TextEditingController();
  final _code = TextEditingController();
  String _channel = 'facebook';
  String _destination = '/';
  bool _codeTouched = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _label.dispose();
    _code.dispose();
    super.dispose();
  }

  void _suggest() {
    if (_codeTouched) return;
    final prefix = linkChannels[_channel]!.$2;
    final rest = suggestCode(_label.text)
        .replaceFirst(RegExp('^${RegExp.escape(_channel)}-?'), '')
        .replaceFirst(RegExp('^${RegExp.escape(prefix)}-?'), '');
    _code.text = suggestCode(rest.isEmpty ? prefix : '$prefix-$rest');
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await createCampaignLink(
      code: _code.text.trim(),
      label: _label.text.trim(),
      channel: _channel,
      destination: _destination,
      uid: currentUserUid,
      name: currentUserDisplayName,
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _busy = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final label = GoogleFonts.inter(fontSize: 12.0, color: theme.secondaryText);
    final ready =
        _label.text.trim().isNotEmpty && linkCodePattern.hasMatch(_code.text.trim());
    return AlertDialog(
      title: const Text('New link'),
      content: SizedBox(
        width: 440.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Where it will be used', style: label),
            const SizedBox(height: 6.0),
            DropdownButtonFormField<String>(
              initialValue: _channel,
              isDense: true,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: [
                for (final e in linkChannels.entries)
                  DropdownMenuItem(value: e.key, child: Text(e.value.$1)),
              ],
              onChanged: (v) => setState(() {
                _channel = v ?? 'other';
                _suggest();
              }),
            ),
            const SizedBox(height: 14.0),
            Text('Name, for this page', style: label),
            const SizedBox(height: 6.0),
            TextField(
              controller: _label,
              maxLength: 80,
              decoration: const InputDecoration(
                isDense: true,
                counterText: '',
                hintText: 'e.g. Facebook October delays ad',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(_suggest),
            ),
            const SizedBox(height: 14.0),
            Text('Link', style: label),
            const SizedBox(height: 6.0),
            TextField(
              controller: _code,
              maxLength: 32,
              decoration: const InputDecoration(
                isDense: true,
                counterText: '',
                prefixText: linkBase,
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() => _codeTouched = true),
            ),
            const SizedBox(height: 4.0),
            Text(
                'Lower case letters, numbers and dashes. It cannot be changed later.',
                style: label),
            const SizedBox(height: 14.0),
            Text('Where it opens', style: label),
            const SizedBox(height: 6.0),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: '/', label: Text('Home page')),
                ButtonSegment(value: '/check', label: Text('Claim check')),
              ],
              selected: {_destination},
              onSelectionChanged: (v) => setState(() => _destination = v.first),
            ),
            const SizedBox(height: 10.0),
            if (_error != null)
              Text(_error!,
                  style: GoogleFonts.inter(fontSize: 13.0, color: theme.error)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _busy || !ready ? null : _save,
          child: Text(_busy ? 'Saving…' : 'Make link'),
        ),
      ],
    );
  }
}
