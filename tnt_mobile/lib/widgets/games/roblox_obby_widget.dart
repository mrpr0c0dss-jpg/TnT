import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';

class RobloxObbyWidget extends StatefulWidget {
  final Function(int score, int coins) onGameOver;
  final Function(int score)? onScoreChanged;

  const RobloxObbyWidget({
    super.key,
    required this.onGameOver,
    this.onScoreChanged,
  });

  @override
  State<RobloxObbyWidget> createState() => _RobloxObbyWidgetState();
}

enum ObbyItemType { coin, lava, hurdle, speedPad }

class ObbyTrackItem {
  final double z; // Distance ahead of player (0 = at player, 1000 = horizon)
  final double x; // Horizontal lane (-1.0 left, 0.0 center, 1.0 right)
  final ObbyItemType type;
  bool collected = false;

  ObbyTrackItem({
    required this.z,
    required this.x,
    required this.type,
  });
}

class _RobloxObbyWidgetState extends State<RobloxObbyWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;

  // Game Physics State
  double _playerX = 0.0; // -1.0 to 1.0
  double _targetX = 0.0;
  double _playerY = 0.0; // Jump height (0 = ground, >0 = in air)
  double _jumpVelocity = 0.0;
  bool _isGrounded = true;

  double _speed = 360.0; // units per second
  double _distanceTraveled = 0.0;
  int _score = 0;
  int _coins = 0;
  int _lives = 3;
  bool _isGameOver = false;
  bool _isInvulnerable = false;
  int _invulnerableTimer = 0;

  // Animation values
  double _legSwing = 0.0;
  double _coinSpin = 0.0;

  // Obstacles & Pickups
  final List<ObbyTrackItem> _items = [];
  double _nextSpawnZ = 300.0;
  final math.Random _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _initGame();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_gameLoop);
    _ticker.repeat();
  }

  void _initGame() {
    _playerX = 0.0;
    _targetX = 0.0;
    _playerY = 0.0;
    _jumpVelocity = 0.0;
    _isGrounded = true;
    _speed = 360.0;
    _distanceTraveled = 0.0;
    _score = 0;
    _coins = 0;
    _lives = 3;
    _isGameOver = false;
    _isInvulnerable = false;
    _items.clear();
    _nextSpawnZ = 300.0;

    // Seed initial track
    for (int i = 0; i < 8; i++) {
      _spawnPattern();
    }
  }

  void _spawnPattern() {
    final lanes = [-0.9, 0.0, 0.9];
    final selectedLane = lanes[_rng.nextInt(lanes.length)];
    final typeRoll = _rng.nextDouble();

    if (typeRoll < 0.45) {
      // Coin trail (3 coins in a row)
      for (int i = 0; i < 3; i++) {
        _items.add(ObbyTrackItem(
          z: _nextSpawnZ + (i * 70),
          x: selectedLane,
          type: ObbyItemType.coin,
        ));
      }
      _nextSpawnZ += 280;
    } else if (typeRoll < 0.75) {
      // Lava Pit (Must jump over)
      _items.add(ObbyTrackItem(
        z: _nextSpawnZ,
        x: selectedLane,
        type: ObbyItemType.lava,
      ));
      // Coin hovering right above the lava
      _items.add(ObbyTrackItem(
        z: _nextSpawnZ,
        x: selectedLane,
        type: ObbyItemType.coin,
      ));
      _nextSpawnZ += 260;
    } else {
      // Hurdle block
      _items.add(ObbyTrackItem(
        z: _nextSpawnZ,
        x: selectedLane,
        type: ObbyItemType.hurdle,
      ));
      _nextSpawnZ += 240;
    }
  }

  void _gameLoop() {
    if (_isGameOver) return;

    const dt = 1.0 / 60.0;

    // Smooth lane interpolation
    _playerX += (_targetX - _playerX) * 0.22;

    // Jump Physics
    if (!_isGrounded) {
      _playerY += _jumpVelocity * dt;
      _jumpVelocity -= 2200.0 * dt; // Gravity
      if (_playerY <= 0.0) {
        _playerY = 0.0;
        _jumpVelocity = 0.0;
        _isGrounded = true;
      }
    }

    // Move forward
    _distanceTraveled += _speed * dt;
    _speed = math.min(680.0, 360.0 + (_distanceTraveled * 0.035)); // Gradual speed ramp
    _score = (_distanceTraveled * 0.1).toInt() + (_coins * 25);
    widget.onScoreChanged?.call(_score);

    _legSwing += dt * (_speed / 50.0);
    _coinSpin += dt * 5.0;

    if (_isInvulnerable) {
      _invulnerableTimer--;
      if (_invulnerableTimer <= 0) {
        _isInvulnerable = false;
      }
    }

    // Update track items
    for (int i = _items.length - 1; i >= 0; i--) {
      final item = _items[i];
      final currentZ = item.z - _distanceTraveled;

      // Item reached player hit-window
      if (currentZ >= -20 && currentZ <= 45 && !item.collected) {
        final distToLane = (item.x - _playerX).abs();

        if (distToLane < 0.45) {
          if (item.type == ObbyItemType.coin) {
            item.collected = true;
            _coins++;
            HapticFeedback.lightImpact();
          } else if (item.type == ObbyItemType.lava) {
            // Must be jumping at least 35 units high to clear lava
            if (_playerY < 35 && !_isInvulnerable) {
              _hitHazard('Stepped in Lava!');
            }
          } else if (item.type == ObbyItemType.hurdle) {
            // Must jump or switch lanes
            if (_playerY < 45 && !_isInvulnerable) {
              _hitHazard('Hit Obstacle Block!');
            }
          }
        }
      }

      // Cleanup past items
      if (currentZ < -150) {
        _items.removeAt(i);
      }
    }

    // Spawn more ahead
    if (_nextSpawnZ - _distanceTraveled < 1600) {
      _spawnPattern();
    }

    setState(() {});
  }

  void _hitHazard(String cause) {
    HapticFeedback.heavyImpact();
    _lives--;
    _isInvulnerable = true;
    _invulnerableTimer = 60; // 1 second flash

    if (_lives <= 0) {
      _isGameOver = true;
      _ticker.stop();
      widget.onGameOver(_score, _coins);
    }
  }

  void _jump() {
    if (_isGrounded && !_isGameOver) {
      _isGrounded = false;
      _jumpVelocity = 820.0;
      HapticFeedback.mediumImpact();
    }
  }

  void _moveLeft() {
    if (_targetX > -0.85) {
      _targetX = math.max(-1.0, _targetX - 0.95);
      HapticFeedback.selectionClick();
    }
  }

  void _moveRight() {
    if (_targetX < 0.85) {
      _targetX = math.min(1.0, _targetX + 0.95);
      HapticFeedback.selectionClick();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < -100) _moveLeft();
          if (details.primaryVelocity! > 100) _moveRight();
        }
      },
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! < -100) {
          _jump();
        }
      },
      child: Stack(
        children: [
          // 3D Perspective Canvas Rendering
          CustomPaint(
            painter: RobloxObbyPainter(
              playerX: _playerX,
              playerY: _playerY,
              items: _items,
              distance: _distanceTraveled,
              legSwing: _legSwing,
              coinSpin: _coinSpin,
              isInvulnerable: _isInvulnerable,
            ),
            child: const SizedBox.expand(),
          ),

          // Top In-Game HUD (Lives, Score, Coins)
          Positioned(
            top: 54,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Lives
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      3,
                      (i) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Icon(
                          Icons.favorite,
                          size: 16,
                          color: i < _lives ? Colors.redAccent : Colors.white24,
                        ),
                      ),
                    ),
                  ),
                ),

                // Robux Coins Collected
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.mintGreen.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🪙', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 5),
                      Text(
                        '$_coins R\$',
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                // Distance Score
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    '$_score PTS',
                    style: const TextStyle(
                      color: Color(0xFF38BDF8),
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom On-Screen Arcade Touch Controls
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Directional Buttons (Left & Right)
                Row(
                  children: [
                    _buildControlButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      label: 'LEFT',
                      onPressed: _moveLeft,
                    ),
                    const SizedBox(width: 14),
                    _buildControlButton(
                      icon: Icons.arrow_forward_ios_rounded,
                      label: 'RIGHT',
                      onPressed: _moveRight,
                    ),
                  ],
                ),

                // Big Glowing JUMP Button
                GestureDetector(
                  onTapDown: (_) => _jump(),
                  child: Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEA580C), Color(0xFFF97316)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEA580C).withValues(alpha: 0.6),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                      border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 3),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.keyboard_double_arrow_up_rounded, color: Colors.white, size: 36),
                        Text(
                          'JUMP',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTapDown: (_) => onPressed(),
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.90),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3D PERSPECTIVE ROBLOX OBBY CUSTOM PAINTER
// ---------------------------------------------------------------------------
class RobloxObbyPainter extends CustomPainter {
  final double playerX;
  final double playerY;
  final List<ObbyTrackItem> items;
  final double distance;
  final double legSwing;
  final double coinSpin;
  final bool isInvulnerable;

