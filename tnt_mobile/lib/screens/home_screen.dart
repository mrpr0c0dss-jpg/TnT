import 'dart:async';
import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/tnt_image.dart';
import '../widgets/checkout_dialog.dart';
import 'in_app_game_screen.dart';
import '../services/arcade_games_engine.dart';
import '../models/game_model.dart';
import '../models/tournament_model.dart';

class HomeScreen extends StatefulWidget {
  final AppState appState;

  const HomeScreen({super.key, required this.appState});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _bannerController = PageController();
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;

  final List<Map<String, dynamic>> _heroBanners = [
    {
      'tag': 'SEASON 4 ARENA LIVE',
      'tagColor': AppTheme.fireOrange,
      'title': 'Apex Champions Cup S4',
      'subtitle': 'Squad Showdown • 38/48 Slots Filled',
      'price': 400.0,
      'buttonText': 'Join Now',
      'image': 'assets/banner/tnt_esports_arena.webp',
      'tabIndex': 2,
    },
    {
      'tag': 'INSTANT 1-CLICK TOP-UP',
      'tagColor': AppTheme.cyan,
      'title': 'Free Fire & PUBG Mobile UC',
      'subtitle': 'Instant UID Delivery • Official Partner',
      'price': 0.99,
      'pricePrefix': 'From ',
      'buttonText': 'Top-Up Now',
      'image': 'assets/banner/neon_loot_battle_royale.webp',
      'tabIndex': 1,
    },
    {
      'tag': 'PLAYABLE ARCADE',
      'tagColor': const Color(0xFF10B981),
      'title': 'Cricket Super Over & 3D Stunt',
      'subtitle': 'Instant 60 FPS Browser & In-App Games',
      'price': 100.0,
      'pricePrefix': 'Prize: ',
      'buttonText': 'Play Free',
      'image': 'assets/banner/cricket_stadium_lights.webp',
      'tabIndex': 4,
    },
    {
      'tag': 'AI TOOLS VAULT',
      'tagColor': AppTheme.purple,
      'title': 'ChatGPT Plus & Claude 3.5 Pro',
      'subtitle': 'Instant License Key Allocation • Official Pro Vault',
      'price': 19.99,
      'pricePrefix': 'From ',
      'buttonText': 'Explore AI',
      'image': 'assets/banner/neon_ai_workspace.webp',
      'tabIndex': 1,
    },
  ];

  @override
  void initState() {
    super.initState();
    _startBannerTimer();
  }

