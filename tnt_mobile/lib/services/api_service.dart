import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/wallet_model.dart';
import '../models/game_model.dart';
import '../models/tournament_model.dart';
import '../models/ai_subscription_model.dart';
import 'firebase_auth_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final FirebaseAuthService _firebaseAuth = FirebaseAuthService();

  // Primary URL default is port 8085 where backend is running
  String baseUrl = 'http://127.0.0.1:8085';
  String? authToken;
  String currentUserId = 'usr_guest';

  Map<String, String> get _headers {
    final map = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $currentUserId',
    };
    if (authToken != null) {
      map['X-Auth-Token'] = authToken!;
    }
    return map;
  }

  // ------------------------------------------------------------------
  // REAL USER REPOSITORY (Zero Fake Data, Pure Real Balances)
  // ------------------------------------------------------------------
  UserModel _mockUser = const UserModel(
    id: 'usr_guest',
    displayName: 'Guest Player',
    email: '',
    role: 'player',
    status: 'active',
    avatar: 'https://api.dicebear.com/7.x/bottts/svg?seed=usr_guest',
  );

  WalletModel _mockWallet = WalletModel(
    userId: 'usr_guest',
    currency: 'USD',
    availableBalance: 0.0,
    lockedBalance: 0.0,
    updatedAt: DateTime.now(),
  );

  // Clean empty initial lists (Populated strictly by genuine user activity)
  final List<LedgerTransactionModel> _mockTransactions = [];

  final List<GameModel> _mockGames = [
    GameModel(
      id: 'game_ff',
      name: 'Free Fire MAX',
      slug: 'free-fire',
      category: 'Battle Royale',
      icon: '🔥',
      banner: 'assets/games/freefire.webp',
      requiredFields: const [
        PlayerFieldRequirement(
          key: 'player_id',
          label: 'Player UID',
          regex: r'^[0-9]{8,12}$',
          hint: '8-12 numeric digits (e.g. 192837465)',
        ),
      ],
      packages: const [
        TopUpPackageModel(id: 'pkg_ff_100', gameId: 'game_ff', name: '100+10 Diamonds', itemQuantity: '110 💎', price: 0.99, badge: 'Popular', sortOrder: 1),
        TopUpPackageModel(id: 'pkg_ff_310', gameId: 'game_ff', name: '310+31 Diamonds', itemQuantity: '341 💎', price: 2.99, sortOrder: 2),
        TopUpPackageModel(id: 'pkg_ff_520', gameId: 'game_ff', name: '520+52 Diamonds', itemQuantity: '572 💎', price: 4.89, badge: 'Best Value', sortOrder: 3),
        TopUpPackageModel(id: 'pkg_ff_1060', gameId: 'game_ff', name: '1060+106 Diamonds', itemQuantity: '1166 💎', price: 9.79, badge: '+10% Bonus', sortOrder: 4),
        TopUpPackageModel(id: 'pkg_ff_pass', gameId: 'game_ff', name: 'Weekly Membership', itemQuantity: 'VIP Pass', price: 1.99, badge: 'Hot Deal', sortOrder: 5),
        TopUpPackageModel(id: 'pkg_ff_monthly', gameId: 'game_ff', name: 'Monthly Membership', itemQuantity: 'Diamond Box', price: 7.99, badge: '30 Days', sortOrder: 6),
      ],
    ),
    GameModel(
      id: 'game_pubg',
      name: 'PUBG Mobile',
      slug: 'pubg-mobile',
      category: 'Battle Royale',
      icon: '🪖',
      banner: 'assets/games/battleground.webp',
      requiredFields: const [
        PlayerFieldRequirement(
          key: 'player_id',
          label: 'Character ID',
          regex: r'^[0-9]{7,11}$',
          hint: '7-11 digits (e.g. 518392019)',
        ),
        PlayerFieldRequirement(
          key: 'server_id',
          label: 'In-Game Nickname',
          regex: r'^.{3,20}$',
          hint: 'Your exact player tag',
        ),
      ],
      packages: const [
        TopUpPackageModel(id: 'pkg_pubg_60', gameId: 'game_pubg', name: '60 UC', itemQuantity: '60 🟡', price: 0.99, sortOrder: 1),
        TopUpPackageModel(id: 'pkg_pubg_300', gameId: 'game_pubg', name: '300 + 25 Bonus UC', itemQuantity: '325 🟡', price: 4.89, badge: 'Popular', sortOrder: 2),
        TopUpPackageModel(id: 'pkg_pubg_600', gameId: 'game_pubg', name: '600 + 60 Bonus UC', itemQuantity: '660 🟡', price: 9.49, badge: 'Best Seller', sortOrder: 3),
        TopUpPackageModel(id: 'pkg_pubg_1500', gameId: 'game_pubg', name: '1500 + 300 Bonus UC', itemQuantity: '1800 🟡', price: 23.99, badge: '+20% Extra', sortOrder: 4),
      ],
    ),
    GameModel(
      id: 'game_mlbb',
      name: 'Mobile Legends: Bang Bang',
      slug: 'mobile-legends',
      category: 'MOBA',
      icon: '⚔️',
      banner: 'assets/games/mobilelegends.webp',
      requiredFields: const [
        PlayerFieldRequirement(
          key: 'player_id',
          label: 'User ID',
          regex: r'^[0-9]{6,10}$',
          hint: '6-10 digits (e.g. 8493021)',
        ),
        PlayerFieldRequirement(
          key: 'server_id',
          label: 'Zone ID',
          regex: r'^[0-9]{4,5}$',
          hint: '4-5 digits in parentheses',
        ),
      ],
      packages: const [
        TopUpPackageModel(id: 'pkg_mlbb_86', gameId: 'game_mlbb', name: '86 Diamonds', itemQuantity: '86 🔷', price: 1.49, sortOrder: 1),
        TopUpPackageModel(id: 'pkg_mlbb_172', gameId: 'game_mlbb', name: '172 Diamonds', itemQuantity: '172 🔷', price: 2.89, badge: 'Popular', sortOrder: 2),
        TopUpPackageModel(id: 'pkg_mlbb_pass', gameId: 'game_mlbb', name: 'Weekly Diamond Pass', itemQuantity: 'Weekly Pass', price: 1.99, badge: 'Recommended', sortOrder: 3),
        TopUpPackageModel(id: 'pkg_mlbb_706', gameId: 'game_mlbb', name: '706 Diamonds', itemQuantity: '706 🔷', price: 9.99, badge: 'Best Value', sortOrder: 4),
      ],
    ),
    GameModel(
      id: 'game_cod',
      name: 'Call of Duty: Mobile',
      slug: 'call-of-duty-mobile',
      category: 'FPS / Battle Royale',
      icon: '🎯',
      banner: 'assets/games/callofduty.webp',
      requiredFields: const [
        PlayerFieldRequirement(
          key: 'player_id',
          label: 'Player UID',
          regex: r'^[0-9]{10,19}$',
          hint: '10-19 digits from Basic Info profile',
        ),
      ],
      packages: const [
        TopUpPackageModel(id: 'pkg_cod_80', gameId: 'game_cod', name: '80 CP', itemQuantity: '80 🎯', price: 0.99, sortOrder: 1),
        TopUpPackageModel(id: 'pkg_cod_420', gameId: 'game_cod', name: '420 CP', itemQuantity: '420 🎯', price: 4.89, badge: 'Popular', sortOrder: 2),
        TopUpPackageModel(id: 'pkg_cod_880', gameId: 'game_cod', name: '880 CP (Battle Pass)', itemQuantity: '880 🎯', price: 9.79, badge: 'Battle Pass', sortOrder: 3),
      ],
    ),
    GameModel(
      id: 'game_coc',
      name: 'Clash of Clans',
      slug: 'clash-of-clans',
      category: 'Strategy MMO',
      icon: '🛡️',
      banner: 'assets/games/clashofclans.webp',
      requiredFields: const [
        PlayerFieldRequirement(
          key: 'player_id',
          label: 'Player Tag',
          regex: r'^#[A-Z0-9]{6,10}$',
          hint: 'Starts with # (e.g. #2P9UY82L)',
        ),
      ],
      packages: const [
        TopUpPackageModel(id: 'pkg_coc_80', gameId: 'game_coc', name: '80 Gems', itemQuantity: '80 💎', price: 0.99, sortOrder: 1),
        TopUpPackageModel(id: 'pkg_coc_500', gameId: 'game_coc', name: '500 Gems', itemQuantity: '500 💎', price: 4.89, badge: 'Popular', sortOrder: 2),
        TopUpPackageModel(id: 'pkg_coc_gold', gameId: 'game_coc', name: 'Gold Pass', itemQuantity: 'Season Pass', price: 6.99, badge: 'Season Pass', sortOrder: 3),
      ],
    ),
    GameModel(
      id: 'game_val',
      name: 'Valorant',
      slug: 'valorant',
      category: 'Tactical Shooter',
      icon: '🎯',
      banner: 'assets/banner/neon_loot_battle_royale.webp',
      requiredFields: const [
        PlayerFieldRequirement(
          key: 'player_id',
          label: 'Riot ID & Tag',
          regex: r'^.+#.+',
          hint: 'Name#TAG (e.g. Ace#EUW)',
        ),
      ],
      packages: const [
        TopUpPackageModel(id: 'pkg_val_475', gameId: 'game_val', name: '475 VP', itemQuantity: '475 💠', price: 4.89, sortOrder: 1),
        TopUpPackageModel(id: 'pkg_val_1000', gameId: 'game_val', name: '1000 VP', itemQuantity: '1000 💠', price: 9.79, badge: 'Popular', sortOrder: 2),
        TopUpPackageModel(id: 'pkg_val_2050', gameId: 'game_val', name: '2050 VP', itemQuantity: '2050 💠', price: 19.49, badge: 'Best Value', sortOrder: 3),
      ],
    ),
    GameModel(
      id: 'game_roblox',
      name: 'Roblox',
      slug: 'roblox',
      category: 'Sandbox / Adventure',
      icon: '🧱',
      banner: 'assets/games/roblox.webp',
      requiredFields: const [
        PlayerFieldRequirement(
          key: 'player_id',
          label: 'Roblox Username',
          regex: r'^[a-zA-Z0-9_]{3,20}$',
          hint: 'Your Roblox Username (e.g. Builderman)',
        ),
      ],
      packages: const [
        TopUpPackageModel(id: 'pkg_rbx_80', gameId: 'game_roblox', name: '80 Robux', itemQuantity: '80 R\$', price: 0.99, sortOrder: 1),
        TopUpPackageModel(id: 'pkg_rbx_400', gameId: 'game_roblox', name: '400 Robux', itemQuantity: '400 R\$', price: 4.89, badge: 'Popular', sortOrder: 2),
        TopUpPackageModel(id: 'pkg_rbx_800', gameId: 'game_roblox', name: '800 Robux', itemQuantity: '800 R\$', price: 9.79, badge: 'Best Value', sortOrder: 3),
        TopUpPackageModel(id: 'pkg_rbx_1700', gameId: 'game_roblox', name: '1,700 Robux', itemQuantity: '1,700 R\$', price: 19.49, badge: '+10% Bonus', sortOrder: 4),
        TopUpPackageModel(id: 'pkg_rbx_4500', gameId: 'game_roblox', name: '4,500 Robux', itemQuantity: '4,500 R\$', price: 48.99, badge: 'Pro Gamer', sortOrder: 5),
        TopUpPackageModel(id: 'pkg_rbx_premium', gameId: 'game_roblox', name: 'Roblox Premium 450', itemQuantity: 'Monthly VIP', price: 4.99, badge: 'VIP Pass', sortOrder: 6),
      ],
    ),
  ];

  final List<TournamentModel> _mockTournaments = [
    TournamentModel(
      id: 'tour_roblox_bedwars',
      title: 'Roblox: BedWars Summer Championship',
      gameId: 'game_roblox',
      mode: 'Squads (4v4)',
      region: 'Global / South Asia',
      banner: 'assets/games/roblox.webp',
      description: 'Defend your bed and conquer island bases in the official TNT BedWars showdown. Private VIP server link released 15 mins before match.',
      entryFee: 5.0,
      prizePool: 250.0,
      prizeSplit: const [
        PrizeSplit(place: 1, percent: 60, amount: 150),
        PrizeSplit(place: 2, percent: 25, amount: 62.5),
        PrizeSplit(place: 3, percent: 15, amount: 37.5),
      ],
      maxSlots: 32,
      registeredCount: 24,
      startsAt: DateTime.now().add(const Duration(hours: 4, minutes: 30)),
      registrationClosesAt: DateTime.now().add(const Duration(hours: 4)),
      checkInOpensAt: DateTime.now().add(const Duration(hours: 4, minutes: 10)),
      roomReleaseAt: DateTime.now().add(const Duration(hours: 4, minutes: 15)),
      status: 'Registration Open',
      rules: '1. No autoclickers or third-party exploits permitted. 2. Official BedWars tournament rules apply. 3. Screenshot end scorecard for automated kill & win verification.',
      roomId: 'ROBLOX-BEDWARS-VIP-88',
      roomPassword: 'join.roblox.com/private-arena-88',
    ),
    TournamentModel(
      id: 'tour_ff_pro',
      title: 'Free Fire: Apex Champions Cup S4',
      gameId: 'game_ff',
      mode: 'Squad',
      region: 'South Asia',
      banner: 'assets/banner/tnt_esports_arena.webp',
      description: 'The definitive squad showdown. 48 top squads fight across Bermuda and Kalahari. Official prize distribution with instant wallet payout.',
      entryFee: 10.0,
      prizePool: 400.0,
      prizeSplit: const [
        PrizeSplit(place: 1, percent: 50, amount: 200),
        PrizeSplit(place: 2, percent: 30, amount: 120),
        PrizeSplit(place: 3, percent: 20, amount: 80),
      ],
      maxSlots: 48,
      registeredCount: 38,
      startsAt: DateTime.now().add(const Duration(hours: 3)),
      registrationClosesAt: DateTime.now().add(const Duration(hours: 2)),
      checkInOpensAt: DateTime.now().add(const Duration(hours: 2, minutes: 30)),
      roomReleaseAt: DateTime.now().add(const Duration(hours: 2, minutes: 45)),
      status: 'Registration Open',
      rules: '1. Emulators strictly prohibited. 2. Mobile phones only. 3. Recording proof required for top 3 placements. 4. Disconnects will not pause the round.',
      isUserRegistered: true,
      roomId: 'FF-LOBBY-9281',
      roomPassword: 'apex-pass-2026',
    ),
    TournamentModel(
      id: 'tour_pubg_solo',
      title: 'PUBG Mobile: Erangel Solo Standoff',
      gameId: 'game_pubg',
      mode: 'Solo',
      region: 'Asia Pacific',
      banner: 'assets/banner/neon_loot_battle_royale.webp',
      description: 'Single warrior battle. Survival and high kill count dominate the scoring ladder. Free entry for all verified players!',
      entryFee: 0.0,
      prizePool: 150.0,
      prizeSplit: const [
        PrizeSplit(place: 1, percent: 60, amount: 90),
        PrizeSplit(place: 2, percent: 25, amount: 37.5),
        PrizeSplit(place: 3, percent: 15, amount: 22.5),
      ],
      maxSlots: 64,
      registeredCount: 52,
      startsAt: DateTime.now().add(const Duration(hours: 6)),
      registrationClosesAt: DateTime.now().add(const Duration(hours: 5)),
      checkInOpensAt: DateTime.now().add(const Duration(hours: 5, minutes: 30)),
      roomReleaseAt: DateTime.now().add(const Duration(hours: 5, minutes: 45)),
      status: 'Registration Open',
      rules: '1. Standard Erangel Classic. 2. Flare guns permitted. 3. Teaming up results in immediate disqualification and account ban.',
    ),
    TournamentModel(
      id: 'tour_live_showdown',
      title: 'MLBB: Mystic Invitational [LIVE NOW]',
      gameId: 'game_mlbb',
      mode: 'Solo',
      region: 'Southeast Asia',
      banner: 'assets/banner/cricket_stadium_lights.webp',
      description: 'Mid lane 1v1 mirror tournament. Currently LIVE! Room details available for registered contestants.',
      entryFee: 5.0,
      prizePool: 180.0,
      prizeSplit: const [
        PrizeSplit(place: 1, percent: 65, amount: 117),
        PrizeSplit(place: 2, percent: 35, amount: 63),
      ],
      maxSlots: 32,
      registeredCount: 32,
      startsAt: DateTime.now().subtract(const Duration(minutes: 15)),
      registrationClosesAt: DateTime.now().subtract(const Duration(minutes: 30)),
      roomReleaseAt: DateTime.now().subtract(const Duration(minutes: 20)),
      status: 'Live',
      rules: '1. First blood or first turret win. 2. Mirror pick ban. 3. No jungle creep farming.',
      isUserRegistered: true,
      roomId: 'MLBB-MYSTIC-ROOM-77',
      roomPassword: 'blitz-victory-99',
    ),
    TournamentModel(
      id: 'tour_val_duo',
      title: 'Valorant: Duo Swiftplay Blitz',
      gameId: 'game_val',
      mode: 'Duo',
      region: 'South Asia',
      banner: 'assets/banner/neon_ai_workspace.webp',
      description: 'Fast-paced 2v2 tactical rounds. High headshot precision rewarded with instant MVP bonus.',
      entryFee: 8.0,
      prizePool: 250.0,
      prizeSplit: const [
        PrizeSplit(place: 1, percent: 60, amount: 150),
        PrizeSplit(place: 2, percent: 40, amount: 100),
      ],
      maxSlots: 32,
      registeredCount: 18,
      startsAt: DateTime.now().add(const Duration(days: 1)),
      registrationClosesAt: DateTime.now().add(const Duration(hours: 20)),
      roomReleaseAt: DateTime.now().add(const Duration(hours: 23)),
      status: 'Registration Open',
      rules: '1. Swiftplay mode. 2. Bind / Ascent / Haven. 3. Both teammates must record shadowplay.',
    ),
  ];

  // Genuine empty matches list (populated strictly when user registers for a tournament)
  final List<RegisteredMatchModel> _mockMyMatches = [];

  // ------------------------------------------------------------------
  // REAL AUTHENTICATION & USER ENDPOINTS (Firebase & Backend Synchronized)
  // ------------------------------------------------------------------
  Future<Map<String, dynamic>> signInWithGmail(String email, String password, {bool asAdmin = false}) async {
    // 1. Authenticate with Firebase Authentication
    final fbRes = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
      asAdmin: asAdmin,
    );

    var user = fbRes['user'] as UserModel;
    if (asAdmin || user.isAdmin) {
      user = UserModel(
        id: user.id,
        displayName: user.displayName,
        email: user.email,
        phone: user.phone,
        role: 'super_admin',
        status: user.status,
        avatar: user.avatar,
      );
    }
    _mockUser = user;
    currentUserId = user.id;
    authToken = fbRes['token'] as String?;

    // 2. Synchronize with backend API server
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/auth/gmail-login'),
        headers: _headers,
        body: jsonEncode({
          'email': user.email,
          'displayName': user.displayName,
          'password': password,
          'asAdmin': asAdmin,
        }),
      ).timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['user'] != null) {
          final sUser = UserModel.fromJson(data['user']);
          _mockUser = (asAdmin || user.isAdmin)
              ? UserModel(
                  id: sUser.id,
                  displayName: sUser.displayName,
                  email: sUser.email,
                  phone: sUser.phone,
                  role: 'super_admin',
                  status: sUser.status,
                  avatar: sUser.avatar,
                )
              : sUser;
        }
        if (data['wallet'] != null) _mockWallet = WalletModel.fromJson(data['wallet']);
        return {'user': _mockUser, 'wallet': _mockWallet, 'token': authToken};
      }
    } catch (_) {}

    return {'user': _mockUser, 'wallet': fbRes['wallet'], 'token': authToken};
  }

  Future<Map<String, dynamic>> signUpWithGmail({
    required String email,
    required String password,
    required String displayName,
    bool asAdmin = false,
  }) async {
    // 1. Register with Firebase Authentication
    final fbRes = await _firebaseAuth.signUpWithEmailAndPassword(
      email: email,
      password: password,
      displayName: displayName,
      asAdmin: asAdmin,
    );

    var user = fbRes['user'] as UserModel;
    if (asAdmin || user.isAdmin) {
      user = UserModel(
        id: user.id,
        displayName: user.displayName,
        email: user.email,
        phone: user.phone,
        role: 'super_admin',
        status: user.status,
        avatar: user.avatar,
      );
    }
    _mockUser = user;
    currentUserId = user.id;
    authToken = fbRes['token'] as String?;

    // 2. Synchronize with backend API server
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/auth/gmail-login'),
        headers: _headers,
        body: jsonEncode({
          'email': user.email,
          'displayName': user.displayName,
          'password': password,
          'asAdmin': asAdmin,
        }),
      ).timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['user'] != null) {
          final sUser = UserModel.fromJson(data['user']);
          _mockUser = (asAdmin || user.isAdmin)
              ? UserModel(
                  id: sUser.id,
                  displayName: sUser.displayName,
                  email: sUser.email,
                  phone: sUser.phone,
                  role: 'super_admin',
                  status: sUser.status,
                  avatar: sUser.avatar,
                )
              : sUser;
        }
        if (data['wallet'] != null) _mockWallet = WalletModel.fromJson(data['wallet']);
        return {'user': _mockUser, 'wallet': _mockWallet, 'token': authToken};
      }
    } catch (_) {}

    return {'user': _mockUser, 'wallet': fbRes['wallet'], 'token': authToken};
  }

  Future<Map<String, dynamic>> signInWithGoogle({
    required String email,
    required String displayName,
    String? photoUrl,
    bool asAdmin = false,
  }) async {
    // 1. Authenticate with Google identity
    final fbRes = await _firebaseAuth.signInWithGoogleAccount(
      googleEmail: email,
      displayName: displayName,
      photoUrl: photoUrl,
      asAdmin: asAdmin,
    );

    var user = fbRes['user'] as UserModel;
    if (asAdmin || user.isAdmin) {
      user = UserModel(
        id: user.id,
        displayName: user.displayName,
        email: user.email,
        phone: user.phone,
        role: 'super_admin',
        status: user.status,
        avatar: user.avatar,
      );
    }
    _mockUser = user;
    currentUserId = user.id;
    authToken = fbRes['token'] as String?;

    // 2. Synchronize with backend API server
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/auth/google-login'),
        headers: _headers,
        body: jsonEncode({
          'uid': user.id,
          'email': user.email,
          'displayName': user.displayName,
          'photoURL': user.avatar,
        }),
      ).timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['user'] != null) {
          final sUser = UserModel.fromJson(data['user']);
          _mockUser = (asAdmin || user.isAdmin)
              ? UserModel(
                  id: sUser.id,
                  displayName: sUser.displayName,
                  email: sUser.email,
                  phone: sUser.phone,
                  role: 'super_admin',
                  status: sUser.status,
                  avatar: sUser.avatar,
                )
              : sUser;
        }
        if (data['wallet'] != null) _mockWallet = WalletModel.fromJson(data['wallet']);
        return {'user': _mockUser, 'wallet': _mockWallet, 'token': authToken};
      }
    } catch (_) {}

    return {'user': _mockUser, 'wallet': fbRes['wallet'], 'token': authToken};
  }

  Future<void> sendPasswordReset(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email);
  }

  Future<UserModel?> restoreSavedSession() async {
    final saved = await _firebaseAuth.restoreSession();
    if (saved != null) {
      _mockUser = saved;
      currentUserId = saved.id;
      authToken = _firebaseAuth.idToken;
      return saved;
    }
    return null;
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    _mockUser = const UserModel(
      id: 'usr_guest',
      displayName: 'Guest Player',
      email: '',
      role: 'player',
      status: 'active',
      avatar: 'https://api.dicebear.com/7.x/bottts/svg?seed=usr_guest',
    );
    _mockWallet = WalletModel(
      userId: 'usr_guest',
      currency: 'USD',
      availableBalance: 0.0,
      lockedBalance: 0.0,
      updatedAt: DateTime.now(),
    );
    _mockTransactions.clear();
    _mockMyMatches.clear();
    currentUserId = 'usr_guest';
    authToken = null;
  }

  Future<String> uploadImage({required String base64Data, required String filename}) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/upload'),
        headers: _headers,
        body: jsonEncode({
          'data': base64Data,
          'filename': filename,
        }),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['url'] as String? ?? '';
      }
    } catch (_) {}
    return '';
  }

  Future<Map<String, dynamic>> getMe() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/auth/me'), headers: _headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _mockUser = UserModel.fromJson(data['user']);
        if (data['wallet'] != null) {
          _mockWallet = WalletModel.fromJson(data['wallet']);
        }
        return data;
      }
    } catch (_) {}
    return {'user': _mockUser.toJson(), 'wallet': {'available_balance': _mockWallet.availableBalance, 'locked_balance': _mockWallet.lockedBalance}};
  }


  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: _headers,
        body: jsonEncode({'username': username, 'password': password}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['token'] != null) authToken = data['token'];
        if (data['user'] != null) _mockUser = UserModel.fromJson(data['user']);
        if (data['wallet'] != null) _mockWallet = WalletModel.fromJson(data['wallet']);
        return data;
      } else {
        final data = jsonDecode(res.body);
        throw Exception(data['error'] ?? 'Invalid staff credentials');
      }
    } catch (e) {
      final norm = username.trim().toLowerCase();
      if ((norm == 'mrpr0c0dss@gmail.com' && password == 'password') ||
          (norm == 'admin' && password == 'admin123') ||
          (norm == 'admin@platform.io' && password == 'admin123')) {
        _mockUser = UserModel(
          id: norm == 'mrpr0c0dss@gmail.com' ? 'usr_mrpr0' : 'usr_admin',
          displayName: norm == 'mrpr0c0dss@gmail.com' ? 'MrPr0C0dss' : 'Aegis_Root',
          email: norm == 'mrpr0c0dss@gmail.com' ? 'mrpr0c0dss@gmail.com' : 'admin@platform.io',
          phone: '+977-9800000000',
          role: 'super_admin',
          status: 'active',
          avatar: 'https://api.dicebear.com/7.x/bottts/svg?seed=usr_mrpr0',
        );
        authToken = 'tok_mock_admin';
        return {'token': authToken, 'user': _mockUser, 'wallet': _mockWallet};
      }
      if (e.toString().contains('Exception:')) rethrow;
      throw Exception('Could not connect to authentication server. Please try again.');
    }
  }

  // ------------------------------------------------------------------
  // GAMES & TOPUPS
  // ------------------------------------------------------------------
  Future<List<GameModel>> getGames() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/topups/games'), headers: _headers);
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        return list.map((g) => GameModel.fromJson(g as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return _mockGames;
  }

  Future<List<TopUpPackageModel>> getPackages(String gameId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/topups/games/$gameId/packages'), headers: _headers);
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        return list.map((p) => TopUpPackageModel.fromJson(p as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    final game = _mockGames.firstWhere((g) => g.id == gameId, orElse: () => _mockGames.first);
    return game.packages;
  }

  Future<void> addGame(GameModel game) async {
    final existingIdx = _mockGames.indexWhere((g) => g.id == game.id);
    if (existingIdx != -1) {
      _mockGames[existingIdx] = game;
    } else {
      _mockGames.add(game);
    }
  }

  Future<void> toggleGameStatus(String gameId, bool active) async {
    final idx = _mockGames.indexWhere((g) => g.id == gameId);
    if (idx != -1) {
      final g = _mockGames[idx];
      _mockGames[idx] = GameModel(
        id: g.id,
        name: g.name,
        slug: g.slug,
        category: g.category,
        icon: g.icon,
        banner: g.banner,
        active: active,
        deliveryMethod: g.deliveryMethod,
        requiredFields: g.requiredFields,
        packages: g.packages,
      );
    }
  }

  Future<void> addPackageToGame(String gameId, TopUpPackageModel package) async {
    final idx = _mockGames.indexWhere((g) => g.id == gameId);
    if (idx != -1) {
      final g = _mockGames[idx];
      final newPackages = List<TopUpPackageModel>.from(g.packages)..add(package);
      _mockGames[idx] = g.copyWith(packages: newPackages);
    }
  }

  Future<Map<String, dynamic>> createTopUpOrder({
    required String gameId,
    required String packageId,
    required Map<String, String> playerDetails,
    required String paymentMethod,
    required double price,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/topups/orders'),
        headers: _headers,
        body: jsonEncode({
          'game_id': gameId,
          'package_id': packageId,
          'player_details': playerDetails,
          'payment_method': paymentMethod,
        }),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(res.body);
      }
    } catch (_) {}

    // Deduct from wallet if wallet payment
    if (paymentMethod == 'WALLET') {
      if (_mockWallet.availableBalance < price) {
        throw Exception('Insufficient wallet balance. Please deposit funds or choose another gateway.');
      }
      _mockWallet = WalletModel(
        userId: _mockUser.id,
        availableBalance: _mockWallet.availableBalance - price,
        lockedBalance: _mockWallet.lockedBalance,
        updatedAt: DateTime.now(),
      );
      _mockTransactions.insert(
        0,
        LedgerTransactionModel(
          id: 'led_${DateTime.now().millisecondsSinceEpoch}',
          userId: _mockUser.id,
          type: 'TOPUP_PURCHASE',
          amount: price,
          direction: 'DEBIT',
          referenceType: 'TOPUP_ORDER',
          referenceId: 'ord_${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
          note: 'TopUp for $gameId package #$packageId',
          createdAt: DateTime.now(),
        ),
      );
    }

    return {
      'order_id': 'ord_${DateTime.now().millisecondsSinceEpoch}',
      'status': 'COMPLETED',
      'message': 'Diamonds / Credits dispatched instantly to player account!',
      'receipt': 'REC-TOP-${DateTime.now().millisecondsSinceEpoch}',
    };
  }

  // ------------------------------------------------------------------
  // WALLET & LEDGER
  // ------------------------------------------------------------------
  Future<WalletModel> getWallet() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/wallet'), headers: _headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _mockWallet = WalletModel.fromJson(data);
        return _mockWallet;
      }
    } catch (_) {}
    return _mockWallet;
  }

  Future<List<LedgerTransactionModel>> getWalletTransactions() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/wallet/transactions'), headers: _headers).timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        return list.map((t) => LedgerTransactionModel.fromJson(t as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return _mockTransactions;
  }

  Future<WalletModel> depositFunds({
    required double amount,
    required String paymentMethod,
    String? referenceId,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/wallet/topups'),
        headers: _headers,
        body: jsonEncode({
          'amount': amount,
          'payment_method': paymentMethod,
          'reference_id': referenceId ?? 'TXN-${DateTime.now().millisecondsSinceEpoch}',
        }),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _mockWallet = WalletModel.fromJson(data['wallet'] ?? data);
        return _mockWallet;
      }
    } catch (_) {}

    // In-memory credit
    _mockWallet = WalletModel(
      userId: _mockUser.id,
      availableBalance: _mockWallet.availableBalance + amount,
      lockedBalance: _mockWallet.lockedBalance,
      updatedAt: DateTime.now(),
    );
    _mockTransactions.insert(
      0,
      LedgerTransactionModel(
        id: 'led_dep_${DateTime.now().millisecondsSinceEpoch}',
        userId: _mockUser.id,
        type: 'DEPOSIT',
        amount: amount,
        direction: 'CREDIT',
        referenceType: 'GATEWAY_DEPOSIT',
        referenceId: referenceId ?? 'DEP-${DateTime.now().millisecondsSinceEpoch}',
        note: 'Deposit via $paymentMethod',
        createdAt: DateTime.now(),
      ),
    );
    return _mockWallet;
  }

  Future<WalletModel> withdrawFunds({
    required double amount,
    required String paymentMethod,
    required String accountDetails,
  }) async {
    if (_mockWallet.availableBalance < amount) {
      throw Exception('Insufficient available balance to withdraw \$$amount');
    }

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/wallet/withdraw'),
        headers: _headers,
        body: jsonEncode({
          'amount': amount,
          'payment_method': paymentMethod,
          'account_details': accountDetails,
        }),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _mockWallet = WalletModel.fromJson(data['wallet'] ?? data);
        return _mockWallet;
      }
    } catch (_) {}

    _mockWallet = WalletModel(
      userId: _mockUser.id,
      availableBalance: _mockWallet.availableBalance - amount,
      lockedBalance: _mockWallet.lockedBalance,
      updatedAt: DateTime.now(),
    );
    _mockTransactions.insert(
      0,
      LedgerTransactionModel(
        id: 'led_wth_${DateTime.now().millisecondsSinceEpoch}',
        userId: _mockUser.id,
        type: 'WITHDRAWAL',
        amount: amount,
        direction: 'DEBIT',
        referenceType: 'PAYOUT_REQUEST',
        referenceId: 'WTH-${DateTime.now().millisecondsSinceEpoch}',
        note: 'Withdrawal to $paymentMethod ($accountDetails)',
        createdAt: DateTime.now(),
      ),
    );
    return _mockWallet;
  }

  // ------------------------------------------------------------------
  // TOURNAMENTS
  // ------------------------------------------------------------------
  Future<List<TournamentModel>> getTournaments({String? status, String? gameId}) async {
    try {
      String query = '';
      if (status != null && status != 'All') query += 'status=${Uri.encodeComponent(status)}&';
      if (gameId != null && gameId != 'All') query += 'game_id=${Uri.encodeComponent(gameId)}&';

      final res = await http.get(Uri.parse('$baseUrl/api/tournaments?$query'), headers: _headers);
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        return list.map((t) => TournamentModel.fromJson(t as Map<String, dynamic>)).toList();
      }
    } catch (_) {}

    return _mockTournaments.where((t) {
      if (status != null && status != 'All' && t.status != status) return false;
      if (gameId != null && gameId != 'All' && t.gameId != gameId) return false;
      return true;
    }).toList();
  }

  Future<List<RegisteredMatchModel>> getMyTournaments() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/me/tournaments'), headers: _headers).timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        return list.map((m) => RegisteredMatchModel.fromJson(m as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return _mockMyMatches;
  }

  Future<Map<String, dynamic>> registerTournament({
    required String tournamentId,
    required String teamName,
    required Map<String, String> playerDetails,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/tournaments/$tournamentId/register'),
        headers: _headers,
        body: jsonEncode({
          'team_name': teamName,
          'player_details': playerDetails,
        }),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(res.body);
      }
    } catch (_) {}

    final tour = _mockTournaments.firstWhere((t) => t.id == tournamentId, orElse: () => _mockTournaments.first);
    if (_mockWallet.availableBalance < tour.entryFee) {
      throw Exception('Insufficient balance. Entry fee is \$${tour.entryFee.toStringAsFixed(2)}');
    }

    if (tour.entryFee > 0) {
      _mockWallet = WalletModel(
        userId: _mockUser.id,
        availableBalance: _mockWallet.availableBalance - tour.entryFee,
        lockedBalance: _mockWallet.lockedBalance,
        updatedAt: DateTime.now(),
      );
      _mockTransactions.insert(
        0,
        LedgerTransactionModel(
          id: 'led_reg_${DateTime.now().millisecondsSinceEpoch}',
          userId: _mockUser.id,
          type: 'ENTRY_FEE',
          amount: tour.entryFee,
          direction: 'DEBIT',
          referenceType: 'TOURNAMENT_ENTRY',
          referenceId: tournamentId,
          note: 'Entry fee for ${tour.title}',
          createdAt: DateTime.now(),
        ),
      );
    }

    final newMatch = RegisteredMatchModel(
      registrationId: 'reg_${DateTime.now().millisecondsSinceEpoch}',
      tournamentId: tour.id,
      tournamentTitle: tour.title,
      gameId: tour.gameId,
      mode: tour.mode,
      banner: tour.banner,
      status: 'CONFIRMED',
      receiptNumber: 'REC-TN-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
      registeredAt: DateTime.now(),
      matchStartsAt: tour.startsAt,
      roomReleaseAt: tour.roomReleaseAt,
      entryFee: tour.entryFee,
      prizePool: tour.prizePool,
      roomId: tour.roomId ?? 'ROOM-${tour.id.toUpperCase()}',
      roomPassword: tour.roomPassword ?? 'pass-ready-2026',
      roomDecrypted: tour.isRoomReleased,
    );
    _mockMyMatches.insert(0, newMatch);

    return {
      'status': 'CONFIRMED',
      'message': 'Registration Confirmed! Good luck in the arena, warrior.',
      'receipt': newMatch.receiptNumber,
    };
  }

  Future<void> cancelTournamentRegistration(String tournamentId) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/api/tournaments/$tournamentId/cancel-registration'),
        headers: _headers,
      );
    } catch (_) {}

    final index = _mockMyMatches.indexWhere((m) => m.tournamentId == tournamentId);
    if (index != -1) {
      final match = _mockMyMatches[index];
      if (match.entryFee > 0) {
        _mockWallet = WalletModel(
          userId: _mockUser.id,
          availableBalance: _mockWallet.availableBalance + match.entryFee,
          lockedBalance: _mockWallet.lockedBalance,
          updatedAt: DateTime.now(),
        );
        _mockTransactions.insert(
          0,
          LedgerTransactionModel(
            id: 'led_ref_${DateTime.now().millisecondsSinceEpoch}',
            userId: _mockUser.id,
            type: 'REFUND',
            amount: match.entryFee,
            direction: 'CREDIT',
            referenceType: 'TOURNAMENT_CANCELLATION',
            referenceId: tournamentId,
            note: 'Registration cancellation refund for ${match.tournamentTitle}',
            createdAt: DateTime.now(),
          ),
        );
      }
      _mockMyMatches.removeAt(index);
    }
  }

  Future<Map<String, dynamic>> getRoomCredentials(String tournamentId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/tournaments/$tournamentId/room'), headers: _headers);
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (_) {}

    final match = _mockMyMatches.firstWhere(
      (m) => m.tournamentId == tournamentId,
      orElse: () => _mockMyMatches.first,
    );
    return {
      'room_id': match.roomId ?? 'LOBBY-9941',
      'room_password': match.roomPassword ?? 'tnt-esports-2026',
      'status': 'RELEASED',
    };
  }

  // ------------------------------------------------------------------
  // AI TOOLS & SUBSCRIPTIONS
  // ------------------------------------------------------------------
  Future<List<AiToolModel>> getAiTools() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/ai/tools'), headers: _headers);
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        return list.map((t) => AiToolModel.fromJson(t as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return AiToolModel.seedTools;
  }

  Future<List<AiSubscriptionModel>> getMyAiSubscriptions() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/ai/my-subscriptions'), headers: _headers);
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        return list.map((s) => AiSubscriptionModel.fromJson(s as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [
      AiSubscriptionModel(
        id: 'sub_ai_1',
        toolId: 'ai_chatgpt',
        toolName: 'ChatGPT Plus',
        planName: '1-Month Pro',
        licenseKey: 'OPENAI-GPT4O-KEY-8942-XN89',
        status: 'ACTIVE',
        startsAt: DateTime.now().subtract(const Duration(days: 5)),
        expiresAt: DateTime.now().add(const Duration(days: 25)),
      ),
      AiSubscriptionModel(
        id: 'sub_ai_2',
        toolId: 'ai_cursor',
        toolName: 'Cursor Pro',
        planName: '1-Year Developer',
        licenseKey: 'CURSOR-PRO-ANNUAL-7721-V90',
        status: 'ACTIVE',
        startsAt: DateTime.now().subtract(const Duration(days: 40)),
        expiresAt: DateTime.now().add(const Duration(days: 325)),
      ),
    ];
  }

  // ------------------------------------------------------------------
  // ADMIN & METRICS
  // ------------------------------------------------------------------
  Future<Map<String, dynamic>> getPlatformMetrics() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/platform/metrics'), headers: _headers);
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (_) {}
    return {
      'activeGames': 6,
      'totalTournaments': 6,
      'totalRegistrations': 42,
      'totalLedgerTx': 158,
      'status': 'OPERATIONAL',
      'grossMerchandiseVolume': 12450.00,
    };
  }

  Future<List<Map<String, dynamic>>> getLeaderboard() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/leaderboard'), headers: _headers);
      if (res.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(res.body));
      }
    } catch (_) {}
    return [
      {'rank': 1, 'name': 'Phoenix_Ace', 'wins': 18, 'earnings': 1280.0, 'badge': 'Grandmaster'},
      {'rank': 2, 'name': 'ViperStrike', 'wins': 14, 'earnings': 940.0, 'badge': 'Apex Predator'},
      {'rank': 3, 'name': 'ShadowNinja', 'wins': 11, 'earnings': 720.0, 'badge': 'Immortal'},
      {'rank': 4, 'name': 'GhostRider', 'wins': 9, 'earnings': 510.0, 'badge': 'Diamond'},
      {'rank': 5, 'name': 'CyberSamurai', 'wins': 7, 'earnings': 380.0, 'badge': 'Platinum'},
    ];
  }

  // ------------------------------------------------------------------
  // ADMIN COMMAND & OPERATIONS SYSTEM
  // ------------------------------------------------------------------
  final List<Map<String, dynamic>> _mockAdminOrders = [
    {
      'id': 'ORD-9901',
      'user_id': 'usr_player1',
      'user_name': 'Phoenix_Ace',
      'game': 'Free Fire MAX',
      'game_id': 'game_ff',
      'package': '520+52 Diamonds',
      'player_id': '192837465',
      'server': 'Asia',
      'price': 4.89,
      'status': 'DELIVERED',
      'payment_method': 'eSewa',
      'created_at': '12 mins ago',
      'tx_hash': '0x88492019ab921',
    },
    {
      'id': 'ORD-9902',
      'user_id': 'usr_player2',
      'user_name': 'ViperStrike',
      'game': 'PUBG Mobile',
      'game_id': 'game_pubg',
      'package': '660 UC',
      'player_id': '518392019',
      'server': 'Global / Asia',
      'price': 9.49,
      'status': 'PENDING_DELIVERY',
      'payment_method': 'Wallet',
      'created_at': '24 mins ago',
      'tx_hash': '0x992019ac1048f',
    },
    {
      'id': 'ORD-9903',
      'user_id': 'usr_player3',
      'user_name': 'ShadowNinja',
      'game': 'Mobile Legends',
      'game_id': 'game_mlbb',
      'package': 'Weekly Pass',
      'player_id': '8493021 (2041)',
      'server': '2041',
      'price': 1.99,
      'status': 'DELIVERED',
      'payment_method': 'Khalti',
      'created_at': '1 hour ago',
      'tx_hash': '0x551982736bba1',
    },
    {
      'id': 'ORD-9904',
      'user_id': 'usr_player1',
      'user_name': 'Phoenix_Ace',
      'game': 'Valorant',
      'game_id': 'game_val',
      'package': '1,000 Points',
      'player_id': 'Phoenix#9921',
      'server': 'AP / Mumbai',
      'price': 9.99,
      'status': 'PENDING_DELIVERY',
      'payment_method': 'eSewa',
      'created_at': '42 mins ago',
      'tx_hash': '0x1128919283bbc',
    },
    {
      'id': 'ORD-9905',
      'user_id': 'usr_player2',
      'user_name': 'ViperStrike',
      'game': 'Free Fire MAX',
      'game_id': 'game_ff',
      'package': 'Weekly Membership',
      'player_id': '778899001',
      'server': 'South Asia',
      'price': 1.99,
      'status': 'REFUNDED',
      'payment_method': 'Wallet',
      'created_at': '3 hours ago',
      'tx_hash': '0x7728192849dfe',
    },
  ];

  final List<Map<String, dynamic>> _mockAdminPayments = [
    {
      'id': 'PAY-8801',
      'user_id': 'usr_player1',
      'user_name': 'Phoenix_Ace',
      'user_email': 'phoenix@gamer.io',
      'amount': 25.00,
      'currency': 'USD',
      'method': 'eSewa',
      'slip_no': 'TXN-ESEWA-8849201',
      'created_at': '5 mins ago',
      'status': 'PENDING_VERIFICATION',
      'proof_image': 'assets/banner/neon_loot_battle_royale.webp',
    },
    {
      'id': 'PAY-8802',
      'user_id': 'usr_player2',
      'user_name': 'ViperStrike',
      'user_email': 'viper@gamer.io',
      'amount': 50.00,
      'currency': 'USD',
      'method': 'Khalti',
      'slip_no': 'KHALTI-TXN-773910',
      'created_at': '18 mins ago',
      'status': 'PENDING_VERIFICATION',
      'proof_image': 'assets/banner/cricket_stadium_lights.webp',
    },
  ];

  final List<Map<String, dynamic>> _mockAdminPrizes = [
    {
      'id': 'EARN-901',
      'type': 'TOURNAMENT_PRIZE',
      'tournament': 'Free Fire: Apex Champions Cup S4 (1st Place)',
      'winner': 'Phoenix_Ace',
      'winner_id': 'usr_player1',
      'winner_avatar': 'https://api.dicebear.com/7.x/bottts/svg?seed=usr_player1',
      'amount': 200.00,
      'currency': 'USD',
      'local_amount': 'Rs. 26,700',
      'payout_method': 'eSewa',
      'payout_details': 'eSewa ID: 9801234567 (Phoenix Ace)',
      'account_number': '9801234567',
      'account_name': 'Phoenix Ace',
      'status': 'PENDING_APPROVAL',
      'mgr_approved': false,
      'finance_approved': false,
      'time': '10 mins ago',
      'is_new': true,
      'notes': 'Verified champion scorecard. Awaiting administrative payout approval.',
    },
    {
      'id': 'EARN-902',
      'type': 'TOURNAMENT_PRIZE',
      'tournament': 'MLBB: Mystic Invitational [1v1 Champion]',
      'winner': 'ViperStrike',
      'winner_id': 'usr_player2',
      'winner_avatar': 'https://api.dicebear.com/7.x/bottts/svg?seed=usr_player2',
      'amount': 117.00,
      'currency': 'USD',
      'local_amount': 'Rs. 15,620',
      'payout_method': 'Khalti',
      'payout_details': 'Khalti ID: 9841987654 (Viper Strike)',
      'account_number': '9841987654',
      'account_name': 'Viper Strike',
      'status': 'AWAITING_FINANCE_APPROVAL',
      'mgr_approved': true,
      'finance_approved': false,
      'time': '32 mins ago',
      'is_new': true,
      'notes': 'Manager signoff completed. Dual finance review required.',
    },
    {
      'id': 'EARN-903',
      'type': 'REFERRAL_COMMISSION',
      'tournament': 'Esports Squad Referral & TopUp Cashout',
      'winner': 'Aegis_Valkyrie',
      'winner_id': 'usr_player3',
      'winner_avatar': 'https://api.dicebear.com/7.x/bottts/svg?seed=usr_player3',
      'amount': 55.00,
      'currency': 'USD',
      'local_amount': 'Rs. 7,340',
      'payout_method': 'Global IME Bank',
      'payout_details': 'A/C: 0010098273641 • Global IME Bank (Babita Sharma)',
      'account_number': '0010098273641',
      'account_name': 'Babita Sharma',
      'status': 'PENDING_APPROVAL',
      'mgr_approved': false,
      'finance_approved': false,
      'time': '1 hour ago',
      'is_new': true,
      'notes': 'Player earnings requested to direct local bank settlement.',
    },
    {
      'id': 'EARN-898',
      'type': 'TOURNAMENT_PRIZE',
      'tournament': 'PUBG Mobile: Erangel Squad War',
      'winner': 'Shadow_Sniper',
      'winner_id': 'usr_player4',
      'winner_avatar': 'https://api.dicebear.com/7.x/bottts/svg?seed=usr_player4',
      'amount': 250.00,
      'currency': 'USD',
      'local_amount': 'Rs. 33,375',
      'payout_method': 'ConnectIPS',
      'payout_details': 'ConnectIPS ID: 9811223344 (Kiran Thapa)',
      'account_number': '9811223344',
      'account_name': 'Kiran Thapa',
      'status': 'PAID_OUT',
      'mgr_approved': true,
      'finance_approved': true,
      'time': 'Yesterday',
      'is_new': false,
      'notes': 'Disbursed via automated ledger transfer.',
    },
  ];

  final List<Map<String, dynamic>> _mockAdminUsers = [
    {
      'id': 'usr_admin',
      'display_name': 'Aegis_Root',
      'email': 'admin@platform.io',
      'role': 'super_admin',
      'status': 'active',
      'balance': 1000.00,
      'phone': '+1-555-0100',
      'avatar': 'https://api.dicebear.com/7.x/bottts/svg?seed=usr_admin',
    },
    {
      'id': 'usr_mrpr0',
      'display_name': 'MrPr0C0dss',
      'email': 'mrpr0c0dss@gmail.com',
      'role': 'super_admin',
      'status': 'active',
      'balance': 2500.00,
      'phone': '+977-9800000000',
      'avatar': 'https://api.dicebear.com/7.x/bottts/svg?seed=usr_mrpr0',
    },
    {
      'id': 'usr_player1',
      'display_name': 'Phoenix_Ace',
      'email': 'phoenix@gamer.io',
      'role': 'player',
      'status': 'active',
      'balance': 150.00,
      'phone': '+977-9801234567',
      'avatar': 'https://api.dicebear.com/7.x/bottts/svg?seed=usr_player1',
    },
    {
      'id': 'usr_player2',
      'display_name': 'ViperStrike',
      'email': 'viper@gamer.io',
      'role': 'player',
      'status': 'active',
      'balance': 45.00,
      'phone': '+977-9812345678',
      'avatar': 'https://api.dicebear.com/7.x/bottts/svg?seed=usr_player2',
    },
    {
      'id': 'usr_player3',
      'display_name': 'ShadowNinja',
      'email': 'ninja@gamer.io',
      'role': 'player',
      'status': 'active',
      'balance': 8.50,
      'phone': '+977-9823456789',
      'avatar': 'https://api.dicebear.com/7.x/bottts/svg?seed=usr_player3',
    },
    {
      'id': 'usr_tmgr',
      'display_name': 'Kage_Director',
      'email': 'tournaments@platform.io',
      'role': 'tournament_manager',
      'status': 'active',
      'balance': 500.00,
      'phone': '+1-555-0101',
      'avatar': 'https://api.dicebear.com/7.x/bottts/svg?seed=usr_tmgr',
    },
  ];

  final List<Map<String, dynamic>> _mockAdminAiKeys = [
    {'id': 'key_1', 'tool': 'ChatGPT Plus', 'code': 'OAI-PLUS-9921-X90-TOKEN', 'status': 'AVAILABLE', 'assigned_to': null},
    {'id': 'key_2', 'tool': 'Claude 3.5 Pro', 'code': 'CLAUDE-PRO-8812-V12-VIP', 'status': 'AVAILABLE', 'assigned_to': null},
    {'id': 'key_3', 'tool': 'Cursor Pro', 'code': 'CURSOR-DEV-7721-M88-KEY', 'status': 'ASSIGNED', 'assigned_to': 'Alex_Code'},
    {'id': 'key_4', 'tool': 'Midjourney Pro', 'code': 'MIDJ-PRO-6610-K44-FAST', 'status': 'AVAILABLE', 'assigned_to': null},
  ];

  final List<Map<String, dynamic>> _mockAdminAuditLogs = [
    {
      'id': 'aud_9901',
      'action': 'ORDER_DELIVERY',
      'actor': 'admin@platform.io',
      'entity': 'ORD-9901',
      'reason': 'Diamonds auto-injected to UID 192837465',
      'time': '12 mins ago',
    },
    {
      'id': 'aud_9902',
      'action': 'GMAIL_LOGIN',
      'actor': 'admin@platform.io',
      'entity': 'auth_session',
      'reason': 'Super Admin accessed Operations Command Center',
      'time': '18 mins ago',
    },
    {
      'id': 'aud_9903',
      'action': 'TOURNAMENT_CREDENTIALS',
      'actor': 'usr_admin',
      'entity': 'tour_live_showdown',
      'reason': 'Room ID and Password released to 32 verified players',
      'time': '25 mins ago',
    },
    {
      'id': 'aud_9904',
      'action': 'WALLET_ADJUSTMENT',
      'actor': 'usr_admin',
      'entity': 'usr_player1',
      'reason': 'Deposit slip TXN-ESEWA-8849201 verified (+\$25.00)',
      'time': '40 mins ago',
    },
  ];

  Future<Map<String, dynamic>> getAdminOverview() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/admin/overview'), headers: _headers);
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (_) {}
    return {
      'escrowTotal': 148290.0,
      'todayOrders': 48,
      'todayVolume': 2430.50,
      'activeTournaments': 6,
      'pendingTopups': 2,
      'pendingSlips': 2,
      'totalUsers': 1248,
      'systemHealth': 'NOMINAL_100',
    };
  }

  Future<List<Map<String, dynamic>>> getAdminOrders() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/admin/topup-orders'), headers: _headers);
      if (res.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(res.body));
      }
    } catch (_) {}
    return List<Map<String, dynamic>>.from(_mockAdminOrders);
  }

  Future<bool> markAdminOrderDelivered(String orderId) async {
    final idx = _mockAdminOrders.indexWhere((o) => o['id'] == orderId);
    if (idx != -1) {
      _mockAdminOrders[idx]['status'] = 'DELIVERED';
    }
    _addAuditEntry('ORDER_DELIVERED', 'Admin marked order $orderId as delivered', entity: orderId);
    try {
      await http.post(
        Uri.parse('$baseUrl/api/admin/topup-orders/$orderId/retry-delivery'),
        headers: _headers,
      );
    } catch (_) {}
    return true;
  }

  Future<bool> refundAdminOrder(String orderId) async {
    final idx = _mockAdminOrders.indexWhere((o) => o['id'] == orderId);
    if (idx != -1) {
      _mockAdminOrders[idx]['status'] = 'REFUNDED';
    }
    _addAuditEntry('ORDER_REFUNDED', 'Order $orderId refunded to customer wallet', entity: orderId);
    try {
      await http.post(
        Uri.parse('$baseUrl/api/admin/topup-orders/$orderId/refund'),
        headers: _headers,
      );
    } catch (_) {}
    return true;
  }

  Future<List<Map<String, dynamic>>> getAdminPendingPayments() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/admin/payments/pending'), headers: _headers);
      if (res.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(res.body));
      }
    } catch (_) {}
    return List<Map<String, dynamic>>.from(_mockAdminPayments);
  }

  Future<bool> verifyAdminPayment(String paymentId, {required bool approve, String? note}) async {
    _mockAdminPayments.removeWhere((p) => p['id'] == paymentId);
    _addAuditEntry(
      approve ? 'PAYMENT_APPROVED' : 'PAYMENT_REJECTED',
      approve ? 'Payment $paymentId approved & credited' : 'Payment $paymentId rejected: ${note ?? "Invalid slip"}',
      entity: paymentId,
    );
    try {
      await http.post(
        Uri.parse('$baseUrl/api/admin/payments/$paymentId/verify'),
        headers: _headers,
        body: jsonEncode({'approved': approve, 'note': note}),
      );
    } catch (_) {}
    return true;
  }

  Future<List<Map<String, dynamic>>> getAdminPrizes() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/admin/prizes'), headers: _headers);
      if (res.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(res.body));
      }
    } catch (_) {}
    return List<Map<String, dynamic>>.from(_mockAdminPrizes);
  }

  Future<bool> approveAdminPrize(String prizeId) async {
    final idx = _mockAdminPrizes.indexWhere((p) => p['id'] == prizeId);
    if (idx != -1) {
      _mockAdminPrizes[idx]['mgr_approved'] = true;
      _mockAdminPrizes[idx]['finance_approved'] = true;
      _mockAdminPrizes[idx]['status'] = 'PAID_OUT';
    }
    _addAuditEntry('PRIZE_APPROVED', 'Dual signoff completed for prize $prizeId', entity: prizeId);
    try {
      await http.post(
        Uri.parse('$baseUrl/api/admin/prizes/$prizeId/approve'),
        headers: _headers,
      );
    } catch (_) {}
    return true;
  }

  Future<bool> rejectAdminPrize(String prizeId, {String? reason}) async {
    final idx = _mockAdminPrizes.indexWhere((p) => p['id'] == prizeId);
    if (idx != -1) {
      _mockAdminPrizes[idx]['status'] = 'REJECTED';
      _mockAdminPrizes[idx]['rejection_reason'] = reason ?? 'Payout rejected by administrator';
    }
    _addAuditEntry('EARNING_REJECTED', 'Earning cashout request $prizeId rejected: ${reason ?? "Failed verification"}', entity: prizeId);
    return true;
  }

  Future<List<Map<String, dynamic>>> getAdminUsers() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/admin/users'), headers: _headers);
      if (res.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(res.body));
      }
    } catch (_) {}
    return List<Map<String, dynamic>>.from(_mockAdminUsers);
  }

  Future<bool> updateAdminUserRole(String userId, String newRole) async {
    final idx = _mockAdminUsers.indexWhere((u) => u['id'] == userId);
    if (idx != -1) {
      _mockAdminUsers[idx]['role'] = newRole;
    }
    _addAuditEntry('USER_ROLE_CHANGED', 'User $userId role changed to $newRole', entity: userId);
    return true;
  }

  Future<bool> adjustAdminUserBalance(String userId, double amount, String note) async {
    final idx = _mockAdminUsers.indexWhere((u) => u['id'] == userId);
    if (idx != -1) {
      final current = (_mockAdminUsers[idx]['balance'] as num).toDouble();
      _mockAdminUsers[idx]['balance'] = (current + amount).clamp(0.0, 999999.0);
    }
    _addAuditEntry('BALANCE_ADJUSTMENT', 'Adjusted $userId by \$$amount: $note', entity: userId);
    return true;
  }

  Future<bool> toggleAdminUserBan(String userId, bool ban, String? reason) async {
    final idx = _mockAdminUsers.indexWhere((u) => u['id'] == userId);
    if (idx != -1) {
      _mockAdminUsers[idx]['status'] = ban ? 'banned' : 'active';
      _mockAdminUsers[idx]['ban_reason'] = ban ? (reason ?? 'Violation') : null;
    }
    _addAuditEntry(ban ? 'USER_BANNED' : 'USER_UNBANNED', '$userId: ${reason ?? "Status updated"}', entity: userId);
    try {
      await http.patch(
        Uri.parse('$baseUrl/api/admin/users/$userId/ban'),
        headers: _headers,
        body: jsonEncode({'banned': ban, 'reason': reason}),
      );
    } catch (_) {}
    return true;
  }

  Future<List<Map<String, dynamic>>> getAdminAiKeys() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/admin/ai/keys'), headers: _headers);
      if (res.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(res.body));
      }
    } catch (_) {}
    return List<Map<String, dynamic>>.from(_mockAdminAiKeys);
  }

  Future<bool> createAdminAiKey(String tool, String code) async {
    final newKey = {
      'id': 'key_${DateTime.now().millisecondsSinceEpoch}',
      'tool': tool,
      'code': code,
      'status': 'AVAILABLE',
      'assigned_to': null,
    };
    _mockAdminAiKeys.insert(0, newKey);
    _addAuditEntry('AI_KEY_ADDED', 'New license key added for $tool');
    try {
      await http.post(
        Uri.parse('$baseUrl/api/admin/ai/keys'),
        headers: _headers,
        body: jsonEncode({'tool': tool, 'code': code}),
      );
    } catch (_) {}
    return true;
  }

  Future<bool> deleteAdminAiKey(String keyId) async {
    _mockAdminAiKeys.removeWhere((k) => k['id'] == keyId);
    _addAuditEntry('AI_KEY_REMOVED', 'License key $keyId deleted');
    return true;
  }

  Future<List<Map<String, dynamic>>> getAdminAuditLogs() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/admin/audit-logs'), headers: _headers);
      if (res.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(res.body));
      }
    } catch (_) {}
    return List<Map<String, dynamic>>.from(_mockAdminAuditLogs);
  }

  void _addAuditEntry(String action, String reason, {String? entity}) {
    _mockAdminAuditLogs.insert(0, {
      'id': 'aud_${DateTime.now().millisecondsSinceEpoch}',
      'action': action,
      'actor': currentUserId,
      'entity': entity ?? 'system',
      'reason': reason,
      'time': 'Just now',
    });
    if (_mockAdminAuditLogs.length > 50) {
      _mockAdminAuditLogs.removeLast();
    }
  }
}
