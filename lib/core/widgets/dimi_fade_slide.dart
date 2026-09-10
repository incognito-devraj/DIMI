import 'package:flutter/material.dart';

import '../motion/dimi_motion.dart';

class DimiFadeSlide extends StatefulWidget {
  const DimiFadeSlide({super.key, required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  State<DimiFadeSlide> createState() => _DimiFadeSlideState();
}

class _DimiFadeSlideState extends State<DimiFadeSlide>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;

    _controller = AnimationController(
      vsync: this,
      duration: DimiMotion.duration(context, DimiMotion.smooth),
    );
    _initialized = true;
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    if (_initialized) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: _controller,
      curve: DimiMotion.curve,
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.018),
          end: Offset.zero,
        ).animate(animation),
        child: widget.child,
      ),
    );
  }
}
