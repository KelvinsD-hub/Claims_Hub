// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class HousingDetailsStruct extends FFFirebaseStruct {
  HousingDetailsStruct({
    String? landlordName,
    String? issueType,
    bool? isEmergency,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _landlordName = landlordName,
        _issueType = issueType,
        _isEmergency = isEmergency,
        super(firestoreUtilData);

  // "landlord_name" field.
  String? _landlordName;
  String get landlordName => _landlordName ?? '';
  set landlordName(String? val) => _landlordName = val;

  bool hasLandlordName() => _landlordName != null;

  // "issue_type" field.
  String? _issueType;
  String get issueType => _issueType ?? '';
  set issueType(String? val) => _issueType = val;

  bool hasIssueType() => _issueType != null;

  // "is_emergency" field.
  bool? _isEmergency;
  bool get isEmergency => _isEmergency ?? false;
  set isEmergency(bool? val) => _isEmergency = val;

  bool hasIsEmergency() => _isEmergency != null;

  static HousingDetailsStruct fromMap(Map<String, dynamic> data) =>
      HousingDetailsStruct(
        landlordName: data['landlord_name'] as String?,
        issueType: data['issue_type'] as String?,
        isEmergency: data['is_emergency'] as bool?,
      );

  static HousingDetailsStruct? maybeFromMap(dynamic data) => data is Map
      ? HousingDetailsStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'landlord_name': _landlordName,
        'issue_type': _issueType,
        'is_emergency': _isEmergency,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'landlord_name': serializeParam(
          _landlordName,
          ParamType.String,
        ),
        'issue_type': serializeParam(
          _issueType,
          ParamType.String,
        ),
        'is_emergency': serializeParam(
          _isEmergency,
          ParamType.bool,
        ),
      }.withoutNulls;

  static HousingDetailsStruct fromSerializableMap(Map<String, dynamic> data) =>
      HousingDetailsStruct(
        landlordName: deserializeParam(
          data['landlord_name'],
          ParamType.String,
          false,
        ),
        issueType: deserializeParam(
          data['issue_type'],
          ParamType.String,
          false,
        ),
        isEmergency: deserializeParam(
          data['is_emergency'],
          ParamType.bool,
          false,
        ),
      );

  @override
  String toString() => 'HousingDetailsStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is HousingDetailsStruct &&
        landlordName == other.landlordName &&
        issueType == other.issueType &&
        isEmergency == other.isEmergency;
  }

  @override
  int get hashCode =>
      const ListEquality().hash([landlordName, issueType, isEmergency]);
}

HousingDetailsStruct createHousingDetailsStruct({
  String? landlordName,
  String? issueType,
  bool? isEmergency,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    HousingDetailsStruct(
      landlordName: landlordName,
      issueType: issueType,
      isEmergency: isEmergency,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

HousingDetailsStruct? updateHousingDetailsStruct(
  HousingDetailsStruct? housingDetails, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    housingDetails
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addHousingDetailsStructData(
  Map<String, dynamic> firestoreData,
  HousingDetailsStruct? housingDetails,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (housingDetails == null) {
    return;
  }
  if (housingDetails.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && housingDetails.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final housingDetailsData =
      getHousingDetailsFirestoreData(housingDetails, forFieldValue);
  final nestedData =
      housingDetailsData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = housingDetails.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getHousingDetailsFirestoreData(
  HousingDetailsStruct? housingDetails, [
  bool forFieldValue = false,
]) {
  if (housingDetails == null) {
    return {};
  }
  final firestoreData = mapToFirestore(housingDetails.toMap());

  // Add any Firestore field values
  mapToFirestore(housingDetails.firestoreUtilData.fieldValues)
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getHousingDetailsListFirestoreData(
  List<HousingDetailsStruct>? housingDetailss,
) =>
    housingDetailss
        ?.map((e) => getHousingDetailsFirestoreData(e, true))
        .toList() ??
    [];
