import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/database.dart';
import '../../data/daos/money_dao.dart';
import '../../providers/money_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/pill_segmented_control.dart';
import '../../widgets_modals/add_expense_sheet.dart';

const _kTabs = ['Overview', 'Transactions', 'Categories'];

// Currency formatter — ₹
final _fmt = NumberFormat('#,##0.00', 'en_IN');

class MoneyScreen extends ConsumerStatefulWidget {
  const MoneyScreen({super.key});

  @override
  ConsumerState<MoneyScreen> createState() => _MoneyScreenState();
}

class _MoneyScreenState extends ConsumerState<MoneyScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final allAsync = ref.watch(allTransactionsProvider);
    final weeklyAsync = ref.watch(thisWeeksTransactionsProvider);
    final allLoansAsync = ref.watch(transactionsByTypeProvider('loan'));
    final expensesAsync = ref.watch(transactionsByTypeProvider('expense'));

    // Which list to show
    final listAsync = _tabIndex == 1 ? expensesAsync : allAsync;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── App bar ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                20,
                AppSpacing.screenHorizontal,
                0,
              ),
              child: Row(
                children: [
                  const Text(
                    'Expense',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.bar_chart_rounded,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Tabs ──────────────────────────────────────────────────
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
            const SizedBox(height: 12),

            // ── Content ───────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Summary cards (visible on all tabs)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenHorizontal,
                    ),
                    child: weeklyAsync.when(
                      data: (weeklyTxns) => allAsync.when(
                        data: (allTxns) => allLoansAsync.when(
                          data: (allLoans) => _ExpenseSummaryCards(
                            weeklyTransactions: weeklyTxns,
                            allTransactions: allTxns,
                            allLoans: allLoans,
                          ),
                          loading: () => _ExpenseSummaryCards(
                            weeklyTransactions: weeklyTxns,
                            allTransactions: allTxns,
                            allLoans: const [],
                          ),
                          error: (_, _) => _ExpenseSummaryCards(
                            weeklyTransactions: weeklyTxns,
                            allTransactions: allTxns,
                            allLoans: const [],
                          ),
                        ),
                        loading: () => const _SkeletonCard(height: 270),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                      loading: () => const _SkeletonCard(height: 88),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Transaction list header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenHorizontal,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _tabIndex == 0
                              ? 'Recent Transactions'
                              : _kTabs[_tabIndex],
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Transaction list
                  listAsync.when(
                    data: (txns) {
                      final list = _tabIndex == 0
                          ? txns.take(20).toList()
                          : txns;
                      if (list.isEmpty) {
                        return const EmptyState(
                          icon: Icons.account_balance_wallet_outlined,
                          title: 'No transactions yet',
                          subtitle: 'Tap + to add one.',
                        );
                      }
                      return Column(
                        children: list
                            .map(
                              (t) => Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  AppSpacing.screenHorizontal,
                                  0,
                                  AppSpacing.screenHorizontal,
                                  8,
                                ),
                                child: _TransactionTile(txn: t),
                              ),
                            )
                            .toList(),
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenHorizontal,
                      ),
                      child: _SkeletonCard(height: 60),
                    ),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),
                  const SizedBox(height: 80), // FAB clearance
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddExpenseSheet(context),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.surface,
        elevation: 2,
        child: const Icon(Icons.add_rounded, size: 24),
      ),
    );
  }
}

// ── Summary cards ─────────────────────────────────────────────────────────────

class _ExpenseSummaryCards extends StatelessWidget {
  const _ExpenseSummaryCards({
    required this.weeklyTransactions,
    required this.allTransactions,
    required this.allLoans,
  });
  final List<MoneyTransaction> weeklyTransactions;
  final List<MoneyTransaction> allTransactions;
  final List<MoneyTransaction> allLoans;
  @override
  Widget build(BuildContext context) {
    final spent = allTransactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (s, t) => s + t.amount);
    final income = allTransactions
        .where((t) => t.type == 'income')
        .fold(0.0, (s, t) => s + t.amount);
    final lent = allLoans
        .where((t) => t.category == 'Lent')
        .fold(0.0, (s, t) => s + t.amount);
    final borrowed = allLoans
        .where((t) => t.category == 'Borrowed')
        .fold(0.0, (s, t) => s + t.amount);
    final balance = income - spent + lent - borrowed;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 17),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Available Balance',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.visibility_outlined,
                    size: 20,
                    color: Colors.white70,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '₹${_fmt.format(balance)}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _BalanceStat(
                      icon: Icons.arrow_downward_rounded,
                      label: 'Total Spent',
                      value: '₹${_fmt.format(spent)}',
                      color: AppColors.danger,
                    ),
                  ),
                  Expanded(
                    child: _BalanceStat(
                      icon: Icons.arrow_upward_rounded,
                      label: 'Total Income',
                      value: '₹${_fmt.format(income)}',
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _LoanCard(
                label: 'Lent Money',
                value: lent,
                icon: Icons.person_outline_rounded,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _LoanCard(
                label: 'Borrowed',
                value: borrowed,
                icon: Icons.account_balance_wallet_outlined,
                color: AppColors.danger,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BalanceStat extends StatelessWidget {
  const _BalanceStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: color, size: 26),
      const SizedBox(width: 8),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: Colors.white70,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    ],
  );
}

class _LoanCard extends StatelessWidget {
  const _LoanCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final double value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.divider),
    ),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 19, color: color),
        ),
        const SizedBox(width: 9),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '₹${_fmt.format(value)}',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

