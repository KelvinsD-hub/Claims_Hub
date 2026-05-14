import 'dart:convert';
import 'package:encrypt/encrypt.dart' as enc;

/// AES-256-CBC encryption for sensitive PII fields stored in Firestore.
///
/// Usage:
///   1. Call [CryptoService.instance.configure] once at app startup
///      (after Firebase Remote Config is fetched) before any claim data
///      is read from or written to Firestore.
///   2. All subsequent [encrypt] / [decrypt] calls are safe to use anywhere.
class CryptoService {
  CryptoService._();
  static final CryptoService instance = CryptoService._();

  String? _encryptionKey;

  /// Sets the AES-256 encryption key.
  /// [key] must be exactly 32 characters (256 bits).
  /// Call this once during app initialisation via [initializeClaimsSecurity].
  void configure(String key) {
    assert(key.length == 32, 'Encryption key must be exactly 32 characters.');
    _encryptionKey = key;
  }

  bool get isConfigured => _encryptionKey != null;

  enc.Encrypter _buildEncrypter() {
    if (_encryptionKey == null) {
      throw StateError(
        'CryptoService has not been configured. '
        'Call initializeClaimsSecurity() before reading or writing claim data.',
      );
    }
    return enc.Encrypter(
      enc.AES(enc.Key.fromUtf8(_encryptionKey!), mode: enc.AESMode.cbc),
    );
  }

  /// Encrypts [plaintext] with AES-256-CBC using a fresh random IV.
  /// Returns a Base64 string in the form `<iv>:<ciphertext>`.
  /// Returns [plaintext] unchanged when it is empty or CryptoService is not
  /// configured (unauthenticated claimant sessions — value stored as plaintext).
  String encrypt(String plaintext) {
    if (plaintext.isEmpty) return plaintext;
    if (!isConfigured) return plaintext;
    final iv = enc.IV.fromSecureRandom(16);
    final encrypted = _buildEncrypter().encrypt(plaintext, iv: iv);
    return '${base64Encode(iv.bytes)}:${encrypted.base64}';
  }

  /// Decrypts a value produced by [encrypt].
  ///
  /// If [ciphertext] does not contain the expected `<iv>:<ciphertext>` format
  /// (e.g. a legacy unencrypted value already in Firestore) it is returned
  /// as-is so that existing records never crash on read.
  ///
  /// When CryptoService is not configured (unauthenticated claimant sessions)
  /// the value is returned as-is — it was stored as plaintext by those sessions.
  String decrypt(String ciphertext) {
    if (ciphertext.isEmpty) return ciphertext;
    if (!isConfigured) return ciphertext;
    try {
      final parts = ciphertext.split(':');
      if (parts.length != 2) return ciphertext; // legacy unencrypted value
      final iv = enc.IV.fromBase64(parts[0]);
      final encrypted = enc.Encrypted.fromBase64(parts[1]);
      return _buildEncrypter().decrypt(encrypted, iv: iv);
    } catch (_) {
      // Graceful fallback: return raw value for unencrypted legacy documents.
      return ciphertext;
    }
  }
}
