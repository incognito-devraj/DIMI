import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../config/supabase_config.dart';
import '../../routing/app_router.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

/// DIMI's lightweight authentication welcome. It reuses the app's design
/// tokens instead of introducing a separate auth-specific visual system.
class DimiWelcomeScreen extends StatefulWidget {
  const DimiWelcomeScreen({super.key});

  @override
  State<DimiWelcomeScreen> createState() => _DimiWelcomeScreenState();
}

/// Preserves the public screen name used by the router.
class LoginScreen extends DimiWelcomeScreen {
  const LoginScreen({super.key});
}

class _DimiWelcomeScreenState extends State<DimiWelcomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _entrance;
  late final AnimationController _environment;
  bool _loading = false;
  String? _error;
  // Tracks whether we've launched the OAuth browser so we can reset the
  // spinner if the user comes back without completing sign-in.
  bool _awaitingOAuthReturn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _environment = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _entrance.dispose();
    _environment.dispose();
    super.dispose();
  }

  /// Called when the app returns to the foreground (e.g. user pressed Back
  /// from the OAuth browser without completing sign-in).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _awaitingOAuthReturn) {
      _awaitingOAuthReturn = false;
      // Give Supabase a short window to process the deep-link callback
      // before deciding whether to reset the spinner.
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        // If still on this screen (no redirect happened), the user cancelled.
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
      // signInWithOAuth launches the browser and returns immediately.
      // The router redirect fires when the deep-link callback comes back.
      // Mark that we're waiting so didChangeAppLifecycleState can clean up
      // if the user cancels in the browser.
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
    // Navigate unconditionally — the router allows /home when offlineMode is set.
    if (mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final entrance = reduceMotion
        ? const AlwaysStoppedAnimation<double>(1)
        : _entrance;
    final environment = reduceMotion
        ? const AlwaysStoppedAnimation<double>(0)
        : _environment;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 650;
            return Stack(
              fit: StackFit.expand,
              children: [
                BackgroundLayers(animation: entrance),
                FloatingFeatureElements(animation: environment),
                FadeTransition(
                  opacity: CurvedAnimation(
                    parent: entrance,
                    curve: const Interval(.05, .62, curve: Curves.easeOut),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenHorizontal,
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: compact ? 16 : 34),
                        const Spacer(flex: 2),
                        DimiBrand(
                          logoSize: compact ? 88 : 108,
                          scale: Tween<double>(begin: .96, end: 1).animate(
                            CurvedAnimation(
                              parent: entrance,
                              curve: const Interval(
                                .18,
                                .68,
                                curve: Curves.easeOutCubic,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: compact ? 14 : 20),
                        WelcomeCopy(animation: entrance),
                        const Spacer(flex: 3),
                        AuthenticationActions(
                          animation: entrance,
                          loading: _loading,
                          error: _error,
                          onGoogle: _handleGoogle,
                          onOffline: _handleOffline,
                        ),
                        SizedBox(height: compact ? 8 : 18),
                      ],
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

class BackgroundLayers extends StatelessWidget {
  const BackgroundLayers({super.key, required this.animation});
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: FadeTransition(
      opacity: animation,
      child: Stack(
        children: [
          // Soft, oversized tonal surfaces keep the screen dimensional
          // without turning the background into an illustration.
          const Positioned(
            top: -210,
            left: -160,
            child: _AmbientBlob(
              size: Size(480, 420),
              colors: [Color(0x54FCE6BE), Color(0x00F4EFE3)],
            ),
          ),
          const Positioned(
            right: -180,
            bottom: -155,
            child: _AmbientBlob(
              size: Size(470, 390),
              colors: [Color(0x38FCE6BE), Color(0x00F4EFE3)],
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-.75, -.9),
                radius: 1.15,
                colors: [Color(0x26F5A623), Colors.transparent],
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(.9, .82),
                radius: 1.1,
                colors: [Color(0x18F5A623), Colors.transparent],
              ),
            ),
          ),
          const Align(alignment: Alignment.center, child: _OrbitLayer()),
        ],
      ),
    ),
  );
}

class _AmbientBlob extends StatelessWidget {
  const _AmbientBlob({required this.size, required this.colors});
  final Size size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) => Container(
    width: size.width,
    height: size.height,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(size.width),
      gradient: RadialGradient(
        center: const Alignment(-.42, -.55),
        radius: 1,
        colors: colors,
      ),
    ),
  );
}

class _OrbitLayer extends StatelessWidget {
  const _OrbitLayer();

  @override
  Widget build(BuildContext context) => SizedBox.expand(
    child: LayoutBuilder(
      builder: (context, constraints) => Transform.rotate(
        angle: -.32,
        child: Stack(
          children: [
            Positioned(
              left: -constraints.maxWidth * .19,
              top: constraints.maxHeight * .15,
              child: Container(
                width: constraints.maxWidth * 1.4,
                height: constraints.maxHeight * .74,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(constraints.maxWidth),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: .42),
                  ),
                ),
              ),
            ),
            const Positioned(left: 28, top: 248, child: _OrbitDot()),
            const Positioned(right: 47, top: 146, child: _OrbitDot()),
            const Positioned(right: 26, bottom: 190, child: _OrbitDot()),
          ],
        ),
      ),
    ),
  );
}

class _OrbitDot extends StatelessWidget {
  const _OrbitDot();

