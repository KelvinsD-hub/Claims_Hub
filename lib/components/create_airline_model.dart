import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'create_airline_widget.dart' show CreateAirlineWidget;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class CreateAirlineModel extends FlutterFlowModel<CreateAirlineWidget> {
  ///  State fields for stateful widgets in this component.

  // State field(s) for Name widget.
  FocusNode? nameFocusNode;
  TextEditingController? nameTextController;
  String? Function(BuildContext, String?)? nameTextControllerValidator;
  // State field(s) for country widget.
  FocusNode? countryFocusNode;
  TextEditingController? countryTextController;
  String? Function(BuildContext, String?)? countryTextControllerValidator;
  // State field(s) for HeadQ widget.
  FocusNode? headQFocusNode;
  TextEditingController? headQTextController;
  String? Function(BuildContext, String?)? headQTextControllerValidator;
  // State field(s) for Email widget.
  FocusNode? emailFocusNode;
  TextEditingController? emailTextController;
  String? Function(BuildContext, String?)? emailTextControllerValidator;
  // State field(s) for Number widget.
  FocusNode? numberFocusNode;
  TextEditingController? numberTextController;
  String? Function(BuildContext, String?)? numberTextControllerValidator;
  // State field(s) for Website widget.
  FocusNode? websiteFocusNode;
  TextEditingController? websiteTextController;
  String? Function(BuildContext, String?)? websiteTextControllerValidator;
  // State field(s) for FlletSize widget.
  FocusNode? flletSizeFocusNode;
  TextEditingController? flletSizeTextController;
  String? Function(BuildContext, String?)? flletSizeTextControllerValidator;
  // State field(s) for YearFounded widget.
  FocusNode? yearFoundedFocusNode;
  TextEditingController? yearFoundedTextController;
  String? Function(BuildContext, String?)? yearFoundedTextControllerValidator;
  // State field(s) for CEO widget.
  FocusNode? ceoFocusNode;
  TextEditingController? ceoTextController;
  String? Function(BuildContext, String?)? ceoTextControllerValidator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    nameFocusNode?.dispose();
    nameTextController?.dispose();

    countryFocusNode?.dispose();
    countryTextController?.dispose();

    headQFocusNode?.dispose();
    headQTextController?.dispose();

    emailFocusNode?.dispose();
    emailTextController?.dispose();

    numberFocusNode?.dispose();
    numberTextController?.dispose();

    websiteFocusNode?.dispose();
    websiteTextController?.dispose();

    flletSizeFocusNode?.dispose();
    flletSizeTextController?.dispose();

    yearFoundedFocusNode?.dispose();
    yearFoundedTextController?.dispose();

    ceoFocusNode?.dispose();
    ceoTextController?.dispose();
  }
}
