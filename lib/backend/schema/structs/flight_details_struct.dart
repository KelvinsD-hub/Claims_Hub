// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class FlightDetailsStruct extends FFFirebaseStruct {
  FlightDetailsStruct({
    String? fullName,
    String? email,
    String? bvn,
    String? airlineName,
    String? flightDate,
    String? bookingRefPNR,
    String? durationofDelay,
    String? reasonGiven,
    String? bankDetails,
    List<String>? uploadBoardingPass,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _fullName = fullName,
        _email = email,
        _bvn = bvn,
        _airlineName = airlineName,
        _flightDate = flightDate,
        _bookingRefPNR = bookingRefPNR,
        _durationofDelay = durationofDelay,
        _reasonGiven = reasonGiven,
        _bankDetails = bankDetails,
        _uploadBoardingPass = uploadBoardingPass,
        super(firestoreUtilData);

  // "FullName" field.
  String? _fullName;
  String get fullName => _fullName ?? '';
  set fullName(String? val) => _fullName = val;

  bool hasFullName() => _fullName != null;

  // "Email" field.
  String? _email;
  String get email => _email ?? '';
  set email(String? val) => _email = val;

  bool hasEmail() => _email != null;

  // "BVN" field.
  String? _bvn;
  String get bvn => _bvn ?? '';
  set bvn(String? val) => _bvn = val;

  bool hasBvn() => _bvn != null;

  // "AirlineName" field.
  String? _airlineName;
  String get airlineName => _airlineName ?? '';
  set airlineName(String? val) => _airlineName = val;

  bool hasAirlineName() => _airlineName != null;

  // "FlightDate" field.
  String? _flightDate;
  String get flightDate => _flightDate ?? '';
  set flightDate(String? val) => _flightDate = val;

  bool hasFlightDate() => _flightDate != null;

  // "BookingRefPNR" field.
  String? _bookingRefPNR;
  String get bookingRefPNR => _bookingRefPNR ?? '';
  set bookingRefPNR(String? val) => _bookingRefPNR = val;

  bool hasBookingRefPNR() => _bookingRefPNR != null;

  // "DurationofDelay" field.
  String? _durationofDelay;
  String get durationofDelay => _durationofDelay ?? '';
  set durationofDelay(String? val) => _durationofDelay = val;

  bool hasDurationofDelay() => _durationofDelay != null;

  // "ReasonGiven" field.
  String? _reasonGiven;
  String get reasonGiven => _reasonGiven ?? '';
  set reasonGiven(String? val) => _reasonGiven = val;

  bool hasReasonGiven() => _reasonGiven != null;

  // "BankDetails" field.
  String? _bankDetails;
  String get bankDetails => _bankDetails ?? '';
  set bankDetails(String? val) => _bankDetails = val;

  bool hasBankDetails() => _bankDetails != null;

  // "UploadBoardingPass" field.
  List<String>? _uploadBoardingPass;
  List<String> get uploadBoardingPass => _uploadBoardingPass ?? const [];
  set uploadBoardingPass(List<String>? val) => _uploadBoardingPass = val;

  void updateUploadBoardingPass(Function(List<String>) updateFn) {
    updateFn(_uploadBoardingPass ??= []);
  }

  bool hasUploadBoardingPass() => _uploadBoardingPass != null;

  static FlightDetailsStruct fromMap(Map<String, dynamic> data) =>
      FlightDetailsStruct(
        fullName: data['FullName'] as String?,
        email: data['Email'] as String?,
        bvn: data['BVN'] as String?,
        airlineName: data['AirlineName'] as String?,
        flightDate: data['FlightDate'] as String?,
        bookingRefPNR: data['BookingRefPNR'] as String?,
        durationofDelay: data['DurationofDelay'] as String?,
        reasonGiven: data['ReasonGiven'] as String?,
        bankDetails: data['BankDetails'] as String?,
        uploadBoardingPass: getDataList(data['UploadBoardingPass']),
      );

  static FlightDetailsStruct? maybeFromMap(dynamic data) => data is Map
      ? FlightDetailsStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'FullName': _fullName,
        'Email': _email,
        'BVN': _bvn,
        'AirlineName': _airlineName,
        'FlightDate': _flightDate,
        'BookingRefPNR': _bookingRefPNR,
        'DurationofDelay': _durationofDelay,
        'ReasonGiven': _reasonGiven,
        'BankDetails': _bankDetails,
        'UploadBoardingPass': _uploadBoardingPass,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'FullName': serializeParam(
          _fullName,
          ParamType.String,
        ),
        'Email': serializeParam(
          _email,
          ParamType.String,
        ),
        'BVN': serializeParam(
          _bvn,
          ParamType.String,
        ),
        'AirlineName': serializeParam(
          _airlineName,
          ParamType.String,
        ),
        'FlightDate': serializeParam(
          _flightDate,
          ParamType.String,
        ),
        'BookingRefPNR': serializeParam(
          _bookingRefPNR,
          ParamType.String,
        ),
        'DurationofDelay': serializeParam(
          _durationofDelay,
          ParamType.String,
        ),
        'ReasonGiven': serializeParam(
          _reasonGiven,
          ParamType.String,
        ),
        'BankDetails': serializeParam(
          _bankDetails,
          ParamType.String,
        ),
        'UploadBoardingPass': serializeParam(
          _uploadBoardingPass,
          ParamType.String,
          isList: true,
        ),
      }.withoutNulls;

  static FlightDetailsStruct fromSerializableMap(Map<String, dynamic> data) =>
      FlightDetailsStruct(
        fullName: deserializeParam(
          data['FullName'],
          ParamType.String,
          false,
        ),
        email: deserializeParam(
          data['Email'],
          ParamType.String,
          false,
        ),
        bvn: deserializeParam(
          data['BVN'],
          ParamType.String,
          false,
        ),
        airlineName: deserializeParam(
          data['AirlineName'],
          ParamType.String,
          false,
        ),
        flightDate: deserializeParam(
          data['FlightDate'],
          ParamType.String,
          false,
        ),
        bookingRefPNR: deserializeParam(
          data['BookingRefPNR'],
          ParamType.String,
          false,
        ),
        durationofDelay: deserializeParam(
          data['DurationofDelay'],
          ParamType.String,
          false,
        ),
        reasonGiven: deserializeParam(
          data['ReasonGiven'],
          ParamType.String,
          false,
        ),
        bankDetails: deserializeParam(
          data['BankDetails'],
          ParamType.String,
          false,
        ),
        uploadBoardingPass: deserializeParam<String>(
          data['UploadBoardingPass'],
          ParamType.String,
          true,
        ),
      );

  @override
  String toString() => 'FlightDetailsStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    const listEquality = ListEquality();
    return other is FlightDetailsStruct &&
        fullName == other.fullName &&
        email == other.email &&
        bvn == other.bvn &&
        airlineName == other.airlineName &&
        flightDate == other.flightDate &&
        bookingRefPNR == other.bookingRefPNR &&
        durationofDelay == other.durationofDelay &&
        reasonGiven == other.reasonGiven &&
        bankDetails == other.bankDetails &&
        listEquality.equals(uploadBoardingPass, other.uploadBoardingPass);
  }

  @override
  int get hashCode => const ListEquality().hash([
        fullName,
        email,
        bvn,
        airlineName,
        flightDate,
        bookingRefPNR,
        durationofDelay,
        reasonGiven,
        bankDetails,
        uploadBoardingPass
      ]);
}

