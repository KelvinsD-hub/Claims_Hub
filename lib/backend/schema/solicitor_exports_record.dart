import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class SolicitorExportsRecord extends FirestoreRecord {
  SolicitorExportsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "export_id" field.
  String? _exportId;
  String get exportId => _exportId ?? '';
  bool hasExportId() => _exportId != null;

  // "solicitor_firm" field.
  String? _solicitorFirm;
  String get solicitorFirm => _solicitorFirm ?? '';
  bool hasSolicitorFirm() => _solicitorFirm != null;

  // "claims_included" field.
  DocumentReference? _claimsIncluded;
  DocumentReference? get claimsIncluded => _claimsIncluded;
  bool hasClaimsIncluded() => _claimsIncluded != null;

  // "export_date" field.
  DateTime? _exportDate;
  DateTime? get exportDate => _exportDate;
  bool hasExportDate() => _exportDate != null;

  // "csv_url" field.
  String? _csvUrl;
  String get csvUrl => _csvUrl ?? '';
  bool hasCsvUrl() => _csvUrl != null;

  // "status" field.
  String? _status;
  String get status => _status ?? '';
  bool hasStatus() => _status != null;

  void _initializeFields() {
    _exportId = snapshotData['export_id'] as String?;
    _solicitorFirm = snapshotData['solicitor_firm'] as String?;
    _claimsIncluded = snapshotData['claims_included'] as DocumentReference?;
    _exportDate = snapshotData['export_date'] as DateTime?;
    _csvUrl = snapshotData['csv_url'] as String?;
    _status = snapshotData['status'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('solicitor_exports');

  static Stream<SolicitorExportsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => SolicitorExportsRecord.fromSnapshot(s));

  static Future<SolicitorExportsRecord> getDocumentOnce(
          DocumentReference ref) =>
      ref.get().then((s) => SolicitorExportsRecord.fromSnapshot(s));

  static SolicitorExportsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      SolicitorExportsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static SolicitorExportsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      SolicitorExportsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'SolicitorExportsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is SolicitorExportsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createSolicitorExportsRecordData({
  String? exportId,
  String? solicitorFirm,
  DocumentReference? claimsIncluded,
  DateTime? exportDate,
  String? csvUrl,
  String? status,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'export_id': exportId,
      'solicitor_firm': solicitorFirm,
      'claims_included': claimsIncluded,
      'export_date': exportDate,
      'csv_url': csvUrl,
      'status': status,
    }.withoutNulls,
  );

  return firestoreData;
}

class SolicitorExportsRecordDocumentEquality
    implements Equality<SolicitorExportsRecord> {
  const SolicitorExportsRecordDocumentEquality();

  @override
  bool equals(SolicitorExportsRecord? e1, SolicitorExportsRecord? e2) {
    return e1?.exportId == e2?.exportId &&
        e1?.solicitorFirm == e2?.solicitorFirm &&
        e1?.claimsIncluded == e2?.claimsIncluded &&
        e1?.exportDate == e2?.exportDate &&
        e1?.csvUrl == e2?.csvUrl &&
        e1?.status == e2?.status;
  }

  @override
  int hash(SolicitorExportsRecord? e) => const ListEquality().hash([
        e?.exportId,
        e?.solicitorFirm,
        e?.claimsIncluded,
        e?.exportDate,
        e?.csvUrl,
        e?.status
      ]);

  @override
  bool isValidKey(Object? o) => o is SolicitorExportsRecord;
}
