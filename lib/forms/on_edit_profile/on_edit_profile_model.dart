import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/firebase_storage/storage.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/upload_data.dart';
import 'dart:ui';
import 'on_edit_profile_widget.dart' show OnEditProfileWidget;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class OnEditProfileModel extends FlutterFlowModel<OnEditProfileWidget> {
  ///  State fields for stateful widgets in this component.

  bool isDataUploading_uploadData1mc = false;
  FFUploadedFile uploadedLocalFile_uploadData1mc =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadData1mc = '';

  // State field(s) for nameTextField widget.
  FocusNode? nameTextFieldFocusNode;
  TextEditingController? nameTextFieldTextController;
  String? Function(BuildContext, String?)? nameTextFieldTextControllerValidator;
  // State field(s) for emailTextField widget.
  FocusNode? emailTextFieldFocusNode;
  TextEditingController? emailTextFieldTextController;
  String? Function(BuildContext, String?)?
      emailTextFieldTextControllerValidator;
  // State field(s) for phoneTextField widget.
  FocusNode? phoneTextFieldFocusNode;
  TextEditingController? phoneTextFieldTextController;
  String? Function(BuildContext, String?)?
      phoneTextFieldTextControllerValidator;
  // State field(s) for addressTextField widget.
  FocusNode? addressTextFieldFocusNode;
  TextEditingController? addressTextFieldTextController;
  String? Function(BuildContext, String?)?
      addressTextFieldTextControllerValidator;
  // State field(s) for cityTextField widget.
  FocusNode? cityTextFieldFocusNode;
  TextEditingController? cityTextFieldTextController;
  String? Function(BuildContext, String?)? cityTextFieldTextControllerValidator;
  // State field(s) for bioTextField widget.
  FocusNode? bioTextFieldFocusNode;
  TextEditingController? bioTextFieldTextController;
  String? Function(BuildContext, String?)? bioTextFieldTextControllerValidator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    nameTextFieldFocusNode?.dispose();
    nameTextFieldTextController?.dispose();

    emailTextFieldFocusNode?.dispose();
    emailTextFieldTextController?.dispose();

    phoneTextFieldFocusNode?.dispose();
    phoneTextFieldTextController?.dispose();

    addressTextFieldFocusNode?.dispose();
    addressTextFieldTextController?.dispose();

    cityTextFieldFocusNode?.dispose();
    cityTextFieldTextController?.dispose();

    bioTextFieldFocusNode?.dispose();
    bioTextFieldTextController?.dispose();
  }
}
