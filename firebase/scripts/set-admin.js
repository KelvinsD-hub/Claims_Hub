/**
 * Grant (or revoke) the { admin: true } custom claim on a Firebase Auth user.
 * This is the bootstrap for the role model enforced in firestore.rules
 * (isAdmin()). Custom claims cannot be set from the client — run this locally
 * with credentials that can manage the project's users.
 *
 * Setup (once):
 *   1. Firebase console → Project settings → Service accounts →
 *      "Generate new private key". Save the JSON somewhere OUTSIDE the repo.
 *   2. export GOOGLE_APPLICATION_CREDENTIALS=/absolute/path/to/serviceAccount.json
 *      (PowerShell: $env:GOOGLE_APPLICATION_CREDENTIALS="C:\path\serviceAccount.json")
 *
 * Usage:
 *   node set-admin.js <email> [--revoke]
 *
 * Examples:
 *   node set-admin.js jane@claimshub.online          # grant admin
 *   node set-admin.js jane@claimshub.online --revoke # remove admin
 *
 * The user must sign out and back in (or refresh their ID token) for the new
 * claim to take effect.
 */
const admin = require('firebase-admin');

async function main() {
  const email = process.argv[2];
  const revoke = process.argv.includes('--revoke');
  if (!email) {
    console.error('Usage: node set-admin.js <email> [--revoke]');
    process.exit(1);
  }

  admin.initializeApp();

  const user = await admin.auth().getUserByEmail(email);
  const claims = { ...(user.customClaims || {}), admin: !revoke };
  if (revoke) delete claims.admin;

  await admin.auth().setCustomUserClaims(user.uid, claims);
  console.log(
    `${revoke ? 'Revoked' : 'Granted'} admin for ${email} (uid: ${user.uid}). ` +
    'The user must re-authenticate for it to take effect.',
  );
}

main().catch((err) => {
  console.error(err.message || err);
  process.exit(1);
});
