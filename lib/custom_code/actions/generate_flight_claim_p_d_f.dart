// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '/custom_code/actions/index.dart';
import '/flutter_flow/custom_functions.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';
import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';

Future<String?> generateFlightClaimPDF(
  String? claimId,
  String? flightNumber,
  String? airlineName,
  String? claimAmount,
  String? claimReason,
  String? claimDate,
  String? passengerName,
  String? signatureBase64,
  bool? termsAccepted,
) async {
  final pdf = pw.Document();

  // Decode signature safely
  Uint8List? signatureBytes;
  if (signatureBase64 != null && signatureBase64.isNotEmpty) {
    try {
      signatureBytes = base64Decode(signatureBase64);
    } catch (e) {
      // If signature decode fails, just continue without it
    }
  }

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.all(40),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Text(
                'Letter of Authority / Formal Demand',
                style:
                    pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Claim ID: ${claimId ?? 'N/A'}',
                style: pw.TextStyle(fontSize: 14)),
            pw.Text('Passenger: ${passengerName ?? 'N/A'}',
                style: pw.TextStyle(fontSize: 14)),
            pw.Text('Flight: ${flightNumber ?? 'N/A'}',
                style: pw.TextStyle(fontSize: 14)),
            pw.Text('Airline: ${airlineName ?? 'N/A'}',
                style: pw.TextStyle(fontSize: 14)),
            pw.Text('Date: ${claimDate ?? 'N/A'}',
                style: pw.TextStyle(fontSize: 14)),
            pw.Text('Amount: \$${claimAmount ?? '0.00'}',
                style: pw.TextStyle(fontSize: 14)),
            pw.Text('Reason: ${claimReason ?? 'N/A'}',
                style: pw.TextStyle(fontSize: 14)),
            pw.SizedBox(height: 30),
            pw.Text(
              'Signature of Passenger',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            if (signatureBytes != null && signatureBytes.isNotEmpty)
              pw.Center(
                child: pw.Image(
                  pw.MemoryImage(signatureBytes),
                  height: 150,
                  fit: pw.BoxFit.contain,
                ),
              )
            else
              pw.Text('No signature available',
                  style: pw.TextStyle(fontSize: 14, color: PdfColors.grey)),
            pw.SizedBox(height: 30),
            if (termsAccepted == true)
              pw.Text('✅ Terms & Conditions Accepted',
                  style: pw.TextStyle(fontSize: 14)),
          ],
        );
      },
    ),
  );

  // Generate bytes (this is the critical part)
  final Uint8List pdfBytes = await pdf.save();

  // Upload to Storage
  final storageRef = FirebaseStorage.instance.ref().child(
      'loa_pdfs/LOA_${claimId ?? DateTime.now().millisecondsSinceEpoch}.pdf');

  await storageRef.putData(pdfBytes);
  final downloadUrl = await storageRef.getDownloadURL();

  return downloadUrl;
}
