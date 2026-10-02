import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'pipeline.dart';

/// The AI assistant: four tasks staff can ask for on a lead or a claim.
///
/// The server (firebase/functions/ai.js and ai-tasks.js) makes the call,
/// decides what is sent, and keeps every answer in `ai_outputs`. The
/// assistant advises only — nothing it returns changes a record. Acting on
/// an answer is always a separate step taken by a person.

enum AiTask {
  leadTriage('lead_triage', 'Triage this lead', RecordKind.lead),
  caseBrief('case_brief', 'Brief me on this claim', RecordKind.claim),
  classifyReply('classify_reply', 'Read an airline reply', RecordKind.claim),
  readEvidence('read_evidence', 'Check a document', RecordKind.claim);

  const AiTask(this.id, this.label, this.kind);

  /// The name the server knows it by.
  final String id;

  /// What the button says.
  final String label;
  final RecordKind kind;
}

/// One field of an answer, for display.
class AiField {
  const AiField(this.key, this.label, {this.isDraft = false});
  final String key;
  final String label;

  /// Text written for staff to edit and send; shown with a copy button.
  final bool isDraft;
}

/// The fields of each task's answer, in the order they are shown. The server's
/// schemas (ai-tasks.js) are the source; a field missing here is simply not
/// displayed.
const Map<String, List<AiField>> aiAnswerFields = {
  'lead_triage': [
    AiField('assessment', 'Assessment'),
    AiField('summary', 'Summary'),
    AiField('reasons', 'Why'),
    AiField('missing_information', 'Still needed'),
    AiField('suggested_next_step', 'Suggested next step'),
    AiField('draft_message_to_client', 'Draft message to the client',
        isDraft: true),
  ],
  'case_brief': [
    AiField('brief', 'Brief'),
    AiField('strengths', 'Strengths'),
    AiField('weaknesses', 'Weaknesses'),
    AiField('missing_evidence', 'Missing evidence'),
    AiField('suggested_next_step', 'Suggested next step'),
  ],
  'classify_reply': [
    AiField('category', 'The airline'),
    AiField('summary', 'What it said'),
    AiField('amount_offered', 'Amount offered'),
    AiField('defence_assessment', 'Does its reason hold?'),
    AiField('suggested_next_step', 'Suggested next step'),
    AiField('draft_reply', 'Draft reply to the airline', isDraft: true),
  ],
  'read_evidence': [
    AiField('document_type', 'Document'),
    AiField('legible', 'Legible'),
    AiField('mismatches', 'Disagrees with the claim'),
    AiField('passenger_name', 'Passenger'),
    AiField('booking_reference', 'Booking reference'),
    AiField('flight_number', 'Flight'),
    AiField('flight_date', 'Date'),
    AiField('route', 'Route'),
    AiField('ticket_price', 'Ticket price'),
    AiField('notes', 'Notes'),
  ],
};

/// A value the server returns as a code, in words.
String aiCodeLabel(String code) {
  const labels = {
    'likely_eligible': 'Likely eligible',
    'arguable': 'Arguable — needs review',
    'likely_not_eligible': 'Likely not eligible',
    'need_more_information': 'More information needed',
    'accepts_in_full': 'Accepts the claim in full',
    'offers_partial': 'Offers part of the claim',
    'rejects_extraordinary_circumstances':
        'Rejects it — extraordinary circumstances',
    'rejects_other_reason': 'Rejects it — another reason',
    'asks_for_information': 'Asks for more information',
    'acknowledgement_only': 'Acknowledges receipt only',
    'unclear': 'Unclear',
  };
  return labels[code] ?? code;
}

/// The outcome of asking the assistant for something.
class AiResult {
  const AiResult.ok(String this.outputId) : error = null;
  const AiResult.failed(String this.error) : outputId = null;

  /// The `ai_outputs` document holding the answer.
  final String? outputId;

  /// Null on success; otherwise a message fit to show the person who asked.
  final String? error;
  bool get succeeded => error == null;
}

const _aiAssistUrl =
    'https://us-central1-msmcrm-g24k37.cloudfunctions.net/aiAssist';

Future<AiResult> _post(Map<String, dynamic> data) async {
  try {
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (idToken == null) {
      return const AiResult.failed('You are signed out. Sign in again.');
    }
    final response = await http
        .post(
          Uri.parse(_aiAssistUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
          body: jsonEncode({'data': data}),
        )
        // The assistant thinks before it answers; give it time.
        .timeout(const Duration(seconds: 170));

    Map<String, dynamic> body = const {};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) body = decoded;
    } catch (_) {}
    if (response.statusCode == 200) {
      return AiResult.ok(body['id'] as String? ?? '');
    }
    return AiResult.failed((body['error'] as String?) ??
        'The AI assistant failed (error ${response.statusCode}).');
  } catch (_) {
    return const AiResult.failed(
        'The AI assistant did not answer in time. Check your connection and try again.');
  }
}

/// Ask the assistant to do [task] for the lead or claim [recordId].
/// [text] is the airline's reply for [AiTask.classifyReply]; [address] the
/// stored document for [AiTask.readEvidence].
Future<AiResult> runAiTask({
  required AiTask task,
  required String recordId,
  String? text,
  String? address,
}) =>
    _post({
      'task': task.id,
      'id': recordId,
      if (text != null) 'text': text,
      if (address != null) 'address': address,
    });

/// Record whether an answer was useful, for the Monitor page.
Future<AiResult> reviewAiAnswer({
  required String outputId,
  required bool useful,
  String note = '',
}) =>
    _post({
      'action': 'review',
      'id': outputId,
      'verdict': useful ? 'useful' : 'not_useful',
      'note': note,
    });
