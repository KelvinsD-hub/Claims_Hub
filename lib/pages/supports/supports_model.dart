import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/menus_file/suppots_menu/suppots_menu_widget.dart';
import 'dart:ui';
import 'supports_widget.dart' show SupportsWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class SupportsModel extends FlutterFlowModel<SupportsWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for Suppots_Menu component.
  late SuppotsMenuModel suppotsMenuModel;

  @override
  void initState(BuildContext context) {
    suppotsMenuModel = createModel(context, () => SuppotsMenuModel());
  }

  @override
  void dispose() {
    suppotsMenuModel.dispose();
  }
}
