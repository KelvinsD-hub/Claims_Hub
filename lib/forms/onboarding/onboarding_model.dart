import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:math';
import 'dart:ui';
import '/index.dart';
import 'onboarding_widget.dart' show OnboardingWidget;
import 'package:smooth_page_indicator/smooth_page_indicator.dart'
    as smooth_page_indicator;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class OnboardingModel extends FlutterFlowModel<OnboardingWidget> {
  ///  Local state fields for this page.

  int? totalPagesCount = 3;

  bool hideButtonText = false;

  List<String> titleList = [
    'Welcome to your CRM',
    'Leads In-take',
    'Communication'
  ];
  void addToTitleList(String item) => titleList.add(item);
  void removeFromTitleList(String item) => titleList.remove(item);
  void removeAtIndexFromTitleList(int index) => titleList.removeAt(index);
  void insertAtIndexInTitleList(int index, String item) =>
      titleList.insert(index, item);
  void updateTitleListAtIndex(int index, Function(String) updateFn) =>
      titleList[index] = updateFn(titleList[index]);

  List<String> subtitleList = [
    'Manage leads, clients. and communication in one place',
    'Capture and manage leads easily. Assign leads to agents instantly',
    'Send automated emails. SMS, and WhatsApp to clients'
  ];
  void addToSubtitleList(String item) => subtitleList.add(item);
  void removeFromSubtitleList(String item) => subtitleList.remove(item);
  void removeAtIndexFromSubtitleList(int index) => subtitleList.removeAt(index);
  void insertAtIndexInSubtitleList(int index, String item) =>
      subtitleList.insert(index, item);
  void updateSubtitleListAtIndex(int index, Function(String) updateFn) =>
      subtitleList[index] = updateFn(subtitleList[index]);

  ///  State fields for stateful widgets in this page.

  // State field(s) for PageView widget.
  PageController? pageViewController;

  int get pageViewCurrentIndex => pageViewController != null &&
          pageViewController!.hasClients &&
          pageViewController!.page != null
      ? pageViewController!.page!.round()
      : 0;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}

  /// Action blocks.
  /// Action that happens when a user presses a button on a last slide.
  Future lastSlideAction(BuildContext context) async {}
}
