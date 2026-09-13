import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/database.dart';
import '../../providers/task_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../core/motion/dimi_motion.dart';
import '../../widgets/dimi_add_action_button.dart';
import '../../widgets/pill_segmented_control.dart';
import '../../widgets_modals/add_task_sheet.dart';
import '../../utils/time_format.dart';
import '../../widgets/dimi_activity_heatmap.dart';

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
  bool _showAddButton = true;

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
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          final visible = switch (notification.direction) {
            ScrollDirection.reverse => false,
            ScrollDirection.forward => true,
            ScrollDirection.idle => _showAddButton,
          };
          if (visible != _showAddButton && mounted) {
            setState(() => _showAddButton = visible);
          }
          return false;
        },
        child: SafeArea(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Planner',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Plan today. A better you tomorrow.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ── View selector (Day / Week / Month) ───────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: PillSegmentedControl(
                    options: _kViews,
                    selected: _view,
                    onSelected: (i) {
                      if (i != _view) setState(() => _view = i);
                    },
                  ),
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
                        child: AnimatedSwitcher(
                          duration: DimiMotion.fast,
                          switchInCurve: DimiMotion.curve,
                          switchOutCurve: DimiMotion.transitionCurve,
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, .08),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              ),
                          child: Text(
                            _headerLabel(),
                            key: ValueKey(_headerLabel()),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
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
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 110),
                  reverseDuration: const Duration(milliseconds: 80),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  layoutBuilder: (currentChild, previousChildren) =>
                      currentChild ?? const SizedBox.shrink(),
                  child: RepaintBoundary(
                    key: ValueKey(_view),
                    child: switch (_view) {
                      1 => _WeekView(
                        anchorDate: _selected,
                        fabVisible: _showAddButton,
                        onDayTap: (d) => setState(() {
                          _selected = d;
                          _view = 0;
                        }),
                      ),
                      2 => _PremiumMonthView(
                        anchorDate: _selected,
                        fabVisible: _showAddButton,
                        onDayTap: (d) => setState(() {
                          _selected = d;
                        }),
                      ),
                      _ => _DayView(
                        date: _selected,
                        fabVisible: _showAddButton,
                      ),
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: IgnorePointer(
        ignoring: !_showAddButton,
        child: AnimatedSlide(
          offset: _showAddButton ? Offset.zero : const Offset(0, 1.4),
          duration: DimiMotion.normal,
          curve: DimiMotion.curve,
          child: AnimatedOpacity(
            opacity: _showAddButton ? 1 : 0,
            duration: DimiMotion.fast,
            child: DimiAddActionButton(
              label: 'Add task',
              onPressed: () => showAddTaskSheet(
                context,
                initialDate: _selected,
                plannerEntry: true,
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// ─── Day View ─────────────────────────────────────────────────────────────────

class _DayView extends ConsumerStatefulWidget {
  const _DayView({required this.date, required this.fabVisible});
  final DateTime date;
  final bool fabVisible;

  @override
  ConsumerState<_DayView> createState() => _DayViewState();
}

class _DayViewState extends ConsumerState<_DayView> {
  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksForDateProvider(_dateOnly(widget.date)));

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

        return sorted.isEmpty
            ? const EmptyState(
                icon: Icons.calendar_today_outlined,
                title: 'Nothing scheduled',
                subtitle: 'Tap Add task to schedule your first task.',
              )
            : _ReferenceDaySchedule(
                tasks: sorted,
                bottomPadding: widget.fabVisible ? 96 : 0,
              );
      },
    );
  }
}

class _ReferenceDaySchedule extends ConsumerWidget {
  const _ReferenceDaySchedule({
    required this.tasks,
    required this.bottomPadding,
  });
  final List<Task> tasks;
  final double bottomPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListView.builder(
          padding: EdgeInsets.fromLTRB(0, 8, 0, bottomPadding),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return _ReferenceTaskRow(task: task);
          },
        ),
      ),
    );
  }
}

class _ReferenceTaskRow extends ConsumerWidget {
  const _ReferenceTaskRow({required this.task});
  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done = task.isCompleted;
    final category = task.category.toLowerCase();
    final color = switch (category) {
      'study' => AppColors.info,
      'health' => AppColors.danger,
      'college' => const Color(0xFF8A4FFF),
      'personal' => AppColors.accent,
      _ => AppColors.textSecondary,
    };
    final icon = switch (category) {
      'study' => Icons.menu_book_outlined,
      'health' => Icons.fitness_center_outlined,
      'college' => Icons.school_outlined,
      'finance' => Icons.account_balance_wallet_outlined,
      _ => Icons.wb_sunny_outlined,
    };

