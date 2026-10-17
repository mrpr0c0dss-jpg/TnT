import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/wallet_model.dart';
import '../models/country_model.dart';
import '../models/game_model.dart';
import '../models/tournament_model.dart';
import '../models/ai_subscription_model.dart';
import 'api_service.dart';

class AppState extends ChangeNotifier {
  final ApiService _api = ApiService();

  UserModel _currentUser = const UserModel(
    id: 'usr_guest',
    displayName: 'Guest Player',
    email: '',
    role: 'player',
    status: 'active',
    avatar: 'https://api.dicebear.com/7.x/bottts/svg?seed=usr_guest',
  );

  WalletModel _wallet = WalletModel(
    userId: 'usr_guest',
    currency: 'USD',
    availableBalance: 0.0,
    lockedBalance: 0.0,
    updatedAt: DateTime.now(),
  );

  CountryModel _selectedCountry = CountryModel.defaultCountry();
  int _currentTabIndex = 0; // 0: Home, 1: Top-Up, 2: Tournaments, 3: My Matches, 4: Wallet, 5: Profile, 6: Admin
  bool _isLoading = false;
  bool _isAdminPanelActive = false;
  bool _isMaintenanceMode = false;

  List<GameModel> _games = [];
  List<TournamentModel> _tournaments = [];
  List<RegisteredMatchModel> _myMatches = [];
  List<LedgerTransactionModel> _transactions = [];
  List<AiToolModel> _aiTools = [];
  List<AiSubscriptionModel> _aiSubscriptions = [];
  Map<String, dynamic> _metrics = {};
  List<Map<String, dynamic>> _leaderboard = [];

  // Dedicated Admin Data
  Map<String, dynamic> _adminOverview = {};
  List<Map<String, dynamic>> _adminOrders = [];
  List<Map<String, dynamic>> _adminPayments = [];
  List<Map<String, dynamic>> _adminPrizes = [];
  List<Map<String, dynamic>> _adminUsers = [];
  List<Map<String, dynamic>> _adminAiKeys = [];
  List<Map<String, dynamic>> _adminAuditLogs = [];

  // Getters
  UserModel get currentUser => _currentUser;
  WalletModel get wallet => _wallet;
  CountryModel get selectedCountry => _selectedCountry;
  int get currentTabIndex => _currentTabIndex;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser.id != 'usr_guest';
  bool get isAdminPanelActive => _isAdminPanelActive;
  bool get isMaintenanceMode => _isMaintenanceMode;

  List<GameModel> get games => _games;
  List<TournamentModel> get tournaments => _tournaments;
  List<RegisteredMatchModel> get myMatches => _myMatches;
  List<LedgerTransactionModel> get transactions => _transactions;
  List<AiToolModel> get aiTools => _aiTools;
  List<AiSubscriptionModel> get aiSubscriptions => _aiSubscriptions;
  Map<String, dynamic> get metrics => _metrics;
  List<Map<String, dynamic>> get leaderboard => _leaderboard;

  // Admin Getters
  Map<String, dynamic> get adminOverview => _adminOverview;
  List<Map<String, dynamic>> get adminOrders => _adminOrders;
  List<Map<String, dynamic>> get adminPayments => _adminPayments;
  List<Map<String, dynamic>> get adminPrizes => _adminPrizes;
  List<Map<String, dynamic>> get adminUsers => _adminUsers;
  List<Map<String, dynamic>> get adminAiKeys => _adminAiKeys;
  List<Map<String, dynamic>> get adminAuditLogs => _adminAuditLogs;

  void setAdminPanelActive(bool active) {
    _isAdminPanelActive = active;
    notifyListeners();
  }

  void toggleAdminPanel() {
    _isAdminPanelActive = !_isAdminPanelActive;
    notifyListeners();
  }

  void toggleMaintenanceMode() {
    _isMaintenanceMode = !_isMaintenanceMode;
    notifyListeners();
  }

  // Init
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCountry = prefs.getString('tnt_country_code');
      if (savedCountry != null) {
        _selectedCountry = CountryModel.supportedCountries.firstWhere(
          (c) => c.code == savedCountry,
          orElse: () => CountryModel.defaultCountry(),
        );
      }