// ignore: unused_element
class _SummaryCards extends StatelessWidget {
  const _SummaryCards({
    required this.weeklyTransactions,
    required this.allLoans,
  });
  final List<MoneyTransaction> weeklyTransactions;
  final List<MoneyTransaction> allLoans;

  @override
  Widget build(BuildContext context) {
    final spent = weeklyTransactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (s, t) => s + t.amount);
    final income = weeklyTransactions
        .where((t) => t.type == 'income')
        .fold(0.0, (s, t) => s + t.amount);
    final lent = allLoans.fold(0.0, (s, t) => s + t.amount);

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'Spent This Week',
            value: '₹${_fmt.format(spent)}',
            sub: income > 0
                ? '${((spent / income) * 100).toStringAsFixed(0)}% of income'
                : null,
            color: AppColors.danger,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            label: 'Lent Money',
            value: '₹${_fmt.format(lent)}',
            sub: allLoans.isNotEmpty ? '${allLoans.length} pending' : null,
            color: AppColors.info,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    this.sub,
  });
  final String label;
  final String value;
  final String? sub;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          if (sub != null)
            Text(
              sub!,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Weekly spending bar chart ─────────────────────────────────────────────────

// ignore: unused_element
class _SpendingChart extends StatelessWidget {
  const _SpendingChart({required this.transactions});
  final List<MoneyTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    // Day buckets for expense type only
    final dayAmounts = List.filled(7, 0.0);
    for (final t in transactions) {
      if (t.type == 'expense') {
        dayAmounts[t.date.weekday - 1] += t.amount;
      }
    }
    final maxAmt = dayAmounts.reduce((a, b) => a > b ? a : b);
    final todayIdx = DateTime.now().weekday - 1;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Spending This Week',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          if (maxAmt <= 0)
            SizedBox(
              height: 80,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.bar_chart_rounded,
                      size: 28,
                      color: AppColors.accentSoft,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'No spending this week',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 80,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxAmt <= 0 ? 100 : maxAmt * 1.35,
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 18,
                        getTitlesWidget: (v, _) {
                          const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
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
                          color: isToday
                              ? AppColors.accent
                              : AppColors.accentSoft,
                          width: 14,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(5),
                          ),
                        ),
                      ],
                    );
                  }),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => AppColors.surfaceDark,
                      getTooltipItem: (group, _, rod, ignored) {
                        final amt = dayAmounts[group.x];
                        return BarTooltipItem(
                          '₹${amt.toStringAsFixed(0)}',
                          const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.surface,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Transaction tile ──────────────────────────────────────────────────────────

class _TransactionTile extends ConsumerWidget {
  const _TransactionTile({required this.txn});
  final MoneyTransaction txn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dao = ref.read(moneyDaoProvider);
    final (color, icon) = _typeStyle(txn.type);
    final sign = txn.type == 'expense' ? '-' : '+';

    return GestureDetector(
      onLongPress: () => _confirmDelete(context, dao),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            // Category icon circle
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 10),
            // Category + note
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    txn.category,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    txn.note ?? DateFormat('d MMM yyyy').format(txn.date),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Amount + date
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$sign₹${_fmt.format(txn.amount)}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                Text(
                  DateFormat('d MMM').format(txn.date),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
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

  (Color, IconData) _typeStyle(String type) => switch (type) {
    'income' => (AppColors.success, Icons.arrow_downward_rounded),
    'loan' => (AppColors.info, Icons.swap_horiz_rounded),
    _ => (AppColors.danger, Icons.arrow_upward_rounded),
  };

  Future<void> _confirmDelete(BuildContext context, MoneyDao dao) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete transaction?',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        content: Text('Remove this ${txn.type} of ₹${txn.amount}?'),
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
    if (ok == true) await dao.deleteTransaction(txn.id);
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.height});
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
