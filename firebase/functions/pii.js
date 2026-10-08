/**
 * Encryption for the most sensitive fields we hold (account numbers).
 *
 * The same AES-256-CBC scheme and key as the app's CryptoService and the
 * website's encryptField: "base64(iv):base64(ciphertext)", with the
 * 32-character key in the PII_ENCRYPTION_KEY secret. A value encrypted here
 * opens in the app.
 */

const crypto = require('crypto');

/** The ciphertext, or '' when the key is missing so the caller can refuse. */
function encryptPii(value, key = process.env.PII_ENCRYPTION_KEY || '') {
  const v = String(value || '');
  if (!v || key.length !== 32) return '';
  const iv = crypto.randomBytes(16);
  const cipher = crypto.createCipheriv('aes-256-cbc', Buffer.from(key, 'utf8'), iv);
  const out = Buffer.concat([cipher.update(v, 'utf8'), cipher.final()]);
  return `${iv.toString('base64')}:${out.toString('base64')}`;
}

/** Reverse of encryptPii; '' when it cannot be opened. */
function decryptPii(ciphertext, key = process.env.PII_ENCRYPTION_KEY || '') {
  const parts = String(ciphertext || '').split(':');
  if (parts.length !== 2 || key.length !== 32) return '';
  try {
    const d = crypto.createDecipheriv('aes-256-cbc', Buffer.from(key, 'utf8'), Buffer.from(parts[0], 'base64'));
    return Buffer.concat([d.update(Buffer.from(parts[1], 'base64')), d.final()]).toString('utf8');
  } catch (e) {
    return '';
  }
}

module.exports = { encryptPii, decryptPii };
