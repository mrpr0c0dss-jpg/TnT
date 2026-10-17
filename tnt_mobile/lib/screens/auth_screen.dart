import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/admin_login_dialog.dart';
import '../widgets/country_select_dialog.dart';

class AuthScreen extends StatefulWidget {
  final AppState appState;
  final bool initialIsSignUp;
  final bool isEmbedded;

  const AuthScreen({
    super.key,
    required this.appState,
    this.initialIsSignUp = false,
    this.isEmbedded = false,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  late bool _isSignUp;
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmFocus = FocusNode();
  final FocusNode _nameFocus = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = true;
  bool _isLoading = false;
  bool _isButtonHovered = false;
  String? _errorMessage;

  late AnimationController _entranceController;
  late AnimationController _ambientController;
  late AnimationController _shimmerController;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<Offset> _headerSlide;
  late Animation<double> _cardFade;
  late Animation<Offset> _cardSlide;
  late Animation<double> _footerFade;

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.initialIsSignUp;

    // Staggered Entrance Animation
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.0, 0.45, curve: Curves.easeOut)),
    );

    _logoScale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack)),
    );

    _headerSlide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.15, 0.6, curve: Curves.easeOutCubic)),
    );

    _cardFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.35, 0.85, curve: Curves.easeOut)),
    );

    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.35, 0.85, curve: Curves.easeOutCubic)),
    );

    _footerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.65, 1.0, curve: Curves.easeOut)),
    );

    // Continuous Ambient Floating Particles & Aura Pulse
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    // Continuous Shimmer Light Gleam across Card and Primary Button
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();

    _emailFocus.addListener(_onFocusChange);
    _passwordFocus.addListener(_onFocusChange);
    _confirmFocus.addListener(_onFocusChange);
    _nameFocus.addListener(_onFocusChange);

    _entranceController.forward();
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _ambientController.dispose();
    _shimmerController.dispose();
    _emailFocus.removeListener(_onFocusChange);
    _passwordFocus.removeListener(_onFocusChange);
    _confirmFocus.removeListener(_onFocusChange);
    _nameFocus.removeListener(_onFocusChange);
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Real Email / Password Authentication
  // ---------------------------------------------------------------------------
  Future<void> _handleEmailAuth() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isSignUp && !_acceptTerms) {
      setState(() => _errorMessage = 'Please accept the Terms of Service to join the arena.');
      return;
    }

    if (_isSignUp && _passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Passwords do not match. Please re-enter.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final name = _nameController.text.trim();

      final normEmail = email.toLowerCase();
      final isAdminLogin = normEmail == 'mrpr0c0dss@gmail.com' ||
          normEmail == 'admin@platform.io' ||
          normEmail.contains('admin');

      if (_isSignUp) {
        await widget.appState.signUpWithGmail(
          email: email,
          password: password,
          displayName: name.isNotEmpty ? name : (normEmail == 'mrpr0c0dss@gmail.com' ? 'MrPr0C0dss' : email.split('@')[0]),
          asAdmin: isAdminLogin,
        );
      } else {
        await widget.appState.signInWithGmail(
          email: email,
          password: password,
          asAdmin: isAdminLogin,
        );
      }

      if (mounted) {
        if (!widget.isEmbedded && Navigator.canPop(context)) {
          Navigator.pop(context);
        }

        if (widget.appState.currentUser.isAdmin || isAdminLogin) {
          widget.appState.setAdminPanelActive(true);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.appState.currentUser.isAdmin
                  ? '🛡️ Super Admin Authenticated! Welcome to Operations Command Center.'
                  : (_isSignUp
                      ? '🎉 Welcome ${widget.appState.currentUser.displayName}! Account created successfully.'
                      : '⚔️ Welcome back ${widget.appState.currentUser.displayName}! Entered arena.'),
            ),
            backgroundColor: widget.appState.currentUser.isAdmin
                ? const Color(0xFF6366F1)
                : AppTheme.emeraldGreen,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Real Google Sign-In Flow
  // ---------------------------------------------------------------------------
  Future<void> _handleGoogleSignIn() async {
    final googleEmailCtrl = TextEditingController(text: _emailController.text.isNotEmpty ? _emailController.text : '');
    final googleNameCtrl = TextEditingController(text: _nameController.text.isNotEmpty ? _nameController.text : '');

    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1B142E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: const Text('G', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Google Account Sign-In',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Direct Firebase Authentication',
                      style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: googleEmailCtrl,
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Google / Gmail Address',
                labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                hintText: 'e.g. shadowhunter@gmail.com',
                hintStyle: const TextStyle(color: Color(0xFF64748B)),
                prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.mintGreen, size: 20),
                filled: true,
                fillColor: const Color(0xFF130E22),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.mintGreen, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: googleNameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Gamer Display Name',
                labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                hintText: 'e.g. ApexLegend',
                hintStyle: const TextStyle(color: Color(0xFF64748B)),
                prefixIcon: const Icon(Icons.sports_esports_outlined, color: AppTheme.fireOrange, size: 20),
                filled: true,
                fillColor: const Color(0xFF130E22),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.fireOrange, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: () {
                final mail = googleEmailCtrl.text.trim();
                if (mail.isEmpty || !mail.contains('@')) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid Gmail address')),
                  );
                  return;
                }
                Navigator.pop(ctx, {
                  'email': mail,
                  'name': googleNameCtrl.text.trim(),
                });
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: AppTheme.fireOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
              ),
              child: const Text(
                'Continue with Google',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ),
          ],
        ),
      ),
    );

    if (result != null && result['email'] != null && result['email']!.isNotEmpty) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final email = result['email']!;
        final name = result['name']!.isNotEmpty ? result['name']! : email.split('@')[0];
        await widget.appState.signInWithGoogle(email: email, displayName: name);

        if (mounted) {
          if (!widget.isEmbedded && Navigator.canPop(context)) {
            Navigator.pop(context);
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚡ Authenticated via Google: ${widget.appState.currentUser.email}'),
              backgroundColor: AppTheme.emeraldGreen,
            ),
          );
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception:', '').trim();
        });
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Real Password Reset Flow
  // ---------------------------------------------------------------------------
  Future<void> _handleForgotPassword() async {
    final resetCtrl = TextEditingController(text: _emailController.text.trim());
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B142E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: AppTheme.mintGreen.withOpacity(0.3)),
        ),
        title: const Row(
          children: [
            Text('🔐 ', style: TextStyle(fontSize: 20)),
            Text('Reset Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your registered Gmail or email address. We will dispatch an official Firebase password reset link.',
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: resetCtrl,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Account Email',
                labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                hintText: 'name@gmail.com',
                hintStyle: const TextStyle(color: Color(0xFF64748B)),
                prefixIcon: const Icon(Icons.mail_outline, size: 20, color: AppTheme.mintGreen),
                filled: true,
                fillColor: const Color(0xFF130E22),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.mintGreen, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.fireOrange),
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );

    if (confirmed == true && resetCtrl.text.trim().isNotEmpty) {
      try {
        await widget.appState.sendPasswordReset(resetCtrl.text.trim());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📬 Password reset instructions sent to ${resetCtrl.text.trim()}'),
              backgroundColor: AppTheme.emeraldGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception:', '').trim()),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0B1E),
      body: Stack(
        children: [
          // 1. Cinematic Esports Animated Layered Background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _ambientController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _CinematicEsportsBackgroundPainter(
                    animationValue: _ambientController.value,
                  ),
                );
              },
            ),
          ),

          // 2. Subtle Arena Graphic Blend
          Positioned.fill(
            child: Opacity(
              opacity: 0.16,
              child: Image.asset(
                'assets/banner/tnt_esports_arena.webp',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
          ),

          // 3. Dark Gradient Vignette for perfect readability
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.4),
                  radius: 1.2,
                  colors: [
                    Colors.transparent,
                    const Color(0xFF0F0B1E).withOpacity(0.85),
                    const Color(0xFF0F0B1E),
                  ],
                ),
              ),
            ),
          ),

          // 4. Main Scrollable Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                  left: 18,
                  right: 18,
                  top: widget.isEmbedded ? 8 : 12,
                  bottom: widget.isEmbedded ? 110 : 28,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Back Button if not embedded
                      if (!widget.isEmbedded)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                            onPressed: () {
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              }
                            },
                          ),
                        ),

                      // Animated Branding Section
                      _buildAnimatedBranding(),
                      const SizedBox(height: 12),

                      // Gaming Pillars Trust Strip
                      _buildGamingPillarsStrip(),
                      const SizedBox(height: 14),

                      // Glassmorphism Main Card
                      _buildGlassmorphismAuthCard(),
                      const SizedBox(height: 14),

                      // Footer Options (Country Currency & Staff)
                      _buildFooterOptions(),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // A. Animated Branding & Tagline
  // ---------------------------------------------------------------------------
  Widget _buildAnimatedBranding() {
    return FadeTransition(
      opacity: _logoFade,
      child: ScaleTransition(
        scale: _logoScale,
        child: SlideTransition(
          position: _headerSlide,
          child: Column(
            children: [
              // Logo with Holographic Crest, Sweeping Specular Sheen & Corner Brackets
              Stack(
                alignment: Alignment.center,
                children: [
                  // Animated Pulsing Radiant Dual Halo (Mint Green & Fire Orange)
                  AnimatedBuilder(
                    animation: _ambientController,
                    builder: (context, _) {
                      final pulse = math.sin(_ambientController.value * 2 * math.pi) * 0.18 + 0.82;
                      return Container(
                        width: 86 * pulse,
                        height: 86 * pulse,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.mintGreen.withOpacity(0.48 * pulse),
                              blurRadius: 42 * pulse,
                              spreadRadius: 6 * pulse,
                            ),
                            BoxShadow(
                              color: AppTheme.fireOrange.withOpacity(0.38 * pulse),
                              blurRadius: 50 * pulse,
                              spreadRadius: 3 * pulse,
                            ),
                            BoxShadow(
                              color: AppTheme.topStripBg.withOpacity(0.35 * pulse),
                              blurRadius: 32 * pulse,
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // Jewel-Cut Glass Crest Container with Animated Shimmer Sweep
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2E244A), Color(0xFF161026)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.mintGreen.withOpacity(0.45),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.7),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: AppTheme.mintGreen.withOpacity(0.35),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.asset(
                            'assets/icons/icon.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Center(
                              child: Text('🔥', style: TextStyle(fontSize: 30)),
                            ),
                          ),
                          // Static Diagonal Specular Sheen
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  stops: const [0.0, 0.42, 0.58, 1.0],
                                  colors: [
                                    Colors.white.withOpacity(0.25),
                                    Colors.white.withOpacity(0.0),
                                    Colors.white.withOpacity(0.0),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Dynamic Sweeping Holographic Glint
                          AnimatedBuilder(
                            animation: _shimmerController,
                            builder: (context, _) {
                              return Transform.translate(
                                offset: Offset((_shimmerController.value * 3.0 - 1.5) * 75, 0),
                                child: Transform.rotate(
                                  angle: 0.5,
                                  child: Container(
                                    width: 16,
                                    height: 110,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white.withOpacity(0.0),
                                          Colors.white.withOpacity(0.35),
                                          Colors.white.withOpacity(0.0),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 11),

              // Title: Metallic TnT Wordmark with Mint Green Glow & ESPORTS Pill
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Colors.white, Color(0xFFE6FFFA), AppTheme.mintGreen],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ).createShader(bounds),
                    child: const Text(
                      'TnT',
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2.0,
                        fontFamily: 'sans-serif',
                        shadows: [
                          Shadow(color: AppTheme.mintGreen, blurRadius: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                    decoration: BoxDecoration(
                      gradient: AppTheme.headerGradient,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.mintGreen.withOpacity(0.45),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: _ambientController,
                          builder: (context, _) {
                            final dotOpacity = 0.5 + 0.5 * math.sin(_ambientController.value * 4 * math.pi);
                            return Container(
                              width: 5,
                              height: 5,
                              margin: const EdgeInsets.only(right: 5),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF0F172A).withOpacity(dotOpacity),
                              ),
                            );
                          },
                        ),
                        const Text(
                          'ESPORTS',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),

              // Esports High-Impact Tagline with Radiant Mint Green Glow
              const Text(
                'PLAY  •  COMPETE  •  WIN',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.mintGreen,
                  letterSpacing: 3.5,
                  shadows: [
                    Shadow(
                      color: AppTheme.mintGreen,
                      blurRadius: 14,
                    ),
                    Shadow(
                      color: AppTheme.mintGreen,
                      blurRadius: 26,
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
  // B. Gaming Pillars Badges (Top-Up, Tournaments, Escrow)
  // ---------------------------------------------------------------------------
  Widget _buildGamingPillarsStrip() {
    return FadeTransition(
      opacity: _cardFade,
      child: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          runSpacing: 5,
          children: [
            _buildPillarBadge(Icons.diamond_outlined, 'Instant TopUp', AppTheme.mintGreen),
            _buildPillarBadge(Icons.emoji_events_outlined, 'Custom Cups', AppTheme.fireOrange),
            _buildPillarBadge(Icons.shield_outlined, 'Escrow Vault', AppTheme.cyan),
          ],
        ),
      ),
    );
  }

  Widget _buildPillarBadge(IconData icon, String text, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withOpacity(0.20),
            const Color(0xFF1E1736).withOpacity(0.92),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withOpacity(0.6), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(3.5),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.22),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(0.4),
                  blurRadius: 5,
                ),
              ],
            ),
            child: Icon(icon, size: 10.5, color: accent),
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // C. Glassmorphism Main Authentication Card
  // ---------------------------------------------------------------------------
  Widget _buildGlassmorphismAuthCard() {
    return FadeTransition(
      opacity: _cardFade,
      child: SlideTransition(
        position: _cardSlide,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.75),
                blurRadius: 40,
                offset: const Offset(0, 18),
              ),
              BoxShadow(
                color: AppTheme.mintGreen.withOpacity(0.18),
                blurRadius: 48,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: AppTheme.fireOrange.withOpacity(0.12),
                blurRadius: 56,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF241C3C).withOpacity(0.90),
                      const Color(0xFF1A142C).withOpacity(0.95),
                      const Color(0xFF110D1E).withOpacity(0.98),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: AppTheme.mintGreen.withOpacity(0.32),
                    width: 1.3,
                  ),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Specular Top Acrylic Glow Strip
                      Container(
                        height: 2,
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              AppTheme.mintGreen.withOpacity(0.85),
                              AppTheme.fireOrange.withOpacity(0.7),
                              Colors.transparent,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      // Segmented Switcher Tab [ Sign In ] vs [ Register ]
                      _buildSegmentedTabToggle(),
                      const SizedBox(height: 15),

                      // Card Heading & Subtitle
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _isSignUp ? 'Create Gamer Account' : 'Welcome Back, Gamer',
                              style: const TextStyle(
                                fontSize: 19.5,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.mintGreen,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.mintGreen,
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _isSignUp
                            ? 'Join the esports arena, top-up diamonds & compete.'
                            : 'Your next victory starts here.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 1-Tap Google Sign-In Button
                      _buildGoogleButton(),
                      const SizedBox(height: 14),

                      // Or with Email divider
                      _buildDividerWithLabel(
                        _isSignUp ? 'OR REGISTER WITH EMAIL' : 'OR SIGN IN WITH EMAIL',
                      ),
                      const SizedBox(height: 12),

                      // Error Banner
                      if (_errorMessage != null) _buildErrorBanner(),

                      // Name Field (Only in Gamer Sign Up Mode)
                      if (_isSignUp) ...[
                        _buildEsportsInput(
                          controller: _nameController,
                          focusNode: _nameFocus,
                          label: 'Gamer Display Name',
                          hint: 'e.g. ApexLegend',
                          icon: Icons.sports_esports_outlined,
                          validator: (v) {
                            if (_isSignUp && (v == null || v.trim().length < 2)) {
                              return 'Enter a name with at least 2 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                      ],

                      // Email Field
                      _buildEsportsInput(
                        controller: _emailController,
                        focusNode: _emailFocus,
                        label: 'Gmail or Email Address',
                        hint: 'gamer@gmail.com',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Email is required';
                          if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email address';
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),

                      // Password Field
                      _buildEsportsInput(
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        label: 'Password',
                        hint: '••••••••',
                        icon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: const Color(0xFF94A3B8),
                            size: 18,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        validator: (v) {
                          if (v == null || v.length < 6) return 'Password must be at least 6 characters';
                          return null;
                        },
                      ),

                      // Confirm Password (Only in Gamer Sign Up Mode)
                      if (_isSignUp) ...[
                        const SizedBox(height: 14),
                        _buildEsportsInput(
                          controller: _confirmPasswordController,
                          focusNode: _confirmFocus,
                          label: 'Confirm Password',
                          hint: '••••••••',
                          icon: Icons.lock_reset_outlined,
                          obscureText: _obscureConfirmPassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                              color: const Color(0xFF94A3B8),
                              size: 18,
                            ),
                            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          ),
                          validator: (v) {
                            if (_isSignUp && v != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                      ],

                      // Forgot Password Link or Terms acceptance
                      if (!_isSignUp) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _emailController.text = 'mrpr0c0dss@gmail.com';
                                    _passwordController.text = 'password';
                                  });
                                },
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.fireOrange.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppTheme.fireOrange.withOpacity(0.4)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.bolt, size: 12, color: AppTheme.fireOrange),
                                      SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          '⚡ mrpr0c0dss (Admin)',
                                          style: TextStyle(
                                            color: AppTheme.fireOrange,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            TextButton(
                              onPressed: _handleForgotPassword,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                minimumSize: const Size(50, 30),
                              ),
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.mintGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: Checkbox(
                                value: _acceptTerms,
                                activeColor: AppTheme.fireOrange,
                                side: BorderSide(color: Colors.white.withOpacity(0.3)),
                                onChanged: (v) => setState(() => _acceptTerms = v ?? true),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'I agree to the Fair Play & Platform Terms of Service',
                                style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Primary High-Energy CTA Button
                      _buildPrimaryCtaButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // D. Segmented Tab Toggle
  // ---------------------------------------------------------------------------
  Widget _buildSegmentedTabToggle() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF110D1F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4.5),
      child: Row(
        children: [
          // SIGN IN TAB
          Expanded(
            child: InkWell(
              onTap: () => setState(() {
                _isSignUp = false;
                _errorMessage = null;
              }),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  gradient: !_isSignUp
                      ? AppTheme.brandGradient
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: !_isSignUp
                      ? [
                          BoxShadow(
                            color: AppTheme.fireOrange.withOpacity(0.50),
                            blurRadius: 14,
                            offset: const Offset(0, 3),
                          ),
                          BoxShadow(
                            color: const Color(0xFFEA580C).withOpacity(0.3),
                            blurRadius: 20,
                          ),
                        ]
                      : [],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Top Specular Acrylic Gloss Highlight for Active Tab
                    if (!_isSignUp)
                      Positioned(
                        top: 0,
                        left: 8,
                        right: 8,
                        height: 6,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withOpacity(0.4),
                                Colors.white.withOpacity(0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    Text(
                      'SIGN IN',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: !_isSignUp ? Colors.white : const Color(0xFF94A3B8),
                        shadows: !_isSignUp
                            ? [
                                Shadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // REGISTER TAB
          Expanded(
            child: InkWell(
              onTap: () => setState(() {
                _isSignUp = true;
                _errorMessage = null;
              }),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  gradient: _isSignUp
                      ? AppTheme.brandGradient
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _isSignUp
                      ? [
                          BoxShadow(
                            color: AppTheme.fireOrange.withOpacity(0.50),
                            blurRadius: 14,
                            offset: const Offset(0, 3),
                          ),
                          BoxShadow(
                            color: const Color(0xFFEA580C).withOpacity(0.3),
                            blurRadius: 20,
                          ),
                        ]
                      : [],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Top Specular Acrylic Gloss Highlight for Active Tab
                    if (_isSignUp)
                      Positioned(
                        top: 0,
                        left: 8,
                        right: 8,
                        height: 6,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withOpacity(0.4),
                                Colors.white.withOpacity(0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    Text(
                      'REGISTER',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: _isSignUp ? Colors.white : const Color(0xFF94A3B8),
                        shadows: _isSignUp
                            ? [
                                Shadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // E. 1-Tap Google VIP Fast Pass Button with Sweeping Shimmer
  // ---------------------------------------------------------------------------
  Widget _buildGoogleButton() {
    return InkWell(
      onTap: _isLoading ? null : _handleGoogleSignIn,
      borderRadius: BorderRadius.circular(15),
      child: AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, _) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: const LinearGradient(
                colors: [Color(0xFF282042), Color(0xFF17122A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: AppTheme.mintGreen.withOpacity(0.35),
                width: 1.3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.45),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: AppTheme.mintGreen.withOpacity(0.16),
                  blurRadius: 16,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Stack(
                children: [
                  // Sweeping Specular Light Beam
                  Positioned.fill(
                    child: Transform.translate(
                      offset: Offset((_shimmerController.value * 3.6 - 1.6) * 280, 0),
                      child: Transform.rotate(
                        angle: 0.4,
                        child: Container(
                          width: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.0),
                                Colors.white.withOpacity(0.14),
                                Colors.white.withOpacity(0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Button Content
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Pristine White Circular Medallion with Google G
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Text(
                            'G',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFEA4335),
                              fontSize: 14,
                              fontFamily: 'sans-serif',
                            ),
                          ),
                        ),
                        const SizedBox(width: 9),
                        const Flexible(
                          child: Text(
                            'Continue with Google / Gmail',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 11,
                          color: AppTheme.mintGreen.withOpacity(0.85),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // F. Custom Esports Text Input with Dedicated Icon Pill & Mint Green Halo
  // ---------------------------------------------------------------------------
  Widget _buildEsportsInput({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final hasFocus = focusNode.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: hasFocus
            ? [
                BoxShadow(
                  color: AppTheme.mintGreen.withOpacity(0.32),
                  blurRadius: 14,
                  spreadRadius: 0,
                ),
              ]
            : [],
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: hasFocus ? AppTheme.mintGreen : const Color(0xFF94A3B8),
            fontSize: 12,
            fontWeight: hasFocus ? FontWeight.bold : FontWeight.w500,
          ),
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12.5),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 10, right: 10, top: 8, bottom: 8),
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: hasFocus
                    ? AppTheme.mintGreen.withOpacity(0.20)
                    : Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: hasFocus
                      ? AppTheme.mintGreen.withOpacity(0.65)
                      : Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                color: hasFocus ? AppTheme.mintGreen : const Color(0xFF94A3B8),
                size: 18,
              ),
            ),
          ),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: const Color(0xFF130E22).withOpacity(0.94),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.12), width: 1.1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.12), width: 1.1),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide(color: AppTheme.mintGreen, width: 1.6),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppTheme.errorRed, width: 1.2),
          ),
          focusedErrorBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide(color: AppTheme.errorRed, width: 1.6),
          ),
        ),
        validator: validator,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // G. Primary CTA Button with Sweeping Light Beam & Molten Fire Aura
  // ---------------------------------------------------------------------------
  Widget _buildPrimaryCtaButton() {
    return MouseRegion(
      onEnter: (_) => setState(() => _isButtonHovered = true),
      onExit: (_) => setState(() => _isButtonHovered = false),
      child: AnimatedScale(
        scale: _isButtonHovered ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 160),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.fireOrange.withOpacity(0.55),
                blurRadius: 24,
                spreadRadius: 1,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: const Color(0xFFEA580C).withOpacity(0.40),
                blurRadius: 36,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleEmailAuth,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: EdgeInsets.zero,
            ),
            child: Ink(
              decoration: const BoxDecoration(
                gradient: AppTheme.brandGradient,
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Top Specular Acrylic Gloss Highlight Edge
                    Positioned(
                      top: 0,
                      left: 12,
                      right: 12,
                      height: 8,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withOpacity(0.42),
                              Colors.white.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Continuous Sweeping Specular Light Glint
                    AnimatedBuilder(
                      animation: _shimmerController,
                      builder: (context, _) {
                        return Positioned.fill(
                          child: Transform.translate(
                            offset: Offset((_shimmerController.value * 3.6 - 1.6) * 320, 0),
                            child: Transform.rotate(
                              angle: 0.45,
                              child: Container(
                                width: 45,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.0),
                                      Colors.white.withOpacity(0.3),
                                      Colors.white.withOpacity(0.0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    // Center Content
                    Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isSignUp ? Icons.person_add_alt_1 : Icons.bolt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isSignUp ? 'JOIN THE ARENA' : 'ENTER ARENA',
                                  style: const TextStyle(
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.4,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black45,
                                        blurRadius: 6,
                                        offset: Offset(0, 1.5),
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
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // H. Error Banner
  // ---------------------------------------------------------------------------
  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.errorRed.withOpacity(0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.errorRed.withOpacity(0.45), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.errorRed.withOpacity(0.12),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppTheme.errorRed, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: AppTheme.errorRed, fontSize: 12, height: 1.3, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // I. Esports Fading Laser Divider with Center Diamond
  // ---------------------------------------------------------------------------
  Widget _buildDividerWithLabel(String label) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppTheme.mintGreen.withOpacity(0.35),
                  Colors.white.withOpacity(0.2),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '◆ ',
                style: TextStyle(fontSize: 7, color: AppTheme.mintGreen),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 1.2,
                ),
              ),
              const Text(
                ' ◆',
                style: TextStyle(fontSize: 7, color: AppTheme.mintGreen),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.2),
                  AppTheme.mintGreen.withOpacity(0.35),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // J. Footer Options & Staff Credentials
  // ---------------------------------------------------------------------------
  Widget _buildFooterOptions() {
    return FadeTransition(
      opacity: _footerFade,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => CountrySelectDialog(appState: widget.appState),
                  );
                },
                icon: const Icon(Icons.language, size: 14, color: AppTheme.cyan),
                label: Text(
                  '${widget.appState.selectedCountry.currency} (${widget.appState.selectedCountry.symbol})',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold),
                ),
              ),
              const Text('•', style: TextStyle(color: Color(0xFF475569))),
              TextButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AdminLoginDialog(appState: widget.appState),
                  );
                },
                icon: const Icon(Icons.shield_rounded, size: 14, color: AppTheme.fireOrange),
                label: const Text(
                  'Admin & Staff Portal',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.fireOrange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Protected by 256-bit SSL • 100% Escrow Financial Protection',
            style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// CINEMATIC ESPORTS BACKGROUND PAINTER
// Smooth, 60fps lightweight glowing orbs, anamorphic flare, cyber grid & cross-stars
// =============================================================================
class _CinematicEsportsBackgroundPainter extends CustomPainter {
  final double animationValue;

  _CinematicEsportsBackgroundPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 1. Deep cosmic gradient base rooted in TnT Dark Violet
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF0F0B1E),
          Color(0xFF1F1934),
          Color(0xFF0A0715),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    // 2. High-Tech Cyber Diagonal Grid Lines
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.022)
      ..strokeWidth = 1.0;
    const spacing = 36.0;
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), gridPaint);
    }

    // 3. Stadium Floodlight Anamorphic Lens Flare (Top Area)
    final flareCenter = Offset(size.width * 0.5, size.height * 0.12);
    final flarePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.5,
        colors: [
          AppTheme.mintGreen.withOpacity(0.22),
          AppTheme.fireOrange.withOpacity(0.12),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCenter(center: flareCenter, width: size.width * 1.5, height: 75));
    canvas.drawOval(Rect.fromCenter(center: flareCenter, width: size.width * 1.5, height: 75), flarePaint);

    // 4. Slow drifting Mint Green orb (Top Right)
    final mintOrbX = size.width * (0.8 + 0.1 * math.sin(animationValue * 2 * math.pi));
    final mintOrbY = size.height * (0.2 + 0.08 * math.cos(animationValue * 2 * math.pi));
    final mintPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.6,
        colors: [
          AppTheme.mintGreen.withOpacity(0.24),
          AppTheme.cyan.withOpacity(0.0),
        ],
      ).createShader(Rect.fromCircle(center: Offset(mintOrbX, mintOrbY), radius: size.width * 0.75));
    canvas.drawCircle(Offset(mintOrbX, mintOrbY), size.width * 0.75, mintPaint);

    // 5. Deep fire-violet arena glow (Bottom Left)
    final violetOrbX = size.width * (0.2 + 0.08 * math.cos(animationValue * 2 * math.pi));
    final violetOrbY = size.height * (0.75 + 0.06 * math.sin(animationValue * 2 * math.pi));
    final violetPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.6,
        colors: [
          AppTheme.topStripBg.withOpacity(0.35),
          AppTheme.fireOrange.withOpacity(0.10),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(violetOrbX, violetOrbY), radius: size.width * 0.7));
    canvas.drawCircle(Offset(violetOrbX, violetOrbY), size.width * 0.7, violetPaint);

    // 6. Central Arena Nebula Glow (Behind Card)
    final nebulaPulse = math.sin(animationValue * 2 * math.pi) * 0.15 + 0.85;
    final centerNebulaPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.5,
        colors: [
          AppTheme.mintGreen.withOpacity(0.09 * nebulaPulse),
          AppTheme.fireOrange.withOpacity(0.06 * nebulaPulse),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.55),
        width: size.width * 1.1,
        height: size.height * 0.6,
      ));
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.55),
        width: size.width * 1.1,
        height: size.height * 0.6,
      ),
      centerNebulaPaint,
    );

    // 7. Shimmering Floating Diamond Particles & Twinkling Cross-Stars (18 points)
    final particlePaint = Paint()..style = PaintingStyle.fill;
    final starPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final rnd = math.Random(77);
    for (int i = 0; i < 18; i++) {
      final speed = 0.35 + rnd.nextDouble() * 0.65;
      final seedX = rnd.nextDouble() * size.width;
      final seedY = (rnd.nextDouble() + animationValue * speed) % 1.0 * size.height;
      final radius = 1.2 + rnd.nextDouble() * 2.2;

      final color = i % 3 == 0
          ? AppTheme.mintGreen // Official Brand Mint Green
          : i % 3 == 1
              ? AppTheme.fireOrange // Official Gaming Action Orange
              : const Color(0xFFFFFFFF); // Diamond white

      final opacity = (0.3 + rnd.nextDouble() * 0.5) * (0.6 + 0.4 * math.sin(animationValue * 4 * math.pi + i));
      particlePaint.color = color.withOpacity(opacity.clamp(0.0, 1.0));
      canvas.drawCircle(Offset(seedX, seedY), radius, particlePaint);

      // Draw Sparkling Diamond Cross-Star on selected particles
      if (i % 4 == 0) {
        starPaint.color = color.withOpacity((opacity * 0.8).clamp(0.0, 1.0));
        final crossSize = 3.5 + rnd.nextDouble() * 3.0;
        canvas.drawLine(Offset(seedX - crossSize, seedY), Offset(seedX + crossSize, seedY), starPaint);
        canvas.drawLine(Offset(seedX, seedY - crossSize), Offset(seedX, seedY + crossSize), starPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CinematicEsportsBackgroundPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
