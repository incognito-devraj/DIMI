import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Reusable rounded white card used across every screen.
/// Matches the soft card style from the mockups: white fill, 1 px divider
/// border, 20 px radius, 16 px internal padding.
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.child, this.padding, this.color});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.divider),
      ),
      padding: padding ?? const EdgeInsets.all(AppSpacing.cardPadding),
      child: child,
    );
  }
}
