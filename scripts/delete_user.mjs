/**
 * Admin script: delete a BeastBlocks user account by e-mail.
 *
 * This does exactly what deleteAccount() does in the app, but for any user.
 * Steps:
 *   1. Look up the user's UID from their e-mail address
 *   2. Anonymise all their leaderboard entries  (uid → "")
 *   3. Delete their profile document from users/{uid}
 *   4. Delete their Firebase Auth account
 *
 * Usage:
 *   node scripts/delete_user.mjs user@example.com
 *
 * First-time setup (one-off):
 *   1. Go to Firebase Console → Project settings → Service accounts
 *   2. Click "Generate new private key" → save as  scripts/serviceAccountKey.json
 *   3. cd scripts && npm install
 *
 * The serviceAccountKey.json is listed in .gitignore – never commit it.
 */

import { createRequire } from 'module';
import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import path from 'path';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const require = createRequire(import.meta.url);

// ── Load Firebase Admin ──────────────────────────────────────────────────────

const admin = require('firebase-admin');

const serviceAccountPath = path.join(__dirname, 'serviceAccountKey.json');
let serviceAccount;
try {
  serviceAccount = JSON.parse(readFileSync(serviceAccountPath, 'utf8'));
} catch {
  console.error('ERROR: scripts/serviceAccountKey.json not found.');
  console.error('Download it from Firebase Console → Project settings → Service accounts.');
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'beastris-game-90b1b',
});

const db    = admin.firestore();
const auth  = admin.auth();

// ── Main ─────────────────────────────────────────────────────────────────────

const email = process.argv[2]?.trim();
if (!email) {
  console.error('Usage: node scripts/delete_user.mjs <email>');
  process.exit(1);
}

console.log(`Looking up user: ${email}`);

let userRecord;
try {
  userRecord = await auth.getUserByEmail(email);
} catch (e) {
  if (e.code === 'auth/user-not-found') {
    console.error(`No Firebase Auth user found with e-mail: ${email}`);
  } else {
    console.error('Auth lookup failed:', e.message);
  }
  process.exit(1);
}

const uid = userRecord.uid;
console.log(`Found UID: ${uid}`);

// 1. Anonymise leaderboard entries
const lbSnap = await db.collection('leaderboard').where('uid', '==', uid).get();
if (lbSnap.empty) {
  console.log('No leaderboard entries found.');
} else {
  const batch = db.batch();
  lbSnap.docs.forEach(doc => batch.update(doc.ref, { uid: '' }));
  await batch.commit();
  console.log(`Anonymised ${lbSnap.size} leaderboard entry/entries.`);
}

// 2. Delete profile document
try {
  await db.collection('users').doc(uid).delete();
  console.log('Deleted profile document.');
} catch (e) {
  console.warn('Profile document not found or already deleted:', e.message);
}

// 3. Delete Firebase Auth account
await auth.deleteUser(uid);
console.log(`Firebase Auth account deleted for ${email}.`);

console.log('Done — account fully removed.');
process.exit(0);