  @override
  Widget build(BuildContext context) => Container(
    width: 14,
    height: 14,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      color: AppColors.accent,
    ),
  );
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.icon, required this.tint});
  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) => Container(
    width: 52,
    height: 52,
    decoration: BoxDecoration(
      color: AppColors.surface.withValues(alpha: .68),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.surface.withValues(alpha: .9)),
      boxShadow: [
        BoxShadow(
          color: AppColors.textPrimary.withValues(alpha: .035),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Icon(icon, color: tint.withValues(alpha: .6), size: 22),
  );
}

class FloatingFeatureElements extends StatelessWidget {
  const FloatingFeatureElements({super.key, required this.animation});
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: AnimatedBuilder(
      animation: animation,
      builder: (context, _) => Stack(
        children: [
          _FloatingFeature(
            alignment: const Alignment(-.92, -.42),
            offset: Offset(0, animation.value * 9),
            icon: Icons.calendar_month_outlined,
            tint: AppColors.info,
            turn: -.09,
          ),
          _FloatingFeature(
            alignment: const Alignment(.91, -.08),
            offset: Offset(0, -animation.value * 8),
            icon: Icons.check_rounded,
            tint: AppColors.success,
            turn: .08,
          ),
          _FloatingFeature(
            alignment: const Alignment(-.88, .40),
            offset: Offset(0, -animation.value * 7),
            icon: Icons.account_balance_wallet_outlined,
            tint: AppColors.danger,
            turn: .06,
          ),
          _FloatingFeature(
            alignment: const Alignment(.9, .58),
            offset: Offset(0, animation.value * 9),
            icon: Icons.notifications_none_rounded,
            tint: AppColors.accent,
            turn: -.07,
          ),
        ],
      ),
    ),
  );
}

class _FloatingFeature extends StatelessWidget {
  const _FloatingFeature({
    required this.alignment,
    required this.offset,
    required this.icon,
    required this.tint,
    required this.turn,
  });
  final Alignment alignment;
  final Offset offset;
  final IconData icon;
  final Color tint;
  final double turn;

  @override
  Widget build(BuildContext context) => Align(
    alignment: alignment,
    child: Transform.translate(
      offset: offset,
      child: Transform.rotate(
        angle: turn,
        child: Opacity(
          opacity: .42,
          child: _FeatureCard(icon: icon, tint: tint),
        ),
      ),
    ),
  );
}

class DimiBrand extends StatelessWidget {
  const DimiBrand({super.key, required this.logoSize, required this.scale});
  final double logoSize;
  final Animation<double> scale;

  @override
  Widget build(BuildContext context) => ScaleTransition(
    scale: scale,
    child: Image.asset(
      'DIMI logo/Logo_PNG.png',
      width: logoSize,
      height: logoSize,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
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
      curve: const Interval(.36, .78, curve: Curves.easeOut),
    );
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, .08),
          end: Offset.zero,
        ).animate(fade),
        child: Column(
          children: [
            Text(
              'DIMI',
              style: AppTextStyles.screenTitle(context).copyWith(
                fontSize: 27,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.4,
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
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(
      parent: animation,
      curve: const Interval(.56, 1, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, .10),
          end: Offset.zero,
        ).animate(fade),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (error != null) ...[
              _AuthError(message: error!),
              const SizedBox(height: 12),
            ],
            _PressableAuthButton(
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
                  : const Row(
                      children: [
                        SizedBox(width: 24),
                        _GoogleMark(),
                        Expanded(
                          child: Center(child: Text('Continue with Google')),
                        ),
                        Icon(Icons.arrow_forward_rounded, size: 19),
                        SizedBox(width: 18),
                      ],
                    ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 15),
              child: Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
            ),
            _PressableAuthButton(
              outlined: true,
              onPressed: loading ? null : () async => onOffline(),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.signal_wifi_off_outlined, size: 20),
                  SizedBox(width: 10),
                  Text('Continue offline'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PressableAuthButton extends StatefulWidget {
  const _PressableAuthButton({
    required this.child,
    required this.onPressed,
    this.outlined = false,
  });
  final Widget child;
  final Future<void> Function()? onPressed;
  final bool outlined;

  @override
  State<_PressableAuthButton> createState() => _PressableAuthButtonState();
}

class _PressableAuthButtonState extends State<_PressableAuthButton> {
  bool _pressed = false;

  void _down(_) {
    if (widget.onPressed != null) setState(() => _pressed = true);
  }

  void _up(_) {
    if (widget.onPressed != null) {
      setState(() => _pressed = false);
      widget.onPressed!();
    }
  }

  void _cancel() => setState(() => _pressed = false);

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _down,
      onPointerUp: _up,
      onPointerCancel: (_) => _cancel(),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeInOut,
        scale: _pressed ? 0.93 : 1.0,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 80),
          opacity: _pressed ? 0.68 : 1.0,
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              // onPressed drives enabled/disabled state only; actual call
              // is handled by Listener above so gesture isn't blocked.
              onPressed: widget.onPressed == null ? null : () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.outlined
                    ? Colors.transparent
                    : AppColors.surface,
                foregroundColor: AppColors.textPrimary,
                disabledBackgroundColor: AppColors.surface,
                elevation: 0,
                shadowColor: Colors.transparent,
                overlayColor: Colors.transparent, // we handle press visually
                side: BorderSide(
                  color: widget.outlined
                      ? AppColors.textSecondary.withValues(alpha: .45)
                      : AppColors.divider,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                ),
                textStyle: AppTextStyles.body(context)
                    .copyWith(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) =>
      SvgPicture.asset('assets/google_g_logo.svg', width: 21, height: 21);
}

class _AuthError extends StatelessWidget {
  const _AuthError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.danger.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.danger.withValues(alpha: .2)),
    ),
    child: Text(
      message,
      textAlign: TextAlign.center,
      style: AppTextStyles.caption(context).copyWith(color: AppColors.danger),
    ),
  );
}