  void _startBannerTimer() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_bannerController.hasClients) {
        final next = (_currentBannerIndex + 1) % _heroBanners.length;
        _bannerController.animateToPage(
          next,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => widget.appState.reloadAll(),
      color: AppTheme.fireOrange,
      backgroundColor: AppTheme.bgSecondary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Trust Strip
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              color: const Color(0xFF1F1934),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🟢', style: TextStyle(fontSize: 10)),
                  SizedBox(width: 6),
                  Text(
                    '24/7 Service • Instant Delivery • 100% Escrow Protection',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Hero Banner Carousel
            _buildHeroBannerCarousel(context),
            const SizedBox(height: 18),

            // Quick Top-Up Games Grid
            _buildSectionHeader(
              '💎 Top-Up Games',
              'Instant Player UID Delivery',
              () => widget.appState.setTab(1),
            ),
            const SizedBox(height: 10),
            _buildGamesHorizontalList(context),
            const SizedBox(height: 20),

            // Featured Packages Quick Buy
            _buildSectionHeader(
              '🔥 Popular Diamond Packs',
              'Instant 1-Click Top-Up',
              () => widget.appState.setTab(1),
            ),
            const SizedBox(height: 10),
            _buildFeaturedPackagesGrid(context),
            const SizedBox(height: 20),

            // Playable Arcade (Instant 60 FPS In-App Ready-Made Games)
            _buildSectionHeader(
              '🕹️ Playable Arcade',
              'Instant 60 FPS Games • Roblox Obby, Racers & Cricket',
              () => widget.appState.setTab(4),
            ),
            const SizedBox(height: 10),
            _buildArcadeHorizontalList(context),
            const SizedBox(height: 20),

            // Live & Upcoming Esports Tournaments
            _buildSectionHeader(
              '🏆 Esports Tournaments',
              'Compete for Real Cash Prizes',
              () => widget.appState.setTab(2),
            ),
            const SizedBox(height: 10),
            _buildTournamentsPreview(context),
            const SizedBox(height: 20),

            // AI Subscriptions & Developer Vault
            _buildAiSubscriptionsSection(context),
            const SizedBox(height: 20),

            // Leaderboard Preview
            _buildLeaderboardPreview(context),
            const SizedBox(height: 20),

            // Platform Metrics & Trust Pillars
            _buildPlatformMetrics(context),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, VoidCallback onSeeAll) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textMain,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: AppTheme.textDim),
              ),
            ],
          ),
          InkWell(
            onTap: onSeeAll,
            child: const Row(
              children: [
                Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.fireOrange,
                  ),
                ),
                Icon(Icons.chevron_right, size: 16, color: AppTheme.fireOrange),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBannerCarousel(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: SizedBox(
            height: 165,
            child: PageView.builder(
              controller: _bannerController,
              itemCount: _heroBanners.length,
              onPageChanged: (idx) {
                setState(() => _currentBannerIndex = idx);
              },
              itemBuilder: (context, index) {
                final b = _heroBanners[index];
                final tagColor = b['tagColor'] as Color;
                final price = (b['price'] as num).toDouble();
                final pricePrefix = (b['pricePrefix'] as String?) ?? 'Prize Pool: ';
                final tabIndex = b['tabIndex'] as int;

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        TntImage(
                          imagePath: b['image'] as String,
                          fit: BoxFit.cover,
                          fallbackIcon: '🏆',
                        ),
                        // Gradient Overlay
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withOpacity(0.88),
                                Colors.black.withOpacity(0.45),
                                Colors.transparent,
                              ],
                              begin: Alignment.bottomLeft,
                              end: Alignment.topRight,
                            ),
                          ),
                        ),
                        // Content
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: tagColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  b['tag'] as String,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                b['title'] as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                b['subtitle'] as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, color: Colors.white70),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    '$pricePrefix${widget.appState.formatPrice(price)}',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.cyan,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton(
                                    onPressed: () => widget.appState.setTab(tabIndex),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                      minimumSize: const Size(64, 28),
                                      backgroundColor: AppTheme.fireOrange,
                                    ),
                                    child: Text(
                                      b['buttonText'] as String,
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Pagination Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_heroBanners.length, (idx) {
            final isActive = idx == _currentBannerIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 18 : 6,
              height: 5,
              decoration: BoxDecoration(
                color: isActive ? AppTheme.fireOrange : Colors.white24,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildGamesHorizontalList(BuildContext context) {
    // Filter out non-games / utility items
    final rawGames = widget.appState.games.where((g) =>
      !g.id.startsWith('ai_') &&
      g.id != 'game_wallet' &&
      !g.id.contains('temp') &&
      !g.id.startsWith('poki_') &&
      !g.id.startsWith('bloxd') &&
      !g.id.startsWith('hexgl')
    ).toList();

    final games = rawGames.isNotEmpty ? rawGames : _fallbackGames;

    return SizedBox(
      height: 115,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: games.length,
        itemBuilder: (context, index) {
          final g = games[index];
          return InkWell(
            onTap: () => widget.appState.setTab(1), // Go to Top-Up tab
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 95,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderCard),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: TntImage(
                      imagePath: g.banner,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      fallbackIcon: g.icon,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      g.name,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textMain,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedPackagesGrid(BuildContext context) {
    final featured = <Map<String, dynamic>>[];

    // Collect featured packages from games
    for (final g in widget.appState.games) {
      if (g.id.startsWith('ai_') || g.id == 'game_wallet' || g.id.contains('temp')) continue;
      for (final p in g.packages) {
        if (p.badge != null || featured.length < 4) {
          featured.add({'game': g, 'package': p});
        }
      }
    }

    // Fallback if games not loaded yet
    if (featured.isEmpty) {
      for (final g in _fallbackGames) {
        for (final p in g.packages.take(2)) {
          featured.add({'game': g, 'package': p});
        }
      }
    }

    final displayList = featured.take(4).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: displayList.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.55,
        ),
        itemBuilder: (context, index) {
          final item = displayList[index];
          final g = item['game'] as GameModel;
          final p = item['package'] as TopUpPackageModel;

          return InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => CheckoutDialog(
                  appState: widget.appState,
                  game: g,
                  package: p,
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderCard),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(g.icon, style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(
                            p.itemQuantity,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.fireOrange,
                            ),
                          ),
                        ],
                      ),
                      if (p.badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.cyan.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            p.badge!,
                            style: const TextStyle(
                              fontSize: 8,
                              color: AppTheme.cyan,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Text(
                    p.name,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textDim),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.appState.formatPrice(p.price),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textMain,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.fireOrange,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'TopUp',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildArcadeHorizontalList(BuildContext context) {
    final games = ArcadeGamesEngine.defaultGames;
    return SizedBox(
      height: 140,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: games.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final game = games[index];
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => InAppGameScreen(game: game, appState: widget.appState),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 230,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderLight),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B5CDB).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(game.icon, style: const TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              game.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppTheme.textMain,
                              ),
                            ),
                            Text(
                              game.category,
                              style: const TextStyle(fontSize: 10.5, color: AppTheme.textDim),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    game.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textDim),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '+${game.rewardCoins} Coins',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B5CDB),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.play_arrow, size: 14, color: Colors.white),
                            SizedBox(width: 2),
                            Text('Play', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTournamentsPreview(BuildContext context) {
    final activeTourneys = widget.appState.tournaments.where(
      (t) => t.status == 'Live' || t.status == 'Registration Open'
    ).toList();

    final tournaments = (activeTourneys.isNotEmpty ? activeTourneys : widget.appState.tournaments).take(2).toList();
    if (tournaments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: tournaments.map((t) {
          final progress = t.maxSlots > 0 ? (t.registeredCount / t.maxSlots) : 0.0;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.borderCard),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  child: Stack(
                    children: [
                      TntImage(
                        imagePath: t.banner,
                        height: 100,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        fallbackIcon: '🏆',
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: t.status == 'Live' ? AppTheme.errorRed : AppTheme.fireOrange,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            t.status.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            t.mode,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.title,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Prize Pool: ${widget.appState.formatPrice(t.prizePool)}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.cyan),
                          ),
                          Text(
                            'Entry: ${widget.appState.formatPrice(t.entryFee, allowFree: true)}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.fireOrange),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          backgroundColor: AppTheme.bgSecondary,
                          color: AppTheme.fireOrange,
                          minHeight: 5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${t.registeredCount}/${t.maxSlots} Slots Filled',
                            style: const TextStyle(fontSize: 10, color: AppTheme.textDim),
                          ),
                          InkWell(
                            onTap: () => widget.appState.setTab(2),
                            child: const Text(
                              'Details & Rules →',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.cyan,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAiSubscriptionsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.purple.withOpacity(0.3)),
          gradient: LinearGradient(
            colors: [AppTheme.bgCard, AppTheme.purple.withOpacity(0.08)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Text('🤖', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 8),
                    Text(
                      'AI Tools & License Vault',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () => widget.appState.setTab(1),
                  child: const Text(
                    'Explore →',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.purple),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Official ChatGPT Plus, Claude 3.5 Pro, Midjourney & Cursor Pro with instant vault key allocation.',
              style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildAiBadge('ChatGPT Plus', '🤖', () => widget.appState.setTab(1)),
                const SizedBox(width: 6),
                _buildAiBadge('Claude Pro', '🧠', () => widget.appState.setTab(1)),
                const SizedBox(width: 6),
                _buildAiBadge('Cursor Pro', '💻', () => widget.appState.setTab(1)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiBadge(String title, String icon, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.bgSecondary,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.borderCard),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Text(
                title,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMain),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardPreview(BuildContext context) {
    final rawList = widget.appState.leaderboard.isNotEmpty
        ? widget.appState.leaderboard
        : _fallbackLeaderboard;

    final list = rawList.take(3).toList();
    if (list.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderCard),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Text('👑', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 6),
                    Text(
                      'Top Champions',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () => widget.appState.setTab(2),
                  child: const Text(
                    'Season Standings →',
                    style: TextStyle(fontSize: 11, color: AppTheme.cyan, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(height: 18),
            ...list.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final int rank = (item['rank'] is int)
                  ? item['rank'] as int
                  : (int.tryParse('${item['rank']}') ?? (idx + 1));
              final name = (item['display_name'] ?? item['name'] ?? 'Gamer').toString();
              final wins = (item['wins'] ?? 0).toString();
              final double earnings = (item['earnings'] is num)
                  ? (item['earnings'] as num).toDouble()
                  : (double.tryParse('${item['earnings']}') ??
                      ((item['total_points'] is num)
                          ? (item['total_points'] as num).toDouble()
                          : (double.tryParse('${item['total_points']}') ?? 0.0)));

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: rank == 1
                          ? AppTheme.amberGold
                          : rank == 2
                              ? const Color(0xFFC0C0C0)
                              : rank == 3
                                  ? const Color(0xFFCD7F32)
                                  : AppTheme.bgSecondary,
                      child: Text(
                        '#$rank',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: (rank >= 1 && rank <= 3) ? Colors.black : AppTheme.textMain,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                      ),
                    ),
                    Text(
                      '$wins Wins',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textDim),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.appState.formatPrice(earnings),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.cyan),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformMetrics(BuildContext context) {
    final metrics = widget.appState.metrics;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.bgSecondary,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderCard),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('ACTIVE GAMES', '${metrics['activeGames'] ?? 7}'),
            _buildStatItem('TOURNAMENTS', '${metrics['totalTournaments'] ?? 6}'),
            _buildStatItem('LEDGER TX', '${metrics['totalLedgerTx'] ?? 158}'),
            _buildStatItem('STATUS', 'ONLINE 🟢'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.cyan)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 8, color: AppTheme.textDim, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // Fallback games if offline/loading
  static final List<GameModel> _fallbackGames = [
    const GameModel(
      id: 'game_ff',
      name: 'Free Fire MAX',
      slug: 'free-fire',
      category: 'Battle Royale',
      icon: '🔥',
      banner: 'assets/games/freefire.webp',
      requiredFields: [PlayerFieldRequirement(key: 'player_id', label: 'Player UID', regex: r'^[0-9]{8,12}$', hint: '8-12 numeric digits')],
      packages: [
        TopUpPackageModel(id: 'pkg_ff_100', gameId: 'game_ff', name: '100+10 Diamonds', itemQuantity: '110 💎', price: 0.99, badge: 'Popular', sortOrder: 1),
        TopUpPackageModel(id: 'pkg_ff_520', gameId: 'game_ff', name: '520+52 Diamonds', itemQuantity: '572 💎', price: 4.89, badge: 'Best Value', sortOrder: 3),
      ],
    ),
    const GameModel(
      id: 'game_pubg',
      name: 'PUBG Mobile',
      slug: 'pubg-mobile',
      category: 'Battle Royale',
      icon: '🪖',
      banner: 'assets/games/battleground.webp',
      requiredFields: [PlayerFieldRequirement(key: 'player_id', label: 'Character ID', regex: r'^[0-9]{7,11}$', hint: '7-11 digits')],
      packages: [
        TopUpPackageModel(id: 'pkg_pubg_60', gameId: 'game_pubg', name: '60 UC', itemQuantity: '60 🟡', price: 0.99, sortOrder: 1),
        TopUpPackageModel(id: 'pkg_pubg_300', gameId: 'game_pubg', name: '300 + 25 Bonus UC', itemQuantity: '325 🟡', price: 4.89, badge: 'Popular', sortOrder: 2),
      ],
    ),
    const GameModel(
      id: 'game_mlbb',
      name: 'Mobile Legends',
      slug: 'mobile-legends',
      category: 'MOBA',
      icon: '⚔️',
      banner: 'assets/games/mobilelegends.webp',
      requiredFields: [PlayerFieldRequirement(key: 'player_id', label: 'User ID', regex: r'^[0-9]{6,10}$', hint: '6-10 digits')],
      packages: [
        TopUpPackageModel(id: 'pkg_mlbb_86', gameId: 'game_mlbb', name: '86 Diamonds', itemQuantity: '86 💎', price: 1.49, sortOrder: 1),
        TopUpPackageModel(id: 'pkg_mlbb_172', gameId: 'game_mlbb', name: '172 Diamonds', itemQuantity: '172 💎', price: 2.99, badge: 'Popular', sortOrder: 2),
      ],
    ),
    const GameModel(
      id: 'game_roblox',
      name: 'Roblox',
      slug: 'roblox',
      category: 'Sandbox / Adventure',
      icon: '🧱',
      banner: 'assets/games/roblox.webp',
      requiredFields: [PlayerFieldRequirement(key: 'player_id', label: 'Username', regex: r'^[a-zA-Z0-9_]{3,20}$', hint: 'Roblox Username')],
      packages: [
        TopUpPackageModel(id: 'pkg_rbx_80', gameId: 'game_roblox', name: '80 Robux', itemQuantity: r'80 R$', price: 0.99, sortOrder: 1),
        TopUpPackageModel(id: 'pkg_rbx_400', gameId: 'game_roblox', name: '400 Robux', itemQuantity: r'400 R$', price: 4.89, badge: 'Popular', sortOrder: 2),
      ],
    ),
    const GameModel(
      id: 'game_cod',
      name: 'Call of Duty: Mobile',
      slug: 'cod-mobile',
      category: 'FPS / Battle Royale',
      icon: '🎯',
      banner: 'assets/games/callofduty.webp',
      requiredFields: [PlayerFieldRequirement(key: 'player_id', label: 'Player OpenID', regex: r'^[0-9]{10,18}$', hint: 'CODM OpenID')],
      packages: [
        TopUpPackageModel(id: 'pkg_cod_80', gameId: 'game_cod', name: '80 CP', itemQuantity: '80 CP', price: 0.99, sortOrder: 1),
        TopUpPackageModel(id: 'pkg_cod_420', gameId: 'game_cod', name: '420 CP', itemQuantity: '420 CP', price: 4.99, badge: 'Popular', sortOrder: 2),
      ],
    ),
  ];

  static const List<Map<String, dynamic>> _fallbackLeaderboard = [
    {'rank': 1, 'name': 'Phoenix_Ace', 'wins': 18, 'earnings': 1280.0, 'avatar': 'https://api.dicebear.com/7.x/bottts/svg?seed=usr_pro_phoenix'},
    {'rank': 2, 'name': 'ViperStrike', 'wins': 14, 'earnings': 940.0, 'avatar': 'https://api.dicebear.com/7.x/bottts/svg?seed=usr_pro_viper'},
    {'rank': 3, 'name': 'ShadowNinja', 'wins': 11, 'earnings': 720.0, 'avatar': 'https://api.dicebear.com/7.x/bottts/svg?seed=usr_pro_shadow'},
  ];
}
