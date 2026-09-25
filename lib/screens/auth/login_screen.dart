import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../config/supabase_config.dart';
import '../../routing/app_router.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/dimi_blob_background.dart';

class DimiWelcomeScreen extends StatefulWidget {
  const DimiWelcomeScreen({super.key});
  @override
  State<DimiWelcomeScreen> createState() => _DimiWelcomeScreenState();
}

class LoginScreen extends DimiWelcomeScreen {
  const LoginScreen({super.key});
}

class _DimiWelcomeScreenState extends State<DimiWelcomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _entrance;
  late final AnimationController _float;
  bool _loading = false;
  String? _error;
  bool _awaitingOAuthReturn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _entrance.dispose();
    _float.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _awaitingOAuthReturn) {
      _awaitingOAuthReturn = false;
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        if (_loading) {
          setState(() {
            _loading = false;
            _error = 'Sign-in cancelled. Try again or continue offline.';
          });
        }
      });
    }
  }

  Future<void> _handleGoogle() async {
    if (!SupabaseConfig.isConfigured) {
      setState(
        () => _error =
            'Google sign-in is unavailable. Use "Continue offline" to proceed.',
      );
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      SupabaseBootstrap.offlineMode = false;
      await AuthService.instance.signInWithGoogle();
      if (mounted) setState(() => _awaitingOAuthReturn = true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _awaitingOAuthReturn = false;
        _error = 'Sign-in failed. Please try again.';
      });
    }
  }

  void _handleOffline() {
    SupabaseBootstrap.offlineMode = true;
    if (mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final entrance = reduceMotion
        ? const AlwaysStoppedAnimation<double>(1.0)
        : _entrance;
    final float = reduceMotion
        ? const AlwaysStoppedAnimation<double>(0.5)
        : _float;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF3EB),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DimiBlobBackground(),
          SafeArea(
            child: AnimatedBuilder(
              animation: Listenable.merge([entrance, float]),
              builder: (context, _) => Column(
                children: [
                  // Upper 62 % — orbit + logo + DIMI
                  Expanded(
                    flex: 62,
                    child: _OrbitArea(entrance: entrance, floatT: float.value),
                  ),
                  // Lower 38 % — buttons
                  Expanded(
                    flex: 38,
                    child: _ButtonsArea(
                      entrance: entrance,
                      loading: _loading,
                      error: _error,
                      onGoogle: _handleGoogle,
                      onOffline: _handleOffline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  ORBIT AREA
//  Strategy: compute a single ring centre & radius from the available box,
//  then place EVERYTHING (ring, logo, DIMI, cards) relative to that point.
//  This guarantees the logo is always perfectly centred inside the ring.
// ═════════════════════════════════════════════════════════════════════════════

// Card definitions — angle uses SCREEN convention:
//   0° = right, 90° = down, 180° = left, 270° = up  (clockwise from right)
// tiltDeg: rotation of the card widget itself.
class _CardDef {
  const _CardDef({
    required this.icon,
    required this.color,
    required this.angleDeg,
    required this.tiltDeg,
  });
  final IconData icon;
  final Color color;
  final double angleDeg;
  final double tiltDeg;
}

// Measured from the reference image:
//   Calendar  ≈ upper-left   (225°)   tilts −12°
//   Bell      ≈ upper-right  (315°)   tilts +12°
//   Wallet    ≈ middle-left  (185°)   tilts −8°
//   Check     ≈ middle-right (355°)   tilts +8°
const _kCards = [
  _CardDef(
    icon: Icons.calendar_month_outlined,
    color: AppColors.info,
    angleDeg: 225,
    tiltDeg: -12,
  ),
  _CardDef(
    icon: Icons.notifications_none_rounded,
    color: AppColors.accent,
    angleDeg: 315,
    tiltDeg: 12,
  ),
  _CardDef(
    icon: Icons.account_balance_wallet_outlined,
    color: AppColors.danger,
    angleDeg: 185,
    tiltDeg: -8,
  ),
  _CardDef(
    icon: Icons.check_rounded,
    color: AppColors.success,
    angleDeg: 355,
    tiltDeg: 8,
  ),
];

class _OrbitArea extends StatelessWidget {
  const _OrbitArea({required this.entrance, required this.floatT});
  final Animation<double> entrance;
  final double floatT; // 0→1 looping, used for card float

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final h = box.maxHeight;

        // ── Ring geometry ───────────────────────────────────────────────
        // True circle: radius = 39% of screen width.
        // The ring must fit inside the available height with comfortable margin.
        final r = math.min(w * 0.39, h * 0.42);

        // Ring centre: horizontally centred; vertically placed so the ring
        // occupies the middle of the available space with the logo above the
        // ring centre and DIMI below.
        // Reference: ring centre sits at ~45% from top of orbit area.
        final cx = w / 2;
        final cy = h * 0.45;

        // Logo size: ~80% of ring diameter, clamped
        final logoSize = (r * 1.10).clamp(100.0, 160.0);

        // Slow bob: each card moves ±4 px, staggered by index
        final bob = math.sin(floatT * math.pi * 2) * 4;

        final cardFade = CurvedAnimation(
          parent: entrance,
          curve: const Interval(0.15, 0.72, curve: Curves.easeOut),
        );

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // ── 1. Ring + dots ──────────────────────────────────────────
            Positioned.fill(
              child: CustomPaint(
                painter: _RingPainter(cx: cx, cy: cy, r: r),
              ),
            ),

            // ── 2. Logo — centred on ring centre, shifted up ────────────
            // Logo centre should be at  cy - logoSize*0.20
            // so the logo occupies upper half and DIMI the lower half.
            Positioned(
              left: cx - logoSize / 2,
              top: cy - logoSize * 0.72, // push logo above ring centre
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.88, end: 1.0).animate(
                  CurvedAnimation(
                    parent: entrance,
                    curve: const Interval(
                      0.05,
                      0.55,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                ),
                child: Image.asset(
                  'assets/logos/dimi_splash_logo.png',
                  width: logoSize,
                  height: logoSize,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),

            // ── 3. DIMI text + amber bar — just below logo ──────────────
            // Top of text block at cy + logoSize * 0.28
            Positioned(
              left: 0,
              right: 0,
              top: cy + logoSize * 0.28,
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: entrance,
                  curve: const Interval(0.30, 0.80, curve: Curves.easeOut),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'DIMI',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.5,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Center(
                      child: Container(
                        width: 38,
                        height: 3,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(99),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF5A623), Color(0xFFFFD166)],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── 4. Icon cards ───────────────────────────────────────────
            for (int i = 0; i < _kCards.length; i++)
              _buildCard(
                card: _kCards[i],
                cx: cx,
                cy: cy,
                r: r,
                floatOffset: bob * (i.isEven ? 1.0 : -1.0),
                fade: cardFade,
              ),
          ],
        );
      },
    );
  }

  Widget _buildCard({
    required _CardDef card,
    required double cx,
    required double cy,
    required double r,
    required double floatOffset,
    required Animation<double> fade,
  }) {
    final rad = card.angleDeg * math.pi / 180;
    // Card centre on the ring
    final cardCx = cx + r * math.cos(rad);
    final cardCy = cy + r * math.sin(rad) + floatOffset;
    const s = 52.0;

    return Positioned(
      left: cardCx - s / 2,
      top: cardCy - s / 2,
      child: FadeTransition(
        opacity: fade,
        child: Transform.rotate(
          angle: card.tiltDeg * math.pi / 180,
          child: _FeatureCard(icon: card.icon, color: card.color),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 52,
    height: 52,
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(15),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Icon(icon, color: color, size: 24),
  );
}

/// True-circle ring + amber dots at 12 and 6 o'clock.
class _RingPainter extends CustomPainter {
  const _RingPainter({required this.cx, required this.cy, required this.r});
  final double cx, cy, r;

  @override
  void paint(Canvas canvas, Size size) {
    // Ring stroke
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..color = const Color(0xFFF5A623).withValues(alpha: 0.40)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    // Amber dot — top (12 o'clock)
    canvas.drawCircle(
      Offset(cx, cy - r),
      5.5,
      Paint()..color = const Color(0xFFF5A623),
    );
    // Amber dot — bottom (6 o'clock)
    canvas.drawCircle(
      Offset(cx, cy + r),
      5.5,
      Paint()..color = const Color(0xFFF5A623),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.cx != cx || old.cy != cy || old.r != r;
}

// ═════════════════════════════════════════════════════════════════════════════
//  BUTTONS AREA
// ═════════════════════════════════════════════════════════════════════════════

class _ButtonsArea extends StatelessWidget {
  const _ButtonsArea({
    required this.entrance,
    required this.loading,
    required this.error,
    required this.onGoogle,
    required this.onOffline,
  });
  final Animation<double> entrance;
  final bool loading;
  final String? error;
  final Future<void> Function() onGoogle;
  final VoidCallback onOffline;

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(
      parent: entrance,
      curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
    );
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.14),
          end: Offset.zero,
        ).animate(fade),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (error != null) ...[
                _AuthError(message: error!),
                const SizedBox(height: 10),
              ],
              // Google — filled white, full width
              _PressButton(
                onPressed: loading ? null : onGoogle,
                child: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textPrimary,
                        ),
                      )
                    : _BtnRow(
                        leading: SvgPicture.asset(
                          'assets/google_g_logo.svg',
                          width: 21,
                          height: 21,
                        ),
                        label: 'Continue with Google',
                      ),
              ),
              // OR divider
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
              ),
              // Offline — outlined, full width
              _PressButton(
                outlined: true,
                onPressed: loading ? null : () async => onOffline(),
                child: const _BtnRow(
                  leading: Icon(
                    Icons.signal_wifi_off_outlined,
                    size: 20,
                    color: AppColors.textPrimary,
                  ),
                  label: 'Continue offline',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-width pill with a spring press animation:
///   down  → 100 ms scale 1.00→0.96, shadow collapses
///   up    → 200 ms spring back, then fires callback
class _PressButton extends StatefulWidget {
  const _PressButton({
    required this.child,
    required this.onPressed,
    this.outlined = false,
  });
  final Widget child;
  final Future<void> Function()? onPressed;
  final bool outlined;

  @override
  State<_PressButton> createState() => _PressButtonState();
}

class _PressButtonState extends State<_PressButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double> _scale;
  late final Animation<double> _elevation;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _press, curve: Curves.easeIn));
    _elevation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _press, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  void _down() {
    if (widget.onPressed != null) _press.forward();
  }

  void _up() {
    _press.reverse().then((_) {
      widget.onPressed?.call();
    });
  }

  void _cancel() {
    _press.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => _down() : null,
      onTapUp: enabled ? (_) => _up() : null,
      onTapCancel: _cancel,
      child: AnimatedBuilder(
        animation: _press,
        builder: (_, child) => Transform.scale(
          scale: _scale.value,
          child: Container(
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              color: widget.outlined ? Colors.transparent : AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
              border: Border.all(
                color: widget.outlined
                    ? AppColors.textSecondary.withValues(alpha: 0.28)
                    : AppColors.divider,
                width: 1.2,
              ),
              boxShadow: widget.outlined
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: 0.09 * _elevation.value,
                        ),
                        blurRadius: 16 * _elevation.value,
                        offset: Offset(0, 5 * _elevation.value),
                      ),
                    ],
            ),
            child: Center(child: child),
          ),
        ),
        child: DefaultTextStyle(
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Left icon · centred text · right arrow — matches reference exactly.
class _BtnRow extends StatelessWidget {
  const _BtnRow({required this.leading, required this.label});
  final Widget leading;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const SizedBox(width: 20),
      leading,
      Expanded(
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      const Icon(
        Icons.arrow_forward_rounded,
        size: 18,
        color: AppColors.textPrimary,
      ),
      const SizedBox(width: 20),
    ],
  );
}

class _AuthError extends StatelessWidget {
  const _AuthError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.danger.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.danger.withValues(alpha: 0.20)),
    ),
    child: Text(
      message,
      textAlign: TextAlign.center,
      style: AppTextStyles.caption(context).copyWith(color: AppColors.danger),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Public re-exports — keep router / other files compiling
// ─────────────────────────────────────────────────────────────────────────────

class DimiBrand extends StatelessWidget {
  const DimiBrand({super.key, required this.logoSize, required this.scale});
  final double logoSize;
  final Animation<double> scale;

  @override
  Widget build(BuildContext context) => ScaleTransition(
    scale: scale,
    child: Image.asset(
      'assets/logos/dimi_splash_logo.png',
      width: logoSize,
      height: logoSize,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    ),
  );
}

class WelcomeCopy extends StatelessWidget {
  const WelcomeCopy({super.key, required this.animation});
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.30, 0.78, curve: Curves.easeOut),
    );
    return FadeTransition(
      opacity: fade,
      child: Column(
        children: [
          const Text(
            'DIMI',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Plan, track, manage and grow,\nall in one place.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body(context).copyWith(
              fontSize: 14,
              height: 1.55,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class AuthenticationActions extends StatelessWidget {
  const AuthenticationActions({
    super.key,
    required this.animation,
    required this.loading,
    required this.error,
    required this.onGoogle,
    required this.onOffline,
  });
  final Animation<double> animation;
  final bool loading;
  final String? error;
  final Future<void> Function() onGoogle;
  final VoidCallback onOffline;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
