import '/backend/backend.dart';
import '/claims/component/lead_note/lead_note_widget.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/leads/leads_options/leads_options_widget.dart';
import '/menus_file/lead_menu/lead_menu_widget.dart';
import 'dart:math';
import 'dart:ui';
import '/index.dart';
import 'leads_widget.dart' show LeadsWidget;
import 'package:aligned_dialog/aligned_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class LeadsModel extends FlutterFlowModel<LeadsWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for Lead_Menu component.
  late LeadMenuModel leadMenuModel;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  // State field(s) for DropDown widget.
  String? dropDownValue1;
  FormFieldController<String>? dropDownValueController1;
  // State field(s) for DropDown widget.
  String? dropDownValue2;
  FormFieldController<String>? dropDownValueController2;

  @override
  void initState(BuildContext context) {
    leadMenuModel = createModel(context, () => LeadMenuModel());
  }

  @override
  void dispose() {
    leadMenuModel.dispose();
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
