import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/claims/claims_options/claims_options_widget.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/menus_file/claims_menu/claims_menu_widget.dart';
import 'dart:math';
import 'dart:ui';
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'claims_under_review_widget.dart' show ClaimsUnderReviewWidget;
import 'package:aligned_dialog/aligned_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ClaimsUnderReviewModel extends FlutterFlowModel<ClaimsUnderReviewWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for Claims_Menu component.
  late ClaimsMenuModel claimsMenuModel;

  @override
  void initState(BuildContext context) {
    claimsMenuModel = createModel(context, () => ClaimsMenuModel());
  }

  @override
  void dispose() {
    claimsMenuModel.dispose();
  }
}
