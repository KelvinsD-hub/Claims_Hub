// Document addresses. Plain node:  node documents.test.js
const d = require('./documents');

let passed = 0;
let failed = 0;
function check(name, ok) {
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}`);
  ok ? passed++ : failed++;
}

const B = 'msmcrm-g24k37.firebasestorage.app';
const address = d.storedAddress(B, 'claims/abc123/LOA_abc123.pdf');

check('a stored address carries no token', !/token=/.test(address));
check('a stored address round-trips to its path', d.storagePathOf(address) === 'claims/abc123/LOA_abc123.pdf');
check('an old address with a token still names its path',
  d.storagePathOf(`https://firebasestorage.googleapis.com/v0/b/${B}/o/claims%2Fabc123%2FLOA_abc123.pdf?alt=media&token=d0c959fe-41e2`) === 'claims/abc123/LOA_abc123.pdf');
check('a bare path is accepted', d.storagePathOf('claims/abc123/evidence/1.jpg') === 'claims/abc123/evidence/1.jpg');
check('a path with spaces survives encoding', d.storagePathOf(d.storedAddress(B, 'claims/a/boarding pass.pdf')) === 'claims/a/boarding pass.pdf');
check('another site is not a stored address', d.storagePathOf('https://example.com/v0/b/x/o/claims%2Fa%2Fb.pdf') === null);
check('plain http is refused', d.storagePathOf(`http://firebasestorage.googleapis.com/v0/b/${B}/o/claims%2Fa%2Fb.pdf`) === null);
check('climbing out of a folder is refused', d.storagePathOf('claims/abc/../../users/x') === null);
check('an encoded climb is refused', d.storagePathOf(`https://firebasestorage.googleapis.com/v0/b/${B}/o/claims%2F..%2Fsecrets`) === null);
check('a broken encoding is refused', d.storagePathOf(`https://firebasestorage.googleapis.com/v0/b/${B}/o/claims%2F%E0%A4%A`) === null);
check('nothing is nothing', d.storagePathOf('') === null && d.storagePathOf(undefined) === null);

check('a generated letter is a client document', d.isClientDocument('claims/abc123/LOA_abc123.pdf'));
check('client evidence is a client document', d.isClientDocument('claims/abc123/evidence/1727861234_0.jpg'));
check('a website signed document is a client document', d.isClientDocument('signed-documents/lead1/authority.pdf'));
check('evidence from the first form is a client document', d.isClientDocument('users/uid1/uploads/1711387123.jpg'));
check('a blog image is not', !d.isClientDocument('blog_images/1-photo.png'));
check('the claims folder itself is not', !d.isClientDocument('claims/abc123/') && !d.isClientDocument('claims/'));
check('something merely named like it is not', !d.isClientDocument('xclaims/abc/file.pdf'));

console.log(`\n${passed} passed, ${failed} failed`);
process.exit(failed ? 1 : 0);
