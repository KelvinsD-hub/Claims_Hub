import 'dart:math';

const _tokenChars =
    'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

// Random.secure() is backed by the platform CSPRNG — unlike the shared
// FlutterFlow Random() used for cosmetic data, it is suitable for secrets.
final _secureRandom = Random.secure();

/// Generates a cryptographically-secure token used as the capability secret in
/// claimant links (`?claimRef=…&token=…`). Defaults to 32 characters.
String generateSecureToken([int length = 32]) {
  return List.generate(
    length,
    (_) => _tokenChars[_secureRandom.nextInt(_tokenChars.length)],
  ).join();
}
