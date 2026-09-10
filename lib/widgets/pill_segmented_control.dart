import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../core/motion/dimi_motion.dart';

/// Dark-active-pill segmented control used throughout DIMI
/// ("All / Today / Upcoming / Completed", "Day / Week / Month", etc.)
class PillSegmentedControl extends StatelessWidget {
  const PillSegmentedControl({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<String> options;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(30),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bounded = constraints.hasBoundedWidth;
          final children = List.generate(options.length, (i) {
            final isActive = i == selected;
            final segment = GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelected(i),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: bounded ? 8 : 16,
                  vertical: 12,
                ),
                child: Center(
                  child: AnimatedDefaultTextStyle(
                    duration: DimiMotion.fast,
                    curve: DimiMotion.curve,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: isActive
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isActive
                          ? AppColors.surface
                          : AppColors.textSecondary,
                    ),
                    child: Text(options[i]),
                  ),
                ),
              ),
            );
            return bounded ? Expanded(child: segment) : segment;
          });

          if (!bounded) {
            return Row(mainAxisSize: MainAxisSize.min, children: children);
          }

          return LayoutBuilder(
            builder: (context, stackConstraints) => Stack(
              children: [
                AnimatedPositioned(
                  left: stackConstraints.maxWidth * selected / options.length,
                  top: 0,
                  bottom: 0,
                  width: stackConstraints.maxWidth / options.length,
                  duration: DimiMotion.normal,
                  curve: DimiMotion.transitionCurve,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                ),
                Row(children: children),
              ],
            ),
          );
        },
      ),
    );
  }
}
