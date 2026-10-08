import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'pipeline.dart';

/// Asking a client for more information on a lead or claim.
///
/// The server's copy (firebase/functions/info-requests.js) is the one that is
/// enforced: it checks the request, emails the client a link to a form on the
/// website, and writes their answers onto the record. The app only asks it.

/// What staff can ask for, in the order the dialog lists them. The keys and
/// labels match ITEMS in info-requests.js.
const infoRequestItems = <String, String>{
  'flight_number': 'Flight number',
  'flight_date': 'Flight date',
  'booking_reference': 'Booking reference',
  'fare': 'Ticket price',
  'date_of_birth': 'Date of birth',
  'address': 'Home address',
  'bank_details': 'Bank details',
  'phone': 'Phone number',
  'boarding_pass': 'Boarding pass',
  'ticket_receipt': 'Ticket or receipt',
  'id_document': 'Photo ID',
  'airline_message': 'Airline message',
  'expense_receipts': 'Expense receipts',
};

/// How every item reads on a request, including those only the full claim
/// form sent with a new lead asks for (INTAKE_ITEMS in info-requests.js).
const infoRequestLabels = <String, String>{
  'what_happened': 'What happened',
  'airline': 'Airline',
  'route_from': 'Flying from',
  'route_to': 'Flying to',
  'story': 'In their words',
  'email': 'Email address',
  ...infoRequestItems,
};

/// Items the client answers with a file rather than typing.
const infoRequestFileItems = {
  'boarding_pass',
  'ticket_receipt',
  'id_document',
  'airline_message',
  'expense_receipts',
};

/// The outcome of sending a request.
class InfoRequestResult {
  const InfoRequestResult.sent({
    required String this.link,
    required String this.email,
    required this.emailed,
  }) : error = null;
  const InfoRequestResult.failed(String this.error)
      : link = null,
        email = null,
        emailed = false;

  /// Null on success; otherwise a message fit to show the person who asked.
  final String? error;

  /// The client's link, to copy into WhatsApp or a text.
  final String? link;
  final String? email;

  /// Whether the email to the client went. The link works either way.
  final bool emailed;
  bool get succeeded => error == null;
}

const _infoRequestUrl =
    'https://us-central1-msmcrm-g24k37.cloudfunctions.net/infoRequest';

Future<(int, Map<String, dynamic>)> _post(Map<String, dynamic> data) async {
  final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
  if (idToken == null) {
    return (401, {'error': 'You are signed out. Sign in again.'});
  }
  final response = await http
      .post(
        Uri.parse(_infoRequestUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({'data': data}),
      )
      .timeout(const Duration(seconds: 40));
  Map<String, dynamic> body = {};
  try {
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) body = decoded;
  } catch (_) {}
  return (response.statusCode, body);
}

/// Ask the client of [recordId] for [items] and up to three [questions].
/// With [sendEmail] false only the link is made, for sending another way.
Future<InfoRequestResult> sendInfoRequest({
  required RecordKind kind,
  required String recordId,
  required List<String> items,
  required List<String> questions,
  required String message,
  bool sendEmail = true,
}) async {
  try {
    final (status, body) = await _post({
      'action': 'create',
      'kind': kind == RecordKind.lead ? 'lead' : 'claim',
      'id': recordId,
      'items': items,
      'questions': questions,
      'message': message,
      'send_email': sendEmail,
    });
    if (status == 200) {
      return InfoRequestResult.sent(
        link: body['link'] as String? ?? '',
        email: body['email'] as String? ?? '',
        emailed: body['emailed'] == true,
      );
    }
    return InfoRequestResult.failed(body['error'] as String? ??
        'The request could not be sent (error $status).');
  } catch (_) {
    return const InfoRequestResult.failed(
        'Could not reach the server. Check your connection and try again.');
  }
}

/// Withdraw an open request so its link stops working. Returns an error
/// message, or null when it worked.
Future<String?> cancelInfoRequest(String requestId) async {
  try {
    final (status, body) =
        await _post({'action': 'cancel', 'id': requestId});
    if (status == 200) return null;
    return body['error'] as String? ??
        'The request could not be withdrawn (error $status).';
  } catch (_) {
    return 'Could not reach the server. Check your connection and try again.';
  }
}

/// Requests made on [record], newest first.
Stream<List<DocumentSnapshot<Map<String, dynamic>>>> infoRequestsFor(
    DocumentReference record) {
  return FirebaseFirestore.instance
      .collection('info_requests')
      .where('record', isEqualTo: record)
      .snapshots()
      .map((snap) {
    final docs = snap.docs.toList();
    DateTime at(DocumentSnapshot<Map<String, dynamic>> d) {
      final v = d.data()?['created_at'];
      return v is Timestamp ? v.toDate() : DateTime.now();
    }

    docs.sort((a, b) => at(b).compareTo(at(a)));
    return docs;
  });
}
