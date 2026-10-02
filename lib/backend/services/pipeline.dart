import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// The pipeline: every stage a lead or a claim can be in, and which moves
/// between them are allowed.
///
/// The server's copy (firebase/functions/pipeline.js) is the one that is
/// enforced; this one only decides what the menus offer, so the two must list
/// the same stages and moves — change them together. The app never writes a
/// stage itself: it asks the changeStage Cloud Function through [changeStage],
/// and the database rules refuse a stage written any other way.

enum RecordKind { lead, claim }

abstract final class LeadStage {
  static const newLead = 'New lead';
  static const contacted = 'Contacted';
  static const qualified = 'Qualified';
  static const rejected = 'Rejected';

  static const all = [newLead, contacted, qualified, rejected];
}

abstract final class ClaimStage {
  /// Waiting for the client's evidence.
  static const detailsPending = 'Details Pending';

  /// Evidence in; the client still has to sign.
  static const termsPending = 'Terms Pending';

  /// The client has finished; nobody has picked it up yet.
  static const readyForReview = 'Ready For Review';

  /// Staff are checking it.
  static const underReview = 'Under Review';

  /// Approved; the letter to the airline has not gone yet.
  static const demandPending = 'Demand Pending';

  /// The airline has our demand.
  static const awaitingReply = 'Awaiting Reply';

  /// Escalated to the legal team.
  static const withSolicitor = 'With Solicitor';
  static const won = 'Won';
  static const lost = 'Lost';

  /// Closed without an outcome: cancelled or not pursued.
  static const withdrawn = 'Withdrawn';

  /// The client has been paid out.
  static const paid = 'Paid';

  static const all = [
    detailsPending,
    termsPending,
    readyForReview,
    underReview,
    demandPending,
    awaitingReply,
    withSolicitor,
    won,
    lost,
    withdrawn,
    paid,
  ];

  /// Stages a claim can sit in with nothing left to do.
  static const closed = [won, lost, withdrawn, paid];

  /// Stages where the claim is with the airline or beyond.
  static const open = [
    detailsPending,
    termsPending,
    readyForReview,
    underReview,
    demandPending,
    awaitingReply,
    withSolicitor,
  ];
}

class _Moves {
  const _Moves(this.to, [this.managerOnly = const []]);
  final List<String> to;
  final List<String> managerOnly;
}

const _managers = ['Manager', 'Admin', 'Super Admin'];

const Map<String, _Moves> _leadMoves = {
  LeadStage.newLead:
      _Moves([LeadStage.contacted, LeadStage.qualified, LeadStage.rejected]),
  LeadStage.contacted: _Moves([LeadStage.qualified, LeadStage.rejected]),
  LeadStage.qualified: _Moves([]),
  LeadStage.rejected: _Moves([], [LeadStage.newLead]),
};

const Map<String, _Moves> _claimMoves = {
  ClaimStage.detailsPending: _Moves([
    ClaimStage.termsPending,
    ClaimStage.readyForReview,
    ClaimStage.withdrawn
  ]),
  ClaimStage.termsPending: _Moves([
    ClaimStage.detailsPending,
    ClaimStage.readyForReview,
    ClaimStage.withdrawn
  ]),
  ClaimStage.readyForReview: _Moves([
    ClaimStage.underReview,
    ClaimStage.demandPending,
    ClaimStage.detailsPending,
    ClaimStage.withdrawn
  ]),
  ClaimStage.underReview: _Moves([
    ClaimStage.demandPending,
    ClaimStage.detailsPending,
    ClaimStage.withdrawn
  ]),
  ClaimStage.demandPending: _Moves(
      [ClaimStage.awaitingReply, ClaimStage.underReview, ClaimStage.withdrawn]),
  ClaimStage.awaitingReply: _Moves([
    ClaimStage.won,
    ClaimStage.lost,
    ClaimStage.withSolicitor,
    ClaimStage.withdrawn
  ]),
  ClaimStage.withSolicitor: _Moves([
    ClaimStage.won,
    ClaimStage.lost,
    ClaimStage.awaitingReply,
    ClaimStage.withdrawn
  ]),
  ClaimStage.won: _Moves([], [ClaimStage.paid, ClaimStage.awaitingReply]),
  ClaimStage.lost:
      _Moves([ClaimStage.withSolicitor], [ClaimStage.awaitingReply]),
  ClaimStage.withdrawn: _Moves([], [ClaimStage.underReview]),
  ClaimStage.paid: _Moves([], [ClaimStage.won]),
};

