import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/tnt_image.dart';
import '../widgets/checkout_dialog.dart';

class TopUpScreen extends StatefulWidget {
  final AppState appState;

  const TopUpScreen({super.key, required this.appState});

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  int _selectedGameIndex = 0;
  TopUpPackageModel? _selectedPackage;
  final Map<String, TextEditingController> _playerFieldControllers = {};
  final Map<String, bool> _fieldValidity = {};

  @override
  void initState() {
    super.initState();
    _initFieldsForCurrentGame();
  }

  void _initFieldsForCurrentGame() {
    for (final c in _playerFieldControllers.values) {
      c.dispose();
    }
    _playerFieldControllers.clear();
    _fieldValidity.clear();

    if (widget.appState.games.isEmpty) return;
    final game = widget.appState.games[_selectedGameIndex];
    for (final field in game.requiredFields) {
      final ctrl = TextEditingController();
      _playerFieldControllers[field.key] = ctrl;
      _fieldValidity[field.key] = false;

      ctrl.addListener(() {
        final val = ctrl.text.trim();
        try {
          final reg = RegExp(field.regex);
          setState(() {
            _fieldValidity[field.key] = reg.hasMatch(val);
          });
        } catch (_) {
          setState(() {
            _fieldValidity[field.key] = val.isNotEmpty;
          });
        }
      });
    }

    if (game.packages.isNotEmpty) {
      _selectedPackage = game.packages.first;
    } else {
      _selectedPackage = null;
    }
  }

  void _selectGame(int index) {
    setState(() {
      _selectedGameIndex = index;
      _initFieldsForCurrentGame();
    });
  }

  @override
  void dispose() {
    for (final c in _playerFieldControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.appState.games.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.fireOrange),
      );
    }

    final currentGame = widget.appState.games[_selectedGameIndex];

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Game Selection Strip
            _buildGameSelector(),

            // Selected Game Hero Banner
            _buildSelectedGameHero(currentGame),
            const SizedBox(height: 16),

            // Step 1: Player Verification
            _buildPlayerVerificationSection(currentGame),
            const SizedBox(height: 16),

            // Step 2: Package Denomination Selection
            _buildPackageGridSection(currentGame),
            const SizedBox(height: 16),

            // Step 3: Checkout Action Bar
            _buildBottomActionCard(currentGame),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }

  Widget _buildGameSelector() {
    final games = widget.appState.games;
    return Container(
      color: AppTheme.bgSecondary,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        height: 75,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: games.length,
          itemBuilder: (context, index) {
            final g = games[index];
            final isSelected = index == _selectedGameIndex;

            return InkWell(
              onTap: () => _selectGame(index),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 70,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.fireOrange.withOpacity(0.15) : AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppTheme.fireOrange : AppTheme.borderCard,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: TntImage(
                        imagePath: g.banner,
                        width: 38,
                        height: 38,
                        fit: BoxFit.cover,
                        fallbackIcon: g.icon,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      g.name.split(' ').first,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? AppTheme.fireOrange : AppTheme.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSelectedGameHero(GameModel game) {
    return Container(
      height: 110,
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderCard),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            TntImage(imagePath: game.banner, fit: BoxFit.cover, fallbackIcon: game.icon),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.85), Colors.black.withOpacity(0.3)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.fireOrange,
                    child: Text(game.icon, style: const TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          game.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${game.category} • Instant Webhook Credit',
                          style: const TextStyle(fontSize: 11, color: AppTheme.cyan),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerVerificationSection(GameModel game) {
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
              children: [
                CircleAvatar(
                  radius: 11,
                  backgroundColor: AppTheme.fireOrange,
                  child: Text('1', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                SizedBox(width: 8),
                Text(
                  'Enter Player Account Details',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (game.requiredFields.isEmpty)
              const Text(
                'No player ID required for direct platform credit.',
                style: TextStyle(color: AppTheme.textDim, fontSize: 12),
              )
            else
              ...game.requiredFields.map((field) {
                final isValid = _fieldValidity[field.key] ?? false;
                final text = _playerFieldControllers[field.key]?.text ?? '';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _playerFieldControllers[field.key],
                        decoration: InputDecoration(
                          labelText: field.label,
                          hintText: field.hint,
                          prefixIcon: const Icon(Icons.videogame_asset_outlined, size: 20, color: AppTheme.cyan),
                          suffixIcon: text.isNotEmpty
                              ? Icon(
                                  isValid ? Icons.check_circle : Icons.error_outline,
                                  color: isValid ? AppTheme.emeraldGreen : AppTheme.errorRed,
                                  size: 20,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        field.hint,
                        style: const TextStyle(fontSize: 10, color: AppTheme.textDim),
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

  Widget _buildPackageGridSection(GameModel game) {
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
              children: [
                CircleAvatar(
                  radius: 11,
                  backgroundColor: AppTheme.fireOrange,
                  child: Text('2', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                SizedBox(width: 8),
                Text(
                  'Select Package Denomination',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (game.packages.isEmpty)
              const Text('No packages currently active for this game.', style: TextStyle(color: AppTheme.textDim))
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: game.packages.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.5,
                ),
                itemBuilder: (context, index) {
                  final pkg = game.packages[index];
                  final isSelected = _selectedPackage?.id == pkg.id;

                  return InkWell(
                    onTap: () => setState(() => _selectedPackage = pkg),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.fireOrange.withOpacity(0.12) : AppTheme.bgSecondary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppTheme.fireOrange : AppTheme.borderCard,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                pkg.itemQuantity,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? AppTheme.fireOrange : AppTheme.textMain,
                                ),
                              ),
                              if (pkg.badge != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.cyan.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    pkg.badge!,
                                    style: const TextStyle(fontSize: 8, color: AppTheme.cyan, fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                          Text(
                            pkg.name,
                            style: const TextStyle(fontSize: 10, color: AppTheme.textDim),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            widget.appState.formatPrice(pkg.price),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? AppTheme.fireOrange : AppTheme.cyan,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionCard(GameModel game) {
    if (_selectedPackage == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.bgSecondary,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderCard),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 10),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Price:', style: TextStyle(fontSize: 11, color: AppTheme.textDim)),
                    Text(
                      widget.appState.formatPrice(_selectedPackage!.price, includeUsd: true),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.cyan),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    final details = <String, String>{};
                    for (final entry in _playerFieldControllers.entries) {
                      details[entry.key] = entry.value.text.trim();
                    }
                    showDialog(
                      context: context,
                      builder: (context) => CheckoutDialog(
                        appState: widget.appState,
                        game: game,
                        package: _selectedPackage!,
                        initialPlayerDetails: details,
                      ),
                    );
                  },
                  icon: const Icon(Icons.bolt, size: 18),
                  label: const Text('Instant Checkout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.fireOrange,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
