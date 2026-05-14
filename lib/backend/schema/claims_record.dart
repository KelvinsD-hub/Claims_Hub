import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';
import '/backend/security/crypto_service.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ClaimsRecord extends FirestoreRecord {
  ClaimsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "lead_ref" field.
  DocumentReference? _leadRef;
  DocumentReference? get leadRef => _leadRef;
  bool hasLeadRef() => _leadRef != null;

  // "pnr_number" field.
  String? _pnrNumber;
  String get pnrNumber => _pnrNumber ?? '';
  bool hasPnrNumber() => _pnrNumber != null;

  // "bvn_number" field.
  String? _bvnNumber;
  String get bvnNumber => _bvnNumber ?? '';
  bool hasBvnNumber() => _bvnNumber != null;

  // "airline_response" field.
  String? _airlineResponse;
  String get airlineResponse => _airlineResponse ?? '';
  bool hasAirlineResponse() => _airlineResponse != null;

  // "claim_status" field.
  String? _claimStatus;
  String get claimStatus => _claimStatus ?? '';
  bool hasClaimStatus() => _claimStatus != null;

  // "flight_details_submitted" field.
  bool? _flightDetailsSubmitted;
  bool get flightDetailsSubmitted => _flightDetailsSubmitted ?? false;
  bool hasFlightDetailsSubmitted() => _flightDetailsSubmitted != null;

  // "terms_accepted" field.
  bool? _termsAccepted;
  bool get termsAccepted => _termsAccepted ?? false;
  bool hasTermsAccepted() => _termsAccepted != null;

  // "signature_submitted" field.
  bool? _signatureSubmitted;
  bool get signatureSubmitted => _signatureSubmitted ?? false;
  bool hasSignatureSubmitted() => _signatureSubmitted != null;

  // "secure_token" field.
  String? _secureToken;
  String get secureToken => _secureToken ?? '';
  bool hasSecureToken() => _secureToken != null;

  // "bank_name" field.
  String? _bankName;
  String get bankName => _bankName ?? '';
  bool hasBankName() => _bankName != null;

  // "account_no" field.
  String? _accountNo;
  String get accountNo => _accountNo ?? '';
  bool hasAccountNo() => _accountNo != null;

  // "account_name" field.
  String? _accountName;
  String get accountName => _accountName ?? '';
  bool hasAccountName() => _accountName != null;

  // "signed_at" field.
  DateTime? _signedAt;
  DateTime? get signedAt => _signedAt;
  bool hasSignedAt() => _signedAt != null;

  // "departure" field.
  String? _departure;
  String get departure => _departure ?? '';
  bool hasDeparture() => _departure != null;

  // "destination" field.
  String? _destination;
  String get destination => _destination ?? '';
  bool hasDestination() => _destination != null;

  // "full_name" field.
  String? _fullName;
  String get fullName => _fullName ?? '';
  bool hasFullName() => _fullName != null;

  // "duration_of_delay" field.
  String? _durationOfDelay;
  String get durationOfDelay => _durationOfDelay ?? '';
  bool hasDurationOfDelay() => _durationOfDelay != null;

  // "flight_date" field.
  String? _flightDate;
  String get flightDate => _flightDate ?? '';
  bool hasFlightDate() => _flightDate != null;

  // "attached_document" field.
  List<String>? _attachedDocument;
  List<String> get attachedDocument => _attachedDocument ?? const [];
  bool hasAttachedDocument() => _attachedDocument != null;

  // "letter_of_authority" field.
  String? _letterOfAuthority;
  String get letterOfAuthority => _letterOfAuthority ?? '';
  bool hasLetterOfAuthority() => _letterOfAuthority != null;

  // "terms_and_conditions" field.
  String? _termsAndConditions;
  String get termsAndConditions => _termsAndConditions ?? '';
  bool hasTermsAndConditions() => _termsAndConditions != null;

  // "airline_name" field.
  String? _airlineName;
  String get airlineName => _airlineName ?? '';
  bool hasAirlineName() => _airlineName != null;

  // "claims_amount" field.
  String? _claimsAmount;
  String get claimsAmount => _claimsAmount ?? '';
  bool hasClaimsAmount() => _claimsAmount != null;

  // "flight_number" field.
  String? _flightNumber;
  String get flightNumber => _flightNumber ?? '';
  bool hasFlightNumber() => _flightNumber != null;

  // "createdAt" field.
  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  bool hasCreatedAt() => _createdAt != null;

  // "client_email" field.
  String? _clientEmail;
  String get clientEmail => _clientEmail ?? '';
  bool hasClientEmail() => _clientEmail != null;

  // "signature" field.
  String? _signature;
  String get signature => _signature ?? '';
  bool hasSignature() => _signature != null;

  // "NIN" field.
  String? _nin;
  String get nin => _nin ?? '';
  bool hasNin() => _nin != null;

  // "Passport" field.
  String? _passport;
  String get passport => _passport ?? '';
  bool hasPassport() => _passport != null;

  // "loa_url" field.
  String? _loaUrl;
  String get loaUrl => _loaUrl ?? '';
  bool hasLoaUrl() => _loaUrl != null;

  // "trigger_airline_email" field.
  bool? _triggerAirlineEmail;
  bool get triggerAirlineEmail => _triggerAirlineEmail ?? false;
  bool hasTriggerAirlineEmail() => _triggerAirlineEmail != null;

  // "airline_email_selection" field.
  String? _airlineEmailSelection;
  String get airlineEmailSelection => _airlineEmailSelection ?? '';
  bool hasAirlineEmailSelection() => _airlineEmailSelection != null;

  // "airline_email_status" field.
  String? _airlineEmailStatus;
  String get airlineEmailStatus => _airlineEmailStatus ?? '';
  bool hasAirlineEmailStatus() => _airlineEmailStatus != null;

  // "claims_reason" field.
  String? _claimsReason;
  String get claimsReason => _claimsReason ?? '';
  bool hasClaimsReason() => _claimsReason != null;

  void _initializeFields() {
    _leadRef = snapshotData['lead_ref'] as DocumentReference?;
    _pnrNumber = snapshotData['pnr_number'] as String?;
    final _rawBvn = CryptoService.instance
        .decrypt(snapshotData['bvn_number'] as String? ?? '');
    _bvnNumber = _rawBvn.isEmpty ? null : _rawBvn;
    _airlineResponse = snapshotData['airline_response'] as String?;
    _claimStatus = snapshotData['claim_status'] as String?;
    _flightDetailsSubmitted = snapshotData['flight_details_submitted'] as bool?;
    _termsAccepted = snapshotData['terms_accepted'] as bool?;
    _signatureSubmitted = snapshotData['signature_submitted'] as bool?;
    _secureToken = snapshotData['secure_token'] as String?;
    _bankName = snapshotData['bank_name'] as String?;
    final _rawAccountNo = CryptoService.instance
        .decrypt(snapshotData['account_no'] as String? ?? '');
    _accountNo = _rawAccountNo.isEmpty ? null : _rawAccountNo;
    _accountName = snapshotData['account_name'] as String?;
    _signedAt = snapshotData['signed_at'] as DateTime?;
    _departure = snapshotData['departure'] as String?;
    _destination = snapshotData['destination'] as String?;
    _fullName = snapshotData['full_name'] as String?;
    _durationOfDelay = snapshotData['duration_of_delay'] as String?;
    _flightDate = snapshotData['flight_date'] as String?;
    _attachedDocument = getDataList(snapshotData['attached_document']);
    _letterOfAuthority = snapshotData['letter_of_authority'] as String?;
    _termsAndConditions = snapshotData['terms_and_conditions'] as String?;
    _airlineName = snapshotData['airline_name'] as String?;
    _claimsAmount = snapshotData['claims_amount'] as String?;
    _flightNumber = snapshotData['flight_number'] as String?;
    _createdAt = snapshotData['createdAt'] as DateTime?;
    _clientEmail = snapshotData['client_email'] as String?;
    _signature = snapshotData['signature'] as String?;
    final _rawNin = CryptoService.instance
        .decrypt(snapshotData['NIN'] as String? ?? '');
    _nin = _rawNin.isEmpty ? null : _rawNin;
    final _rawPassport = CryptoService.instance
        .decrypt(snapshotData['Passport'] as String? ?? '');
    _passport = _rawPassport.isEmpty ? null : _rawPassport;
    _loaUrl = snapshotData['loa_url'] as String?;
    _triggerAirlineEmail = snapshotData['trigger_airline_email'] as bool?;
    _airlineEmailSelection = snapshotData['airline_email_selection'] as String?;
    _airlineEmailStatus = snapshotData['airline_email_status'] as String?;
    _claimsReason = snapshotData['claims_reason'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('claims');

  static Stream<ClaimsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => ClaimsRecord.fromSnapshot(s));

  static Future<ClaimsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => ClaimsRecord.fromSnapshot(s));

  static ClaimsRecord fromSnapshot(DocumentSnapshot snapshot) => ClaimsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static ClaimsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      ClaimsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'ClaimsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is ClaimsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createClaimsRecordData({
  DocumentReference? leadRef,
  String? pnrNumber,
  String? bvnNumber,
  String? airlineResponse,
  String? claimStatus,
  bool? flightDetailsSubmitted,
  bool? termsAccepted,
  bool? signatureSubmitted,
  String? secureToken,
  String? bankName,
  String? accountNo,
  String? accountName,
  DateTime? signedAt,
  String? departure,
  String? destination,
  String? fullName,
  String? durationOfDelay,
  String? flightDate,
  String? letterOfAuthority,
  String? termsAndConditions,
  String? airlineName,
  String? claimsAmount,
  String? flightNumber,
  DateTime? createdAt,
  String? clientEmail,
  String? signature,
  String? nin,
  String? passport,
  String? loaUrl,
  bool? triggerAirlineEmail,
  String? airlineEmailSelection,
  String? airlineEmailStatus,
  String? claimsReason,
}) {
  final _crypto = CryptoService.instance;
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'lead_ref': leadRef,
      'pnr_number': pnrNumber,
      'bvn_number': bvnNumber != null ? _crypto.encrypt(bvnNumber) : null,
      'airline_response': airlineResponse,
      'claim_status': claimStatus,
      'flight_details_submitted': flightDetailsSubmitted,
      'terms_accepted': termsAccepted,
      'signature_submitted': signatureSubmitted,
      'secure_token': secureToken,
      'bank_name': bankName,
      'account_no': accountNo != null ? _crypto.encrypt(accountNo) : null,
      'account_name': accountName,
      'signed_at': signedAt,
      'departure': departure,
      'destination': destination,
      'full_name': fullName,
      'duration_of_delay': durationOfDelay,
      'flight_date': flightDate,
      'letter_of_authority': letterOfAuthority,
      'terms_and_conditions': termsAndConditions,
      'airline_name': airlineName,
      'claims_amount': claimsAmount,
      'flight_number': flightNumber,
      'createdAt': createdAt,
      'client_email': clientEmail,
      'signature': signature,
      'NIN': nin != null ? _crypto.encrypt(nin) : null,
      'Passport': passport != null ? _crypto.encrypt(passport) : null,
      'loa_url': loaUrl,
      'trigger_airline_email': triggerAirlineEmail,
      'airline_email_selection': airlineEmailSelection,
      'airline_email_status': airlineEmailStatus,
      'claims_reason': claimsReason,
    }.withoutNulls,
  );

  return firestoreData;
}