/// Names written by earlier versions of the app, and what they meant.
const Map<String, String> _legacyLead = {
  'Under Review': LeadStage.contacted,
  'Not Qualified': LeadStage.rejected,
  'Converted to Claim': LeadStage.qualified,
};
const Map<String, String> _legacyClaim = {
  'Submit to Solicitor': ClaimStage.demandPending,
  'Submitted to Solicitors': ClaimStage.demandPending,
  'Submitted': ClaimStage.readyForReview,
  'Claim Won': ClaimStage.won,
  'Claim Lost': ClaimStage.lost,
};

/// The stage as the table knows it, whatever an older record calls it.
String canonicalStage(RecordKind kind, String stage) {
  final value = stage.trim();
  final legacy = kind == RecordKind.lead ? _legacyLead : _legacyClaim;
  if (legacy.containsKey(value)) return legacy[value]!;
  if (value.isEmpty) {
    return kind == RecordKind.lead
        ? LeadStage.newLead
        : ClaimStage.detailsPending;
  }
  return value;
}

/// Every stage someone with [role] may move a record to from [stage].
List<String> allowedMoves(RecordKind kind, String stage, String role) {
  final moves = (kind == RecordKind.lead
      ? _leadMoves
      : _claimMoves)[canonicalStage(kind, stage)];
  if (moves == null) return const [];
  return [
    ...moves.to,
    if (_managers.contains(role)) ...moves.managerOnly,
  ];
}

/// Closing something without an outcome has to be explained.
bool moveNeedsReason(String to) =>
    to == LeadStage.rejected || to == ClaimStage.withdrawn;

/// What a move is called on a button, from the point of view of the person
/// making it.
String moveLabel(RecordKind kind, String from, String to) {
  if (kind == RecordKind.lead) {
    switch (to) {
      case LeadStage.contacted:
        return 'Mark as contacted';
      case LeadStage.qualified:
        return 'Qualify — open a claim';
      case LeadStage.rejected:
        return 'Reject lead';
      case LeadStage.newLead:
        return 'Reopen lead';
    }
    return to;
  }
  final reopening = ClaimStage.closed.contains(canonicalStage(kind, from));
  switch (to) {
    case ClaimStage.detailsPending:
      return 'Send back for more evidence';
    case ClaimStage.termsPending:
      return 'Evidence received — awaiting signature';
    case ClaimStage.readyForReview:
      return 'Mark ready for review';
    case ClaimStage.underReview:
      return reopening ? 'Reopen for review' : 'Start review';
    case ClaimStage.demandPending:
      return 'Approve — ready for demand letter';
    case ClaimStage.awaitingReply:
      return reopening
          ? 'Reopen — awaiting airline'
          : 'Demand sent — await reply';
    case ClaimStage.withSolicitor:
      return 'Escalate to legal team';
    case ClaimStage.won:
      return reopening ? 'Undo paid — back to won' : 'Mark as won';
    case ClaimStage.lost:
      return 'Mark as lost';
    case ClaimStage.withdrawn:
      return 'Withdraw claim';
    case ClaimStage.paid:
      return 'Mark as paid out';
  }
  return to;
}

/// The outcome of asking the server to change a stage.
class StageChangeResult {
  const StageChangeResult.ok({this.claimId}) : error = null;
  const StageChangeResult.failed(String this.error) : claimId = null;

  /// Null on success; otherwise a message fit to show the person who asked.
  final String? error;

  /// The claim opened by qualifying a lead.
  final String? claimId;

  bool get succeeded => error == null;
}

const _changeStageUrl =
    'https://us-central1-msmcrm-g24k37.cloudfunctions.net/changeStage';

/// Ask the server to move a lead or claim to [to].
///
/// [note] is kept with the change in the event log; it is required when
/// [moveNeedsReason] is true. [amount] is the sum recovered, in naira, when a
/// claim is won. Never throws.
Future<StageChangeResult> changeStage({
  required RecordKind kind,
  required String id,
  required String to,
  String note = '',
  double? amount,
}) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();
    if (idToken == null) {
      return const StageChangeResult.failed(
          'You are signed out. Sign in again.');
    }
    final response = await http
        .post(
          Uri.parse(_changeStageUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
          body: jsonEncode({
            'data': {
              'kind': kind == RecordKind.lead ? 'lead' : 'claim',
              'id': id,
              'to': to,
              'note': note,
              if (amount != null) 'amount': amount,
            },
          }),
        )
        .timeout(const Duration(seconds: 30));

    Map<String, dynamic> body = const {};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) body = decoded;
    } catch (_) {}

    if (response.statusCode == 200) {
      return StageChangeResult.ok(claimId: body['claimId'] as String?);
    }
    return StageChangeResult.failed(
      (body['error'] as String?) ??
          'The stage could not be changed (error ${response.statusCode}).',
    );
  } catch (_) {
    return const StageChangeResult.failed(
        'Could not reach the server. Check your connection and try again.');
  }
}
