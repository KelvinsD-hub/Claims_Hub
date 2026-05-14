import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/menus_file/menn_pro/menn_pro_widget.dart';
import 'dart:ui';
import 'notifications_widget.dart' show NotificationsWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class NotificationsModel extends FlutterFlowModel<NotificationsWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for MennPro component.
  late MennProModel mennProModel;

  @override
  void initState(BuildContext context) {
    mennProModel = createModel(context, () => MennProModel());
  }

  @override
  void dispose() {
    mennProModel.dispose();
  }
}
