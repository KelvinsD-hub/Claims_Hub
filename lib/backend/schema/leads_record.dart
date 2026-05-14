import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class LeadsRecord extends FirestoreRecord {
  LeadsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "full_name" field.
  String? _fullName;
  String get fullName => _fullName ?? '';
  bool hasFullName() => _fullName != null;

  // "email" field.
  String? _email;
  String get email => _email ?? '';
  bool hasEmail() => _email != null;

  // "phone" field.
  String? _phone;
  String get phone => _phone ?? '';
  bool hasPhone() => _phone != null;

  // "claim_type" field.
  String? _claimType;
  String get claimType => _claimType ?? '';
  bool hasClaimType() => _claimType != null;

  // "utm_source" field.
  String? _utmSource;
  String get utmSource => _utmSource ?? '';
  bool hasUtmSource() => _utmSource != null;

  // "initial_summary" field.
  String? _initialSummary;
  String get initialSummary => _initialSummary ?? '';
  bool hasInitialSummary() => _initialSummary != null;

  // "status" field.
  String? _status;
  String get status => _status ?? '';
  bool hasStatus() => _status != null;

  // "is_qualified" field.
  bool? _isQualified;
  bool get isQualified => _isQualified ?? false;
  bool hasIsQualified() => _isQualified != null;

  // "complaint_type" field.
  String? _complaintType;
  String get complaintType => _complaintType ?? '';
  bool hasComplaintType() => _complaintType != null;

  // "airline_name" field.
  String? _airlineName;
  String get airlineName => _airlineName ?? '';
  bool hasAirlineName() => _airlineName != null;

  // "claim_ref" field.
  DocumentReference? _claimRef;
  DocumentReference? get claimRef => _claimRef;
  bool hasClaimRef() => _claimRef != null;

  // "created_at" field.
  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  bool hasCreatedAt() => _createdAt != null;

  // "agent_Ref" field.
  DocumentReference? _agentRef;
  DocumentReference? get agentRef => _agentRef;
  bool hasAgentRef() => _agentRef != null;

  // "medium_of_contact" field.
  String? _mediumOfContact;
  String get mediumOfContact => _mediumOfContact ?? '';
  bool hasMediumOfContact() => _mediumOfContact != null;

  // "is_contacted" field.
  bool? _isContacted;
  bool get isContacted => _isContacted ?? false;
  bool hasIsContacted() => _isContacted != null;

  // "estimate_value" field.
  String? _estimateValue;
  String get estimateValue => _estimateValue ?? '';
  bool hasEstimateValue() => _estimateValue != null;

  // "country" field.
  String? _country;
  String get country => _country ?? '';
  bool hasCountry() => _country != null;

  void _initializeFields() {
    _fullName = snapshotData['full_name'] as String?;
    _email = snapshotData['email'] as String?;
    _phone = snapshotData['phone'] as String?;
    _claimType = snapshotData['claim_type'] as String?;
    _utmSource = snapshotData['utm_source'] as String?;
    _initialSummary = snapshotData['initial_summary'] as String?;
    _status = snapshotData['status'] as String?;
    _isQualified = snapshotData['is_qualified'] as bool?;
    _complaintType = snapshotData['complaint_type'] as String?;
    _airlineName = snapshotData['airline_name'] as String?;
    _claimRef = snapshotData['claim_ref'] as DocumentReference?;
    _createdAt = snapshotData['created_at'] as DateTime?;
    _agentRef = snapshotData['agent_Ref'] as DocumentReference?;
    _mediumOfContact = snapshotData['medium_of_contact'] as String?;
    _isContacted = snapshotData['is_contacted'] as bool?;
    _estimateValue = snapshotData['estimate_value'] as String?;
    _country = snapshotData['country'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('leads');

  static Stream<LeadsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => LeadsRecord.fromSnapshot(s));

  static Future<LeadsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => LeadsRecord.fromSnapshot(s));

  static LeadsRecord fromSnapshot(DocumentSnapshot snapshot) => LeadsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static LeadsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      LeadsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'LeadsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is LeadsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createLeadsRecordData({
  String? fullName,
  String? email,
  String? phone,
  String? claimType,
  String? utmSource,
  String? initialSummary,
  String? status,
  bool? isQualified,
  String? complaintType,
  String? airlineName,
  DocumentReference? claimRef,
  DateTime? createdAt,
  DocumentReference? agentRef,
  String? mediumOfContact,
  bool? isContacted,
  String? estimateValue,
  String? country,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'claim_type': claimType,
      'utm_source': utmSource,
      'initial_summary': initialSummary,
      'status': status,
      'is_qualified': isQualified,
      'complaint_type': complaintType,
      'airline_name': airlineName,
      'claim_ref': claimRef,
      'created_at': createdAt,
      'agent_Ref': agentRef,
      'medium_of_contact': mediumOfContact,
      'is_contacted': isContacted,
      'estimate_value': estimateValue,
      'country': country,
    }.withoutNulls,
  );

  return firestoreData;
}

class LeadsRecordDocumentEquality implements Equality<LeadsRecord> {
  const LeadsRecordDocumentEquality();

  @override
  bool equals(LeadsRecord? e1, LeadsRecord? e2) {
    return e1?.fullName == e2?.fullName &&
        e1?.email == e2?.email &&
        e1?.phone == e2?.phone &&
        e1?.claimType == e2?.claimType &&
        e1?.utmSource == e2?.utmSource &&
        e1?.initialSummary == e2?.initialSummary &&
        e1?.status == e2?.status &&
        e1?.isQualified == e2?.isQualified &&
        e1?.complaintType == e2?.complaintType &&
        e1?.airlineName == e2?.airlineName &&
        e1?.claimRef == e2?.claimRef &&
        e1?.createdAt == e2?.createdAt &&
        e1?.agentRef == e2?.agentRef &&
        e1?.mediumOfContact == e2?.mediumOfContact &&
        e1?.isContacted == e2?.isContacted &&
        e1?.estimateValue == e2?.estimateValue &&
        e1?.country == e2?.country;
  }

  @override
  int hash(LeadsRecord? e) => const ListEquality().hash([
        e?.fullName,
        e?.email,
        e?.phone,
        e?.claimType,
        e?.utmSource,
        e?.initialSummary,
        e?.status,
        e?.isQualified,
        e?.complaintType,
        e?.airlineName,
        e?.claimRef,
        e?.createdAt,
        e?.agentRef,
        e?.mediumOfContact,
        e?.isContacted,
        e?.estimateValue,
        e?.country
      ]);

  @override
  bool isValidKey(Object? o) => o is LeadsRecord;
}
