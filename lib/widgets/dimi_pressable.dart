import 'package:flutter/material.dart';

import '../core/motion/dimi_motion.dart';

/// Adds a small, consistent lift/press response without changing tap behavior.
class DimiPressable extends StatefulWidget {
  const DimiPressable({
    super.key,
    required this.onTap,
    required this.child,
    this.borderRadius = BorderRadius.zero,
  });

  final VoidCallback? onTap;
  final Widget child;
  final BorderRadius borderRadius;

  @override
  State<DimiPressable> createState() => _DimiPressableState();
}

class _DimiPressableState extends State<DimiPressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: widget.onTap == null ? null : (_) => _setPressed(true),
      onTapUp: widget.onTap == null ? null : (_) => _setPressed(false),
      onTapCancel: widget.onTap == null ? null : () => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? .985 : 1,
        duration: DimiMotion.fast,
        curve: DimiMotion.curve,
        child: ClipRRect(borderRadius: widget.borderRadius, child: widget.child),
      ),
    );
  }

  void _setPressed(bool value) {
    if (mounted) setState(() => _pressed = value);
  }
}
