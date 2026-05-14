// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '/custom_code/widgets/index.dart';
import '/custom_code/actions/index.dart';
import '/flutter_flow/custom_functions.dart';

import 'dart:convert';
import 'package:signature/signature.dart';
import '/custom_code/actions/init_signature_controller.dart';

class SignaturePadWidget extends StatefulWidget {
  const SignaturePadWidget({
    Key? key,
    this.width,
    this.height,
  }) : super(key: key);

  final double? width;
  final double? height;

  @override
  _SignaturePadWidgetState createState() => _SignaturePadWidgetState();
}

class _SignaturePadWidgetState extends State<SignaturePadWidget> {
  late SignatureController _signatureController;

  @override
  void initState() {
    super.initState();
    _signatureController = SignatureControllerSingleton().signatureController!;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Signature(
        controller: _signatureController,
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        height: widget.height ?? 200,
        width: widget.width ?? double.infinity,
      ),
    );
  }
}
