import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/tnt_image.dart';
import '../widgets/checkout_dialog.dart';
import 'in_app_game_screen.dart';
import '../services/arcade_games_engine.dart';

class HomeScreen extends StatelessWidget {
  final AppState appState;

  const HomeScreen({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => appState.reloadAll(),
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
            _buildHeroBanner(context),
            const SizedBox(height: 18),

            // Quick Top-Up Games Grid
            _buildSectionHeader('💎 Top-Up Games', 'Instant Player UID Delivery', () => appState.setTab(1)),
            const SizedBox(height: 10),
            _buildGamesHorizontalList(context),
            const SizedBox(height: 20),

            // Featured Packages Quick Buy
            _buildSectionHeader('🔥 Popular Diamond Packs', 'Instant 1-Click Top-Up', () => appState.setTab(1)),
            const SizedBox(height: 10),
            _buildFeaturedPackagesGrid(context),
            const SizedBox(height: 20),

            // Playable Arcade (Instant 60 FPS In-App Ready-Made Games)
            _buildSectionHeader('🕹️ Playable Arcade', 'Instant 60 FPS Games • Roblox Obby, Racers & Puzzle', () => appState.setTab(4)),
            const SizedBox(height: 10),
            _buildArcadeHorizontalList(context),
            const SizedBox(height: 20),

            // Live & Upcoming Esports Tournaments
            _buildSectionHeader('🏆 Esports Tournaments', 'Compete for Real Cash Prizes', () => appState.setTab(2)),
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

  Widget _buildHeroBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
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
              const TntImage(
                imagePath: 'assets/banner/tnt_esports_arena.webp',
                fit: BoxFit.cover,
                fallbackIcon: '🏆',
              ),
              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.85),
                      Colors.black.withOpacity(0.4),
                      Colors.transparent,
                    ],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.fireOrange,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'SEASON 4 ARENA LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Apex Champions Cup S4',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Prize Pool: ${appState.formatPrice(400.0)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.cyan,
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () => appState.setTab(2),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            minimumSize: const Size(60, 28),
                            backgroundColor: AppTheme.fireOrange,
                          ),
                          child: const Text('Join Now', style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGamesHorizontalList(BuildContext context) {
    final games = appState.games;
    if (games.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator(color: AppTheme.cyan)),
      );
    }

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: games.length,
        itemBuilder: (context, index) {
          final g = games[index];
          return InkWell(
            onTap: () => appState.setTab(1), // Go to Top-Up tab
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 90,
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
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      fallbackIcon: g.icon,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedPackagesGrid(BuildContext context) {
    if (appState.games.isEmpty) return const SizedBox.shrink();

    // Pull packages from first 2 games
    final featured = <Map<String, dynamic>>[];
    for (final g in appState.games) {
      for (final p in g.packages.take(2)) {
        featured.add({'game': g, 'package': p});
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: featured.take(4).length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.6,
        ),
        itemBuilder: (context, index) {
          final item = featured[index];
          final g = item['game'] as dynamic;
          final p = item['package'] as dynamic;

          return InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => CheckoutDialog(
                  appState: appState,
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
                      Text(p.itemQuantity, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.fireOrange)),
                      if (p.badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.cyan.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            p.badge!,
                            style: const TextStyle(fontSize: 8, color: AppTheme.cyan, fontWeight: FontWeight.bold),
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
                        appState.formatPrice(p.price),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.fireOrange,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('TopUp', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
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
                  builder: (_) => InAppGameScreen(game: game, appState: appState),
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
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textMain),
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
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
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
    final tournaments = appState.tournaments.take(2).toList();
    if (tournaments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: tournaments.map((t) {
          final progress = t.registeredCount / t.maxSlots;
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
                      TntImage(imagePath: t.banner, height: 100, width: double.infinity, fit: BoxFit.cover, fallbackIcon: '🏆'),
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
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
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
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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
                      Text(t.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Prize Pool: ${appState.formatPrice(t.prizePool)}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.cyan),
                          ),
                          Text(
                            'Entry: ${appState.formatPrice(t.entryFee, allowFree: true)}',
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
                          Text('${t.registeredCount}/${t.maxSlots} Slots Filled', style: const TextStyle(fontSize: 10, color: AppTheme.textDim)),
                          InkWell(
                            onTap: () => appState.setTab(2),
                            child: const Text('Details & Rules →', style: TextStyle(fontSize: 11, color: AppTheme.cyan, fontWeight: FontWeight.bold)),
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
            const SizedBox(height: 4),
            const Text(
              'Official ChatGPT Plus, Claude 3.5 Pro, Midjourney & Cursor Pro with instant vault key allocation.',
              style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildAiBadge('ChatGPT Plus', '🤖'),
                const SizedBox(width: 6),
                _buildAiBadge('Claude Pro', '🧠'),
                const SizedBox(width: 6),
                _buildAiBadge('Cursor Pro', '💻'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiBadge(String title, String icon) {
    return Expanded(
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
            Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardPreview(BuildContext context) {
    final list = appState.leaderboard.take(3).toList();
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
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('👑 Top Champions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
                Text('Season Leaderboard', style: TextStyle(fontSize: 10, color: AppTheme.cyan, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 18),
            ...list.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final rank = item['rank'] ?? (idx + 1);
              final name = (item['display_name'] ?? item['name'] ?? 'Gamer').toString();
              final wins = (item['wins'] ?? 0).toString();
              final earnings = (item['earnings'] as num?)?.toDouble() ??
                  (item['total_points'] as num?)?.toDouble() ??
                  0.0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: rank == 1 ? AppTheme.amberGold : AppTheme.bgSecondary,
                      child: Text(
                        '#$rank',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: rank == 1 ? Colors.black : AppTheme.textMain,
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
                    const SizedBox(width: 10),
                    Text(
                      appState.formatPrice(earnings),
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
    final metrics = appState.metrics;
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
            _buildStatItem('ACTIVE GAMES', '${metrics['activeGames'] ?? 6}'),
            _buildStatItem('TOURNAMENTS', '${metrics['totalTournaments'] ?? 6}'),
            _buildStatItem('LEDGER TX', '${metrics['totalLedgerTx'] ?? 48}'),
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
}
