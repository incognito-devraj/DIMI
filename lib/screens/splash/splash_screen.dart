import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../routing/app_router.dart';
import '../../theme/app_theme.dart';

/// Lightweight startup handoff for DIMI.
///
/// This screen only owns the launch animation. The real HomeScreen is still
/// created by the router after the animation completes.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<Offset> _logoOffset;
  late final Animation<double> _dashboardOpacity;
  late final Animation<double> _dashboardScale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..addStatusListener(_onAnimationStatus);

    _logoOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.92, curve: Curves.easeInOut),
    );
    _logoScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.48, curve: Curves.easeOutCubic),
      ),
    );
    _logoOffset = Tween<Offset>(begin: Offset.zero, end: const Offset(0, -0.10))
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.56, 1.0, curve: Curves.easeInOutCubic),
          ),
        );
    _dashboardOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.62, 1.0, curve: Curves.easeOut),
    );
    _dashboardScale = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.62, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _controller.forward();
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      context.go(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _controller
      ..removeStatusListener(_onAnimationStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reducedMotion && !_controller.isAnimating) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(AppRoutes.login);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              fit: StackFit.expand,
              children: [
                _DashboardEcho(
                  opacity: _dashboardOpacity.value,
                  scale: _dashboardScale.value,
                ),
                Center(
                  child: FractionalTranslation(
                    translation: _logoOffset.value,
                    child: Opacity(
                      opacity:
                          _logoOpacity.value *
                          (1.0 - (_dashboardOpacity.value * 0.96)),
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: Image.asset(
                          'DIMI logo/Main Logo.png',
                          width: 250,
                          cacheWidth: 600,
                          filterQuality: FilterQuality.medium,
                        ),
                      ),
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

/// A restrained visual hint of the dashboard appearing beneath the logo.
/// It is intentionally not a second Home screen; the real screen follows via
/// the router once the animation is complete.
class _DashboardEcho extends StatelessWidget {
  const _DashboardEcho({required this.opacity, required this.scale});

  final double opacity;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: opacity * 0.42,
        child: Transform.scale(
          scale: scale,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 72),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: 94,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.cardRadius,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.cardGap),
                  Row(
                    children: [
                      Expanded(child: _EchoCard(height: 138)),
                      const SizedBox(width: AppSpacing.cardGap),
                      Expanded(child: _EchoCard(height: 138)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EchoCard extends StatelessWidget {
  const _EchoCard({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
    );
  }
}
