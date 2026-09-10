import 'package:flutter/material.dart';

import 'dimi_motion.dart';

Widget dimiPageTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final curved = CurvedAnimation(
    parent: animation,
    curve: DimiMotion.transitionCurve,
  );
  return FadeTransition(
    opacity: curved,
    child: SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.018, 0),
        end: Offset.zero,
      ).animate(curved),
      child: child,
    ),
  );
}
