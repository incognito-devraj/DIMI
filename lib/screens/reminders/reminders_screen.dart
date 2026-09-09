import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/database.dart';
import '../../providers/reminder_providers.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/pill_segmented_control.dart';
import '../../widgets_modals/add_reminder_sheet.dart';

const _kTabs = ['All', 'Today', 'Upcoming'];

class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Reminder>> remindersAsync = switch (_tabIndex) {
      0 => ref.watch(allRemindersProvider),
      1 => ref.watch(todaysRemindersProvider),
      2 => ref.watch(upcomingRemindersProvider),
      _ => ref.watch(allRemindersProvider),
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                20,
                AppSpacing.screenHorizontal,
                0,
              ),
              child: Text(
                'Reminders',
                style: Theme.of(context).textTheme.displayMedium,
              ),
            ),
            const SizedBox(height: 16),
            // ── Filter tabs ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
              ),
              child: PillSegmentedControl(
                options: _kTabs,
                selected: _tabIndex,
                onSelected: (i) => setState(() => _tabIndex = i),
              ),
            ),
            const SizedBox(height: 16),
            // ── Reminder list ────────────────────────────────────────────────
            Expanded(
              child: remindersAsync.when(
                data: (reminders) {
                  if (reminders.isEmpty) {
                    return const EmptyState(
                      icon: Icons.notifications_outlined,
                      title: 'No reminders',
                      subtitle: 'Tap + to set a reminder.',
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenHorizontal,
                      vertical: 4,
                    ),
                    itemCount: reminders.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.cardGap),
                    itemBuilder: (context, i) =>
                        _ReminderCard(reminder: reminders[i]),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddReminderSheet(context),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.surface,
        elevation: 3,
        child: const Icon(Icons.add_rounded, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// ── Reminder card ─────────────────────────────────────────────────────────────

class _ReminderCard extends ConsumerWidget {
  const _ReminderCard({required this.reminder});
  final Reminder reminder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dao = ref.read(reminderDaoProvider);
    final isOverdue = !reminder.isEnabled
        ? false
        : reminder.dueAt.isBefore(DateTime.now());

    return GestureDetector(
      onLongPress: () => _showDeleteDialog(context, dao),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
            color: isOverdue
                ? AppColors.danger.withAlpha(80)
                : AppColors.divider,
          ),
        ),
        child: Row(
          children: [
            // Bell icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: reminder.isEnabled
                    ? AppColors.accentSoft
                    : AppColors.divider,
                shape: BoxShape.circle,
              ),
              child: Icon(
                reminder.isEnabled
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_off_outlined,
                size: 20,
                color: reminder.isEnabled
                    ? AppColors.accent
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            // Title + date/time
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: reminder.isEnabled
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_outlined,
                        size: 11,
                        color: isOverdue
                            ? AppColors.danger
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDue(reminder.dueAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: isOverdue
                              ? AppColors.danger
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Toggle switch
            Switch(
              value: reminder.isEnabled,
              onChanged: (v) async {
                await dao.toggleEnabled(reminder.id, v);
                if (v) {
                  final updated = await dao.getById(reminder.id);
                  if (updated != null) {
                    await NotificationService.instance.scheduleReminder(
                      updated,
                    );
                  }
                } else {
                  await NotificationService.instance.cancelReminder(
                    reminder.id,
                  );
                }
              },
              activeThumbColor: AppColors.accent,
              activeTrackColor: AppColors.accentSoft,
              inactiveThumbColor: AppColors.textSecondary,
              inactiveTrackColor: AppColors.divider,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDue(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateDay = DateTime(dt.year, dt.month, dt.day);
    final diff = dateDay.difference(today).inDays;

    final timeStr = DateFormat('h:mm a').format(dt);

    if (diff == 0) return 'Today · $timeStr';
    if (diff == 1) return 'Tomorrow · $timeStr';
    if (diff == -1) return 'Yesterday · $timeStr';
    if (diff < 0) return '${diff.abs()}d ago · $timeStr';
    return '${DateFormat('d MMM').format(dt)} · $timeStr';
  }

  Future<void> _showDeleteDialog(BuildContext context, dynamic dao) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        title: const Text('Delete reminder?'),
        content: Text('This will permanently remove "${reminder.title}".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await NotificationService.instance.cancelReminder(reminder.id);
      await dao.deleteReminder(reminder.id);
    }
  }
}