  RobloxObbyPainter({
    required this.playerX,
    required this.playerY,
    required this.items,
    required this.distance,
    required this.legSwing,
    required this.coinSpin,
    required this.isInvulnerable,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Horizon line
    final horizonY = h * 0.38;

    // 1. Sky Gradient & Stars
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF030712), Color(0xFF0F172A), Color(0xFF1E1B4B)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, horizonY));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, horizonY), skyPaint);

    // Neon Sun/Portal at Horizon
    final sunCenter = Offset(w * 0.5, horizonY - 10);
    final sunPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF818CF8).withValues(alpha: 0.7),
          const Color(0xFF4F46E5).withValues(alpha: 0.3),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: sunCenter, radius: 90));
    canvas.drawCircle(sunCenter, 90, sunPaint);

    // 2. Neon Perspective Floor (Lava Void & Grid Platforms)
    final floorPaint = Paint()..color = const Color(0xFF090D16);
    canvas.drawRect(Rect.fromLTWH(0, horizonY, w, h - horizonY), floorPaint);

    // Draw Perspective Running Track
    final trackPath = Path();
    final topTrackW = w * 0.28;
    final bottomTrackW = w * 0.94;

    trackPath.moveTo(w * 0.5 - topTrackW * 0.5, horizonY);
    trackPath.lineTo(w * 0.5 + topTrackW * 0.5, horizonY);
    trackPath.lineTo(w * 0.5 + bottomTrackW * 0.5, h);
    trackPath.lineTo(w * 0.5 - bottomTrackW * 0.5, h);
    trackPath.close();

    final trackPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF1E293B),
          const Color(0xFF0F172A),
          const Color(0xFF0B0F19),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, horizonY, w, h - horizonY));
    canvas.drawPath(trackPath, trackPaint);

    // Track Borders (Glowing Cyber Neon Rails)
    final railPaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(w * 0.5 - topTrackW * 0.5, horizonY), Offset(w * 0.5 - bottomTrackW * 0.5, h), railPaint);
    canvas.drawLine(Offset(w * 0.5 + topTrackW * 0.5, horizonY), Offset(w * 0.5 + bottomTrackW * 0.5, h), railPaint);

    // Dynamic Moving Grid Lines (Gives sensation of forward velocity)
    final gridLinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1.5;

    final offsetDistance = distance % 80;
    for (double z = 20; z < 700; z += 60) {
      final adjustedZ = z - offsetDistance;
      if (adjustedZ <= 5) continue;
      final t = 1.0 - (adjustedZ / 700.0);
      if (t < 0 || t > 1) continue;

      final y = horizonY + (h - horizonY) * math.pow(t, 2.2);
      final trackSpan = topTrackW + (bottomTrackW - topTrackW) * t;
      canvas.drawLine(
        Offset(w * 0.5 - trackSpan * 0.5, y),
        Offset(w * 0.5 + trackSpan * 0.5, y),
        gridLinePaint,
      );
    }

    // 3. Draw Track Items (Lava pits, Obstacle blocks, Robux coins) sorted by distance
    final sortedItems = List<ObbyTrackItem>.from(items)
      ..sort((a, b) => (b.z - distance).compareTo(a.z - distance));

    for (final item in sortedItems) {
      final zRel = item.z - distance;
      if (zRel <= 5 || zRel > 900) continue;

      final t = 1.0 - (zRel / 900.0);
      final y = horizonY + (h - horizonY) * math.pow(t, 2.2);
      final trackSpan = topTrackW + (bottomTrackW - topTrackW) * t;
      final x = w * 0.5 + (item.x * (trackSpan * 0.38));
      final scale = math.max(0.15, t);

      if (item.type == ObbyItemType.coin && !item.collected) {
        _drawRobuxCoin(canvas, Offset(x, y - (28 * scale)), scale);
      } else if (item.type == ObbyItemType.lava) {
        _drawLavaPit(canvas, Offset(x, y), scale, trackSpan * 0.28);
      } else if (item.type == ObbyItemType.hurdle) {
        _drawHurdleBlock(canvas, Offset(x, y), scale);
      }
    }

    // 4. Draw Blocky Roblox Avatar
    final playerBaseY = h * 0.76 - (playerY * 1.1);
    final playerBaseX = w * 0.5 + (playerX * (bottomTrackW * 0.38));

    _drawRobloxPlayer(
      canvas,
      Offset(playerBaseX, playerBaseY),
      legSwing,
      isInvulnerable,
      playerY > 5,
    );
  }

  void _drawRobuxCoin(Canvas canvas, Offset center, double scale) {
    final radius = 16.0 * scale;
    final spinWidth = radius * math.cos(coinSpin).abs();

    final coinPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFD700), Color(0xFFF59E0B), Color(0xFFB45309)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawOval(
      Rect.fromCenter(center: center, width: math.max(4.0, spinWidth * 2), height: radius * 2),
      coinPaint,
    );

    // Glowing rim
    final rimPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * scale;
    canvas.drawOval(
      Rect.fromCenter(center: center, width: math.max(4.0, spinWidth * 2), height: radius * 2),
      rimPaint,
    );
  }

  void _drawLavaPit(Canvas canvas, Offset center, double scale, double width) {
    final lavaRect = Rect.fromCenter(
      center: center,
      width: width,
      height: 22.0 * scale,
    );

    final lavaPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFEF4444), Color(0xFFF97316), Color(0xFFDC2626)],
      ).createShader(lavaRect);

    canvas.drawRRect(RRect.fromRectAndRadius(lavaRect, Radius.circular(6 * scale)), lavaPaint);

    // Fire glow
    final glowPaint = Paint()
      ..color = const Color(0xFFF59E0B).withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRect(lavaRect, glowPaint);
  }

  void _drawHurdleBlock(Canvas canvas, Offset center, double scale) {
    final blockW = 34.0 * scale;
    final blockH = 42.0 * scale;
    final rect = Rect.fromCenter(center: Offset(center.dx, center.dy - blockH * 0.5), width: blockW, height: blockH);

    final blockPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFE11D48), Color(0xFF881337)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);

    canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(5 * scale)), blockPaint);

    final borderPaint = Paint()
      ..color = Colors.white38
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * scale;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(5 * scale)), borderPaint);
  }

  void _drawRobloxPlayer(
    Canvas canvas,
    Offset pos,
    double swing,
    bool invulnerable,
    bool inAir,
  ) {
    if (invulnerable && (math.sin(swing * 20) > 0)) {
      return; // Blinking effect when taking damage
    }

    final shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.45);
    // Draw shadow on ground
    canvas.drawOval(
      Rect.fromCenter(center: Offset(pos.dx, pos.dy + 38), width: 44, height: 14),
      shadowPaint,
    );

    // --- LEGS (Blocky Roblox Green Legs) ---
    final legW = 11.0;
    final legH = 22.0;
    final legSwingOffset = inAir ? 6.0 : math.sin(swing) * 8.0;

    final legPaint = Paint()..color = const Color(0xFF15803D); // Roblox Green

    // Left Leg
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(pos.dx - 13, pos.dy + 12 - legSwingOffset, legW, legH),
        const Radius.circular(2),
      ),
      legPaint,
    );
    // Right Leg
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(pos.dx + 2, pos.dy + 12 + legSwingOffset, legW, legH),
        const Radius.circular(2),
      ),
      legPaint,
    );

    // --- TORSO (Blocky Blue Torso with 'R' Roblox logo) ---
    final torsoRect = Rect.fromCenter(center: Offset(pos.dx, pos.dy), width: 28, height: 26);
    final torsoPaint = Paint()..color = const Color(0xFF0284C7); // Roblox Sky Blue
    canvas.drawRRect(RRect.fromRectAndRadius(torsoRect, const Radius.circular(3)), torsoPaint);

    // White 'R' Logo on Torso
    final logoPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(Offset(pos.dx, pos.dy), 6, logoPaint);

    // --- ARMS (Blocky Yellow Arms swinging) ---
    final armW = 8.0;
    final armH = 22.0;
    final armPaint = Paint()..color = const Color(0xFFFACC15); // Roblox Yellow Head/Arm skin

    // Left Arm
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(pos.dx - 23, pos.dy - 12 + legSwingOffset, armW, armH),
        const Radius.circular(2),
      ),
      armPaint,
    );
    // Right Arm
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(pos.dx + 15, pos.dy - 12 - legSwingOffset, armW, armH),
        const Radius.circular(2),
      ),
      armPaint,
    );

    // --- HEAD (Classic Yellow Blocky Head with face) ---
    final headRect = Rect.fromCenter(center: Offset(pos.dx, pos.dy - 23), width: 19, height: 19);
    final headPaint = Paint()..color = const Color(0xFFFACC15);
    canvas.drawRRect(RRect.fromRectAndRadius(headRect, const Radius.circular(3)), headPaint);

    // Roblox Cute Eyes & Smile
    final eyePaint = Paint()..color = const Color(0xFF0F172A);
    canvas.drawCircle(Offset(pos.dx - 4, pos.dy - 25), 2.0, eyePaint);
    canvas.drawCircle(Offset(pos.dx + 4, pos.dy - 25), 2.0, eyePaint);

    final smilePaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(pos.dx, pos.dy - 21), width: 7, height: 6),
      0,
      math.pi,
      false,
      smilePaint,
    );

    // Head Hat / Cap (Red Gamer Cap)
    final capPaint = Paint()..color = const Color(0xFFEF4444);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(pos.dx - 11, pos.dy - 34, 22, 6),
        const Radius.circular(2),
      ),
      capPaint,
    );
  }

  @override
  bool shouldRepaint(covariant RobloxObbyPainter oldDelegate) => true;
}
