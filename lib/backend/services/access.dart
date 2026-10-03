import 'casework.dart';

/// Which pages each role can open.
///
/// The sidebar shows a page only to the roles that may open it, and a page
/// opened by its address anyway says it is not available. The actions that
/// matter are also checked on the server: only managers and above can send a
/// demand letter, and only the legal team a final notice (functions/demand.js).

/// Every page a member of staff can go to.
enum WorkPage {
  dashboard,
  leads,
  links,
  claims,
  demands,
  legal,
  evidence,
  monitor,
  staff,
  notifications,
  support,
  settings,
}

const _admins = ['Admin', 'Super Admin'];

/// Whether someone with [role] may open [page].
bool canSeePage(WorkPage page, String role) => switch (page) {
      // Agents work the leads; managers oversee them.
      WorkPage.leads => role == 'Agent' || isManagerRole(role),
      // Sending a letter to an airline is a manager's decision.
      WorkPage.demands => isManagerRole(role),
      // Making ad links and reading what they bring in.
      WorkPage.links => isManagerRole(role),
      WorkPage.legal => isLegalRole(role),
      WorkPage.monitor || WorkPage.staff => _admins.contains(role),
      WorkPage.dashboard ||
      WorkPage.claims ||
      WorkPage.evidence ||
      WorkPage.notifications ||
      WorkPage.support ||
      WorkPage.settings =>
        true,
    };
