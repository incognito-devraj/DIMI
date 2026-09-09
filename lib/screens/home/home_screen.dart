import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/database.dart';
import '../../providers/money_providers.dart';
import '../../providers/profile_providers.dart';
import '../../providers/reminder_providers.dart';
import '../../providers/task_providers.dart';
import '../../routing/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/dimi_progress_bar.dart';
import '../../widgets/section_card.dart';
import '../../widgets_modals/add_expense_sheet.dart';
import '../../utils/time_format.dart';
import '../../widgets_modals/add_reminder_sheet.dart';
import '../../widgets_modals/add_task_sheet.dart';

final _currencyFmt = NumberFormat('#,##0', 'en_IN');

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final todaysTasksAsync = ref.watch(todaysTasksProvider);
    final allTasksAsync = ref.watch(allTasksProvider);
    final plannerEntriesAsync = ref.watch(allPlannerEntriesProvider);
    final weeklyTxnAsync = ref.watch(thisWeeksTransactionsProvider);
    final upcomingRemindersAsync = ref.watch(upcomingRemindersProvider);

    final name = profileAsync.valueOrNull?.name ?? 'Student';

    // Derived stats (computed outside widgets so they're in one place)
    final todayTotal = todaysTasksAsync.valueOrNull?.length ?? 0;
    final todayDone =
        todaysTasksAsync.valueOrNull?.where((t) => t.isCompleted).length ?? 0;
    final allTotal = allTasksAsync.valueOrNull?.length ?? 0;
    final allDone =
        allTasksAsync.valueOrNull?.where((t) => t.isCompleted).length ?? 0;
    final todayProgress = todayTotal == 0 ? 0.0 : todayDone / todayTotal;
    final weeklyGoal = allTotal == 0 ? 0 : (allDone / allTotal * 100).round();
    final weeklySpent =
        weeklyTxnAsync.valueOrNull
            ?.where((t) => t.type == 'expense')
            .fold(0.0, (s, t) => s + t.amount) ??
        0.0;
    final reminderCount =
        upcomingRemindersAsync.valueOrNull
            ?.where((r) => r.isEnabled && r.dueAt.isAfter(DateTime.now()))
            .length ??
        0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── App bar ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  20,
                  AppSpacing.screenHorizontal,
                  0,
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'DIMI',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 28,
                              height: 1,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              letterSpacing: 1.5,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Plan  ·  Track  ·  Grow',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _HomeHeaderButton(icon: Icons.search_rounded, onTap: () {}),
                    const SizedBox(width: 8),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _HomeHeaderButton(
                          icon: Icons.notifications_none_rounded,
                          onTap: () => context.go(AppRoutes.reminders),
                        ),
                        Positioned(
                          right: 7,
                          top: 6,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AppColors.danger,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.settings),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.surfaceDark,
                        child: Text(
                          name.isEmpty ? 'DM' : name[0].toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.surface,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                child: _ProfileHeroCard(
                  name: name,
                  role:
                      profileAsync.valueOrNull?.role ??
                      'Computer Science Engineer',
                  points: profileAsync.valueOrNull?.points ?? 0,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),

            // ── Dark stats card ────────────────────────────────────────
            // ── Quick actions ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                child: _StatsCard(
                  todayProgress: todayProgress,
                  todayDone: todayDone,
                  todayTotal: todayTotal,
                  weeklyGoal: weeklyGoal,
                  weeklySpent: weeklySpent,
                  reminderCount: reminderCount,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),

            // ── Today's tasks ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                child: const _HomeContentGrid() /*
                child: todaysTasksAsync.when(
                  data: (t) => plannerTasksAsync.when(
                    data: (plannerTasks) => Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _TodayTasksCard(tasks: t, compact: true),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _PlannerPreviewCard(
                            tasks: plannerTasks,
                            compact: true,
                          ),
                        ),
                      ],
                    ),
                    loading: () => const _Shimmer(height: 280),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                  loading: () => const _Shimmer(height: 280),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),

            // ── Weekly spending ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                child: allTxnAsync.when(
                  data: (all) => weeklyTxnAsync.when(
                    data: (weekly) => Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _SpendingCard(
                            transactions: weekly,
                            compact: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _BalanceCard(transactions: all, compact: true),
                        ),
                      ],
                    ),
                    loading: () => const _Shimmer(height: 190),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                  loading: () => const _Shimmer(height: 190),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ),
            ),
            */,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),

            // ── Upcoming reminders ─────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                child: upcomingRemindersAsync.when(
                  data: (r) => _RemindersCard(reminders: r),
                  loading: () => const _Shimmer(height: 90),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),

            // Adaptive GitHub-style completion history.
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                child: plannerEntriesAsync.when(
                  data: (tasks) => _HomeHeatmapCard(tasks: tasks),
                  loading: () => const _Shimmer(height: 155),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
          ],
        ),
      ),
    );
  }
}

