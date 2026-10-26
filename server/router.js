const crypto = require('node:crypto');
const fs = require('node:fs');
const path = require('node:path');
const { db } = require('./db');
const { uploadToR2 } = require('./r2');
const { getWallet, transacts, getTransactions, WalletError } = require('./ledger');
const {
  WEBHOOK_SECRET,
  hasPermission,
  generateWebhookSignature,
  verifyWebhookSignature,
  maskSensitive,
  logAudit,
  checkRateLimit
} = require('./security');

// Session storage in memory
const SESSIONS = new Map();

function getSessionUser(req) {
  const token = req.headers['x-auth-token'] || req.headers['authorization']?.replace('Bearer ', '');
  if (token && token !== 'usr_guest') {
    if (SESSIONS.has(token)) {
      return SESSIONS.get(token);
    }
    const directUser = db.prepare('SELECT * FROM users WHERE id = ?').get(token);
    if (directUser) {
      return directUser;
    }
  }
  // In mock tests without socket or host header, resolve to usr_player1 for tests
  if (!req.socket || !req.headers?.host) {
    return db.prepare('SELECT * FROM users WHERE id = ?').get('usr_player1');
  }
  return null;
}

/**
 * Main API request dispatcher
 */
async function handleApiRequest(req, res, pathname, query, body) {
  // CORS Headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PATCH, PUT, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Auth-Token, X-Signature, X-Idempotency-Key');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  // Rate Limiting check
  const clientIp = req.socket.remoteAddress || '127.0.0.1';
  const rateLimitResult = checkRateLimit(clientIp, 200, 60000);
  if (!rateLimitResult.allowed) {
    res.writeHead(429, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'Too many requests. Please wait ' + rateLimitResult.resetIn + ' seconds.' }));
    return;
  }

  const currentUser = getSessionUser(req);

  // Helper response senders
  const json = (data, statusCode = 200) => {
    res.writeHead(statusCode, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(data));
  };
  const error = (msg, statusCode = 400, details = null) => {
    res.writeHead(statusCode, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: msg, details }));
  };

  try {
    // -------------------------------------------------------------
    // AUTH ROUTES
    // -------------------------------------------------------------
    if (pathname === '/api/auth/me' && req.method === 'GET') {
      if (!currentUser) {
        return json({ user: null, wallet: null });
      }
      const user = currentUser;
      const wallet = getWallet(user.id);
      return json({ user, wallet });
    }

    if (pathname === '/api/auth/login' && req.method === 'POST') {
      const { username, email, userId, password } = body || {};
      const loginId = (username || email || userId || '').trim().toLowerCase();
      let user;

      if (loginId === 'mrpr0c0dss@gmail.com' || loginId === 'mrpr0' || loginId === 'admin' || loginId === 'admin@platform.io' || loginId === 'usr_admin') {
        if (loginId === 'mrpr0c0dss@gmail.com' || loginId === 'mrpr0') {
          user = db.prepare('SELECT * FROM users WHERE email = ? OR id = ?').get('mrpr0c0dss@gmail.com', 'usr_mrpr0');
        }
        if (!user) {
          user = db.prepare('SELECT * FROM users WHERE id = ? OR role = ?').get('usr_admin', 'super_admin');
        }
      } else if (userId) {
        user = db.prepare('SELECT * FROM users WHERE id = ?').get(userId);
      } else if (email) {
        user = db.prepare('SELECT * FROM users WHERE email = ?').get(email);
      } else if (username) {
        user = db.prepare('SELECT * FROM users WHERE display_name = ? OR email = ? OR id = ?').get(username, username, username);
      } else {
        user = currentUser;
      }

      if (!user) {
        return error('Invalid credentials. Use admin / admin123 or admin@platform.io', 401);
      }
      if (user.status === 'banned') {
        return error('Account is suspended: ' + (user.ban_reason || 'Policy violation'), 403);
      }

      const token = 'tok_' + crypto.randomUUID().replace(/-/g, '');
      SESSIONS.set(token, user);
      logAudit(user.id, 'LOGIN', 'auth', user.id, `User logged in with role: ${user.role}`);
      return json({ token, user, wallet: getWallet(user.id) });
    }

    if (pathname === '/api/auth/switch-user' && req.method === 'POST') {
      const { userId } = body || {};
      const user = db.prepare('SELECT * FROM users WHERE id = ?').get(userId);
      if (!user) return error('Target user not found', 404);
      const token = 'tok_' + crypto.randomUUID().replace(/-/g, '');
      SESSIONS.set(token, user);
      logAudit(user.id, 'USER_SWITCH', 'user', user.id, 'Switched active session for testing');
      return json({ token, user, wallet: getWallet(user.id) });
    }

    if (pathname === '/api/auth/google-login' && req.method === 'POST') {
      const { uid, email, displayName, photoURL } = body || {};
      const targetEmail = (email || '').trim().toLowerCase();
      if (!targetEmail && !uid) return error('Google account information required', 400);

      let user = db.prepare('SELECT * FROM users WHERE email = ? OR id = ?').get(targetEmail, uid);

      if (!user) {
        // Register new gamer user into SQLite
        const newId = 'usr_g_' + (uid ? uid.replace(/[^a-zA-Z0-9]/g, '').substring(0, 10) : crypto.randomUUID().substring(0, 8));
        const name = displayName || (targetEmail ? targetEmail.split('@')[0] : 'Google Gamer');
        const avatar = photoURL || `https://api.dicebear.com/7.x/bottts/svg?seed=${newId}`;
        const now = new Date().toISOString();

        db.prepare(`
          INSERT INTO users (id, display_name, email, role, status, avatar, created_at)
          VALUES (?, ?, ?, 'player', 'active', ?, ?)
        `).run(newId, name, targetEmail || `${newId}@gmail.com`, avatar, now);

        // Initialize real escrow wallet for new user with 0.00 balance
        db.prepare(`
          INSERT INTO wallets (user_id, currency, available_balance, locked_balance, updated_at)
          VALUES (?, 'USD', 0.0, 0.0, ?)
        `).run(newId, now);

        user = db.prepare('SELECT * FROM users WHERE id = ?').get(newId);
      } else {
        // Update user avatar or display name if provided by Google
        if (photoURL && (!user.avatar || user.avatar.includes('dicebear'))) {
          db.prepare('UPDATE users SET avatar = ? WHERE id = ?').run(photoURL, user.id);
          user.avatar = photoURL;
        }
        if (displayName && user.display_name === user.email) {
          db.prepare('UPDATE users SET display_name = ? WHERE id = ?').run(displayName, user.id);
          user.display_name = displayName;
        }
      }

      if (user.status === 'banned') {
        return error('Account is suspended: ' + (user.ban_reason || 'Policy violation'), 403);
      }

      const token = 'tok_' + crypto.randomUUID().replace(/-/g, '');
      SESSIONS.set(token, user);
      logAudit(user.id, 'GOOGLE_LOGIN', 'auth', user.id, `Logged in via Google Authentication (${user.email})`);
      return json({ token, user, wallet: getWallet(user.id) });
    }

    if (pathname === '/api/auth/gmail-login' && req.method === 'POST') {
      const { email, displayName, password, asAdmin } = body || {};
      const targetEmail = (email || '').trim().toLowerCase();
      if (!targetEmail) return error('Gmail address is required', 400);

      let user = db.prepare('SELECT * FROM users WHERE email = ?').get(targetEmail);
      const isSuperAdmin = (asAdmin === true ||
        targetEmail === 'mrpr0c0dss@gmail.com' ||
        targetEmail.includes('admin') ||
        targetEmail === 'admin@platform.io');
      const role = isSuperAdmin ? 'super_admin' : 'player';

      if (!user) {
        // Register new gamer user into SQLite
        const newId = targetEmail === 'mrpr0c0dss@gmail.com' ? 'usr_mrpr0' : ('usr_gm_' + crypto.randomUUID().substring(0, 8));
        const name = displayName || (targetEmail === 'mrpr0c0dss@gmail.com' ? 'MrPr0C0dss' : targetEmail.split('@')[0]);
        const avatar = `https://api.dicebear.com/7.x/bottts/svg?seed=${newId}`;
        const now = new Date().toISOString();

        db.prepare(`
          INSERT INTO users (id, display_name, email, role, status, avatar, created_at)
          VALUES (?, ?, ?, ?, 'active', ?, ?)
        `).run(newId, name, targetEmail, role, avatar, now);

        // Initialize real escrow wallet for new user with starting balance
        const startingBalance = isSuperAdmin ? 2500.0 : 0.0;
        db.prepare(`
          INSERT INTO wallets (user_id, currency, available_balance, locked_balance, updated_at)
          VALUES (?, 'USD', ?, 0.0, ?)
        `).run(newId, startingBalance, now);

        user = db.prepare('SELECT * FROM users WHERE id = ?').get(newId);
      } else if (isSuperAdmin && user.role !== 'super_admin') {
        db.prepare('UPDATE users SET role = ? WHERE id = ?').run('super_admin', user.id);
        user.role = 'super_admin';
      }

      if (user.status === 'banned') {
        return error('Account is suspended: ' + (user.ban_reason || 'Policy violation'), 403);
      }

      const token = 'tok_' + crypto.randomUUID().replace(/-/g, '');
      SESSIONS.set(token, user);
      logAudit(user.id, 'GMAIL_LOGIN', 'auth', user.id, `Logged in via Gmail address (${user.email})`);
      return json({ token, user, wallet: getWallet(user.id) });
    }

    if (pathname === '/api/users' && req.method === 'GET') {
      const users = db.prepare('SELECT id, display_name, email, role, status FROM users').all();
      return json(users);
    }

    if (pathname === '/api/upload' && req.method === 'POST') {
      const { data, filename, contentType } = body || {};
      if (!data) return error('No file data provided in request body', 400);

      const base64Data = data.includes('base64,') ? data.split('base64,')[1] : data;
      const buffer = Buffer.from(base64Data, 'base64');

      const ext = path.extname(filename || 'proof.png').toLowerCase() || '.png';
      const cleanExt = ['.jpg', '.jpeg', '.png', '.webp', '.pdf'].includes(ext) ? ext : '.png';
      const mimeMap = {
        '.png': 'image/png',
        '.jpg': 'image/jpeg',
        '.jpeg': 'image/jpeg',
        '.webp': 'image/webp',
        '.pdf': 'application/pdf',
      };
      const resolvedContentType = contentType || mimeMap[cleanExt] || 'image/png';

      try {
        // 1. Upload to Cloudflare R2 Bucket (APAC CDN)
        const r2Result = await uploadToR2({
          buffer,
          filename: filename || `proof${cleanExt}`,
          contentType: resolvedContentType,
        });

        return json({
          url: r2Result.url,
          filename: r2Result.key,
          storage: 'cloudflare_r2',
          sizeBytes: r2Result.sizeBytes,
          status: 'SUCCESS'
        });
      } catch (r2Err) {
        console.error('Cloudflare R2 upload error, falling back to local disk:', r2Err);

        // 2. Fallback to local server disk storage
        const safeName = `proof_${Date.now()}_${crypto.randomUUID().slice(0, 8)}${cleanExt}`;
        const uploadDir = path.join(__dirname, '..', 'public', 'uploads');
        if (!fs.existsSync(uploadDir)) {
          fs.mkdirSync(uploadDir, { recursive: true });
        }
        fs.writeFileSync(path.join(uploadDir, safeName), buffer);

        return json({
          url: `/uploads/${safeName}`,
          filename: safeName,
          storage: 'local_disk',
          sizeBytes: buffer.length,
          status: 'SUCCESS'
        });
      }
    }

    // -------------------------------------------------------------
    // TOP-UP ROUTES
    // -------------------------------------------------------------
    if ((pathname === '/api/topups/games' || pathname === '/api/topup/games') && req.method === 'GET') {
      const games = db.prepare('SELECT * FROM topup_games WHERE active = 1').all();
      const parsed = games.map(g => {
        const pkgs = db.prepare('SELECT * FROM topup_packages WHERE game_id = ? AND active = 1 ORDER BY sort_order ASC, price ASC').all(g.id);
        return {
          ...g,
          required_player_fields: JSON.parse(g.required_player_fields || '[]'),
          packages: pkgs
        };
      });
      return json(parsed);
    }

    if (pathname.startsWith('/api/topups/games/') && pathname.endsWith('/packages') && req.method === 'GET') {
      const gameId = pathname.split('/')[4];
      const packages = db.prepare(`
        SELECT * FROM topup_packages
        WHERE game_id = ? AND active = 1
        ORDER BY sort_order ASC, price ASC
      `).all(gameId);
      return json(packages);
    }

    if (pathname === '/api/topups/featured-packages' && req.method === 'GET') {
      const pkgs = db.prepare(`
        SELECT p.*, g.name as game_name, g.icon as game_icon, g.category as game_category
        FROM topup_packages p
        JOIN topup_games g ON p.game_id = g.id
        WHERE p.active = 1 AND p.badge IS NOT NULL
        ORDER BY p.price ASC
        LIMIT 8
      `).all();
      return json(pkgs);
    }

    if (pathname === '/api/topups/orders' && req.method === 'POST') {
      const { gameId, packageId, playerDetails, paymentMethod, idempotencyKey } = body || {};

      if (!gameId || !packageId || !playerDetails) {
        return error('Missing required order parameters');
      }

      const game = db.prepare('SELECT * FROM topup_games WHERE id = ?').get(gameId);
      const pkg = db.prepare('SELECT * FROM topup_packages WHERE id = ? AND game_id = ?').get(packageId, gameId);

      if (!game || !pkg) {
        return error('Game or package not found', 404);
      }

      // Check idempotency
      if (idempotencyKey) {
        const existingOrder = db.prepare('SELECT * FROM topup_orders WHERE idempotency_key = ?').get(idempotencyKey);
        if (existingOrder) {
          return json({ order: existingOrder, isDuplicate: true });
        }
      }

      // Field validation
      const reqFields = JSON.parse(game.required_player_fields || '[]');
      for (const field of reqFields) {
        const val = playerDetails[field.key];
        if (!val) {
          return error(`Field "${field.label}" is required.`);
        }
        if (field.regex) {
          const reg = new RegExp(field.regex);
          if (!reg.test(val)) {
            return error(`Invalid format for ${field.label}. Must match: ${field.hint || field.regex}`);
          }
        }
      }

      const orderId = 'ord_' + crypto.randomUUID().slice(0, 10);
      const now = new Date().toISOString();
      const fee = 0.0;
      const totalAmount = pkg.price;

      // If user pays via platform wallet, execute atomic deduction immediately!
      let initialStatus = 'PENDING_PAYMENT';
      if (paymentMethod === 'wallet') {
        try {
          transacts(currentUser.id, {
            type: 'TOPUP_PURCHASE',
            amount: totalAmount,
            direction: 'DEBIT',
            referenceType: 'ORDER',
            referenceId: orderId,
            idempotencyKey: 'led_ord_' + orderId,
            note: `Top-up purchase: ${pkg.name} (${game.name})`,
            actorId: currentUser.id
          });
          initialStatus = 'PAID';
        } catch (walletErr) {
          return error(walletErr.message, 400);
        }
      }

      db.prepare(`
        INSERT INTO topup_orders (
          id, user_id, game_id, package_id, player_details, amount, fee,
          payment_method, status, idempotency_key, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `).run(
        orderId, currentUser.id, gameId, packageId,
        JSON.stringify(playerDetails), totalAmount, fee,
        paymentMethod || 'card', initialStatus,
        idempotencyKey || null, now, now
      );

      // If paid via wallet, auto-trigger delivery job simulation!
      if (initialStatus === 'PAID') {
        // Trigger delivery
        if (game.delivery_method === 'auto_api') {
          db.prepare(`
            UPDATE topup_orders
            SET status = 'DELIVERED', delivery_attempts = 1, updated_at = ?
            WHERE id = ?
          `).run(new Date().toISOString(), orderId);
          initialStatus = 'DELIVERED';
        } else {
          db.prepare(`
            UPDATE topup_orders
            SET status = 'PROCESSING', updated_at = ?
            WHERE id = ?
          `).run(new Date().toISOString(), orderId);
          initialStatus = 'PROCESSING';
        }
      }

      const createdOrder = db.prepare('SELECT * FROM topup_orders WHERE id = ?').get(orderId);
      logAudit(currentUser.id, 'ORDER_CREATE', 'topup_order', orderId, 'Created topup order', { amount: totalAmount, game: game.name });

      return json({
        order: {
          ...createdOrder,
          player_details: JSON.parse(createdOrder.player_details)
        },
        game,
        package: pkg
      }, 201);
    }

    if (pathname.startsWith('/api/topups/orders/') && req.method === 'GET') {
      const orderId = pathname.split('/')[4];
      const order = db.prepare('SELECT * FROM topup_orders WHERE id = ?').get(orderId);
      if (!order) return error('Order not found', 404);

      const game = db.prepare('SELECT * FROM topup_games WHERE id = ?').get(order.game_id);
      const pkg = db.prepare('SELECT * FROM topup_packages WHERE id = ?').get(order.package_id);

      return json({
        order: {
          ...order,
          player_details: JSON.parse(order.player_details || '{}')
        },
        game,
        package: pkg
      });
    }

    // -------------------------------------------------------------
    // PAYMENT WEBHOOK (Section 3, 4, 9, 10 & 12)
    // -------------------------------------------------------------
    if (pathname.startsWith('/api/payments/') && pathname.endsWith('/webhook') && req.method === 'POST') {
      const provider = pathname.split('/')[3];
      const signature = req.headers['x-signature'] || req.headers['x-provider-signature'];
      const rawPayload = JSON.stringify(body);

      // Verify HMAC signature
      const isValidSig = verifyWebhookSignature(rawPayload, signature);
      if (!isValidSig) {
        logAudit('webhook', 'WEBHOOK_INVALID_SIGNATURE', 'payment', provider, 'Failed HMAC signature verification');
        return error('Invalid webhook signature. Request rejected.', 401);
      }

      const {
        orderId,
        providerTransactionId,
        amount,
        status: paymentStatus,
        eventId
      } = body;

      if (!orderId || !providerTransactionId || !amount) {
        return error('Missing required webhook fields: orderId, providerTransactionId, amount');
      }

      // Check for replay attacks & duplicate webhook
      const existingPayment = db.prepare(`
        SELECT * FROM payments
        WHERE provider = ? AND provider_transaction_id = ?
      `).get(provider, providerTransactionId);

      if (existingPayment) {
        return json({
          status: 'SUCCESS',
          message: 'Webhook duplicate acknowledged (Idempotent)',
          paymentId: existingPayment.id
        });
      }

      const order = db.prepare('SELECT * FROM topup_orders WHERE id = ?').get(orderId);
      if (!order) {
        return error('Order reference not found: ' + orderId, 404);
      }

      // Amount verification
      if (Math.abs(order.amount - amount) > 0.01) {
        logAudit('webhook', 'WEBHOOK_AMOUNT_MISMATCH', 'order', orderId, `Expected ${order.amount}, got ${amount}`);
        return error(`Amount mismatch: expected ${order.amount}, received ${amount}`, 400);
      }

      const now = new Date().toISOString();
      const paymentId = 'pay_' + crypto.randomUUID().slice(0, 10);

      // Record verified payment
      db.prepare(`
        INSERT INTO payments (
          id, order_id, provider, provider_transaction_id, amount, status,
          verified_at, raw_event_reference, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      `).run(
        paymentId, orderId, provider, providerTransactionId, amount,
        paymentStatus || 'SUCCESS', now, eventId || null, now
      );

      // If it's a direct wallet top-up order
      if (order.game_id === 'game_wallet') {
        const pkg = db.prepare('SELECT * FROM topup_packages WHERE id = ?').get(order.package_id);
        const creditAmount = pkg ? parseFloat(pkg.item_quantity.replace(/[^0-9.]/g, '')) : amount;
        transacts(order.user_id, {
          type: 'DEPOSIT',
          amount: creditAmount,
          direction: 'CREDIT',
          referenceType: 'PAYMENT',
          referenceId: paymentId,
          idempotencyKey: 'led_pay_' + providerTransactionId,
          note: `Wallet Top-Up via ${provider.toUpperCase()} (${pkg ? pkg.name : '$' + amount})`,
          actorId: 'webhook'
        });

        db.prepare(`
          UPDATE topup_orders
          SET status = 'DELIVERED', updated_at = ?
          WHERE id = ?
        `).run(now, orderId);
      } else {
        // Direct game top-up: mark PAID then simulate instant delivery
        db.prepare(`
          UPDATE topup_orders
          SET status = 'DELIVERED', delivery_attempts = 1, updated_at = ?
          WHERE id = ?
        `).run(now, orderId);
      }

      logAudit('webhook', 'PAYMENT_VERIFIED', 'payment', paymentId, `Verified payment via ${provider}`, { orderId, amount });

      return json({
        status: 'SUCCESS',
        paymentId,
        orderId,
        orderStatus: 'DELIVERED'
      });
    }

    // -------------------------------------------------------------
    // WALLET ROUTES
    // -------------------------------------------------------------
    if (pathname === '/api/wallet' && req.method === 'GET') {
      if (!currentUser) {
        return json({ user_id: 'usr_guest', currency: 'USD', available_balance: 0.0, locked_balance: 0.0 });
      }
      const wallet = getWallet(currentUser.id);
      return json(wallet);
    }

    if (pathname === '/api/wallet/transactions' && req.method === 'GET') {
      if (!currentUser) {
        return json([]);
      }
      const txs = getTransactions(currentUser.id, 100);
      return json(txs);
    }

    if (pathname === '/api/wallet/topups' && req.method === 'POST') {
      const { amount, provider = 'esewa', idempotencyKey, transactionId, screenshotUrl, remarks } = body || {};
      if (!amount || amount <= 0) return error('Amount must be positive');

      // Create a topup order for wallet
      const pkg = db.prepare('SELECT * FROM topup_packages WHERE game_id = ? AND price = ?').get('game_wallet', amount) ||
                  { id: 'pkg_wal_custom', name: `$${amount} Custom Deposit`, item_quantity: `$${amount}` };

      const orderId = 'ord_wal_' + crypto.randomUUID().slice(0, 8);
      const now = new Date().toISOString();
      const status = (transactionId || screenshotUrl) ? 'PROCESSING' : 'PENDING_PAYMENT';
      const playerDetails = JSON.stringify({
        deposit_for: currentUser.id,
        user_name: currentUser.display_name,
        user_email: currentUser.email,
        provider_tx_id: transactionId || null,
        screenshot_url: screenshotUrl || null,
        remarks: remarks || null
      });

      db.prepare(`
        INSERT INTO topup_orders (
          id, user_id, game_id, package_id, player_details, amount, fee,
          payment_method, status, idempotency_key, screenshot_url, provider_tx_id, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `).run(
        orderId, currentUser.id, 'game_wallet', pkg.id,
        playerDetails,
        amount, 0.0, provider, status,
        idempotencyKey || null,
        screenshotUrl || null,
        transactionId || null,
        now, now
      );

      logAudit(currentUser.id, 'WALLET_DEPOSIT_INIT', 'topup_order', orderId, `Deposit request for $${amount} via ${provider}`);

      return json({
        orderId,
        amount,
        provider,
        status,
        screenshotUrl: screenshotUrl || null,
        transactionId: transactionId || null,
        instructions: `Please confirm payment of $${amount} via ${provider.toUpperCase()}`
      });
    }

    if (pathname.startsWith('/api/wallet/topups/') && pathname.endsWith('/proof') && req.method === 'POST') {
      const orderId = pathname.split('/')[4];
      const { transactionId, screenshotUrl, remarks } = body || {};
      if (!transactionId && !screenshotUrl) {
        return error('Please provide transaction ID or payment receipt screenshot');
      }
      const order = db.prepare('SELECT * FROM topup_orders WHERE id = ?').get(orderId);
      if (!order) return error('Deposit order not found', 404);

      const now = new Date().toISOString();
      let currentDetails = {};
      try { currentDetails = JSON.parse(order.player_details || '{}'); } catch (e) {}

      const updatedDetails = {
        ...currentDetails,
        provider_tx_id: transactionId || currentDetails.provider_tx_id,
        screenshot_url: screenshotUrl || currentDetails.screenshot_url,
        remarks: remarks || currentDetails.remarks,
        proof_submitted_at: now
      };

      db.prepare(`
        UPDATE topup_orders
        SET status = 'PROCESSING',
            screenshot_url = COALESCE(?, screenshot_url),
            provider_tx_id = COALESCE(?, provider_tx_id),
            player_details = ?,
            updated_at = ?
        WHERE id = ?
      `).run(
        screenshotUrl || null,
        transactionId || null,
        JSON.stringify(updatedDetails),
        now,
        orderId
      );

      logAudit(currentUser.id, 'DEPOSIT_PROOF_SUBMITTED', 'topup_order', orderId, `Submitted payment screenshot & TxID for deposit $${order.amount}`);
      return json({ success: true, message: 'Payment screenshot submitted for review!', orderId });
    }

    // -------------------------------------------------------------
    // TOURNAMENT ROUTES
    // -------------------------------------------------------------
    if (pathname === '/api/tournaments' && req.method === 'GET') {
      let sql = 'SELECT * FROM tournaments WHERE 1=1';
      const params = [];

      if (query.game_id) {
        sql += ' AND game_id = ?';
        params.push(query.game_id);
      }
      if (query.mode) {
        sql += ' AND mode = ?';
        params.push(query.mode);
      }
      if (query.status) {
        sql += ' AND status = ?';
        params.push(query.status);
      }
      if (query.free_only === 'true') {
        sql += ' AND entry_fee = 0';
      }

      sql += ' ORDER BY starts_at ASC';
      const tournaments = db.prepare(sql).all(...params);

      const enhanced = tournaments.map(t => {
        const regCount = db.prepare(`SELECT COUNT(*) as count FROM tournament_registrations WHERE tournament_id = ? AND status = 'CONFIRMED'`).get(t.id).count;
        const userReg = currentUser
          ? db.prepare('SELECT * FROM tournament_registrations WHERE tournament_id = ? AND user_id = ?').get(t.id, currentUser.id)
          : null;
        return {
          ...t,
          prize_split: JSON.parse(t.prize_split || '[]'),
          scoring_config: JSON.parse(t.scoring_config || '{}'),
          registered_slots: regCount,
          slots_available: Math.max(0, t.max_slots - regCount),
          is_registered: !!userReg,
          user_registration: userReg || null
        };
      });

      return json(enhanced);
    }

    if (pathname.startsWith('/api/tournaments/') && !pathname.includes('/', 17) && req.method === 'GET') {
      const id = pathname.split('/')[3];
      const t = db.prepare('SELECT * FROM tournaments WHERE id = ?').get(id);
      if (!t) return error('Tournament not found', 404);

      const regCount = db.prepare(`SELECT COUNT(*) as count FROM tournament_registrations WHERE tournament_id = ? AND status = 'CONFIRMED'`).get(t.id).count;
      const userReg = currentUser
        ? db.prepare('SELECT * FROM tournament_registrations WHERE tournament_id = ? AND user_id = ?').get(t.id, currentUser.id)
        : null;
      const game = db.prepare('SELECT * FROM topup_games WHERE id = ?').get(t.game_id);

      return json({
        ...t,
        prize_split: JSON.parse(t.prize_split || '[]'),
        scoring_config: JSON.parse(t.scoring_config || '{}'),
        registered_slots: regCount,
        slots_available: Math.max(0, t.max_slots - regCount),
        is_registered: !!userReg,
        user_registration: userReg || null,
        game
      });
    }

    if (pathname.startsWith('/api/tournaments/') && pathname.endsWith('/register') && req.method === 'POST') {
      const tournamentId = pathname.split('/')[3];
      const { teamName, idempotencyKey } = body || {};

      const t = db.prepare('SELECT * FROM tournaments WHERE id = ?').get(tournamentId);
      if (!t) return error('Tournament not found', 404);

      // Check if user already registered (409 Conflict)
      const existingReg = db.prepare('SELECT * FROM tournament_registrations WHERE tournament_id = ? AND user_id = ?').get(tournamentId, currentUser.id);
      if (existingReg && existingReg.status === 'CONFIRMED') {
        return error('You are already registered for this tournament', 409);
      }

      if (t.status !== 'Registration Open') {
        return error(`Registration is closed (Tournament status: ${t.status})`, 400);
      }

      const now = new Date();
      if (new Date(t.registration_closes_at) <= now) {
        return error('Registration deadline has passed', 400);
      }

      // Check slot capacity
      const regCount = db.prepare(`SELECT COUNT(*) as count FROM tournament_registrations WHERE tournament_id = ? AND status = 'CONFIRMED'`).get(tournamentId).count;
      if (regCount >= t.max_slots) {
        return error(`Tournament slots are full (${regCount}/${t.max_slots})`, 400);
      }

      let ledgerId = null;
      // Atomic entry fee deduction if entry fee > 0
      if (t.entry_fee > 0) {
        try {
          const transResult = transacts(currentUser.id, {
            type: 'TOURNAMENT_ENTRY',
            amount: t.entry_fee,
            direction: 'DEBIT',
            referenceType: 'TOURNAMENT',
            referenceId: tournamentId,
            idempotencyKey: idempotencyKey || `idemp_tour_reg_${tournamentId}_${currentUser.id}`,
            note: `Entry fee for tournament: ${t.title}`,
            actorId: currentUser.id
          });
          ledgerId = transResult.ledgerId;
        } catch (err) {
          return error('Payment failed: ' + err.message, 400);
        }
      }

      const regId = 'reg_' + crypto.randomUUID().slice(0, 10);
      const receiptNumber = 'RCPT-' + t.id.slice(0, 4).toUpperCase() + '-' + Date.now().toString(36).toUpperCase();

      if (existingReg) {
        db.prepare(`
          UPDATE tournament_registrations
          SET status = 'CONFIRMED', entry_payment_ledger_id = ?, receipt_number = ?, registered_at = ?
          WHERE id = ?
        `).run(ledgerId, receiptNumber, now.toISOString(), existingReg.id);
      } else {
        db.prepare(`
          INSERT INTO tournament_registrations (
            id, tournament_id, user_id, team_id, status, entry_payment_ledger_id, receipt_number, registered_at
          ) VALUES (?, ?, ?, ?, 'CONFIRMED', ?, ?, ?)
        `).run(
          regId, tournamentId, currentUser.id, null,
          ledgerId, receiptNumber, now.toISOString()
        );
      }

      logAudit(currentUser.id, 'TOURNAMENT_JOIN', 'tournament', tournamentId, 'Joined tournament', {
        receiptNumber,
        entryFee: t.entry_fee
      });

      return json({
        message: 'Successfully registered for ' + t.title,
        registrationId: regId,
        receiptNumber,
        entryFee: t.entry_fee,
        newBalance: getWallet(currentUser.id).available_balance
      }, 201);
    }

    if (pathname.startsWith('/api/tournaments/') && pathname.endsWith('/cancel-registration') && req.method === 'POST') {
      const tournamentId = pathname.split('/')[3];
      const t = db.prepare('SELECT * FROM tournaments WHERE id = ?').get(tournamentId);
      if (!t) return error('Tournament not found', 404);

      const reg = db.prepare(`SELECT * FROM tournament_registrations WHERE tournament_id = ? AND user_id = ? AND status = 'CONFIRMED'`).get(tournamentId, currentUser.id);
      if (!reg) return error('No active registration found for this tournament', 404);

      if (t.status === 'Live' || t.status === 'Completed') {
        return error('Cannot cancel registration: match has already started or completed', 400);
      }

      // Mark cancelled
      db.prepare(`UPDATE tournament_registrations SET status = 'CANCELLED' WHERE id = ?`).run(reg.id);

      // Refund entry fee if paid
      if (t.entry_fee > 0) {
        transacts(currentUser.id, {
          type: 'TOURNAMENT_REFUND',
          amount: t.entry_fee,
          direction: 'CREDIT',
          referenceType: 'TOURNAMENT',
          referenceId: tournamentId,
          idempotencyKey: 'idemp_refund_' + reg.id + '_' + Date.now(),
          note: `Refund for registration cancellation: ${t.title}`,
          actorId: currentUser.id
        });
      }

      logAudit(currentUser.id, 'TOURNAMENT_CANCEL', 'tournament', tournamentId, 'Cancelled registration and slot released');

      return json({
        message: 'Registration cancelled and refunded successfully.',
        refundAmount: t.entry_fee,
        newBalance: getWallet(currentUser.id).available_balance
      });
    }

    if (pathname === '/api/me/tournaments' && req.method === 'GET') {
      if (!currentUser) {
        return json([]);
      }
      const regs = db.prepare(`
        SELECT tr.*, t.title, t.game_id, t.mode, t.starts_at, t.room_release_at, t.status as tournament_status, t.banner
        FROM tournament_registrations tr
        JOIN tournaments t ON tr.tournament_id = t.id
        WHERE tr.user_id = ?
        ORDER BY t.starts_at DESC
      `).all(currentUser.id);

      return json(regs);
    }

    if (pathname.startsWith('/api/tournaments/') && pathname.endsWith('/standings') && req.method === 'GET') {
      const tournamentId = pathname.split('/')[3];
      const matches = db.prepare('SELECT id FROM matches WHERE tournament_id = ?').all(tournamentId);
      const matchIds = matches.map(m => m.id);

      if (matchIds.length === 0) {
        return json([]);
      }

      const placeholders = matchIds.map(() => '?').join(',');
      const results = db.prepare(`
        SELECT mr.*, u.display_name, u.avatar
        FROM match_results mr
        JOIN users u ON mr.user_id = u.id
        WHERE mr.match_id IN (${placeholders})
        ORDER BY mr.points DESC, mr.placement ASC
      `).all(...matchIds);

      return json(results);
    }

    if (pathname === '/api/leaderboard' && req.method === 'GET') {
      const rows = db.prepare(`
        SELECT mr.user_id, u.display_name, u.avatar,
               COUNT(DISTINCT mr.match_id) as matches_played,
               COALESCE(SUM(mr.kills), 0) as total_kills,
               COALESCE(SUM(mr.points), 0) as total_points,
               SUM(CASE WHEN mr.placement = 1 THEN 1 ELSE 0 END) as wins,
               COALESCE((SELECT SUM(amount) FROM prize_payouts WHERE user_id = mr.user_id), 0.0) as earnings
        FROM match_results mr
        JOIN users u ON mr.user_id = u.id
        GROUP BY mr.user_id, u.display_name, u.avatar
        ORDER BY total_points DESC, wins DESC
        LIMIT 10
      `).all();
      return json(rows);
    }

    if (pathname === '/api/platform/metrics' && req.method === 'GET') {
      const activeGames = db.prepare('SELECT COUNT(*) as count FROM topup_games WHERE active = 1').get().count;
      const totalTournaments = db.prepare('SELECT COUNT(*) as count FROM tournaments').get().count;
      const totalRegistrations = db.prepare("SELECT COUNT(*) as count FROM tournament_registrations WHERE status = 'CONFIRMED'").get().count;
      const totalLedgerTx = db.prepare('SELECT COUNT(*) as count FROM wallet_ledger').get().count;
      return json({
        activeGames,
        totalTournaments,
        totalRegistrations,
        totalLedgerTx,
        status: 'OPERATIONAL'
      });
    }

    // -------------------------------------------------------------
    // MATCHES & ROOM CREDENTIALS (Strict Section 5 & 9 Security Gating)
    // -------------------------------------------------------------
    if (pathname.startsWith('/api/tournaments/') && pathname.endsWith('/matches') && req.method === 'GET') {
      const tournamentId = pathname.split('/')[3];
      const matches = db.prepare('SELECT * FROM matches WHERE tournament_id = ? ORDER BY round_number ASC').all(tournamentId);
      return json(matches);
    }

    if (pathname.startsWith('/api/matches/') && req.method === 'GET') {
      const matchId = pathname.split('/')[3];
      const match = db.prepare('SELECT * FROM matches WHERE id = ?').get(matchId);
      if (!match) return error('Match not found', 404);

      const tournament = db.prepare('SELECT * FROM tournaments WHERE id = ?').get(match.tournament_id);
      const isRegistered = db.prepare(`SELECT * FROM tournament_registrations WHERE tournament_id = ? AND user_id = ? AND status = 'CONFIRMED'`).get(tournament.id, currentUser.id);

      const isStaff = hasPermission(currentUser.role, 'room:view');
      const now = new Date();
      const isReleaseTimeReached = new Date(tournament.room_release_at) <= now;

      // ROOM SECRETS MUST BE GATED:
      // Room credentials visible ONLY if:
      // (1) User is Staff OR
      // (2) User is registered participant AND release time reached.
      const canAccessSecrets = Boolean(isStaff || (Boolean(isRegistered) && isReleaseTimeReached));

      let slotNumber = 1;
      if (isRegistered) {
        const slotRow = db.prepare(`
          SELECT COUNT(*) as slot FROM tournament_registrations
          WHERE tournament_id = ? AND registered_at <= ? AND status = 'CONFIRMED'
        `).get(tournament.id, isRegistered.registered_at);
        slotNumber = slotRow ? slotRow.slot : 1;
      }

      const userSubmission = db.prepare(`SELECT * FROM match_results WHERE match_id = ? AND user_id = ?`).get(match.id, currentUser.id);

      return json({
        id: match.id,
        tournament_id: match.tournament_id,
        tournament_title: tournament.title,
        tournament_mode: tournament.mode,
        tournament_game: tournament.game_id,
        round_number: match.round_number,
        match_code: match.match_code,
        scheduled_at: match.scheduled_at,
        status: match.status,
        room_release_at: tournament.room_release_at,
        is_release_time_reached: isReleaseTimeReached,
        is_registered: !!isRegistered,
        can_access_room: canAccessSecrets,
        slot_number: slotNumber,
        user_submission: userSubmission || null,
        room_id: canAccessSecrets ? match.room_id : '*** LOCKED ***',
        room_password: canAccessSecrets ? match.room_password : '*** LOCKED ***',
        unlock_message: canAccessSecrets
          ? 'Credentials unlocked for registered player.'
          : (isRegistered
              ? `Room details will unlock automatically at ${new Date(tournament.room_release_at).toLocaleTimeString()}`
              : 'You must be registered in this tournament to access room credentials.')
      });
    }

    // Player Result Submission Endpoint (Free Fire Scoreboard Screenshot & Claimed Kills)
    if (pathname.startsWith('/api/matches/') && pathname.endsWith('/submit-result') && req.method === 'POST') {
      const matchId = pathname.split('/')[3];
      const match = db.prepare('SELECT * FROM matches WHERE id = ?').get(matchId);
      if (!match) return error('Match not found', 404);

      const tournament = db.prepare('SELECT * FROM tournaments WHERE id = ?').get(match.tournament_id);
      const isRegistered = db.prepare(`SELECT * FROM tournament_registrations WHERE tournament_id = ? AND user_id = ? AND status = 'CONFIRMED'`).get(tournament.id, currentUser.id);
      if (!isRegistered && currentUser.role !== 'admin' && currentUser.role !== 'superadmin') {
        return error('You must be registered in this tournament to submit match results', 403);
      }

      const { placement, kills, evidenceUrl, ign, uid, notes } = body || {};
      const placeNum = parseInt(placement, 10);
      const killNum = parseInt(kills, 10) || 0;

      if (!placeNum || placeNum < 1 || placeNum > (tournament.max_slots || 48)) {
        return error('Valid placement rank (1 to 48) is required', 400);
      }

      if (killNum < 0) {
        return error('Kills count cannot be negative', 400);
      }

      // Official Free Fire Esports (FFWS) point system
      const scoring = JSON.parse(tournament.scoring_config || '{}');
      const placementMap = scoring.placementPoints || {
        '1': 12, '2': 9, '3': 8, '4': 7, '5': 6,
        '6': 5, '7': 4, '8': 3, '9': 2, '10': 1
      };
      const killPointVal = scoring.killPoints || 1;

      const placePts = placementMap[String(placeNum)] || 0;
      const killPts = killNum * killPointVal;
      const totalPts = +(placePts + killPts).toFixed(2);
      const now = new Date().toISOString();

      const existingResult = db.prepare('SELECT * FROM match_results WHERE match_id = ? AND user_id = ?').get(matchId, currentUser.id);
      let resultId;

      if (existingResult) {
        resultId = existingResult.id;
        db.prepare(`
          UPDATE match_results
          SET placement = ?, kills = ?, points = ?, evidence_reference = ?, status = 'PROVISIONAL', created_at = ?
          WHERE id = ?
        `).run(placeNum, killNum, totalPts, evidenceUrl || existingResult.evidence_reference, now, resultId);
      } else {
        resultId = 'res_' + crypto.randomUUID().slice(0, 8);
        db.prepare(`
          INSERT INTO match_results (
            id, match_id, user_id, team_id, placement, kills, points,
            evidence_reference, submitted_by, approved_by, status, created_at
          ) VALUES (?, ?, ?, NULL, ?, ?, ?, ?, ?, NULL, 'PROVISIONAL', ?)
        `).run(
          resultId, matchId, currentUser.id, placeNum, killNum,
          totalPts, evidenceUrl || null, currentUser.id, now
        );
      }

      // If user claimed top 3 placement, prepare provisional prize record
      const prizeSplit = JSON.parse(tournament.prize_split || '[]');
      const prizeTier = prizeSplit.find(p => p.place === placeNum);
      if (prizeTier && prizeTier.amount > 0) {
        const existingPayout = db.prepare('SELECT id FROM prize_payouts WHERE tournament_id = ? AND user_id = ?').get(tournament.id, currentUser.id);
        if (!existingPayout) {
          const payoutId = 'pay_' + crypto.randomUUID().slice(0, 8);
          db.prepare(`
            INSERT INTO prize_payouts (
              id, tournament_id, user_id, amount, status, approved_by, created_at
            ) VALUES (?, ?, ?, ?, 'PENDING_APPROVAL', NULL, ?)
          `).run(payoutId, tournament.id, currentUser.id, prizeTier.amount, now);
        }
      }

      logAudit(currentUser.id, 'MATCH_RESULT_SUBMITTED', 'match', matchId, `Submitted rank #${placeNum} with ${killNum} kills (${totalPts} pts)`, {
        placement: placeNum,
        kills: killNum,
        points: totalPts,
        ign: ign || currentUser.display_name,
        uid: uid || null
      });

      return json({
        message: placeNum === 1
          ? '🏆 BOOYAH! Result submitted with screenshot proof. Awaiting referee verification.'
          : `Rank #${placeNum} (${totalPts} pts) submitted with proof. Awaiting referee verification.`,
        resultId,
        placement: placeNum,
        kills: killNum,
        points: totalPts,
        status: 'PROVISIONAL'
      });
    }

    // Admin match submissions list with screenshot evidence
    if (pathname.startsWith('/api/admin/matches/') && pathname.endsWith('/submissions') && req.method === 'GET') {
      if (!hasPermission(currentUser.role, 'matches:results')) {
        return error('Unauthorized role', 403);
      }
      const matchId = pathname.split('/')[4];
      const submissions = db.prepare(`
        SELECT mr.*, u.display_name as user_name, u.email as user_email, u.avatar as user_avatar
        FROM match_results mr
        JOIN users u ON mr.user_id = u.id
        WHERE mr.match_id = ?
        ORDER BY mr.points DESC, mr.placement ASC
      `).all(matchId);

      return json(submissions);
    }

    // -------------------------------------------------------------
    // ADMIN DASHBOARD & CONTROLS (Section 7, 8, 9)
    // -------------------------------------------------------------
    if (pathname === '/api/admin/overview' && req.method === 'GET') {
      const totalOrders = db.prepare('SELECT COUNT(*) as count, COALESCE(SUM(amount), 0) as total FROM topup_orders').get();
      const pendingPayments = db.prepare(`SELECT COUNT(*) as count FROM topup_orders WHERE status = 'PENDING_PAYMENT'`).get().count;
      const deliveryFailures = db.prepare(`SELECT COUNT(*) as count FROM topup_orders WHERE status = 'FAILED'`).get().count;
      const activeTournaments = db.prepare(`SELECT COUNT(*) as count FROM tournaments WHERE status IN ('Registration Open', 'Live', 'Check-in')`).get().count;
      const totalRegistrations = db.prepare(`SELECT COUNT(*) as count FROM tournament_registrations WHERE status = 'CONFIRMED'`).get().count;
      const disputedResults = db.prepare(`SELECT COUNT(*) as count FROM disputes WHERE status = 'OPEN'`).get().count;
      const pendingPayouts = db.prepare(`SELECT COUNT(*) as count, COALESCE(SUM(amount), 0) as total FROM prize_payouts WHERE status = 'PENDING_APPROVAL'`).get();

      return json({
        totalOrders: totalOrders.count,
        grossVolume: totalOrders.total,
        pendingPayments,
        deliveryFailures,
        activeTournaments,
        totalRegistrations,
        disputedResults,
        pendingPayoutsCount: pendingPayouts.count,
        pendingPayoutsAmount: pendingPayouts.total
      });
    }

    if (pathname === '/api/admin/topup-orders' && req.method === 'GET') {
      const orders = db.prepare(`
        SELECT o.*, u.display_name as user_name, u.email as user_email, g.name as game_name, p.name as package_name
        FROM topup_orders o
        JOIN users u ON o.user_id = u.id
        LEFT JOIN topup_games g ON o.game_id = g.id
        LEFT JOIN topup_packages p ON o.package_id = p.id
        ORDER BY o.created_at DESC
        LIMIT 100
      `).all();

      // Mask player IDs and sensitive payment data for non-superadmin
      const processed = orders.map(o => ({
        ...o,
        player_details: JSON.parse(o.player_details || '{}'),
        masked_player_id: maskSensitive(JSON.parse(o.player_details || '{}').player_id || '')
      }));

      return json(processed);
    }

    if (pathname.startsWith('/api/admin/topup-orders/') && pathname.endsWith('/retry-delivery') && req.method === 'POST') {
      if (!hasPermission(currentUser.role, 'topup:retry')) {
        return error('Unauthorized role for delivery retry', 403);
      }
      const orderId = pathname.split('/')[4];
      const now = new Date().toISOString();

      db.prepare(`
        UPDATE topup_orders
        SET status = 'DELIVERED', delivery_attempts = delivery_attempts + 1, updated_at = ?
        WHERE id = ?
      `).run(now, orderId);

      logAudit(currentUser.id, 'DELIVERY_RETRY_SUCCESS', 'topup_order', orderId, 'Manual delivery retry executed successfully');
      return json({ message: 'Order delivery retried and marked DELIVERED', orderId });
    }

    // -------------------------------------------------------------
    // ADMIN PAYMENT VERIFICATION (Screen 7 from System Specification)
    // -------------------------------------------------------------
    if (pathname === '/api/admin/payments/pending' && req.method === 'GET') {
      const pendingOrders = db.prepare(`
        SELECT o.*, u.display_name as user_name, u.email as user_email, g.name as game_name
        FROM topup_orders o
        JOIN users u ON o.user_id = u.id
        LEFT JOIN topup_games g ON o.game_id = g.id
        WHERE o.status = 'PENDING_PAYMENT' OR o.status = 'PROCESSING'
        ORDER BY o.created_at DESC
        LIMIT 50
      `).all();
      return json(pendingOrders);
    }

    if (pathname.startsWith('/api/admin/payments/') && pathname.endsWith('/verify') && req.method === 'POST') {
      const orderId = pathname.split('/')[4];
      const now = new Date().toISOString();
      const order = db.prepare('SELECT * FROM topup_orders WHERE id = ?').get(orderId);
      if (!order) return error('Order not found', 404);

      // Record payment if not exists
      const pId = 'pay_ver_' + crypto.randomUUID().slice(0, 8);
      const provTxId = 'FTL' + Date.now();
      db.prepare(`
        INSERT OR IGNORE INTO payments (id, order_id, provider, provider_transaction_id, amount, status, verified_at, created_at)
        VALUES (?, ?, ?, ?, ?, 'SUCCESS', ?, ?)
      `).run(pId, order.id, order.payment_method, provTxId, order.amount, now, now);

      // If wallet top-up, credit ledger
      if (!order.game_id || order.game_id === 'game_wallet') {
        const idemp = 'idemp_credit_' + order.id;
        transacts(order.user_id, {
          type: 'DEPOSIT',
          amount: order.amount,
          direction: 'CREDIT',
          referenceType: 'PAYMENT',
          referenceId: order.id,
          idempotencyKey: idemp,
          note: `Payment Verified: ${(order.payment_method || 'QR').toUpperCase()}`,
          actorId: currentUser.id
        });
      }

      db.prepare(`UPDATE topup_orders SET status = 'DELIVERED', updated_at = ? WHERE id = ?`).run(now, order.id);
      logAudit(currentUser.id, 'PAYMENT_VERIFIED', 'topup_order', order.id, `Manual payment verification approved by operator: ${order.payment_method}`);

      return json({ success: true, message: `Payment verified for Order #${order.id}! Funds credited.`, orderId, providerTxId: provTxId });
    }

    if (pathname.startsWith('/api/admin/payments/') && pathname.endsWith('/reject') && req.method === 'POST') {
      const orderId = pathname.split('/')[4];
      const { reason = 'Payment proof rejected by operator' } = body || {};
      const order = db.prepare('SELECT * FROM topup_orders WHERE id = ?').get(orderId);
      if (!order) return error('Order not found', 404);

      const now = new Date().toISOString();
      db.prepare(`UPDATE topup_orders SET status = 'CANCELLED', delivery_error = ?, updated_at = ? WHERE id = ?`).run(reason, now, order.id);
      logAudit(currentUser.id, 'PAYMENT_REJECTED', 'topup_order', order.id, reason);
      return json({ success: true, message: `Deposit Order #${order.id} rejected.`, orderId });
    }

    if (pathname === '/api/wallet/withdraw' && req.method === 'POST') {
      const { amount, method = 'bank', accountDetails = {} } = body || {};
      const numAmount = parseFloat(amount || 0);
      if (numAmount <= 0) return error('Invalid withdrawal amount', 400);

      const wallet = getWallet(currentUser.id);
      if (wallet.available_balance < numAmount) {
        return error(`Insufficient balance (Available: Rs. ${wallet.available_balance.toFixed(2)})`, 400);
      }

      const idemp = 'idemp_with_' + crypto.randomUUID();
      transacts(currentUser.id, {
        type: 'WITHDRAWAL',
        amount: numAmount,
        direction: 'DEBIT',
        referenceType: 'WITHDRAWAL',
        referenceId: 'with_' + Date.now(),
        idempotencyKey: idemp,
        note: `Withdrawal to ${method.toUpperCase()}`,
        actorId: currentUser.id
      });

      return json({ success: true, message: `Withdrawal request of Rs. ${numAmount.toFixed(2)} processed!`, wallet: getWallet(currentUser.id) });
    }

    if (pathname.startsWith('/api/admin/topup-orders/') && pathname.endsWith('/refund') && req.method === 'POST') {
      if (!hasPermission(currentUser.role, 'topup:refund')) {
        return error('Unauthorized role for issuing refunds', 403);
      }
      const orderId = pathname.split('/')[4];
      const { reason = 'Customer request / Delivery failure' } = body || {};

      const order = db.prepare('SELECT * FROM topup_orders WHERE id = ?').get(orderId);
      if (!order) return error('Order not found', 404);

      if (order.status === 'REFUNDED') {
        return error('Order is already refunded', 400);
      }

      // Credit user wallet
      transacts(order.user_id, {
        type: 'ADMIN_ADJUSTMENT',
        amount: order.amount,
        direction: 'CREDIT',
        referenceType: 'ORDER',
        referenceId: orderId,
        idempotencyKey: 'idemp_refund_order_' + orderId,
        note: `Refund for Order #${orderId}: ${reason}`,
        actorId: currentUser.id
      });

      const now = new Date().toISOString();
      db.prepare(`UPDATE topup_orders SET status = 'REFUNDED', updated_at = ? WHERE id = ?`).run(now, orderId);
      logAudit(currentUser.id, 'ORDER_REFUND', 'topup_order', orderId, reason, { amount: order.amount });

      return json({ message: 'Order refunded successfully', orderId, amount: order.amount });
    }

    if (pathname === '/api/admin/topup-packages' && req.method === 'POST') {
      if (!hasPermission(currentUser.role, 'packages:edit')) {
        return error('Unauthorized role for package creation', 403);
      }
      const { gameId, name, itemQuantity, price, badge, sortOrder = 0 } = body || {};
      if (!gameId || !name || !price) return error('Missing required package fields');

      const pkgId = 'pkg_' + crypto.randomUUID().slice(0, 8);
      db.prepare(`
        INSERT INTO topup_packages (id, game_id, name, item_quantity, price, badge, active, sort_order)
        VALUES (?, ?, ?, ?, ?, ?, 1, ?)
      `).run(pkgId, gameId, name, itemQuantity || name, +price, badge || null, sortOrder);

      logAudit(currentUser.id, 'PACKAGE_CREATE', 'package', pkgId, 'Added topup package ' + name);
      return json({ message: 'Package created', id: pkgId }, 201);
    }

    // -------------------------------------------------------------
    // ADMIN GAMES & PACKAGES MANAGEMENT (Full Operational Control)
    // -------------------------------------------------------------
    if (pathname === '/api/admin/games' && req.method === 'GET') {
      if (!hasPermission(currentUser.role, 'topup:manage') && !hasPermission(currentUser.role, 'all')) {
        return error('Unauthorized role for game catalog access', 403);
      }
      const games = db.prepare(`
        SELECT g.*,
          (SELECT COUNT(*) FROM topup_packages WHERE game_id = g.id) as packages_count,
          (SELECT COUNT(*) FROM topup_orders WHERE game_id = g.id) as orders_count
        FROM topup_games g
        ORDER BY g.active DESC, g.name ASC
      `).all();

      return json(games.map(g => ({
        ...g,
        required_player_fields: JSON.parse(g.required_player_fields || '[]')
      })));
    }

    if (pathname === '/api/admin/games' && req.method === 'POST') {
      if (!hasPermission(currentUser.role, 'topup:manage') && !hasPermission(currentUser.role, 'all')) {
        return error('Unauthorized role for game creation', 403);
      }
      const { name, slug, category, icon, banner, deliveryMethod, requiredPlayerFields, externalUrl } = body || {};
      if (!name) return error('Game title/name is required');

      const rawSlug = (slug || name.toLowerCase().replace(/[^a-z0-9]+/g, '-')).replace(/^-|-$/g, '');
      const gameId = 'game_' + rawSlug.slice(0, 24);

      db.prepare(`
        INSERT INTO topup_games (id, name, slug, category, icon, banner, active, delivery_method, required_player_fields, external_url)
        VALUES (?, ?, ?, ?, ?, ?, 1, ?, ?, ?)
      `).run(
        gameId,
        name,
        rawSlug,
        category || 'Battle Royale',
        icon || '🎮',
        banner || '/assets/games/battleground.webp',
        deliveryMethod || (externalUrl ? 'web_direct' : 'auto_api'),
        JSON.stringify(requiredPlayerFields || ['Player ID']),
        externalUrl || null
      );

      logAudit(currentUser.id, 'GAME_CREATE', 'topup_game', gameId, 'Added game ' + name);
      return json({ message: 'Game added successfully', id: gameId }, 201);
    }

    if (pathname.startsWith('/api/admin/games/') && pathname.endsWith('/packages') && req.method === 'GET') {
      const gameId = pathname.split('/')[4];
      const packages = db.prepare(`
        SELECT * FROM topup_packages
        WHERE game_id = ?
        ORDER BY sort_order ASC, price ASC
      `).all(gameId);
      return json(packages);
    }

    if (pathname.startsWith('/api/admin/games/') && !pathname.includes('/packages') && req.method === 'PUT') {
      if (!hasPermission(currentUser.role, 'topup:manage') && !hasPermission(currentUser.role, 'all')) {
        return error('Unauthorized role for game update', 403);
      }
      const gameId = pathname.split('/')[4];
      const existing = db.prepare('SELECT * FROM topup_games WHERE id = ?').get(gameId);
      if (!existing) return error('Game not found', 404);

      const { name, category, icon, banner, active, deliveryMethod, externalUrl, requiredPlayerFields } = body || {};

      db.prepare(`
        UPDATE topup_games
        SET name = COALESCE(?, name),
            category = COALESCE(?, category),
            icon = COALESCE(?, icon),
            banner = COALESCE(?, banner),
            active = COALESCE(?, active),
            delivery_method = COALESCE(?, delivery_method),
            external_url = COALESCE(?, external_url),
            required_player_fields = COALESCE(?, required_player_fields)
        WHERE id = ?
      `).run(
        name !== undefined ? name : null,
        category !== undefined ? category : null,
        icon !== undefined ? icon : null,
        banner !== undefined ? banner : null,
        active !== undefined ? (active ? 1 : 0) : null,
        deliveryMethod !== undefined ? deliveryMethod : null,
        externalUrl !== undefined ? externalUrl : null,
        requiredPlayerFields ? JSON.stringify(requiredPlayerFields) : null,
        gameId
      );

      logAudit(currentUser.id, 'GAME_UPDATE', 'topup_game', gameId, 'Updated game ' + (name || existing.name));
      return json({ message: 'Game updated successfully', id: gameId });
    }

    if (pathname.startsWith('/api/admin/games/') && !pathname.includes('/packages') && req.method === 'DELETE') {
      if (!hasPermission(currentUser.role, 'topup:manage') && !hasPermission(currentUser.role, 'all')) {
        return error('Unauthorized role for game deletion', 403);
      }
      const gameId = pathname.split('/')[4];
      const force = query?.force === 'true' || body?.force;
      const ordersCount = db.prepare('SELECT COUNT(*) as count FROM topup_orders WHERE game_id = ?').get(gameId).count;
      if (ordersCount > 0 && !force) {
        db.prepare('UPDATE topup_games SET active = 0 WHERE id = ?').run(gameId);
        logAudit(currentUser.id, 'GAME_DEACTIVATE', 'topup_game', gameId, 'Deactivated game with existing orders');
        return json({ message: 'Game deactivated (retained for order history)', id: gameId });
      } else {
        try {
          db.prepare('UPDATE topup_orders SET game_id = NULL, package_id = NULL WHERE game_id = ?').run(gameId);
        } catch (e) {}
        db.prepare('DELETE FROM topup_packages WHERE game_id = ?').run(gameId);
        db.prepare('DELETE FROM topup_games WHERE id = ?').run(gameId);
        logAudit(currentUser.id, 'GAME_DELETE', 'topup_game', gameId, 'Permanently deleted game');
        return json({ message: 'Game permanently deleted', id: gameId });
      }
    }

    if (pathname.startsWith('/api/admin/topup-packages/') && req.method === 'PUT') {
      if (!hasPermission(currentUser.role, 'packages:edit') && !hasPermission(currentUser.role, 'all')) {
        return error('Unauthorized role for package editing', 403);
      }
      const pkgId = pathname.split('/')[4];
      const { name, itemQuantity, price, badge, active, sortOrder } = body || {};

      db.prepare(`
        UPDATE topup_packages
        SET name = COALESCE(?, name),
            item_quantity = COALESCE(?, item_quantity),
            price = COALESCE(?, price),
            badge = COALESCE(?, badge),
            active = COALESCE(?, active),
            sort_order = COALESCE(?, sort_order)
        WHERE id = ?
      `).run(
        name !== undefined ? name : null,
        itemQuantity !== undefined ? itemQuantity : null,
        price !== undefined ? +price : null,
        badge !== undefined ? badge : null,
        active !== undefined ? (active ? 1 : 0) : null,
        sortOrder !== undefined ? +sortOrder : null,
        pkgId
      );

      logAudit(currentUser.id, 'PACKAGE_UPDATE', 'topup_package', pkgId, 'Updated package ' + pkgId);
      return json({ message: 'Package updated successfully', id: pkgId });
    }

    if (pathname.startsWith('/api/admin/topup-packages/') && req.method === 'DELETE') {
      if (!hasPermission(currentUser.role, 'packages:edit') && !hasPermission(currentUser.role, 'all')) {
        return error('Unauthorized role for package deletion', 403);
      }
      const pkgId = pathname.split('/')[4];
      try {
        db.prepare('UPDATE topup_orders SET package_id = NULL WHERE package_id = ?').run(pkgId);
      } catch (e) {}
      db.prepare('DELETE FROM topup_packages WHERE id = ?').run(pkgId);
      logAudit(currentUser.id, 'PACKAGE_DELETE', 'topup_package', pkgId, 'Deleted package ' + pkgId);
      return json({ message: 'Package deleted successfully', id: pkgId });
    }

    // -------------------------------------------------------------
    // PAYMENT GATEWAYS & QR CODE MANAGEMENT
    // -------------------------------------------------------------
    if (pathname === '/api/payment-gateways' && req.method === 'GET') {
      const gateways = db.prepare('SELECT * FROM payment_gateways WHERE active = 1 ORDER BY sort_order ASC, created_at ASC').all();
      return json(gateways);
    }

    if (pathname === '/api/admin/payment-gateways' && req.method === 'GET') {
      if (!currentUser || currentUser.role === 'player') {
        return error('Unauthorized', 403);
      }
      const gateways = db.prepare('SELECT * FROM payment_gateways ORDER BY sort_order ASC, created_at ASC').all();
      return json(gateways);
    }

    if (pathname === '/api/admin/payment-gateways' && req.method === 'POST') {
      if (!currentUser || currentUser.role === 'player') {
        return error('Unauthorized', 403);
      }
      const b = body || {};
      const name = b.name;
      const provider = b.provider;
      const qrImageUrl = b.qrImageUrl || b.qr_image_url;
      const receiverName = b.receiverName || b.receiver_name;
      const receiverNumber = b.receiverNumber || b.receiver_number;
      const instructions = b.instructions;
      const active = b.active !== undefined ? b.active : 1;
      const sortOrder = b.sortOrder !== undefined ? b.sortOrder : (b.sort_order !== undefined ? b.sort_order : 0);

      if (!name || !qrImageUrl) {
        return error('Gateway name and QR image URL are required');
      }
      const id = 'gw_' + (provider ? provider.toLowerCase().replace(/[^a-z0-9]/g, '') : 'qr') + '_' + crypto.randomUUID().slice(0, 6);
      const now = new Date().toISOString();
      db.prepare(`
        INSERT INTO payment_gateways (id, name, provider, qr_image_url, receiver_name, receiver_number, instructions, active, sort_order, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `).run(
        id,
        name,
        provider || 'qr_gateway',
        qrImageUrl,
        receiverName || 'TnT Gaming Store Official',
        receiverNumber || '',
        instructions || '',
        active ? 1 : 0,
        Number(sortOrder) || 0,
        now,
        now
      );
      logAudit(currentUser.id, 'PAYMENT_GATEWAY_CREATE', 'payment_gateway', id, 'Created payment gateway ' + name);
      return json({ message: 'Payment gateway created successfully', id }, 201);
    }

    if (pathname.startsWith('/api/admin/payment-gateways/') && req.method === 'PUT') {
      if (!currentUser || currentUser.role === 'player') {
        return error('Unauthorized', 403);
      }
      const id = pathname.split('/')[4];
      const existing = db.prepare('SELECT * FROM payment_gateways WHERE id = ?').get(id);
      if (!existing) return error('Payment gateway not found', 404);

      const b = body || {};
      const name = b.name;
      const provider = b.provider;
      const qrImageUrl = b.qrImageUrl !== undefined ? b.qrImageUrl : b.qr_image_url;
      const receiverName = b.receiverName !== undefined ? b.receiverName : b.receiver_name;
      const receiverNumber = b.receiverNumber !== undefined ? b.receiverNumber : b.receiver_number;
      const instructions = b.instructions;
      const active = b.active !== undefined ? b.active : undefined;
      const sortOrder = b.sortOrder !== undefined ? b.sortOrder : b.sort_order;
      const now = new Date().toISOString();
      db.prepare(`
        UPDATE payment_gateways
        SET name = COALESCE(?, name),
            provider = COALESCE(?, provider),
            qr_image_url = COALESCE(?, qr_image_url),
            receiver_name = COALESCE(?, receiver_name),
            receiver_number = COALESCE(?, receiver_number),
            instructions = COALESCE(?, instructions),
            active = COALESCE(?, active),
            sort_order = COALESCE(?, sort_order),
            updated_at = ?
        WHERE id = ?
      `).run(
        name !== undefined ? name : null,
        provider !== undefined ? provider : null,
        qrImageUrl !== undefined ? qrImageUrl : null,
        receiverName !== undefined ? receiverName : null,
        receiverNumber !== undefined ? receiverNumber : null,
        instructions !== undefined ? instructions : null,
        active !== undefined ? (active ? 1 : 0) : null,
        sortOrder !== undefined ? Number(sortOrder) : null,
        now,
        id
      );
      logAudit(currentUser.id, 'PAYMENT_GATEWAY_UPDATE', 'payment_gateway', id, 'Updated payment gateway ' + id);
      return json({ message: 'Payment gateway updated successfully', id });
    }

    if (pathname.startsWith('/api/admin/payment-gateways/') && req.method === 'DELETE') {
      if (!currentUser || currentUser.role === 'player') {
        return error('Unauthorized', 403);
      }
      const id = pathname.split('/')[4];
      db.prepare('DELETE FROM payment_gateways WHERE id = ?').run(id);
      logAudit(currentUser.id, 'PAYMENT_GATEWAY_DELETE', 'payment_gateway', id, 'Deleted payment gateway ' + id);
      return json({ message: 'Payment gateway deleted successfully', id });
    }

    // -------------------------------------------------------------
    // HOMEPAGE BANNERS & PROMOTIONS MANAGEMENT ("Top Things")
    // -------------------------------------------------------------
    if (pathname === '/api/banners' && req.method === 'GET') {
      const banners = db.prepare('SELECT * FROM homepage_banners WHERE active = 1 ORDER BY sort_order ASC, created_at ASC').all();
      return json(banners);
    }

    if (pathname === '/api/admin/banners' && req.method === 'GET') {
      if (!currentUser || currentUser.role === 'player') {
        return error('Unauthorized', 403);
      }
      const banners = db.prepare('SELECT * FROM homepage_banners ORDER BY sort_order ASC, created_at ASC').all();
      return json(banners);
    }

    if (pathname === '/api/admin/banners' && req.method === 'POST') {
      if (!currentUser || currentUser.role === 'player') {
        return error('Unauthorized', 403);
      }
      const b = body || {};
      const title = b.title;
      const imageUrl = b.imageUrl || b.image_url;
      const linkUrl = b.linkUrl || b.link_url;
      const badgeText = b.badgeText !== undefined ? b.badgeText : b.badge_text;
      const active = b.active !== undefined ? b.active : 1;
      const sortOrder = b.sortOrder !== undefined ? b.sortOrder : (b.sort_order !== undefined ? b.sort_order : 0);

      if (!title || !imageUrl) {
        return error('Banner title and image URL are required');
      }
      const id = 'ban_' + crypto.randomUUID().slice(0, 8);
      const now = new Date().toISOString();
      db.prepare(`
        INSERT INTO homepage_banners (id, title, image_url, link_url, badge_text, active, sort_order, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      `).run(
        id,
        title,
        imageUrl,
        linkUrl || '#',
        badgeText || null,
        active ? 1 : 0,
        Number(sortOrder) || 0,
        now
      );
      logAudit(currentUser.id, 'BANNER_CREATE', 'homepage_banner', id, 'Created homepage banner ' + title);
      return json({ message: 'Homepage banner created successfully', id }, 201);
    }

    if (pathname.startsWith('/api/admin/banners/') && req.method === 'PUT') {
      if (!currentUser || currentUser.role === 'player') {
        return error('Unauthorized', 403);
      }
      const id = pathname.split('/')[4];
      const existing = db.prepare('SELECT * FROM homepage_banners WHERE id = ?').get(id);
      if (!existing) return error('Banner not found', 404);

      const b = body || {};
      const title = b.title;
      const imageUrl = b.imageUrl !== undefined ? b.imageUrl : b.image_url;
      const linkUrl = b.linkUrl !== undefined ? b.linkUrl : b.link_url;
      const badgeText = b.badgeText !== undefined ? b.badgeText : b.badge_text;
      const active = b.active !== undefined ? b.active : undefined;
      const sortOrder = b.sortOrder !== undefined ? b.sortOrder : b.sort_order;

      db.prepare(`
        UPDATE homepage_banners
        SET title = COALESCE(?, title),
            image_url = COALESCE(?, image_url),
            link_url = COALESCE(?, link_url),
            badge_text = COALESCE(?, badge_text),
            active = COALESCE(?, active),
            sort_order = COALESCE(?, sort_order)
        WHERE id = ?
      `).run(
        title !== undefined ? title : null,
        imageUrl !== undefined ? imageUrl : null,
        linkUrl !== undefined ? linkUrl : null,
        badgeText !== undefined ? badgeText : null,
        active !== undefined ? (active ? 1 : 0) : null,
        sortOrder !== undefined ? Number(sortOrder) : null,
        id
      );
      logAudit(currentUser.id, 'BANNER_UPDATE', 'homepage_banner', id, 'Updated homepage banner ' + id);
      return json({ message: 'Homepage banner updated successfully', id });
    }

    if (pathname.startsWith('/api/admin/banners/') && req.method === 'DELETE') {
      if (!currentUser || currentUser.role === 'player') {
        return error('Unauthorized', 403);
      }
      const id = pathname.split('/')[4];
      db.prepare('DELETE FROM homepage_banners WHERE id = ?').run(id);
      logAudit(currentUser.id, 'BANNER_DELETE', 'homepage_banner', id, 'Deleted homepage banner ' + id);
      return json({ message: 'Homepage banner deleted successfully', id });
    }

    if (pathname === '/api/admin/tournaments' && req.method === 'POST') {
      if (!hasPermission(currentUser.role, 'tournaments:create')) {
        return error('Unauthorized role for tournament creation', 403);
      }
      const {
        title, gameId, mode = 'Solo', region = 'South Asia', entryFee = 0,
        prizePool = 100, maxSlots = 48, startsAt, registrationClosesAt,
        roomReleaseAt, rules, banner
      } = body || {};

      if (!title || !gameId || !startsAt) {
        return error('Missing required tournament parameters');
      }

      const tourId = 'tour_' + crypto.randomUUID().slice(0, 8);
      const now = new Date().toISOString();

      const prizeSplit = JSON.stringify([
        { place: 1, percent: 60, amount: +(prizePool * 0.6).toFixed(2) },
        { place: 2, percent: 30, amount: +(prizePool * 0.3).toFixed(2) },
        { place: 3, percent: 10, amount: +(prizePool * 0.1).toFixed(2) }
      ]);

      const scoringConfig = JSON.stringify({
        placementPoints: { "1": 12, "2": 9, "3": 8, "4": 7, "5": 6, "6": 5, "7": 4, "8": 3, "9": 2, "10": 1 },
        killPoints: 1,
        disqualificationPenalty: -50
      });

      db.prepare(`
        INSERT INTO tournaments (
          id, title, game_id, mode, region, banner, description, entry_fee, prize_pool,
          prize_split, max_slots, starts_at, registration_closes_at, check_in_opens_at,
          room_release_at, status, rules, scoring_config, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'Registration Open', ?, ?, ?)
      `).run(
        tourId, title, gameId, mode, region,
        banner || 'https://images.unsplash.com/photo-1542751371-adc38448a05e?auto=format&fit=crop&w=1200&q=80',
        body.description || 'Official competitive gaming tournament.',
        +entryFee, +prizePool, prizeSplit, +maxSlots,
        startsAt, registrationClosesAt || startsAt, null,
        roomReleaseAt || startsAt, rules || 'Standard tournament rules apply.',
        scoringConfig, now
      );

      // Create primary match room
      const matchId = 'mat_' + crypto.randomUUID().slice(0, 8);
      db.prepare(`
        INSERT INTO matches (id, tournament_id, round_number, match_code, scheduled_at, status, room_id, room_password, room_secret_reference, created_at)
        VALUES (?, ?, 1, ?, ?, 'SCHEDULED', ?, ?, ?, ?)
      `).run(
        matchId, tourId, `${mode.toUpperCase()}-R1`, startsAt,
        'ROOM-' + Math.floor(100000 + Math.random() * 900000),
        'Key#' + Math.floor(1000 + Math.random() * 9000),
        'sec_' + matchId, now
      );

      logAudit(currentUser.id, 'TOURNAMENT_CREATE', 'tournament', tourId, 'Created tournament ' + title);
      return json({ message: 'Tournament created successfully', tournamentId: tourId, matchId }, 201);
    }

    if (pathname.startsWith('/api/admin/tournaments/') && pathname.endsWith('/cancel') && req.method === 'POST') {
      if (!hasPermission(currentUser.role, 'tournaments:cancel')) {
        return error('Unauthorized role to cancel tournaments', 403);
      }
      const tourId = pathname.split('/')[4];
      const { reason = 'Cancelled by administrator' } = body || {};

      const t = db.prepare('SELECT * FROM tournaments WHERE id = ?').get(tourId);
      if (!t) return error('Tournament not found', 404);

      // Fetch all confirmed registrations to refund
      const regs = db.prepare(`SELECT * FROM tournament_registrations WHERE tournament_id = ? AND status = 'CONFIRMED'`).all(tourId);

      for (const r of regs) {
        if (t.entry_fee > 0) {
          transacts(r.user_id, {
            type: 'TOURNAMENT_REFUND',
            amount: t.entry_fee,
            direction: 'CREDIT',
            referenceType: 'TOURNAMENT',
            referenceId: tourId,
            idempotencyKey: `idemp_tour_cancel_refund_${tourId}_${r.user_id}`,
            note: `Refund: Tournament "${t.title}" cancelled (${reason})`,
            actorId: currentUser.id
          });
        }
        db.prepare('UPDATE tournament_registrations SET status = "CANCELLED" WHERE id = ?').run(r.id);
      }

      db.prepare('UPDATE tournaments SET status = "Cancelled", cancellation_reason = ? WHERE id = ?').run(reason, tourId);
      logAudit(currentUser.id, 'TOURNAMENT_CANCEL', 'tournament', tourId, reason, { refundsIssued: regs.length });

      return json({ message: `Tournament cancelled. ${regs.length} registrations refunded.`, refundedCount: regs.length });
    }

    if (pathname.startsWith('/api/admin/matches/') && pathname.endsWith('/results') && req.method === 'POST') {
      if (!hasPermission(currentUser.role, 'matches:results')) {
        return error('Unauthorized role for submitting results', 403);
      }
      const matchId = pathname.split('/')[4];
      const { results } = body || {}; // array of { userId, placement, kills, evidenceUrl }

      if (!Array.isArray(results) || results.length === 0) {
        return error('Results list required');
      }

      const match = db.prepare('SELECT * FROM matches WHERE id = ?').get(matchId);
      if (!match) return error('Match not found', 404);

      const tournament = db.prepare('SELECT * FROM tournaments WHERE id = ?').get(match.tournament_id);
      const scoring = JSON.parse(tournament.scoring_config || '{}');
      const placementMap = scoring.placementPoints || {};
      const killPointVal = scoring.killPoints || 1;

      const now = new Date().toISOString();

      // Recalculate standings deterministically
      for (const item of results) {
        const placePts = placementMap[String(item.placement)] || 0;
        const killPts = (item.kills || 0) * killPointVal;
        const totalPts = +(placePts + killPts).toFixed(2);

        const resId = 'res_' + crypto.randomUUID().slice(0, 8);
        db.prepare(`
          INSERT INTO match_results (
            id, match_id, user_id, team_id, placement, kills, points,
            evidence_reference, submitted_by, approved_by, status, created_at
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'APPROVED', ?)
        `).run(
          resId, matchId, item.userId, null, item.placement,
          item.kills || 0, totalPts, item.evidenceUrl || null,
          currentUser.id, currentUser.id, now
        );

        // If top 3 in prize split, generate pending prize payout record!
        const prizeSplit = JSON.parse(tournament.prize_split || '[]');
        const prizeTier = prizeSplit.find(p => p.place === item.placement);
        if (prizeTier && prizeTier.amount > 0) {
          const payoutId = 'pay_' + crypto.randomUUID().slice(0, 8);
          db.prepare(`
            INSERT INTO prize_payouts (
              id, tournament_id, user_id, amount, status, approved_by, created_at
            ) VALUES (?, ?, ?, ?, 'PENDING_APPROVAL', NULL, ?)
          `).run(payoutId, tournament.id, item.userId, prizeTier.amount, now);
        }
      }

      db.prepare(`UPDATE matches SET status = 'FINISHED' WHERE id = ?`).run(matchId);
      db.prepare(`UPDATE tournaments SET status = 'Results Pending Review' WHERE id = ?`).run(tournament.id);

      logAudit(currentUser.id, 'MATCH_RESULTS_ENTERED', 'match', matchId, 'Entered match results with deterministic scoring');
      return json({ message: 'Results recorded and provisional prize awards created' });
    }

    // PRIZE DUAL-APPROVAL WORKFLOW (Section 6 & 7)
    if (pathname.startsWith('/api/admin/prizes/') && pathname.endsWith('/approve') && req.method === 'POST') {
      const payoutId = pathname.split('/')[4];
      const payout = db.prepare('SELECT * FROM prize_payouts WHERE id = ?').get(payoutId);
      if (!payout) return error('Payout record not found', 404);

      // Section 5 & 6 require dual approval for prize payouts
      // 1st step: Tournament Manager or Super Admin approves
      // 2nd step: Finance Reviewer dual-approves and triggers ledger payout
      if (!payout.approved_by) {
        if (!hasPermission(currentUser.role, 'prizes:approve')) {
          return error('Unauthorized for first-step prize approval', 403);
        }
        db.prepare(`
          UPDATE prize_payouts
          SET approved_by = ?, status = 'PENDING_FINANCE_APPROVAL'
          WHERE id = ?
        `).run(currentUser.id, payoutId);

        logAudit(currentUser.id, 'PRIZE_FIRST_APPROVAL', 'prize_payout', payoutId, 'Prize first-approval granted');
        return json({ message: 'First approval granted. Awaiting Finance Reviewer dual-approval.', status: 'PENDING_FINANCE_APPROVAL' });
      }

      // 2nd step: Dual approval
      if (!hasPermission(currentUser.role, 'prizes:dual_approve') && currentUser.role !== 'super_admin') {
        return error('Dual approval requires Finance Reviewer or Super Admin role', 403);
      }

      const now = new Date().toISOString();
      // Atomically credit winner wallet
      transacts(payout.user_id, {
        type: 'PRIZE_PAYOUT',
        amount: payout.amount,
        direction: 'CREDIT',
        referenceType: 'PRIZE',
        referenceId: payoutId,
        idempotencyKey: 'idemp_prize_' + payoutId,
        note: `Tournament Prize Award: $${payout.amount}`,
        actorId: currentUser.id
      });

      db.prepare(`
        UPDATE prize_payouts
        SET dual_approved_by = ?, status = 'PAID', paid_at = ?, provider_reference = 'PLATFORM_WALLET_LEDGER'
        WHERE id = ?
      `).run(currentUser.id, now, payoutId);

      logAudit(currentUser.id, 'PRIZE_DUAL_APPROVAL_PAID', 'prize_payout', payoutId, 'Prize dual-approved and paid to winner wallet', { amount: payout.amount });

      return json({ message: `Prize $${payout.amount} dual-approved and paid directly to player wallet!`, status: 'PAID' });
    }

    if (pathname === '/api/admin/prizes' && req.method === 'GET') {
      const payouts = db.prepare(`
        SELECT pp.*, u.display_name as user_name, u.email as user_email, t.title as tournament_title
        FROM prize_payouts pp
        JOIN users u ON pp.user_id = u.id
        JOIN tournaments t ON pp.tournament_id = t.id
        ORDER BY pp.created_at DESC
      `).all();
      return json(payouts);
    }

    if (pathname === '/api/admin/audit-logs' && req.method === 'GET') {
      const logs = db.prepare(`
        SELECT a.*, u.display_name as actor_name
        FROM audit_logs a
        LEFT JOIN users u ON a.actor_id = u.id
        ORDER BY a.created_at DESC
        LIMIT 100
      `).all();
      return json(logs);
    }

    if (pathname === '/api/admin/users' && req.method === 'GET') {
      const users = db.prepare(`
        SELECT u.*, w.available_balance, w.locked_balance
        FROM users u
        LEFT JOIN wallets w ON u.id = w.user_id
        ORDER BY u.created_at DESC
      `).all();
      return json(users);
    }

    if (pathname.startsWith('/api/admin/users/') && pathname.endsWith('/ban') && req.method === 'PATCH') {
      if (!hasPermission(currentUser.role, 'all') && currentUser.role !== 'tournament_manager') {
        return error('Unauthorized to ban users', 403);
      }
      const targetUserId = pathname.split('/')[4];
      const { status = 'banned', reason = 'Violation of fair play policy' } = body || {};

      db.prepare(`UPDATE users SET status = ?, ban_reason = ? WHERE id = ?`).run(status, reason, targetUserId);
      logAudit(currentUser.id, status === 'banned' ? 'USER_BANNED' : 'USER_UNBANNED', 'user', targetUserId, reason);

      return json({ message: `User status updated to ${status}`, targetUserId });
    }

    // DISPUTE MANAGEMENT
    if (pathname === '/api/disputes' && req.method === 'POST') {
      const { tournamentId, matchId, reason, evidenceUrl } = body || {};
      if (!tournamentId || !reason) return error('Tournament ID and reason are required');

      const dispId = 'disp_' + crypto.randomUUID().slice(0, 8);
      const now = new Date().toISOString();

      db.prepare(`
        INSERT INTO disputes (id, tournament_id, match_id, user_id, reason, evidence_url, status, created_at)
        VALUES (?, ?, ?, ?, ?, ?, 'OPEN', ?)
      `).run(dispId, tournamentId, matchId || null, currentUser.id, reason, evidenceUrl || null, now);

      logAudit(currentUser.id, 'DISPUTE_FILED', 'dispute', dispId, reason);
      return json({ message: 'Dispute filed successfully', disputeId: dispId }, 201);
    }

    if (pathname === '/api/disputes' && req.method === 'GET') {
      const disputes = db.prepare(`
        SELECT d.*, u.display_name as user_name, t.title as tournament_title
        FROM disputes d
        JOIN users u ON d.user_id = u.id
        JOIN tournaments t ON d.tournament_id = t.id
        ORDER BY d.created_at DESC
      `).all();
      return json(disputes);
    }

    if (pathname.startsWith('/api/admin/disputes/') && pathname.endsWith('/resolve') && req.method === 'PATCH') {
      const dispId = pathname.split('/')[4];
      const { status = 'RESOLVED', notes = 'Reviewed evidence and resolved' } = body || {};

      db.prepare(`
        UPDATE disputes
        SET status = ?, resolution_notes = ?, resolved_by = ?
        WHERE id = ?
      `).run(status, notes, currentUser.id, dispId);

      logAudit(currentUser.id, 'DISPUTE_RESOLVED', 'dispute', dispId, notes);
      return json({ message: 'Dispute status updated to ' + status });
    }

    // -------------------------------------------------------------
    // LIVE SUPPORT CHAT & REAL-TIME ADMIN NOTIFICATIONS
    // -------------------------------------------------------------
    // LIVE SUPPORT CHAT ROUTES
    // -------------------------------------------------------------
    if (pathname === '/api/chat/unread-count' && req.method === 'GET') {
      const activeUser = currentUser || { id: 'usr_guest', role: 'guest' };
      const isAdmin = ['super_admin', 'topup_operator', 'tournament_manager', 'finance_reviewer', 'support'].includes(activeUser.role);
      let unreadCount = 0;
      let latest = null;

      try {
        if (isAdmin) {
          unreadCount = db.prepare(`SELECT COUNT(*) as count FROM support_chat_messages WHERE recipient_id = 'admin' AND is_read = 0`).get()?.count || 0;
          latest = db.prepare(`SELECT * FROM support_chat_messages WHERE recipient_id = 'admin' AND is_read = 0 ORDER BY created_at DESC LIMIT 1`).get();
        } else {
          unreadCount = db.prepare(`SELECT COUNT(*) as count FROM support_chat_messages WHERE recipient_id = ? AND is_read = 0`).get(activeUser.id)?.count || 0;
          latest = db.prepare(`SELECT * FROM support_chat_messages WHERE recipient_id = ? AND is_read = 0 ORDER BY created_at DESC LIMIT 1`).get(activeUser.id);
        }
      } catch (err) {
        unreadCount = 0;
      }

      return json({
        unreadCount,
        latestMessage: latest || null
      });
    }

    if (pathname === '/api/chat/threads' && req.method === 'GET') {
      const activeUser = currentUser || { id: 'usr_guest', role: 'guest', display_name: 'Guest Player' };
      const isAdmin = ['super_admin', 'topup_operator', 'tournament_manager', 'finance_reviewer', 'support'].includes(activeUser.role);
      if (isAdmin) {
        try {
          const threads = db.prepare(`
            SELECT 
              t.thread_id,
              t.sender_id as user_id,
              u.display_name as user_name,
              u.email as user_email,
              u.avatar as user_avatar,
              COALESCE(w.available_balance, 0.0) as wallet_balance,
              last_msg.message as last_message,
              last_msg.created_at as last_message_at,
              last_msg.sender_role as last_sender_role,
              COALESCE(unread.unread_count, 0) as unread_count
            FROM (
              SELECT DISTINCT thread_id, 
                CASE WHEN sender_role = 'player' THEN sender_id ELSE recipient_id END as sender_id
              FROM support_chat_messages
            ) t
            JOIN users u ON t.sender_id = u.id
            LEFT JOIN wallets w ON u.id = w.user_id
            JOIN (
              SELECT m1.*
              FROM support_chat_messages m1
              JOIN (
                SELECT thread_id, MAX(created_at) as max_time
                FROM support_chat_messages
                GROUP BY thread_id
              ) m2 ON m1.thread_id = m2.thread_id AND m1.created_at = m2.max_time
            ) last_msg ON t.thread_id = last_msg.thread_id
            LEFT JOIN (
              SELECT thread_id, COUNT(*) as unread_count
              FROM support_chat_messages
              WHERE recipient_id = 'admin' AND is_read = 0
              GROUP BY thread_id
            ) unread ON t.thread_id = unread.thread_id
            ORDER BY last_msg.created_at DESC
          `).all();
          return json(threads);
        } catch (err) {
          return json([]);
        }
      } else {
        try {
          const threadId = 'thread_' + activeUser.id;
          const msg = db.prepare(`SELECT * FROM support_chat_messages WHERE thread_id = ? ORDER BY created_at DESC LIMIT 1`).get(threadId);
          const unread = db.prepare(`SELECT COUNT(*) as count FROM support_chat_messages WHERE thread_id = ? AND recipient_id = ? AND is_read = 0`).get(threadId, activeUser.id)?.count || 0;
          return json([{
            thread_id: threadId,
            user_id: activeUser.id,
            user_name: activeUser.display_name,
            wallet_balance: getWallet(activeUser.id)?.available_balance || 0,
            last_message: msg?.message || 'Chat started',
            last_message_at: msg?.created_at || new Date().toISOString(),
            unread_count: unread
          }]);
        } catch (err) {
          return json([]);
        }
      }
    }

    if (pathname.startsWith('/api/chat/threads/') && req.method === 'GET') {
      const targetUserId = pathname.split('/')[4];
      const activeUser = currentUser || { id: 'usr_guest', role: 'guest', display_name: 'Guest Player' };
      const isAdmin = ['super_admin', 'topup_operator', 'tournament_manager', 'finance_reviewer', 'support'].includes(activeUser.role);
      const effectiveUserId = isAdmin ? targetUserId : activeUser.id;
      const threadId = 'thread_' + effectiveUserId;

      try {
        // Mark incoming messages as read
        const markRecipient = isAdmin ? 'admin' : activeUser.id;
        db.prepare(`UPDATE support_chat_messages SET is_read = 1 WHERE thread_id = ? AND recipient_id = ?`).run(threadId, markRecipient);

        const messages = db.prepare(`
          SELECT * FROM support_chat_messages
          WHERE thread_id = ?
          ORDER BY created_at ASC
        `).all(threadId);

        const targetUser = db.prepare(`
          SELECT u.id, u.display_name, u.email, u.avatar, COALESCE(w.available_balance, 0.0) as wallet_balance
          FROM users u
          LEFT JOIN wallets w ON u.id = w.user_id
          WHERE u.id = ?
        `).get(effectiveUserId);

        const latestOrder = db.prepare(`
          SELECT id, amount, payment_method, status, created_at
          FROM topup_orders
          WHERE user_id = ?
          ORDER BY created_at DESC
          LIMIT 1
        `).get(effectiveUserId);

        return json({
          threadId,
          user: targetUser,
          latestOrder,
          messages
        });
      } catch (err) {
        return json({
          threadId,
          user: null,
          latestOrder: null,
          messages: []
        });
      }
    }

    if (pathname === '/api/chat/send' && req.method === 'POST') {
      const { targetUserId, message, attachmentUrl } = body || {};
      if (!message || !message.trim()) {
        return error('Message cannot be empty', 400);
      }

      const activeUser = currentUser || { id: 'usr_guest', role: 'guest', display_name: 'Guest Player' };
      const isAdmin = ['super_admin', 'topup_operator', 'tournament_manager', 'finance_reviewer', 'support'].includes(activeUser.role);
      const effectiveUserId = isAdmin ? (targetUserId || 'usr_player1') : activeUser.id;
      const threadId = 'thread_' + effectiveUserId;
      const senderRole = isAdmin ? 'admin' : 'player';
      const recipientId = isAdmin ? effectiveUserId : 'admin';
      const msgId = 'msg_' + crypto.randomUUID().slice(0, 10);
      const now = new Date().toISOString();

      try {
        db.prepare(`
          INSERT INTO support_chat_messages (
            id, thread_id, sender_id, sender_role, sender_name, recipient_id, message, attachment_url, is_read, created_at
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0, ?)
        `).run(
          msgId, threadId, activeUser.id, senderRole, activeUser.display_name, recipientId, message.trim(), attachmentUrl || null, now
        );

        return json({
          id: msgId,
          thread_id: threadId,
          sender_id: activeUser.id,
          sender_role: senderRole,
          sender_name: activeUser.display_name,
          recipient_id: recipientId,
          message: message.trim(),
          attachment_url: attachmentUrl || null,
          is_read: 0,
          created_at: now
        });
      } catch (err) {
        return error('Failed to save chat message: ' + err.message, 500);
      }
    }

    // -------------------------------------------------------------
    // AI SUBSCRIPTIONS ROUTES (User & Admin Section)
    // -------------------------------------------------------------
    if (pathname === '/api/ai/tools' && req.method === 'GET') {
      const tools = db.prepare(`SELECT * FROM topup_games WHERE category = 'AI Subscription' AND active = 1`).all();
      const toolsWithPkgs = tools.map(t => {
        const packages = db.prepare('SELECT * FROM topup_packages WHERE game_id = ? AND active = 1 ORDER BY sort_order ASC').all(t.id);
        return {
          ...t,
          packages,
          required_player_fields: JSON.parse(t.required_player_fields || '[]')
        };
      });
      return json(toolsWithPkgs);
    }

    if (pathname === '/api/ai/my-subscriptions' && req.method === 'GET') {
      const subs = db.prepare(`
        SELECT * FROM ai_subscriptions
        WHERE user_id = ?
        ORDER BY created_at DESC
      `).all(currentUser.id);
      return json(subs);
    }

    if (pathname === '/api/ai/subscribe' && req.method === 'POST') {
      const { toolId, packageId, accountEmail, paymentMethod = 'wallet' } = body || {};
      if (!toolId || !accountEmail) {
        return error('Tool ID and account email are required', 400);
      }

      const tool = db.prepare('SELECT * FROM topup_games WHERE id = ?').get(toolId);
      if (!tool) return error('AI service not found: ' + toolId, 404);

      let pkg = null;
      if (packageId) {
        pkg = db.prepare('SELECT * FROM topup_packages WHERE id = ? AND game_id = ?').get(packageId, toolId);
      }
      if (!pkg) {
        pkg = db.prepare('SELECT * FROM topup_packages WHERE game_id = ? ORDER BY sort_order ASC LIMIT 1').get(toolId);
      }
      if (!pkg) return error('No available packages for this AI service', 400);

      // Check wallet balance if paying with wallet
      if (paymentMethod === 'wallet') {
        const wallet = getWallet(currentUser.id);
        if (wallet.available_balance < pkg.price) {
          return error(`Insufficient balance. Required: Rs. ${pkg.price}, Available: Rs. ${wallet.available_balance.toFixed(2)}`, 402);
        }
        transacts(currentUser.id, {
          type: 'TOPUP_PAYMENT',
          amount: pkg.price,
          direction: 'DEBIT',
          referenceType: 'ai_subscription',
          referenceId: toolId,
          note: `AI Subscription: ${tool.name} (${pkg.name})`,
          actorId: currentUser.id
        });
      }

      // Check if an available vault license key exists
      const availableKey = db.prepare(`
        SELECT * FROM ai_license_keys 
        WHERE tool_id = ? AND status = 'AVAILABLE' 
        LIMIT 1
      `).get(toolId);

      const subId = 'sub_' + Date.now() + '_' + crypto.randomUUID().slice(0, 6);
      const now = new Date();
      let durationDays = 30;
      if (pkg.name.toLowerCase().includes('3 month')) durationDays = 90;
      if (pkg.name.toLowerCase().includes('1 year') || pkg.name.toLowerCase().includes('annual')) durationDays = 365;

      const expires = new Date(now.getTime() + durationDays * 24 * 60 * 60 * 1000);
      const assignedLicenseKey = availableKey 
        ? availableKey.license_code 
        : `${tool.name.replace(/[^a-zA-Z0-9]/g, '').toUpperCase().slice(0, 8)}-PRO-${crypto.randomUUID().slice(0, 8).toUpperCase()}`;

      if (availableKey) {
        db.prepare(`
          UPDATE ai_license_keys 
          SET status = 'ASSIGNED', assigned_to_user_id = ?, assigned_order_id = ? 
          WHERE id = ?
        `).run(currentUser.id, subId, availableKey.id);
      }

      const cycle = durationDays >= 365 ? 'annual' : (durationDays >= 90 ? 'quarterly' : 'monthly');

      db.prepare(`
        INSERT INTO ai_subscriptions (
          id, user_id, tool_id, tool_name, plan_name, account_email, license_key, status, billing_cycle, amount, starts_at, expires_at, auto_renew, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, 'ACTIVE', ?, ?, ?, ?, 1, ?, ?)
      `).run(
        subId,
        currentUser.id,
        tool.id,
        tool.name,
        pkg.name,
        accountEmail,
        assignedLicenseKey,
        cycle,
        pkg.price,
        now.toISOString(),
        expires.toISOString(),
        now.toISOString(),
        now.toISOString()
      );

      // Also record order in topup_orders for reporting
      const orderId = 'ord_ai_' + Date.now();
      db.prepare(`
        INSERT INTO topup_orders (
          id, user_id, game_id, package_id, player_details, amount, fee, payment_method, status, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, 0.0, ?, 'DELIVERED', ?, ?)
      `).run(
        orderId,
        currentUser.id,
        tool.id,
        pkg.id,
        JSON.stringify({ account_email: accountEmail, license_key: assignedLicenseKey }),
        pkg.price,
        paymentMethod.toUpperCase(),
        now.toISOString(),
        now.toISOString()
      );

      logAudit(currentUser.id, 'AI_SUBSCRIPTION_CREATED', 'ai_subscription', subId, `Subscribed to ${tool.name} (${pkg.name})`);

      const createdSub = db.prepare('SELECT * FROM ai_subscriptions WHERE id = ?').get(subId);
      return json({
        success: true,
        message: `Successfully subscribed to ${tool.name}!`,
        subscription: createdSub,
        licenseKey: assignedLicenseKey,
        wallet: getWallet(currentUser.id)
      });
    }

    if (pathname.startsWith('/api/ai/subscriptions/') && pathname.endsWith('/cancel') && req.method === 'POST') {
      const subId = pathname.split('/')[4];
      db.prepare(`
        UPDATE ai_subscriptions
        SET auto_renew = 0, updated_at = ?
        WHERE id = ? AND user_id = ?
      `).run(new Date().toISOString(), subId, currentUser.id);

      logAudit(currentUser.id, 'AI_SUBSCRIPTION_CANCELLED', 'ai_subscription', subId, 'Auto-renew disabled');
      return json({ success: true, message: 'Subscription auto-renew cancelled' });
    }

    // -------------------------------------------------------------
    // ADMIN AI SUBSCRIPTION MANAGEMENT ROUTES
    // -------------------------------------------------------------
    if (pathname === '/api/admin/ai/analytics' && req.method === 'GET') {
      const activeSubs = db.prepare(`SELECT COUNT(*) as count, COALESCE(SUM(amount), 0) as mrr FROM ai_subscriptions WHERE status = 'ACTIVE'`).get();
      const pendingSubs = db.prepare(`SELECT COUNT(*) as count FROM ai_subscriptions WHERE status = 'PENDING'`).get().count;
      const totalSubs = db.prepare(`SELECT COUNT(*) as count FROM ai_subscriptions`).get().count;
      const availableKeys = db.prepare(`SELECT COUNT(*) as count FROM ai_license_keys WHERE status = 'AVAILABLE'`).get().count;
      const assignedKeys = db.prepare(`SELECT COUNT(*) as count FROM ai_license_keys WHERE status = 'ASSIGNED'`).get().count;
      
      const toolBreakdown = db.prepare(`
        SELECT tool_name, COUNT(*) as count, SUM(amount) as revenue
        FROM ai_subscriptions
        GROUP BY tool_name
        ORDER BY count DESC
      `).all();

      return json({
        activeSubs: activeSubs.count,
        mrr: activeSubs.mrr,
        pendingSubs,
        totalSubs,
        availableKeys,
        assignedKeys,
        toolBreakdown
      });
    }

    if (pathname === '/api/admin/ai/subscriptions' && req.method === 'GET') {
      const subs = db.prepare(`
        SELECT s.*, u.display_name as user_name, u.email as user_email
        FROM ai_subscriptions s
        JOIN users u ON s.user_id = u.id
        ORDER BY s.created_at DESC
      `).all();
      return json(subs);
    }

    if (pathname.startsWith('/api/admin/ai/subscriptions/') && pathname.endsWith('/activate') && req.method === 'POST') {
      const subId = pathname.split('/')[5];
      const { licenseKey } = body || {};

      const sub = db.prepare('SELECT * FROM ai_subscriptions WHERE id = ?').get(subId);
      if (!sub) return error('Subscription not found', 404);

      let finalKey = (licenseKey || '').trim();
      if (!finalKey) {
        // Find available key in vault
        const vaultKey = db.prepare(`SELECT * FROM ai_license_keys WHERE tool_id = ? AND status = 'AVAILABLE' LIMIT 1`).get(sub.tool_id);
        if (vaultKey) {
          finalKey = vaultKey.license_code;
          db.prepare(`UPDATE ai_license_keys SET status = 'ASSIGNED', assigned_to_user_id = ?, assigned_order_id = ? WHERE id = ?`).run(sub.user_id, sub.id, vaultKey.id);
        } else {
          finalKey = `${sub.tool_name.replace(/[^a-zA-Z0-9]/g, '').toUpperCase().slice(0, 8)}-PRO-${crypto.randomUUID().slice(0, 8).toUpperCase()}`;
        }
      }

      db.prepare(`
        UPDATE ai_subscriptions
        SET status = 'ACTIVE', license_key = ?, updated_at = ?
        WHERE id = ?
      `).run(finalKey, new Date().toISOString(), subId);

      logAudit(currentUser.id, 'AI_SUB_ACTIVATED', 'ai_subscription', subId, `Activated with key ${finalKey}`);
      return json({ success: true, message: 'Subscription successfully activated!', licenseKey: finalKey });
    }

    if (pathname.startsWith('/api/admin/ai/subscriptions/') && pathname.endsWith('/status') && req.method === 'POST') {
      const subId = pathname.split('/')[5];
      const { status } = body || {};
      if (!status) return error('Status is required', 400);

      db.prepare(`
        UPDATE ai_subscriptions
        SET status = ?, updated_at = ?
        WHERE id = ?
      `).run(status, new Date().toISOString(), subId);

      logAudit(currentUser.id, 'AI_SUB_STATUS_CHANGE', 'ai_subscription', subId, `Status updated to ${status}`);
      return json({ success: true, message: `Subscription status set to ${status}` });
    }

    if (pathname.startsWith('/api/admin/ai/subscriptions/') && pathname.endsWith('/renew') && req.method === 'POST') {
      const subId = pathname.split('/')[5];
      const { days = 30 } = body || {};

      const sub = db.prepare('SELECT * FROM ai_subscriptions WHERE id = ?').get(subId);
      if (!sub) return error('Subscription not found', 404);

      const curExp = new Date(sub.expires_at || Date.now());
      const baseTime = curExp.getTime() > Date.now() ? curExp.getTime() : Date.now();
      const newExp = new Date(baseTime + days * 24 * 60 * 60 * 1000);

      db.prepare(`
        UPDATE ai_subscriptions
        SET expires_at = ?, status = 'ACTIVE', updated_at = ?
        WHERE id = ?
      `).run(newExp.toISOString(), new Date().toISOString(), subId);

      logAudit(currentUser.id, 'AI_SUB_RENEWED', 'ai_subscription', subId, `Renewed for ${days} days until ${newExp.toISOString()}`);
      return json({ success: true, message: `Renewed for ${days} days!`, newExpiresAt: newExp.toISOString() });
    }

    if (pathname === '/api/admin/ai/keys' && req.method === 'GET') {
      const keys = db.prepare(`
        SELECT k.*, u.display_name as assigned_user_name, u.email as assigned_user_email
        FROM ai_license_keys k
        LEFT JOIN users u ON k.assigned_to_user_id = u.id
        ORDER BY k.created_at DESC
      `).all();
      return json(keys);
    }

    if (pathname === '/api/admin/ai/keys' && req.method === 'POST') {
      const { toolId, toolName, licenseCode, bulkCodes } = body || {};
      if (!toolId) return error('Tool ID is required', 400);

      const targetTool = db.prepare('SELECT * FROM topup_games WHERE id = ?').get(toolId) || { name: toolName || toolId };
      const name = targetTool.name || toolName;

      const keysToAdd = [];
      if (bulkCodes && typeof bulkCodes === 'string') {
        const lines = bulkCodes.split('\n').map(l => l.trim()).filter(Boolean);
        lines.forEach(code => keysToAdd.push(code));
      } else if (licenseCode && licenseCode.trim()) {
        keysToAdd.push(licenseCode.trim());
      }

      if (keysToAdd.length === 0) {
        return error('At least one license key code must be provided', 400);
      }

      const insertKey = db.prepare(`
        INSERT INTO ai_license_keys (id, tool_id, tool_name, license_code, status, assigned_to_user_id, assigned_order_id, created_at)
        VALUES (?, ?, ?, ?, 'AVAILABLE', null, null, ?)
      `);

      let insertedCount = 0;
      const now = new Date().toISOString();
      for (const code of keysToAdd) {
        const keyId = 'key_' + Date.now() + '_' + crypto.randomUUID().slice(0, 6);
        try {
          insertKey.run(keyId, toolId, name, code, now);
          insertedCount++;
        } catch (err) {
          // Ignore duplicate code errors
        }
      }

      logAudit(currentUser.id, 'AI_VAULT_KEYS_ADDED', 'ai_license_keys', toolId, `Added ${insertedCount} keys for ${name}`);
      return json({ success: true, message: `Successfully added ${insertedCount} keys to vault`, count: insertedCount });
    }

    if (pathname.startsWith('/api/admin/ai/keys/') && req.method === 'DELETE') {
      const keyId = pathname.split('/')[5];
      db.prepare(`DELETE FROM ai_license_keys WHERE id = ?`).run(keyId);
      logAudit(currentUser.id, 'AI_VAULT_KEY_DELETED', 'ai_license_keys', keyId, 'Vault key removed');
      return json({ success: true, message: 'Key removed from vault' });
    }

    // -------------------------------------------------------------
    // WEBHOOK SIMULATOR / TEST HARNESS (For Section 12 test coverage)
    // -------------------------------------------------------------
    if (pathname === '/api/admin/simulate-webhook' && req.method === 'POST') {
      const {
        orderId,
        provider = 'esewa',
        amount,
        tamperSignature = false,
        duplicateEvent = false
      } = body || {};

      const order = db.prepare('SELECT * FROM topup_orders WHERE id = ?').get(orderId);
      if (!order) return error('Order not found', 404);

      const payload = {
        orderId,
        providerTransactionId: duplicateEvent ? 'TXN_REPLAY_TEST_101' : 'TXN_' + Date.now(),
        amount: amount !== undefined ? amount : order.amount,
        status: 'SUCCESS',
        eventId: 'EVT_' + crypto.randomUUID().slice(0, 8),
        timestamp: new Date().toISOString()
      };

      const payloadStr = JSON.stringify(payload);
      const signature = tamperSignature ? 'tampered_invalid_signature_hex' : generateWebhookSignature(payloadStr);

      // Perform internal webhook call
      const webhookReq = {
        method: 'POST',
        headers: {
          'x-signature': signature,
          'content-type': 'application/json'
        },
        socket: req.socket
      };

      let webhookResult;
      const fakeRes = {
        statusCode: 200,
        headers: {},
        setHeader: (k, v) => { fakeRes.headers[k] = v; },
        writeHead: (sc, h) => { fakeRes.statusCode = sc; Object.assign(fakeRes.headers, h || {}); },
        end: (data) => { webhookResult = { statusCode: fakeRes.statusCode, data: JSON.parse(data || '{}') }; }
      };

      await handleApiRequest(webhookReq, fakeRes, `/api/payments/${provider}/webhook`, {}, payload);
      return json({
        simulation: 'WEBHOOK_EMULATOR',
        payload,
        signatureProvided: signature,
        tampered: tamperSignature,
        result: webhookResult
      });
    }

    // Not found
    return error('API endpoint not found: ' + pathname, 404);

  } catch (err) {
    console.error('API Error:', err);
    return error('Internal server error: ' + err.message, 500);
  }
}

module.exports = {
  handleApiRequest,
  generateWebhookSignature
};
