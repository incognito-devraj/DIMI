import 'package:flutter/material.dart';

abstract final class DimiMotion {
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 240);
  static const smooth = Duration(milliseconds: 320);
  static const slow = Duration(milliseconds: 420);

  static const curve = Curves.easeOutCubic;
  static const transitionCurve = Curves.easeInOutCubic;

  static Duration duration(BuildContext context, Duration value) =>
      MediaQuery.maybeOf(context)?.disableAnimations == true
          ? Duration.zero
          : value;
}
