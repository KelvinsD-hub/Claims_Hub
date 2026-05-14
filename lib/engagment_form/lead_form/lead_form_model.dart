import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import 'dart:ui';
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'lead_form_widget.dart' show LeadFormWidget;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class LeadFormModel extends FlutterFlowModel<LeadFormWidget> {
  ///  Local state fields for this page.

  String? countryCode;

  ///  State fields for stateful widgets in this page.

  // State field(s) for FullName widget.
  FocusNode? fullNameFocusNode;
  TextEditingController? fullNameTextController;
  String? Function(BuildContext, String?)? fullNameTextControllerValidator;
  // State field(s) for Email widget.
  FocusNode? emailFocusNode;
  TextEditingController? emailTextController;
  String? Function(BuildContext, String?)? emailTextControllerValidator;
  // State field(s) for countryDropDown widget.
  String? countryDropDownValue;
  FormFieldController<String>? countryDropDownValueController;
  // State field(s) for phoneNumber widget.
  FocusNode? phoneNumberFocusNode;
  TextEditingController? phoneNumberTextController;
  String? Function(BuildContext, String?)? phoneNumberTextControllerValidator;
  // State field(s) for AirlineName widget.
  FocusNode? airlineNameFocusNode;
  TextEditingController? airlineNameTextController;
  String? Function(BuildContext, String?)? airlineNameTextControllerValidator;
  // State field(s) for ComplainDropdown widget.
  String? complainDropdownValue;
  FormFieldController<String>? complainDropdownValueController;
  // State field(s) for contactDropdown widget.
  String? contactDropdownValue;
  FormFieldController<String>? contactDropdownValueController;
  // State field(s) for NoteTextField widget.
  FocusNode? noteTextFieldFocusNode;
  TextEditingController? noteTextFieldTextController;
  String? Function(BuildContext, String?)? noteTextFieldTextControllerValidator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    fullNameFocusNode?.dispose();
    fullNameTextController?.dispose();

    emailFocusNode?.dispose();
    emailTextController?.dispose();

    phoneNumberFocusNode?.dispose();
    phoneNumberTextController?.dispose();

    airlineNameFocusNode?.dispose();
    airlineNameTextController?.dispose();

    noteTextFieldFocusNode?.dispose();
    noteTextFieldTextController?.dispose();
  }
}
