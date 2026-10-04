import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// Staff entering a lead: someone who phoned, sent a WhatsApp or a social
/// media message, or walked in.
///
/// The server's copy (firebase/functions/add-lead.js) checks it, saves it
/// with who entered it, and, when asked, sends the person the full claim
/// form to fill in themselves. The lists match REACHED, HEARD and PROBLEMS
/// there.

/// How the person got in touch.
const leadReachedVia = [
  'Phone call',
  'WhatsApp',
  'Social media message',
  'Walk-in',
  'Email',
  'Other',
];

/// Where they heard about us. Counted on the Links page beside the ad links.
const leadHeardFrom = [
  'Facebook',
  'Instagram',
  'X',
  'TikTok',
  'WhatsApp',
  'Google search',
  'Friend or family',
  'Radio or TV',
  'Other',
];

/// What went wrong, in the website's words.
const leadProblems = [
  'Flight delay',
  'Flight cancellation',
  'Denied boarding',
  'Missed connection',
  'Downgrade',
  'Baggage claim',
  'Something else',
];

/// The outcome of adding a lead.
class AddLeadResult {
  const AddLeadResult({
    this.id,
    this.error,
    this.link,
    this.email = '',
    this.phone = '',
    this.emailed = false,
  });

  /// The new lead, or null if it was not saved. A lead can be saved and
  /// still have an [error], when the form could not be sent.
  final String? id;
  final String? error;

  /// The claim form's link, when one was sent.
  final String? link;
  final String email;
  final String phone;
  final bool emailed;

  bool get saved => id != null && id!.isNotEmpty;
}

const _addLeadUrl =
    'https://us-central1-msmcrm-g24k37.cloudfunctions.net/addLead';

/// Save a lead. [fields] are the form's values under the server's names.
/// With [sendForm] the person is sent the claim form; [sendEmail] false
/// makes only the link, for WhatsApp or text.
Future<AddLeadResult> addLead({
  required Map<String, String> fields,
  required bool sendForm,
  required bool own,
  bool sendEmail = true,
}) async {
  final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
  if (idToken == null) {
    return const AddLeadResult(error: 'You are signed out. Sign in again.');
  }
  try {
    final response = await http
        .post(
          Uri.parse(_addLeadUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
          body: jsonEncode({
            'data': {
              ...fields,
              'mode': sendForm ? 'form' : 'details',
              'own': own,
              'send_email': sendEmail,
            },
          }),
        )
        .timeout(const Duration(seconds: 40));
    Map<String, dynamic> body = {};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) body = decoded;
    } catch (_) {}
    final id = body['id'] as String?;
    if (response.statusCode == 200) {
      return AddLeadResult(
        id: id,
        link: body['link'] as String?,
        email: body['email'] as String? ?? '',
        phone: body['phone'] as String? ?? '',
        emailed: body['emailed'] == true,
      );
    }
    return AddLeadResult(
      id: id,
      error: body['error'] as String? ??
          'The lead could not be saved (error ${response.statusCode}).',
    );
  } catch (_) {
    return const AddLeadResult(
        error: 'Could not reach the server. Check your connection and try again.');
  }
}

/// A WhatsApp chat with [phone], with [message] typed in ready to send.
/// Null when the number cannot be used.
Uri? whatsAppLink(String phone, String message) {
  final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length < 7) return null;
  return Uri.https('wa.me', '/$digits', {'text': message});
}
