import '/flutter_flow/flutter_flow_util.dart';
import '/menus_file/menn_pro/menn_pro_widget.dart';
import 'package:flutter/material.dart';
import 'evidence_locker_widget.dart' show EvidenceLockerWidget;

class EvidenceLockerModel extends FlutterFlowModel<EvidenceLockerWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for MennPro component.
  late MennProModel mennProModel;

  // State field(s) for the search field.
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
