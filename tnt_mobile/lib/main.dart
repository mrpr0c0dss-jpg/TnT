import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'services/app_state.dart';
import 'theme/app_theme.dart';
import 'widgets/app_header.dart';
import 'widgets/bottom_nav_bar.dart';
import 'screens/home_screen.dart';
import 'screens/topup_screen.dart';
import 'screens/tournaments_screen.dart';
import 'screens/my_matches_screen.dart';
import 'screens/wallet_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/admin_panel_shell.dart';
import 'screens/arcade_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final appState = AppState();
  runApp(TnTGamingApp(appState: appState));
  // Initialize state asynchronously so Flutter renders the UI immediately
  appState.init();
}

class TnTGamingApp extends StatelessWidget {
  final AppState appState;

  const TnTGamingApp({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final bool showAdminPanel = appState.isLoggedIn &&
            appState.currentUser.isAdmin &&
            appState.isAdminPanelActive;

        return MaterialApp(
          title: 'TnT — TopUp & Tournament',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: showAdminPanel
              ? AdminPanelShell(appState: appState)
              : MainShell(appState: appState),
        );
      },
    );
  }
}

class MainShell extends StatefulWidget {
  final AppState appState;

  const MainShell({super.key, required this.appState});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  bool _isBottomNavVisible = true;
  int _lastTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _lastTabIndex = widget.appState.currentTabIndex;
    widget.appState.addListener(_onAppStateChanged);
  }

  @override
  void dispose() {
    widget.appState.removeListener(_onAppStateChanged);
    super.dispose();
  }

  void _onAppStateChanged() {
    if (widget.appState.currentTabIndex != _lastTabIndex) {
      _lastTabIndex = widget.appState.currentTabIndex;
      if (!_isBottomNavVisible) {
        setState(() {
          _isBottomNavVisible = true;
        });
      }
    }
  }

  bool _onScrollNotification(ScrollNotification notification) {
    // Only respond to vertical scrolling, ignore horizontal carousels/swipes
    if (notification.metrics.axis == Axis.vertical) {
      if (notification is UserScrollNotification) {
        // Dragging finger up (content scrolls down) -> slide down & hide navbar
        if (notification.direction == ScrollDirection.reverse) {
          if (_isBottomNavVisible) {
            setState(() {
              _isBottomNavVisible = false;
            });
          }
        }
        // Dragging finger down (content scrolls up) -> slide up & show navbar
        else if (notification.direction == ScrollDirection.forward) {
          if (!_isBottomNavVisible) {
            setState(() {
              _isBottomNavVisible = true;
            });
          }
        }
      } else if (notification is ScrollUpdateNotification) {
        // If scrolled back to the very top, always show navbar
        if (notification.metrics.pixels <= 10 && !_isBottomNavVisible) {
          setState(() {
            _isBottomNavVisible = true;
          });
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    Widget activeScreen;
    switch (widget.appState.currentTabIndex) {
      case 0:
        activeScreen = HomeScreen(appState: widget.appState);
        break;
      case 1:
        activeScreen = TopUpScreen(appState: widget.appState);
        break;
      case 2:
        activeScreen = TournamentsScreen(appState: widget.appState);
        break;
      case 3:
        activeScreen = MyMatchesScreen(appState: widget.appState);
        break;
      case 4:
        activeScreen = ArcadeScreen(appState: widget.appState);
        break;
      case 5:
        activeScreen = ProfileScreen(appState: widget.appState);
        break;
      case 6:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.appState.setAdminPanelActive(true);
        });
        activeScreen = AdminPanelShell(appState: widget.appState);
        break;
      case 7:
        activeScreen = WalletScreen(appState: widget.appState);
        break;
      default:
        activeScreen = HomeScreen(appState: widget.appState);
    }

    final isAdminPreviewing = widget.appState.currentUser.isAdmin && !widget.appState.isAdminPanelActive;

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      extendBody: true,
      appBar: AppHeader(appState: widget.appState),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: isAdminPreviewing
          ? Container(
              margin: const EdgeInsets.only(bottom: 58),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: const Color(0xFF6366F1), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF59E0B),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '🛡️ Admin Active (Gamer Mode)',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: () => widget.appState.setAdminPanelActive(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        children: [
                          Text('Command Center', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                          SizedBox(width: 3),
                          Icon(Icons.arrow_forward_rounded, size: 12, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
      body: NotificationListener<ScrollNotification>(
        onNotification: _onScrollNotification,
        child: activeScreen,
      ),
      bottomNavigationBar: AnimatedSlide(
        offset: _isBottomNavVisible ? Offset.zero : const Offset(0, 1.3),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOutCubic,
        child: AnimatedOpacity(
          opacity: _isBottomNavVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: IgnorePointer(
            ignoring: !_isBottomNavVisible,
            child: BottomNavBar(appState: widget.appState),
          ),
        ),
      ),
    );
  }
}

