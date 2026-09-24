import 'package:fl_chart/fl_chart.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/database.dart';
import '../../data/daos/money_dao.dart';
import '../../providers/money_providers.dart';
import '../../providers/transaction_detection_providers.dart';
import '../../providers/database_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/dimi_add_action_button.dart';
import '../../core/motion/dimi_motion.dart';
import '../../widgets/pill_segmented_control.dart';
import '../../widgets/section_card.dart';
import '../../widgets_modals/add_expense_sheet.dart';

const _kTabs = ['Overview', 'Transactions', 'Categories'];
const _allMoneyCategories = [
  'Sundries',
  'Grocery',
  'Food & Dining',
  'Transport',
  'Shopping',
  'Entertainment',
  'Health',
  'Education',
  'Utilities',
  'Allowance',
  'Salary',
  'Freelance',
  'Gift',
  'Lent',
  'Borrowed',
  'Other',
];

// Currency formatter — ₹
final _fmt = NumberFormat('#,##0.00', 'en_IN');

double _moneyMajorAmount(int amountMinor) => amountMinor / 100.0;

class MoneyScreen extends ConsumerStatefulWidget {
  const MoneyScreen({super.key});

  @override
  ConsumerState<MoneyScreen> createState() => _MoneyScreenState();
}

class _MoneyScreenState extends ConsumerState<MoneyScreen> {
  int _tabIndex = 0;
  bool _showAddButton = true;
  String? _categoryFilter;
  String _searchQuery = '';