FlightDetailsStruct createFlightDetailsStruct({
  String? fullName,
  String? email,
  String? bvn,
  String? airlineName,
  String? flightDate,
  String? bookingRefPNR,
  String? durationofDelay,
  String? reasonGiven,
  String? bankDetails,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    FlightDetailsStruct(
      fullName: fullName,
      email: email,
      bvn: bvn,
      airlineName: airlineName,
      flightDate: flightDate,
      bookingRefPNR: bookingRefPNR,
      durationofDelay: durationofDelay,
      reasonGiven: reasonGiven,
      bankDetails: bankDetails,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

FlightDetailsStruct? updateFlightDetailsStruct(
  FlightDetailsStruct? flightDetails, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    flightDetails
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addFlightDetailsStructData(
  Map<String, dynamic> firestoreData,
  FlightDetailsStruct? flightDetails,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (flightDetails == null) {
    return;
  }
  if (flightDetails.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && flightDetails.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final flightDetailsData =
      getFlightDetailsFirestoreData(flightDetails, forFieldValue);
  final nestedData =
      flightDetailsData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = flightDetails.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getFlightDetailsFirestoreData(
  FlightDetailsStruct? flightDetails, [
  bool forFieldValue = false,
]) {
  if (flightDetails == null) {
    return {};
  }
  final firestoreData = mapToFirestore(flightDetails.toMap());

  // Add any Firestore field values
  mapToFirestore(flightDetails.firestoreUtilData.fieldValues)
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getFlightDetailsListFirestoreData(
  List<FlightDetailsStruct>? flightDetailss,
) =>
    flightDetailss
        ?.map((e) => getFlightDetailsFirestoreData(e, true))
        .toList() ??
    [];
