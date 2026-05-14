// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class BankDetailsStruct extends FFFirebaseStruct {
  BankDetailsStruct({
    String? bankName,
    String? accountNo,
    String? accountName,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _bankName = bankName,
        _accountNo = accountNo,
        _accountName = accountName,
        super(firestoreUtilData);

  // "bank_name" field.
  String? _bankName;
  String get bankName => _bankName ?? '';
  set bankName(String? val) => _bankName = val;

  bool hasBankName() => _bankName != null;

  // "account_no" field.
  String? _accountNo;
  String get accountNo => _accountNo ?? '';
  set accountNo(String? val) => _accountNo = val;

  bool hasAccountNo() => _accountNo != null;

  // "account_name" field.
  String? _accountName;
  String get accountName => _accountName ?? '';
  set accountName(String? val) => _accountName = val;

  bool hasAccountName() => _accountName != null;

  static BankDetailsStruct fromMap(Map<String, dynamic> data) =>
      BankDetailsStruct(
        bankName: data['bank_name'] as String?,
        accountNo: data['account_no'] as String?,
        accountName: data['account_name'] as String?,
      );

  static BankDetailsStruct? maybeFromMap(dynamic data) => data is Map
      ? BankDetailsStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'bank_name': _bankName,
        'account_no': _accountNo,
        'account_name': _accountName,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'bank_name': serializeParam(
          _bankName,
          ParamType.String,
        ),
        'account_no': serializeParam(
          _accountNo,
          ParamType.String,
        ),
        'account_name': serializeParam(
          _accountName,
          ParamType.String,
        ),
      }.withoutNulls;

  static BankDetailsStruct fromSerializableMap(Map<String, dynamic> data) =>
      BankDetailsStruct(
        bankName: deserializeParam(
          data['bank_name'],
          ParamType.String,
          false,
        ),
        accountNo: deserializeParam(
          data['account_no'],
          ParamType.String,
          false,
        ),
        accountName: deserializeParam(
          data['account_name'],
          ParamType.String,
          false,
        ),
      );

  @override
  String toString() => 'BankDetailsStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is BankDetailsStruct &&
        bankName == other.bankName &&
        accountNo == other.accountNo &&
        accountName == other.accountName;
  }

  @override
  int get hashCode =>
      const ListEquality().hash([bankName, accountNo, accountName]);
}

BankDetailsStruct createBankDetailsStruct({
  String? bankName,
  String? accountNo,
  String? accountName,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    BankDetailsStruct(
      bankName: bankName,
      accountNo: accountNo,
      accountName: accountName,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

BankDetailsStruct? updateBankDetailsStruct(
  BankDetailsStruct? bankDetails, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    bankDetails
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addBankDetailsStructData(
  Map<String, dynamic> firestoreData,
  BankDetailsStruct? bankDetails,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (bankDetails == null) {
    return;
  }
  if (bankDetails.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && bankDetails.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final bankDetailsData =
      getBankDetailsFirestoreData(bankDetails, forFieldValue);
  final nestedData =
      bankDetailsData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = bankDetails.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getBankDetailsFirestoreData(
  BankDetailsStruct? bankDetails, [
  bool forFieldValue = false,
]) {
  if (bankDetails == null) {
    return {};
  }
  final firestoreData = mapToFirestore(bankDetails.toMap());

  // Add any Firestore field values
  mapToFirestore(bankDetails.firestoreUtilData.fieldValues)
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getBankDetailsListFirestoreData(
  List<BankDetailsStruct>? bankDetailss,
) =>
    bankDetailss?.map((e) => getBankDetailsFirestoreData(e, true)).toList() ??
    [];
