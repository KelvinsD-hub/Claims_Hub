import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'documents/tab_stub.dart'
    if (dart.library.js_interop) 'documents/tab_web.dart' as tab;

/// Client documents: the letters the system generates and the evidence a
/// client sends.
///
/// None of them is reachable by a link. What a claim stores for a document is
/// an address that opens nothing by itself; staff are served the file by the
/// staffDocument Cloud Function after it has checked who they are
/// ([fetchStoredDocument]). Use [openStoredDocument] and [StoredImage] to
/// show one — never launchURL or Image.network.

const _staffDocumentUrl =
    'https://us-central1-msmcrm-g24k37.cloudfunctions.net/staffDocument';

class StoredDocument {
  const StoredDocument(this.bytes, this.contentType);
  final Uint8List bytes;
  final String contentType;
}

/// Thrown with a message fit to show the person who asked.
class DocumentError implements Exception {
  const DocumentError(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Fetch the document a claim stores at [address], as the signed-in member of
/// staff. Throws [DocumentError].
Future<StoredDocument> fetchStoredDocument(String address) async {
  final http.Response response;
  try {
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (idToken == null) {
      throw const DocumentError('You are signed out. Sign in again.');
    }
    response = await http
        .post(
          Uri.parse(_staffDocumentUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
          body: jsonEncode({
            'data': {'address': address}
          }),
        )
        .timeout(const Duration(seconds: 60));
  } on DocumentError {
    rethrow;
  } catch (_) {
    throw const DocumentError(
        'Could not reach the server. Check your connection and try again.');
  }
  if (response.statusCode == 200) {
    return StoredDocument(
      response.bodyBytes,
      response.headers['content-type'] ?? 'application/octet-stream',
    );
  }
  String? message;
  try {
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) message = decoded['error'] as String?;
  } catch (_) {}
  throw DocumentError(message ??
      'The document could not be opened (error ${response.statusCode}).');
}

/// Open the document stored at [address] in a new browser tab. Call this
/// directly from the tap handler: the tab has to be opened during the click.
Future<void> openStoredDocument(BuildContext context, String address) async {
  final messenger = ScaffoldMessenger.of(context);
  final pending = tab.openPendingTab();
  try {
    final document = await fetchStoredDocument(address);
    tab.showInTab(pending, document.bytes, document.contentType);
  } on DocumentError catch (e) {
    tab.closeTab(pending);
    messenger.showSnackBar(SnackBar(
      content: Text(e.message, style: const TextStyle(color: Colors.white)),
      backgroundColor: const Color(0xFFB00020),
      duration: const Duration(seconds: 7),
    ));
  }
}

/// Open whatever a claim holds in one of its document fields: a stored
/// document's address, or a signature kept on the claim itself as base64 PNG.
Future<void> openClaimDocument(BuildContext context, String value) async {
  final trimmed = value.trim();
  if (trimmed.startsWith('http') || trimmed.startsWith('claims/')) {
    return openStoredDocument(context, trimmed);
  }
  try {
    final bytes = base64Decode(trimmed.contains(',')
        ? trimmed.substring(trimmed.indexOf(',') + 1)
        : trimmed);
    tab.showInTab(tab.openPendingTab(), bytes, 'image/png');
  } catch (_) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That document cannot be displayed.')));
  }
}

/// An image a claim stores at [address], fetched as the signed-in member of
/// staff. Tapping it opens it full size in a new tab.
class StoredImage extends StatefulWidget {
  const StoredImage({
    super.key,
    required this.address,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  final String address;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  State<StoredImage> createState() => _StoredImageState();
}

class _StoredImageState extends State<StoredImage> {
  late Future<StoredDocument> _document = fetchStoredDocument(widget.address);

  @override
  void didUpdateWidget(StoredImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.address != widget.address) {
      _document = fetchStoredDocument(widget.address);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: FutureBuilder<StoredDocument>(
        future: _document,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Tooltip(
              message: '${snapshot.error}',
              child: const Center(
                  child: Icon(Icons.broken_image_outlined, color: Colors.grey)),
            );
          }
          if (!snapshot.hasData) {
            return const Center(
              child: SizedBox(
                width: 22.0,
                height: 22.0,
                child: CircularProgressIndicator(strokeWidth: 2.0),
              ),
            );
          }
          final document = snapshot.data!;
          return InkWell(
            onTap: () {
              // Already in memory, so the tab can be filled at once.
              tab.showInTab(
                  tab.openPendingTab(), document.bytes, document.contentType);
            },
            child: document.contentType.startsWith('image/')
                ? Image.memory(document.bytes,
                    width: widget.width, height: widget.height, fit: widget.fit)
                : const Center(
                    child: Icon(Icons.picture_as_pdf_outlined, size: 40.0)),
          );
        },
      ),
    );
  }
}

String _contentTypeFor(String name) {
  switch (name.split('.').last.toLowerCase()) {
    case 'pdf':
      return 'application/pdf';
    case 'png':
      return 'image/png';
    case 'webp':
      return 'image/webp';
    case 'heic':
      return 'image/heic';
    case 'gif':
      return 'image/gif';
    default:
      return 'image/jpeg';
  }
}

/// Add one piece of client evidence to a claim and return the address to
/// store on it, or null if the upload failed.
///
/// Works for a client who is not signed in: the storage rules let anyone add
/// a file to a claim's evidence folder, and nobody but staff read one back.
/// [name] supplies the file extension; [index] keeps files chosen together
/// from colliding.
Future<String?> uploadClaimEvidence({
  required String claimId,
  required Uint8List bytes,
  required String name,
  int index = 0,
}) async {
  try {
    final extension =
        name.contains('.') ? name.split('.').last.toLowerCase() : 'jpg';
    final path = 'claims/$claimId/evidence/'
        '${DateTime.now().microsecondsSinceEpoch}_$index.$extension';
    final ref = FirebaseStorage.instance.ref().child(path);
    final result = await ref.putData(
        bytes, SettableMetadata(contentType: _contentTypeFor(name)));
    if (result.state != TaskState.success) return null;
    return 'https://firebasestorage.googleapis.com/v0/b/${ref.bucket}/o/'
        '${Uri.encodeComponent(path)}?alt=media';
  } catch (e) {
    debugPrint('uploadClaimEvidence failed: $e');
    return null;
  }
}
