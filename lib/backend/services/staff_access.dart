import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';

/// Signing in to Claims Hub, and joining it by invitation.
///
/// Nobody signs themselves up. An admin invites a person by email with a role
/// (the staffInvite Cloud Function, firebase/functions/invites.js); the link
/// they are sent opens the sign-in page in "join" mode, and accepting it
/// approves their account. Signing in with an account that has no approved
/// access signs straight back out, and an account made a moment ago for
/// nothing (a stranger trying Google sign-in) is removed again.

const _inviteUrl =
    'https://us-central1-msmcrm-g24k37.cloudfunctions.net/staffInvite';

/// The roles an invite can give, lowest first.
const inviteRoles = ['Agent', 'Solicitor', 'Manager', 'Admin', 'Super Admin'];

/// What to do with someone who has just signed in.
enum SignInOutcome { allow, removeNewAccount, signOut }

/// [hasDoc] and [approved] describe their users document; [createdAt] is
/// when the sign-in account was made. A brand-new account with no access is
/// removed rather than left behind.
SignInOutcome signInOutcome({
  required bool hasDoc,
  required bool approved,
  DateTime? createdAt,
  required DateTime now,
}) {
  if (hasDoc && approved) return SignInOutcome.allow;
  final isNew =
      createdAt != null && now.difference(createdAt).inMinutes.abs() < 10;
  return isNew ? SignInOutcome.removeNewAccount : SignInOutcome.signOut;
}

/// The words to show for a sign-in error.
String signInError(Object e) {
  if (e is FirebaseAuthException) {
    return switch (e.code) {
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' ||
      'INVALID_LOGIN_CREDENTIALS' =>
        'That email and password do not match. Try again, or reset your password.',
      'invalid-email' => 'That is not a valid email address.',
      'user-disabled' => 'This account has been switched off. Ask an admin.',
      'too-many-requests' =>
        'Too many attempts. Wait a few minutes, or reset your password.',
      'popup-blocked' =>
        'Your browser blocked the Google window. Allow pop-ups for this site and try again.',
      'popup-closed-by-user' ||
      'cancelled-popup-request' =>
        'The Google window was closed before you finished.',
      'unauthorized-domain' ||
      'operation-not-allowed' =>
        'Google sign-in is not switched on for Claims Hub yet. Ask an admin.',
      'weak-password' => 'Choose a password of at least 8 characters.',
      'network-request-failed' =>
        'Could not reach the server. Check your connection and try again.',
      _ => e.message ?? 'Sign-in failed. Please try again.',
    };
  }
  return 'Sign-in failed. Please try again.';
}

/// Sign in with Google in a pop-up. Call it straight from the button's tap,
/// before anything else is awaited, or the browser blocks the pop-up.
Future<User?> googleSignInPopup() async {
  final provider = GoogleAuthProvider()
    ..setCustomParameters({'prompt': 'select_account'});
  final result = await FirebaseAuth.instance.signInWithPopup(provider);
  return result.user;
}

/// Decide whether the person now signed in may stay. Returns null when they
/// may, or the reason they may not (and they are signed out).
Future<String?> admitSignedInUser() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return 'Sign-in failed. Please try again.';
  final ref = UsersRecord.collection.doc(user.uid);
  final snap = await ref.get();
  final data = snap.data() as Map<String, dynamic>?;
  final outcome = signInOutcome(
    hasDoc: snap.exists,
    approved: data?['approved'] == true,
    createdAt: user.metadata.creationTime,
    now: DateTime.now(),
  );
  if (outcome == SignInOutcome.allow) {
    currentUserDocument = UsersRecord.getDocumentFromData(data!, ref);
    return null;
  }
  final email = user.email ?? 'this account';
  if (outcome == SignInOutcome.removeNewAccount) {
    try {
      await user.delete();
    } catch (_) {
      await FirebaseAuth.instance.signOut();
    }
  } else {
    await FirebaseAuth.instance.signOut();
  }
  return '$email does not have access to Claims Hub. Accounts are by '
      'invitation: ask an admin to send you an invite link.';
}

/// Undo a sign-in that should not stand: remove the account if it was made a
/// moment ago, otherwise just sign out.
Future<void> dropSignIn() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  final created = user.metadata.creationTime;
  final isNew = created != null &&
      DateTime.now().difference(created).inMinutes.abs() < 10;
  try {
    if (isNew) {
      await user.delete();
      return;
    }
  } catch (_) {}
  await FirebaseAuth.instance.signOut();
}

/// Send a password reset link. Firebase does not say whether the address has
/// an account, so neither does this.
Future<String?> sendPasswordReset(String email) async {
  try {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
    return null;
  } catch (e) {
    return signInError(e);
  }
}

// ── Invites ──────────────────────────────────────────────────────────────────

/// An invite as the join page sees it.
class InviteInfo {
  const InviteInfo({
    required this.status,
    this.message = '',
    this.email = '',
    this.name = '',
    this.role = '',
    this.invitedBy = '',
    this.expiresAt,
  });

  /// open, used, revoked, expired or missing.
  final String status;
  final String message;
  final String email;
  final String name;
  final String role;
  final String invitedBy;
  final DateTime? expiresAt;

  bool get isOpen => status == 'open';
}

