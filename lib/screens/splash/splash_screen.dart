import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../routing/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/dimi_blob_background.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Timing spec (all values in fractions of a 3 200 ms controller)
//
//  0 ms       Background cream appears instantly (Scaffold bg color).
//  0–250 ms   Logo: opacity 0→1, scale 0.92→1.00  [0.000–0.078]
//  250–650 ms Logo scale eases to final 1.00       [0.078–0.203]
//  450–850 ms DIMI wordmark fades in               [0.141–0.266]
//  550–900 ms Subtitle fades in                    [0.172–0.281]
//  700–1200 ms Loading bar expands 0→38%           [0.219–0.375]
//  Throughout  Blobs drift ±12 px over 18 s (separate controller)
//  Exit phase  2 200–2 550 ms: logo+text opacity 1→0, scale 1.0→1.04,
//              background opacity 1→0             [0.688–0.797]
// ─────────────────────────────────────────────────────────────────────────────

const _kTotalMs = 3200;

// Entrance
const _kLogoFadeIn = Interval(0.000, 0.078, curve: Curves.easeOut);
const _kLogoScale = Interval(0.000, 0.203, curve: Curves.easeOutCubic);
const _kDimiFade = Interval(0.141, 0.266, curve: Curves.easeOut);
const _kSubFade = Interval(0.172, 0.294, curve: Curves.easeOut);
const _kBarReveal = Interval(0.219, 0.640, curve: Curves.easeInOut);

// Exit
const _kExitContent = Interval(0.688, 0.797, curve: Curves.easeIn);
const _kExitBg = Interval(0.719, 0.828, curve: Curves.easeIn);

