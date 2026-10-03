import 'package:claims_hub/backend/services/links.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  CampaignLink link(String code, {int clicks = 0, bool active = true}) =>
      CampaignLink(
        code: code,
        label: code,
        channel: 'facebook',
        destination: '/',
        active: active,
        clicks: clicks,
      );
  LeadFact lead(String link,
          {String utm = '', bool signed = false, bool qualified = false}) =>
      LeadFact(
          sourceLink: link,
          utmSource: utm.isEmpty ? (link.isEmpty ? 'claims-assist-site' : link) : utm,
          signed: signed,
          qualified: qualified);

  test('leads, signed and claims are counted per link', () {
    final r = linkStats(
      [link('fb', clicks: 40), link('ig', clicks: 10)],
      [
        lead('fb', signed: true, qualified: true),
        lead('fb', signed: true),
        lead('fb'),
        lead('ig'),
      ],
      const [],
    );
    final fb = r.links.firstWhere((s) => s.link.code == 'fb');
    expect(fb.leads, 3);
    expect(fb.signed, 2);
    expect(fb.claims, 1);
    expect(fb.leadRate, closeTo(0.075, 1e-9));
    expect(r.links.first.link.code, 'fb', reason: 'most leads first');
  });

  test('won claims and money recovered come from claims', () {
    final r = linkStats(
      [link('fb')],
      const [],
      const [
        ClaimFact(sourceLink: 'fb', stage: 'Won', recovered: 21250),
        ClaimFact(sourceLink: 'fb', stage: 'Paid', recovered: 10000),
        ClaimFact(sourceLink: 'fb', stage: 'Claim Won', recovered: 5000),
        ClaimFact(sourceLink: 'fb', stage: 'Awaiting Reply'),
        ClaimFact(sourceLink: 'gone', stage: 'Won', recovered: 99),
      ],
    );
    expect(r.links.single.won, 3);
    expect(r.links.single.recovered, 36250);
  });

  test('leads without a known link are grouped by what the website recorded', () {
    final r = linkStats(
      [link('fb')],
      [
        lead(''),
        lead(''),
        LeadFact(sourceLink: '', utmSource: '', signed: false, qualified: false),
        lead('', utm: 'newsletter'),
        lead('old-code'),
      ],
      const [],
    );
    final names = {for (final o in r.others) o.name: o.leads};
    expect(names['Website, no link'], 3,
        reason: 'a blank source and the site name are the same thing');
    expect(r.others.where((o) => o.name == 'Website, no link').length, 1);
    expect(names['newsletter'], 1);
    expect(names['old-code'], 1);
  });

  test('no clicks means no rate rather than zero', () {
    expect(linkStats([link('fb')], const [], const []).links.single.leadRate,
        isNull);
  });

  test('switched-off links sort last', () {
    final r = linkStats(
        [link('off', active: false), link('on')], [lead('off')], const []);
    expect(r.links.first.link.code, 'on');
  });

  test('codes', () {
    expect(suggestCode('Facebook October!'), 'facebook-october');
    expect(linkCodePattern.hasMatch('fb-oct'), isTrue);
    expect(linkCodePattern.hasMatch('Fb'), isFalse);
    expect(linkCodePattern.hasMatch('a'), isFalse);
    expect(suggestCode('x' * 40).length, 32);
  });
}
