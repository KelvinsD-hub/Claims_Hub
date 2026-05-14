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

import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';

Future<String?> uploadSignatureToFirebase(
  FFUploadedFile? signatureFile, // Changed parameter name and type
  String folderName,
) async {
  // Check if file exists and has data
  if (signatureFile == null || signatureFile.bytes == null) {
    return null;
  }

  try {
    // 1. Get the raw bytes from the FFUploadedFile object
    Uint8List rawBytes = signatureFile.bytes!;

    // 2. Create a unique filename
    String fileName = 'sig_${DateTime.now().millisecondsSinceEpoch}.png';

    // 3. Reference to Firebase Storage
    Reference storageRef =
        FirebaseStorage.instance.ref().child(folderName).child(fileName);

    // 4. Set the content type
    SettableMetadata metadata = SettableMetadata(contentType: 'image/png');

    // 5. Upload the bytes
    UploadTask uploadTask = storageRef.putData(rawBytes, metadata);
    TaskSnapshot snapshot = await uploadTask;

    // 6. Return the URL
    return await snapshot.ref.getDownloadURL();
  } catch (e) {
    print('Error: $e');
    return null;
  }
}