class _HomeHeatmapCard extends StatelessWidget {
  const _HomeHeatmapCard({required this.tasks});
  final List<Task> tasks;

  @override
  Widget build(BuildContext context) {
    final today = _homeDateOnly(DateTime.now());
    final availableWidth = MediaQuery.sizeOf(context).width -
        AppSpacing.screenHorizontal * 2 -
        29;
    final weekCount = (availableWidth / 15).floor().clamp(13, 53).toInt();
    final firstMonday = today.subtract(
      Duration(days: today.weekday - 1 + (weekCount - 1) * 7),
    );
    final days = List.generate(
      weekCount * 7,
      (index) => firstMonday.add(Duration(days: index)),
    );
    final totals = <DateTime, int>{};
    final completed = <DateTime, int>{};
    for (final task in tasks) {
      final day = _homeDateOnly(task.dueDate);
      totals[day] = (totals[day] ?? 0) + 1;
      if (task.isCompleted) completed[day] = (completed[day] ?? 0) + 1;
    }

    final scoredDays = days.where((day) => !day.isAfter(today));
    final planned = scoredDays.fold<int>(
      0,
      (sum, day) => sum + (totals[day] ?? 0),
    );
    final done = scoredDays.fold<int>(
      0,
      (sum, day) => sum + (completed[day] ?? 0),
    );
    final average = planned == 0 ? 0 : (done / planned * 100).round();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 11),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.divider),
      ),
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
                      'Your planning rhythm at a glance',
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
                child: Text(
                  '$average%',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
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
                    weekCount,
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
                    Text('Mon', style: _homeHeatmapLabelStyle),
                    Text('Wed', style: _homeHeatmapLabelStyle),
                    Text('Fri', style: _homeHeatmapLabelStyle),
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
                      crossAxisCount: weekCount,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                    ),
                    itemCount: days.length,
                    itemBuilder: (_, index) {
                      final day = days[(index % 7) * weekCount + index ~/ 7];
                      final total = totals[day] ?? 0;
                      final ratio = total == 0
                          ? 0.0
                          : (completed[day] ?? 0) / total;
                      return DecoratedBox(
                        decoration: BoxDecoration(
                          color: _homeHeatColor(ratio, total, day.isAfter(today)),
                          borderRadius: BorderRadius.circular(3),
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
              const Text('Less', style: _homeHeatmapLabelStyle),
              const SizedBox(width: 5),
              ...[0.0, .25, .5, .75, 1.0].map(
                (ratio) => Padding(
                  padding: const EdgeInsets.only(left: 3),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _homeHeatColor(ratio, 1, false),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 5),
              const Text('More', style: _homeHeatmapLabelStyle),
            ],
          ),
        ],
      ),
    );
  }
}

const _homeHeatmapLabelStyle = TextStyle(
  fontFamily: 'Poppins',
  fontSize: 9,
  color: AppColors.textSecondary,
);

DateTime _homeDateOnly(DateTime date) =>
    DateTime(date.year, date.month, date.day);

Color _homeHeatColor(double ratio, int total, bool future) {
  if (future || total == 0 || ratio == 0) return AppColors.accentSoft;
  if (ratio < .25) return AppColors.accent.withAlpha(70);
  if (ratio < .5) return AppColors.accent.withAlpha(120);
  if (ratio < .75) return AppColors.accent.withAlpha(180);
  return AppColors.accent;
}

class _HomeContentGrid extends ConsumerWidget {
  const _HomeContentGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final tasks = ref.watch(todaysTasksProvider);
    final planner = ref.watch(
      tasksForDateProvider(DateTime(now.year, now.month, now.day)),
    );
    final weekly = ref.watch(thisWeeksTransactionsProvider);
    final all = ref.watch(allTransactionsProvider);