    return InkWell(
      onLongPress: () => _TaskTile(task: task)._showOptions(context, ref),
      onTap: () => ref.read(taskDaoProvider).toggleCompleted(task.id, !done),
      child: Container(
        height: 82,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              child: Text(
                formatTime12Hour(task.dueTime),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Container(width: 2, height: 48, color: color),
            const SizedBox(width: 12),
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withAlpha(28),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: done
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                      decoration: done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2),
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
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () =>
                  ref.read(taskDaoProvider).toggleCompleted(task.id, !done),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: done ? AppColors.accent : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: done ? AppColors.accent : const Color(0xFFD7D0C3),
                    width: 2,
                  ),
                ),
                child: done
                    ? const Icon(
                        Icons.check_rounded,
                        color: AppColors.surface,
                        size: 18,
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Week View ────────────────────────────────────────────────────────────────

class _WeekView extends ConsumerWidget {
  const _WeekView({
    required this.anchorDate,
    required this.onDayTap,
    required this.fabVisible,
  });
  final DateTime anchorDate;
  final ValueChanged<DateTime> onDayTap;
  final bool fabVisible;

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
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        0,
        AppSpacing.screenHorizontal,
        fabVisible ? 96 : 0,
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
                      width: 48,
                      height: 48,
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
                        textAlign: TextAlign.center,
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
                            child: _TaskTile(
                              task: t,
                              compact: true,
                              tapToToggle: true,
                            ),
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

class _DayPlan {
  const _DayPlan(this.date, this.tasks);
  final DateTime date;
  final List<Task> tasks;

  int get plannedMinutes =>
      tasks.fold(0, (sum, task) => sum + task.plannedMinutes);
  int get completedMinutes => tasks.fold(
    0,
    (sum, task) =>
        sum +
        (task.completedMinutes > 0
            ? task.completedMinutes
            : task.isCompleted
            ? task.plannedMinutes
            : 0),
  );
  int get completedTasks => tasks.where((task) => task.isCompleted).length;
  bool get hasPlan => plannedMinutes > 0;
  double get score => hasPlan ? completedMinutes / plannedMinutes : 0;
}

class _PremiumMonthView extends ConsumerStatefulWidget {
  const _PremiumMonthView({
    required this.anchorDate,
    required this.onDayTap,
    required this.fabVisible,
  });
  final DateTime anchorDate;
  final ValueChanged<DateTime> onDayTap;
  final bool fabVisible;

  @override
  ConsumerState<_PremiumMonthView> createState() => _PremiumMonthViewState();
}

class _PremiumMonthViewState extends ConsumerState<_PremiumMonthView> {
  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final async = ref.watch(allPlannerEntriesProvider);
    return async.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (error, _) =>
          Center(child: Text('Unable to load planner data: $error')),
      data: (tasks) {
        final grouped = <DateTime, List<Task>>{};
        for (final task in tasks) {
          grouped.putIfAbsent(_dateOnly(task.dueDate), () => []).add(task);
        }
        _DayPlan planFor(DateTime date) => _DayPlan(
          _dateOnly(date),
          grouped[_dateOnly(date)] ?? const <Task>[],
        );
        final monthStart = DateTime(
          widget.anchorDate.year,
          widget.anchorDate.month,
          1,
        );
        final monthEnd = DateTime(
          widget.anchorDate.year,
          widget.anchorDate.month + 1,
          0,
        );
        final today = _dateOnly(DateTime.now());
        final monthPlans = List.generate(
          monthEnd.day,
          (i) => planFor(
            DateTime(widget.anchorDate.year, widget.anchorDate.month, i + 1),
          ),
        );
        final plannedDays = monthPlans.where((p) => p.hasPlan).length;
        final completedDays = monthPlans
            .where((p) => p.hasPlan && p.completedTasks == p.tasks.length)
            .length;
        final plannedTaskCount = monthPlans.fold(
          0,
          (sum, plan) => sum + plan.tasks.length,
        );
        final completedTaskCount = monthPlans.fold(
          0,
          (sum, plan) => sum + plan.completedTasks,
        );
        final average = plannedTaskCount == 0
            ? 0.0
            : completedTaskCount / plannedTaskCount;
        var streak = 0;
        var cursor = today;
        while (true) {
          final p = planFor(cursor);
          if (!p.hasPlan || p.score < .7) break;
          streak++;
          cursor = cursor.subtract(const Duration(days: 1));
        }
        final cells = <DateTime?>[
          ...List<DateTime?>.filled(monthStart.weekday - 1, null),
          ...monthPlans.map((p) => p.date),
        ];
        return ListView(
          padding: EdgeInsets.only(bottom: widget.fabVisible ? 96 : 0),
          children: [
            RepaintBoundary(
              child: DimiActivityHeatmap(
                tasks: tasks,
                title: 'Completion heatmap',
                subtitle: 'Activity over the last year',
              ),
            ),
            const SizedBox(height: 12),
            _MonthStats(
              plannedDays: plannedDays,
              completedDays: completedDays,
              average: average,
              streak: streak,
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: DimiMotion.normal,
              switchInCurve: DimiMotion.curve,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(.018, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              layoutBuilder: (currentChild, previousChildren) =>
                  currentChild ?? const SizedBox.shrink(),
              child: RepaintBoundary(
                child: _CalendarCard(
                  key: ValueKey(
                    '${widget.anchorDate.year}-${widget.anchorDate.month}',
                  ),
                  month: widget.anchorDate,
                  cells: cells,
                  planFor: planFor,
                  today: today,
                  selected: widget.anchorDate,
                  onTap: widget.onDayTap,
                ),
              ),
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: DimiMotion.fast,
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: _SelectedPlanCard(
                key: ValueKey(_dateOnly(widget.anchorDate)),
                plan: planFor(widget.anchorDate),
              ),
            ),
          ],
        );
      },
    );
  }

  // ignore: unused_element
  void _showDetails(
    BuildContext context,
    _DayPlan plan,
  ) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('MMMM d, yyyy').format(plan.date),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            plan.hasPlan
                ? '${(plan.score * 100).round()}% completed'
                : 'No plan recorded',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_minutesLabel(plan.completedMinutes)} / ${_minutesLabel(plan.plannedMinutes)} planned',
          ),
          Text(
            '${plan.completedTasks} of ${plan.tasks.length} tasks completed',
          ),
        ],
      ),
    ),
  );
}