  Future<void> _openSearch() async {
    final controller = TextEditingController(text: _searchQuery);
    final query = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Search expenses'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Search by description or category',
            prefixIcon: Icon(Icons.search_rounded),
          ),
          onSubmitted: (value) => Navigator.pop(dialogContext, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Search'),
          ),
        ],
      ),
    );
    // The dialog route can still be detaching its TextField when the future
    // completes. Dispose on the next frame so Flutter has released the
    // controller's dependents first.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.dispose();
    });
    if (query != null && mounted) setState(() => _searchQuery = query);
  }

  Future<void> _openFilter(List<String> categories) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Filter expenses',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _FilterChip(
                    label: 'All categories',
                    selected: _categoryFilter == null,
                    onTap: () => Navigator.pop(sheetContext, ''),
                  ),
                  ...categories.map(
                    (category) => _FilterChip(
                      label: category,
                      selected: _categoryFilter == category,
                      onTap: () => Navigator.pop(sheetContext, category),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (selected != null && mounted) {
      setState(() => _categoryFilter = selected.isEmpty ? null : selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allAsync = ref.watch(allTransactionsProvider);
    final weeklyAsync = ref.watch(thisWeeksTransactionsProvider);
    final allLoansAsync = ref.watch(allTransactionsProvider);
    final expensesAsync = ref.watch(transactionsByTypeProvider('expense'));

    // Which list to show
    final listAsync = _tabIndex == 1 ? expensesAsync : allAsync;

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
                    'Finance',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Filter finance',
                    onPressed: () {
                      final categories = {
                        ..._allMoneyCategories,
                        ...allAsync.maybeWhen(
                          data: (items) => items
                              .map((item) => item.category)
                              .toSet(),
                          orElse: () => <String>{},
                        ),
                      }.toList()..sort();
                      _openFilter(categories);
                    },
                    icon: const Icon(
                      Icons.bar_chart_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Search finance',
                    onPressed: _openSearch,
                    icon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.textSecondary,
                    ),
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
              child: SizedBox(
                width: double.infinity,
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
                  const _DetectedTransactionsPanel(),
                  const SizedBox(height: 8),
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

                  if (_tabIndex == 2)
                    allAsync.when(
                      data: (transactions) => _CategorySpendGridV2(
                        transactions: transactions,
                      ),
                      loading: () => const _SkeletonCard(height: 180),
                      error: (_, _) => const SizedBox.shrink(),
                    )
                  else ...[
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
                      final query = _searchQuery.toLowerCase();
                      final filtered = txns.where((txn) {
                        final matchesCategory = _categoryFilter == null ||
                            txn.category == _categoryFilter;
                        final matchesSearch = query.isEmpty ||
                            txn.category.toLowerCase().contains(query) ||
                            (txn.note?.toLowerCase().contains(query) ?? false);
                        return matchesCategory && matchesSearch;
                      }).toList();
                      final list = _tabIndex == 0
                          ? filtered.take(20).toList()
                          : filtered;
                      if (list.isEmpty) {
                        return const EmptyState(
                          icon: Icons.account_balance_wallet_outlined,
                          title: 'No transactions yet',
                          subtitle: 'Tap + to add one.',
                          asset: 'assets/illustrations/Finance.png',
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
                  SizedBox(height: _showAddButton ? 80 : 0), // FAB clearance
                  ],
                ],
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
              label: 'Add Transaction',
              icon: Icons.currency_rupee_rounded,
              onPressed: () => showAddExpenseSheet(context),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _DetectedTransactionsPanel extends ConsumerWidget {
  const _DetectedTransactionsPanel();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingTransactionCandidatesProvider).valueOrNull ?? const <TransactionCandidate>[];
    if (pending.isEmpty) return const SizedBox.shrink();
    final db = ref.read(databaseProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
      child: Card(
        elevation: 0,
        color: AppColors.surface,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('New Transactions Detected', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ...pending.take(3).map((candidate) => ListTile(contentPadding: EdgeInsets.zero, title: Text(candidate.merchantName), subtitle: Text('₹${(candidate.amountMinor / 100).toStringAsFixed(2)} · ${candidate.category} · ${candidate.paymentMethod ?? candidate.source}'), trailing: Wrap(spacing: 4, children: [IconButton(tooltip: 'Ignore', icon: const Icon(Icons.close_rounded), onPressed: () => db.transactionDetectionDao.updateStatus(candidate.candidateId, 'IGNORED')), IconButton(tooltip: 'Add', icon: const Icon(Icons.check_rounded), onPressed: () async { final isIncome = candidate.transactionType == 'INCOME'; await db.moneyDao.insertTransaction(MoneyTransactionsCompanion.insert(type: isIncome ? 'income' : 'expense', amount: candidate.amountMinor, category: candidate.category, note: Value('${candidate.merchantName} · Detected automatically'), date: candidate.occurredAt)); await db.transactionDetectionDao.updateStatus(candidate.candidateId, 'CONFIRMED'); })]))),
          ]),
        ),
      ),
    );
  }
}

// ── Summary cards ─────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: DimiMotion.fast,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.textPrimary : AppColors.background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.textPrimary : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.surface : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _CategorySpendGridV2 extends StatelessWidget {
  const _CategorySpendGridV2({required this.transactions});
  final List<MoneyTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    final totals = <String, double>{};
    for (final transaction in transactions) {
      if (transaction.type == 'expense') {
        totals.update(transaction.category, (value) => value + _moneyMajorAmount(transaction.amount),
            ifAbsent: () => _moneyMajorAmount(transaction.amount));
      }
    }
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = (constraints.maxWidth - 16) / 3;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: entries.map((entry) => SizedBox(
              width: width,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(_categoryIcon(entry.key), size: 17, color: AppColors.accent),
                    ),
                    const SizedBox(height: 7),
                    Text(entry.key, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    Text(_formatMoney(entry.value), maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.danger)),
                  ],
                ),
              ),
            )).toList(),
          );
        },
      ),
    );
  }

  static IconData _categoryIcon(String category) => financeCategoryIcon(category);

  static String _formatMoney(double amount) {
    final value = amount == amount.roundToDouble()
        ? NumberFormat('#,##0', 'en_IN').format(amount)
        : _fmt.format(amount);
    return '₹$value';
  }
}

