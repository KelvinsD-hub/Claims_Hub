import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/create_airline_widget.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_choice_chips.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/menus_file/menn_pro/menn_pro_widget.dart';
import 'dart:math';
import 'dart:ui';
import '/index.dart';
import 'email_airlines_widget.dart' show EmailAirlinesWidget;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class EmailAirlinesModel extends FlutterFlowModel<EmailAirlinesWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for MennPro component.
  late MennProModel mennProModel;
  // State field(s) for ChoiceChips widget.
  FormFieldController<List<String>>? choiceChipsValueController;
  String? get choiceChipsValue =>
      choiceChipsValueController?.value?.firstOrNull;
  set choiceChipsValue(String? val) =>
      choiceChipsValueController?.value = val != null ? [val] : [];
  // State field(s) for DropDown widget.
  String? dropDownValue;
  FormFieldController<String>? dropDownValueController;

  @override
  void initState(BuildContext context) {
    mennProModel = createModel(context, () => MennProModel());
  }

  @override
  void dispose() {
    mennProModel.dispose();
  }
}
