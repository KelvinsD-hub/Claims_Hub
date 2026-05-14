import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/firebase_storage/storage.dart';
import '/flutter_flow/flutter_flow_choice_chips.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/flutter_flow/upload_data.dart';
import 'dart:ui';
import '/index.dart';
import 'evidence_form_widget.dart' show EvidenceFormWidget;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class EvidenceFormModel extends FlutterFlowModel<EvidenceFormWidget> {
  ///  Local state fields for this page.

  String? hasBoardingPass;

  List<String> uploadedImages = [];
  void addToUploadedImages(String item) => uploadedImages.add(item);
  void removeFromUploadedImages(String item) => uploadedImages.remove(item);
  void removeAtIndexFromUploadedImages(int index) =>
      uploadedImages.removeAt(index);
  void insertAtIndexInUploadedImages(int index, String item) =>
      uploadedImages.insert(index, item);
  void updateUploadedImagesAtIndex(int index, Function(String) updateFn) =>
      uploadedImages[index] = updateFn(uploadedImages[index]);

  String? selectedDate;

  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();
  // Stores action output result for [Firestore Query - Query a collection] action in EvidenceForm widget.
  List<ClaimsRecord>? activeClaim;
  // State field(s) for fullName widget.
  FocusNode? fullNameFocusNode;
  TextEditingController? fullNameTextController;
  String? Function(BuildContext, String?)? fullNameTextControllerValidator;
  // State field(s) for email widget.
  FocusNode? emailFocusNode;
  TextEditingController? emailTextController;
  String? Function(BuildContext, String?)? emailTextControllerValidator;
  // State field(s) for phonrNo widget.
  FocusNode? phonrNoFocusNode;
  TextEditingController? phonrNoTextController;
  String? Function(BuildContext, String?)? phonrNoTextControllerValidator;
  // State field(s) for NIN widget.
  FocusNode? ninFocusNode;
  TextEditingController? ninTextController;
  String? Function(BuildContext, String?)? ninTextControllerValidator;
  // State field(s) for PassportID widget.
  FocusNode? passportIDFocusNode;
  TextEditingController? passportIDTextController;
  String? Function(BuildContext, String?)? passportIDTextControllerValidator;
  // State field(s) for airlineName widget.
  FocusNode? airlineNameFocusNode;
  TextEditingController? airlineNameTextController;
  String? Function(BuildContext, String?)? airlineNameTextControllerValidator;
  // State field(s) for flightNumber widget.
  FocusNode? flightNumberFocusNode;
  TextEditingController? flightNumberTextController;
  String? Function(BuildContext, String?)? flightNumberTextControllerValidator;
  // State field(s) for claimAmount widget.
  FocusNode? claimAmountFocusNode;
  TextEditingController? claimAmountTextController;
  String? Function(BuildContext, String?)? claimAmountTextControllerValidator;
  DateTime? datePicked;
  // State field(s) for flightDate widget.
  FocusNode? flightDateFocusNode;
  TextEditingController? flightDateTextController;
  String? Function(BuildContext, String?)? flightDateTextControllerValidator;
  // State field(s) for PNR widget.
  FocusNode? pnrFocusNode;
  TextEditingController? pnrTextController;
  String? Function(BuildContext, String?)? pnrTextControllerValidator;
  // State field(s) for duration widget.
  FocusNode? durationFocusNode;
  TextEditingController? durationTextController;
  String? Function(BuildContext, String?)? durationTextControllerValidator;
  // State field(s) for departure widget.
  FocusNode? departureFocusNode;
  TextEditingController? departureTextController;
  String? Function(BuildContext, String?)? departureTextControllerValidator;
  // State field(s) for destination widget.
  FocusNode? destinationFocusNode;
  TextEditingController? destinationTextController;
  String? Function(BuildContext, String?)? destinationTextControllerValidator;
  // State field(s) for issue widget.
  FocusNode? issueFocusNode;
  TextEditingController? issueTextController;
  String? Function(BuildContext, String?)? issueTextControllerValidator;
  // State field(s) for reason widget.
  FocusNode? reasonFocusNode;
  TextEditingController? reasonTextController;
  String? Function(BuildContext, String?)? reasonTextControllerValidator;
  // State field(s) for Bankname widget.
  FocusNode? banknameFocusNode;
  TextEditingController? banknameTextController;
  String? Function(BuildContext, String?)? banknameTextControllerValidator;
  // State field(s) for Accountname widget.
  FocusNode? accountnameFocusNode;
  TextEditingController? accountnameTextController;
  String? Function(BuildContext, String?)? accountnameTextControllerValidator;
  // State field(s) for Accountnumber widget.
  FocusNode? accountnumberFocusNode;
  TextEditingController? accountnumberTextController;
  String? Function(BuildContext, String?)? accountnumberTextControllerValidator;
  // State field(s) for ChoiceChips widget.
  FormFieldController<List<String>>? choiceChipsValueController;
  String? get choiceChipsValue =>
      choiceChipsValueController?.value?.firstOrNull;
  set choiceChipsValue(String? val) =>
      choiceChipsValueController?.value = val != null ? [val] : [];
  bool isDataUploading_uploadDataUg8ca = false;
  List<FFUploadedFile> uploadedLocalFiles_uploadDataUg8ca = [];
  List<String> uploadedFileUrls_uploadDataUg8ca = [];

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    fullNameFocusNode?.dispose();
    fullNameTextController?.dispose();

    emailFocusNode?.dispose();
    emailTextController?.dispose();

    phonrNoFocusNode?.dispose();
    phonrNoTextController?.dispose();

    ninFocusNode?.dispose();
    ninTextController?.dispose();

    passportIDFocusNode?.dispose();
    passportIDTextController?.dispose();

    airlineNameFocusNode?.dispose();
    airlineNameTextController?.dispose();

    flightNumberFocusNode?.dispose();
    flightNumberTextController?.dispose();

    claimAmountFocusNode?.dispose();
    claimAmountTextController?.dispose();

    flightDateFocusNode?.dispose();
    flightDateTextController?.dispose();

    pnrFocusNode?.dispose();
    pnrTextController?.dispose();

    durationFocusNode?.dispose();
    durationTextController?.dispose();

    departureFocusNode?.dispose();
    departureTextController?.dispose();

    destinationFocusNode?.dispose();
    destinationTextController?.dispose();

    issueFocusNode?.dispose();
    issueTextController?.dispose();

    reasonFocusNode?.dispose();
    reasonTextController?.dispose();

    banknameFocusNode?.dispose();
    banknameTextController?.dispose();

    accountnameFocusNode?.dispose();
    accountnameTextController?.dispose();

    accountnumberFocusNode?.dispose();
    accountnumberTextController?.dispose();
  }
}
