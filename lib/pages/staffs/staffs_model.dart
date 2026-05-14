import '/claims/component/staffs_roles/staffs_roles_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/menus_file/menn_pro/menn_pro_widget.dart';
import 'dart:ui';
import 'staffs_widget.dart' show StaffsWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class StaffsModel extends FlutterFlowModel<StaffsWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for MennPro component.
  late MennProModel mennProModel;
  // Model for Staffs_Roles component.
  late StaffsRolesModel staffsRolesModel;

  @override
  void initState(BuildContext context) {
    mennProModel = createModel(context, () => MennProModel());
    staffsRolesModel = createModel(context, () => StaffsRolesModel());
  }

  @override
  void dispose() {
    mennProModel.dispose();
    staffsRolesModel.dispose();
  }
}
