const assert = require('node:assert');
const { db } = require('../server/db');
const { transacts, getWallet, getTransactions } = require('../server/ledger');
const { generateWebhookSignature, verifyWebhookSignature } = require('../server/security');
const { handleApiRequest } = require('../server/router');

async function runMockRequest(method, pathname, headers = {}, body = null, query = {}) {
  const req = {
    method,
    headers: {
      'content-type': 'application/json',
      ...headers
    },
    socket: { remoteAddress: '127.0.0.1' }
  };

  let statusCode = 200;
  let resHeaders = {};
  let responseData = null;

  const res = {
    statusCode: 200,
    headers: {},
    setHeader: (k, v) => { resHeaders[k] = v; },
    writeHead: (sc, h) => { statusCode = sc; Object.assign(resHeaders, h || {}); },
    end: (data) => {
      if (data) {
        try { responseData = JSON.parse(data); } catch { responseData = data; }
      }
    }
  };

  await handleApiRequest(req, res, pathname, query, body);
  return { status: statusCode, headers: resHeaders, data: responseData };
}

function setupTestFixtures() {
  const now = new Date().toISOString();
  const testUsers = [
    { id: 'usr_player1', name: 'Phoenix_Ace', email: 'phoenix@gamer.io', role: 'player', balance: 150.0 },
    { id: 'usr_player2', name: 'ViperStrike', email: 'viper@gamer.io', role: 'player', balance: 45.0 },
    { id: 'usr_player3', name: 'ShadowNinja', email: 'ninja@gamer.io', role: 'player', balance: 8.5 },
    { id: 'usr_tmgr', name: 'Kage_Director', email: 'tournaments@platform.io', role: 'tournament_manager', balance: 500.0 },
    { id: 'usr_finance', name: 'Audit_Vault', email: 'finance@platform.io', role: 'finance_reviewer', balance: 5000.0 }
  ];

  for (const u of testUsers) {
    db.prepare(`
      INSERT OR REPLACE INTO users (id, display_name, email, phone, role, status, avatar, created_at)
      VALUES (?, ?, ?, '+977-9800000000', ?, 'active', ?, ?)
    `).run(u.id, u.name, u.email, u.role, `https://api.dicebear.com/7.x/bottts/svg?seed=${u.id}`, now);

    db.prepare(`
      INSERT OR REPLACE INTO wallets (user_id, currency, available_balance, locked_balance, updated_at)
      VALUES (?, 'USD', ?, 0.0, ?)
    `).run(u.id, u.balance, now);

    db.prepare(`
      INSERT OR REPLACE INTO wallet_ledger (id, user_id, type, amount, direction, reference_type, reference_id, idempotency_key, note, created_at)
      VALUES (?, ?, 'DEPOSIT', ?, 'CREDIT', 'INITIAL_GRANT', 'genesis', ?, 'Initial platform balance', ?)
    `).run('led_test_' + u.id, u.id, u.balance, 'idemp_test_init_' + u.id, now);
  }

  try {
    db.prepare(`
      INSERT OR IGNORE INTO tournament_registrations (id, tournament_id, user_id, team_id, status, entry_payment_ledger_id, receipt_number, registered_at)
      VALUES ('reg_usr1_mlbb_test', 'tour_live_showdown', 'usr_player1', null, 'CONFIRMED', 'led_test', 'RCPT-MLBB-TEST', ?)
    `).run(now);
  } catch (e) {}

  try {
    db.prepare(`
      INSERT OR IGNORE INTO support_chat_messages (id, thread_id, sender_id, sender_role, sender_name, recipient_id, message, attachment_url, is_read, created_at)
      VALUES ('msg_test_prior', 'thread_usr_player1', 'usr_player1', 'player', 'Phoenix_Ace', 'admin', 'Prior greeting', null, 1, ?)
    `).run(now);
  } catch (e) {}
}

function teardownTestFixtures() {
  const { cleanupDemoAccounts } = require('../server/db');
  cleanupDemoAccounts();
}

