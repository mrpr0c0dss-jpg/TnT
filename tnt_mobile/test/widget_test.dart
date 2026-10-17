import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tnt_mobile/main.dart';
import 'package:tnt_mobile/screens/auth_screen.dart';
import 'package:tnt_mobile/services/app_state.dart';
import 'package:tnt_mobile/widgets/bottom_nav_bar.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('TnTGamingApp smoke test', (WidgetTester tester) async {
    final appState = AppState();
    await tester.pumpWidget(TnTGamingApp(appState: appState));
    expect(find.text('TnT'), findsWidgets);
  });

  testWidgets('Bottom navbar slides down on scroll down, and slides back up on scroll up',
      (WidgetTester tester) async {
    final appState = AppState();
    await tester.pumpWidget(TnTGamingApp(appState: appState));
    await tester.pump(const Duration(milliseconds: 350));

    // 1. Initial State: bottom navbar is at Offset.zero
    Finder animatedSlideFinder = find.ancestor(
      of: find.byType(BottomNavBar),
      matching: find.byType(AnimatedSlide),
    );
    expect(animatedSlideFinder, findsOneWidget);

    AnimatedSlide slideWidget = tester.widget<AnimatedSlide>(animatedSlideFinder);
    expect(slideWidget.offset, equals(Offset.zero));

    // 2. Drag finger upwards (scrolls down into content) -> navbar slides down
    await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -300));
    await tester.pump(const Duration(milliseconds: 350));

    slideWidget = tester.widget<AnimatedSlide>(animatedSlideFinder);
    expect(slideWidget.offset, equals(const Offset(0, 1.3)));

    // 3. Drag finger downwards (scrolls up towards top) -> navbar slides back up
    await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, 300));
    await tester.pump(const Duration(milliseconds: 350));

    slideWidget = tester.widget<AnimatedSlide>(animatedSlideFinder);
    expect(slideWidget.offset, equals(Offset.zero));
  });

  testWidgets('Bottom navbar resets to visible when switching tabs', (WidgetTester tester) async {
    final appState = AppState();
    await tester.pumpWidget(TnTGamingApp(appState: appState));
    await tester.pump(const Duration(milliseconds: 350));

    Finder animatedSlideFinder = find.ancestor(
      of: find.byType(BottomNavBar),
      matching: find.byType(AnimatedSlide),
    );

    // Scroll down to hide navbar
    await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -300));
    await tester.pump(const Duration(milliseconds: 350));

    AnimatedSlide slideWidget = tester.widget<AnimatedSlide>(animatedSlideFinder);
    expect(slideWidget.offset, equals(const Offset(0, 1.3)));

    // Switch tab programmatically (e.g., to Tournaments tab index 2)
    appState.setTab(2);
    await tester.pump(const Duration(milliseconds: 350));

    slideWidget = tester.widget<AnimatedSlide>(animatedSlideFinder);
    expect(slideWidget.offset, equals(Offset.zero));
  });

  testWidgets('Zero fake data initial state test', (WidgetTester tester) async {
    final appState = AppState();
    expect(appState.isLoggedIn, isFalse);
    expect(appState.wallet.availableBalance, equals(0.0));
    expect(appState.wallet.lockedBalance, equals(0.0));
    expect(appState.transactions, isEmpty);
    expect(appState.myMatches, isEmpty);
    expect(appState.currentUser.email, isEmpty);
  });

  testWidgets('Profile screen displays authentication form when logged out', (WidgetTester tester) async {
    final appState = AppState();
    await tester.pumpWidget(TnTGamingApp(appState: appState));
    await tester.pump(const Duration(milliseconds: 350));

    // Switch to Profile Tab (index 5)
    appState.setTab(5);
    await tester.pump(const Duration(milliseconds: 500));

    // Verify Premium Esports Auth UI elements
    expect(find.text('PLAY  •  COMPETE  •  WIN'), findsOneWidget);
    expect(find.text('Welcome Back, Gamer'), findsOneWidget);
    expect(find.text('Continue with Google / Gmail'), findsOneWidget);
    expect(find.text('SIGN IN'), findsOneWidget);
    expect(find.text('REGISTER'), findsOneWidget);
    expect(find.text('ENTER ARENA'), findsOneWidget);
    expect(find.text('Forgot Password?'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Google login and logout cycle works cleanly', (WidgetTester tester) async {
    final appState = AppState();
    await tester.pumpWidget(TnTGamingApp(appState: appState));
    await tester.pump(const Duration(milliseconds: 350));

    // Sign in with Google
    await appState.signInWithGoogle(email: 'proplayer@gmail.com', displayName: 'ProPlayer');
    expect(appState.isLoggedIn, isTrue);
    expect(appState.currentUser.email, equals('proplayer@gmail.com'));
    expect(appState.currentUser.displayName, equals('ProPlayer'));

    // Switch to Profile Tab
    appState.setTab(5);
    await tester.pump(const Duration(milliseconds: 350));

    // Verify Logged In Profile UI elements
    expect(find.text('ProPlayer'), findsWidgets);
    expect(find.text('proplayer@gmail.com'), findsOneWidget);
    expect(find.text('Sign Out Session'), findsOneWidget);

    // Sign out
    await appState.signOut();
    expect(appState.isLoggedIn, isFalse);
    expect(appState.wallet.availableBalance, equals(0.0));
    expect(appState.currentUser.email, isEmpty);

    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.text('Continue with Google / Gmail'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('AuthScreen switches between SIGN IN and REGISTER smoothly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final appState = AppState();
    await tester.pumpWidget(MaterialApp(home: AuthScreen(appState: appState, isEmbedded: true)));
    await tester.pump(const Duration(milliseconds: 1200));

    expect(find.text('Welcome Back, Gamer'), findsOneWidget);
    expect(find.text('ENTER ARENA'), findsOneWidget);

    // Tap REGISTER tab
    await tester.tap(find.text('REGISTER'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Create Gamer Account'), findsOneWidget);
    expect(find.text('JOIN THE ARENA'), findsOneWidget);
    expect(find.text('Gamer Display Name'), findsOneWidget);
    expect(find.text('Confirm Password'), findsOneWidget);

    // Tap back to SIGN IN tab
    await tester.tap(find.text('SIGN IN'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Welcome Back, Gamer'), findsOneWidget);
    expect(find.text('ENTER ARENA'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Bottom navbar displays Games item and switches to Games tab', (WidgetTester tester) async {
    final appState = AppState();
    await tester.pumpWidget(TnTGamingApp(appState: appState));
    await tester.pump(const Duration(milliseconds: 350));

    // Verify Games is in the navbar and Wallet is not in the bottom navbar
    expect(find.text('Games'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Top-Up'), findsOneWidget);
    expect(find.text('Tournaments'), findsOneWidget);
    expect(find.text('Matches'), findsOneWidget);

    // Tap Games in bottom navbar
    await tester.tap(find.text('Games'));
    await tester.pump(const Duration(milliseconds: 350));

    expect(appState.currentTabIndex, equals(4));
    await tester.pumpWidget(const SizedBox());
  });
}

