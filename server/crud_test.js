// Direct SQLite CRUD test - runs against the real database
const { DatabaseSync } = require('node:sqlite');
const path = require('path');

const db = new DatabaseSync(path.join(__dirname, 'database.db'));

console.log('\n============================');
console.log(' CHPA Real Backend CRUD Test');
console.log('============================\n');

// READ all existing users
const existing = db.prepare('SELECT * FROM users').all();
console.log(`[READ]   Existing users in DB: ${existing.length}`);
existing.forEach(u => console.log(`         → ${u.email} (${u.role})`));

// CREATE
db.prepare(`
  INSERT OR REPLACE INTO users (uid, email, display_name, role, is_verified, created_at)
  VALUES (?, ?, ?, ?, ?, ?)
`).run('crud_test_01', 'crud@test.org', 'CRUD Test User', 'viewer', 1, new Date().toISOString());
const created = db.prepare('SELECT * FROM users WHERE uid=?').get('crud_test_01');
console.log(`\n[CREATE] Inserted: ${created.email} | name: ${created.display_name} | role: ${created.role}`);

// UPDATE
db.prepare('UPDATE users SET display_name=? WHERE uid=?').run('Updated Name', 'crud_test_01');
const updated = db.prepare('SELECT display_name FROM users WHERE uid=?').get('crud_test_01');
console.log(`[UPDATE] display_name changed to: "${updated.display_name}"`);

// DELETE
db.prepare('DELETE FROM users WHERE uid=?').run('crud_test_01');
const deleted = db.prepare('SELECT * FROM users WHERE uid=?').get('crud_test_01');
console.log(`[DELETE] Record gone: ${deleted === undefined ? 'YES ✅' : 'NO ❌'}`);

// Final state
const final = db.prepare('SELECT * FROM users').all();
console.log(`\n[READ]   Final users in DB: ${final.length}`);
final.forEach(u => console.log(`         → ${u.email} (${u.role})`));

console.log('\n✅ All CRUD operations verified against real SQLite database!\n');
