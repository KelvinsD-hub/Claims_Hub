import 'package:cloud_firestore/cloud_firestore.dart';

import 'pipeline.dart';

/// Short links for ads and posts: claimsassistltd.com/go/<code>.
///
/// Managers make them on the Links page. The website's `go` function counts
/// a click from a person (not a link preview) and sends them to the site,
/// which remembers the link for 30 days and puts its code on any lead they
/// submit as `source_link`; qualifying the lead copies it onto the claim.
/// The figures here are counted from those leads and claims, so they always
/// match the records.

const linkBase = 'https://claimsassistltd.com/go/';

/// Where a link can be used, in the order the dialog offers them, and the
/// code it suggests. Must match the list in firestore.rules.
const linkChannels = <String, (String, String)>{
  'facebook': ('Facebook', 'fb'),
  'instagram': ('Instagram', 'ig'),
  'x': ('X (Twitter)', 'x'),
  'tiktok': ('TikTok', 'tt'),
  'whatsapp': ('WhatsApp', 'wa'),
  'linkedin': ('LinkedIn', 'in'),
  'youtube': ('YouTube', 'yt'),
  'google': ('Google', 'gg'),
  'email': ('Email', 'mail'),
  'sms': ('Text message', 'sms'),
  'other': ('Other', 'link'),
};

String channelName(String channel) => channel == 'partner'
    ? 'Referral partner'
    : (linkChannels[channel]?.$1 ?? channel);

/// A code the rules accept: lower case letters, digits and dashes, 2 to 32.
final linkCodePattern = RegExp(r'^[a-z0-9][a-z0-9-]{1,31}$');

/// [text] made into a code: "Facebook October" → "facebook-october".
String suggestCode(String text) {
  var code = text
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  if (code.length > 32) {
    code = code.substring(0, 32).replaceAll(RegExp(r'-+$'), '');
  }
  return code;
}

/// One link as stored.
class CampaignLink {
  const CampaignLink({
    required this.code,
    required this.label,
    required this.channel,
    required this.destination,
    required this.active,
    required this.clicks,
    this.lastClickAt,
    this.createdAt,
    this.createdByName = '',
  });

  factory CampaignLink.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    DateTime? date(dynamic v) => v is Timestamp ? v.toDate() : null;
    return CampaignLink(
      code: doc.id,
      label: d['label'] as String? ?? doc.id,
      channel: d['channel'] as String? ?? 'other',
      destination: d['destination'] as String? ?? '/',
      active: d['active'] != false,
      clicks: (d['clicks'] as num?)?.toInt() ?? 0,
      lastClickAt: date(d['last_click_at']),
      createdAt: date(d['created_at']),
      createdByName: d['created_by_name'] as String? ?? '',
    );
  }

  final String code;
  final String label;
  final String channel;
  final String destination;
  final bool active;
  final int clicks;
  final DateTime? lastClickAt;
  final DateTime? createdAt;
  final String createdByName;

  String get url => '$linkBase$code';
}

/// What a lead tells the counts.
class LeadFact {
  const LeadFact({
    required this.sourceLink,
    required this.utmSource,
    required this.signed,
    required this.qualified,
  });
  final String sourceLink;
  final String utmSource;
  final bool signed;
  final bool qualified;
}

/// What a claim tells the counts.
class ClaimFact {
  const ClaimFact({
    required this.sourceLink,
    required this.stage,
    this.recovered = 0,
  });
  final String sourceLink;
  final String stage;
  final double recovered;
}

/// The figures for one link.
class LinkStats {
  LinkStats(this.link);
  final CampaignLink link;
  int leads = 0;
  int signed = 0;
  int claims = 0;
  int won = 0;
  double recovered = 0;

  /// Leads per click, or null before anyone has clicked.
  double? get leadRate => link.clicks == 0 ? null : leads / link.clicks;
}

