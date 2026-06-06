import '/flutter_flow/flutter_flow_util.dart';
import '/menus_file/menn_pro/menn_pro_widget.dart';
import 'supports_widget.dart' show SupportsWidget;
import 'package:flutter/material.dart';

class SupportsModel extends FlutterFlowModel<SupportsWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for MennPro component.
  late MennProModel mennProModel;

  // State field(s) for the FAQ search field.
  TextEditingController? searchController;
  FocusNode? searchFocusNode;

  @override
  void initState(BuildContext context) {
    mennProModel = createModel(context, () => MennProModel());
  }

  @override
  void dispose() {
    mennProModel.dispose();
    searchController?.dispose();
    searchFocusNode?.dispose();
  }
}
