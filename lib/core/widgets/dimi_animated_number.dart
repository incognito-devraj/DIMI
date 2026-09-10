import 'package:flutter/material.dart';

import '../motion/dimi_motion.dart';

class DimiAnimatedNumber extends StatelessWidget {
  const DimiAnimatedNumber({
    super.key,
    required this.value,
    this.decimals = 0,
    this.suffix = '',
    this.prefix = '',
    this.style,
    this.duration = DimiMotion.slow,
  });

  final double value;
  final int decimals;
  final String suffix;
  final String prefix;
  final TextStyle? style;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value),
      duration: DimiMotion.duration(context, duration),
      curve: DimiMotion.curve,
      builder: (context, current, _) => Text(
        '$prefix${current.toStringAsFixed(decimals)}$suffix',
        style: style,
      ),
    );
  }
}