class ClaimsRecordDocumentEquality implements Equality<ClaimsRecord> {
  const ClaimsRecordDocumentEquality();

  @override
  bool equals(ClaimsRecord? e1, ClaimsRecord? e2) {
    const listEquality = ListEquality();
    return e1?.leadRef == e2?.leadRef &&
        e1?.pnrNumber == e2?.pnrNumber &&
        e1?.bvnNumber == e2?.bvnNumber &&
        e1?.airlineResponse == e2?.airlineResponse &&
        e1?.claimStatus == e2?.claimStatus &&
        e1?.flightDetailsSubmitted == e2?.flightDetailsSubmitted &&
        e1?.termsAccepted == e2?.termsAccepted &&
        e1?.signatureSubmitted == e2?.signatureSubmitted &&
        e1?.secureToken == e2?.secureToken &&
        e1?.bankName == e2?.bankName &&
        e1?.accountNo == e2?.accountNo &&
        e1?.accountName == e2?.accountName &&
        e1?.signedAt == e2?.signedAt &&
        e1?.departure == e2?.departure &&
        e1?.destination == e2?.destination &&
        e1?.fullName == e2?.fullName &&
        e1?.durationOfDelay == e2?.durationOfDelay &&
        e1?.flightDate == e2?.flightDate &&
        listEquality.equals(e1?.attachedDocument, e2?.attachedDocument) &&
        e1?.letterOfAuthority == e2?.letterOfAuthority &&
        e1?.termsAndConditions == e2?.termsAndConditions &&
        e1?.airlineName == e2?.airlineName &&
        e1?.claimsAmount == e2?.claimsAmount &&
        e1?.flightNumber == e2?.flightNumber &&
        e1?.createdAt == e2?.createdAt &&
        e1?.clientEmail == e2?.clientEmail &&
        e1?.signature == e2?.signature &&
        e1?.nin == e2?.nin &&
        e1?.passport == e2?.passport &&
        e1?.loaUrl == e2?.loaUrl &&
        e1?.triggerAirlineEmail == e2?.triggerAirlineEmail &&
        e1?.airlineEmailSelection == e2?.airlineEmailSelection &&
        e1?.airlineEmailStatus == e2?.airlineEmailStatus &&
        e1?.claimsReason == e2?.claimsReason;
  }

  @override
  int hash(ClaimsRecord? e) => const ListEquality().hash([
        e?.leadRef,
        e?.pnrNumber,
        e?.bvnNumber,
        e?.airlineResponse,
        e?.claimStatus,
        e?.flightDetailsSubmitted,
        e?.termsAccepted,
        e?.signatureSubmitted,
        e?.secureToken,
        e?.bankName,
        e?.accountNo,
        e?.accountName,
        e?.signedAt,
        e?.departure,
        e?.destination,
        e?.fullName,
        e?.durationOfDelay,
        e?.flightDate,
        e?.attachedDocument,
        e?.letterOfAuthority,
        e?.termsAndConditions,
        e?.airlineName,
        e?.claimsAmount,
        e?.flightNumber,
        e?.createdAt,
        e?.clientEmail,
        e?.signature,
        e?.nin,
        e?.passport,
        e?.loaUrl,
        e?.triggerAirlineEmail,
        e?.airlineEmailSelection,
        e?.airlineEmailStatus,
        e?.claimsReason
      ]);

  @override
  bool isValidKey(Object? o) => o is ClaimsRecord;
}
