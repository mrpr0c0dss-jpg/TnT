const { DatabaseSync } = require('node:sqlite');
const path = require('node:path');
const fs = require('node:fs');
const crypto = require('node:crypto');

const DB_PATH = path.join(__dirname, '..', 'topup_tournament.sqlite');
const db = new DatabaseSync(DB_PATH);

// Enable foreign keys and WAL mode
db.exec('PRAGMA foreign_keys = ON;');

function initSchema() {
  db.exec(`
    CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY,
      display_name TEXT NOT NULL,
      email TEXT UNIQUE NOT NULL,
      phone TEXT,
      role TEXT NOT NULL DEFAULT 'player',
      status TEXT NOT NULL DEFAULT 'active',
      ban_reason TEXT,
      avatar TEXT,
      created_at TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS wallets (
      user_id TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
      currency TEXT NOT NULL DEFAULT 'USD',
      available_balance REAL NOT NULL DEFAULT 0.0,
      locked_balance REAL NOT NULL DEFAULT 0.0,
      updated_at TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS wallet_ledger (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL REFERENCES users(id),
      type TEXT NOT NULL,
      amount REAL NOT NULL,
      direction TEXT NOT NULL,
      reference_type TEXT,
      reference_id TEXT,
      idempotency_key TEXT UNIQUE,
      note TEXT,
      created_at TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS topup_games (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      slug TEXT UNIQUE NOT NULL,
      category TEXT NOT NULL DEFAULT 'Battle Royale',
      icon TEXT NOT NULL,
      banner TEXT NOT NULL,
      active INTEGER NOT NULL DEFAULT 1,
      delivery_method TEXT NOT NULL DEFAULT 'auto_api',
      required_player_fields TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS topup_packages (
      id TEXT PRIMARY KEY,
      game_id TEXT NOT NULL REFERENCES topup_games(id) ON DELETE CASCADE,
      name TEXT NOT NULL,
      item_quantity TEXT NOT NULL,
      price REAL NOT NULL,
      badge TEXT,
      active INTEGER NOT NULL DEFAULT 1,
      sort_order INTEGER NOT NULL DEFAULT 0
    );

    CREATE TABLE IF NOT EXISTS topup_orders (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL REFERENCES users(id),
      game_id TEXT REFERENCES topup_games(id),
      package_id TEXT REFERENCES topup_packages(id),
      player_details TEXT NOT NULL,
      amount REAL NOT NULL,
      fee REAL NOT NULL DEFAULT 0.0,
      payment_method TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'PENDING_PAYMENT',
      idempotency_key TEXT UNIQUE,
      delivery_attempts INTEGER NOT NULL DEFAULT 0,
      delivery_error TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS payments (
      id TEXT PRIMARY KEY,
      order_id TEXT NOT NULL REFERENCES topup_orders(id),
      provider TEXT NOT NULL,
      provider_transaction_id TEXT NOT NULL,
      amount REAL NOT NULL,
      status TEXT NOT NULL DEFAULT 'SUCCESS',
      verified_at TEXT,
      raw_event_reference TEXT,
      created_at TEXT NOT NULL,
      UNIQUE(provider, provider_transaction_id)
    );

    CREATE TABLE IF NOT EXISTS tournaments (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      game_id TEXT NOT NULL REFERENCES topup_games(id),
      mode TEXT NOT NULL DEFAULT 'Solo',
      region TEXT NOT NULL DEFAULT 'South Asia',
      banner TEXT NOT NULL,
      description TEXT,
      entry_fee REAL NOT NULL DEFAULT 0.0,
      prize_pool REAL NOT NULL DEFAULT 0.0,
      prize_split TEXT NOT NULL,
      max_slots INTEGER NOT NULL DEFAULT 48,
      starts_at TEXT NOT NULL,
      registration_closes_at TEXT NOT NULL,
      check_in_opens_at TEXT,
      room_release_at TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'Registration Open',
      rules TEXT NOT NULL,
      scoring_config TEXT NOT NULL,
      cancellation_reason TEXT,
      created_at TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS tournament_registrations (
      id TEXT PRIMARY KEY,
      tournament_id TEXT NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
      user_id TEXT NOT NULL REFERENCES users(id),
      team_id TEXT,
      status TEXT NOT NULL DEFAULT 'CONFIRMED',
      entry_payment_ledger_id TEXT,
      receipt_number TEXT UNIQUE NOT NULL,
      registered_at TEXT NOT NULL,
      UNIQUE(tournament_id, user_id)
    );

    CREATE TABLE IF NOT EXISTS teams (
      id TEXT PRIMARY KEY,
      tournament_id TEXT NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
      name TEXT NOT NULL,
      captain_user_id TEXT NOT NULL REFERENCES users(id),
      created_at TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS team_members (
      id TEXT PRIMARY KEY,
      team_id TEXT NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
      user_id TEXT NOT NULL REFERENCES users(id),
      role TEXT NOT NULL DEFAULT 'member',
      UNIQUE(team_id, user_id)
    );

    CREATE TABLE IF NOT EXISTS matches (
      id TEXT PRIMARY KEY,
      tournament_id TEXT NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
      round_number INTEGER NOT NULL DEFAULT 1,
      match_code TEXT NOT NULL,
      scheduled_at TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'SCHEDULED',
      room_id TEXT,
      room_password TEXT,
      room_secret_reference TEXT,
      created_at TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS match_results (
      id TEXT PRIMARY KEY,
      match_id TEXT NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
      user_id TEXT NOT NULL REFERENCES users(id),
      team_id TEXT,
      placement INTEGER NOT NULL,
      kills INTEGER NOT NULL DEFAULT 0,
      points REAL NOT NULL DEFAULT 0.0,
      evidence_reference TEXT,
      submitted_by TEXT,
      approved_by TEXT,
      status TEXT NOT NULL DEFAULT 'PROVISIONAL',
      created_at TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS prize_payouts (
      id TEXT PRIMARY KEY,
      tournament_id TEXT NOT NULL REFERENCES tournaments(id),
      user_id TEXT NOT NULL REFERENCES users(id),
      team_id TEXT,
      amount REAL NOT NULL,
      status TEXT NOT NULL DEFAULT 'PENDING_APPROVAL',
      provider_reference TEXT,
      approved_by TEXT,
      dual_approved_by TEXT,
      paid_at TEXT,
      created_at TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS disputes (
      id TEXT PRIMARY KEY,
      tournament_id TEXT NOT NULL REFERENCES tournaments(id),
      match_id TEXT REFERENCES matches(id),
      user_id TEXT NOT NULL REFERENCES users(id),
      reason TEXT NOT NULL,
      evidence_url TEXT,
      status TEXT NOT NULL DEFAULT 'OPEN',
      resolution_notes TEXT,
      resolved_by TEXT,
      created_at TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS audit_logs (
      id TEXT PRIMARY KEY,
      actor_id TEXT NOT NULL,
      action TEXT NOT NULL,
      entity_type TEXT NOT NULL,
      entity_id TEXT NOT NULL,
      reason TEXT,
      metadata TEXT,
      created_at TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS ai_subscriptions (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL REFERENCES users(id),
      tool_id TEXT NOT NULL,
      tool_name TEXT NOT NULL,
      plan_name TEXT NOT NULL,
      account_email TEXT NOT NULL,
      license_key TEXT,
      status TEXT NOT NULL DEFAULT 'ACTIVE',
      billing_cycle TEXT NOT NULL DEFAULT 'monthly',
      amount REAL NOT NULL,
      starts_at TEXT NOT NULL,
      expires_at TEXT NOT NULL,
      auto_renew INTEGER NOT NULL DEFAULT 1,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS ai_license_keys (
      id TEXT PRIMARY KEY,
      tool_id TEXT NOT NULL,
      tool_name TEXT NOT NULL,
      license_code TEXT UNIQUE NOT NULL,
      status TEXT NOT NULL DEFAULT 'AVAILABLE',
      assigned_to_user_id TEXT REFERENCES users(id),
      assigned_order_id TEXT,
      created_at TEXT NOT NULL
    );
  `);

  try {
    db.exec(`ALTER TABLE topup_games ADD COLUMN external_url TEXT DEFAULT NULL;`);
  } catch (e) {
    // Column already exists
  }

  try {
    db.exec(`ALTER TABLE topup_orders ADD COLUMN screenshot_url TEXT DEFAULT NULL;`);
  } catch (e) {}

  try {
    db.exec(`ALTER TABLE topup_orders ADD COLUMN provider_tx_id TEXT DEFAULT NULL;`);
  } catch (e) {}

  // Ensure Poki & Web Arcade Games exist in database
  const ensureWebGames = [
    {
      id: 'poki_subway_surfers',
      name: 'Subway Surfers (Poki)',
      slug: 'subway-surfers-poki',
      category: 'Web Arcade / Runner',
      icon: '🛹',
      banner: '/assets/games/subway_surfers.jpg',
      active: 1,
      delivery_method: 'web_direct',
      required_player_fields: '[]',
      external_url: 'https://poki.com/en/g/subway-surfers'
    },
    {
      id: 'poki_drive_mad',
      name: 'Drive Mad: 3D Stunt (Poki)',
      slug: 'drive-mad-poki',
      category: 'Web Arcade / 3D Racing',
      icon: '🚙',
      banner: '/assets/games/drive_mad.jpg',
      active: 1,
      delivery_method: 'web_direct',
      required_player_fields: '[]',
      external_url: 'https://poki.com/en/g/drive-mad'
    },
    {
      id: 'poki_games_hub',
      name: 'Poki: 1,000+ Online Games',
      slug: 'poki-games-hub',
      category: 'Web Arcade / Hub',
      icon: '👾',
      banner: '/assets/games/poki.jpg',
      active: 1,
      delivery_method: 'web_direct',
      required_player_fields: '[]',
      external_url: 'https://poki.com/'
    },
    {
      id: 'bloxd_io_3d',
      name: 'Bloxd.io: 3D BedWars & Obby',
      slug: 'bloxd-io-3d',
      category: '3D WebGL / Voxel',
      icon: '⛏️',
      banner: '/assets/games/bloxd_io.webp',
      active: 1,
      delivery_method: 'web_direct',
      required_player_fields: '[]',
      external_url: 'https://bloxd.io/'
    },
    {
      id: 'hexgl_3d_racer',
      name: 'HexGL: 3D Sci-Fi Racer',
      slug: 'hexgl-3d-racer',
      category: '3D WebGL / Racing',
      icon: '🏎️',
      banner: '/assets/games/hexgl.webp',
      active: 1,
      delivery_method: 'web_direct',
      required_player_fields: '[]',
      external_url: 'https://hexgl.bkcore.com/play/'
    }
  ];

  for (const wg of ensureWebGames) {
    try {
      const existing = db.prepare('SELECT id FROM topup_games WHERE id = ?').get(wg.id);
      if (!existing) {
        db.prepare(`
          INSERT INTO topup_games (id, name, slug, category, icon, banner, active, delivery_method, required_player_fields, external_url)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `).run(wg.id, wg.name, wg.slug, wg.category, wg.icon, wg.banner, wg.active, wg.delivery_method, wg.required_player_fields, wg.external_url);
      }
    } catch (err) {
      // Ignore if table not yet populated
    }
  }
}

