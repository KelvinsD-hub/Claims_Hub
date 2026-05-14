import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'eligibility_checker_widget.dart';

class EligibilityCheckerModel
    extends FlutterFlowModel<EligibilityCheckerWidget> {
  TextEditingController? airlineController;
  FocusNode? airlineFocusNode;

  TextEditingController? departureController;
  FocusNode? departureFocusNode;

  TextEditingController? destinationController;
  FocusNode? destinationFocusNode;

  final formKey = GlobalKey<FormState>();

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    airlineController?.dispose();
    airlineFocusNode?.dispose();
    departureController?.dispose();
    departureFocusNode?.dispose();
    destinationController?.dispose();
    destinationFocusNode?.dispose();
  }
}
