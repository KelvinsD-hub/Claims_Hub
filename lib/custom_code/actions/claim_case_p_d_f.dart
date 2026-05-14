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

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

Future claimCasePDF(ClaimsRecord claimDoc) async {
  final pdf = pw.Document();
  List<Uint8List> evidenceImages = [];

  // Download evidence images safely
  final List<String>? attachedDocs = claimDoc.attachedDocument.toList();
  if (attachedDocs != null && attachedDocs.isNotEmpty) {
    for (final imageUrl in attachedDocs) {
      if (imageUrl.isNotEmpty) {
        try {
          final response = await http.get(Uri.parse(imageUrl));
          if (response.statusCode == 200) {
            evidenceImages.add(response.bodyBytes);
          }
        } catch (e) {
          print("Error downloading image: $e");
        }
      }
    }
  }

  // Download signature image safely
  Uint8List? signatureBytes;
  final String? signatureUrl = claimDoc.signature;
  if (signatureUrl != null && signatureUrl.isNotEmpty) {
    try {
      final response = await http.get(Uri.parse(signatureUrl));
      if (response.statusCode == 200) {
        signatureBytes = response.bodyBytes;
      }
    } catch (e) {
      print("Error downloading signature: $e");
    }
  }

  final claimRef = "CLM-${DateTime.now().millisecondsSinceEpoch}";
  final generatedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

  pdf.addPage(
    pw.MultiPage(
      build: (context) => [
        // HEADER
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              "CLAIMS ASSIST",
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text("Claim Reference: $claimRef"),
                pw.Text("Generated Date: $generatedDate"),
              ],
            ),
          ],
        ),
        pw.Divider(),
        pw.SizedBox(height: 10),

        // PASSENGER DETAILS
        pw.Text("Passenger Details",
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 5),
        pw.Text("Full Name: ${claimDoc.fullName}"),
        pw.Text("PNR Number: ${claimDoc.pnrNumber}"),

        pw.SizedBox(height: 10),

        // FLIGHT DETAILS
        pw.Text("Flight Details",
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.Text("Flight Date: ${claimDoc.flightDate.toString()}"),
        pw.Text("Departure: ${claimDoc.departure}"),
        pw.Text("Destination: ${claimDoc.destination}"),
        pw.Text("Delay Duration: ${claimDoc.durationOfDelay}"),

        pw.SizedBox(height: 15),

        // AUTHORITY LETTER
        pw.Text("Letter of Authority",
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 5),
        pw.Text(
          "I, ${claimDoc.fullName}, hereby authorize Claims Assist and its appointed legal representatives to pursue compensation on my behalf regarding the disrupted flight listed above.",
          style: pw.TextStyle(fontSize: 12),
        ),

        pw.SizedBox(height: 20),

        // SIGNATURE
        pw.Text("Passenger Signature",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        if (signatureBytes != null)
          pw.Image(pw.MemoryImage(signatureBytes), width: 150, height: 60),

        pw.SizedBox(height: 20),
        pw.Divider(),

        // EVIDENCE
        pw.Text("Supporting Evidence",
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.Wrap(
          spacing: 10,
          runSpacing: 10,
          children: evidenceImages.map((img) {
            return pw.Container(
              width: 250,
              child: pw.Image(pw.MemoryImage(img), fit: pw.BoxFit.contain),
            );
          }).toList(),
        ),
      ],
    ),
  );

  await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save());
}
