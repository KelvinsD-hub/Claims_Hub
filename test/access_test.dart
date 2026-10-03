import 'package:claims_hub/backend/services/access.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Set<WorkPage> pages(String role) =>
      WorkPage.values.where((p) => canSeePage(p, role)).toSet();

  const everyone = {
    WorkPage.dashboard,
    WorkPage.claims,
    WorkPage.evidence,
    WorkPage.notifications,
    WorkPage.support,
    WorkPage.settings,
  };

  test('an agent works leads and claims, and sends nothing to an airline', () {
    expect(pages('Agent'), {...everyone, WorkPage.leads});
  });

  test('a lawyer sees claims and the legal workspace, not leads or demands',
      () {
    expect(pages('Solicitor'), {...everyone, WorkPage.legal});
  });

  test('a manager also sends demand letters and makes ad links', () {
    expect(pages('Manager'), {
      ...everyone,
      WorkPage.leads,
      WorkPage.links,
      WorkPage.demands,
      WorkPage.legal,
    });
  });

  test('admins see everything', () {
    expect(pages('Admin'), WorkPage.values.toSet());
    expect(pages('Super Admin'), WorkPage.values.toSet());
  });

  test('someone with no role yet sees only the common pages', () {
    expect(pages(''), everyone);
  });
}
