import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'pipeline.dart';

/// Casework: who owns a lead or claim, what has to happen to it next and by
/// when, and how far the legal team has taken an escalated claim.
///
/// The server's copy (firebase/functions/casework.js) is the one that is
/// enforced. The app never writes these fields itself: it asks the caseAction
/// Cloud Function, which checks the request, writes it and records it in the
/// event log. The database rules refuse them written any other way.

/// Where an escalated claim (stage "With Solicitor") has got to, in the usual
/// order. Court is a case-by-case decision, never the automatic next step.
abstract final class LegalStage {
  static const review = 'Legal review';
  static const noticeSent = 'Final notice sent';
  static const ncaa = 'NCAA complaint filed';
  static const court = 'Court proceedings';

  static const all = [review, noticeSent, ncaa, court];
}

const _managerRoles = ['Manager', 'Admin', 'Super Admin'];

/// Managers and above assign work to other people and reopen closed records.
bool isManagerRole(String role) => _managerRoles.contains(role);

/// Who may hold or work the legal side of a claim.
bool isLegalRole(String role) => role == 'Solicitor' || isManagerRole(role);

/// The casework fields on a lead or a claim, read from its document data.
class Casework {
  Casework.of(Map<String, dynamic> data)
      : handlerUid = _text(data['handler_uid']),
        handlerName = _text(data['handler_name']),
        lawyerUid = _text(data['lawyer_uid']),
        lawyerName = _text(data['lawyer_name']),
        nextAction = _text(data['next_action']),
        nextActionDue = _date(data['next_action_due']),
        legalStage = _text(data['legal_stage']),
        escalatedAt = _date(data['escalated_at']),
        airlineReplyAt = _date(data['airline_reply_at']),
        airlineReplySummary = _text(data['airline_reply_summary']),
        settlementOffer = _number(data['settlement_offer_amount']),
        amountRecovered = _number(data['amount_recovered']);

  final String handlerUid;
  final String handlerName;
  final String lawyerUid;
  final String lawyerName;
  final String nextAction;
  final DateTime? nextActionDue;

  /// Empty unless the claim has been with the legal team.
  final String legalStage;
  final DateTime? escalatedAt;
  final DateTime? airlineReplyAt;
  final String airlineReplySummary;
  final double? settlementOffer;
  final double? amountRecovered;

  bool get hasHandler => handlerUid.isNotEmpty;
  bool get hasLawyer => lawyerUid.isNotEmpty;
  bool get hasNextAction => nextAction.isNotEmpty;

  /// The date has passed and the action is still there.
  bool get isOverdue =>
      hasNextAction &&
      nextActionDue != null &&
      nextActionDue!.isBefore(DateTime.now());

  /// Whole days until the due date; negative once it has passed.
  int? get daysUntilDue {
    if (nextActionDue == null) return null;
    final today = DateTime.now();
    final due = nextActionDue!;
    return DateTime(due.year, due.month, due.day)
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;
  }

  /// "Overdue by 3 days", "Due today", "Due in 5 days".
  String get dueLabel {
    final days = daysUntilDue;
    if (days == null) return '';
    if (days < -1) return 'Overdue by ${-days} days';
    if (days == -1) return 'Overdue by 1 day';
    if (days == 0) return 'Due today';
    if (days == 1) return 'Due tomorrow';
    return 'Due in $days days';
  }

  static String _text(dynamic v) => v is String ? v : '';
  static double? _number(dynamic v) => v is num ? v.toDouble() : null;
  static DateTime? _date(dynamic v) {
    if (v is DateTime) return v;
    if (v is Timestamp) return v.toDate();
    return null;
  }
}

/// The outcome of asking the server for a piece of casework.
class CaseActionResult {
  const CaseActionResult.ok() : error = null;
  const CaseActionResult.failed(String this.error);

  /// Null on success; otherwise a message fit to show the person who asked.
  final String? error;
  bool get succeeded => error == null;
}

const _caseActionUrl =
    'https://us-central1-msmcrm-g24k37.cloudfunctions.net/caseAction';

String _kind(RecordKind kind) => kind == RecordKind.lead ? 'lead' : 'claim';

Future<CaseActionResult> _post(Map<String, dynamic> data) async {
  try {
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (idToken == null) {
      return const CaseActionResult.failed('You are signed out. Sign in again.');
    }
    final response = await http
        .post(
          Uri.parse(_caseActionUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
          body: jsonEncode({'data': data}),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) return const CaseActionResult.ok();

    String? message;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) message = decoded['error'] as String?;
    } catch (_) {}
    return CaseActionResult.failed(
        message ?? 'That could not be saved (error ${response.statusCode}).');
  } catch (_) {
    return const CaseActionResult.failed(
        'Could not reach the server. Check your connection and try again.');
  }
}

/// Put [toUid] in charge of a record, or pass an empty [toUid] to unassign.
/// [lawyer] assigns the lawyer on a claim instead of its handler.
Future<CaseActionResult> assignRecord({
  required RecordKind kind,
  required String id,
  required String toUid,
  bool lawyer = false,
}) =>
    _post({
      'action': 'assign',
      'kind': _kind(kind),
      'id': id,
      'slot': lawyer ? 'lawyer' : 'handler',
      'to': toUid,
    });

/// Say what happens to a record next and by when. An empty [text] clears it.
Future<CaseActionResult> setNextAction({
  required RecordKind kind,
  required String id,
  required String text,
  DateTime? due,
}) =>
    _post({
      'action': 'next_action',
      'kind': _kind(kind),
      'id': id,
      'text': text,
      'due': due == null
          ? ''
          : '${due.year.toString().padLeft(4, '0')}-'
              '${due.month.toString().padLeft(2, '0')}-'
              '${due.day.toString().padLeft(2, '0')}',
    });

/// Move an escalated claim to another legal stage. Going to court needs a
/// [note] saying why.
Future<CaseActionResult> setLegalStage({
  required String claimId,
  required String to,
  String note = '',
}) =>
    _post({'action': 'legal_stage', 'id': claimId, 'to': to, 'note': note});

enum CaseNoteType { note, airlineReply, offer }

/// Add to a record's case file. An [offer] carries the [amount] in naira.
Future<CaseActionResult> addCaseNote({
  required RecordKind kind,
  required String id,
  required String text,
  CaseNoteType type = CaseNoteType.note,
  double? amount,
}) =>
    _post({
      'action': 'note',
      'kind': _kind(kind),
      'id': id,
      'type': switch (type) {
        CaseNoteType.note => 'note',
        CaseNoteType.airlineReply => 'airline_reply',
        CaseNoteType.offer => 'offer',
      },
      'text': text,
      if (amount != null) 'amount': amount,
    });
