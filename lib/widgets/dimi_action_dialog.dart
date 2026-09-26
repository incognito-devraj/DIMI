import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class DimiDialogAction<T> {
  const DimiDialogAction({
    required this.label,
    required this.value,
    this.icon,
    this.primary = false,
  });

  final String label;
  final T value;
  final IconData? icon;
  final bool primary;
}

Future<T?> showDimiActionDialog<T>(
  BuildContext context, {
  required String title,
  required String message,
  required List<DimiDialogAction<T>> actions,
}) {
  return showDialog<T>(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withAlpha(18),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            actions.length <= 2
                ? Row(
                    children: [
                      for (var i = 0; i < actions.length; i++) ...[
                        if (i > 0) const SizedBox(width: 10),
                        Expanded(
                          child: _DimiActionButton(
                            action: actions[i],
                            onPressed: () => Navigator.pop(
                              dialogContext,
                              actions[i].value,
                            ),
                          ),
                        ),
                      ],
                    ],
                  )
                : Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.end,
                    children: [
                      for (final action in actions)
                        _DimiActionButton(
                          action: action,
                          onPressed: () => Navigator.pop(
                            dialogContext,
                            action.value,
                          ),
                        ),
                    ],
                  ),
          ],
        ),
      ),
    ),
  );
}

class _DimiActionButton<T> extends StatelessWidget {
  const _DimiActionButton({required this.action, required this.onPressed});

  final DimiDialogAction<T> action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final background = action.primary
        ? AppColors.accent
        : AppColors.accentSoft;
    final foreground = action.primary
        ? AppColors.surface
        : AppColors.textPrimary;
    return FilledButton.icon(
      onPressed: onPressed,
      icon: action.icon == null ? const SizedBox.shrink() : Icon(action.icon),
      label: Text(action.label),
      style: FilledButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
