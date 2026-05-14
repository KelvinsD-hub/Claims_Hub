import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/claims/component/lead_note/lead_note_widget.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/leads/leads_options/leads_options_widget.dart';
import '/menus_file/lead_menu/lead_menu_widget.dart';
import 'dart:math';
import 'dart:ui';
import 'contact_lead_widget.dart' show ContactLeadWidget;
import 'package:aligned_dialog/aligned_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ContactLeadModel extends FlutterFlowModel<ContactLeadWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for Lead_Menu component.
  late LeadMenuModel leadMenuModel;

  @override
  void initState(BuildContext context) {
    leadMenuModel = createModel(context, () => LeadMenuModel());
  }

  @override
  void dispose() {
    leadMenuModel.dispose();
  }
}
