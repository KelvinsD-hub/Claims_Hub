import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/menus_file/claims_menu/claims_menu_widget.dart';
import 'dart:math';
import 'dart:ui';
import 'claims_submit_to_solicitors_widget.dart'
    show ClaimsSubmitToSolicitorsWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ClaimsSubmitToSolicitorsModel
    extends FlutterFlowModel<ClaimsSubmitToSolicitorsWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for Claims_Menu component.
  late ClaimsMenuModel claimsMenuModel;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  // State field(s) for DropDown widget.
  String? dropDownValue1;
  FormFieldController<String>? dropDownValueController1;
  // State field(s) for Checkbox widget.
  bool? checkboxValue;
  // State field(s) for DropDown widget.
  String? dropDownValue2;
  FormFieldController<String>? dropDownValueController2;

  @override
  void initState(BuildContext context) {
    claimsMenuModel = createModel(context, () => ClaimsMenuModel());
  }

  @override
  void dispose() {
    claimsMenuModel.dispose();
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
