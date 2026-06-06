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

import '/auth/firebase_auth/auth_util.dart';

/// Writes an entry to the `activity_logs` collection so it shows up in the
/// Notifications feed. Safe to call from anywhere; failures are swallowed so a
/// logging error never breaks the action that triggered it.
///
/// [entityType] is a short label used for filtering (e.g. 'Lead', 'Claim').
Future logActivity({
  required String action,
  String? description,
  String? entityType,
  DocumentReference? leadRef,
  DocumentReference? claimRef,
  String? metadata,
}) async {
  try {
    await ActivityLogsRecord.collection.doc().set(
          createActivityLogsRecordData(
            entityType: entityType,
            leadRef: leadRef,
            claims: claimRef,
            action: action,
            description: description,
            performedBy: currentUserReference,
            performedByName:
                currentUserDisplayName.isNotEmpty ? currentUserDisplayName : null,
            createdAt: getCurrentTimestamp,
            metadata: metadata,
          ),
        );
  } catch (e) {
    debugPrint('logActivity failed: $e');
  }
}
