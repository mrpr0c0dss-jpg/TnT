import 'package:flutter/material.dart';
import '../models/tournament_model.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/tnt_image.dart';
import '../widgets/room_credentials_dialog.dart';

class MyMatchesScreen extends StatelessWidget {
  final AppState appState;

  const MyMatchesScreen({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    final matches = appState.myMatches;

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: RefreshIndicator(
        onRefresh: () => appState.reloadAll(),
        color: AppTheme.fireOrange,
        backgroundColor: Colors.white,
        child: matches.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('⚔️', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 14),
                      const Text(
                        'No Registered Tournaments',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'You haven\'t joined any tournaments yet. Check the Tournaments tab to register and compete!',
                        style: TextStyle(fontSize: 12, color: AppTheme.textDim),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton(
                        onPressed: () => appState.setTab(2),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.fireOrange),
                        child: const Text('Browse Tournaments'),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.only(left: 14, right: 14, top: 12, bottom: 90),
                itemCount: matches.length,
                itemBuilder: (context, index) {
                  return _buildMatchCard(context, matches[index]);
                },
              ),
      ),
    );
  }

  Widget _buildMatchCard(BuildContext context, RegisteredMatchModel match) {
    final isUnlocked = match.roomDecrypted || DateTime.now().isAfter(match.roomReleaseAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderCard),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner & Status
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Stack(
              children: [
                TntImage(imagePath: match.banner, height: 110, width: double.infinity, fit: BoxFit.cover, fallbackIcon: '⚔️'),
                Container(
                  height: 110,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black.withValues(alpha: 0.65), Colors.transparent],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isUnlocked ? AppTheme.emeraldGreen : AppTheme.fireOrange,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isUnlocked ? 'LOBBY REVEALED 🔓' : 'CONFIRMED ⚔️',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      match.mode,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  match.tournamentTitle,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Receipt: ${match.receiptNumber}', style: const TextStyle(fontSize: 11, color: AppTheme.mintGreen, fontWeight: FontWeight.bold)),
                    Text(
                      'Entry Fee: ${appState.formatPrice(match.entryFee, allowFree: true)}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.fireOrange, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(height: 18),
                // Time-Gated Room Credentials Widget
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUnlocked ? AppTheme.emeraldGreen.withValues(alpha: 0.08) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isUnlocked ? AppTheme.emeraldGreen.withValues(alpha: 0.3) : AppTheme.borderCard),
                  ),
                  child: Row(
                    children: [
                      Text(isUnlocked ? '🔓' : '🔒', style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isUnlocked ? 'Room Credentials Available' : 'Room ID & Password Locked',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isUnlocked ? const Color(0xFF047857) : AppTheme.textDim,
                              ),
                            ),
                            Text(
                              isUnlocked ? 'Click below to reveal Room ID and password.' : 'Credentials reveal 15 mins before match begins.',
                              style: const TextStyle(fontSize: 10, color: AppTheme.textDim),
                            ),
                          ],
                        ),
                      ),
                      if (isUnlocked)
                        ElevatedButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => RoomCredentialsDialog(
                                tournamentTitle: match.tournamentTitle,
                                roomId: match.roomId ?? 'LOBBY-9982',
                                roomPassword: match.roomPassword ?? 'tnt-pass-2026',
                                mode: match.mode,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.emeraldGreen,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: const Size(60, 32),
                          ),
                          child: const Text('View Room', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Cancel Registration & Refund Button (if eligible)
                if (match.canCancel)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: Colors.white,
                            title: const Text('Cancel Registration?'),
                            content: Text(
                              'Are you sure you want to cancel your spot in ${match.tournamentTitle}? Your entry fee of ${appState.formatPrice(match.entryFee)} will be automatically refunded to your escrow wallet.',
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep Spot')),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
                                child: const Text('Cancel & Refund'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await appState.cancelTournamentRegistration(match.tournamentId);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Registration cancelled. Entry fee refunded!'), backgroundColor: AppTheme.fireOrange),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.cancel_outlined, size: 14, color: AppTheme.errorRed),
                      label: const Text('Cancel & Auto-Refund', style: TextStyle(fontSize: 11, color: AppTheme.errorRed)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
