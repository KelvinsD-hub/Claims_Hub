// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class PCPDetailsStruct extends FFFirebaseStruct {
  PCPDetailsStruct({
    String? carRegistration,
    String? financeProvider,
    DateTime? agreementDay,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _carRegistration = carRegistration,
        _financeProvider = financeProvider,
        _agreementDay = agreementDay,
        super(firestoreUtilData);

  // "car_registration" field.
  String? _carRegistration;
  String get carRegistration => _carRegistration ?? '';
  set carRegistration(String? val) => _carRegistration = val;

  bool hasCarRegistration() => _carRegistration != null;

  // "finance_provider" field.
  String? _financeProvider;
  String get financeProvider => _financeProvider ?? '';
  set financeProvider(String? val) => _financeProvider = val;

  bool hasFinanceProvider() => _financeProvider != null;

  // "agreement_day" field.
  DateTime? _agreementDay;
  DateTime? get agreementDay => _agreementDay;
  set agreementDay(DateTime? val) => _agreementDay = val;

  bool hasAgreementDay() => _agreementDay != null;

  static PCPDetailsStruct fromMap(Map<String, dynamic> data) =>
      PCPDetailsStruct(
        carRegistration: data['car_registration'] as String?,
        financeProvider: data['finance_provider'] as String?,
        agreementDay: data['agreement_day'] as DateTime?,
      );

  static PCPDetailsStruct? maybeFromMap(dynamic data) => data is Map
      ? PCPDetailsStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'car_registration': _carRegistration,
        'finance_provider': _financeProvider,
        'agreement_day': _agreementDay,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'car_registration': serializeParam(
          _carRegistration,
          ParamType.String,
        ),
        'finance_provider': serializeParam(
          _financeProvider,
          ParamType.String,
        ),
        'agreement_day': serializeParam(
          _agreementDay,
          ParamType.DateTime,
        ),
      }.withoutNulls;

  static PCPDetailsStruct fromSerializableMap(Map<String, dynamic> data) =>
      PCPDetailsStruct(
        carRegistration: deserializeParam(
          data['car_registration'],
          ParamType.String,
          false,
        ),
        financeProvider: deserializeParam(
          data['finance_provider'],
          ParamType.String,
          false,
        ),
        agreementDay: deserializeParam(
          data['agreement_day'],
          ParamType.DateTime,
          false,
        ),
      );

  @override
  String toString() => 'PCPDetailsStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is PCPDetailsStruct &&
        carRegistration == other.carRegistration &&
        financeProvider == other.financeProvider &&
        agreementDay == other.agreementDay;
  }

  @override
  int get hashCode => const ListEquality()
      .hash([carRegistration, financeProvider, agreementDay]);
}

PCPDetailsStruct createPCPDetailsStruct({
  String? carRegistration,
  String? financeProvider,
  DateTime? agreementDay,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    PCPDetailsStruct(
      carRegistration: carRegistration,
      financeProvider: financeProvider,
      agreementDay: agreementDay,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

PCPDetailsStruct? updatePCPDetailsStruct(
  PCPDetailsStruct? pCPDetails, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    pCPDetails
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addPCPDetailsStructData(
  Map<String, dynamic> firestoreData,
  PCPDetailsStruct? pCPDetails,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (pCPDetails == null) {
    return;
  }
  if (pCPDetails.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && pCPDetails.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final pCPDetailsData = getPCPDetailsFirestoreData(pCPDetails, forFieldValue);
  final nestedData = pCPDetailsData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = pCPDetails.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getPCPDetailsFirestoreData(
  PCPDetailsStruct? pCPDetails, [
  bool forFieldValue = false,
]) {
  if (pCPDetails == null) {
    return {};
  }
  final firestoreData = mapToFirestore(pCPDetails.toMap());

  // Add any Firestore field values
  mapToFirestore(pCPDetails.firestoreUtilData.fieldValues)
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getPCPDetailsListFirestoreData(
  List<PCPDetailsStruct>? pCPDetailss,
) =>
    pCPDetailss?.map((e) => getPCPDetailsFirestoreData(e, true)).toList() ?? [];
