/**
 * Client documents in Cloud Storage: where they live and who may be handed
 * one.
 *
 * Nothing here is reachable by a link. A stored document carries no download
 * token, so its address is only a name: staff are served the file by the
 * staffDocument function after it has checked who they are, and nobody else
 * is served it at all.
 *
 * Pure: no Firebase imports, so it can be tested with plain node.
 */

/** Largest file staffDocument will serve; an HTTP function's response is capped. */
const MAX_SERVED_BYTES = 9 * 1024 * 1024;

/**
 * The address stored on a claim for a document at `path`. Not a working
 * link: with no token it is refused to anyone asking for it directly.
 */
function storedAddress(bucketName, path) {
  return `https://firebasestorage.googleapis.com/v0/b/${bucketName}/o/${encodeURIComponent(path)}?alt=media`;
}

/**
 * The storage path a stored address names, or null if it is not one.
 * Accepts the addresses written before tokens were dropped (which carry
 * "&token=…") and bare paths.
 */
function storagePathOf(address) {
  const value = String(address || '').trim();
  if (!value) return null;
  let path = value;
  if (/^https?:\/\//i.test(value)) {
    const m = /^https:\/\/firebasestorage\.googleapis\.com\/v0\/b\/[^/]+\/o\/([^?#]+)/.exec(value);
    if (!m) return null;
    try {
      path = decodeURIComponent(m[1]);
    } catch (_) {
      return null;
    }
  }
  if (path.startsWith('/') || path.includes('//') || path.split('/').includes('..')) return null;
  return path;
}

/**
 * Whether a path holds a client's document, which approved staff may open.
 * Anything else in the bucket (profile photos, blog images) is not this
 * function's business.
 */
function isClientDocument(path) {
  return /^claims\/[^/]+\/.+/.test(path) ||
    // Files a client sent in answer to a request, before the lead was a claim.
    /^leads\/[^/]+\/.+/.test(path) ||
    /^signed-documents\/[^/]+\/.+/.test(path) ||
    // Evidence uploaded by the first version of the evidence form.
    /^users\/[^/]+\/uploads\/.+/.test(path);
}

module.exports = { MAX_SERVED_BYTES, storedAddress, storagePathOf, isClientDocument };
