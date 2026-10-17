/**
 * Script to sync all tables from topup_tournament.sqlite to Cloud Firestore
 * Run with: node scripts/sync_to_firestore.js
 */
const { db: sqliteDb } = require('../server/db');
const { firestore } = require('../server/firestore');

const COLLECTIONS_MAP = [
  { table: 'users', collection: 'users', idField: 'id' },
  { table: 'wallets', collection: 'wallets', idField: 'user_id' },
  { table: 'wallet_ledger', collection: 'wallet_ledger', idField: 'id' },
  { table: 'topup_games', collection: 'topup_games', idField: 'id' },
  { table: 'topup_packages', collection: 'topup_packages', idField: 'id' },
  { table: 'topup_orders', collection: 'topup_orders', idField: 'id' },
  { table: 'tournaments', collection: 'tournaments', idField: 'id' },
  { table: 'tournament_registrations', collection: 'tournament_registrations', idField: 'id' },
  { table: 'matches', collection: 'matches', idField: 'id' },
  { table: 'match_results', collection: 'match_results', idField: 'id' },
  { table: 'audit_logs', collection: 'audit_logs', idField: 'id' },
];

async function syncAll() {
  console.log('🚀 Starting Cloud Firestore Sync from SQLite...');

  for (const { table, collection, idField } of COLLECTIONS_MAP) {
    try {
      const rows = sqliteDb.prepare(`SELECT * FROM ${table}`).all();
      console.log(`📦 Table "${table}" -> Collection "${collection}" (${rows.length} records)...`);

      if (rows.length === 0) continue;

      // Batch write in chunks of 450 (Firestore limit is 500)
      const chunkSize = 400;
      for (let i = 0; i < rows.length; i += chunkSize) {
        const batch = firestore.batch();
        const chunk = rows.slice(i, i + chunkSize);

        for (const row of chunk) {
          const docId = String(row[idField]);
          const docRef = firestore.collection(collection).doc(docId);

          // Parse JSON fields if any
          const cleanData = { ...row };
          for (const key of Object.keys(cleanData)) {
            if (typeof cleanData[key] === 'string' && (cleanData[key].startsWith('{') || cleanData[key].startsWith('['))) {
              try {
                cleanData[key] = JSON.parse(cleanData[key]);
              } catch (e) {}
            }
          }

          batch.set(docRef, cleanData, { merge: true });
        }

        await batch.commit();
      }
      console.log(`  ✅ Successfully synced ${rows.length} documents to "${collection}"`);
    } catch (err) {
      console.warn(`  ⚠️ Failed to sync table ${table}:`, err.message);
    }
  }

  console.log('\n✨ Firestore synchronization complete!');
}

if (require.main === module) {
  syncAll().catch(err => {
    console.error('Sync failed:', err);
    process.exit(1);
  });
}

module.exports = { syncAll };
