import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import '/menus_file/menn_pro/menn_pro_widget.dart';
import 'home_page_widget.dart' show HomePageWidget;
import 'package:flutter/material.dart';

class HomePageModel extends FlutterFlowModel<HomePageWidget> {
  late MennProModel mennProModel;

  // Header filter dropdown
  String? dropDownValue;
  FormFieldController<String>? dropDownValueController;

  @override
  void initState(BuildContext context) {
    mennProModel = createModel(context, () => MennProModel());
  }

  @override
  void dispose() {
    mennProModel.dispose();
  }
}
