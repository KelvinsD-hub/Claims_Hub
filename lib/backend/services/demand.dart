import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'casework.dart';

/// Sending a claim's demand letter to the airline.
///
/// The server's copy (firebase/functions/demand.js) is the one that is
/// enforced: the app asks the sendDemand Cloud Function, which checks the
/// claim and sets the letter going. [demandReadiness] is here so staff see
/// what is missing before they press Send, not after.

/// What stands between a claim and its demand letter.
class DemandReadiness {
  const DemandReadiness(this.blockers, this.warnings);

  /// The letter cannot go until these are fixed.
  final List<String> blockers;

  /// The letter is weaker without these, but can go.
  final List<String> warnings;

  bool get ready => blockers.isEmpty;
}

/// Checks a claim's document [data] for what the demand letter states.
DemandReadiness demandReadiness(Map<String, dynamic> data) {
  bool missing(String field) => '${data[field] ?? ''}'.trim().isEmpty;
  return DemandReadiness([
    if (missing('full_name')) 'The passenger\'s name is missing.',
    if (missing('airline_name')) 'The airline is missing.',
    if (missing('flight_number')) 'The flight number is missing.',
    if (missing('flight_date')) 'The flight date is missing.',
    if (missing('departure') || missing('destination')) 'The route is missing.',
    if (missing('signature'))
      'The client has not signed the letter of authority.',
  ], [
    if (missing('claims_amount'))
      'No amount is set: the letter will ask for "the applicable statutory amount".',
    if (missing('pnr_number')) 'No booking reference.',
    if (missing('duration_of_delay') && missing('claims_reason'))
      'Nothing says what went wrong with the flight.',
  ]);
}

final _email = RegExp(r'^[^\s@,;<>]+@[^\s@,;<>]+\.[^\s@,;<>]{2,}$');

/// Whether [value] is one plain email address.
bool isEmailAddress(String value) => _email.hasMatch(value.trim());

/// The directory address for [airlineName], matched loosely on the name
/// ("Air Peace" finds "Air Peace Limited"). Empty when nothing matches.
/// [directory] is a list of (airline name, legal email).
String suggestedAirlineEmail(
    String airlineName, List<({String name, String email})> directory) {
  String key(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  final wanted = key(airlineName);
  if (wanted.isEmpty) return '';
  for (final entry in directory) {
    if (key(entry.name) == wanted && isEmailAddress(entry.email)) {
      return entry.email.trim();
    }
  }
  for (final entry in directory) {
    final have = key(entry.name);
    if (have.isNotEmpty &&
        (have.contains(wanted) || wanted.contains(have)) &&
        isEmailAddress(entry.email)) {
      return entry.email.trim();
    }
  }
  return '';
}

const _sendDemandUrl =
    'https://us-central1-msmcrm-g24k37.cloudfunctions.net/sendDemand';

/// Ask the server to send the demand letter for [claimId] to [email]. With
/// [finalNotice] it sends the legal team's final notice instead.
Future<CaseActionResult> sendDemandLetter({
  required String claimId,
  required String email,
  bool finalNotice = false,
}) async {
  try {
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (idToken == null) {
      return const CaseActionResult.failed(
          'You are signed out. Sign in again.');
    }
    final response = await http
        .post(
          Uri.parse(_sendDemandUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
          body: jsonEncode({
            'data': {
              'id': claimId,
              'email': email.trim(),
              if (finalNotice) 'letter': 'final_notice',
            }
          }),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) return const CaseActionResult.ok();

    String? message;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>)
        message = decoded['error'] as String?;
    } catch (_) {}
    return CaseActionResult.failed(message ??
        'The letter could not be sent (error ${response.statusCode}).');
  } catch (_) {
    return const CaseActionResult.failed(
        'Could not reach the server. Check your connection and try again.');
  }
}