/// Leads that came some other way, by what the website recorded.
class OtherSource {
  OtherSource(this.source);
  final String source;
  int leads = 0;
  int signed = 0;

  /// How the source reads on the page.
  String get name => switch (source) {
        '' || 'claims-assist-site' => 'Website, no link',
        _ => source,
      };
}

/// Counts for every link, plus the leads that came in without one.
({List<LinkStats> links, List<OtherSource> others}) linkStats(
  List<CampaignLink> links,
  List<LeadFact> leads,
  List<ClaimFact> claims,
) {
  final byCode = {for (final l in links) l.code: LinkStats(l)};
  final others = <String, OtherSource>{};
  for (final lead in leads) {
    final stats = byCode[lead.sourceLink];
    if (stats != null) {
      stats.leads++;
      if (lead.signed) stats.signed++;
      if (lead.qualified) stats.claims++;
    } else {
      final raw = lead.sourceLink.isNotEmpty ? lead.sourceLink : lead.utmSource;
      // Older leads left the source blank; newer ones say the site's name.
      final key = raw == 'claims-assist-site' ? '' : raw;
      final other = others.putIfAbsent(key, () => OtherSource(key));
      other.leads++;
      if (lead.signed) other.signed++;
    }
  }
  for (final claim in claims) {
    final stats = byCode[claim.sourceLink];
    if (stats == null) continue;
    final stage = canonicalStage(RecordKind.claim, claim.stage);
    if (stage == ClaimStage.won || stage == ClaimStage.paid) {
      stats.won++;
      stats.recovered += claim.recovered;
    }
  }
  final list = byCode.values.toList()
    ..sort((a, b) {
      if (a.link.active != b.link.active) return a.link.active ? -1 : 1;
      final byLeads = b.leads.compareTo(a.leads);
      return byLeads != 0 ? byLeads : b.link.clicks.compareTo(a.link.clicks);
    });
  final rest = others.values.toList()
    ..sort((a, b) => b.leads.compareTo(a.leads));
  return (links: list, others: rest);
}

/// Every link, newest first.
Stream<List<CampaignLink>> campaignLinks() => FirebaseFirestore.instance
    .collection('campaign_links')
    .snapshots()
    .map((s) => s.docs.map(CampaignLink.fromDoc).toList()
      ..sort((a, b) => (b.createdAt ?? DateTime.now())
          .compareTo(a.createdAt ?? DateTime.now())));

/// Make a link. Returns an error message, or null when it worked.
Future<String?> createCampaignLink({
  required String code,
  required String label,
  required String channel,
  required String destination,
  required String uid,
  required String name,
}) async {
  if (!linkCodePattern.hasMatch(code)) {
    return 'Use 2 to 32 lower case letters, numbers and dashes for the code.';
  }
  final ref =
      FirebaseFirestore.instance.collection('campaign_links').doc(code);
  try {
    // The rules refuse an update with these fields, so a taken code fails
    // here rather than overwriting someone else's link.
    final taken = await ref.get();
    if (taken.exists) return 'The code "$code" is taken. Choose another.';
    await ref.set({
      'label': label.trim(),
      'channel': channel,
      'destination': destination,
      'active': true,
      'clicks': 0,
      'created_at': FieldValue.serverTimestamp(),
      'created_by': uid,
      'created_by_name': name,
    });
    return null;
  } on FirebaseException catch (e) {
    return e.code == 'permission-denied'
        ? 'Only managers and admins can make links.'
        : 'The link could not be saved (${e.code}).';
  }
}

/// Switch a link on or off. An off link still lands on the home page, but
/// counts nothing and credits nobody.
Future<String?> setCampaignLinkActive(String code, bool active) async {
  try {
    await FirebaseFirestore.instance
        .collection('campaign_links')
        .doc(code)
        .update({'active': active});
    return null;
  } on FirebaseException catch (e) {
    return 'That could not be changed (${e.code}).';
  }
}
