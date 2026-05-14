import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/forms/on_edit_profile/on_edit_profile_widget.dart';
import 'dart:ui';
import 'edit_profile_widget.dart' show EditProfileWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class EditProfileModel extends FlutterFlowModel<EditProfileWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for OnEditProfile component.
  late OnEditProfileModel onEditProfileModel;

  @override
  void initState(BuildContext context) {
    onEditProfileModel = createModel(context, () => OnEditProfileModel());
  }

  @override
  void dispose() {
    onEditProfileModel.dispose();
  }
}
