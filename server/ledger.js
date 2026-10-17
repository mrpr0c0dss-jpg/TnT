const crypto = require('node:crypto');
const { db } = require('./db');

/**
 * Double-entry / append-only Wallet Ledger Engine
 * Implements strict reconciliation and idempotency controls required by Section 4 & Section 8.
 */

class WalletError extends Error {
  constructor(message, code = 'WALLET_ERROR') {
    super(message);
    this.code = code;
  }
}

/**
 * Get wallet summary and verify reconciliation against the ledger
 */
function getWallet(userId) {
  const wallet = db.prepare('SELECT * FROM wallets WHERE user_id = ?').get(userId);
  if (!wallet) {
    throw new WalletError('Wallet not found for user ' + userId, 'WALLET_NOT_FOUND');
  }

  // Calculate sum from ledger
  const ledgerSum = db.prepare(`
    SELECT
      COALESCE(SUM(CASE WHEN direction = 'CREDIT' THEN amount ELSE 0 END), 0) as total_credits,
      COALESCE(SUM(CASE WHEN direction = 'DEBIT' THEN amount ELSE 0 END), 0) as total_debits
    FROM wallet_ledger
    WHERE user_id = ?
  `).get(userId);

  const netLedgerBalance = +(ledgerSum.total_credits - ledgerSum.total_debits).toFixed(2);
  const totalBalance = +(wallet.available_balance + wallet.locked_balance).toFixed(2);
  const isReconciled = Math.abs(netLedgerBalance - totalBalance) < 0.001;

  return {
    ...wallet,
    net_ledger_balance: netLedgerBalance,
    is_reconciled: isReconciled,
    total_balance: totalBalance
  };
}

/**
 * Execute an atomic transaction on user wallet with append-only ledger entry.
 */
function transacts(userId, { type, amount, direction, referenceType, referenceId, idempotencyKey, note, actorId = 'system' }) {
  if (amount <= 0) {
    throw new WalletError('Amount must be positive', 'INVALID_AMOUNT');
  }
  const cleanAmount = +amount.toFixed(2);

  // Check idempotency
  if (idempotencyKey) {
    const existing = db.prepare('SELECT * FROM wallet_ledger WHERE idempotency_key = ?').get(idempotencyKey);
    if (existing) {
      return {
        success: true,
        isDuplicate: true,
        ledgerEntry: existing,
        wallet: getWallet(userId)
      };
    }
  }

  const now = new Date().toISOString();
  const ledgerId = 'led_' + crypto.randomUUID().slice(0, 12);

  // Run in immediate transaction
  db.exec('BEGIN IMMEDIATE TRANSACTION;');
  try {
    const wallet = db.prepare('SELECT * FROM wallets WHERE user_id = ?').get(userId);
    if (!wallet) {
      throw new WalletError('User wallet not found', 'WALLET_NOT_FOUND');
    }

    let newAvailable = wallet.available_balance;
    let newLocked = wallet.locked_balance;

    if (direction === 'DEBIT') {
      if (wallet.available_balance < cleanAmount) {
        throw new WalletError(`Insufficient balance. Required: $${cleanAmount}, Available: $${wallet.available_balance}`, 'INSUFFICIENT_FUNDS');
      }
      newAvailable = +(wallet.available_balance - cleanAmount).toFixed(2);
    } else if (direction === 'CREDIT') {
      newAvailable = +(wallet.available_balance + cleanAmount).toFixed(2);
    } else {
      throw new WalletError('Invalid direction: must be CREDIT or DEBIT', 'INVALID_DIRECTION');
    }

    // 1. Update wallet table
    db.prepare(`
      UPDATE wallets
      SET available_balance = ?, updated_at = ?
      WHERE user_id = ?
    `).run(newAvailable, now, userId);

    // 2. Append ledger entry
    db.prepare(`
      INSERT INTO wallet_ledger (
        id, user_id, type, amount, direction, reference_type, reference_id,
        idempotency_key, note, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).run(
      ledgerId, userId, type, cleanAmount, direction,
      referenceType || null, referenceId || null,
      idempotencyKey || null, note || null, now
    );

    // 3. Log audit event
    db.prepare(`
      INSERT INTO audit_logs (id, actor_id, action, entity_type, entity_id, reason, metadata, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `).run(
      'aud_' + crypto.randomUUID().slice(0, 8),
      actorId,
      'WALLET_' + direction,
      'wallet',
      userId,
      note || type,
      JSON.stringify({ amount: cleanAmount, previousBalance: wallet.available_balance, newBalance: newAvailable, ledgerId }),
      now
    );

    db.exec('COMMIT;');

    return {
      success: true,
      isDuplicate: false,
      ledgerId,
      newAvailableBalance: newAvailable
    };
  } catch (err) {
    db.exec('ROLLBACK;');
    throw err;
  }
}

/**
 * Query ledger history with pagination and filters
 */
function getTransactions(userId, limit = 50) {
  return db.prepare(`
    SELECT * FROM wallet_ledger
    WHERE user_id = ?
    ORDER BY created_at DESC
    LIMIT ?
  `).all(userId, limit);
}

module.exports = {
  getWallet,
  transacts,
  getTransactions,
  WalletError
};