function seedDatabase() {
  const userCount = db.prepare('SELECT COUNT(*) as count FROM users').get().count;
  if (userCount > 0) {
    return;
  }

  const now = new Date();
  const iso = (offsetMinutes = 0) => new Date(now.getTime() + offsetMinutes * 60000).toISOString();

  // 1. Seed Users (Roles: super_admin, tournament_manager, topup_operator, finance_reviewer, support, player)
  const users = [
    { id: 'usr_player1', name: 'Phoenix_Ace', email: 'phoenix@gamer.io', phone: '+977-9801234567', role: 'player', status: 'active', balance: 150.0 },
    { id: 'usr_player2', name: 'ViperStrike', email: 'viper@gamer.io', phone: '+977-9812345678', role: 'player', status: 'active', balance: 45.0 },
    { id: 'usr_player3', name: 'ShadowNinja', email: 'ninja@gamer.io', phone: '+977-9823456789', role: 'player', status: 'active', balance: 8.5 },
    { id: 'usr_admin', name: 'Aegis_Root', email: 'admin@platform.io', phone: '+1-555-0100', role: 'super_admin', status: 'active', balance: 1000.0 },
    { id: 'usr_mrpr0', name: 'MrPr0C0dss', email: 'mrpr0c0dss@gmail.com', phone: '+977-9800000000', role: 'super_admin', status: 'active', balance: 2500.0 },
    { id: 'usr_tmgr', name: 'Kage_Director', email: 'tournaments@platform.io', phone: '+1-555-0101', role: 'tournament_manager', status: 'active', balance: 500.0 },
    { id: 'usr_operator', name: 'Nexus_Ops', email: 'ops@platform.io', phone: '+1-555-0102', role: 'topup_operator', status: 'active', balance: 250.0 },
    { id: 'usr_finance', name: 'Audit_Vault', email: 'finance@platform.io', phone: '+1-555-0103', role: 'finance_reviewer', status: 'active', balance: 5000.0 },
    { id: 'usr_support', name: 'Sentinel_Care', email: 'support@platform.io', phone: '+1-555-0104', role: 'support', status: 'active', balance: 100.0 },
  ];

  const insertUser = db.prepare(`
    INSERT INTO users (id, display_name, email, phone, role, status, avatar, created_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
  `);
  const insertWallet = db.prepare(`
    INSERT INTO wallets (user_id, currency, available_balance, locked_balance, updated_at)
    VALUES (?, 'USD', ?, 0.0, ?)
  `);
  const insertLedger = db.prepare(`
    INSERT INTO wallet_ledger (id, user_id, type, amount, direction, reference_type, reference_id, idempotency_key, note, created_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);

  for (const u of users) {
    insertUser.run(u.id, u.display_name || u.name, u.email, u.phone, u.role, u.status, `https://api.dicebear.com/7.x/bottts/svg?seed=${u.id}`, iso(-1440));
    insertWallet.run(u.id, u.balance, iso(-1440));
    if (u.balance > 0) {
      insertLedger.run(
        'led_' + crypto.randomUUID().slice(0, 8),
        u.id,
        'DEPOSIT',
        u.balance,
        'CREDIT',
        'INITIAL_GRANT',
        'genesis',
        'idemp_init_' + u.id,
        'Initial platform starting balance',
        iso(-1440)
      );
    }
  }

  // 2. Seed Games & Packages
  const games = [
    {
      id: 'game_ff',
      name: 'Free Fire MAX',
      slug: 'free-fire',
      category: 'Battle Royale',
      icon: '🔥',
      banner: 'https://images.unsplash.com/photo-1542751371-adc38448a05e?auto=format&fit=crop&w=800&q=80',
      active: 1,
      delivery_method: 'auto_api',
      required_player_fields: JSON.stringify([
        { key: 'player_id', label: 'Player UID', regex: '^[0-9]{8,12}$', hint: '8-12 numeric digits (e.g. 192837465)' }
      ]),
      packages: [
        { id: 'pkg_ff_100', name: '100+10 Diamonds', item_quantity: '110 💎', price: 0.99, badge: 'Popular', sort_order: 1 },
        { id: 'pkg_ff_310', name: '310+31 Diamonds', item_quantity: '341 💎', price: 2.99, badge: null, sort_order: 2 },
        { id: 'pkg_ff_520', name: '520+52 Diamonds', item_quantity: '572 💎', price: 4.89, badge: 'Best Value', sort_order: 3 },
        { id: 'pkg_ff_1060', name: '1060+106 Diamonds', item_quantity: '1166 💎', price: 9.79, badge: '+10% Bonus', sort_order: 4 },
        { id: 'pkg_ff_pass', name: 'Weekly Membership', item_quantity: 'VIP Pass', price: 1.99, badge: 'Hot Deal', sort_order: 5 }
      ]
    },
    {
      id: 'game_pubg',
      name: 'PUBG Mobile',
      slug: 'pubg-mobile',
      category: 'Battle Royale',
      icon: '🪖',
      banner: 'https://images.unsplash.com/photo-1511512578047-dfb367046420?auto=format&fit=crop&w=800&q=80',
      active: 1,
      delivery_method: 'auto_api',
      required_player_fields: JSON.stringify([
        { key: 'player_id', label: 'Character ID', regex: '^[0-9]{7,11}$', hint: '7-11 digits (e.g. 518392019)' },
        { key: 'server_id', label: 'In-Game Nickname', regex: '^.{3,20}$', hint: 'Your exact player tag' }
      ]),
      packages: [
        { id: 'pkg_pubg_60', name: '60 UC', item_quantity: '60 🟡', price: 0.99, badge: null, sort_order: 1 },
        { id: 'pkg_pubg_300', name: '300 + 25 Bonus UC', item_quantity: '325 🟡', price: 4.89, badge: 'Popular', sort_order: 2 },
        { id: 'pkg_pubg_600', name: '600 + 60 Bonus UC', item_quantity: '660 🟡', price: 9.49, badge: 'Best Seller', sort_order: 3 },
        { id: 'pkg_pubg_1500', name: '1500 + 300 Bonus UC', item_quantity: '1800 🟡', price: 23.99, badge: '+20% Extra', sort_order: 4 }
      ]
    },
    {
      id: 'game_mlbb',
      name: 'Mobile Legends: Bang Bang',
      slug: 'mobile-legends',
      category: 'MOBA',
      icon: '⚔️',
      banner: 'https://images.unsplash.com/photo-1550745165-9bc0b252726f?auto=format&fit=crop&w=800&q=80',
      active: 1,
      delivery_method: 'auto_api',
      required_player_fields: JSON.stringify([
        { key: 'player_id', label: 'User ID', regex: '^[0-9]{6,10}$', hint: '6-10 digits (e.g. 8493021)' },
        { key: 'server_id', label: 'Zone ID', regex: '^[0-9]{4,5}$', hint: '4-5 digits in parentheses' }
      ]),
      packages: [
        { id: 'pkg_mlbb_86', name: '86 Diamonds', item_quantity: '86 💎', price: 1.49, badge: null, sort_order: 1 },
        { id: 'pkg_mlbb_172', name: '172 Diamonds', item_quantity: '172 💎', price: 2.99, badge: 'Popular', sort_order: 2 },
        { id: 'pkg_mlbb_257', name: '257 Diamonds', item_quantity: '257 💎', price: 4.39, badge: null, sort_order: 3 },
        { id: 'pkg_mlbb_706', name: '706 Diamonds', item_quantity: '706 💎', price: 11.89, badge: 'Best Value', sort_order: 4 },
        { id: 'pkg_mlbb_pass', name: 'Twilight Pass', item_quantity: 'Season Pass', price: 9.99, badge: 'Exclusive', sort_order: 5 }
      ]
    },
    {
      id: 'game_val',
      name: 'Valorant',
      slug: 'valorant',
      category: 'Tactical Shooter',
      icon: '🎯',
      banner: 'https://images.unsplash.com/photo-1563089145-599997674d42?auto=format&fit=crop&w=800&q=80',
      active: 1,
      delivery_method: 'auto_api',
      required_player_fields: JSON.stringify([
        { key: 'player_id', label: 'Riot ID & Tag', regex: '^.+#.+', hint: 'Name#TAG (e.g. Ace#EUW)' }
      ]),
      packages: [
        { id: 'pkg_val_475', name: '475 VP', item_quantity: '475 💠', price: 4.99, badge: null, sort_order: 1 },
        { id: 'pkg_val_1000', name: '1,000 VP', item_quantity: '1,000 💠', price: 9.99, badge: 'Popular', sort_order: 2 },
        { id: 'pkg_val_2050', name: '2,050 VP', item_quantity: '2,050 💠', price: 19.99, badge: 'Best Value', sort_order: 3 }
      ]
    },
    {
      id: 'game_roblox',
      name: 'Roblox',
      slug: 'roblox',
      category: 'Sandbox / Adventure',
      icon: '🧱',
      banner: '/assets/games/roblox.webp',
      active: 1,
      delivery_method: 'auto_api',
      required_player_fields: JSON.stringify([
        { key: 'player_id', label: 'Roblox Username', regex: '^[a-zA-Z0-9_]{3,20}$', hint: 'Your Roblox Username (e.g. Builderman)' }
      ]),
      packages: [
        { id: 'pkg_rbx_80', name: '80 Robux', item_quantity: '80 R$', price: 0.99, badge: null, sort_order: 1 },
        { id: 'pkg_rbx_400', name: '400 Robux', item_quantity: '400 R$', price: 4.89, badge: 'Popular', sort_order: 2 },
        { id: 'pkg_rbx_800', name: '800 Robux', item_quantity: '800 R$', price: 9.79, badge: 'Best Value', sort_order: 3 },
        { id: 'pkg_rbx_1700', name: '1,700 Robux', item_quantity: '1,700 R$', price: 19.49, badge: '+10% Bonus', sort_order: 4 },
        { id: 'pkg_rbx_4500', name: '4,500 Robux', item_quantity: '4,500 R$', price: 48.99, badge: 'Pro Gamer', sort_order: 5 },
        { id: 'pkg_rbx_premium', name: 'Roblox Premium 450', item_quantity: 'Monthly VIP', price: 4.99, badge: 'VIP Pass', sort_order: 6 }
      ]
    },
    {
      id: 'game_wallet',
      name: 'Platform Wallet Top-Up',
      slug: 'wallet-topup',
      category: 'Direct Funds',
      icon: '💳',
      banner: 'https://images.unsplash.com/photo-1559526324-4b87b5e36e44?auto=format&fit=crop&w=800&q=80',
      active: 1,
      delivery_method: 'auto_api',
      required_player_fields: '[]',
      packages: [
        { id: 'pkg_wal_5', name: '$5.00 Wallet Credits', item_quantity: '$5.00', price: 5.00, badge: null, sort_order: 1 },
        { id: 'pkg_wal_10', name: '$10.00 Wallet Credits', item_quantity: '$10.00', price: 10.00, badge: 'Popular', sort_order: 2 },
        { id: 'pkg_wal_25', name: '$25.00 + $1.00 Bonus', item_quantity: '$26.00', price: 25.00, badge: '+4% Bonus', sort_order: 3 },
        { id: 'pkg_wal_50', name: '$50.00 + $3.00 Bonus', item_quantity: '$53.00', price: 50.00, badge: 'Best Value', sort_order: 4 },
        { id: 'pkg_wal_100', name: '$100.00 + $10.00 Bonus', item_quantity: '$110.00', price: 100.00, badge: 'VIP Pack', sort_order: 5 }
      ]
    }
  ];

  const insertGame = db.prepare(`
    INSERT INTO topup_games (id, name, slug, category, icon, banner, active, delivery_method, required_player_fields)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);
  const insertPackage = db.prepare(`
    INSERT INTO topup_packages (id, game_id, name, item_quantity, price, badge, active, sort_order)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
  `);

  for (const g of games) {
    insertGame.run(g.id, g.name, g.slug, g.category, g.icon, g.banner, g.active, g.delivery_method, g.required_player_fields);
    for (const p of g.packages) {
      insertPackage.run(p.id, g.id, p.name, p.item_quantity, p.price, p.badge, 1, p.sort_order);
    }
  }

  // 3. Seed Tournaments across states (Draft, Published, Registration Open, Check-in, Live, Completed)
  const defaultScoring = JSON.stringify({
    placementPoints: { "1": 12, "2": 9, "3": 8, "4": 7, "5": 6, "6": 5, "7": 4, "8": 3, "9": 2, "10": 1 },
    killPoints: 1,
    disqualificationPenalty: -50
  });

  const tournaments = [
    {
      id: 'tour_ff_pro',
      title: 'Free Fire: Apex Champions Cup S4',
      game_id: 'game_ff',
      mode: 'Squad',
      region: 'South Asia',
      banner: 'https://images.unsplash.com/photo-1542751371-adc38448a05e?auto=format&fit=crop&w=1200&q=80',
      description: 'The definitive squad showdown. 48 top squads fight across Bermuda and Kalahari. Official prize distribution with instant wallet payout.',
      entry_fee: 10.0,
      prize_pool: 400.0,
      prize_split: JSON.stringify([
        { place: 1, percent: 50, amount: 200 },
        { place: 2, percent: 30, amount: 120 },
        { place: 3, percent: 20, amount: 80 }
      ]),
      max_slots: 48,
      starts_at: iso(180), // in 3 hours
      registration_closes_at: iso(120), // in 2 hours
      check_in_opens_at: iso(150),
      room_release_at: iso(165), // 15 mins before match
      status: 'Registration Open',
      rules: '1. Emulators strictly prohibited. 2. Mobile phones only. 3. Recording proof required for top 3 placements. 4. Disconnects will not pause the round.'
    },
    {
      id: 'tour_pubg_solo',
      title: 'PUBG Mobile: Erangel Solo Standoff',
      game_id: 'game_pubg',
      mode: 'Solo',
      region: 'Asia Pacific',
      banner: 'https://images.unsplash.com/photo-1511512578047-dfb367046420?auto=format&fit=crop&w=1200&q=80',
      description: 'Single warrior battle. Survival and high kill count dominate the scoring ladder. Free entry for all verified players!',
      entry_fee: 0.0,
      prize_pool: 150.0,
      prize_split: JSON.stringify([
        { place: 1, percent: 60, amount: 90 },
        { place: 2, percent: 25, amount: 37.5 },
        { place: 3, percent: 15, amount: 22.5 }
      ]),
      max_slots: 64,
      starts_at: iso(360), // in 6 hours
      registration_closes_at: iso(300),
      check_in_opens_at: iso(330),
      room_release_at: iso(345),
      status: 'Registration Open',
      rules: '1. Standard Erangel Classic. 2. Flare guns permitted. 3. Teaming up results in immediate disqualification and account ban.'
    },
    {
      id: 'tour_live_showdown',
      title: 'MLBB: Mystic Invitational [LIVE NOW]',
      game_id: 'game_mlbb',
      mode: 'Solo',
      region: 'Southeast Asia',
      banner: 'https://images.unsplash.com/photo-1550745165-9bc0b252726f?auto=format&fit=crop&w=1200&q=80',
      description: 'Mid lane 1v1 mirror tournament. Currently LIVE! Room details available for registered contestants.',
      entry_fee: 5.0,
      prize_pool: 180.0,
      prize_split: JSON.stringify([
        { place: 1, percent: 65, amount: 117 },
        { place: 2, percent: 35, amount: 63 }
      ]),
      max_slots: 32,
      starts_at: iso(-10), // started 10 mins ago
      registration_closes_at: iso(-30),
      check_in_opens_at: iso(-25),
      room_release_at: iso(-20), // room released!
      status: 'Live',
      rules: '1. First blood or first turret win. 2. Mirror pick ban. 3. No jungle creep farming.'
    },
    {
      id: 'tour_completed_val',
      title: 'Valorant: Spike Assault Season 2',
      game_id: 'game_val',
      mode: 'Solo',
      region: 'North America',
      banner: 'https://images.unsplash.com/photo-1563089145-599997674d42?auto=format&fit=crop&w=1200&q=80',
      description: 'Completed tournament with official results approved and audited.',
      entry_fee: 8.0,
      prize_pool: 300.0,
      prize_split: JSON.stringify([
        { place: 1, percent: 60, amount: 180 },
        { place: 2, percent: 30, amount: 90 },
        { place: 3, percent: 10, amount: 30 }
      ]),
      max_slots: 32,
      starts_at: iso(-1440),
      registration_closes_at: iso(-1500),
      check_in_opens_at: iso(-1470),
      room_release_at: iso(-1450),
      status: 'Completed',
      rules: '1. Deathmatch 10-minute cap. 2. Standard weapon loadouts.'
    }
  ];

  const insertTour = db.prepare(`
    INSERT INTO tournaments (
      id, title, game_id, mode, region, banner, description, entry_fee, prize_pool,
      prize_split, max_slots, starts_at, registration_closes_at, check_in_opens_at,
      room_release_at, status, rules, scoring_config, created_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);

  for (const t of tournaments) {
    insertTour.run(
      t.id, t.title, t.game_id, t.mode, t.region, t.banner, t.description,
      t.entry_fee, t.prize_pool, t.prize_split, t.max_slots, t.starts_at,
      t.registration_closes_at, t.check_in_opens_at, t.room_release_at,
      t.status, t.rules, defaultScoring, iso(-720)
    );
  }

  // 4. Seed Matches & Room Secrets
  const insertMatch = db.prepare(`
    INSERT INTO matches (id, tournament_id, round_number, match_code, scheduled_at, status, room_id, room_password, room_secret_reference, created_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);

  // Match for Free Fire (upcoming, room release time in future)
  insertMatch.run(
    'mat_ff_r1',
    'tour_ff_pro',
    1,
    'FF-R1-LOBBY-A',
    iso(180),
    'SCHEDULED',
    'ROOM-99214',
    'ApexPass#77',
    'sec_ff_99214',
    iso(-60)
  );

  // Match for MLBB Live tournament (Room released!)
  insertMatch.run(
    'mat_mlbb_live',
    'tour_live_showdown',
    1,
    'ML-FINALS-01',
    iso(-10),
    'LIVE',
    'CUSTOM-ML-552',
    'Mystic888',
    'sec_mlbb_552',
    iso(-120)
  );

  // Match for completed tournament
  insertMatch.run(
    'mat_val_done',
    'tour_completed_val',
    1,
    'VAL-CHAMP-R1',
    iso(-1440),
    'FINISHED',
    'VAL-CUSTOM-01',
    'GGPass123',
    'sec_val_01',
    iso(-1500)
  );

  // 5. Seed sample registrations for usr_player1 in tour_ff_pro and tour_live_showdown
  const insertReg = db.prepare(`
    INSERT INTO tournament_registrations (id, tournament_id, user_id, team_id, status, entry_payment_ledger_id, receipt_number, registered_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
  `);

  insertReg.run(
    'reg_usr1_ff',
    'tour_ff_pro',
    'usr_player1',
    null,
    'CONFIRMED',
    'led_entry_usr1_ff',
    'RCPT-FF-' + Date.now().toString(36).toUpperCase(),
    iso(-60)
  );

  insertReg.run(
    'reg_usr1_mlbb',
    'tour_live_showdown',
    'usr_player1',
    null,
    'CONFIRMED',
    'led_entry_usr1_mlbb',
    'RCPT-ML-' + Date.now().toString(36).toUpperCase(),
    iso(-100)
  );

  insertReg.run(
    'reg_usr2_ff',
    'tour_ff_pro',
    'usr_player2',
    null,
    'CONFIRMED',
    'led_entry_usr2_ff',
    'RCPT-FF2-' + Date.now().toString(36).toUpperCase(),
    iso(-50)
  );

  // 6. Seed sample match results for completed tournament
  const insertMatchResult = db.prepare(`
    INSERT INTO match_results (id, match_id, user_id, team_id, placement, kills, points, evidence_reference, submitted_by, approved_by, status, created_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);
  insertMatchResult.run(
    'res_1',
    'mat_val_done',
    'usr_player1',
    null,
    1,
    14,
    26.0,
    'https://img.gaming.proof/val_p1.png',
    'usr_operator',
    'usr_tmgr',
    'APPROVED',
    iso(-1400)
  );
  insertMatchResult.run(
    'res_2',
    'mat_val_done',
    'usr_player2',
    null,
    2,
    9,
    18.0,
    'https://img.gaming.proof/val_p2.png',
    'usr_operator',
    'usr_tmgr',
    'APPROVED',
    iso(-1400)
  );

  // 7. Seed sample prize payout for usr_player1
  const insertPayout = db.prepare(`
    INSERT INTO prize_payouts (id, tournament_id, user_id, amount, status, provider_reference, approved_by, dual_approved_by, paid_at, created_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);
  insertPayout.run(
    'pay_val_1st',
    'tour_completed_val',
    'usr_player1',
    180.0,
    'PAID',
    'WAL-LED-PRIZE-VAL',
    'usr_tmgr',
    'usr_finance',
    iso(-1380),
    iso(-1390)
  );

  // 8. Seed sample top-up orders
  const insertOrder = db.prepare(`
    INSERT INTO topup_orders (id, user_id, game_id, package_id, player_details, amount, fee, payment_method, status, idempotency_key, delivery_attempts, created_at, updated_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);

  insertOrder.run(
    'ord_sample_dlv',
    'usr_player1',
    'game_ff',
    'pkg_ff_520',
    JSON.stringify({ player_id: '192837465' }),
    4.89,
    0.0,
    'esewa',
    'DELIVERED',
    'idemp_sample_dlv',
    1,
    iso(-300),
    iso(-298)
  );

  insertOrder.run(
    'ord_sample_proc',
    'usr_player2',
    'game_pubg',
    'pkg_pubg_300',
    JSON.stringify({ player_id: '518392019', server_id: 'ViperKing' }),
    4.89,
    0.0,
    'khalti',
    'PROCESSING',
    'idemp_sample_proc',
    0,
    iso(-15),
    iso(-14)
  );

  // 9. Initial Audit Log
  const insertAudit = db.prepare(`
    INSERT INTO audit_logs (id, actor_id, action, entity_type, entity_id, reason, metadata, created_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
  `);
  insertAudit.run(
    'aud_' + crypto.randomUUID().slice(0, 8),
    'usr_admin',
    'SYSTEM_BOOTSTRAP',
    'system',
    'core',
    'Initial platform configuration & verified seed records',
    JSON.stringify({ version: '1.0.0', specVersion: 'Version 1.0 (11 Oct 2026)' }),
    iso(-1440)
  );
}

function seedAiSubscriptionsIfEmpty() {
  const now = new Date();
  const iso = (offsetMinutes = 0) => new Date(now.getTime() + offsetMinutes * 60000).toISOString();

  // 1. Seed AI tools into topup_games if not present
  const aiTools = [
    {
      id: 'ai_chatgpt',
      name: 'ChatGPT Plus',
      slug: 'chatgpt-plus',
      category: 'AI Subscription',
      icon: '🤖',
      banner: 'https://images.unsplash.com/photo-1677442136019-21780efad99a?auto=format&fit=crop&w=800&q=80',
      active: 1,
      delivery_method: 'auto_api',
      required_player_fields: JSON.stringify([
        { key: 'email', label: 'OpenAI Account Email', regex: '^[^@]+@[^@]+\\.[^@]+$', hint: 'Email linked to your OpenAI account' }
      ]),
      packages: [
        { id: 'pkg_ai_gpt_1m', name: '1 Month Access (GPT-4o & Canvas)', item_quantity: '1 Month', price: 20.0, badge: 'Popular', sort_order: 1 },
        { id: 'pkg_ai_gpt_3m', name: '3 Months Pro Pack', item_quantity: '3 Months', price: 55.0, badge: 'Save 10%', sort_order: 2 },
        { id: 'pkg_ai_gpt_1y', name: '1 Year Annual VIP License', item_quantity: '12 Months', price: 199.0, badge: 'Best Value', sort_order: 3 }
      ]
    },
    {
      id: 'ai_claude',
      name: 'Claude Pro',
      slug: 'claude-pro',
      category: 'AI Subscription',
      icon: '🧠',
      banner: 'https://images.unsplash.com/photo-1620712943543-bcc4688e7485?auto=format&fit=crop&w=800&q=80',
      active: 1,
      delivery_method: 'auto_api',
      required_player_fields: JSON.stringify([
        { key: 'email', label: 'Anthropic Account Email', regex: '^[^@]+@[^@]+\\.[^@]+$', hint: 'Email linked to your Claude account' }
      ]),
      packages: [
        { id: 'pkg_ai_claude_1m', name: '1 Month Pro (Sonnet 3.5 & 200k Context)', item_quantity: '1 Month', price: 20.0, badge: 'Developer Choice', sort_order: 1 },
        { id: 'pkg_ai_claude_3m', name: '3 Months Pro Pack', item_quantity: '3 Months', price: 55.0, badge: 'Save 10%', sort_order: 2 }
      ]
    },
    {
      id: 'ai_midjourney',
      name: 'Midjourney Pro',
      slug: 'midjourney-pro',
      category: 'AI Subscription',
      icon: '🎨',
      banner: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?auto=format&fit=crop&w=800&q=80',
      active: 1,
      delivery_method: 'auto_api',
      required_player_fields: JSON.stringify([
        { key: 'email', label: 'Discord / Midjourney Email', regex: '^[^@]+@[^@]+\\.[^@]+$', hint: 'Email or Discord linked to account' }
      ]),
      packages: [
        { id: 'pkg_ai_mj_basic', name: 'Basic Plan (200 Fast GPU Min)', item_quantity: '1 Month', price: 10.0, badge: null, sort_order: 1 },
        { id: 'pkg_ai_mj_standard', name: 'Standard Plan (15h Fast GPU)', item_quantity: '1 Month', price: 30.0, badge: 'Popular', sort_order: 2 },
        { id: 'pkg_ai_mj_pro', name: 'Pro Plan (30h Fast GPU + Stealth)', item_quantity: '1 Month', price: 60.0, badge: 'Studio Choice', sort_order: 3 }
      ]
    },
    {
      id: 'ai_cursor',
      name: 'Cursor Pro',
      slug: 'cursor-pro',
      category: 'AI Subscription',
      icon: '💻',
      banner: 'https://images.unsplash.com/photo-1555066931-4365d14bab8c?auto=format&fit=crop&w=800&q=80',
      active: 1,
      delivery_method: 'auto_api',
      required_player_fields: JSON.stringify([
        { key: 'email', label: 'Cursor Account Email', regex: '^[^@]+@[^@]+\\.[^@]+$', hint: 'Your Cursor registered email' }
      ]),
      packages: [
        { id: 'pkg_ai_cursor_1m', name: '1 Month Pro (Unlimited Tab & Claude 3.5)', item_quantity: '1 Month', price: 20.0, badge: 'Hot Deal', sort_order: 1 },
        { id: 'pkg_ai_cursor_1y', name: '1 Year Pro License', item_quantity: '12 Months', price: 192.0, badge: 'Save 20%', sort_order: 2 }
      ]
    },
    {
      id: 'ai_perplexity',
      name: 'Perplexity Pro',
      slug: 'perplexity-pro',
      category: 'AI Subscription',
      icon: '🔍',
      banner: 'https://images.unsplash.com/photo-1507238691740-187a5b1d37b8?auto=format&fit=crop&w=800&q=80',
      active: 1,
      delivery_method: 'auto_api',
      required_player_fields: JSON.stringify([
        { key: 'email', label: 'Perplexity Account Email', regex: '^[^@]+@[^@]+\\.[^@]+$', hint: 'Email for Pro Search activation' }
      ]),
      packages: [
        { id: 'pkg_ai_perp_1m', name: '1 Month Pro (GPT-4o & Claude 3.5 Sonnet)', item_quantity: '1 Month', price: 20.0, badge: 'Search AI', sort_order: 1 }
      ]
    },
    {
      id: 'ai_copilot',
      name: 'GitHub Copilot',
      slug: 'github-copilot',
      category: 'AI Subscription',
      icon: '🐙',
      banner: 'https://images.unsplash.com/photo-1618401471353-b98afee0b2eb?auto=format&fit=crop&w=800&q=80',
      active: 1,
      delivery_method: 'auto_api',
      required_player_fields: JSON.stringify([
        { key: 'email', label: 'GitHub Username / Email', regex: '^.+$', hint: 'GitHub account to provision license' }
      ]),
      packages: [
        { id: 'pkg_ai_copilot_1m', name: '1 Month Individual Plan', item_quantity: '1 Month', price: 10.0, badge: null, sort_order: 1 },
        { id: 'pkg_ai_copilot_1y', name: '1 Year Individual Plan', item_quantity: '12 Months', price: 100.0, badge: 'Save $20', sort_order: 2 }
      ]
    }
  ];

  const insertGame = db.prepare(`
    INSERT OR IGNORE INTO topup_games (id, name, slug, category, icon, banner, active, delivery_method, required_player_fields)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);
  const insertPkg = db.prepare(`
    INSERT OR IGNORE INTO topup_packages (id, game_id, name, item_quantity, price, badge, active, sort_order)
    VALUES (?, ?, ?, ?, ?, ?, 1, ?)
  `);

  for (const t of aiTools) {
    insertGame.run(t.id, t.name, t.slug, t.category, t.icon, t.banner, t.active, t.delivery_method, t.required_player_fields);
    for (const p of t.packages) {
      insertPkg.run(p.id, t.id, p.name, p.item_quantity, p.price, p.badge, p.sort_order);
    }
  }

  // 2. Seed AI Subscriptions if table is empty
  const subCount = db.prepare('SELECT COUNT(*) as count FROM ai_subscriptions').get().count;
  if (subCount === 0) {
    const insertSub = db.prepare(`
      INSERT INTO ai_subscriptions (id, user_id, tool_id, tool_name, plan_name, account_email, license_key, status, billing_cycle, amount, starts_at, expires_at, auto_renew, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `);

    insertSub.run(
      'sub_gpt_1',
      'usr_player1',
      'ai_chatgpt',
      'ChatGPT Plus',
      '1 Month Access (GPT-4o & Canvas)',
      'phoenix@gamer.io',
      'GPT4-PLUS-7782-9912',
      'ACTIVE',
      'monthly',
      20.0,
      iso(-2880),
      iso(40320), // expires in 28 days
      1,
      iso(-2880),
      iso(-2880)
    );

    insertSub.run(
      'sub_claude_1',
      'usr_player1',
      'ai_claude',
      'Claude Pro',
      '1 Month Pro (Sonnet 3.5 & 200k Context)',
      'phoenix@gamer.io',
      'CLAUDE-PRO-8812-4410',
      'ACTIVE',
      'monthly',
      20.0,
      iso(-8640),
      iso(34560), // expires in 24 days
      1,
      iso(-8640),
      iso(-8640)
    );

    insertSub.run(
      'sub_cursor_1',
      'usr_player2',
      'ai_cursor',
      'Cursor Pro',
      '1 Month Pro (Unlimited Tab & Claude 3.5)',
      'viper@gamer.io',
      null,
      'PENDING_ACTIVATION',
      'monthly',
      20.0,
      iso(-120),
      iso(43200),
      1,
      iso(-120),
      iso(-120)
    );

    insertSub.run(
      'sub_mj_1',
      'usr_player3',
      'ai_midjourney',
      'Midjourney Pro',
      'Standard Plan (15h Fast GPU)',
      'ninja@gamer.io',
      'MJ-STD-5541-2098',
      'ACTIVE',
      'monthly',
      30.0,
      iso(-20160),
      iso(23040), // expires in 16 days
      1,
      iso(-20160),
      iso(-20160)
    );
  }

  // 3. Seed AI Vault License Keys if empty
  const keyCount = db.prepare('SELECT COUNT(*) as count FROM ai_license_keys').get().count;
  if (keyCount === 0) {
    const insertKey = db.prepare(`
      INSERT INTO ai_license_keys (id, tool_id, tool_name, license_code, status, assigned_to_user_id, assigned_order_id, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `);

    insertKey.run('key_gpt_1', 'ai_chatgpt', 'ChatGPT Plus', 'GPT4-VAULT-AA192-K89', 'AVAILABLE', null, null, iso(-1440));
    insertKey.run('key_gpt_2', 'ai_chatgpt', 'ChatGPT Plus', 'GPT4-VAULT-BB441-X12', 'AVAILABLE', null, null, iso(-1440));
    insertKey.run('key_claude_1', 'ai_claude', 'Claude Pro', 'CLAUDE-VAULT-9912-P33', 'AVAILABLE', null, null, iso(-1440));
    insertKey.run('key_claude_2', 'ai_claude', 'Claude Pro', 'CLAUDE-VAULT-8831-Q47', 'AVAILABLE', null, null, iso(-1440));
    insertKey.run('key_cursor_1', 'ai_cursor', 'Cursor Pro', 'CURSOR-PRO-KEY-0091-DEV', 'AVAILABLE', null, null, iso(-1440));
    insertKey.run('key_cursor_2', 'ai_cursor', 'Cursor Pro', 'CURSOR-PRO-KEY-7714-PRO', 'AVAILABLE', null, null, iso(-1440));
    insertKey.run('key_mj_1', 'ai_midjourney', 'Midjourney Pro', 'MJ-PRO-VAULT-1149-FAST', 'AVAILABLE', null, null, iso(-1440));
    insertKey.run('key_copilot_1', 'ai_copilot', 'GitHub Copilot', 'COPILOT-INDIV-6671-GH', 'AVAILABLE', null, null, iso(-1440));
  }
}

function ensureMasterAdmins() {
  const masterAdmins = [
    { id: 'usr_admin', name: 'Aegis_Root', email: 'admin@platform.io', balance: 1000.0 },
    { id: 'usr_mrpr0', name: 'MrPr0C0dss', email: 'mrpr0c0dss@gmail.com', balance: 2500.0 }
  ];

  const now = new Date().toISOString();
  for (const m of masterAdmins) {
    const existing = db.prepare('SELECT * FROM users WHERE email = ?').get(m.email);
    if (!existing) {
      db.prepare(`
        INSERT INTO users (id, display_name, email, phone, role, status, avatar, created_at)
        VALUES (?, ?, ?, ?, 'super_admin', 'active', ?, ?)
      `).run(m.id, m.name, m.email, '+977-9800000000', `https://api.dicebear.com/7.x/bottts/svg?seed=${m.id}`, now);

      db.prepare(`
        INSERT INTO wallets (user_id, currency, available_balance, locked_balance, updated_at)
        VALUES (?, 'USD', ?, 0.0, ?)
      `).run(m.id, m.balance, now);
    } else if (existing.role !== 'super_admin') {
      db.prepare("UPDATE users SET role = 'super_admin' WHERE id = ?").run(existing.id);
    }
  }
}

function seedRobloxIfEmpty() {
  const existing = db.prepare('SELECT id FROM topup_games WHERE id = ?').get('game_roblox');
  if (!existing) {
    db.prepare(`
      INSERT INTO topup_games (id, name, slug, category, icon, banner, active, delivery_method, required_player_fields)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).run(
      'game_roblox',
      'Roblox',
      'roblox',
      'Sandbox / Adventure',
      '🧱',
      '/assets/games/roblox.webp',
      1,
      'auto_api',
      JSON.stringify([
        { key: 'player_id', label: 'Roblox Username', regex: '^[a-zA-Z0-9_]{3,20}$', hint: 'Your Roblox Username (e.g. Builderman)' }
      ])
    );

    const insertPkg = db.prepare(`
      INSERT OR IGNORE INTO topup_packages (id, game_id, name, item_quantity, price, badge, active, sort_order)
      VALUES (?, ?, ?, ?, ?, ?, 1, ?)
    `);

    const packages = [
      { id: 'pkg_rbx_80', name: '80 Robux', item_quantity: '80 R$', price: 0.99, badge: null, sort_order: 1 },
      { id: 'pkg_rbx_400', name: '400 Robux', item_quantity: '400 R$', price: 4.89, badge: 'Popular', sort_order: 2 },
      { id: 'pkg_rbx_800', name: '800 Robux', item_quantity: '800 R$', price: 9.79, badge: 'Best Value', sort_order: 3 },
      { id: 'pkg_rbx_1700', name: '1,700 Robux', item_quantity: '1,700 R$', price: 19.49, badge: '+10% Bonus', sort_order: 4 },
      { id: 'pkg_rbx_4500', name: '4,500 Robux', item_quantity: '4,500 R$', price: 48.99, badge: 'Pro Gamer', sort_order: 5 },
      { id: 'pkg_rbx_premium', name: 'Roblox Premium 450', item_quantity: 'Monthly VIP', price: 4.99, badge: 'VIP Pass', sort_order: 6 }
    ];

    for (const p of packages) {
      insertPkg.run(p.id, 'game_roblox', p.name, p.item_quantity, p.price, p.badge, p.sort_order);
    }
  }
}

initSchema();
seedDatabase();
seedAiSubscriptionsIfEmpty();
seedRobloxIfEmpty();
ensureMasterAdmins();

module.exports = {
  db,
  initSchema,
  seedAiSubscriptionsIfEmpty,
  seedRobloxIfEmpty,
  ensureMasterAdmins
};
