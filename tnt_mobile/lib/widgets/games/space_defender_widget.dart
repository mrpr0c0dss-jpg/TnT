import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SpaceDefenderWidget extends StatefulWidget {
  final Function(int score, int coins) onGameOver;
  final Function(int score)? onScoreChanged;

  const SpaceDefenderWidget({
    super.key,
    required this.onGameOver,
    this.onScoreChanged,
  });

  @override
  State<SpaceDefenderWidget> createState() => _SpaceDefenderWidgetState();
}

class Projectile {
  double x, y;
  Projectile({required this.x, required this.y});
}

class SpaceEnemy {
  double x, y;
  double speed;
  int hp;
  bool isBoss;
  SpaceEnemy({required this.x, required this.y, required this.speed, this.hp = 1, this.isBoss = false});
}

class Particle {
  double x, y, vx, vy;
  Color color;
  int life;
  Particle({required this.x, required this.y, required this.vx, required this.vy, required this.color, required this.life});
}

class _SpaceDefenderWidgetState extends State<SpaceDefenderWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;

  double _playerX = 0.5; // 0.0 to 1.0 (relative screen width)
  int _score = 0;
  int _coins = 0;
  int _lives = 3;
  bool _isGameOver = false;

  final List<Projectile> _lasers = [];
  final List<SpaceEnemy> _enemies = [];
  final List<Particle> _particles = [];
  int _shotCooldown = 0;
  int _spawnCooldown = 0;
  final math.Random _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..addListener(_gameLoop);
    _ticker.repeat();
  }

  void _gameLoop() {
    if (_isGameOver) return;

    // Auto-fire laser
    _shotCooldown++;
    if (_shotCooldown >= 10) {
      _shotCooldown = 0;
      _lasers.add(Projectile(x: _playerX, y: 0.82));
    }

    // Spawn enemies
    _spawnCooldown++;
    if (_spawnCooldown >= 28) {
      _spawnCooldown = 0;
      _enemies.add(SpaceEnemy(
        x: 0.1 + _rng.nextDouble() * 0.8,
        y: -0.05,
        speed: 0.004 + _rng.nextDouble() * 0.005,
      ));
    }

    // Update lasers
    for (int i = _lasers.length - 1; i >= 0; i--) {
      _lasers[i].y -= 0.025;
      if (_lasers[i].y < -0.05) {
        _lasers.removeAt(i);
      }
    }

    // Update enemies & collisions
    for (int eIdx = _enemies.length - 1; eIdx >= 0; eIdx--) {
      final enemy = _enemies[eIdx];
      enemy.y += enemy.speed;

      // Laser collision
      for (int lIdx = _lasers.length - 1; lIdx >= 0; lIdx--) {
        final laser = _lasers[lIdx];
        final dx = (laser.x - enemy.x).abs();
        final dy = (laser.y - enemy.y).abs();
        if (dx < 0.08 && dy < 0.05) {
          _lasers.removeAt(lIdx);
          enemy.hp--;
          if (enemy.hp <= 0) {
            _spawnExplosion(enemy.x, enemy.y);
            _enemies.removeAt(eIdx);
            _score += 150;
            if (_rng.nextDouble() < 0.5) _coins++;
            widget.onScoreChanged?.call(_score);
            HapticFeedback.lightImpact();
            break;
          }
        }
      }

      // Check if enemy collided with player
      if (eIdx < _enemies.length) {
        final distToPlayerX = (_playerX - enemy.x).abs();
        final distToPlayerY = (0.85 - enemy.y).abs();
        if (distToPlayerX < 0.10 && distToPlayerY < 0.06) {
          _spawnExplosion(enemy.x, enemy.y);
          _enemies.removeAt(eIdx);
          _lives--;
          HapticFeedback.heavyImpact();
          if (_lives <= 0) {
            _isGameOver = true;
            _ticker.stop();
            widget.onGameOver(_score, _coins);
            return;
          }
        } else if (enemy.y > 1.05) {
          _enemies.removeAt(eIdx);
        }
      }
    }

    // Update particles
    for (int i = _particles.length - 1; i >= 0; i--) {
      final p = _particles[i];
      p.x += p.vx;
      p.y += p.vy;
      p.life--;
      if (p.life <= 0) _particles.removeAt(i);
    }

    setState(() {});
  }

  void _spawnExplosion(double x, double y) {
    for (int i = 0; i < 14; i++) {
      final angle = _rng.nextDouble() * 2 * math.pi;
      final speed = 0.002 + _rng.nextDouble() * 0.008;
      _particles.add(Particle(
        x: x,
        y: y,
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed,
        color: _rng.nextBool() ? const Color(0xFFF59E0B) : const Color(0xFFEF4444),
        life: 18 + _rng.nextInt(12),
      ));
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
      onPanUpdate: (details) {
        final box = context.findRenderObject() as RenderBox?;
        if (box != null) {
          setState(() {
            _playerX = (details.localPosition.dx / box.size.width).clamp(0.08, 0.92);
          });
        }
      },
      child: Stack(
        children: [
          CustomPaint(
            painter: SpaceShooterPainter(
              playerX: _playerX,
              lasers: _lasers,
              enemies: _enemies,
              particles: _particles,
            ),
            child: const SizedBox.expand(),
          ),

          // Top In-Game HUD
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
                    children: List.generate(
                      3,
                      (i) => Icon(
                        Icons.shield_rounded,
                        size: 16,
                        color: i < _lives ? const Color(0xFF38BDF8) : Colors.white24,
                      ),
                    ),
                  ),
                ),

                // Coins
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Text('🪙', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 5),
                      Text(
                        '$_coins',
                        style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),

                // Score
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    '$_score PTS',
                    style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          // Guidance prompt
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '👈 Drag finger left or right to steer starship 👉',
                  style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SpaceShooterPainter extends CustomPainter {
  final double playerX;
  final List<Projectile> lasers;
  final List<SpaceEnemy> enemies;
  final List<Particle> particles;

  SpaceShooterPainter({
    required this.playerX,
    required this.lasers,
    required this.enemies,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Deep Space Background
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF030712), Color(0xFF0B1329), Color(0xFF1A103C)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // Stars
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.35);
    for (int i = 0; i < 40; i++) {
      final sx = (i * 97) % w;
      final sy = (i * 137) % h;
      canvas.drawCircle(Offset(sx, sy), (i % 3 == 0) ? 1.5 : 1.0, starPaint);
    }

    // Lasers (Glowing Neon Cyan bolts)
    final laserPaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    for (final l in lasers) {
      canvas.drawLine(Offset(l.x * w, l.y * h), Offset(l.x * w, (l.y - 0.03) * h), laserPaint);
    }

    // Enemies (Alien Raiders)
    for (final e in enemies) {
      final ec = Offset(e.x * w, e.y * h);
      final enemyPaint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFF991B1B)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromCircle(center: ec, radius: 18));

      final enemyPath = Path();
      enemyPath.moveTo(ec.dx, ec.dy + 14);
      enemyPath.lineTo(ec.dx - 16, ec.dy - 12);
      enemyPath.lineTo(ec.dx + 16, ec.dy - 12);
      enemyPath.close();
      canvas.drawPath(enemyPath, enemyPaint);

      // Eye
      final eyePaint = Paint()..color = const Color(0xFFFDE047);
      canvas.drawCircle(Offset(ec.dx, ec.dy - 2), 4, eyePaint);
    }

    // Particles
    for (final p in particles) {
      final pPaint = Paint()..color = p.color.withValues(alpha: p.life / 30.0);
      canvas.drawCircle(Offset(p.x * w, p.y * h), 2.5, pPaint);
    }

    // Player Starship (Cyber Viper)
    final pc = Offset(playerX * w, 0.85 * h);
    final shipPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCircle(center: pc, radius: 24));

    final shipPath = Path();
    shipPath.moveTo(pc.dx, pc.dy - 22);
    shipPath.lineTo(pc.dx - 22, pc.dy + 18);
    shipPath.lineTo(pc.dx, pc.dy + 8);
    shipPath.lineTo(pc.dx + 22, pc.dy + 18);
    shipPath.close();
    canvas.drawPath(shipPath, shipPaint);

    // Engine Thruster Flame
    final thrusterPaint = Paint()..color = const Color(0xFFF97316);
    canvas.drawCircle(Offset(pc.dx, pc.dy + 15), 6, thrusterPaint);
  }

  @override
  bool shouldRepaint(covariant SpaceShooterPainter oldDelegate) => true;
}
