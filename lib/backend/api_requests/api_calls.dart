import 'dart:convert';
import 'dart:typed_data';
import '../schema/structs/index.dart';

import 'package:flutter/foundation.dart';

import '/flutter_flow/flutter_flow_util.dart';
import 'api_manager.dart';

export 'api_manager.dart' show ApiCallResponse;

const _kPrivateApiFunctionName = 'ffPrivateApiCall';

class SendManualAirlineEmailCall {
  static Future<ApiCallResponse> call({
    String? airlineEmail = '',
    String? airlineName = '',
    String? clientName = '',
    String? pnr = '',
    String? flightNo = '',
    String? route = '',
    String? flightDate = '',
    String? delayDuration = '',
    String? compensation = '',
    String? loaPdfUrl = '',
    String? claimId = '',
  }) async {
    final ffApiRequestBody = '''
{
  "data": {
    "airlineEmail": "${escapeStringForJson(airlineEmail)}",
    "airlineName": "${escapeStringForJson(airlineName)}",
    "clientName": "${escapeStringForJson(clientName)}",
    "pnr": "${escapeStringForJson(pnr)}",
    "flightNo": "${escapeStringForJson(flightNo)}",
    "route": "${escapeStringForJson(route)}",
    "flightDate": "${escapeStringForJson(flightDate)}",
    "delayDuration": "${escapeStringForJson(delayDuration)}",
    "compensation": "${escapeStringForJson(compensation)}",
    "loaPdfUrl": "${escapeStringForJson(loaPdfUrl)}",
    "claimId": "${escapeStringForJson(claimId)}"
  }
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'sendManualAirlineEmail',
      apiUrl:
          'https://us-central1-msmcrm-g24k37.cloudfunctions.net/sendManualAirlineEmail',
      callType: ApiCallType.POST,
      headers: {},
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ApiPagingParams {
  int nextPageNumber = 0;
  int numItems = 0;
  dynamic lastResponse;

  ApiPagingParams({
    required this.nextPageNumber,
    required this.numItems,
    required this.lastResponse,
  });

  @override
  String toString() =>
      'PagingParams(nextPageNumber: $nextPageNumber, numItems: $numItems, lastResponse: $lastResponse,)';
}

String _toEncodable(dynamic item) {
  if (item is DocumentReference) {
    return item.path;
  }
  return item;
}

String _serializeList(List? list) {
  list ??= <String>[];
  try {
    return json.encode(list, toEncodable: _toEncodable);
  } catch (_) {
    if (kDebugMode) {
      print("List serialization failed. Returning empty list.");
    }
    return '[]';
  }
}

String _serializeJson(dynamic jsonVar, [bool isList = false]) {
  jsonVar ??= (isList ? [] : {});
  try {
    return json.encode(jsonVar, toEncodable: _toEncodable);
  } catch (_) {
    if (kDebugMode) {
      print("Json serialization failed. Returning empty json.");
    }
    return isList ? '[]' : '{}';
  }
}

String? escapeStringForJson(String? input) {
  if (input == null) {
    return null;
  }
  return input
      .replaceAll('\\', '\\\\')
      .replaceAll('"', '\\"')
      .replaceAll('\n', '\\n')
      .replaceAll('\t', '\\t');
}
