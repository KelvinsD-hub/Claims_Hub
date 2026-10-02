import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'solicitors_widget.dart' show SolicitorsWidget;

class SolicitorsModel extends FlutterFlowModel<SolicitorsWidget> {
  TextEditingController? searchController;
  FocusNode? searchFocusNode;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    searchController?.dispose();
    searchFocusNode?.dispose();
  }
}
