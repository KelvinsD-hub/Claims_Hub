import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/forms/complete_profile/complete_profile_widget.dart';
import 'dart:ui';
import 'update_profile_widget.dart' show UpdateProfileWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class UpdateProfileModel extends FlutterFlowModel<UpdateProfileWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for CompleteProfile component.
  late CompleteProfileModel completeProfileModel;

  @override
  void initState(BuildContext context) {
    completeProfileModel = createModel(context, () => CompleteProfileModel());
  }

  @override
  void dispose() {
    completeProfileModel.dispose();
  }
}
