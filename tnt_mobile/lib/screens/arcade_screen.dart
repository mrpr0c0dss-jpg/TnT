import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../models/mini_game_model.dart';
import '../services/arcade_games_engine.dart';
import '../theme/app_theme.dart';
import '../widgets/tnt_image.dart';
import 'in_app_game_screen.dart';

class ArcadeScreen extends StatefulWidget {
  final AppState appState;

  const ArcadeScreen({super.key, required this.appState});

  @override
  State<ArcadeScreen> createState() => _ArcadeScreenState();
}

class _ArcadeScreenState extends State<ArcadeScreen> {
  final List<MiniGameModel> _games = ArcadeGamesEngine.defaultGames;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  final List<String> _categories = [
    'All',
    '👾 Poki Games',
    '🏃 Obby & Parkour',
    '🔥 Popular',
    '⛏️ BedWars & Voxel',
    '🏎️ Racing',
    '🎯 Battles & FPS',
    '🧩 Strategy',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _playGame(MiniGameModel game) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InAppGameScreen(
          game: game,
          appState: widget.appState,
        ),
      ),
    );
  }

  void _showRobloxDetailsSheet(MiniGameModel game) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.45,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Big Experience Banner
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                children: [
                  TntImage(
                    imagePath: game.banner,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    fallbackIcon: game.icon,
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.circle, size: 8, color: AppTheme.mintGreen),
                          const SizedBox(width: 5),
                          Text(
                            '${game.activePlaying} Playing',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Title & Developer
            Text(
              game.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppTheme.textMain,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.verified, size: 15, color: AppTheme.electricBlue),
                const SizedBox(width: 5),
                Text(
                  'By ${game.developer}',
                  style: const TextStyle(fontSize: 12.5, color: AppTheme.textDim, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Light-Themed Stats Bar
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderCard),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Rating', '👍 ${game.likeRatio}', const Color(0xFF16A34A)),
                  Container(width: 1, height: 28, color: AppTheme.borderCard),
                  _buildStatItem('Active Players', '👥 ${game.activePlaying}', AppTheme.textMain),
                  Container(width: 1, height: 28, color: AppTheme.borderCard),
                  _buildStatItem('Reward', '🪙 +${game.rewardCoins}', AppTheme.fireOrange),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Description
            Text(
              game.subtitle,
              style: const TextStyle(fontSize: 13.5, color: AppTheme.textMuted, height: 1.45),
            ),
            const SizedBox(height: 24),

            // Action PLAY Button (Matching HomeScreen brand colors)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _playGame(game);
                },
                icon: const Icon(Icons.play_arrow_rounded, size: 28, color: Colors.white),
                label: const Text(
                  'PLAY NOW',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.mintGreen,
                  elevation: 3,
                  shadowColor: AppTheme.mintGreen.withOpacity(0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 13.5)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppTheme.textDim, fontSize: 11)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredGames = _games.where((g) {
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return g.title.toLowerCase().contains(query) ||
            g.category.toLowerCase().contains(query) ||
            g.subtitle.toLowerCase().contains(query);
      }
      if (_selectedCategory == 'All') return true;
      if (_selectedCategory.contains('Poki')) {
        return g.id.startsWith('poki_') ||
            g.category.toLowerCase().contains('poki') ||
            g.title.toLowerCase().contains('poki');
      }
      if (_selectedCategory.contains('Obby')) return g.category.toLowerCase().contains('obby');
      if (_selectedCategory.contains('Popular')) return g.rating >= 4.8;
      if (_selectedCategory.contains('BedWars')) return g.category.toLowerCase().contains('voxel');
      if (_selectedCategory.contains('Racing')) return g.category.toLowerCase().contains('racing');
      if (_selectedCategory.contains('Battles')) return g.category.toLowerCase().contains('action') || g.category.toLowerCase().contains('fps');
      if (_selectedCategory.contains('Strategy')) return g.category.toLowerCase().contains('puzzle') || g.category.toLowerCase().contains('shooter');
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary, // Light Ice-Blue matching HomeScreen
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Top Header Area (Matching HomeScreen light theme)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Experiences',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textMain,
                                letterSpacing: -0.5,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Roblox-style 3D & WebGL Arcade',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textDim,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            // Wallet Balance Chip (Same as HomeScreen)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppTheme.borderCard),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('🪙', style: TextStyle(fontSize: 13)),
                                  const SizedBox(width: 5),
                                  Text(
                                    widget.appState.formatPrice(widget.appState.wallet.availableBalance),
                                    style: const TextStyle(
                                      color: AppTheme.mintGreen,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Quick URL Launcher Icon
                            IconButton(
                              icon: const Icon(Icons.link_rounded, color: AppTheme.electricBlue, size: 22),
                              tooltip: 'Launch Custom URL',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: _showCustomUrlDialog,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Light-Themed Search Bar
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.borderCard),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded, color: AppTheme.fireOrange, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              style: const TextStyle(color: AppTheme.textMain, fontSize: 13.5),
                              decoration: const InputDecoration(
                                hintText: 'Search experiences & 3D games...',
                                hintStyle: TextStyle(color: AppTheme.textDim, fontSize: 13.5),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (val) => setState(() => _searchQuery = val),
                            ),
                          ),
                          if (_searchQuery.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                              child: const Icon(Icons.close_rounded, color: AppTheme.textDim, size: 18),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Category Filter Pills (HomeScreen Style)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: _categories.map((cat) {
                          final isSel = _selectedCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedCategory = cat),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSel ? AppTheme.fireOrange : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSel ? AppTheme.fireOrange : AppTheme.borderCard,
                                  ),
                                  boxShadow: isSel
                                      ? [
                                          BoxShadow(
                                            color: AppTheme.fireOrange.withOpacity(0.3),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.02),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                ),
                                child: Text(
                                  cat,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                                    color: isSel ? Colors.white : AppTheme.textMuted,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // If Search or Filter is active, show 2-column Grid
            if (_searchQuery.trim().isNotEmpty || _selectedCategory != 'All')
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.74,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 14,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _buildRobloxGridCard(filteredGames[i]),
                    childCount: filteredGames.length,
                  ),
                ),
              )
            else ...[
              // Featured Hero Experience Banner (Clean Light-Themed Container)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: _buildFeaturedHeroCard(_games.first),
                ),
              ),

              // Roblox Carousel 1: 👾 Poki Instant Games Hub
              SliverToBoxAdapter(
                child: _buildRobloxSection(
                  title: '👾 Poki Instant Games Hub',
                  subtitle: '1,000+ instant mobile web games on Poki',
                  games: _games.where((g) => g.id.startsWith('poki_')).toList(),
                ),
              ),

              // Roblox Carousel 2: Recommended for You
              SliverToBoxAdapter(
                child: _buildRobloxSection(
                  title: 'Recommended for You',
                  subtitle: 'Top handpicked 3D experiences',
                  games: [_games[0], _games[1], _games[2], _games[3]],
                ),
              ),

              // Roblox Carousel 2: 🔥 Popular & Trending Now
              SliverToBoxAdapter(
                child: _buildRobloxSection(
                  title: '🔥 Popular & Trending Now',
                  subtitle: 'Most active players today',
                  games: [_games[1], _games[4], _games[3], _games[5]],
                ),
              ),

              // Roblox Carousel 3: 🏃 3D Obby & Parkour
              SliverToBoxAdapter(
                child: _buildRobloxSection(
                  title: '🏃 3D Obby & Parkour',
                  subtitle: 'Jump across platforms & collect coins',
                  games: [_games[0], _games[1], _games[2], _games[6]],
                ),
              ),

              // Bottom Grid Section: 🎮 All Experiences
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🎮 All Experiences',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textMain,
                              letterSpacing: 0.2,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Full arcade library with coin payouts',
                            style: TextStyle(fontSize: 11, color: AppTheme.textDim),
                          ),
                        ],
                      ),
                      Text(
                        '${_games.length} Games',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.fireOrange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 95),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.74,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 14,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _buildRobloxGridCard(_games[i]),
                    childCount: _games.length,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Featured Hero Experience Banner
  // ---------------------------------------------------------------------------
  Widget _buildFeaturedHeroCard(MiniGameModel game) {
    return GestureDetector(
      onTap: () => _showRobloxDetailsSheet(game),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.borderCard),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              TntImage(
                imagePath: game.banner,
                fit: BoxFit.cover,
                fallbackIcon: game.icon,
              ),
              // Scrim gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.35),
                      Colors.black.withOpacity(0.90),
                    ],
                  ),
                ),
              ),
              // Badges & details
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.fireOrange,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '⭐ FEATURED EXPERIENCE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.circle, color: AppTheme.mintGreen, size: 7),
                              const SizedBox(width: 4),
                              Text(
                                '${game.activePlaying} Playing',
                                style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                game.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Text(
                                    '👍 ${game.likeRatio}',
                                    style: const TextStyle(color: AppTheme.mintGreen, fontSize: 11.5, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '🪙 +${game.rewardCoins} Coins',
                                    style: const TextStyle(color: Color(0xFFFBBF24), fontSize: 11.5, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: () => _playGame(game),
                          icon: const Icon(Icons.play_arrow_rounded, size: 20, color: Colors.white),
                          label: const Text(
                            'PLAY',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.mintGreen,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            elevation: 3,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Roblox Horizontal Section Carousel (Clean Light Theme)
  // ---------------------------------------------------------------------------
  Widget _buildRobloxSection({
    required String title,
    required String subtitle,
    required List<MiniGameModel> games,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
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
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textDim),
                  ),
                ],
              ),
              const Row(
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
            ],
          ),
        ),
        SizedBox(
          height: 215,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: games.length,
            itemBuilder: (ctx, i) => _buildRobloxExperienceCard(games[i]),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Roblox Experience Card Tile (HomeScreen White Card Theme)
  // ---------------------------------------------------------------------------
  Widget _buildRobloxExperienceCard(MiniGameModel game) {
    return GestureDetector(
      onTap: () => _showRobloxDetailsSheet(game),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderCard),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  Container(
                    width: 124,
                    height: 124,
                    color: AppTheme.bgPrimary,
                    child: TntImage(
                      imagePath: game.effectiveIconImage,
                      width: 124,
                      height: 124,
                      fit: BoxFit.cover,
                      fallbackIcon: game.icon,
                    ),
                  ),
                  // Coins reward badge
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Text(
                        '🪙 +${game.rewardCoins}',
                        style: const TextStyle(color: Color(0xFFD97706), fontSize: 9.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  // Engine badge (bottom-left)
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: (game.externalUrl != null && game.externalUrl!.isNotEmpty)
                            ? const Color(0xFFEEF2FF)
                            : const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        (game.externalUrl != null && game.externalUrl!.isNotEmpty) ? '3D Web' : '60 FPS',
                        style: TextStyle(
                          color: (game.externalUrl != null && game.externalUrl!.isNotEmpty)
                              ? const Color(0xFF4F46E5)
                              : const Color(0xFF059669),
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Experience Title
            Text(
              game.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textMain,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 4),

            // Stats Row (Like % and Playing)
            Row(
              children: [
                const Icon(Icons.thumb_up_alt_rounded, size: 11, color: Color(0xFF16A34A)),
                const SizedBox(width: 3),
                Text(
                  game.likeRatio,
                  style: const TextStyle(color: Color(0xFF16A34A), fontSize: 10.5, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.person_rounded, size: 12, color: AppTheme.textDim),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    game.activePlaying,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.textDim, fontSize: 10.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Roblox Grid Card (Used in search and all experiences)
  // ---------------------------------------------------------------------------
  Widget _buildRobloxGridCard(MiniGameModel game) {
    return GestureDetector(
      onTap: () => _showRobloxDetailsSheet(game),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderCard),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    TntImage(
                      imagePath: game.effectiveIconImage,
                      fit: BoxFit.cover,
                      fallbackIcon: game.icon,
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Text(
                          '🪙 +${game.rewardCoins}',
                          style: const TextStyle(color: Color(0xFFD97706), fontSize: 9.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Title
            Text(
              game.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textMain,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),

            // Stats
            Row(
              children: [
                const Icon(Icons.thumb_up_alt_rounded, size: 11, color: Color(0xFF16A34A)),
                const SizedBox(width: 3),
                Text(
                  game.likeRatio,
                  style: const TextStyle(color: Color(0xFF16A34A), fontSize: 10.5, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.person_rounded, size: 12, color: AppTheme.textDim),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    game.activePlaying,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.textDim, fontSize: 10.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Launch Any Custom Web Game URL Dialog (HomeScreen Light Theme)
  // ---------------------------------------------------------------------------
  void _showCustomUrlDialog() {
    final urlCtrl = TextEditingController(text: 'https://play.famobi.com/table-tennis-world-tour');
    final titleCtrl = TextEditingController(text: 'Custom Experience');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.public, color: AppTheme.electricBlue, size: 22),
            SizedBox(width: 8),
            Text(
              'Launch Experience URL',
              style: TextStyle(color: AppTheme.textMain, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter any HTML5/WebGL game link from GameDistribution, Famobi, or Poki:',
              style: TextStyle(fontSize: 12, color: AppTheme.textDim),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleCtrl,
              style: const TextStyle(color: AppTheme.textMain, fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Experience Title',
                labelStyle: const TextStyle(color: AppTheme.textDim),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.borderCard),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: urlCtrl,
              style: const TextStyle(color: AppTheme.textMain, fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Game URL (https://...)',
                labelStyle: const TextStyle(color: AppTheme.textDim),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.borderCard),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textDim)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.fireOrange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              if (urlCtrl.text.trim().isNotEmpty) {
                Navigator.pop(ctx);
                _playGame(
                  MiniGameModel(
                    id: 'custom_game_${DateTime.now().millisecondsSinceEpoch}',
                    title: titleCtrl.text.trim().isEmpty ? 'Custom Game' : titleCtrl.text.trim(),
                    subtitle: 'Online WebGL Ready-Made Game',
                    category: 'Web Game',
                    icon: '🎮',
                    iconImage: 'assets/banner/neon_loot_battle_royale.webp',
                    banner: 'assets/banner/neon_loot_battle_royale.webp',
                    externalUrl: urlCtrl.text.trim(),
                    likeRatio: '95%',
                    activePlaying: '12K',
                    developer: 'Community Creator',
                  ),
                );
              }
            },
            child: const Text('Launch ▶', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