class _CategorySpendGrid extends StatelessWidget {
  const _CategorySpendGrid({required this.transactions});
  final List<MoneyTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    final totals = <String, double>{};
    for (final transaction in transactions) {
      if (transaction.type == 'expense') {
        totals.update(
          transaction.category,
          (value) => value + _moneyMajorAmount(transaction.amount),
          ifAbsent: () => _moneyMajorAmount(transaction.amount),
        );
      }
    }
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Spending by category',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          if (entries.isEmpty)
            const SectionCard(
              child: Text(
                'No expense categories yet',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entries.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.7,
              ),
              itemBuilder: (context, index) {
                final entry = entries[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        entry.key,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '₹${_fmt.format(entry.value)}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

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
        .fold(0.0, (s, t) => s + _moneyMajorAmount(t.amount));
    final income = allTransactions
        .where((t) => t.type == 'income')
        .fold(0.0, (s, t) => s + _moneyMajorAmount(t.amount));
    final lent = allLoans.where((t) => t.type == 'lent')
        .fold(0.0, (s, t) => s + _moneyMajorAmount(t.amount));
    final borrowed = allLoans.where((t) => t.type == 'borrowed')
        .fold(0.0, (s, t) => s + _moneyMajorAmount(t.amount));
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
              SizedBox(
                width: double.infinity,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '₹${_fmt.format(balance)}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _BalanceStat(
                      icon: Icons.arrow_upward_rounded,
                      label: 'Total Spent',
                      value: '₹${_fmt.format(spent)}',
                      color: AppColors.danger,
                    ),
                  ),
                  Expanded(
                    child: _BalanceStat(
                      icon: Icons.arrow_downward_rounded,
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
      Expanded(
        child: Column(
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
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          ],
        ),
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
        Expanded(
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
            SizedBox(
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '₹${_fmt.format(value)}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            ],
          ),
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
        .fold(0.0, (s, t) => s + _moneyMajorAmount(t.amount));
    final income = weeklyTransactions
        .where((t) => t.type == 'income')
        .fold(0.0, (s, t) => s + _moneyMajorAmount(t.amount));
    final lent = allLoans.fold(0.0, (s, t) => s + _moneyMajorAmount(t.amount));

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
        dayAmounts[t.date.weekday - 1] += _moneyMajorAmount(t.amount);
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
      onTap: () => _showDetails(context, color, icon),
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
                    txn.note?.trim().isNotEmpty == true
                        ? txn.note!
                        : txn.category,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    softWrap: true,
                  ),
                  Text(
                    '${txn.category} · ${DateFormat('d MMM yyyy').format(txn.date)}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Amount + date
            SizedBox(
              width: 145,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    '$sign₹${_fmt.format(_moneyMajorAmount(txn.amount))}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
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
            ),
          ],
        ),
      ),
    );
  }

  (Color, IconData) _typeStyle(String type) => switch (type) {
    'income' => (AppColors.success, Icons.arrow_downward_rounded),
    'lent' || 'borrowed' => (AppColors.info, Icons.swap_horiz_rounded),
    _ => (AppColors.danger, Icons.arrow_upward_rounded),
  };

  Future<void> _showDetails(BuildContext context, Color color, IconData icon) {
    final isIncome = txn.type == 'income';
    final sign = isIncome ? '+' : txn.type == 'expense' ? '-' : '';
    final description = txn.note?.trim().isNotEmpty == true
        ? txn.note!.trim()
        : 'No description added';
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
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
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: color.withAlpha(28),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(dialogContext),
                    icon: const Icon(Icons.close_rounded),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                '$sign${_fmt.format(_moneyMajorAmount(txn.amount))}',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: color,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                txn.type == 'income' ? 'Income' : txn.type == 'lent' ? 'Lent' : txn.type == 'borrowed' ? 'Borrowed' : 'Expense',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 22),
              _DetailRow(label: 'Category', value: txn.category, icon: Icons.sell_outlined),
              const SizedBox(height: 14),
              _DetailRow(label: 'Date and time', value: DateFormat('EEEE, d MMM yyyy · h:mm a').format(txn.date), icon: Icons.calendar_today_outlined),
              const SizedBox(height: 14),
              _DetailRow(label: 'Description', value: description, icon: Icons.notes_rounded),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.textPrimary,
                    foregroundColor: AppColors.surface,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Done', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, MoneyDao dao) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Are you sure?',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        content: Text('Remove this ${txn.type} of ₹${_fmt.format(_moneyMajorAmount(txn.amount))}?'),
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 18, color: AppColors.textSecondary),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          ],
        ),
      ),
    ],
  );
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
