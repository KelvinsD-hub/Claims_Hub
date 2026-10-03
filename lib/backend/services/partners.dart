import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// Referral partners: people outside the firm who bring in clients through
/// their own link, and follow their referrals on a page of their own on the
/// website (claimsassistltd.com/partner).
///
/// The server (firebase/functions/partners.js) invites, suspends and restores
/// them, and decides what a partner may see. The app only asks it.

/// One partner as stored.
class ReferralPartner {
  const ReferralPartner({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.code,
    required this.status,
    this.createdAt,
    this.joinedAt,
    this.lastSeenAt,
    this.invitedByName = '',
  });

  factory ReferralPartner.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    DateTime? date(dynamic v) => v is Timestamp ? v.toDate() : null;
    return ReferralPartner(
      id: doc.id,
      name: d['name'] as String? ?? '',
      email: d['email'] as String? ?? '',
      phone: d['phone'] as String? ?? '',
      code: d['code'] as String? ?? '',
      status: d['status'] as String? ?? 'invited',
      createdAt: date(d['created_at']),
      joinedAt: date(d['joined_at']),
      lastSeenAt: date(d['last_seen_at']),
      invitedByName: d['invited_by_name'] as String? ?? '',
    );
  }

  final String id;
  final String name;
  final String email;
  final String phone;

  /// Their link code, "p-…"; the link is claimsassistltd.com/go/<code>.
  final String code;

  /// invited (has not opened their page yet), active or suspended.
  final String status;
  final DateTime? createdAt;
  final DateTime? joinedAt;
  final DateTime? lastSeenAt;
  final String invitedByName;

  String get link => 'https://claimsassistltd.com/go/$code';
  bool get suspended => status == 'suspended';
}

/// Every partner, by name.
Stream<List<ReferralPartner>> referralPartners() => FirebaseFirestore.instance
    .collection('partners')
    .snapshots()
    .map((s) => s.docs.map(ReferralPartner.fromDoc).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())));

/// The outcome of an invite or a fresh sign-in link.
class PartnerInviteResult {
  const PartnerInviteResult.sent({
    required String this.link,
    required String this.signIn,
    required String this.email,
    required this.emailed,
  }) : error = null;
  const PartnerInviteResult.failed(String this.error)
      : link = null,
        signIn = null,
        email = null,
        emailed = false;

  final String? error;

  /// The partner's referral link, to share with passengers.
  final String? link;

  /// A one-click sign-in to their partner page, to send by WhatsApp if the
  /// email did not arrive.
  final String? signIn;
  final String? email;
  final bool emailed;
  bool get succeeded => error == null;
}

const _partnerAdminUrl =
    'https://us-central1-msmcrm-g24k37.cloudfunctions.net/partnerAdmin';

Future<(int, Map<String, dynamic>)> _post(Map<String, dynamic> data) async {
  final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
  if (idToken == null) {
    return (401, {'error': 'You are signed out. Sign in again.'});
  }
  final response = await http
      .post(
        Uri.parse(_partnerAdminUrl),
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

Future<PartnerInviteResult> _invite(Map<String, dynamic> data) async {
  try {
    final (status, body) = await _post(data);
    if (status == 200) {
      return PartnerInviteResult.sent(
        link: body['link'] as String? ?? '',
        signIn: body['signIn'] as String? ?? '',
        email: body['email'] as String? ?? '',
        emailed: body['emailed'] == true,
      );
    }
    return PartnerInviteResult.failed(
        body['error'] as String? ?? 'That could not be done (error $status).');
  } catch (_) {
    return const PartnerInviteResult.failed(
        'Could not reach the server. Check your connection and try again.');
  }
}

/// Invite a partner. Admins only; the server checks.
Future<PartnerInviteResult> invitePartner({
  required String name,
  required String email,
  required String phone,
  bool sendEmail = true,
}) =>
    _invite({
      'action': 'invite',
      'name': name,
      'email': email,
      'phone': phone,
      'send_email': sendEmail,
    });

/// Send a partner a fresh sign-in link.
Future<PartnerInviteResult> resendPartnerLink(String id,
        {bool sendEmail = true}) =>
    _invite({'action': 'resend', 'id': id, 'send_email': sendEmail});

/// Suspend a partner (their page closes and their link stops crediting) or
/// restore them. Returns an error message, or null when it worked.
Future<String?> setPartnerActive(String id, bool active) async {
  try {
    final (status, body) =
        await _post({'action': 'set_active', 'id': id, 'active': active});
    if (status == 200) return null;
    return body['error'] as String? ?? 'That could not be done (error $status).';
  } catch (_) {
    return 'Could not reach the server. Check your connection and try again.';
  }
}
