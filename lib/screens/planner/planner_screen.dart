import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/database.dart';
import '../../providers/task_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/pill_segmented_control.dart';
import '../../widgets_modals/add_task_sheet.dart';

const _kViews = ['Day', 'Week', 'Month'];

// ─── Date helpers ─────────────────────────────────────────────────────────────

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

// ─── Screen ───────────────────────────────────────────────────────────────────

class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  DateTime _selected = DateTime.now();
  int _view = 0; // 0=Day, 1=Week, 2=Month

  // ── Nav helpers ─────────────────────────────────────────────────────────

  void _prev() {
    setState(() {
      _selected = switch (_view) {
        1 => _selected.subtract(const Duration(days: 7)),
        2 => DateTime(_selected.year, _selected.month - 1, 1),
        _ => _selected.subtract(const Duration(days: 1)),
      };
    });
  }

  void _next() {
    setState(() {
      _selected = switch (_view) {
        1 => _selected.add(const Duration(days: 7)),
        2 => DateTime(_selected.year, _selected.month + 1, 1),
        _ => _selected.add(const Duration(days: 1)),
      };
    });
  }

  // ── Header label ────────────────────────────────────────────────────────

  String _headerLabel() {
    return switch (_view) {
      1 => _weekLabel(_selected),
      2 => DateFormat('MMMM yyyy').format(_selected),
      _ => _dayLabel(_selected),
    };
  }

  String _dayLabel(DateTime d) {
    if (_sameDay(d, DateTime.now())) {
      return 'Today, ${DateFormat('d MMM yyyy').format(d)}';
    }
    if (_sameDay(d, DateTime.now().add(const Duration(days: 1)))) {
      return 'Tomorrow, ${DateFormat('d MMM yyyy').format(d)}';
    }
    if (_sameDay(d, DateTime.now().subtract(const Duration(days: 1)))) {
      return 'Yesterday, ${DateFormat('d MMM yyyy').format(d)}';
    }
    return DateFormat('EEE, d MMM yyyy').format(d);
  }

  String _weekLabel(DateTime d) {
    final mon = d.subtract(Duration(days: d.weekday - 1));
    final sun = mon.add(const Duration(days: 6));
    return '${DateFormat('d MMM').format(mon)} – ${DateFormat('d MMM').format(sun)}';
  }

  // ── Date pick ────────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selected,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
            primary: AppColors.accent,
            onPrimary: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selected = picked);
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── App bar ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                20,
                AppSpacing.screenHorizontal,
                0,
              ),
              child: Row(
                children: [
                  Text(
                    'Planner',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const Spacer(),
                  _SmallBtn(
                    icon: Icons.today_outlined,
                    onTap: () {
                      setState(() => _selected = DateTime.now());
                    },
                  ),
                  const SizedBox(width: 8),
                  _SmallBtn(icon: Icons.more_vert_rounded, onTap: () {}),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── View selector (Day / Week / Month) ───────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
              ),
              child: PillSegmentedControl(
                options: _kViews,
                selected: _view,
                onSelected: (i) => setState(() => _view = i),
              ),
            ),
            const SizedBox(height: 14),

            // ── Date navigation ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
              ),
              child: Row(
                children: [
                  _NavArrow(icon: Icons.chevron_left_rounded, onTap: _prev),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickDate,
                      child: Text(
                        _headerLabel(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _NavArrow(icon: Icons.chevron_right_rounded, onTap: _next),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Content ──────────────────────────────────────────────────
            Expanded(
              child: switch (_view) {
                1 => _WeekView(
                  anchorDate: _selected,
                  onDayTap: (d) => setState(() {
                    _selected = d;
                    _view = 0;
                  }),
                ),
                2 => _MonthView(
                  anchorDate: _selected,
                  onDayTap: (d) => setState(() {
                    _selected = d;
                    _view = 0;
                  }),
                ),
                _ => _DayView(date: _selected),
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddTaskSheet(context, initialDate: _selected),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.surface,
        elevation: 2,
        child: const Icon(Icons.add_rounded, size: 24),
      ),
    );
  }
}

// ─── Day View ─────────────────────────────────────────────────────────────────

class _DayView extends ConsumerWidget {
  const _DayView({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksForDateProvider(_dateOnly(date)));

    return tasksAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: AppColors.accent,
          strokeWidth: 2,
        ),
      ),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (tasks) {
        final sorted = [...tasks]
          ..sort((a, b) {
            final aMin = _timeToMinutes(a.dueTime);
            final bMin = _timeToMinutes(b.dueTime);
            return aMin.compareTo(bMin);
          });

        if (sorted.isEmpty) {
          return const EmptyState(
            icon: Icons.calendar_today_outlined,
            title: 'Nothing scheduled',
            subtitle: 'Tap + to add a task for this day.',
          );
        }

        // Progress header
        final done = sorted.where((t) => t.isCompleted).length;

        return Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                0,
                AppSpacing.screenHorizontal,
                10,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: sorted.isEmpty ? 0 : done / sorted.length,
                        backgroundColor: AppColors.accentSoft,
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.accent,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$done/${sorted.length}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                  vertical: 4,
                ),
                itemCount: sorted.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.cardGap),
                itemBuilder: (ctx, i) => _TaskTile(task: sorted[i]),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Week View ────────────────────────────────────────────────────────────────

class _WeekView extends ConsumerWidget {
  const _WeekView({required this.anchorDate, required this.onDayTap});
  final DateTime anchorDate;
  final ValueChanged<DateTime> onDayTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get Mon–Sun of the week containing anchorDate
    final mon = anchorDate.subtract(Duration(days: anchorDate.weekday - 1));
    final days = List.generate(7, (i) => _dateOnly(mon.add(Duration(days: i))));

    final upcomingAsync = ref.watch(upcomingTasksProvider);
    final allAsync = ref.watch(allTasksProvider);

    // Merge both streams, deduplicate by id, get full week picture
    final seenIds = <int>{};
    final allTasks = <Task>[
      ...?upcomingAsync.valueOrNull,
      ...?allAsync.valueOrNull,
    ].where((t) => seenIds.add(t.id)).toList();
    // Group tasks by date
    Map<DateTime, List<Task>> byDay = {};
    for (final d in days) {
      byDay[d] = allTasks.where((t) => _sameDay(t.dueDate, d)).toList()
        ..sort(
          (a, b) =>
              _timeToMinutes(a.dueTime).compareTo(_timeToMinutes(b.dueTime)),
        );
    }

    final today = _dateOnly(DateTime.now());

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      children: days.map((d) {
        final dayTasks = byDay[d] ?? [];
        final isToday = d == today;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => onDayTap(d),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isToday ? AppColors.accent : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          DateFormat('d').format(d),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isToday
                                ? AppColors.surface
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('EEE, d MMM').format(d),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isToday
                            ? AppColors.accent
                            : AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    if (dayTasks.isNotEmpty)
                      Text(
                        '${dayTasks.where((t) => t.isCompleted).length}/${dayTasks.length}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              if (dayTasks.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(left: 40, top: 4, bottom: 4),
                  child: Text(
                    'No tasks',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    children: dayTasks
                        .map(
                          (t) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: _TaskTile(task: t, compact: true),
                          ),
                        )
                        .toList(),
                  ),
                ),
              const Divider(height: 1, color: AppColors.divider),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─── Month View ───────────────────────────────────────────────────────────────

class _MonthView extends ConsumerWidget {
  const _MonthView({required this.anchorDate, required this.onDayTap});
  final DateTime anchorDate;
  final ValueChanged<DateTime> onDayTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allAsync = ref.watch(allTasksProvider);
    final allTasks = allAsync.valueOrNull ?? [];

    final firstOfMonth = DateTime(anchorDate.year, anchorDate.month, 1);
    final daysInMonth = DateTime(anchorDate.year, anchorDate.month + 1, 0).day;
    final startWeekday = firstOfMonth.weekday; // 1=Mon
    final today = _dateOnly(DateTime.now());

    // Build calendar grid cells (leading empties + days)
    final cells = <DateTime?>[
      ...List.filled(startWeekday - 1, null),
      ...List.generate(
        daysInMonth,
        (i) => DateTime(anchorDate.year, anchorDate.month, i + 1),
      ),
    ];

    // Task count per day
    Map<DateTime, int> taskCount = {};
    for (final t in allTasks) {
      final d = _dateOnly(t.dueDate);
      taskCount[d] = (taskCount[d] ?? 0) + 1;
    }

    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Column(
      children: [
        // Day-of-week header
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
          ),
          child: Row(
            children: dayLabels
                .map(
                  (l) => Expanded(
                    child: Center(
                      child: Text(
                        l,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 8),
        // Calendar grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: cells.length,
            itemBuilder: (ctx, i) {
              final d = cells[i];
              if (d == null) return const SizedBox.shrink();

              final isToday = d == today;
              final isSelected = _sameDay(d, anchorDate);
              final count = taskCount[d] ?? 0;

              return GestureDetector(
                onTap: () => onDayTap(d),
                child: Container(
                  decoration: BoxDecoration(
                    color: isToday
                        ? AppColors.accent
                        : isSelected
                        ? AppColors.accentSoft
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '${d.day}',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: isToday || isSelected
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isToday
                              ? AppColors.surface
                              : AppColors.textPrimary,
                        ),
                      ),
                      if (count > 0)
                        Positioned(
                          bottom: 4,
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isToday
                                  ? AppColors.surface
                                  : AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Task tile ────────────────────────────────────────────────────────────────

class _TaskTile extends ConsumerWidget {
  const _TaskTile({required this.task, this.compact = false});
  final Task task;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dao = ref.read(taskDaoProvider);
    final done = task.isCompleted;

    return GestureDetector(
      onLongPress: () => _showOptions(context, ref),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 14,
          vertical: compact ? 10 : 13,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
            color: done ? AppColors.success.withAlpha(80) : AppColors.divider,
          ),
        ),
        child: Row(
          children: [
            // Left color bar
            Container(
              width: 4,
              height: compact ? 36 : 44,
              decoration: BoxDecoration(
                color: _categoryColor(task.category),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            // Time column
            if (task.dueTime != null)
              SizedBox(
                width: 38,
                child: Text(
                  task.dueTime!,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            if (task.dueTime != null)
              Container(
                width: 1,
                height: 28,
                color: AppColors.divider,
                margin: const EdgeInsets.only(right: 10),
              ),
            // Title + category
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: compact ? 12 : 13,
                      fontWeight: FontWeight.w600,
                      color: done
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                      decoration: done ? TextDecoration.lineThrough : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!compact)
                    Text(
                      task.category,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            // Checkbox
            GestureDetector(
              onTap: () => dao.toggleCompleted(task.id, !done),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: done ? AppColors.accent : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: done ? AppColors.accent : AppColors.textSecondary,
                    width: 1.5,
                  ),
                ),
                child: done
                    ? const Icon(
                        Icons.check_rounded,
                        size: 13,
                        color: AppColors.surface,
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _categoryColor(String cat) => switch (cat.toLowerCase()) {
    'study' => AppColors.info,
    'personal' => AppColors.success,
    'health' => AppColors.danger,
    'finance' => AppColors.accent,
    'college' => const Color(0xFF8A4FFF),
    _ => AppColors.textSecondary,
  };

  Future<void> _showOptions(BuildContext context, WidgetRef ref) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                task.title,
                style: Theme.of(context).textTheme.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(
                Icons.edit_outlined,
                color: AppColors.textPrimary,
              ),
              title: const Text(
                'Edit task',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 14),
              ),
              onTap: () => Navigator.pop(ctx, 'edit'),
            ),
            ListTile(
              leading: Icon(
                task.isCompleted
                    ? Icons.radio_button_unchecked
                    : Icons.check_circle_outline,
                color: AppColors.accent,
              ),
              title: Text(
                task.isCompleted ? 'Mark incomplete' : 'Mark complete',
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
              ),
              onTap: () => Navigator.pop(ctx, 'toggle'),
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: AppColors.danger,
              ),
              title: const Text(
                'Delete',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: AppColors.danger,
                ),
              ),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (!context.mounted) return;
    final dao = ref.read(taskDaoProvider);

    switch (action) {
      case 'edit':
        await showAddTaskSheet(context, existingTask: task);
        break;
      case 'toggle':
        await dao.toggleCompleted(task.id, !task.isCompleted);
        break;
      case 'delete':
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            ),
            title: const Text(
              'Delete task?',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Text(
              'Remove "${task.title}"?',
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
            ),
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
        if (ok == true) await dao.deleteTask(task.id);
        break;
    }
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

int _timeToMinutes(String? time) {
  if (time == null || time.isEmpty) return 1440;
  final p = time.split(':');
  if (p.length < 2) return 1440;
  return int.parse(p[0]) * 60 + int.parse(p[1]);
}

class _NavArrow extends StatelessWidget {
  const _NavArrow({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.divider),
        ),
        child: Icon(icon, size: 18, color: AppColors.textPrimary),
      ),
    );
  }
}

class _SmallBtn extends StatelessWidget {
  const _SmallBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.divider),
        ),
        child: Icon(icon, size: 16, color: AppColors.textPrimary),
      ),
    );
  }
}
