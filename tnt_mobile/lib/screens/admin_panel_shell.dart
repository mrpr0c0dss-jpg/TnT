import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/app_state.dart';
import '../models/tournament_model.dart';
import '../models/game_model.dart';
import 'arcade_screen.dart';

/// Global Smart Plus / Fintech Banking Hub Themed Admin Panel
/// Pixel-for-pixel replica of the clean light banking hub UI requested by the user,
/// with 100% platform-specific items: Gaming, TopUp, Tournaments, Earning Requests & Escrow.
class AdminPanelShell extends StatefulWidget {
  final AppState appState;

  const AdminPanelShell({super.key, required this.appState});

  @override
  State<AdminPanelShell> createState() => _AdminPanelShellState();
}

class _AdminPanelShellState extends State<AdminPanelShell> {
  // 4 Main Bottom Tabs: 0: Home, 1: Accounts, 2: Cards, 3: Hub
  int _currentTab = 0;
  bool _isBalanceMasked = true;
  String _hubSearchQuery = '';
  String _selectedHubCategory = 'All';

  // Sub-filter states
  String _orderStatusFilter = 'ALL';
  String _orderSearchQuery = '';
  String _earningStatusFilter = 'ALL';
  String _userRoleFilter = 'ALL';
  String _userSearchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.appState.reloadAdminData();
    });
  }

  // Visual Theme Constants (Global Smart Plus Theme)
  static const Color kBgColor = Color(0xFFF8F9FD);
  static const Color kSurfaceWhite = Color(0xFFFFFFFF);
  static const Color kTileBg = Color(0xFFEEF2F9);
  static const Color kMintTileBg = Color(0xFFCCE8DF);
  static const Color kMintText = Color(0xFF115E59);
  static const Color kPrimaryBlue = Color(0xFF0B5CDB);
  static const Color kVibrantBlue = Color(0xFF1E75FF);
  static const Color kSkyBlue = Color(0xFF4C91FF);
  static const Color kActivePillBg = Color(0xFFE2ECFF);
  static const Color kTextDark = Color(0xFF182230);
  static const Color kTextMuted = Color(0xFF64748B);
  static const Color kTextLight = Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      body: SafeArea(
        child: IndexedStack(
          index: _currentTab,
          children: [
            _buildHomeScreen(),
            _buildAccountsScreen(),
            _buildCardsScreen(),
            _buildHubScreen(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // ===========================================================================
  // SCREEN 0: HOME SCREEN (Exact Banking Style with TnT Platform Items)
  // ===========================================================================
  Widget _buildHomeScreen() {
    final user = widget.appState.currentUser;
    final overview = widget.appState.adminOverview;
    final escrow = overview['escrowTotal'] ?? 48250.0;
    final todayVolume = overview['todayVolume'] ?? 14820.0;
    const prizeReserves = 8500.0;
    final displayName = user.displayName.isNotEmpty ? user.displayName : 'Admin';
    final earnings = widget.appState.adminPrizes;
    final pendingEarnings = earnings.where((e) => e['status'] != 'PAID_OUT' && e['status'] != 'PAID').toList();

    return RefreshIndicator(
      onRefresh: () => widget.appState.reloadAdminData(),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // -------------------------------------------------------------------
          // TOP HEADER: Avatar + Hi, Babita! + Search, Bell, Eye Icons (NO OVERFLOW)
          // -------------------------------------------------------------------
          Row(
            children: [
              // Avatar circle with blue background and white person icon
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: kPrimaryBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hi, $displayName!',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kTextDark,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shield_rounded, size: 12, color: Color(0xFF10B981)),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Super Admin',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 10.5, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Search Icon (Compact touch targets to prevent overflow)
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                icon: const Icon(Icons.search, color: kTextDark, size: 22),
                onPressed: () => _openSearchDialog(),
              ),
              // Notification Bell with Red Badge
              Stack(
                alignment: Alignment.topRight,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    icon: const Icon(Icons.notifications_none_outlined, color: kTextDark, size: 22),
                    onPressed: () => _openAuditLogsModal(),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              // Eye Icon (Toggle Balance Visibility)
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                icon: Icon(
                  _isBalanceMasked ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: kTextDark,
                  size: 22,
                ),
                onPressed: () {
                  setState(() => _isBalanceMasked = !_isBalanceMasked);
                },
              ),
            ],
          ),
          const SizedBox(height: 18),

          // -------------------------------------------------------------------
          // TOP 4 ACTION TILES: TopUp Orders, Esports Tourneys, Earning Requests, View All
          // -------------------------------------------------------------------
          Row(
            children: [
              Expanded(
                child: _buildTopActionTile(
                  icon: Icons.phone_android_outlined,
                  label: 'TopUp\nOrders',
                  bgColor: kTileBg,
                  iconColor: kTextDark,
                  onTap: () => _openOrdersModal(),
                ),
              ),
              Expanded(
                child: _buildTopActionTile(
                  icon: Icons.emoji_events_outlined,
                  label: 'Esports\nTourneys',
                  bgColor: kTileBg,
                  iconColor: kTextDark,
                  onTap: () => setState(() => _currentTab = 2),
                ),
              ),
              Expanded(
                child: _buildTopActionTile(
                  icon: Icons.payments_outlined,
                  label: 'Earning\nRequests',
                  bgColor: kTileBg,
                  iconColor: kPrimaryBlue,
                  badgeCount: pendingEarnings.length,
                  onTap: () => _openEarningRequestsModal(),
                ),
              ),
              Expanded(
                child: _buildTopActionTile(
                  icon: Icons.grid_view,
                  label: 'View\nAll',
                  bgColor: kMintTileBg,
                  iconColor: kMintText,
                  onTap: () => setState(() => _currentTab = 3), // Switch to Hub
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // -------------------------------------------------------------------
          // EASY BALANCE: 3-TIER BLUE STACKED CARD (OUR PLATFORM LIQUIDITY)
          // -------------------------------------------------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Platform Vault & Liquidity',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kTextDark),
              ),
              GestureDetector(
                onTap: () => setState(() => _currentTab = 1),
                child: const Text(
                  'View Statement',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kPrimaryBlue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Stacked Card Container
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(
              children: [
                // Layer 1: Dark Royal Blue
                Container(
                  width: double.infinity,
                  color: kPrimaryBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TnT Master Escrow Vault (USD)',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _showEscrowDetailsDialog(),
                            child: const Icon(Icons.more_horiz, color: Colors.white, size: 24),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _isBalanceMasked ? '******' : '\$${escrow.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Available Settlement Liquidity • SQLite Reconciled',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                // Layer 2: Vibrant Blue
                Container(
                  width: double.infinity,
                  color: kVibrantBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '24h Diamonds & UC Volume (USD)',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                      Text(
                        _isBalanceMasked ? '******' : '\$${todayVolume.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                // Layer 3: Soft Sky Blue
                Container(
                  width: double.infinity,
                  color: kSkyBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tournament Prize Pool Reserves (USD)',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                      Text(
                        _isBalanceMasked ? '******' : '\$${prizeReserves.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // -------------------------------------------------------------------
          // NEW EARNING REQUESTS HIGHLIGHT SECTION (User Requested!)
          // -------------------------------------------------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Flexible(
                      child: Text(
                        'New Earning Requests',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kTextDark),
                      ),
                    ),
                    if (pendingEarnings.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${pendingEarnings.length} NEW',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _openEarningRequestsModal(),
                child: const Text(
                  'View All',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kPrimaryBlue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (pendingEarnings.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kSurfaceWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: const Center(
                child: Text('✨ No pending earning cashouts. All player payouts cleared.', style: TextStyle(color: kTextMuted, fontSize: 12)),
              ),
            )
          else
            Column(
              children: [
                for (final earn in pendingEarnings.take(2))
                  _buildEarningRequestCard(earn, isMini: true),
              ],
            ),
          const SizedBox(height: 24),

          // -------------------------------------------------------------------
          // RECENT TOP-UP ORDERS & ACTIVITY
          // -------------------------------------------------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Top-Up Orders',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kTextDark),
              ),
              GestureDetector(
                onTap: () => _openOrdersModal(),
                child: const Text(
                  'View All',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kPrimaryBlue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (widget.appState.adminOrders.isEmpty)
            _buildEmptyHistoryPlaceholder()
          else
            Column(
              children: [
                for (final ord in widget.appState.adminOrders.take(3))
                  _buildHistoryOrderTile(ord),
              ],
            ),
          const SizedBox(height: 24),

          // -------------------------------------------------------------------
          // FAVOURITES / QUICK OPERATIONS: Approve Slips & Scan QR
          // -------------------------------------------------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Quick Dispatch',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kTextDark),
              ),
              GestureDetector(
                onTap: () => setState(() => _currentTab = 3),
                child: const Text(
                  'View All',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kPrimaryBlue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              // Approve Slips Button (Royal Blue)
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _currentTab = 1),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: kPrimaryBlue,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Approve Slips',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Scan QR Button (Soft Mint Green)
              Expanded(
                child: InkWell(
                  onTap: () => _openScanQrDialog(),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD2EBE4),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_scanner_rounded, color: kMintText, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Scan Player QR',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kMintText),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Switch to Gamer Mode quick action banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: kSurfaceWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kTileBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.sports_esports_outlined, color: kPrimaryBlue, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Switch to Gamer View',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kTextDark),
                      ),
                      Text(
                        'Participate in tournaments, buy top-ups, or test gamer profile',
                        style: TextStyle(fontSize: 11, color: kTextMuted),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    widget.appState.setAdminPanelActive(false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🎮 Viewing as Gamer. Tap floating banner anytime to return to Admin Console.'),
                        backgroundColor: kPrimaryBlue,
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: kPrimaryBlue,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  child: const Text('SWITCH'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTopActionTile({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color iconColor,
    int? badgeCount,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              if (badgeCount != null && badgeCount > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: kTextDark,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHistoryPlaceholder() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: kSurfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 140,
                  height: 10,
                  child: DecoratedBox(decoration: BoxDecoration(color: Color(0xFFF1F5F9), borderRadius: BorderRadius.all(Radius.circular(4)))),
                ),
                SizedBox(height: 8),
                SizedBox(
                  width: 90,
                  height: 8,
                  child: DecoratedBox(decoration: BoxDecoration(color: Color(0xFFF1F5F9), borderRadius: BorderRadius.all(Radius.circular(4)))),
                ),
                SizedBox(height: 10),
                Text(
                  'Your digital orders and transactions will appear here',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryOrderTile(Map<String, dynamic> ord) {
    final status = ord['status'] ?? 'PENDING';
    final isDelivered = status == 'DELIVERED';
    final statusColor = isDelivered ? const Color(0xFF10B981) : const Color(0xFFF59E0B);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kSurfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kTileBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.shopping_bag_outlined, color: kPrimaryBlue, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${ord['game']} — ${ord['package']}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kTextDark),
                ),
                Text(
                  'UID: ${ord['player_id']} • ${ord['id']}',
                  style: const TextStyle(fontSize: 11, color: kTextMuted),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+\$${(ord['price'] ?? 0.0).toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kTextDark),
              ),
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status.toString().replaceAll('_', ' '),
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SCREEN 3: HUB SCREEN (Matches Screenshot 1 with TnT Items)
  // ===========================================================================
  Widget _buildHubScreen() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // ---------------------------------------------------------------------
        // Title: "Hub"
        // ---------------------------------------------------------------------
        const Text(
          'Hub',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: kTextDark,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 14),

        // ---------------------------------------------------------------------
        // Search Bar (Rounded pill shape)
        // ---------------------------------------------------------------------
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F4F9),
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              const Icon(Icons.search, color: kTextLight, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  style: const TextStyle(color: kTextDark, fontSize: 15),
                  decoration: const InputDecoration(
                    hintText: 'Search admin tools, games, players...',
                    hintStyle: TextStyle(color: kTextLight, fontSize: 15),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (val) => setState(() => _hubSearchQuery = val),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Horizontal Category Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['All', 'Top-Up', 'Tournaments', 'Earnings', 'AI Vault', 'Security'].map((cat) {
              final isSel = _selectedHubCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 18),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedHubCategory = cat),
                  child: Text(
                    cat,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                      color: isSel ? kPrimaryBlue : kTextMuted,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),

        // ---------------------------------------------------------------------
        // CATEGORY: Gaming & Esports Operations
        // ---------------------------------------------------------------------
        const Text(
          'Gaming & Esports Operations',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: kTextDark,
          ),
        ),
        const SizedBox(height: 14),

        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _buildHubTile(
              icon: Icons.phone_android_outlined,
              label: 'TopUp\nOrders',
              onTap: () => _openOrdersModal(),
            ),
            const SizedBox(width: 22),
            _buildHubTile(
              icon: Icons.emoji_events_outlined,
              label: 'Esports\nArenas',
              onTap: () => setState(() => _currentTab = 2), // Tournaments
            ),
            const SizedBox(width: 22),
            _buildHubTile(
              icon: Icons.vpn_key_outlined,
              label: 'AI Key\nVault',
              onTap: () => _openAiKeysModal(),
            ),
          ],
        ),
        const SizedBox(height: 26),

        // ---------------------------------------------------------------------
        // CATEGORY: EARNINGS & PAYOUTS (Our Items!)
        // ---------------------------------------------------------------------
        const Text(
          'EARNINGS & PAYOUTS',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF475569),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 14),

        Row(
          children: [
            _buildHubTile(
              icon: Icons.payments_outlined,
              label: 'Earning\nRequests',
              onTap: () => _openEarningRequestsModal(),
            ),
            const SizedBox(width: 22),
            _buildHubTile(
              icon: Icons.receipt_long_outlined,
              label: 'Deposit\nSlips',
              onTap: () => setState(() => _currentTab = 1),
            ),
          ],
        ),
        const SizedBox(height: 26),

        // ---------------------------------------------------------------------
        // CATEGORY: Platform Governance & Management
        // ---------------------------------------------------------------------
        const Text(
          'Platform Governance',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: kTextDark,
          ),
        ),
        const SizedBox(height: 14),

        // Grid of Helpful Management Services
        Wrap(
          spacing: 22,
          runSpacing: 20,
          children: [
            _buildHubTile(
              icon: Icons.games_outlined,
              label: 'Game\nCatalog',
              onTap: () => _openGameCatalogModal(),
            ),
            _buildHubTile(
              icon: Icons.sports_esports_outlined,
              label: 'Instant\nArcade',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ArcadeScreen(appState: widget.appState)),
                );
              },
            ),
            _buildHubTile(
              icon: Icons.currency_exchange_outlined,
              label: 'Exchange\nRates',
              onTap: () => _showExchangeRatesDialog(),
            ),
            _buildHubTile(
              icon: Icons.people_outline,
              label: 'Player\nDirectory',
              onTap: () => _openUserDirectoryModal(),
            ),
            _buildHubTile(
              icon: Icons.meeting_room_outlined,
              label: 'Lobby Room\nCreds',
              onTap: () => setState(() => _currentTab = 2),
            ),
            _buildHubTile(
              icon: Icons.history_edu_outlined,
              label: 'Security\nAudit',
              onTap: () => _openAuditLogsModal(),
            ),
            _buildHubTile(
              icon: Icons.monitor_heart_outlined,
              label: 'System\nHealth',
              onTap: () => _showSystemHealthDialog(),
            ),
            _buildHubTile(
              icon: Icons.visibility_outlined,
              label: 'Gamer\nView',
              onTap: () {
                widget.appState.setAdminPanelActive(false);
              },
            ),
          ],
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  Widget _buildHubTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: kTileBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: kTextDark, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: kTextDark,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SCREEN 1: ACCOUNTS SCREEN (Earning Requests & Deposit Verification Slips)
  // ===========================================================================
  Widget _buildAccountsScreen() {
    final payments = widget.appState.adminPayments;
    final earnings = widget.appState.adminPrizes;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Accounts & Statements',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kTextDark),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: kPrimaryBlue),
              onPressed: () => widget.appState.reloadAdminData(),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Liquidity Summary Cards
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kSurfaceWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Global IME Escrow (NPR)', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: kTextMuted, fontWeight: FontWeight.bold)),
                    SizedBox(height: 6),
                    Text('NPR 4,820,500', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kPrimaryBlue)),
                    SizedBox(height: 2),
                    Text('Local Bank Settlement', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: Color(0xFF10B981))),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kSurfaceWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('USD Settlement Vault', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: kTextMuted, fontWeight: FontWeight.bold)),
                    SizedBox(height: 6),
                    Text('\$48,250.00', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                    SizedBox(height: 2),
                    Text('Stripe Reconciled', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: Color(0xFF10B981))),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // ---------------------------------------------------------------------
        // SECTION 1: PLAYER EARNING CASH-OUT REQUESTS (PROMINENT & DETAILED)
        // ---------------------------------------------------------------------
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  const Flexible(
                    child: Text(
                      'Player Earning Requests',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kTextDark),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: kPrimaryBlue.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${earnings.length} Requests',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kPrimaryBlue),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => _openEarningRequestsModal(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Manage All', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: kPrimaryBlue)),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (earnings.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: kSurfaceWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: const Center(
              child: Text('No earning withdrawal requests.', style: TextStyle(color: kTextMuted, fontSize: 12)),
            ),
          )
        else
          Column(
            children: [
              for (final earn in earnings)
                _buildEarningRequestCard(earn, isMini: false),
            ],
          ),
        const SizedBox(height: 24),

        // ---------------------------------------------------------------------
        // SECTION 2: PENDING DEPOSIT VERIFICATION SLIPS
        // ---------------------------------------------------------------------
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Deposit Verification Slips (${payments.length})',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kTextDark),
              ),
            ),
            if (payments.isNotEmpty) ...[
              const SizedBox(width: 8),
              const Text(
                'Review Required',
                style: TextStyle(fontSize: 11, color: Color(0xFFF59E0B), fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),

        if (payments.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: kSurfaceWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: const Center(
              child: Text(
                '✨ All deposit slips reviewed. Zero pending approvals.',
                style: TextStyle(fontSize: 13, color: kTextMuted),
              ),
            ),
          )
        else
          Column(
            children: [
              for (final pay in payments)
                _buildPaymentSlipCard(pay),
            ],
          ),
      ],
    );
  }

  // ===========================================================================
  // EARNING REQUEST CARD COMPONENT (Proper Details, Gateway, Account, Actions)
  // ===========================================================================
  Widget _buildEarningRequestCard(Map<String, dynamic> earn, {required bool isMini}) {
    final status = earn['status'] ?? 'PENDING_APPROVAL';
    final isPaid = status == 'PAID_OUT' || status == 'PAID';
    final isPendingFinance = status == 'AWAITING_FINANCE_APPROVAL';
    final isNew = earn['is_new'] == true && !isPaid;

    Color badgeColor = const Color(0xFFF59E0B);
    String statusLabel = 'Awaiting Approval';
    if (isPaid) {
      badgeColor = const Color(0xFF10B981);
      statusLabel = 'Paid Out';
    } else if (isPendingFinance) {
      badgeColor = const Color(0xFF6366F1);
      statusLabel = 'Finance Sign-Off';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isNew ? kPrimaryBlue.withOpacity(0.4) : const Color(0xFFE2E8F0),
          width: isNew ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Payout ID + New Tag + Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        earn['id'] ?? '#EARN',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kPrimaryBlue),
                      ),
                    ),
                    if (isNew) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Player Name & Tournament Winning Details
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: kTileBg,
                child: const Icon(Icons.person, color: kPrimaryBlue, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (earn['winner'] ?? earn['user_name'] ?? earn['user_email'] ?? 'Tournament Champion').toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kTextDark),
                    ),
                    Text(
                      (earn['tournament'] ?? earn['tournament_title'] ?? 'Esports Match Earnings').toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: kTextMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '+\$${((earn['amount'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
                  ),
                  Text(
                    (earn['local_amount'] ?? 'Rs. ${(((earn['amount'] as num?)?.toDouble() ?? 0.0) * 133.5).toStringAsFixed(0)}').toString(),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kTextMuted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Payout Details Box (Account number, Gateway, 1-Click Copy - Never null: null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: kTileBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_outlined, size: 16, color: kPrimaryBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    () {
                      final details = earn['payout_details']?.toString();
                      if (details != null && details.isNotEmpty && details != 'null: null') {
                        return details;
                      }
                      if (earn['payout_method'] != null && earn['account_number'] != null) {
                        return '${earn['payout_method']}: ${earn['account_number']}';
                      }
                      final ref = earn['provider_reference']?.toString();
                      if (ref != null && ref.isNotEmpty && ref != 'PLATFORM_WALLET_LEDGER') {
                        return 'Gateway Ref: $ref';
                      }
                      return 'Platform Wallet Ledger • Instant Payout';
                    }(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: kTextDark),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 14, color: kPrimaryBlue),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Copy Payout ID / Account',
                  onPressed: () {
                    final target = (earn['account_number'] ?? earn['payout_details'] ?? earn['id'] ?? '').toString();
                    Clipboard.setData(ClipboardData(text: target));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Payout account copied to clipboard!'), duration: Duration(seconds: 1)),
                    );
                  },
                ),
              ],
            ),
          ),

          // Actions (Responsive Wrap to guarantee ZERO overflow on any screen)
          if (!isPaid) ...[
            const Divider(height: 20, color: Color(0xFFF1F5F9)),
            SizedBox(
              width: double.infinity,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () => _showRejectEarningDialog(earn),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Reject', style: TextStyle(color: Color(0xFFEF4444), fontSize: 11)),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await widget.appState.approveAdminPrize(earn['id']);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✅ Earning payout \$${earn['amount']} approved & disbursed to ${earn['winner']}!'),
                            backgroundColor: const Color(0xFF10B981),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.check_circle_outline, size: 15),
                    label: Text(isPendingFinance ? 'Finance Sign-Off' : 'Approve & Pay'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPendingFinance ? const Color(0xFF6366F1) : const Color(0xFF10B981),
                      textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentSlipCard(Map<String, dynamic> pay) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kSurfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'SLIP #${pay['slip_no']}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kPrimaryBlue),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                pay['created_at'] ?? 'Just now',
                style: const TextStyle(fontSize: 11, color: kTextMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pay['user_name'] ?? 'User', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kTextDark)),
                    Text('Via ${pay['method']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: kTextMuted)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '+\$${(pay['amount'] ?? 0.0).toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
              ),
            ],
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          SizedBox(
            width: double.infinity,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => widget.appState.verifyAdminPayment(pay['id'], approve: false, note: 'Rejected by admin'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFEF4444)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Reject Slip', style: TextStyle(color: Color(0xFFEF4444), fontSize: 11.5)),
                ),
                ElevatedButton.icon(
                  onPressed: () => widget.appState.verifyAdminPayment(pay['id'], approve: true),
                  icon: const Icon(Icons.check, size: 15),
                  label: const Text('Approve & Credit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SCREEN 2: CARDS SCREEN (Tournaments & AI Subscription Cards)
  // ===========================================================================
  Widget _buildCardsScreen() {
    final tournaments = widget.appState.tournaments;
    final keys = widget.appState.adminAiKeys;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Esports Lobbies & Cards',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kTextDark),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _showCreateTournamentDialog(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('New Tourney'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryBlue,
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Tournament Cards
        for (final tour in tournaments)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kSurfaceWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        tour.title,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kTextDark),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: kActivePillBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tour.status,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: kPrimaryBlue),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${tour.gameId} • Mode: ${tour.mode} • Region: ${tour.region}',
                  style: const TextStyle(fontSize: 12, color: kTextMuted),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('Prize: \$${tour.prizePool.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                    const SizedBox(width: 14),
                    Text('Entry: \$${tour.entryFee.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: kTextMuted)),
                    const SizedBox(width: 14),
                    Text('Slots: ${tour.registeredCount}/${tour.maxSlots}', style: const TextStyle(fontSize: 12, color: Color(0xFFF59E0B))),
                  ],
                ),
                const Divider(height: 20, color: Color(0xFFF1F5F9)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Room ID: ${tour.roomId ?? "UNASSIGNED"}', style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: kPrimaryBlue, fontWeight: FontWeight.bold)),
                        Text('Pass: ${tour.roomPassword ?? "NOT SET"}', style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: kTextMuted)),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showReleaseCredentialsDialog(tour),
                      icon: const Icon(Icons.key, size: 14),
                      label: const Text('Broadcast Creds'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kTileBg,
                        foregroundColor: kTextDark,
                        elevation: 0,
                        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),

        // AI Key Vault Cards
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'AI Subscription Cards',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kTextDark),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: kPrimaryBlue),
              onPressed: () => _showAddKeyDialog(),
            ),
          ],
        ),
        const SizedBox(height: 10),

        for (final k in keys)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kSurfaceWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.smart_toy_outlined, color: kPrimaryBlue, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(k['tool'] ?? 'AI Tool', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kTextDark)),
                      Text(k['code'] ?? '', style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: kTextMuted)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: k['status'] == 'AVAILABLE' ? const Color(0xFF10B981).withOpacity(0.12) : const Color(0xFFEF4444).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    k['status'] ?? 'UNKNOWN',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: k['status'] == 'AVAILABLE' ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ===========================================================================
  // BOTTOM NAVIGATION BAR (Exact Match: Home, Accounts, Cards, Hub with Active Pill)
  // ===========================================================================
  Widget _buildBottomNavBar() {
    return Container(
      decoration: const BoxDecoration(
        color: kSurfaceWhite,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            children: [
              _buildBottomNavItem(
                index: 0,
                icon: Icons.public,
                label: 'Home',
              ),
              _buildBottomNavItem(
                index: 1,
                icon: Icons.account_balance_outlined,
                label: 'Accounts',
              ),
              _buildBottomNavItem(
                index: 2,
                icon: Icons.credit_card_outlined,
                label: 'Cards',
              ),
              _buildBottomNavItem(
                index: 3,
                icon: Icons.grid_view_rounded,
                label: 'Hub',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentTab = index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? kActivePillBg : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 22,
                color: isSelected ? kPrimaryBlue : kTextMuted,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? kPrimaryBlue : kTextMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // DEDICATED EARNING REQUESTS MODAL (Requested by User)
  // ===========================================================================
  void _openEarningRequestsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kBgColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setMState) {
            final allEarnings = widget.appState.adminPrizes;
            final earnings = allEarnings.where((e) {
              if (_earningStatusFilter == 'PENDING' && (e['status'] == 'PAID_OUT' || e['status'] == 'PAID')) return false;
              if (_earningStatusFilter == 'PAID' && (e['status'] != 'PAID_OUT' && e['status'] != 'PAID')) return false;
              return true;
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.88,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Player Earning Cash-Outs', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextDark)),
                            Text('Review, approve, and disburse gamer winnings', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: kTextMuted)),
                          ],
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Filter Chips (All, Pending, Paid Out)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: const Text('All Requests', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          selected: _earningStatusFilter == 'ALL',
                          selectedColor: kPrimaryBlue,
                          labelStyle: TextStyle(color: _earningStatusFilter == 'ALL' ? Colors.white : kTextDark),
                          onSelected: (_) => setMState(() => _earningStatusFilter = 'ALL'),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Pending Approval', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          selected: _earningStatusFilter == 'PENDING',
                          selectedColor: const Color(0xFFF59E0B),
                          labelStyle: TextStyle(color: _earningStatusFilter == 'PENDING' ? Colors.white : kTextDark),
                          onSelected: (_) => setMState(() => _earningStatusFilter = 'PENDING'),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Paid Out', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          selected: _earningStatusFilter == 'PAID',
                          selectedColor: const Color(0xFF10B981),
                          labelStyle: TextStyle(color: _earningStatusFilter == 'PAID' ? Colors.white : kTextDark),
                          onSelected: (_) => setMState(() => _earningStatusFilter = 'PAID'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  Expanded(
                    child: earnings.isEmpty
                        ? const Center(
                            child: Text('No earning requests found in this filter.', style: TextStyle(color: kTextMuted)),
                          )
                        : ListView.builder(
                            itemCount: earnings.length,
                            itemBuilder: (c, i) => _buildEarningRequestCard(earnings[i], isMini: false),
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showRejectEarningDialog(Map<String, dynamic> earn) {
    final reasonCtrl = TextEditingController(text: 'Scorecard discrepancy / Invalid payment details');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceWhite,
        title: Text('Reject Earning Payout #${earn['id']}?', style: const TextStyle(fontWeight: FontWeight.bold, color: kTextDark)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Player: ${earn['winner']} • Amount: \$${earn['amount']}', style: const TextStyle(fontWeight: FontWeight.bold, color: kTextDark)),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(labelText: 'Rejection Reason / Note to Player'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () async {
              await widget.appState.rejectAdminPrize(earn['id'], reason: reasonCtrl.text.trim());
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Confirm Rejection'),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TOP-UP ORDERS MODAL
  // ===========================================================================
  void _openOrdersModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kBgColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setMState) {
            final orders = widget.appState.adminOrders.where((o) {
              if (_orderStatusFilter != 'ALL' && o['status'] != _orderStatusFilter) return false;
              if (_orderSearchQuery.isNotEmpty) {
                final q = _orderSearchQuery.toLowerCase();
                final id = (o['id'] ?? '').toString().toLowerCase();
                final pid = (o['player_id'] ?? '').toString().toLowerCase();
                final g = (o['game'] ?? '').toString().toLowerCase();
                if (!id.contains(q) && !pid.contains(q) && !g.contains(q)) return false;
              }
              return true;
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Top-Up Delivery Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextDark)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    style: const TextStyle(fontSize: 13, color: kTextDark),
                    decoration: InputDecoration(
                      hintText: 'Search by Order ID, UID, or Game...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: kSurfaceWhite,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                    onChanged: (val) {
                      setMState(() => _orderSearchQuery = val);
                      setState(() => _orderSearchQuery = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: orders.isEmpty
                        ? const Center(child: Text('No orders match your search.', style: TextStyle(color: kTextMuted)))
                        : ListView.builder(
                            itemCount: orders.length,
                            itemBuilder: (c, i) => _buildModalOrderCard(orders[i], setMState),
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModalOrderCard(Map<String, dynamic> ord, StateSetter setMState) {
    final status = ord['status'] ?? 'PENDING';
    final isDelivered = status == 'DELIVERED';
    final isPending = status == 'PENDING_DELIVERY';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kSurfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(ord['id'] ?? '#ORD', style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryBlue)),
              Text(ord['created_at'] ?? '', style: const TextStyle(fontSize: 11, color: kTextMuted)),
            ],
          ),
          const SizedBox(height: 6),
          Text('${ord['game']} — ${ord['package']}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kTextDark)),
          Text('Target Player UID: ${ord['player_id']}', style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: kPrimaryBlue)),
          if (isPending) ...[
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () async {
                    await widget.appState.refundAdminOrder(ord['id']);
                    setMState(() {});
                  },
                  child: const Text('Refund', style: TextStyle(color: Color(0xFFEF4444))),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    await widget.appState.markAdminOrderDelivered(ord['id']);
                    setMState(() {});
                  },
                  icon: const Icon(Icons.check, size: 14),
                  label: const Text('Mark Delivered'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _openUserDirectoryModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kBgColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setMState) {
            final users = widget.appState.adminUsers;
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Player & Staff Directory', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextDark)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (c, i) {
                        final u = users[i];
                        final isBanned = u['status'] == 'banned';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: kSurfaceWhite,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: kTileBg,
                                child: Text((u['display_name'] ?? 'U')[0].toUpperCase(), style: const TextStyle(color: kPrimaryBlue, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(u['display_name'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold, color: kTextDark)),
                                    Text('${u['email']} • Role: ${u['role']}', style: const TextStyle(fontSize: 11, color: kTextMuted)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(isBanned ? Icons.lock_open : Icons.block, color: isBanned ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                                onPressed: () async {
                                  await widget.appState.toggleAdminUserBan(u['id'], !isBanned, 'Admin action');
                                  setMState(() {});
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openAiKeysModal() {
    setState(() => _currentTab = 2);
  }

  void _openAuditLogsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kBgColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final logs = widget.appState.adminAuditLogs;
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Audit & Security Log', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextDark)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (c, i) {
                    final l = logs[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kSurfaceWhite,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: kActivePillBg, borderRadius: BorderRadius.circular(4)),
                            child: Text(l['action'] ?? '', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: kPrimaryBlue)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(l['reason'] ?? '', style: const TextStyle(fontSize: 12, color: kTextDark)),
                          ),
                          Text(l['time'] ?? '', style: const TextStyle(fontSize: 10, color: kTextMuted)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCreateTournamentDialog() {
    final titleCtrl = TextEditingController();
    final gameCtrl = TextEditingController(text: 'PUBG Mobile');
    final prizeCtrl = TextEditingController(text: '1000');
    final feeCtrl = TextEditingController(text: '50');
    final slotsCtrl = TextEditingController(text: '100');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceWhite,
        title: const Text('Create New Tournament', style: TextStyle(color: kTextDark, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Tournament Title')),
              TextField(controller: gameCtrl, decoration: const InputDecoration(labelText: 'Game Title')),
              TextField(controller: prizeCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Prize Pool (\$)')),
              TextField(controller: feeCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Entry Fee (\$)')),
              TextField(controller: slotsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Max Slots')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kPrimaryBlue),
            onPressed: () async {
              if (titleCtrl.text.isNotEmpty) {
                final now = DateTime.now();
                final prize = double.tryParse(prizeCtrl.text) ?? 1000.0;
                await widget.appState.addAdminTournament(
                  TournamentModel(
                    id: 'tour_${now.millisecondsSinceEpoch}',
                    title: titleCtrl.text.trim(),
                    gameId: gameCtrl.text.trim(),
                    mode: 'SQUAD',
                    region: 'Asia',
                    banner: 'https://images.unsplash.com/photo-1542751371-adc38448a05e?auto=format&fit=crop&w=600&q=80',
                    description: 'Competitive Esports Arena tournament hosted by TnT Administration.',
                    entryFee: double.tryParse(feeCtrl.text) ?? 50.0,
                    prizePool: prize,
                    prizeSplit: [
                      PrizeSplit(place: 1, percent: 60.0, amount: prize * 0.60),
                      PrizeSplit(place: 2, percent: 25.0, amount: prize * 0.25),
                      PrizeSplit(place: 3, percent: 15.0, amount: prize * 0.15),
                    ],
                    maxSlots: int.tryParse(slotsCtrl.text) ?? 100,
                    registeredCount: 0,
                    startsAt: now.add(const Duration(hours: 3)),
                    registrationClosesAt: now.add(const Duration(hours: 2)),
                    checkInOpensAt: now.add(const Duration(hours: 2, minutes: 45)),
                    roomReleaseAt: now.add(const Duration(hours: 2, minutes: 50)),
                    status: 'Upcoming',
                    rules: 'Fair play only. Emulators prohibited. Check-in mandatory 15 minutes prior to match.',
                    isUserRegistered: false,
                    roomId: null,
                    roomPassword: null,
                  ),
                );
                if (mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // GAME CATALOG & PACKAGES MANAGEMENT MODAL (Roblox, Free Fire, PUBG, etc.)
  // ===========================================================================
  void _openGameCatalogModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kBgColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setMState) {
            final games = widget.appState.games;

            return Container(
              height: MediaQuery.of(context).size.height * 0.88,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Game Catalog & Packages',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextDark),
                            ),
                            Text(
                              'Configure top-up games, robux/diamond packages & active status',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: kTextMuted),
                            ),
                          ],
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showAddGameDialog();
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add New Game to Catalog'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: games.isEmpty
                        ? const Center(child: Text('No games configured in catalog.', style: TextStyle(color: kTextMuted)))
                        : ListView.builder(
                            itemCount: games.length,
                            itemBuilder: (c, i) {
                              final g = games[i];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: kSurfaceWhite,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(g.icon, style: const TextStyle(fontSize: 22)),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                g.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kTextDark),
                                              ),
                                              Text(
                                                '${g.category} • ${g.packages.length} Packages',
                                                style: const TextStyle(fontSize: 11, color: kTextMuted),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Switch.adaptive(
                                          value: g.active,
                                          activeColor: kPrimaryBlue,
                                          onChanged: (val) async {
                                            await widget.appState.toggleAdminGameStatus(g.id, val);
                                            setMState(() {});
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: [
                                          for (final p in g.packages)
                                            Container(
                                              margin: const EdgeInsets.only(right: 6),
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: kTileBg,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                '${p.name} (\$${p.price.toStringAsFixed(2)})',
                                                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: kTextDark),
                                              ),
                                            ),
                                          ActionChip(
                                            avatar: const Icon(Icons.add, size: 14, color: kPrimaryBlue),
                                            label: const Text('+ Pkg', style: TextStyle(fontSize: 10.5, color: kPrimaryBlue, fontWeight: FontWeight.bold)),
                                            padding: EdgeInsets.zero,
                                            visualDensity: VisualDensity.compact,
                                            backgroundColor: kActivePillBg,
                                            onPressed: () {
                                              Navigator.pop(ctx);
                                              _showAddPackageDialog(g);
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddGameDialog() {
    final nameCtrl = TextEditingController();
    final catCtrl = TextEditingController(text: 'Sandbox / Action');
    final iconCtrl = TextEditingController(text: '🎮');
    final fieldCtrl = TextEditingController(text: 'Player UID / Username');
    final pkgNameCtrl = TextEditingController(text: '100 Credits');
    final pkgPriceCtrl = TextEditingController(text: '1.49');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceWhite,
        title: const Text('Add New Game to Catalog', style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Game Title (e.g. Roblox, Minecraft)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: catCtrl,
                decoration: const InputDecoration(labelText: 'Category (e.g. Sandbox, MOBA)'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: iconCtrl,
                      decoration: const InputDecoration(labelText: 'Emoji Icon (e.g. 🧱, 🎮)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: fieldCtrl,
                      decoration: const InputDecoration(labelText: 'Player Field (e.g. Username)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Initial Top-Up Package:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kTextMuted)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: pkgNameCtrl,
                      decoration: const InputDecoration(labelText: 'Pkg Name (e.g. 100 Robux)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: pkgPriceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Price (\$)'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kPrimaryBlue),
            onPressed: () async {
              if (nameCtrl.text.trim().isNotEmpty) {
                final id = 'game_${nameCtrl.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}';
                final price = double.tryParse(pkgPriceCtrl.text.trim()) ?? 1.49;
                final newGame = GameModel(
                  id: id,
                  name: nameCtrl.text.trim(),
                  slug: nameCtrl.text.trim().toLowerCase().replaceAll(' ', '-'),
                  category: catCtrl.text.trim(),
                  icon: iconCtrl.text.trim().isEmpty ? '🎮' : iconCtrl.text.trim(),
                  banner: 'assets/games/roblox.webp',
                  active: true,
                  deliveryMethod: 'auto_api',
                  requiredFields: [
                    PlayerFieldRequirement(
                      key: 'player_id',
                      label: fieldCtrl.text.trim(),
                      regex: r'^.+$',
                      hint: 'Enter ${fieldCtrl.text.trim()}',
                    ),
                  ],
                  packages: [
                    TopUpPackageModel(
                      id: 'pkg_${id}_initial',
                      gameId: id,
                      name: pkgNameCtrl.text.trim(),
                      itemQuantity: pkgNameCtrl.text.trim(),
                      price: price,
                      sortOrder: 1,
                    ),
                  ],
                );

                await widget.appState.addAdminGame(newGame);
                if (mounted) Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('🎮 Game "${nameCtrl.text}" published to Top-Up store!'),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
              }
            },
            child: const Text('Save & Publish'),
          ),
        ],
      ),
    );
  }

  void _showAddPackageDialog(GameModel game) {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final badgeCtrl = TextEditingController(text: 'Popular');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceWhite,
        title: Text('Add Package to ${game.name}', style: const TextStyle(fontWeight: FontWeight.bold, color: kTextDark)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Package Name (e.g. 400 Robux)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: qtyCtrl,
              decoration: const InputDecoration(labelText: 'Quantity (e.g. 400 R\$)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Price in USD (\$)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: badgeCtrl,
              decoration: const InputDecoration(labelText: 'Promo Badge (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kPrimaryBlue),
            onPressed: () async {
              if (nameCtrl.text.trim().isNotEmpty) {
                final price = double.tryParse(priceCtrl.text.trim()) ?? 0.99;
                final pkgId = 'pkg_${game.id}_${DateTime.now().millisecondsSinceEpoch % 10000}';
                await widget.appState.addAdminPackage(
                  game.id,
                  TopUpPackageModel(
                    id: pkgId,
                    gameId: game.id,
                    name: nameCtrl.text.trim(),
                    itemQuantity: qtyCtrl.text.trim().isEmpty ? nameCtrl.text.trim() : qtyCtrl.text.trim(),
                    price: price,
                    badge: badgeCtrl.text.trim().isEmpty ? null : badgeCtrl.text.trim(),
                    sortOrder: game.packages.length + 1,
                  ),
                );
                if (mounted) Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ New package added to ${game.name}!'),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
              }
            },
            child: const Text('Add Package'),
          ),
        ],
      ),
    );
  }

  void _showReleaseCredentialsDialog(TournamentModel tour) {
    final roomCtrl = TextEditingController(text: tour.roomId ?? '');
    final passCtrl = TextEditingController(text: tour.roomPassword ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceWhite,
        title: Text('Lobby Room: ${tour.title}', style: const TextStyle(color: kTextDark, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: roomCtrl, decoration: const InputDecoration(labelText: 'Custom Room ID')),
            TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'Lobby Password')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kPrimaryBlue),
            onPressed: () async {
              await widget.appState.releaseRoomCredentials(
                tour.id,
                roomCtrl.text.trim(),
                passCtrl.text.trim(),
              );
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Release to Players'),
          ),
        ],
      ),
    );
  }

  void _showAddKeyDialog() {
    final toolCtrl = TextEditingController(text: 'ChatGPT Plus');
    final codeCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceWhite,
        title: const Text('Add AI License Key', style: TextStyle(color: kTextDark, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: toolCtrl, decoration: const InputDecoration(labelText: 'AI Software')),
            TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Activation Key Code')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kPrimaryBlue),
            onPressed: () async {
              if (codeCtrl.text.isNotEmpty) {
                await widget.appState.createAdminAiKey(
                  toolCtrl.text.trim(),
                  codeCtrl.text.trim(),
                );
                if (mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Save to Vault'),
          ),
        ],
      ),
    );
  }

  void _showEscrowDetailsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceWhite,
        title: const Text('Platform Liquidity Breakdown', style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Player Wallet Escrow: \$24,930.00'),
            SizedBox(height: 6),
            Text('• Active Tournament Prize Lock: \$14,820.00'),
            SizedBox(height: 6),
            Text('• AI Prepaid License Pool: \$8,500.00'),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kPrimaryBlue),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _openSearchDialog() {
    showSearch(
      context: context,
      delegate: _AdminSearchDelegate(appState: widget.appState),
    );
  }

  void _openScanQrDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📷 Ready to scan payment deposit slip or player UID QR code.'),
        backgroundColor: kPrimaryBlue,
      ),
    );
  }

  void _showExchangeRatesDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceWhite,
        title: const Text('Live Exchange Rates for Gaming TopUp', style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text('USD / NPR (Local Currency)'), trailing: Text('133.50 रु', style: TextStyle(fontWeight: FontWeight.bold, color: kPrimaryBlue))),
            ListTile(title: Text('INR / NPR (eSports Hub)'), trailing: Text('1.60 रु', style: TextStyle(fontWeight: FontWeight.bold))),
            ListTile(title: Text('USD / INR'), trailing: Text('83.40 ₹', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done')),
        ],
      ),
    );
  }

  void _showSystemHealthDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceWhite,
        title: const Text('System & Ledger Health', style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Status: 100% NOMINAL', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text('• Database: SQLite WAL Synced'),
            Text('• Firebase Auth: Connected'),
            Text('• Cloudflare R2: Connected'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}

class _AdminSearchDelegate extends SearchDelegate<String> {
  final AppState appState;
  _AdminSearchDelegate({required this.appState});

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, ''));
  }

  @override
  Widget buildResults(BuildContext context) {
    return Center(child: Text('Search results for "$query"'));
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.payments_outlined, color: Color(0xFF0B5CDB)),
          title: const Text('Review Player Earning Requests'),
          onTap: () => close(context, 'earnings'),
        ),
        ListTile(
          leading: const Icon(Icons.shopping_bag_outlined),
          title: const Text('View Pending Top-Up Orders'),
          onTap: () => close(context, 'orders'),
        ),
        ListTile(
          leading: const Icon(Icons.emoji_events_outlined),
          title: const Text('Manage Tournament Lobbies'),
          onTap: () => close(context, 'tournaments'),
        ),
        ListTile(
          leading: const Icon(Icons.receipt_long_outlined),
          title: const Text('Verify Deposit Slips'),
          onTap: () => close(context, 'slips'),
        ),
      ],
    );
  }
}
