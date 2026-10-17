import 'package:flutter/material.dart';
import '../models/tournament_model.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/tnt_image.dart';
import '../widgets/room_credentials_dialog.dart';

class TournamentsScreen extends StatefulWidget {
  final AppState appState;

  const TournamentsScreen({super.key, required this.appState});

  @override
  State<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends State<TournamentsScreen> {
  String _selectedStatus = 'All';
  String _selectedGame = 'All';

  final List<String> _statuses = ['All', 'Registration Open', 'Live', 'Upcoming', 'Completed'];
  List<Map<String, String>> get _games {
    final list = <Map<String, String>>[{'id': 'All', 'name': 'All Games'}];
    for (final g in widget.appState.games) {
      list.add({'id': g.id, 'name': g.name});
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.appState.tournaments.where((t) {
      if (_selectedStatus != 'All' && t.status != _selectedStatus) return false;
      if (_selectedGame != 'All' && t.gameId != _selectedGame) return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: Column(
        children: [
          // Filter Bars
          _buildFilterBar(),

          // Tournament List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => widget.appState.reloadAll(),
              color: AppTheme.fireOrange,
              backgroundColor: AppTheme.bgSecondary,
              child: filtered.isEmpty
                  ? const Center(
                      child: Text(
                        'No tournaments found matching the filters.',
                        style: TextStyle(color: AppTheme.textDim),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(left: 14, right: 14, top: 10, bottom: 90),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        return _buildTournamentCard(filtered[index]);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: AppTheme.bgSecondary,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // Status Filters
          SizedBox(
            height: 34,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _statuses.length,
              itemBuilder: (context, index) {
                final s = _statuses[index];
                final isSelected = s == _selectedStatus;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(s),
                    selected: isSelected,
                    selectedColor: AppTheme.fireOrange,
                    backgroundColor: AppTheme.bgCard,
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : AppTheme.textMuted,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: isSelected ? AppTheme.fireOrange : AppTheme.borderCard),
                    ),
                    onSelected: (val) => setState(() => _selectedStatus = s),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          // Game Filters
          SizedBox(
            height: 32,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _games.length,
              itemBuilder: (context, index) {
                final g = _games[index];
                final isSelected = g['id'] == _selectedGame;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(g['name']!),
                    selected: isSelected,
                    selectedColor: AppTheme.cyan.withOpacity(0.2),
                    backgroundColor: AppTheme.bgCard,
                    labelStyle: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppTheme.cyan : AppTheme.textDim,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: isSelected ? AppTheme.cyan : AppTheme.borderSubtle),
                    ),
                    onSelected: (val) => setState(() => _selectedGame = g['id']!),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTournamentCard(TournamentModel t) {
    final progress = t.registeredCount / t.maxSlots;
    final isRegistered = widget.appState.myMatches.any((m) => m.tournamentId == t.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Image & Badges
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Stack(
              children: [
                TntImage(imagePath: t.banner, height: 120, width: double.infinity, fit: BoxFit.cover, fallbackIcon: '🏆'),
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black.withOpacity(0.7), Colors.transparent],
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
                      color: t.status == 'Live' ? AppTheme.errorRed : (t.status == 'Registration Open' ? AppTheme.emeraldGreen : AppTheme.fireOrange),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      t.status.toUpperCase(),
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
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      '${t.mode} • ${t.region}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                if (isRegistered)
                  Positioned(
                    bottom: 8,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.cyan,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check, size: 12, color: Colors.black),
                          SizedBox(width: 4),
                          Text('REGISTERED', style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Details
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                ),
                const SizedBox(height: 4),
                Text(
                  t.description,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Prize Pool', style: TextStyle(fontSize: 10, color: AppTheme.textDim)),
                        Text(
                          widget.appState.formatPrice(t.prizePool),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.cyan),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Entry Fee', style: TextStyle(fontSize: 10, color: AppTheme.textDim)),
                        Text(
                          widget.appState.formatPrice(t.entryFee, allowFree: true),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.fireOrange),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Slots bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor: AppTheme.bgSecondary,
                    color: progress >= 1.0 ? AppTheme.errorRed : AppTheme.fireOrange,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${t.registeredCount}/${t.maxSlots} Slots Filled',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textDim),
                    ),
                    Text(
                      'Starts: ${t.startsAt.hour}:${t.startsAt.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(height: 20),
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showTournamentDetailModal(t),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          foregroundColor: AppTheme.cyan,
                          side: const BorderSide(color: AppTheme.cyan),
                        ),
                        child: const Text('Rules & Details'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (isRegistered) {
                            if (t.isRoomReleased) {
                              showDialog(
                                context: context,
                                builder: (context) => RoomCredentialsDialog(
                                  tournamentTitle: t.title,
                                  roomId: t.roomId ?? 'LOBBY-9982',
                                  roomPassword: t.roomPassword ?? 'pass-2026',
                                  mode: t.mode,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Room ID & Password will unlock 15 mins before match starts.'),
                                  backgroundColor: AppTheme.amberGold,
                                ),
                              );
                            }
                          } else {
                            _showRegistrationModal(t);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          backgroundColor: isRegistered ? AppTheme.emeraldGreen : AppTheme.fireOrange,
                        ),
                        child: Text(
                          isRegistered ? 'Lobby Room 🔓' : 'Register Now',
                          style: const TextStyle(fontWeight: FontWeight.bold),
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
  }

  void _showTournamentDetailModal(TournamentModel t) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppTheme.borderCard, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text(t.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
              const SizedBox(height: 4),
              Text('${t.mode} • ${t.region} • Prize: ${widget.appState.formatPrice(t.prizePool)}', style: const TextStyle(color: AppTheme.cyan, fontSize: 13, fontWeight: FontWeight.bold)),
              const Divider(height: 24),
              const Text('Official Tournament Rules:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.borderCard)),
                child: Text(t.rules, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.4)),
              ),
              const SizedBox(height: 16),
              const Text('Prize Pool Distribution:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
              const SizedBox(height: 8),
              ...t.prizeSplit.map((s) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Place #${s.place}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMain)),
                    Text('${s.percent.toStringAsFixed(0)}% (${widget.appState.formatPrice(s.amount)})', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.fireOrange)),
                  ],
                ),
              )),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showRegistrationModal(t);
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  backgroundColor: AppTheme.fireOrange,
                ),
                child: Text('Register for ${widget.appState.formatPrice(t.entryFee, allowFree: true)}'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRegistrationModal(TournamentModel t) {
    final teamNameCtrl = TextEditingController(text: '${widget.appState.currentUser.displayName}\'s Team');
    final ignCtrl = TextEditingController(text: widget.appState.currentUser.displayName);
    final uidCtrl = TextEditingController(text: '928471928');
    bool isLoading = false;
    String? err;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Dialog(
          backgroundColor: AppTheme.bgSecondary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Container(
            padding: const EdgeInsets.all(22),
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('🏆 Confirm Registration', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
                      IconButton(icon: const Icon(Icons.close, size: 20, color: AppTheme.textDim), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  Text(t.title, style: const TextStyle(fontSize: 12, color: AppTheme.cyan, fontWeight: FontWeight.bold)),
                  const Divider(height: 20),
                  if (err != null)
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: AppTheme.errorRed.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                      child: Text(err!, style: const TextStyle(color: AppTheme.errorRed, fontSize: 12)),
                    ),
                  TextField(controller: teamNameCtrl, decoration: const InputDecoration(labelText: 'Team Name')),
                  const SizedBox(height: 10),
                  TextField(controller: ignCtrl, decoration: const InputDecoration(labelText: 'Captain In-Game Nickname (IGN)')),
                  const SizedBox(height: 10),
                  TextField(controller: uidCtrl, decoration: const InputDecoration(labelText: 'Game Character UID')),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Entry Fee (From Wallet):', style: TextStyle(color: AppTheme.textDim, fontSize: 12)),
                        Text(widget.appState.formatPrice(t.entryFee, allowFree: true), style: const TextStyle(color: AppTheme.fireOrange, fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: isLoading ? null : () async {
                      if (widget.appState.wallet.availableBalance < t.entryFee) {
                        setModalState(() => err = 'Insufficient wallet balance (${widget.appState.formatPrice(widget.appState.wallet.availableBalance)}). Please deposit funds first.');
                        return;
                      }
                      setModalState(() => isLoading = true);
                      try {
                        await widget.appState.registerTournament(
                          tournamentId: t.id,
                          teamName: teamNameCtrl.text.trim(),
                          playerDetails: {'ign': ignCtrl.text.trim(), 'uid': uidCtrl.text.trim()},
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Registration Confirmed! Added to My Matches.'), backgroundColor: AppTheme.emeraldGreen),
                          );
                        }
                      } catch (e) {
                        setModalState(() => err = e.toString().replaceAll('Exception:', '').trim());
                      } finally {
                        setModalState(() => isLoading = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(46), backgroundColor: AppTheme.fireOrange),
                    child: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Confirm Registration'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
