import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/index.dart';
import 'terms_of_engagment_widget.dart' show TermsOfEngagmentWidget;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class TermsOfEngagmentModel extends FlutterFlowModel<TermsOfEngagmentWidget> {
  ///  Local state fields for this page.

  bool? isTermAccepted = false;

  FFUploadedFile? tempSignature;

  ///  State fields for stateful widgets in this page.

  // State field(s) for Checkbox widget.
  bool? checkboxValue;
  // Stores action output result for [Custom Action - convertToBase64] action in Button widget.
  String? rawBase64;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
