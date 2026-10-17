import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Diamond2048Widget extends StatefulWidget {
  final Function(int score, int coins) onGameOver;
  final Function(int score)? onScoreChanged;

  const Diamond2048Widget({
    super.key,
    required this.onGameOver,
    this.onScoreChanged,
  });

  @override
  State<Diamond2048Widget> createState() => _Diamond2048WidgetState();
}

class _Diamond2048WidgetState extends State<Diamond2048Widget> {
  static const int size = 4;
  late List<List<int>> _grid;
  int _score = 0;
  int _coins = 0;
  bool _isGameOver = false;
  final math.Random _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  void _startNewGame() {
    _grid = List.generate(size, (_) => List.filled(size, 0));
    _score = 0;
    _coins = 0;
    _isGameOver = false;
    _spawnTile();
    _spawnTile();
    setState(() {});
  }

  void _spawnTile() {
    final emptySpots = <Point>[];
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (_grid[r][c] == 0) emptySpots.add(Point(r, c));
      }
    }
    if (emptySpots.isNotEmpty) {
      final p = emptySpots[_rng.nextInt(emptySpots.length)];
      _grid[p.r][p.c] = _rng.nextDouble() < 0.9 ? 2 : 4;
    }
  }

  void _handleSwipe(AxisDirection dir) {
    if (_isGameOver) return;

    bool moved = false;
    int pointsGained = 0;

    List<int> mergeLine(List<int> line) {
      final nonZero = line.where((x) => x != 0).toList();
      final result = <int>[];
      int i = 0;
      while (i < nonZero.length) {
        if (i + 1 < nonZero.length && nonZero[i] == nonZero[i + 1]) {
          final mergedVal = nonZero[i] * 2;
          result.add(mergedVal);
          pointsGained += mergedVal;
          if (mergedVal >= 128) _coins += (mergedVal ~/ 128);
          i += 2;
        } else {
          result.add(nonZero[i]);
          i++;
        }
      }
      while (result.length < size) {
        result.add(0);
      }
      return result;
    }

    if (dir == AxisDirection.left) {
      for (int r = 0; r < size; r++) {
        final original = List<int>.from(_grid[r]);
        final merged = mergeLine(original);
        _grid[r] = merged;
        if (!_listsEqual(original, merged)) moved = true;
      }
    } else if (dir == AxisDirection.right) {
      for (int r = 0; r < size; r++) {
        final original = List<int>.from(_grid[r]);
        final reversed = original.reversed.toList();
        final merged = mergeLine(reversed).reversed.toList();
        _grid[r] = merged;
        if (!_listsEqual(original, merged)) moved = true;
      }
    } else if (dir == AxisDirection.up) {
      for (int c = 0; c < size; c++) {
        final original = [_grid[0][c], _grid[1][c], _grid[2][c], _grid[3][c]];
        final merged = mergeLine(original);
        for (int r = 0; r < size; r++) {
          _grid[r][c] = merged[r];
        }
        if (!_listsEqual(original, merged)) moved = true;
      }
    } else if (dir == AxisDirection.down) {
      for (int c = 0; c < size; c++) {
        final original = [_grid[0][c], _grid[1][c], _grid[2][c], _grid[3][c]];
        final reversed = original.reversed.toList();
        final merged = mergeLine(reversed).reversed.toList();
        for (int r = 0; r < size; r++) {
          _grid[r][c] = merged[r];
        }
        if (!_listsEqual(original, merged)) moved = true;
      }
    }

    if (moved) {
      HapticFeedback.lightImpact();
      _score += pointsGained;
      widget.onScoreChanged?.call(_score);
      _spawnTile();

      if (_checkGameOver()) {
        _isGameOver = true;
        HapticFeedback.heavyImpact();
        widget.onGameOver(_score, _coins);
      }
      setState(() {});
    }
  }

  bool _listsEqual(List<int> a, List<int> b) {
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  bool _checkGameOver() {
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (_grid[r][c] == 0) return false;
        if (c + 1 < size && _grid[r][c] == _grid[r][c + 1]) return false;
        if (r + 1 < size && _grid[r][c] == _grid[r + 1][c]) return false;
      }
    }
    return true;
  }

  Color _getTileColor(int val) {
    switch (val) {
      case 2:
        return const Color(0xFF1E293B);
      case 4:
        return const Color(0xFF334155);
      case 8:
        return const Color(0xFF0284C7);
      case 16:
        return const Color(0xFF0284C7);
      case 32:
        return const Color(0xFF2563EB);
      case 64:
        return const Color(0xFF7C3AED);
      case 128:
        return const Color(0xFF9333EA);
      case 256:
        return const Color(0xFFD946EF);
      case 512:
        return const Color(0xFFEA580C);
      case 1024:
        return const Color(0xFFF59E0B);
      case 2048:
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF0F172A);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < -100) _handleSwipe(AxisDirection.up);
          if (details.primaryVelocity! > 100) _handleSwipe(AxisDirection.down);
        }
      },
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < -100) _handleSwipe(AxisDirection.left);
          if (details.primaryVelocity! > 100) _handleSwipe(AxisDirection.right);
        }
      },
      child: Container(
        color: const Color(0xFF0B0F19),
        child: Column(
          children: [
            const SizedBox(height: 54),
            // Header stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      children: [
                        const Text('🪙', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          '$_coins Coins',
                          style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF38BDF8)),
                    ),
                    child: Text(
                      'SCORE: $_score',
                      style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),

            // 4x4 Grid
            Center(
              child: Container(
                width: 320,
                height: 320,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1B4B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF4F46E5), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.35),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: size,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: size * size,
                  itemBuilder: (context, idx) {
                    final r = idx ~/ size;
                    final c = idx % size;
                    final val = _grid[r][c];

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      decoration: BoxDecoration(
                        color: _getTileColor(val),
                        borderRadius: BorderRadius.circular(12),
                        border: val > 0
                            ? Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: val > 0
                          ? Text(
                              '$val',
                              style: TextStyle(
                                fontSize: val > 512 ? 16 : 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Swipe ⬆️ ⬇️ ⬅️ ➡️ to merge diamonds to 2048!',
              style: TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class Point {
  final int r, c;
  Point(this.r, this.c);
}