/// DIMI premium splash screen.
///
/// Five independent animation layers:
///   1. Background (cream) — static, instant.
///   2. Blob layer — extremely slow ambient drift (separate controller).
///   3. Logo — fade in + scale 0.92→1.00.
///   4. Text (DIMI + subtitle) — fade in with slight stagger.
///   5. Loading bar — gradient reveal 0→38%.
///
/// Exit: logo+text scale up 1.00→1.04 + fade to zero, then background fades,
/// then navigate.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Main sequence controller
  late final AnimationController _seq;

  // Blob ambient drift (very slow, looping)
  late final AnimationController _drift;

  // ── Entrance animations ──────────────────────────────────────────────────
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _dimiOpacity;
  late final Animation<double> _subOpacity;
  late final Animation<double> _barProgress; // 0.0 → 0.38

  // ── Exit animations ───────────────────────────────────────────────────────
  late final Animation<double> _exitContentOpacity; // 1 → 0
  late final Animation<double> _exitContentScale; // 1.00 → 1.04
  late final Animation<double> _exitBgOpacity; // 1 → 0

  // ── Blob drift ────────────────────────────────────────────────────────────
  late final Animation<Offset> _blobDrift;

  @override
  void initState() {
    super.initState();

    // ── Main sequence ────────────────────────────────────────────────────
    _seq = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _kTotalMs),
    )..addStatusListener(_onSeqStatus);

    _logoOpacity = CurvedAnimation(parent: _seq, curve: _kLogoFadeIn);
    _logoScale = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _seq, curve: _kLogoScale));

    _dimiOpacity = CurvedAnimation(parent: _seq, curve: _kDimiFade);
    _subOpacity = CurvedAnimation(parent: _seq, curve: _kSubFade);

    _barProgress = Tween<double>(
      begin: 0.0,
      end: 1.0, // fills completely before exit begins
    ).animate(CurvedAnimation(parent: _seq, curve: _kBarReveal));

    // Exit: content fades+scales out
    _exitContentOpacity = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _seq, curve: _kExitContent));
    _exitContentScale = Tween<double>(
      begin: 1.0,
      end: 1.04,
    ).animate(CurvedAnimation(parent: _seq, curve: _kExitContent));
    _exitBgOpacity = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _seq, curve: _kExitBg));

    // ── Blob drift — 18-second looping, tiny movement ────────────────────
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat(reverse: true);

    // Drift range: ±12 px horizontal, ±8 px vertical — imperceptible
    _blobDrift = Tween<Offset>(
      begin: const Offset(-12, -8),
      end: const Offset(12, 8),
    ).animate(CurvedAnimation(parent: _drift, curve: Curves.easeInOut));

    _seq.forward();
  }

  void _onSeqStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      context.go(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _seq
      ..removeStatusListener(_onSeqStatus)
      ..dispose();
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reducedMotion && !_seq.isAnimating) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(AppRoutes.login);
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAF3EB),
      body: RepaintBoundary(
        child: AnimatedBuilder(
          // Listen to both controllers in one builder.
          animation: Listenable.merge([_seq, _drift]),
          builder: (context, _) {
            return Stack(
              fit: StackFit.expand,
              children: [
                // ── Layer 1: Background blobs (slow drift) ────────────
                Opacity(
                  opacity: _exitBgOpacity.value,
                  child: DimiBlobBackground(
                    blobDrift: reducedMotion ? Offset.zero : _blobDrift.value,
                  ),
                ),

                // ── Layer 2: Content (logo + text + bar) ──────────────
                Opacity(
                  opacity: _exitContentOpacity.value,
                  child: Transform.scale(
                    scale: _exitContentScale.value,
                    child: _SplashContent(
                      logoOpacity: _logoOpacity.value,
                      logoScale: _logoScale.value,
                      dimiOpacity: _dimiOpacity.value,
                      subOpacity: _subOpacity.value,
                      barProgress: _barProgress.value,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Content layer
// ─────────────────────────────────────────────────────────────────────────────

class _SplashContent extends StatelessWidget {
  const _SplashContent({
    required this.logoOpacity,
    required this.logoScale,
    required this.dimiOpacity,
    required this.subOpacity,
    required this.barProgress,
  });

  final double logoOpacity;
  final double logoScale;
  final double dimiOpacity;
  final double subOpacity;
  final double barProgress;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final h = box.maxHeight;

        // Logo: 44 % of width, kept square, generous but never cropped.
        final logoSize = (w * 0.44).clamp(130.0, 220.0);

        return SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Shift the whole composition slightly above mathematical
              // centre for a more premium, spacious feel.
              SizedBox(height: h * 0.02),

              // ── Logo ────────────────────────────────────────────────
              Opacity(
                opacity: logoOpacity,
                child: Transform.scale(
                  scale: logoScale,
                  child: Image.asset(
                    'assets/logos/dimi_splash_logo.png',
                    width: logoSize,
                    height: logoSize,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),

              // Logo → text gap: tight so they read as one unit
              const SizedBox(height: 20),

              // ── DIMI wordmark ────────────────────────────────────────
              Opacity(
                opacity: dimiOpacity,
                child: const Text(
                  'DIMI',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.5,
                    height: 1.0,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ── Subtitle ─────────────────────────────────────────────
              Opacity(
                opacity: subOpacity,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Digital Interface For Monitoring and Improvement',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── Loading bar ───────────────────────────────────────────
              Opacity(
                opacity: subOpacity, // appear with subtitle
                child: _LoadingBar(progress: barProgress),
              ),

              SizedBox(height: h * 0.06),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading bar — thin, rounded, orange-to-amber gradient reveal
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingBar extends StatelessWidget {
  const _LoadingBar({required this.progress});

  /// 0.0 → 1.0 — fraction of the track that is filled.
  final double progress;

  static const double _trackW = 160.0;
  static const double _trackH = 3.0;
  static const double _radius = 999.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _trackW,
      height: _trackH,
      child: Stack(
        children: [
          // Track
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFE8DFCF),
              borderRadius: BorderRadius.circular(_radius),
            ),
          ),
          // Filled portion
          FractionallySizedBox(
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_radius),
                gradient: const LinearGradient(
                  colors: [Color(0xFFF5A623), Color(0xFFFFD166)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
