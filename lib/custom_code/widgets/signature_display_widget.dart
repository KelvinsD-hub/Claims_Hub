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
import 'dart:typed_data';

class SignatureDisplayWidget extends StatelessWidget {
  const SignatureDisplayWidget({
    Key? key,
    this.width, // Add this
    this.height, // Add this
    required this.base64String,
  }) : super(key: key);

  final double? width; // Add this
  final double? height; // Add this
  final String? base64String;

  @override
  Widget build(BuildContext context) {
    if (base64String == null || base64String!.isEmpty) {
      return Container(
        height: height ?? 250, // Use the parameter
        width: width ?? double.infinity, // Use the parameter
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(child: Text('No signature yet')),
      );
    }

    // Clean the string to avoid decoding errors
    String cleanBase64 = base64String!.contains(',')
        ? base64String!.split(',').last
        : base64String!;

    final Uint8List bytes = base64.decode(cleanBase64.trim());

    return Image.memory(
      bytes,
      height: height ?? 250, // Use the parameter
      width: width ?? double.infinity, // Use the parameter
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Container(
        height: height ?? 250,
        width: width ?? double.infinity,
        color: Colors.grey[200],
        child: const Center(child: Text('Error loading signature')),
      ),
    );
  }
}