/// An invite not yet used, as the Staff page lists it.
class PendingInvite {
  const PendingInvite({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.phone,
    required this.invitedBy,
    required this.expiresAt,
    required this.expired,
  });

  final String id;
  final String email;
  final String name;
  final String role;
  final String phone;
  final String invitedBy;
  final DateTime? expiresAt;
  final bool expired;
}

/// A new invite: its link, and whether it was emailed.
class NewInvite {
  const NewInvite({
    required this.link,
    required this.email,
    required this.name,
    required this.role,
    required this.emailed,
    this.expiresAt,
  });

  final String link;
  final String email;
  final String name;
  final String role;
  final bool emailed;
  final DateTime? expiresAt;
}

/// The result of an invite call: [data] on success, else [error].
class InviteCall {
  const InviteCall(this.data, this.error);
  final Map<String, dynamic>? data;
  final String? error;
  bool get ok => error == null;
}

Future<InviteCall> _call(Map<String, dynamic> body,
    {bool signedIn = true}) async {
  try {
    final headers = {'Content-Type': 'application/json'};
    if (signedIn) {
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken == null) {
        return const InviteCall(null, 'You are signed out. Sign in again.');
      }
      headers['Authorization'] = 'Bearer $idToken';
    }
    final response = await http
        .post(Uri.parse(_inviteUrl),
            headers: headers, body: jsonEncode({'data': body}))
        .timeout(const Duration(seconds: 30));
    Map<String, dynamic>? decoded;
    try {
      final d = jsonDecode(response.body);
      if (d is Map<String, dynamic>) decoded = d;
    } catch (_) {}
    if (response.statusCode == 200 && decoded != null) {
      return InviteCall(decoded, null);
    }
    return InviteCall(
        null,
        decoded?['error'] as String? ??
            'Something went wrong (error ${response.statusCode}).');
  } catch (_) {
    return const InviteCall(null,
        'Could not reach the server. Check your connection and try again.');
  }
}

DateTime? _date(Object? v) => v is String ? DateTime.tryParse(v) : null;

/// What the invite in a link is for. Works signed out.
Future<InviteInfo> fetchInvite(String token) async {
  final r = await _call({'action': 'info', 'token': token}, signedIn: false);
  if (!r.ok) return InviteInfo(status: 'error', message: r.error!);
  final d = r.data!;
  return InviteInfo(
    status: '${d['status'] ?? 'missing'}',
    message: '${d['message'] ?? ''}',
    email: '${d['email'] ?? ''}',
    name: '${d['name'] ?? ''}',
    role: '${d['role'] ?? ''}',
    invitedBy: '${d['invitedBy'] ?? ''}',
    expiresAt: _date(d['expiresAt']),
  );
}

/// Use the invite with the account now signed in. Returns null on success,
/// or the reason it failed.
Future<String?> acceptInvite(String token) async {
  final r = await _call({'action': 'accept', 'token': token});
  return r.error;
}

/// Invite [email] as [role]. With [sendEmail] the server emails the link.
Future<(NewInvite?, String?)> createInvite({
  required String name,
  required String email,
  required String role,
  String phone = '',
  bool sendEmail = true,
}) async {
  final r = await _call({
    'action': 'create',
    'name': name.trim(),
    'email': email.trim(),
    'role': role,
    'phone': phone.trim(),
    'send_email': sendEmail,
  });
  if (!r.ok) return (null, r.error);
  final d = r.data!;
  return (
    NewInvite(
      link: '${d['link']}',
      email: '${d['email']}',
      name: '${d['name']}',
      role: '${d['role']}',
      emailed: d['emailed'] == true,
      expiresAt: _date(d['expiresAt']),
    ),
    null
  );
}

/// Invites not yet used or cancelled, newest first.
Future<(List<PendingInvite>, String?)> listInvites() async {
  final r = await _call({'action': 'list'});
  if (!r.ok) return (const <PendingInvite>[], r.error);
  final list = (r.data!['invites'] as List? ?? const [])
      .whereType<Map<String, dynamic>>()
      .map((x) => PendingInvite(
            id: '${x['id']}',
            email: '${x['email'] ?? ''}',
            name: '${x['name'] ?? ''}',
            role: '${x['role'] ?? ''}',
            phone: '${x['phone'] ?? ''}',
            invitedBy: '${x['invitedBy'] ?? ''}',
            expiresAt: _date(x['expiresAt']),
            expired: x['expired'] == true,
          ))
      .toList();
  return (list, null);
}

/// Cancel an invite so its link stops working.
Future<String?> revokeInvite(String id) async =>
    (await _call({'action': 'revoke', 'id': id})).error;

/// The WhatsApp message for an invite link.
String inviteWhatsAppText(
        {required String name, required String role, required String link}) =>
    'Hello ${name.split(' ').first}, you have been invited to Claims Hub, '
    'the Claims Assist case system, as $role. Set up your account here: '
    '$link\n\nThe link works once and expires in 7 days.';

/// A wa.me link that opens WhatsApp with [text], to [phone] if given.
String whatsAppLink(String text, {String phone = ''}) {
  final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
  return 'https://wa.me/$digits?text=${Uri.encodeComponent(text)}';
}
