import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/menus_file/claims_menu/claims_menu_widget.dart';
import 'solicitors_widget.dart' show SolicitorsWidget;

class SolicitorsModel extends FlutterFlowModel<SolicitorsWidget> {
  late ClaimsMenuModel claimsMenuModel;

  TextEditingController? searchController;
  FocusNode? searchFocusNode;

  @override
  void initState(BuildContext context) {
    claimsMenuModel = createModel(context, () => ClaimsMenuModel());
  }

  @override
  void dispose() {
    claimsMenuModel.dispose();
    searchController?.dispose();
    searchFocusNode?.dispose();
  }
}