class _HeatmapCard extends StatelessWidget {
  const _HeatmapCard({required this.planFor, required this.onTap});
  final _DayPlan Function(DateTime) planFor;
  final ValueChanged<DateTime> onTap;
  @override
  Widget build(BuildContext context) {
    final today = _dateOnly(DateTime.now());
    // Choose the number of weeks from the available width. This keeps the
    // GitHub-style grid readable on phones while showing a full year on
    // wider layouts.
    final availableGridWidth = MediaQuery.sizeOf(context).width - 14 * 2 - 29;
    final weekCount = (availableGridWidth / 15).floor().clamp(13, 53).toInt();
    final firstMonday = today.subtract(
      Duration(days: today.weekday - 1 + (weekCount - 1) * 7),
    );
    final days = List.generate(
      weekCount * 7,
      (i) => firstMonday.add(Duration(days: i)),
    );
    final scoredDays = days
        .where((day) => !day.isAfter(today) && planFor(day).hasPlan)
        .map(planFor)
        .toList();
    final average = scoredDays.isEmpty
        ? 0
        : (scoredDays.fold(0.0, (sum, plan) => sum + plan.score) /
                  scoredDays.length *
                  100)
              .round();
    return _PlannerCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bar_chart_rounded, size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Completion Heatmap',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'How much of your plan you completed',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Adaptive history',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const SizedBox(width: 29),
              Expanded(
                child: Row(
                  children: List.generate(
                    days.length ~/ 7,
                    (week) => Expanded(
                      child: Text(
                        days[week * 7].day <= 7
                            ? DateFormat('MMM').format(days[week * 7])
                            : '',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 8,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                width: 24,
                height: 86,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      'Mon',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 9,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'Wed',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 9,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'Fri',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 9,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: SizedBox(
                  height: 86,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: days.length ~/ 7,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                    ),
                    itemCount: days.length,
                    itemBuilder: (_, index) {
                      final day =
                          days[(index % 7) * (days.length ~/ 7) + index ~/ 7];
                      final plan = planFor(day);
                      final future = day.isAfter(today);
                      return GestureDetector(
                        onTap: () => onTap(day),
                        child: AnimatedContainer(
                          duration: DimiMotion.normal,
                          curve: DimiMotion.curve,
                          decoration: BoxDecoration(
                            color: _heatColor(plan, future),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text(
                'Less',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 9,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 5),
              ...List.generate(
                5,
                (i) => Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(left: 3),
                  decoration: BoxDecoration(
                    color: _legendColor(i),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(width: 5),
              const Text(
                'More',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 9,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$average%',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Text(
                    'Average',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 9,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Color _heatColor(_DayPlan plan, bool future) => future || !plan.hasPlan
      ? AppColors.background
      : _legendColor((plan.score * 5).ceil().clamp(1, 5) - 1);
  static Color _legendColor(int level) => [
    AppColors.accentSoft,
    const Color(0xFFFFD98A),
    const Color(0xFFFFB52E),
    const Color(0xFFE48113),
    const Color(0xFF9C3F0C),
  ][level];
}

class _MonthStats extends StatelessWidget {
  const _MonthStats({
    required this.plannedDays,
    required this.completedDays,
    required this.average,
    required this.streak,
  });
  final int plannedDays, completedDays, streak;
  final double average;
  @override
  Widget build(BuildContext context) => Row(
    children:
        [
              _StatBox(
                icon: Icons.check_rounded,
                color: AppColors.accent,
                value: '$plannedDays',
                label: 'Days planned',
              ),
              _StatBox(
                icon: Icons.done_all_rounded,
                color: AppColors.success,
                value: '$completedDays',
                label: 'Days completed',
              ),
              _StatBox(
                icon: Icons.pie_chart_outline_rounded,
                color: AppColors.accent,
                value: '${(average * 100).round()}%',
                label: 'Avg completion',
              ),
              _StatBox(
                icon: Icons.local_fire_department_outlined,
                color: AppColors.danger,
                value: '$streak',
                label: 'Day streak',
              ),
            ]
            .map(
              (w) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: w,
                ),
              ),
            )
            .toList(),
  );
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final Color color;
  final String value, label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
    decoration: BoxDecoration(
      color: color.withAlpha(20),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: color.withAlpha(18)),
    ),
    child: Column(
      children: [
        Icon(icon, size: 19, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 8,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    ),
  );
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({
    super.key,
    required this.month,
    required this.cells,
    required this.planFor,
    required this.today,
    required this.selected,
    required this.onTap,
  });
  final DateTime month, today, selected;
  final List<DateTime?> cells;
  final _DayPlan Function(DateTime) planFor;
  final ValueChanged<DateTime> onTap;
  @override
  Widget build(BuildContext context) => _PlannerCard(
    child: Column(
      children: [
        Row(
          children: [
            const Icon(Icons.calendar_month_outlined, size: 20),
            const SizedBox(width: 8),
            Text(
              DateFormat('MMMM yyyy').format(month),
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            const Text(
              'Today',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
              .map(
                (d) => Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 7),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 5,
            crossAxisSpacing: 5,
          ),
          itemCount: ((cells.length + 6) ~/ 7) * 7,
          itemBuilder: (_, index) {
            final day = index < cells.length ? cells[index] : null;
            if (day == null) return const SizedBox.shrink();
            final plan = planFor(day);
            final isToday = _sameDay(day, today);
            final isSelected = _sameDay(day, selected);
            final future = day.isAfter(today);
            return GestureDetector(
              onTap: () => onTap(day),
              child: Container(
                decoration: BoxDecoration(
                  color: isToday
                      ? AppColors.accent
                      : _HeatmapCard._heatColor(plan, future).withAlpha(45),
                  borderRadius: BorderRadius.circular(11),
                  border: isSelected && !isToday
                      ? Border.all(color: AppColors.accent)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${day.day}',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: isToday || isSelected
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: isToday
                            ? AppColors.surface
                            : AppColors.textPrimary,
                      ),
                    ),
                    if (plan.hasPlan)
                      Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.only(top: 3),
                        decoration: BoxDecoration(
                          color: isToday ? AppColors.surface : AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    ),
  );
}

class _SelectedPlanCard extends StatelessWidget {
  const _SelectedPlanCard({super.key, required this.plan});
  final _DayPlan plan;
  @override
  Widget build(BuildContext context) => _PlannerCard(
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: AppColors.background,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.description_outlined),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tasks on ${DateFormat('d MMM').format(plan.date)}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${plan.completedTasks} of ${plan.tasks.length} completed',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded),
      ],
    ),
  );
}

class _PlannerCard extends StatelessWidget {
  const _PlannerCard({
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppColors.divider),
    ),
    child: child,
  );
}

String _minutesLabel(int minutes) => minutes < 60
    ? '${minutes}m'
    : '${minutes ~/ 60}h${minutes % 60 == 0 ? '' : ' ${minutes % 60}m'}';

// ignore: unused_element
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
        _CompletionHeatmap(tasks: allTasks),
        const SizedBox(height: 10),
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

/// GitHub-style completion history. Each square is the percentage of tasks
/// completed on that day, rather than just the number of tasks.
class _CompletionHeatmap extends StatelessWidget {
  const _CompletionHeatmap({required this.tasks});
  final List<Task> tasks;

  static const _weeks = 13;

  @override
  Widget build(BuildContext context) {
    final today = _dateOnly(DateTime.now());
    final start = today.subtract(
      Duration(days: today.weekday - 1 + (_weeks - 1) * 7),
    );
    final cells = List.generate(
      _weeks * 7,
      (i) => start.add(Duration(days: i)),
    );
    final totals = <DateTime, int>{};
    final completed = <DateTime, int>{};

    for (final task in tasks) {
      final day = _dateOnly(task.dueDate);
      totals[day] = (totals[day] ?? 0) + 1;
      if (task.isCompleted) completed[day] = (completed[day] ?? 0) + 1;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Completion rhythm',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                const Text(
                  'last 13 weeks',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 62,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 13,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemCount: cells.length,
                itemBuilder: (context, index) {
                  // GridView lays children out row-first; reorder them so
                  // each vertical column represents one calendar week.
                  final day = cells[(index % 7) * _weeks + index ~/ 7];
                  final total = totals[day] ?? 0;
                  final done = completed[day] ?? 0;
                  final ratio = total == 0 ? 0.0 : done / total;
                  return Tooltip(
                    message: total == 0
                        ? '${DateFormat('d MMM').format(day)} · no tasks'
                        : '${DateFormat('d MMM').format(day)} · $done/$total complete',
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: _heatColor(ratio, total),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'Less',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 9,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 5),
                ...[0.0, .25, .5, .75, 1.0].map(
                  (ratio) => Padding(
                    padding: const EdgeInsets.only(left: 3),
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: _heatColor(ratio, 1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  'More',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 9,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Color _heatColor(double ratio, int total) {
    if (total == 0 || ratio == 0) return AppColors.accentSoft;
    if (ratio < .25) return AppColors.accent.withAlpha(70);
    if (ratio < .5) return AppColors.accent.withAlpha(120);
    if (ratio < .75) return AppColors.accent.withAlpha(180);
    return AppColors.accent;
  }
}

// ─── Task tile ────────────────────────────────────────────────────────────────

class _TaskTile extends ConsumerWidget {
  const _TaskTile({
    required this.task,
    this.compact = false,
    this.tapToToggle = false,
  });
  final Task task;
  final bool compact;
  final bool tapToToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dao = ref.read(taskDaoProvider);
    final done = task.isCompleted;

    return GestureDetector(
      onLongPress: () => _showOptions(context, ref),
      onTap: tapToToggle ? () => dao.toggleCompleted(task.id, !done) : null,
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
                  formatTime12Hour(task.dueTime),
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
              onTap: tapToToggle
                  ? null
                  : () => dao.toggleCompleted(task.id, !done),
              child: AnimatedContainer(
                duration: DimiMotion.fast,
                curve: DimiMotion.curve,
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
                child: AnimatedSwitcher(
                  duration: DimiMotion.fast,
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: done
                      ? const Icon(
                          Icons.check_rounded,
                          key: ValueKey('planner-done'),
                          size: 13,
                          color: AppColors.surface,
                        )
                      : const SizedBox(key: ValueKey('planner-pending')),
                ),
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
        child: Icon(icon, size: 28, color: AppColors.textPrimary),
      ),
    );
  }
}
