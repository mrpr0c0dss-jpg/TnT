import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/mini_game_model.dart';
import '../services/app_state.dart';
import '../services/arcade_games_engine.dart';
import '../widgets/games/roblox_obby_widget.dart';
import '../widgets/games/space_defender_widget.dart';
import '../widgets/games/diamond_2048_widget.dart';

class InAppGameScreen extends StatefulWidget {
  final MiniGameModel game;
  final AppState appState;

  const InAppGameScreen({
    super.key,
    required this.game,
    required this.appState,
  });

  @override
  State<InAppGameScreen> createState() => _InAppGameScreenState();
}

class _InAppGameScreenState extends State<InAppGameScreen> {
  // Engine Mode: Native 60 FPS 3D vs Web HTML5 / WebGL
  bool _useNativeEngine = true;
  int _gameKey = 0; // Incremented to restart native game

  // Webview variables (for external games / web mode)
  WebViewController? _webController;
  bool _isWebLoading = true;
  String? _webError;

  @override
  void initState() {
    super.initState();
    // External ready-made games (Bloxd.io, HexGL, Smash Karts) run in Web engine
    // Built-in titles (Roblox: 3D Obby Parkour) run in 3D Perspective native runner
    if (widget.game.externalUrl != null && widget.game.externalUrl!.isNotEmpty) {
      _useNativeEngine = false;
      _initWebView();
    } else {
      _useNativeEngine = true;
    }
  }

  void _initWebView() {
    try {
      _webController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFF0B0F19))
        ..setUserAgent('Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148')
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (progress) {
              if (progress >= 65 && mounted && _isWebLoading) {
                setState(() => _isWebLoading = false);
              }
            },
            onPageFinished: (_) {
              if (mounted) setState(() => _isWebLoading = false);
            },
            onWebResourceError: (error) {
              if (error.isForMainFrame == true && mounted) {
                setState(() {
                  _webError = error.description;
                  _isWebLoading = false;
                });
              }
            },
          ),
        )
        ..addJavaScriptChannel(
          'FlutterTNTGameBridge',
          onMessageReceived: (JavaScriptMessage message) {
            _handleGameBridgeMessage(message.message);
          },
        );

      if (widget.game.externalUrl != null && widget.game.externalUrl!.isNotEmpty) {
        _webController!.loadRequest(Uri.parse(widget.game.externalUrl!));
      } else {
        final html = ArcadeGamesEngine.getGameHtml(widget.game.id);
        _webController!.loadHtmlString(html, baseUrl: 'https://flutter.dev');
      }

      // Safety timeout: dismiss spinner after 3 seconds max
      Future.delayed(const Duration(milliseconds: 3200), () {
        if (mounted && _isWebLoading) {
          setState(() => _isWebLoading = false);
        }
      });
    } catch (e) {
      // Fallback to native engine if WebView plugin fails
      setState(() {
        _useNativeEngine = true;
        _isWebLoading = false;
      });
    }
  }

  void _handleGameBridgeMessage(String rawJson) {
    try {
      final data = jsonDecode(rawJson);
      final event = data['event'];
      if (event == 'GAME_OVER') {
        final score = (data['score'] as num?)?.toInt() ?? 0;
        final coins = (data['coins'] as num?)?.toInt() ?? 10;
        _handleGameOver(score, coins);
      }
    } catch (_) {}
  }

  void _handleGameOver(int score, int coins) {
    if (!mounted) return;

    final coinAmount = coins * 0.01; // 1 coin = $0.01 USD credit
    widget.appState.awardArcadeReward(
      amount: coinAmount,
      gameTitle: widget.game.title,
      score: score,
    );

    _showVictoryCelebration(score, coins, coinAmount);
  }

  void _restartGame() {
    setState(() {
      _gameKey++;
      if (!_useNativeEngine && _webController != null) {
        _webController!.reload();
      }
    });
  }

  void _showVictoryCelebration(int score, int coins, double coinAmount) {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            const Text('🎉', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text(
              '${widget.game.title} Complete!',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 6),
            const Text(
              'Your high-score was recorded and synced to your platform wallet!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('FINAL SCORE', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('$score', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF38BDF8))),
                    ],
                  ),
                  Container(width: 1, height: 36, color: const Color(0xFF334155)),
                  Column(
                    children: [
                      const Text('REWARD EARNED', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('+$coins Coins', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF10B981))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF475569)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Exit to Lobby'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _restartGame();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B5CDB),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Play Again'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameBody() {
    if (_useNativeEngine) {
      switch (widget.game.id) {
        case 'roblox_obby_3d':
          return RobloxObbyWidget(
            key: ValueKey('roblox_$_gameKey'),
            onGameOver: _handleGameOver,
          );
        case 'cyber_space_shooter':
          return SpaceDefenderWidget(
            key: ValueKey('space_$_gameKey'),
            onGameOver: _handleGameOver,
          );
        case 'diamond_merge_2048':
          return Diamond2048Widget(
            key: ValueKey('diamond_$_gameKey'),
            onGameOver: _handleGameOver,
          );
        default:
          return RobloxObbyWidget(
            key: ValueKey('default_$_gameKey'),
            onGameOver: _handleGameOver,
          );
      }
    } else {
      if (_webController == null) {
        _initWebView();
      }
      return Stack(
        children: [
          if (_webController != null)
            WebViewWidget(controller: _webController!),
          if (_isWebLoading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF0B5CDB)),
            ),
          if (_webError != null)
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 10),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Web Notice: $_webError',
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _webError = null;
                          _isWebLoading = true;
                        });
                        _webController?.reload();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0B5CDB),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      body: SafeArea(
        child: Stack(
          children: [
            // Game Arena Body
            _buildGameBody(),

            // Minimalist Floating Back Button (unobtrusive, does not block game controls or scoreboards)
            Positioned(
              top: 10,
              left: 12,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.65),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
