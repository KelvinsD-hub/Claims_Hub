import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class AirlinesDirectoryRecord extends FirestoreRecord {
  AirlinesDirectoryRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "airline_name" field.
  String? _airlineName;
  String get airlineName => _airlineName ?? '';
  bool hasAirlineName() => _airlineName != null;

  // "legal_email" field.
  String? _legalEmail;
  String get legalEmail => _legalEmail ?? '';
  bool hasLegalEmail() => _legalEmail != null;

  // "hq_address" field.
  String? _hqAddress;
  String get hqAddress => _hqAddress ?? '';
  bool hasHqAddress() => _hqAddress != null;

  // "country" field.
  String? _country;
  String get country => _country ?? '';
  bool hasCountry() => _country != null;

  // "logo_url" field.
  String? _logoUrl;
  String get logoUrl => _logoUrl ?? '';
  bool hasLogoUrl() => _logoUrl != null;

  // "phone_number" field.
  String? _phoneNumber;
  String get phoneNumber => _phoneNumber ?? '';
  bool hasPhoneNumber() => _phoneNumber != null;

  // "official_website" field.
  String? _officialWebsite;
  String get officialWebsite => _officialWebsite ?? '';
  bool hasOfficialWebsite() => _officialWebsite != null;

  // "fleet_size" field.
  String? _fleetSize;
  String get fleetSize => _fleetSize ?? '';
  bool hasFleetSize() => _fleetSize != null;

  // "year_founded" field.
  String? _yearFounded;
  String get yearFounded => _yearFounded ?? '';
  bool hasYearFounded() => _yearFounded != null;

  // "CEO" field.
  String? _ceo;
  String get ceo => _ceo ?? '';
  bool hasCeo() => _ceo != null;

  // "country_of_origin" field.
  String? _countryOfOrigin;
  String get countryOfOrigin => _countryOfOrigin ?? '';
  bool hasCountryOfOrigin() => _countryOfOrigin != null;

  // "ICAC" field.
  String? _icac;
  String get icac => _icac ?? '';
  bool hasIcac() => _icac != null;

  // "user_id" field.
  DocumentReference? _userId;
  DocumentReference? get userId => _userId;
  bool hasUserId() => _userId != null;

  void _initializeFields() {
    _airlineName = snapshotData['airline_name'] as String?;
    _legalEmail = snapshotData['legal_email'] as String?;
    _hqAddress = snapshotData['hq_address'] as String?;
    _country = snapshotData['country'] as String?;
    _logoUrl = snapshotData['logo_url'] as String?;
    _phoneNumber = snapshotData['phone_number'] as String?;
    _officialWebsite = snapshotData['official_website'] as String?;
    _fleetSize = snapshotData['fleet_size'] as String?;
    _yearFounded = snapshotData['year_founded'] as String?;
    _ceo = snapshotData['CEO'] as String?;
    _countryOfOrigin = snapshotData['country_of_origin'] as String?;
    _icac = snapshotData['ICAC'] as String?;
    _userId = snapshotData['user_id'] as DocumentReference?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('airlines_directory');

  static Stream<AirlinesDirectoryRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => AirlinesDirectoryRecord.fromSnapshot(s));

  static Future<AirlinesDirectoryRecord> getDocumentOnce(
          DocumentReference ref) =>
      ref.get().then((s) => AirlinesDirectoryRecord.fromSnapshot(s));

  static AirlinesDirectoryRecord fromSnapshot(DocumentSnapshot snapshot) =>
      AirlinesDirectoryRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static AirlinesDirectoryRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      AirlinesDirectoryRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'AirlinesDirectoryRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is AirlinesDirectoryRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createAirlinesDirectoryRecordData({
  String? airlineName,
  String? legalEmail,
  String? hqAddress,
  String? country,
  String? logoUrl,
  String? phoneNumber,
  String? officialWebsite,
  String? fleetSize,
  String? yearFounded,
  String? ceo,
  String? countryOfOrigin,
  String? icac,
  DocumentReference? userId,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'airline_name': airlineName,
      'legal_email': legalEmail,
      'hq_address': hqAddress,
      'country': country,
      'logo_url': logoUrl,
      'phone_number': phoneNumber,
      'official_website': officialWebsite,
      'fleet_size': fleetSize,
      'year_founded': yearFounded,
      'CEO': ceo,
      'country_of_origin': countryOfOrigin,
      'ICAC': icac,
      'user_id': userId,
    }.withoutNulls,
  );

  return firestoreData;
}

class AirlinesDirectoryRecordDocumentEquality
    implements Equality<AirlinesDirectoryRecord> {
  const AirlinesDirectoryRecordDocumentEquality();

  @override
  bool equals(AirlinesDirectoryRecord? e1, AirlinesDirectoryRecord? e2) {
    return e1?.airlineName == e2?.airlineName &&
        e1?.legalEmail == e2?.legalEmail &&
        e1?.hqAddress == e2?.hqAddress &&
        e1?.country == e2?.country &&
        e1?.logoUrl == e2?.logoUrl &&
        e1?.phoneNumber == e2?.phoneNumber &&
        e1?.officialWebsite == e2?.officialWebsite &&
        e1?.fleetSize == e2?.fleetSize &&
        e1?.yearFounded == e2?.yearFounded &&
        e1?.ceo == e2?.ceo &&
        e1?.countryOfOrigin == e2?.countryOfOrigin &&
        e1?.icac == e2?.icac &&
        e1?.userId == e2?.userId;
  }

  @override
  int hash(AirlinesDirectoryRecord? e) => const ListEquality().hash([
        e?.airlineName,
        e?.legalEmail,
        e?.hqAddress,
        e?.country,
        e?.logoUrl,
        e?.phoneNumber,
        e?.officialWebsite,
        e?.fleetSize,
        e?.yearFounded,
        e?.ceo,
        e?.countryOfOrigin,
        e?.icac,
        e?.userId
      ]);

  @override
  bool isValidKey(Object? o) => o is AirlinesDirectoryRecord;
}
