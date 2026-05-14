import '/flutter_flow/flutter_flow_util.dart';
import '/menus_file/claims_menu/claims_menu_widget.dart';
import 'claims_dashboard_widget.dart' show ClaimsDashboardWidget;
import 'package:flutter/material.dart';

class ClaimsDashboardModel extends FlutterFlowModel<ClaimsDashboardWidget> {
  late ClaimsMenuModel claimsMenuModel;

  @override
  void initState(BuildContext context) {
    claimsMenuModel = createModel(context, () => ClaimsMenuModel());
  }

  @override
  void dispose() {
    claimsMenuModel.dispose();
  }
}
