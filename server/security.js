const crypto = require('node:crypto');
const { db } = require('./db');

const WEBHOOK_SECRET = process.env.WEBHOOK_SECRET || 'topup_tournament_hmac_secret_2026';

// Role permissions mapping
const ROLE_PERMISSIONS = {
  super_admin: ['all'],
  tournament_manager: [
    'tournaments:create', 'tournaments:edit', 'tournaments:cancel',
    'matches:manage', 'matches:results', 'standings:approve',
    'room:view', 'room:edit', 'disputes:manage', 'prizes:approve'
  ],
  topup_operator: [
    'topup:manage', 'topup:retry', 'topup:review', 'packages:edit'
  ],
  finance_reviewer: [
    'prizes:approve', 'prizes:dual_approve', 'wallets:adjust',
    'topup:refund', 'audit:view'
  ],
  support: [
    'users:view', 'disputes:view', 'tickets:manage', 'audit:view'
  ],
  player: [
    'topup:order', 'tournament:join', 'tournament:cancel',
    'wallet:view', 'matches:my_matches'
  ]
};

function hasPermission(role, permission) {
  if (!role) return false;
  if (role === 'super_admin') return true;
  const perms = ROLE_PERMISSIONS[role] || [];
  return perms.includes(permission) || perms.includes('all');
}

/**
 * Generate HMAC SHA256 signature for payload
 */
function generateWebhookSignature(payloadString, secret = WEBHOOK_SECRET) {
  return crypto.createHmac('sha256', secret).update(payloadString).digest('hex');
}

/**
 * Verify HMAC SHA256 webhook signature
 */
function verifyWebhookSignature(payloadString, signatureHeader, secret = WEBHOOK_SECRET) {
  if (!signatureHeader) return false;
  try {
    const expected = crypto.createHmac('sha256', secret).update(payloadString).digest('hex');
    return crypto.timingSafeEqual(Buffer.from(signatureHeader, 'utf8'), Buffer.from(expected, 'utf8'));
  } catch (err) {
    return false;
  }
}

/**
 * Mask sensitive strings (Player IDs, bank accounts, tokens)
 */
function maskSensitive(val) {
  if (!val || typeof val !== 'string') return val;
  if (val.length <= 4) return '***';
  return val.slice(0, 3) + '***' + val.slice(-3);
}

/**
 * Record an immutable audit log
 */
function logAudit(actorId, action, entityType, entityId, reason, metadata = {}) {
  const now = new Date().toISOString();
  const id = 'aud_' + crypto.randomUUID().slice(0, 10);
  db.prepare(`
    INSERT INTO audit_logs (id, actor_id, action, entity_type, entity_id, reason, metadata, created_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
  `).run(
    id,
    actorId || 'system',
    action,
    entityType,
    entityId,
    reason || null,
    JSON.stringify(metadata),
    now
  );
  return id;
}

// In-memory rate limiter
const rateLimitMap = new Map();

function checkRateLimit(ipOrKey, limit = 60, windowMs = 60000) {
  const now = Date.now();
  let record = rateLimitMap.get(ipOrKey);
  if (!record || now > record.resetAt) {
    record = { count: 1, resetAt: now + windowMs };
    rateLimitMap.set(ipOrKey, record);
    return { allowed: true, remaining: limit - 1 };
  }
  record.count++;
  if (record.count > limit) {
    return { allowed: false, remaining: 0, resetIn: Math.ceil((record.resetAt - now) / 1000) };
  }
  return { allowed: true, remaining: limit - record.count };
}

module.exports = {
  WEBHOOK_SECRET,
  hasPermission,
  generateWebhookSignature,
  verifyWebhookSignature,
  maskSensitive,
  logAudit,
  checkRateLimit
};
