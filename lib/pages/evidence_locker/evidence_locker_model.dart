import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'evidence_locker_widget.dart' show EvidenceLockerWidget;

class EvidenceLockerModel extends FlutterFlowModel<EvidenceLockerWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for the search field.
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
