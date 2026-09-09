import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/database.dart';
import '../../providers/task_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/dimi_progress_bar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/pill_segmented_control.dart';
import '../../widgets_modals/add_task_sheet.dart';

// ── Filter tab index → label mapping ─────────────────────────────────────────
const _kTabs = ['All', 'Today', 'Upcoming', 'Completed'];

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Decide which provider to watch based on selected tab.
    final AsyncValue<List<Task>> tasksAsync = switch (_tabIndex) {
      0 => ref.watch(allTasksProvider),
      1 => ref.watch(todaysTasksProvider),
      2 => ref.watch(upcomingTasksProvider),
      3 => ref.watch(completedTasksProvider),
      _ => ref.watch(allTasksProvider),
    };

    // For the progress bar we always need today's tasks regardless of tab.
    final todaysAsync = ref.watch(todaysTasksProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                20,
                AppSpacing.screenHorizontal,
                0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tasks',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  // Add task button
                  GestureDetector(
                    onTap: () =>
                        showAddTaskSheet(context, initialDate: DateTime.now()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.buttonRadius,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.add_rounded,
                            size: 16,
                            color: AppColors.surface,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Add Task',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.surface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // ── Progress bar (today's tasks) ──────────────────────────────
            todaysAsync.when(
              data: (tasks) {
                final total = tasks.length;
                final done = tasks.where((t) => t.isCompleted).length;
                final ratio = total == 0 ? 0.0 : done / total;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenHorizontal,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Today\'s Progress',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                          ),
                          Text(
                            '$done / $total tasks',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      DimiProgressBar(value: ratio),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox(height: 20),
              error: (_, _) => const SizedBox(height: 20),
            ),
            const SizedBox(height: 16),
            // ── Filter tabs ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: PillSegmentedControl(
                  options: _kTabs,
                  selected: _tabIndex,
                  onSelected: (i) => setState(() => _tabIndex = i),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // ── Task list ─────────────────────────────────────────────────
            Expanded(
              child: tasksAsync.when(
                data: (tasks) {
                  if (tasks.isEmpty) {
                    return EmptyState(
                      icon: Icons.check_circle_outline_rounded,
                      title: 'No tasks here',
                      subtitle: _tabIndex == 3
                          ? 'Complete a task and it will appear here.'
                          : 'Tap "Add Task" to get started.',
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenHorizontal,
                      vertical: 4,
                    ),
                    itemCount: tasks.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.cardGap),
                    itemBuilder: (context, i) => _TaskCard(task: tasks[i]),
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
    );
  }
}

// ── Task card ──────────────────────────────────────────────────────────────────

class _TaskCard extends ConsumerWidget {
  const _TaskCard({required this.task});
  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dao = ref.read(taskDaoProvider);
    final isCompleted = task.isCompleted;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: isCompleted
              ? AppColors.success.withAlpha(80)
              : AppColors.divider,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          onLongPress: () => _showDeleteDialog(context, dao),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                // Checkbox
                GestureDetector(
                  onTap: () => dao.toggleCompleted(task.id, !isCompleted),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppColors.success
                          : Colors.transparent,
                      border: Border.all(
                        color: isCompleted
                            ? AppColors.success
                            : AppColors.textSecondary,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: isCompleted
                        ? const Icon(
                            Icons.check_rounded,
                            size: 15,
                            color: AppColors.surface,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                // Title + meta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: isCompleted
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 11,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDue(task),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontSize: 11),
                          ),
                          const SizedBox(width: 10),
                          _CategoryPill(category: task.category),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDue(Task task) {
    final date = DateFormat('d MMM').format(task.dueDate);
    final time = task.dueTime ?? '';
    return time.isNotEmpty ? '$date · $time' : date;
  }

  Future<void> _showDeleteDialog(BuildContext context, dynamic dao) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        title: const Text('Delete task?'),
        content: Text('This will permanently remove "${task.title}".'),
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
      await dao.deleteTask(task.id);
    }
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.category});
  final String category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        category,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppColors.accent,
        ),
      ),
    );
  }
}
