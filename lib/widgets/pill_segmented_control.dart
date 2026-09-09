import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

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
              onTap: () => onSelected(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: EdgeInsets.symmetric(
                  horizontal: bounded ? 8 : 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.surfaceDark : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Center(
                  child: Text(
                    options[i],
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive
                          ? AppColors.surface
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            );
            return bounded ? Expanded(child: segment) : segment;
          });

          return Row(
            mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
            children: children,
          );
        },
      ),
    );
  }
}