      // Restore genuine saved Firebase session if available
      final restored = await _api.restoreSavedSession();
      if (restored != null) {
        _currentUser = restored;
        if (_currentUser.isAdmin) {
          _isAdminPanelActive = true;
          await reloadAdminData();
        }
      }
    } catch (_) {}

    await reloadAll();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> reloadAll() async {
    try {
      if (isLoggedIn) {
        final meData = await _api.getMe();
        if (meData['user'] != null) {
          _currentUser = UserModel.fromJson(meData['user']);
        }
        if (meData['wallet'] != null) {
          _wallet = WalletModel.fromJson(meData['wallet']);
        }
        _myMatches = await _api.getMyTournaments();
        _transactions = await _api.getWalletTransactions();
        _aiSubscriptions = await _api.getMyAiSubscriptions();
      } else {
        _wallet = WalletModel(
          userId: 'usr_guest',
          currency: 'USD',
          availableBalance: 0.0,
          lockedBalance: 0.0,
          updatedAt: DateTime.now(),
        );
        _myMatches = [];
        _transactions = [];
        _aiSubscriptions = [];
      }

      _games = await _api.getGames();
      _tournaments = await _api.getTournaments();
      _aiTools = await _api.getAiTools();
      _metrics = await _api.getPlatformMetrics();
      _leaderboard = await _api.getLeaderboard();
      if (_currentUser.isAdmin) {
        await reloadAdminData();
      }
    } catch (e) {
      if (kDebugMode) print('Error reloading state: $e');
    }
    notifyListeners();
  }

  Future<void> reloadAdminData() async {
    try {
      _adminOverview = await _api.getAdminOverview();
      _adminOrders = await _api.getAdminOrders();
      _adminPayments = await _api.getAdminPendingPayments();
      _adminPrizes = await _api.getAdminPrizes();
      _adminUsers = await _api.getAdminUsers();
      _adminAiKeys = await _api.getAdminAiKeys();
      _adminAuditLogs = await _api.getAdminAuditLogs();
    } catch (e) {
      if (kDebugMode) print('Error reloading admin data: $e');
    }
    notifyListeners();
  }

  void setTab(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  Future<void> switchCountry(CountryModel country) async {
    _selectedCountry = country;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('tnt_country_code', country.code);
    } catch (_) {}
  }

  Future<void> signInWithGmail({required String email, required String password, bool asAdmin = false}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _api.signInWithGmail(email, password, asAdmin: asAdmin);
      if (res['user'] != null) {
        _currentUser = res['user'] is UserModel ? res['user'] : UserModel.fromJson(res['user']);
      }
      if (res['wallet'] != null) {
        _wallet = res['wallet'] is WalletModel ? res['wallet'] : WalletModel.fromJson(res['wallet']);
      }
      _myMatches = await _api.getMyTournaments();
      _transactions = await _api.getWalletTransactions();

      if (asAdmin || _currentUser.isAdmin) {
        _isAdminPanelActive = true;
        await reloadAdminData();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInAsAdminWithGmail({required String email, required String password}) async {
    await signInWithGmail(email: email, password: password, asAdmin: true);
  }

  Future<void> signUpWithGmail({
    required String email,
    required String password,
    required String displayName,
    bool asAdmin = false,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _api.signUpWithGmail(
        email: email,
        password: password,
        displayName: displayName,
        asAdmin: asAdmin,
      );
      if (res['user'] != null) {
        _currentUser = res['user'] is UserModel ? res['user'] : UserModel.fromJson(res['user']);
      }
      if (res['wallet'] != null) {
        _wallet = res['wallet'] is WalletModel ? res['wallet'] : WalletModel.fromJson(res['wallet']);
      }
      _myMatches = await _api.getMyTournaments();
      _transactions = await _api.getWalletTransactions();

      if (asAdmin || _currentUser.isAdmin) {
        _isAdminPanelActive = true;
        await reloadAdminData();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithGoogle({
    required String email,
    required String displayName,
    String? photoUrl,
    bool asAdmin = false,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _api.signInWithGoogle(
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
        asAdmin: asAdmin,
      );
      if (res['user'] != null) {
        _currentUser = res['user'] is UserModel ? res['user'] : UserModel.fromJson(res['user']);
      }
      if (res['wallet'] != null) {
        _wallet = res['wallet'] is WalletModel ? res['wallet'] : WalletModel.fromJson(res['wallet']);
      }
      _myMatches = await _api.getMyTournaments();
      _transactions = await _api.getWalletTransactions();

      if (asAdmin || _currentUser.isAdmin) {
        _isAdminPanelActive = true;
        await reloadAdminData();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendPasswordReset(String email) async {
    await _api.sendPasswordReset(email);
  }

  Future<String> uploadImage({required String base64Data, required String filename}) async {
    return await _api.uploadImage(base64Data: base64Data, filename: filename);
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _api.signOut();
      _currentUser = const UserModel(
        id: 'usr_guest',
        displayName: 'Guest Player',
        email: '',
        role: 'player',
        status: 'active',
        avatar: 'https://api.dicebear.com/7.x/bottts/svg?seed=usr_guest',
      );
      _wallet = WalletModel(
        userId: 'usr_guest',
        currency: 'USD',
        availableBalance: 0.0,
        lockedBalance: 0.0,
        updatedAt: DateTime.now(),
      );
      _myMatches.clear();
      _transactions.clear();
      _isAdminPanelActive = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loginWithAdmin(String username, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _api.login(username, password);
      if (res['user'] != null) {
        _currentUser = UserModel.fromJson(res['user']);
      }
      _wallet = await _api.getWallet();
      if (_currentUser.isAdmin) {
        _isAdminPanelActive = true;
        await reloadAdminData();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Admin Operational Handlers
  Future<void> markAdminOrderDelivered(String orderId) async {
    await _api.markAdminOrderDelivered(orderId);
    _adminOrders = await _api.getAdminOrders();
    _adminAuditLogs = await _api.getAdminAuditLogs();
    notifyListeners();
  }

  Future<void> refundAdminOrder(String orderId) async {
    await _api.refundAdminOrder(orderId);
    _adminOrders = await _api.getAdminOrders();
    _adminAuditLogs = await _api.getAdminAuditLogs();
    notifyListeners();
  }

  Future<void> verifyAdminPayment(String paymentId, {required bool approve, String? note}) async {
    await _api.verifyAdminPayment(paymentId, approve: approve, note: note);
    _adminPayments = await _api.getAdminPendingPayments();
    _adminAuditLogs = await _api.getAdminAuditLogs();
    notifyListeners();
  }

  Future<void> approveAdminPrize(String prizeId) async {
    await _api.approveAdminPrize(prizeId);
    _adminPrizes = await _api.getAdminPrizes();
    _adminAuditLogs = await _api.getAdminAuditLogs();
    notifyListeners();
  }

  Future<void> rejectAdminPrize(String prizeId, {String? reason}) async {
    await _api.rejectAdminPrize(prizeId, reason: reason);
    _adminPrizes = await _api.getAdminPrizes();
    _adminAuditLogs = await _api.getAdminAuditLogs();
    notifyListeners();
  }

  Future<void> updateAdminUserRole(String userId, String newRole) async {
    await _api.updateAdminUserRole(userId, newRole);
    _adminUsers = await _api.getAdminUsers();
    _adminAuditLogs = await _api.getAdminAuditLogs();
    notifyListeners();
  }

  Future<void> adjustAdminUserBalance(String userId, double amount, String note) async {
    await _api.adjustAdminUserBalance(userId, amount, note);
    _adminUsers = await _api.getAdminUsers();
    _adminAuditLogs = await _api.getAdminAuditLogs();
    notifyListeners();
  }

  Future<void> toggleAdminUserBan(String userId, bool ban, String? reason) async {
    await _api.toggleAdminUserBan(userId, ban, reason);
    _adminUsers = await _api.getAdminUsers();
    _adminAuditLogs = await _api.getAdminAuditLogs();
    notifyListeners();
  }

  Future<void> createAdminAiKey(String tool, String code) async {
    await _api.createAdminAiKey(tool, code);
    _adminAiKeys = await _api.getAdminAiKeys();
    _adminAuditLogs = await _api.getAdminAuditLogs();
    notifyListeners();
  }

  Future<void> deleteAdminAiKey(String keyId) async {
    await _api.deleteAdminAiKey(keyId);
    _adminAiKeys = await _api.getAdminAiKeys();
    _adminAuditLogs = await _api.getAdminAuditLogs();
    notifyListeners();
  }

  Future<void> addAdminTournament(TournamentModel tournament) async {
    _tournaments.insert(0, tournament);
    notifyListeners();
  }

  Future<void> releaseRoomCredentials(String tournamentId, String roomId, String password) async {
    final idx = _tournaments.indexWhere((t) => t.id == tournamentId);
    if (idx != -1) {
      final old = _tournaments[idx];
      _tournaments[idx] = TournamentModel(
        id: old.id,
        title: old.title,
        gameId: old.gameId,
        mode: old.mode,
        region: old.region,
        banner: old.banner,
        description: old.description,
        entryFee: old.entryFee,
        prizePool: old.prizePool,
        prizeSplit: old.prizeSplit,
        maxSlots: old.maxSlots,
        registeredCount: old.registeredCount,
        startsAt: old.startsAt,
        registrationClosesAt: old.registrationClosesAt,
        checkInOpensAt: old.checkInOpensAt,
        roomReleaseAt: DateTime.now().subtract(const Duration(minutes: 1)),
        status: 'Live',
        rules: old.rules,
        isUserRegistered: old.isUserRegistered,
        roomId: roomId,
        roomPassword: password,
      );
    }
    notifyListeners();
  }

  Future<void> depositFunds(double amount, String paymentMethod, {String? referenceId}) async {
    _wallet = await _api.depositFunds(
      amount: amount,
      paymentMethod: paymentMethod,
      referenceId: referenceId,
    );
    _transactions = await _api.getWalletTransactions();
    notifyListeners();
  }

  Future<void> withdrawFunds(double amount, String paymentMethod, String accountDetails) async {
    _wallet = await _api.withdrawFunds(
      amount: amount,
      paymentMethod: paymentMethod,
      accountDetails: accountDetails,
    );
    _transactions = await _api.getWalletTransactions();
    notifyListeners();
  }

  Future<Map<String, dynamic>> purchaseTopUp({
    required String gameId,
    required String packageId,
    required Map<String, String> playerDetails,
    required String paymentMethod,
    required double price,
  }) async {
    final result = await _api.createTopUpOrder(
      gameId: gameId,
      packageId: packageId,
      playerDetails: playerDetails,
      paymentMethod: paymentMethod,
      price: price,
    );
    _wallet = await _api.getWallet();
    _transactions = await _api.getWalletTransactions();
    notifyListeners();
    return result;
  }

  Future<Map<String, dynamic>> registerTournament({
    required String tournamentId,
    required String teamName,
    required Map<String, String> playerDetails,
  }) async {
    final result = await _api.registerTournament(
      tournamentId: tournamentId,
      teamName: teamName,
      playerDetails: playerDetails,
    );
    _wallet = await _api.getWallet();
    _myMatches = await _api.getMyTournaments();
    _tournaments = await _api.getTournaments();
    _transactions = await _api.getWalletTransactions();
    notifyListeners();
    return result;
  }

  Future<void> cancelTournamentRegistration(String tournamentId) async {
    await _api.cancelTournamentRegistration(tournamentId);
    _wallet = await _api.getWallet();
    _myMatches = await _api.getMyTournaments();
    _tournaments = await _api.getTournaments();
    _transactions = await _api.getWalletTransactions();
    notifyListeners();
  }

  Future<void> addAdminGame(GameModel game) async {
    await _api.addGame(game);
    _games = await _api.getGames();
    notifyListeners();
  }

  Future<void> toggleAdminGameStatus(String gameId, bool active) async {
    await _api.toggleGameStatus(gameId, active);
    _games = await _api.getGames();
    notifyListeners();
  }

  Future<void> addAdminPackage(String gameId, TopUpPackageModel package) async {
    await _api.addPackageToGame(gameId, package);
    _games = await _api.getGames();
    notifyListeners();
  }

  Future<void> awardArcadeReward({required double amount, required String gameTitle, required int score}) async {
    _wallet = _wallet.copyWith(
      availableBalance: _wallet.availableBalance + amount,
    );
    notifyListeners();
  }

  String formatPrice(double usdAmount, {bool includeUsd = false, bool allowFree = false}) {
    return _selectedCountry.formatPrice(usdAmount, includeUsd: includeUsd, allowFree: allowFree);
  }
}
