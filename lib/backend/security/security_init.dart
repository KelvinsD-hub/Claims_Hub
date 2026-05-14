import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'crypto_service.dart';

/// Fetches the AES-256 encryption key from Firebase Remote Config and
/// configures [CryptoService] so that claim PII fields can be encrypted
/// and decrypted throughout the app.
///
/// Call this once during app startup, after Firebase has been initialised
/// and before any Firestore claim data is read or written:
///
/// ```dart
/// await initFirebase();
/// await initializeClaimsSecurity();
/// ```
///
/// Setup required in the Firebase console:
///   Remote Config → Add parameter
///     Key:           claims_encryption_key
///     Value:         <your 32-character AES key>
///     Value type:    String
///     Default value: (leave empty — absence is detected and throws below)
Future<void> initializeClaimsSecurity() async {
  final remoteConfig = FirebaseRemoteConfig.instance;

  await remoteConfig.setConfigSettings(RemoteConfigSettings(
    // Zero interval forces a fresh fetch every time during development.
    // Set to Duration(hours: 1) or more in production.
    fetchTimeout: const Duration(seconds: 10),
    minimumFetchInterval: Duration.zero,
  ));

  // Provide an empty default so the fetch never throws on first run.
  await remoteConfig.setDefaults(const {'claims_encryption_key': ''});

  await remoteConfig.fetchAndActivate();

  final key = remoteConfig.getString('claims_encryption_key');

  if (key.isEmpty) {
    throw StateError(
      'Firebase Remote Config is missing the "claims_encryption_key" parameter. '
      'Add it in the Firebase console before running the app.',
    );
  }

  if (key.length != 32) {
    throw StateError(
      '"claims_encryption_key" must be exactly 32 characters for AES-256. '
      'Found ${key.length} characters.',
    );
  }

  CryptoService.instance.configure(key);
}