async function runTests() {
  setupTestFixtures();
  console.log('--- STARTING SECTION 12 SPECIFICATION TEST PLAN ---');
  let passed = 0;
  let failed = 0;

  async function test(name, fn) {
    try {
      await fn();
      console.log(`  ✅ PASS: ${name}`);
      passed++;
    } catch (err) {
      console.error(`  ❌ FAIL: ${name}`);
      console.error(err);
      failed++;
    }
  }

  // 1. PAYMENT & WEBHOOK TESTS
  await test('Payment Test 1: Valid webhook signature and delivery credit', async () => {
    // Create an order
    const createRes = await runMockRequest('POST', '/api/topups/orders', { 'x-auth-token': 'usr_player1' }, {
      gameId: 'game_ff',
      packageId: 'pkg_ff_100',
      playerDetails: { player_id: '123456789' },
      paymentMethod: 'esewa'
    });
    assert.strictEqual(createRes.status, 201);
    const orderId = createRes.data.order.id;
    assert.strictEqual(createRes.data.order.status, 'PENDING_PAYMENT');

    // Simulate verified webhook
    const payload = {
      orderId,
      providerTransactionId: 'ESEWA_TX_' + Date.now(),
      amount: createRes.data.order.amount,
      status: 'SUCCESS'
    };
    const sig = generateWebhookSignature(JSON.stringify(payload));
    const webhookRes = await runMockRequest('POST', '/api/payments/esewa/webhook', { 'x-signature': sig }, payload);

    assert.strictEqual(webhookRes.status, 200);
    assert.strictEqual(webhookRes.data.orderStatus, 'DELIVERED');

    // Verify order in DB
    const updatedOrder = db.prepare('SELECT status FROM topup_orders WHERE id = ?').get(orderId);
    assert.strictEqual(updatedOrder.status, 'DELIVERED');
  });

  await test('Payment Test 2: Invalid signature rejection', async () => {
    const payload = {
      orderId: 'ord_sample_proc',
      providerTransactionId: 'TXN_FAKE_123',
      amount: 4.89,
      status: 'SUCCESS'
    };
    const webhookRes = await runMockRequest('POST', '/api/payments/esewa/webhook', { 'x-signature': 'bad_signature_hex' }, payload);
    assert.strictEqual(webhookRes.status, 401);
  });

  await test('Payment Test 3: Amount mismatch rejection', async () => {
    // Create order for $0.99
    const createRes = await runMockRequest('POST', '/api/topups/orders', {}, {
      gameId: 'game_ff',
      packageId: 'pkg_ff_100',
      playerDetails: { player_id: '123456789' },
      paymentMethod: 'esewa'
    });
    const orderId = createRes.data.order.id;

    // Send webhook with $999.00
    const payload = {
      orderId,
      providerTransactionId: 'TXN_WRONG_AMT_' + Date.now(),
      amount: 999.00,
      status: 'SUCCESS'
    };
    const sig = generateWebhookSignature(JSON.stringify(payload));
    const webhookRes = await runMockRequest('POST', '/api/payments/esewa/webhook', { 'x-signature': sig }, payload);
    assert.strictEqual(webhookRes.status, 400);
    assert.match(webhookRes.data.error, /Amount mismatch/);
  });

  await test('Payment Test 4: Duplicate webhook idempotency protection', async () => {
    const createRes = await runMockRequest('POST', '/api/topups/orders', {}, {
      gameId: 'game_wallet',
      packageId: 'pkg_wal_5',
      playerDetails: {},
      paymentMethod: 'khalti'
    });
    const orderId = createRes.data.order.id;
    const txnId = 'KHALTI_DUP_TX_' + Date.now();

    const payload = {
      orderId,
      providerTransactionId: txnId,
      amount: 5.0,
      status: 'SUCCESS'
    };
    const sig = generateWebhookSignature(JSON.stringify(payload));

    // First call
    const firstCall = await runMockRequest('POST', '/api/payments/khalti/webhook', { 'x-signature': sig }, payload);
    assert.strictEqual(firstCall.status, 200);

    // Second call with same txnId
    const secondCall = await runMockRequest('POST', '/api/payments/khalti/webhook', { 'x-signature': sig }, payload);
    assert.strictEqual(secondCall.status, 200);
    assert.strictEqual(secondCall.data.message, 'Webhook duplicate acknowledged (Idempotent)');
  });

  // 2. WALLET & RECONCILIATION TESTS
  await test('Wallet Test 1: Double-entry ledger reconciliation check', async () => {
    const wallet = getWallet('usr_player1');
    assert.strictEqual(wallet.is_reconciled, true);
    assert.strictEqual(wallet.available_balance + wallet.locked_balance, wallet.net_ledger_balance);
  });

  await test('Wallet Test 2: Insufficient balance prevents spending', async () => {
    let failedWithInsufficient = false;
    try {
      transacts('usr_player3', {
        type: 'TOPUP_PURCHASE',
        amount: 99999.0, // usr_player3 has small balance
        direction: 'DEBIT',
        referenceType: 'TEST',
        actorId: 'usr_player3'
      });
    } catch (e) {
      if (e.code === 'INSUFFICIENT_FUNDS') {
        failedWithInsufficient = true;
      }
    }
    assert.strictEqual(failedWithInsufficient, true);
  });

  await test('Wallet Test 3: Idempotent transaction key prevents duplicate debit', async () => {
    const key = 'test_idemp_key_' + Date.now();
    const wBefore = getWallet('usr_player1').available_balance;

    const t1 = transacts('usr_player1', {
      type: 'TOPUP_PURCHASE',
      amount: 1.0,
      direction: 'DEBIT',
      idempotencyKey: key,
      actorId: 'usr_player1'
    });
    assert.strictEqual(t1.isDuplicate, false);

    const t2 = transacts('usr_player1', {
      type: 'TOPUP_PURCHASE',
      amount: 1.0,
      direction: 'DEBIT',
      idempotencyKey: key,
      actorId: 'usr_player1'
    });
    assert.strictEqual(t2.isDuplicate, true);

    const wAfter = getWallet('usr_player1').available_balance;
    assert.strictEqual(+(wBefore - wAfter).toFixed(2), 1.0); // Only deducted once!
  });

  // 3. TOURNAMENT LIFECYCLE & SECURITY TESTS
  await test('Tournament Test 1: Duplicate registration blocked', async () => {
    // Ensure usr_player1 has active registration
    db.prepare(`
      INSERT INTO tournament_registrations (id, tournament_id, user_id, status, receipt_number, registered_at)
      VALUES ('reg_test_ff', 'tour_ff_pro', 'usr_player1', 'CONFIRMED', 'RCPT-TEST-SEED', datetime('now'))
      ON CONFLICT(tournament_id, user_id) DO UPDATE SET status = 'CONFIRMED'
    `).run();

    const joinRes = await runMockRequest('POST', '/api/tournaments/tour_ff_pro/register', {}, {});
    assert.strictEqual(joinRes.status, 409);
    assert.match(joinRes.data.error, /already registered/);
  });

  await test('Tournament Test 2: Cancellation refunds entry fee to ledger', async () => {
    const wBefore = getWallet('usr_player1').available_balance;
    const cancelRes = await runMockRequest('POST', '/api/tournaments/tour_ff_pro/cancel-registration', {}, {});
    assert.strictEqual(cancelRes.status, 200);
    assert.strictEqual(cancelRes.data.refundAmount, 10.0);

    const wAfter = getWallet('usr_player1').available_balance;
    assert.strictEqual(+(wAfter - wBefore).toFixed(2), 10.0);
  });

  await test('Tournament Test 3: Room secrets hidden from public & unreleased matches', async () => {
    // tour_ff_pro match room release is in 165 minutes
    const matchRes = await runMockRequest('GET', '/api/matches/mat_ff_r1', {}, {});
    assert.strictEqual(matchRes.status, 200);
    assert.strictEqual(matchRes.data.room_id, '*** LOCKED ***');
    assert.strictEqual(matchRes.data.can_access_room, false);
  });

  await test('Tournament Test 4: Room secrets revealed when live and registered', async () => {
    // mat_mlbb_live has room release in past (-20 mins) and usr_player1 is registered
    const matchRes = await runMockRequest('GET', '/api/matches/mat_mlbb_live', {}, {});
    assert.strictEqual(matchRes.status, 200);
    assert.strictEqual(matchRes.data.can_access_room, true);
    assert.strictEqual(matchRes.data.room_id, 'CUSTOM-ML-552');
    assert.strictEqual(matchRes.data.room_password, 'Mystic888');
  });

  // 4. RESULTS & DUAL-APPROVAL PRIZE WORKFLOW
  await test('Results & Rewards: Deterministic scoring and dual-approval payout', async () => {
    // Create new tournament with Tournament Manager
    const tourRes = await runMockRequest('POST', '/api/admin/tournaments', { 'x-auth-token': 'usr_tmgr' }, {
      title: 'Championship Test Tourney',
      gameId: 'game_ff',
      mode: 'Solo',
      entryFee: 0,
      prizePool: 100,
      startsAt: new Date().toISOString()
    });
    const { tournamentId, matchId } = tourRes.data;

    // Submit match results with Tournament Manager
    const scoreRes = await runMockRequest('POST', `/api/admin/matches/${matchId}/results`, { 'x-auth-token': 'usr_tmgr' }, {
      results: [
        { userId: 'usr_player1', placement: 1, kills: 8 },
        { userId: 'usr_player2', placement: 2, kills: 3 }
      ]
    });
    assert.strictEqual(scoreRes.status, 200);

    // Verify prize payouts created
    const payouts = db.prepare('SELECT * FROM prize_payouts WHERE tournament_id = ?').all(tournamentId);
    assert.strictEqual(payouts.length, 2);
    const p1Payout = payouts.find(p => p.user_id === 'usr_player1');
    assert.strictEqual(p1Payout.amount, 60.0); // 60% of 100

    // Step 1: First approval by Tournament Manager
    const app1 = await runMockRequest('POST', `/api/admin/prizes/${p1Payout.id}/approve`, { 'x-auth-token': 'usr_tmgr' }, {});
    assert.strictEqual(app1.data.status, 'PENDING_FINANCE_APPROVAL');

    // Step 2: Dual approval with finance role
    const app2 = await runMockRequest('POST', `/api/admin/prizes/${p1Payout.id}/approve`, { 'x-auth-token': 'usr_finance' }, {});
    assert.strictEqual(app2.data.status, 'PAID');

    // Winner wallet credited
    const p1Ledger = db.prepare('SELECT * FROM wallet_ledger WHERE reference_id = ?').get(p1Payout.id);
    assert.strictEqual(p1Ledger.amount, 60.0);
    assert.strictEqual(p1Ledger.type, 'PRIZE_PAYOUT');
  });

  await test('Free Fire Scoreboard Submission: Player submits proof, kills & deterministic points', async () => {
    // usr_player1 is confirmed in tour_live_showdown / mat_mlbb_live
    const subRes = await runMockRequest('POST', '/api/matches/mat_mlbb_live/submit-result', {}, {
      placement: 1,
      kills: 6,
      ign: 'TNT_ShadowHunter',
      uid: '1092837461',
      evidenceUrl: 'https://images.unsplash.com/photo-1542751371-adc38448a05e'
    });
    assert.strictEqual(subRes.status, 200);
    assert.strictEqual(subRes.data.placement, 1);
    assert.strictEqual(subRes.data.kills, 6);
    assert.strictEqual(subRes.data.points, 18.0); // 12 placement + 6 kills
    assert.strictEqual(subRes.data.status, 'PROVISIONAL');

    // Verify stored in match_results
    const stored = db.prepare('SELECT * FROM match_results WHERE match_id = ? AND user_id = ?').get('mat_mlbb_live', 'usr_player1');
    assert.ok(stored);
    assert.strictEqual(stored.placement, 1);
    assert.strictEqual(stored.kills, 6);
    assert.strictEqual(stored.points, 18.0);
  });

  await test('Admin Game Catalog: List, create, toggle and manage packages', async () => {
    // 1. Get all admin games as super_admin
    const listRes = await runMockRequest('GET', '/api/admin/games', { 'x-auth-token': 'usr_admin' });
    assert.strictEqual(listRes.status, 200);
    assert.ok(Array.isArray(listRes.data));
    assert.ok(listRes.data.length >= 5);

    // Verify Poki/Web games exist
    const hasPoki = listRes.data.some(g => g.id.startsWith('poki_'));
    assert.ok(hasPoki, 'Poki game should be present in games catalog');

    // 2. Create a new game title as admin
    const newGameRes = await runMockRequest('POST', '/api/admin/games', { 'x-auth-token': 'usr_admin' }, {
      name: 'Test Battle Royale 2026',
      category: 'Battle Royale',
      icon: '🔥',
      banner: '/assets/games/battleground.webp',
      deliveryMethod: 'auto_api',
      requiredPlayerFields: ['Player ID', 'Server']
    });
    assert.strictEqual(newGameRes.status, 201);
    assert.ok(newGameRes.data.id);
    const createdGameId = newGameRes.data.id;

    // 3. Add a topup package to the game
    const pkgRes = await runMockRequest('POST', '/api/admin/topup-packages', { 'x-auth-token': 'usr_admin' }, {
      gameId: createdGameId,
      name: '1000 Battle Credits',
      itemQuantity: '1000 Credits',
      price: 9.99,
      badge: 'HOT'
    });
    assert.strictEqual(pkgRes.status, 201);
    assert.ok(pkgRes.data.id);

    // 4. Update the game (toggle status)
    const updateRes = await runMockRequest('PUT', `/api/admin/games/${createdGameId}`, { 'x-auth-token': 'usr_admin' }, {
      active: false
    });
    assert.strictEqual(updateRes.status, 200);

    // 5. Delete/deactivate game
    const delRes = await runMockRequest('DELETE', `/api/admin/games/${createdGameId}`, { 'x-auth-token': 'usr_admin' });
    assert.strictEqual(delRes.status, 200);
  });

  await test('Wallet Deposit: User requests deposit, submits QR payment screenshot & TxID, admin verifies and credits balance', async () => {
    const userWalletBefore = db.prepare('SELECT * FROM wallets WHERE user_id = ?').get('usr_player1');
    const initialBalance = userWalletBefore.available_balance;

    // 1. User initiates a $25 deposit via eSewa QR
    const initRes = await runMockRequest('POST', '/api/wallet/topups', { 'x-auth-token': 'usr_player1' }, {
      amount: 25.0,
      provider: 'esewa',
      remarks: 'DEP-TEST-1234'
    });
    assert.strictEqual(initRes.status, 200);
    assert.ok(initRes.data.orderId);
    assert.strictEqual(initRes.data.amount, 25.0);
    assert.strictEqual(initRes.data.status, 'PENDING_PAYMENT');
    const orderId = initRes.data.orderId;

    // 2. User submits screenshot proof & provider transaction ID
    const sampleScreenshot = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';
    const proofRes = await runMockRequest('POST', `/api/wallet/topups/${orderId}/proof`, { 'x-auth-token': 'usr_player1' }, {
      transactionId: 'ESEWA-TX-998877',
      screenshotUrl: sampleScreenshot,
      remarks: 'Payment completed via eSewa app'
    });
    assert.strictEqual(proofRes.status, 200);
    assert.strictEqual(proofRes.data.success, true);

    // Verify order is now PROCESSING with screenshot attached
    const storedOrder = db.prepare('SELECT * FROM topup_orders WHERE id = ?').get(orderId);
    assert.strictEqual(storedOrder.status, 'PROCESSING');
    assert.strictEqual(storedOrder.provider_tx_id, 'ESEWA-TX-998877');
    assert.strictEqual(storedOrder.screenshot_url, sampleScreenshot);

    // 3. Admin checks pending payments queue
    const pendingRes = await runMockRequest('GET', '/api/admin/payments/pending', { 'x-auth-token': 'usr_admin' });
    assert.strictEqual(pendingRes.status, 200);
    const orderInQueue = pendingRes.data.find(o => o.id === orderId);
    assert.ok(orderInQueue, 'Order should be present in admin pending queue');
    assert.strictEqual(orderInQueue.provider_tx_id, 'ESEWA-TX-998877');

    // 4. Admin verifies payment and approves
    const verifyRes = await runMockRequest('POST', `/api/admin/payments/${orderId}/verify`, { 'x-auth-token': 'usr_admin' });
    assert.strictEqual(verifyRes.status, 200);
    assert.strictEqual(verifyRes.data.success, true);

    // 5. Verify order is DELIVERED and user wallet balance was credited by exactly $25.00
    const finalOrder = db.prepare('SELECT * FROM topup_orders WHERE id = ?').get(orderId);
    assert.strictEqual(finalOrder.status, 'DELIVERED');

    const userWalletAfter = db.prepare('SELECT * FROM wallets WHERE user_id = ?').get('usr_player1');
    assert.strictEqual(userWalletAfter.available_balance, initialBalance + 25.0);

    // Verify ledger entry
    const ledgerEntry = db.prepare('SELECT * FROM wallet_ledger WHERE user_id = ? AND reference_id = ?').get('usr_player1', orderId);
    assert.ok(ledgerEntry, 'Ledger entry should be created');
    assert.strictEqual(ledgerEntry.amount, 25.0);
    assert.strictEqual(ledgerEntry.type, 'DEPOSIT');
  });

  await test('Live Support Chat: Player sends inquiry, Admin receives unread notification count, inspects thread, and sends reply', async () => {
    // 1. Player1 sends a message to support
    const sendRes = await runMockRequest('POST', '/api/chat/send', { 'x-auth-token': 'usr_player1' }, {
      message: 'Hello, need help checking my latest Free Fire diamond package status!'
    });
    assert.strictEqual(sendRes.status, 200);
    assert.strictEqual(sendRes.data.sender_role, 'player');
    assert.strictEqual(sendRes.data.recipient_id, 'admin');

    // 2. Admin checks unread notification count
    const unreadRes = await runMockRequest('GET', '/api/chat/unread-count', { 'x-auth-token': 'usr_admin' });
    assert.strictEqual(unreadRes.status, 200);
    assert.ok(unreadRes.data.unreadCount >= 1);
    assert.ok(unreadRes.data.latestMessage);

    // 3. Admin lists chat threads
    const threadsRes = await runMockRequest('GET', '/api/chat/threads', { 'x-auth-token': 'usr_admin' });
    assert.strictEqual(threadsRes.status, 200);
    assert.ok(Array.isArray(threadsRes.data));
    const playerThread = threadsRes.data.find(t => t.user_id === 'usr_player1');
    assert.ok(playerThread, 'Player1 thread should be present in admin chat list');
    assert.strictEqual(playerThread.user_name, 'Phoenix_Ace');

    // 4. Admin opens conversation thread (which marks unread as read)
    const threadDetailsRes = await runMockRequest('GET', '/api/chat/threads/usr_player1', { 'x-auth-token': 'usr_admin' });
    assert.strictEqual(threadDetailsRes.status, 200);
    assert.ok(threadDetailsRes.data.messages.length >= 2);
    assert.ok(threadDetailsRes.data.user);

    // 5. Admin sends a reply back to Player1
    const replyRes = await runMockRequest('POST', '/api/chat/send', { 'x-auth-token': 'usr_admin' }, {
      targetUserId: 'usr_player1',
      message: 'Hello Aarav! Your Free Fire diamond package was successfully delivered to your UID.'
    });
    assert.strictEqual(replyRes.status, 200);
    assert.strictEqual(replyRes.data.sender_role, 'admin');
    assert.strictEqual(replyRes.data.recipient_id, 'usr_player1');

    // 6. Player checks their conversation and sees admin reply
    const playerChatRes = await runMockRequest('GET', '/api/chat/threads/usr_player1', { 'x-auth-token': 'usr_player1' });
    assert.strictEqual(playerChatRes.status, 200);
    const lastMsg = playerChatRes.data.messages[playerChatRes.data.messages.length - 1];
    assert.strictEqual(lastMsg.sender_role, 'admin');
    assert.strictEqual(lastMsg.message, 'Hello Aarav! Your Free Fire diamond package was successfully delivered to your UID.');
  });

  await test('Payment Gateways & QR Codes: Admin creates, updates, and deletes payment QR', async () => {
    // 1. Public retrieval of active gateways
    const pubRes = await runMockRequest('GET', '/api/payment-gateways');
    assert.strictEqual(pubRes.status, 200);
    assert.ok(Array.isArray(pubRes.data));
    assert.ok(pubRes.data.length >= 3); // Seeded eSewa, Khalti, Fonepay

    // 2. Admin creates a new custom QR gateway
    const createRes = await runMockRequest('POST', '/api/admin/payment-gateways', { 'x-auth-token': 'usr_admin' }, {
      name: 'Binance USDT Pay (TRC20)',
      provider: 'usdt',
      qrImageUrl: '/assets/payment/usdt_qr.png',
      receiverName: 'TnT Crypto Vault',
      receiverNumber: 'TFxyz123456789CryptoAddress',
      instructions: 'Transfer USDT TRC20 and paste TXID in remarks',
      active: 1,
      sortOrder: 5
    });
    assert.strictEqual(createRes.status, 201);
    const createdId = createRes.data.id;
    assert.ok(createdId);

    // 3. Admin updates gateway
    const updateRes = await runMockRequest('PUT', `/api/admin/payment-gateways/${createdId}`, { 'x-auth-token': 'usr_admin' }, {
      active: 0,
      instructions: 'Updated instructions for crypto deposits'
    });
    assert.strictEqual(updateRes.status, 200);

    // 4. Verify deactivated gateway does not show in public list
    const pubAfterRes = await runMockRequest('GET', '/api/payment-gateways');
    const foundInactive = pubAfterRes.data.find(g => g.id === createdId);
    assert.strictEqual(foundInactive, undefined, 'Deactivated gateway must not appear in public active list');

    // 5. Admin deletes the test gateway
    const delRes = await runMockRequest('DELETE', `/api/admin/payment-gateways/${createdId}`, { 'x-auth-token': 'usr_admin' });
    assert.strictEqual(delRes.status, 200);
  });

  await test('Homepage Hero Banners ("Top Things"): Admin creates, updates, and deletes billboard banners', async () => {
    // 1. Public retrieval of active banners
    const pubRes = await runMockRequest('GET', '/api/banners');
    assert.strictEqual(pubRes.status, 200);
    assert.ok(Array.isArray(pubRes.data));
    assert.ok(pubRes.data.length >= 1);

    // 2. Admin creates a new promo billboard banner
    const createRes = await runMockRequest('POST', '/api/admin/banners', { 'x-auth-token': 'usr_admin' }, {
      title: 'Free Fire World Series 2026 Registration Open',
      imageUrl: '/assets/banners/ff_world_series.webp',
      linkUrl: '#tournaments',
      badgeText: '🔥 $10,000 PRIZE',
      active: 1,
      sortOrder: 1
    });
    assert.strictEqual(createRes.status, 201);
    const bannerId = createRes.data.id;
    assert.ok(bannerId);

    // 3. Admin updates banner status
    const updateRes = await runMockRequest('PUT', `/api/admin/banners/${bannerId}`, { 'x-auth-token': 'usr_admin' }, {
      badgeText: '🏆 CHAMPIONSHIP LIVE',
      active: 0
    });
    assert.strictEqual(updateRes.status, 200);

    // 4. Admin deletes test banner
    const delRes = await runMockRequest('DELETE', `/api/admin/banners/${bannerId}`, { 'x-auth-token': 'usr_admin' });
    assert.strictEqual(delRes.status, 200);
  });

  await test('Game & Package Management: Safe package and game deletion', async () => {
    // 1. Create temporary test game
    const gameRes = await runMockRequest('POST', '/api/admin/games', { 'x-auth-token': 'usr_admin' }, {
      name: 'Temp Deletion Game',
      category: 'Shooter',
      icon: '🎯',
      banner: '/assets/games/battleground.webp',
      deliveryMethod: 'auto_api',
      requiredPlayerFields: ['Player ID']
    });
    assert.strictEqual(gameRes.status, 201);
    const gameId = gameRes.data.id;

    // 2. Add package to test game
    const pkgRes = await runMockRequest('POST', '/api/admin/topup-packages', { 'x-auth-token': 'usr_admin' }, {
      gameId,
      name: '500 Coins',
      itemQuantity: '500 Coins',
      price: 4.99,
      badge: 'SPECIAL'
    });
    assert.strictEqual(pkgRes.status, 201);
    const pkgId = pkgRes.data.id;

    // 3. Delete package
    const delPkgRes = await runMockRequest('DELETE', `/api/admin/topup-packages/${pkgId}`, { 'x-auth-token': 'usr_admin' });
    assert.strictEqual(delPkgRes.status, 200);

    // 4. Delete game
    const delGameRes = await runMockRequest('DELETE', `/api/admin/games/${gameId}?force=true`, { 'x-auth-token': 'usr_admin' });
    assert.strictEqual(delGameRes.status, 200);
  });

  console.log(`\n========================================`);
  console.log(`TEST RESULTS: ${passed} PASSED, ${failed} FAILED`);
  console.log(`========================================\n`);

  // Teardown test fixtures so database remains completely clean
  teardownTestFixtures();

  if (failed > 0) {
    process.exit(1);
  }
}

runTests();
