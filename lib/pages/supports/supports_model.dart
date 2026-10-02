import '/flutter_flow/flutter_flow_util.dart';
import 'supports_widget.dart' show SupportsWidget;
import 'package:flutter/material.dart';

class SupportsModel extends FlutterFlowModel<SupportsWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for the FAQ search field.
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
