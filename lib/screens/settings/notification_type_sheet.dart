import 'package:flutter/material.dart';

import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';

/// A styled modal bottom sheet for selecting the DIMI notification type.
///
/// Shows two option cards — Normal and Full Screen — and saves the selection
/// to [NotificationService] when the user taps Save.
///
/// Pops with a [bool] result (true = full screen) so the caller can update
/// its subtitle without an async reload.
class NotificationTypeSheet extends StatefulWidget {
  const NotificationTypeSheet({
    super.key,
    required this.initialFullScreen,
    required this.onSaved,
  });

  final bool initialFullScreen;
  final void Function(bool fullScreen) onSaved;

  @override
  State<NotificationTypeSheet> createState() => _NotificationTypeSheetState();
}

class _NotificationTypeSheetState extends State<NotificationTypeSheet> {
  late bool _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialFullScreen;
  }

  Future<void> _onSave() async {
    await NotificationService.instance.setNotificationMode(
      _selected
          ? DimiNotificationMode.fullScreen
          : DimiNotificationMode.normal,
    );
    if (!mounted) return;
    widget.onSaved(_selected);
    Navigator.of(context).pop(_selected);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Title
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Notification Type',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Choose how DIMI notifies you',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Normal card
            _OptionCard(
              icon: Icons.notifications_outlined,
              title: 'Normal Notification',
              subtitle:
                  'Standard notification with Mark Done and Snooze actions',
              selected: !_selected,
              onTap: () => setState(() => _selected = false),
            ),
            const SizedBox(height: 12),
            // Full screen card
            _OptionCard(
              icon: Icons.fullscreen_rounded,
              title: 'Full Screen Notification',
              subtitle:
                  'Full-screen reminder experience shown on your lock screen',
              selected: _selected,
              onTap: () => setState(() => _selected = true),
            ),
            const SizedBox(height: 24),
            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceDark,
                  foregroundColor: AppColors.surface,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.buttonRadius),
                  ),
                  elevation: 0,
                  textStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: _onSave,
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Option card ──────────────────────────────────────────────────────────────

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor =
        selected ? AppColors.accent : AppColors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent.withAlpha(20) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.divider,
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            // Icon circle
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 22, color: iconColor),
            ),
            const SizedBox(width: 14),
            // Labels
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? AppColors.textPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.accent,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
