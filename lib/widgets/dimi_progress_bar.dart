import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Thin animated horizontal progress bar.
/// Track is [AppColors.accentSoft]; fill is [fillColor] (defaults to accent).
class DimiProgressBar extends StatelessWidget {
  const DimiProgressBar({
    super.key,
    required this.value, // 0.0 – 1.0
    this.fillColor,
    this.height = 6.0,
  });

  final double value;
  final Color? fillColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final total = constraints.maxWidth;
        return Stack(
          children: [
            // Track
            Container(
              height: height,
              width: total,
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(height),
              ),
            ),
            // Fill
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              height: height,
              width: (value.clamp(0.0, 1.0) * total),
              decoration: BoxDecoration(
                color: fillColor ?? AppColors.accent,
                borderRadius: BorderRadius.circular(height),
              ),
            ),
          ],
        );
      },
    );
  }
}
