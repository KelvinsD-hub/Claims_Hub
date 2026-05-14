import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ActivityLogsRecord extends FirestoreRecord {
  ActivityLogsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "entityType" field.
  String? _entityType;
  String get entityType => _entityType ?? '';
  bool hasEntityType() => _entityType != null;

  // "leadRef" field.
  DocumentReference? _leadRef;
  DocumentReference? get leadRef => _leadRef;
  bool hasLeadRef() => _leadRef != null;

  // "claims" field.
  DocumentReference? _claims;
  DocumentReference? get claims => _claims;
  bool hasClaims() => _claims != null;

  // "action" field.
  String? _action;
  String get action => _action ?? '';
  bool hasAction() => _action != null;

  // "description" field.
  String? _description;
  String get description => _description ?? '';
  bool hasDescription() => _description != null;

  // "performedBy" field.
  DocumentReference? _performedBy;
  DocumentReference? get performedBy => _performedBy;
  bool hasPerformedBy() => _performedBy != null;

  // "performedByName" field.
  String? _performedByName;
  String get performedByName => _performedByName ?? '';
  bool hasPerformedByName() => _performedByName != null;

  // "createdAt" field.
  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  bool hasCreatedAt() => _createdAt != null;

  // "metadata" field.
  String? _metadata;
  String get metadata => _metadata ?? '';
  bool hasMetadata() => _metadata != null;

  void _initializeFields() {
    _entityType = snapshotData['entityType'] as String?;
    _leadRef = snapshotData['leadRef'] as DocumentReference?;
    _claims = snapshotData['claims'] as DocumentReference?;
    _action = snapshotData['action'] as String?;
    _description = snapshotData['description'] as String?;
    _performedBy = snapshotData['performedBy'] as DocumentReference?;
    _performedByName = snapshotData['performedByName'] as String?;
    _createdAt = snapshotData['createdAt'] as DateTime?;
    _metadata = snapshotData['metadata'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('activity_logs');

  static Stream<ActivityLogsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => ActivityLogsRecord.fromSnapshot(s));

  static Future<ActivityLogsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => ActivityLogsRecord.fromSnapshot(s));

  static ActivityLogsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      ActivityLogsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static ActivityLogsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      ActivityLogsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'ActivityLogsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is ActivityLogsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createActivityLogsRecordData({
  String? entityType,
  DocumentReference? leadRef,
  DocumentReference? claims,
  String? action,
  String? description,
  DocumentReference? performedBy,
  String? performedByName,
  DateTime? createdAt,
  String? metadata,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'entityType': entityType,
      'leadRef': leadRef,
      'claims': claims,
      'action': action,
      'description': description,
      'performedBy': performedBy,
      'performedByName': performedByName,
      'createdAt': createdAt,
      'metadata': metadata,
    }.withoutNulls,
  );

  return firestoreData;
}

class ActivityLogsRecordDocumentEquality
    implements Equality<ActivityLogsRecord> {
  const ActivityLogsRecordDocumentEquality();

  @override
  bool equals(ActivityLogsRecord? e1, ActivityLogsRecord? e2) {
    return e1?.entityType == e2?.entityType &&
        e1?.leadRef == e2?.leadRef &&
        e1?.claims == e2?.claims &&
        e1?.action == e2?.action &&
        e1?.description == e2?.description &&
        e1?.performedBy == e2?.performedBy &&
        e1?.performedByName == e2?.performedByName &&
        e1?.createdAt == e2?.createdAt &&
        e1?.metadata == e2?.metadata;
  }

  @override
  int hash(ActivityLogsRecord? e) => const ListEquality().hash([
        e?.entityType,
        e?.leadRef,
        e?.claims,
        e?.action,
        e?.description,
        e?.performedBy,
        e?.performedByName,
        e?.createdAt,
        e?.metadata
      ]);

  @override
  bool isValidKey(Object? o) => o is ActivityLogsRecord;
}