    return tasks.when(
      data: (taskItems) => planner.when(
        data: (plannerItems) => weekly.when(
          data: (weeklyItems) => all.when(
            data: (allItems) => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _TodayTasksCard(tasks: taskItems, compact: true),
                      const SizedBox(height: 10),
                      _SpendingCard(transactions: weeklyItems, compact: true),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    children: [
                      _PlannerPreviewCard(tasks: plannerItems, compact: true),
                      const SizedBox(height: 10),
                      _BalanceCard(transactions: allItems, compact: true),
                    ],
                  ),
                ),
              ],
            ),
            loading: () => const _Shimmer(height: 220),
            error: (_, _) => const SizedBox.shrink(),
          ),
          loading: () => const _Shimmer(height: 220),
          error: (_, _) => const SizedBox.shrink(),
        ),
        loading: () => const _Shimmer(height: 280),
        error: (_, _) => const SizedBox.shrink(),
      ),
      loading: () => const _Shimmer(height: 280),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.name,
    required this.role,
    required this.points,
  });

  final String name;
  final String role;
  final int points;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: .92, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: 164,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset('assets/profile/devraj.png', fit: BoxFit.cover),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withAlpha(180),
                      Colors.transparent,
                      AppColors.accent.withAlpha(90),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Welcome back, $name 👋',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      role,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: Colors.white.withAlpha(220),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(230),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: AppColors.textPrimary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('EEE, d MMM yyyy').format(DateTime.now()),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(Icons.chevron_right_rounded, size: 16),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(220),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 15,
                        color: AppColors.textPrimary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$points DIMI Points',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Dark stats card ───────────────────────────────────────────────────────────

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.todayProgress,
    required this.todayDone,
    required this.todayTotal,
    required this.weeklyGoal,
    required this.weeklySpent,
    required this.reminderCount,
  });

  final double todayProgress;
  final int todayDone;
  final int todayTotal;
  final int weeklyGoal;
  final double weeklySpent;
  final int reminderCount;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      color: AppColors.surfaceDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Three stat chips
          Row(
            children: [
              _StatChip(
                label: "Today's Progress",
                value: '${(todayProgress * 100).round()}%',
              ),
              const _VDiv(),
              _StatChip(
                label: 'Tasks Completed',
                value: '$todayDone/$todayTotal',
              ),
              const _VDiv(),
              _StatChip(label: 'Weekly Goal', value: '$weeklyGoal%'),
            ],
          ),
          const SizedBox(height: 14),
          DimiProgressBar(
            value: todayProgress,
            fillColor: AppColors.accent,
            height: 6,
          ),
          const SizedBox(height: 16),
          // Bottom icon-chip row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _IconStat(
                icon: Icons.check_circle_outline_rounded,
                label: 'Task',
                value: '$todayTotal',
              ),
              _IconStat(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Expense',
                value: '₹${_currencyFmt.format(weeklySpent)}',
              ),
              _IconStat(
                icon: Icons.notifications_outlined,
                label: 'Reminder',
                value: '$reminderCount',
              ),
              _IconStat(
                icon: Icons.calendar_today_outlined,
                label: 'Planner',
                value: '→',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.surface,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 9,
              color: AppColors.surface.withAlpha(180),
            ),
          ),
        ],
      ),
    );
  }
}

class _VDiv extends StatelessWidget {
  const _VDiv();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: AppColors.surface.withAlpha(40),
      margin: const EdgeInsets.symmetric(horizontal: 6),
    );
  }
}

class _IconStat extends StatelessWidget {
  const _IconStat({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.surface.withAlpha(180)),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.surface,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 9,
            color: AppColors.surface.withAlpha(140),
          ),
        ),
      ],
    );
  }
}

// ── Quick actions ─────────────────────────────────────────────────────────────

// Retained for reuse on another dashboard surface; the Home screen now uses
// inline actions inside each data card.
// ignore: unused_element
class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QATile(
            icon: Icons.check_rounded,
            label: 'Task',
            subtitle: 'Stay on track',
            color: AppColors.accent,
            onTap: () => showAddTaskSheet(context),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QATile(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Expense',
            subtitle: 'Track spending',
            color: AppColors.danger,
            onTap: () => showAddExpenseSheet(context),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QATile(
            icon: Icons.notifications_outlined,
            label: 'Reminder',
            subtitle: 'Never forget',
            color: AppColors.success,
            onTap: () => showAddReminderSheet(context),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QATile(
            icon: Icons.calendar_today_outlined,
            label: 'Planner',
            subtitle: 'Plan your day',
            color: AppColors.info,
            onTap: () => context.go(AppRoutes.planner),
          ),
        ),
      ],
    );
  }
}

class _QATile extends StatelessWidget {
  const _QATile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.subtitle,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 132,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 21, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 8,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Today's tasks card ────────────────────────────────────────────────────────

class _TodayTasksCard extends ConsumerWidget {
  const _TodayTasksCard({required this.tasks, this.compact = false});
  final List<Task> tasks;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dao = ref.read(taskDaoProvider);
    final done = tasks.where((t) => t.isCompleted).length;

