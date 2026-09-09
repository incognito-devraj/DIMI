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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: const Text(
                              'DIMI',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _IconBtn(icon: Icons.search_rounded, onTap: () {}),
                    const SizedBox(width: 8),
                    _IconBtn(
                      icon: Icons.settings_outlined,
                      onTap: () => context.push(AppRoutes.settings),
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
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),

            // ── Quick actions ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                child: _QuickActions(),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),

            // ── Today's tasks ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                child: todaysTasksAsync.when(
                  data: (t) => _TodayTasksCard(tasks: t),
                  loading: () => const _Shimmer(height: 130),
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
                child: weeklyTxnAsync.when(
                  data: (t) => _SpendingCard(transactions: t),
                  loading: () => const _Shimmer(height: 160),
                  error: (_, _) => const SizedBox.shrink(),
                ),
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
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
          ],
        ),
      ),
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
  });

  final double todayProgress;
  final int todayDone;
  final int todayTotal;
  final int weeklyGoal;
  final double weeklySpent;

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
                // resolved in parent; pass placeholder — card reads provider
                value: '—',
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

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.cardPadding,
        vertical: 14,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _QATile(
            icon: Icons.check_rounded,
            label: 'Task',
            color: AppColors.accent,
            onTap: () => showAddTaskSheet(context),
          ),
          _QATile(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Expense',
            color: AppColors.danger,
            onTap: () => showAddExpenseSheet(context),
          ),
          _QATile(
            icon: Icons.notifications_outlined,
            label: 'Reminder',
            color: AppColors.success,
            onTap: () => showAddReminderSheet(context),
          ),
          _QATile(
            icon: Icons.calendar_today_outlined,
            label: 'Planner',
            color: AppColors.info,
            onTap: () => context.go(AppRoutes.planner),
          ),
        ],
      ),
    );
  }
}

class _QATile extends StatelessWidget {
  const _QATile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Today's tasks card ────────────────────────────────────────────────────────

class _TodayTasksCard extends ConsumerWidget {
  const _TodayTasksCard({required this.tasks});
  final List<Task> tasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dao = ref.read(taskDaoProvider);
    final done = tasks.where((t) => t.isCompleted).length;
    final pending = tasks.where((t) => !t.isCompleted).toList();

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's Tasks",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              GestureDetector(
                onTap: () => context.go(AppRoutes.planner),
                child: Text(
                  '$done/${tasks.length} done',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
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
            ...pending.take(4).map((t) => _MiniTaskRow(task: t, dao: dao)),
            if (pending.length > 4)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '+ ${pending.length - 4} more tasks',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: AppColors.textSecondary,
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
  const _MiniTaskRow({required this.task, required this.dao});
  final Task task;
  final dynamic dao;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => dao.toggleCompleted(task.id, !task.isCompleted),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 20,
              height: 20,
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
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              task.title,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
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
          if (task.dueTime != null)
            Text(
              task.dueTime!,
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

class _SpendingCard extends StatelessWidget {
  const _SpendingCard({required this.transactions});
  final List<MoneyTransaction> transactions;

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
    final weeklyIncome = transactions
        .where((t) => t.type == 'income')
        .fold(0.0, (s, t) => s + t.amount);

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spending This Week',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              GestureDetector(
                onTap: () => context.go(AppRoutes.money),
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
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${_currencyFmt.format(totalSpent)}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              if (weeklyIncome > 0)
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
                      '${(totalSpent / weeklyIncome * 100).toStringAsFixed(0)}% of income',
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
          const Text(
            'Spent This Week',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
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
              height: 90,
              child: _HomeBarChart(
                dayAmounts: dayAmounts,
                maxAmt: maxAmt,
                todayIdx: todayIdx,
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
  });
  final List<double> dayAmounts;
  final double maxAmt;
  final int todayIdx;

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
                      fontSize: 10,
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
                width: 14,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(5),
                ),
              ),
            ],
            showingTooltipIndicators: isToday && amt > 0 ? [0] : [],
          );
        }),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.surfaceDark,
            getTooltipItem: (group, _, rod, _) => BarTooltipItem(
              '₹${dayAmounts[group.x].toStringAsFixed(0)}',
              const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.surface,
              ),
            ),
          ),
        ),
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

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
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
