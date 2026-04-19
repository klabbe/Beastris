// Seed script: query leaderboard, delete Kocken's entries, add 10 test users
// Uses Firestore REST API (leaderboard collection has open read/write rules)

const PROJECT_ID = 'beastris-game-90b1b';
const BASE = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

async function firestoreGet(path) {
  const res = await fetch(`${BASE}/${path}`);
  if (!res.ok) throw new Error(`GET ${path}: ${res.status} ${await res.text()}`);
  return res.json();
}

async function firestoreList(collection, pageSize = 300) {
  const res = await fetch(`${BASE}/${collection}?pageSize=${pageSize}`);
  if (!res.ok) throw new Error(`LIST ${collection}: ${res.status} ${await res.text()}`);
  return res.json();
}

async function firestoreDelete(docPath) {
  const res = await fetch(`${BASE}/${docPath}`, { method: 'DELETE' });
  if (!res.ok) throw new Error(`DELETE ${docPath}: ${res.status} ${await res.text()}`);
}

async function firestoreAdd(collection, fields) {
  const res = await fetch(`${BASE}/${collection}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ fields }),
  });
  if (!res.ok) throw new Error(`POST ${collection}: ${res.status} ${await res.text()}`);
  return res.json();
}

function parseValue(v) {
  if (v.stringValue !== undefined) return v.stringValue;
  if (v.integerValue !== undefined) return parseInt(v.integerValue);
  return v.stringValue || v.integerValue || null;
}

// ── Main ──

const data = await firestoreList('leaderboard');
const docs = data.documents || [];
console.log(`Found ${docs.length} leaderboard entries`);

// Parse all entries
const entries = docs.map(doc => {
  const f = doc.fields;
  return {
    path: doc.name.split('/documents/')[1],
    name: parseValue(f.name || {}),
    score: parseValue(f.score || {}),
    uid: parseValue(f.uid || {}),
    level: parseValue(f.level || {}),
    lines: parseValue(f.lines || {}),
    country: parseValue(f.country || {}),
    timestamp: parseValue(f.timestamp || {}),
  };
});

// Show current entries
entries.sort((a, b) => b.score - a.score);
console.log('\nCurrent leaderboard:');
entries.forEach((e, i) => console.log(`  ${i + 1}. ${e.name} — ${e.score} pts (uid: ${e.uid || 'none'})`));

// Find and delete Kocken's entries (uid matching klas.flodqvist@gmail.com)
// We need to find the uid associated with Kocken
const kockenEntries = entries.filter(e =>
  e.name === 'Kocken' || e.name === 'klasett' || e.name === 'Klas'
);
// Collect unique uids from those entries
const kockenUids = [...new Set(kockenEntries.map(e => e.uid).filter(Boolean))];
console.log(`\nKocken-related uids: ${kockenUids.join(', ')}`);

// Delete ALL entries matching any of those uids
const toDelete = entries.filter(e => e.uid && kockenUids.includes(e.uid));
console.log(`Deleting ${toDelete.length} entries for Kocken:`);
for (const e of toDelete) {
  console.log(`  Deleting: ${e.name} — ${e.score} pts`);
  await firestoreDelete(e.path);
}

// Calculate score range from remaining entries
const remaining = entries.filter(e => !toDelete.includes(e));
const maxScore = remaining.length > 0 ? Math.max(...remaining.map(e => e.score)) : 5000;
const minScore = remaining.length > 0 ? Math.min(...remaining.map(e => e.score)) : 100;
console.log(`\nScore range (remaining): ${minScore} – ${maxScore}`);

// ── Create 10 test users ──
const testUsers = [
  { alias: 'DragonSlayer', country: 'US' },
  { alias: 'TetrisMaster', country: 'JP' },
  { alias: 'BlockBuster', country: 'GB' },
  { alias: 'PuzzleKing', country: 'DE' },
  { alias: 'NeonNinja', country: 'KR' },
  { alias: 'PixelQueen', country: 'FR' },
  { alias: 'StackAttack', country: 'BR' },
  { alias: 'LineCrusher', country: 'CA' },
  { alias: 'BeastMode', country: 'AU' },
  { alias: 'GridMaster', country: 'NO' },
];

// Spread scores evenly between min and max
const spread = maxScore - minScore;
console.log(`\nCreating ${testUsers.length} test entries:`);

for (let i = 0; i < testUsers.length; i++) {
  const { alias, country } = testUsers[i];
  // Evenly distribute + small random jitter
  const ratio = (i + 1) / (testUsers.length + 1);
  const score = Math.round(minScore + spread * ratio + (Math.random() * 200 - 100));
  const lines = Math.round(score / 50) + Math.floor(Math.random() * 10);
  const level = Math.min(Math.floor(lines / 10) + 1, 20);
  const now = new Date();
  // Vary dates within last 5 days
  const date = new Date(now.getTime() - Math.random() * 5 * 86400000);

  const fields = {
    name: { stringValue: alias },
    score: { integerValue: String(score) },
    lines: { integerValue: String(lines) },
    level: { integerValue: String(level) },
    date: { stringValue: date.toISOString() },
    timestamp: { integerValue: String(date.getTime()) },
    uid: { stringValue: `test-${alias.toLowerCase()}` },
    country: { stringValue: country },
  };

  await firestoreAdd('leaderboard', fields);
  console.log(`  ✓ ${alias} (${country}) — ${score} pts, level ${level}`);
}

console.log('\nDone! Leaderboard seeded.');