    return SectionCard(
      padding: EdgeInsets.all(compact ? 8 : AppSpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "Today's Tasks",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: compact ? 10 : 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => context.go(AppRoutes.planner),
                child: Text(
                  '$done/${tasks.length} done',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: compact ? 7 : 12,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (tasks.isEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'All clear today 🎉',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            ...tasks.map(
              (t) => _MiniTaskRow(task: t, dao: dao, compact: compact),
            ),
            const SizedBox(height: 3),
            GestureDetector(
              onTap: () => showAddTaskSheet(context),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 8 : 14,
                  vertical: compact ? 8 : 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.add_rounded,
                      size: compact ? 16 : 20,
                      color: AppColors.textPrimary,
                    ),
                    SizedBox(width: compact ? 6 : 10),
                    Expanded(
                      child: Text(
                        'Add a new task',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: compact ? 9 : 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: compact ? 16 : 20,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniTaskRow extends StatelessWidget {
  const _MiniTaskRow({
    required this.task,
    required this.dao,
    this.compact = false,
  });
  final Task task;
  final dynamic dao;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 5 : 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => dao.toggleCompleted(task.id, !task.isCompleted),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: compact ? 16 : 20,
              height: compact ? 16 : 20,
              decoration: BoxDecoration(
                color: task.isCompleted ? AppColors.accent : Colors.transparent,
                border: Border.all(
                  color: task.isCompleted
                      ? AppColors.accent
                      : AppColors.textSecondary,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: task.isCompleted
                  ? const Icon(
                      Icons.check_rounded,
                      size: 12,
                      color: AppColors.surface,
                    )
                  : null,
            ),
          ),
          SizedBox(width: compact ? 5 : 10),
          Expanded(
            child: Text(
              task.title,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: compact ? 10 : 13,
                color: task.isCompleted
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
                decoration: task.isCompleted
                    ? TextDecoration.lineThrough
                    : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!compact && task.dueTime != null)
            Text(
              formatTime12Hour(task.dueTime),
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Weekly spending card ──────────────────────────────────────────────────────

class _PlannerPreviewCard extends StatelessWidget {
  const _PlannerPreviewCard({required this.tasks, this.compact = false});
  final List<Task> tasks;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final sorted = [...tasks]
      ..sort((a, b) => (a.dueTime ?? '99:99').compareTo(b.dueTime ?? '99:99'));
    return SectionCard(
      padding: EdgeInsets.all(compact ? 8 : AppSpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Today · ${DateFormat('d MMM').format(DateTime.now())}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: compact ? 11 : 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 18),
            ],
          ),
          const SizedBox(height: 10),
          if (sorted.isEmpty)
            Text(
              'Nothing planned today',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: compact ? 9 : 11,
                color: AppColors.textSecondary,
              ),
            )
          else
            ...sorted.map(
              (task) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: compact ? 31 : 52,
                      child: Text(
                        formatTime12Hour(task.dueTime),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: compact ? 8 : 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    SizedBox(width: compact ? 3 : 8),
                    Container(
                      width: 3,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _plannerColor(task.category),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    SizedBox(width: compact ? 3 : 8),
                    Expanded(
                      child: Text(
                        task.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: compact ? 9 : 11,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => context.go(AppRoutes.planner),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text(
                  'Open Planner  ›',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _plannerColor(String category) => switch (category.toLowerCase()) {
    'college' => const Color(0xFF4A90D9),
    'study' => AppColors.accent,
    'health' => AppColors.danger,
    'personal' => AppColors.success,
    _ => AppColors.textSecondary,
  };
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.transactions, this.compact = false});
  final List<MoneyTransaction> transactions;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final expenses = transactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);
    final income = transactions
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);
    final loans = transactions
        .where((t) => t.type == 'loan')
        .fold(0.0, (sum, t) => sum + t.amount);
    final balance = income - expenses;

    return SectionCard(
      padding: EdgeInsets.all(compact ? 8 : AppSpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: compact ? 16 : 20,
              ),
              SizedBox(width: compact ? 4 : 8),
              Expanded(
                child: Text(
                  'Current Balance',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: compact ? 10 : 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: compact ? 15 : 18),
            ],
          ),
          SizedBox(height: compact ? 5 : 8),
          Text(
            '₹${_currencyFmt.format(balance)}',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: compact ? 17 : 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: compact ? 10 : 14),
          Row(
            children: [
              Expanded(
                child: _BalanceMetric(
                  value: '₹${_currencyFmt.format(expenses)}',
                  label: 'Total Expenses',
                  color: AppColors.success,
                  compact: compact,
                ),
              ),
              SizedBox(width: compact ? 5 : 8),
              Expanded(
                child: _BalanceMetric(
                  value: '₹${_currencyFmt.format(loans)}',
                  label: 'Loans',
                  color: AppColors.danger,
                  compact: compact,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceMetric extends StatelessWidget {
  const _BalanceMetric({
    required this.value,
    required this.label,
    required this.color,
    this.compact = false,
  });
  final String value;
  final String label;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(compact ? 6 : 9),
    decoration: BoxDecoration(
      color: color.withAlpha(24),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: compact ? 10 : 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 9,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    ),
  );
}

class _SpendingCard extends StatelessWidget {
  const _SpendingCard({required this.transactions, this.compact = false});
  final List<MoneyTransaction> transactions;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    // Build per-weekday buckets (0=Mon … 6=Sun)
    final dayAmounts = List.filled(7, 0.0);
    for (final t in transactions) {
      if (t.type == 'expense') {
        // weekday: 1=Mon … 7=Sun → index 0–6
        dayAmounts[t.date.weekday - 1] += t.amount;
      }
    }
    final maxAmt = dayAmounts.reduce((a, b) => a > b ? a : b);
    final todayIdx = DateTime.now().weekday - 1;
    final totalSpent = dayAmounts.fold(0.0, (a, b) => a + b);
    final todaySpent = transactions
        .where(
          (t) =>
              t.type == 'expense' &&
              t.date.year == DateTime.now().year &&
              t.date.month == DateTime.now().month &&
              t.date.day == DateTime.now().day,
        )
        .fold(0.0, (sum, t) => sum + t.amount);
    final weeklyIncome = transactions
        .where((t) => t.type == 'income')
        .fold(0.0, (s, t) => s + t.amount);

    return SectionCard(
      padding: EdgeInsets.all(compact ? 8 : AppSpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                compact ? 'Spending' : 'Spending This Week',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: compact ? 13 : 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () => context.go(AppRoutes.money),
                child: Text(
                  compact ? '›' : 'View All',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: compact ? 16 : 12,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${_currencyFmt.format(todaySpent)}',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: compact ? 20 : 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              if (!compact && weeklyIncome > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withAlpha(26),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${(todaySpent / weeklyIncome * 100).toStringAsFixed(0)}% of income',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            "This week's spending ₹${_currencyFmt.format(totalSpent)}",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: compact ? 9 : 11,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: compact ? 8 : 14),
          if (maxAmt <= 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  'No spending recorded this week',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: compact ? 60 : 90,
              child: _HomeBarChart(
                dayAmounts: dayAmounts,
                maxAmt: maxAmt,
                todayIdx: todayIdx,
                compact: compact,
              ),
            ),
        ],
      ),
    );
  }
}

class _HomeBarChart extends StatelessWidget {
  const _HomeBarChart({
    required this.dayAmounts,
    required this.maxAmt,
    required this.todayIdx,
    this.compact = false,
  });
  final List<double> dayAmounts;
  final double maxAmt;
  final int todayIdx;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxAmt * 1.35,
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 18,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: compact ? 8 : 10,
                      fontWeight: i == todayIdx
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: i == todayIdx
                          ? AppColors.accent
                          : AppColors.textSecondary,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: List.generate(7, (i) {
          final amt = dayAmounts[i];
          final isToday = i == todayIdx;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: amt <= 0 ? 1 : amt,
                color: isToday ? AppColors.accent : AppColors.accentSoft,
                width: compact ? 7 : 14,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(5),
                ),
              ),
            ],
            showingTooltipIndicators: const [],
          );
        }),
        barTouchData: BarTouchData(enabled: false),
      ),
    );
  }
}

// ── Upcoming reminders card ───────────────────────────────────────────────────

class _RemindersCard extends StatelessWidget {
  const _RemindersCard({required this.reminders});
  final List<Reminder> reminders;

  @override
  Widget build(BuildContext context) {
    final upcoming = reminders
        .where((r) => r.isEnabled && r.dueAt.isAfter(DateTime.now()))
        .take(3)
        .toList();

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Upcoming Reminders',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              GestureDetector(
                onTap: () => context.go(AppRoutes.reminders),
                child: const Text(
                  'View All',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
          if (upcoming.isEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'No upcoming reminders',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            ...upcoming.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_active_outlined,
                        size: 16,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        r.title,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      DateFormat('d MMM · h:mm a').format(r.dueAt),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _HomeHeaderButton extends StatelessWidget {
  const _HomeHeaderButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.divider),
        ),
        child: Icon(icon, size: 22, color: AppColors.textPrimary),
      ),
    );
  }
}

class _Shimmer extends StatelessWidget {
  const _Shimmer({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.divider),
      ),
    );
  }
}
