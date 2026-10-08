import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/database.dart';
import '../../data/daos/money_dao.dart';
import '../../providers/money_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/dimi_add_action_button.dart';
import '../../widgets/dimi_action_dialog.dart';
import '../../core/motion/dimi_motion.dart';
import '../../widgets/pill_segmented_control.dart';
import '../../widgets/section_card.dart';
import '../../widgets_modals/add_expense_sheet.dart';

const _kTabs = ['Wallet', 'Transactions', 'Overview'];
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

List<MoneyTransaction> _activeTransactionsOfType(
  List<MoneyTransaction> transactions,
  String type,
) => transactions.where((transaction) => transaction.type == type).toList();

double _totalForTransactions(List<MoneyTransaction> transactions) =>
    transactions.fold(0.0, (sum, transaction) {
      return sum + _moneyMajorAmount(transaction.amount);
    });

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
  String _transactionTypeFilter = 'all';
  DateTime? _transactionMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );
  bool _sortAscending = false;

  Future<void> _openSearch() async {
    final controller = TextEditingController(text: _searchQuery);
    final query = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Search transactions'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Search notes, categories, people, or dates',
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

  Future<void> _openMonthSelector() async {
    final now = DateTime.now();
    final months = List.generate(
      12,
      (index) => DateTime(now.year, now.month - index),
    );
    final selected = await showModalBottomSheet<DateTime?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _FinancePickerSheet<DateTime?>(
        title: 'Date period',
        selected: _transactionMonth,
        items: [null, ...months],
        label: (month) =>
            month == null ? 'All dates' : DateFormat('MMM yyyy').format(month),
        onSelected: (value) =>
            Navigator.pop(sheetContext, value ?? DateTime(1900)),
      ),
    );
    if (selected != null && mounted) {
      setState(
        () => _transactionMonth = selected.year == 1900 ? null : selected,
      );
    }
  }

  Future<void> _openSortSelector() async {
    final selected = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _FinancePickerSheet<bool>(
        title: 'Sort transactions',
        selected: _sortAscending,
        items: const [false, true],
        label: (ascending) => ascending ? 'Oldest first' : 'Latest first',
        onSelected: (value) => Navigator.pop(sheetContext, value),
      ),
    );
    if (selected != null && mounted) {
      setState(() => _sortAscending = selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allAsync = ref.watch(allTransactionsProvider);

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
                            data: (items) =>
                                items.map((item) => item.category).toSet(),
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
              if (_tabIndex == 1)
                _TransactionFilterToolbar(
                  selectedType: _transactionTypeFilter,
                  selectedMonth: _transactionMonth,
                  sortAscending: _sortAscending,
                  onTypeSelected: (type) =>
                      setState(() => _transactionTypeFilter = type),
                  onMonthTap: _openMonthSelector,
                  onSortTap: _openSortSelector,
                ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    allAsync.when(
                      data: (transactions) => switch (_tabIndex) {
                        0 => _WalletContent(
                          transactions: transactions,
                          onSeeAll: () => setState(() => _tabIndex = 1),
                        ),
                        1 => _TransactionsContent(
                          transactions: transactions,
                          categoryFilter: _categoryFilter,
                          searchQuery: _searchQuery,
                          typeFilter: _transactionTypeFilter,
                          selectedMonth: _transactionMonth,
                          sortAscending: _sortAscending,
                        ),
                        _ => _OverviewContent(transactions: transactions),
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenHorizontal,
                        ),
                        child: _SkeletonCard(height: 270),
                      ),
                      error: (error, _) => Center(child: Text('Error: $error')),
                    ),
                    SizedBox(height: _showAddButton ? 80 : 0),
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

String _formatFinanceAmount(double amount) {
  final prefix = amount < 0 ? '-' : '+';
  return '$prefix₹${_formatAbsoluteFinanceAmount(amount)}';
}

String _formatAbsoluteFinanceAmount(double amount) {
  final absolute = amount.abs();
  final formatted = absolute == absolute.roundToDouble()
      ? NumberFormat('#,##0', 'en_IN').format(absolute)
      : _fmt.format(absolute);
  return formatted;
}

class _FinanceAmountText extends StatelessWidget {
  const _FinanceAmountText({
    required this.text,
    required this.style,
    this.negative = false,
  });

  final String text;
  final TextStyle style;
  final bool negative;

  @override
  Widget build(BuildContext context) {
    final displayText = negative && !text.startsWith('-') ? '-$text' : text;
    final decimalIndex = displayText.lastIndexOf('.');
    if (decimalIndex == -1 || decimalIndex == displayText.length - 1) {
      return Text(displayText, style: style);
    }
    final main = displayText.substring(0, decimalIndex);
    final decimal = displayText.substring(decimalIndex);
    final decimalStyle = style.copyWith(
      fontSize: (style.fontSize ?? 14) * .72,
      color: style.color?.withAlpha(190),
    );
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: main, style: style),
          TextSpan(text: decimal, style: decimalStyle),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _WalletContent extends StatelessWidget {
  const _WalletContent({required this.transactions, required this.onSeeAll});

  final List<MoneyTransaction> transactions;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(const Duration(days: 6));
    final recent = transactions.where((transaction) {
      final date = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      return !date.isBefore(start) && !date.isAfter(today);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
          ),
          child: _ExpenseSummaryCards(
            weeklyTransactions: recent,
            allTransactions: transactions,
            allLoans: transactions,
          ),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
          ),
          child: Row(
            children: [
              const Text(
                'Recent activity',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onSeeAll,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                child: const Text(
                  'See All',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        _GroupedTransactionList(
          transactions: recent,
          emptyTitle: 'No activity in the last 7 days',
          emptySubtitle: 'Your latest income and spending will appear here.',
          useRelativeDates: true,
          summaryFilter: 'wallet',
        ),
      ],
    );
  }
}

class _TransactionsContent extends StatelessWidget {
  const _TransactionsContent({
    required this.transactions,
    required this.categoryFilter,
    required this.searchQuery,
    required this.typeFilter,
    required this.selectedMonth,
    required this.sortAscending,
  });

  final List<MoneyTransaction> transactions;
  final String? categoryFilter;
  final String searchQuery;
  final String typeFilter;
  final DateTime? selectedMonth;
  final bool sortAscending;

  @override
  Widget build(BuildContext context) {
    final query = searchQuery.toLowerCase();
    final filtered =
        transactions.where((transaction) {
          final matchesCategory =
              categoryFilter == null || transaction.category == categoryFilter;
          final matchesType =
              typeFilter == 'all' ||
              (typeFilter == 'loan'
                  ? transaction.type == 'lent' || transaction.type == 'borrowed'
                  : transaction.type == typeFilter);
          final matchesMonth =
              selectedMonth == null ||
              (transaction.date.year == selectedMonth!.year &&
                  transaction.date.month == selectedMonth!.month);
          final matchesSearch =
              query.isEmpty ||
              transaction.category.toLowerCase().contains(query) ||
              (transaction.note?.toLowerCase().contains(query) ?? false) ||
              (transaction.counterparty?.toLowerCase().contains(query) ??
                  false) ||
              transaction.type.toLowerCase().contains(query) ||
              DateFormat('d MMM yyyy')
                  .format(transaction.date)
                  .toLowerCase()
                  .contains(query);
          return matchesCategory &&
              matchesType &&
              matchesMonth &&
              matchesSearch;
        }).toList()..sort(
          (a, b) => sortAscending
              ? a.date.compareTo(b.date)
              : b.date.compareTo(a.date),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            8,
            AppSpacing.screenHorizontal,
            8,
          ),
          child: Text(
            searchQuery.isEmpty ? 'Transactions' : 'Search results',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        _GroupedTransactionList(
          transactions: filtered,
          emptyTitle: 'No matching transactions',
          emptySubtitle: 'Try changing your search or category filter.',
          useRelativeDates: false,
          summaryFilter: typeFilter,
        ),
      ],
    );
  }
}

class _OverviewContent extends StatelessWidget {
  const _OverviewContent({required this.transactions});

  final List<MoneyTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    final income = _totalForTransactions(
      transactions
          .where((transaction) => transaction.type == 'income')
          .toList(),
    );
    final spending = _totalForTransactions(
      transactions
          .where((transaction) => transaction.type == 'expense')
          .toList(),
    );
    final net = income - spending;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
          ),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _OverviewMetric(
                    label: 'Income',
                    value: '₹${_fmt.format(income)}',
                    color: AppColors.success,
                  ),
                ),
                Expanded(
                  child: _OverviewMetric(
                    label: 'Spending',
                    value: '₹${_fmt.format(spending)}',
                    color: AppColors.danger,
                  ),
                ),
                Expanded(
                  child: _OverviewMetric(
                    label: 'Net flow',
                    value: _formatFinanceAmount(net),
                    color: net >= 0 ? AppColors.success : AppColors.danger,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
          ),
          child: _SpendingChart(transactions: transactions),
        ),
        const SizedBox(height: 14),
        _CategorySpendGrid(transactions: transactions),
      ],
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 10,
          color: AppColors.textSecondary,
        ),
      ),
      const SizedBox(height: 4),
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: _FinanceAmountText(
          text: value,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    ],
  );
}

class _GroupedTransactionList extends StatelessWidget {
  const _GroupedTransactionList({
    required this.transactions,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.useRelativeDates,
    this.summaryFilter,
  });

  final List<MoneyTransaction> transactions;
  final String emptyTitle;
  final String emptySubtitle;
  final bool useRelativeDates;
  final String? summaryFilter;

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return EmptyState(
        icon: Icons.account_balance_wallet_outlined,
        title: emptyTitle,
        subtitle: emptySubtitle,
        asset: 'assets/illustrations/Finance.png',
      );
    }

    final grouped = <DateTime, List<MoneyTransaction>>{};
    for (final transaction in transactions) {
      final day = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      grouped.putIfAbsent(day, () => []).add(transaction);
    }
    final entries = grouped.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return Column(
      children: [
        for (final entry in entries)
          _DailyTransactionGroup(
            date: entry.key,
            transactions: entry.value,
            useRelativeDates: useRelativeDates,
            summaryFilter: summaryFilter,
          ),
      ],
    );
  }
}

class _DailyTransactionGroup extends StatelessWidget {
  const _DailyTransactionGroup({
    required this.date,
    required this.transactions,
    required this.useRelativeDates,
    this.summaryFilter,
  });

  final DateTime date;
  final List<MoneyTransaction> transactions;
  final bool useRelativeDates;
  final String? summaryFilter;

  @override
  Widget build(BuildContext context) {
    final income = transactions.fold(0.0, (sum, transaction) {
      final isIncome =
          transaction.type == 'income' || transaction.type == 'borrowed';
      return isIncome ? sum + _moneyMajorAmount(transaction.amount) : sum;
    });
    final expense = transactions.fold(0.0, (sum, transaction) {
      final isExpense =
          transaction.type == 'expense' || transaction.type == 'lent';
      return isExpense ? sum + _moneyMajorAmount(transaction.amount) : sum;
    });
    final net = income - expense;

    final headerSummary = switch (summaryFilter) {
      'income' => '+₹${_formatAbsoluteFinanceAmount(income)}',
      'expense' => '-₹${_formatAbsoluteFinanceAmount(expense)}',
      'loan' => _formatFinanceAmount(net),
      _ => null,
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        5,
        AppSpacing.screenHorizontal,
        5,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
              decoration: const BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _dateLabel(date, useRelativeDates),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (summaryFilter == 'all') ...[
                    _FinanceAmountText(
                      text: '+₹${_formatAbsoluteFinanceAmount(income)}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 7),
                    _FinanceAmountText(
                      text: '-₹${_formatAbsoluteFinanceAmount(expense)}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.danger,
                      ),
                    ),
                  ] else
                    _FinanceAmountText(
                      text: headerSummary ?? _formatFinanceAmount(net),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color:
                            (summaryFilter == 'expense' ||
                                (summaryFilter == 'loan' && net < 0))
                            ? AppColors.danger
                            : AppColors.success,
                      ),
                    ),
                  const SizedBox(width: 3),
                  const Icon(
                    Icons.keyboard_arrow_up_rounded,
                    size: 16,
                    color: Colors.white70,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            for (final transaction in transactions)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
                child: _TransactionTile(txn: transaction),
              ),
          ],
        ),
      ),
    );
  }
}

String _dateLabel(DateTime date, bool relative) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  if (relative && date == today) return 'Today';
  if (relative && date == today.subtract(const Duration(days: 1))) {
    return 'Yesterday';
  }
  return DateFormat('EEEE, d MMM yyyy').format(date);
}

class _TransactionFilterToolbar extends StatelessWidget {
  const _TransactionFilterToolbar({
    required this.selectedType,
    required this.selectedMonth,
    required this.sortAscending,
    required this.onTypeSelected,
    required this.onMonthTap,
    required this.onSortTap,
  });

  final String selectedType;
  final DateTime? selectedMonth;
  final bool sortAscending;
  final ValueChanged<String> onTypeSelected;
  final VoidCallback onMonthTap;
  final VoidCallback onSortTap;

  @override
  Widget build(BuildContext context) {
    const filters = [
      ('all', 'All', Icons.grid_view_rounded),
      ('income', 'Income', Icons.arrow_downward_rounded),
      ('expense', 'Expense', Icons.arrow_upward_rounded),
      ('loan', 'Lent/Borrowed', Icons.swap_horiz_rounded),
    ];

    return Column(
      children: [
        SizedBox(
          height: 38,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
            ),
            scrollDirection: Axis.horizontal,
            itemCount: filters.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final filter = filters[index];
              final selected = selectedType == filter.$1;
              return _FinanceFilterPill(
                label: filter.$2,
                icon: filter.$3,
                selected: selected,
                onTap: () => onTypeSelected(filter.$1),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
          ),
          child: Row(
            children: [
              Expanded(
                child: _FinanceControlButton(
                  icon: Icons.calendar_today_outlined,
                  label: selectedMonth == null
                      ? 'All dates'
                      : DateFormat('MMM yyyy').format(selectedMonth!),
                  onTap: onMonthTap,
                ),
              ),
              const SizedBox(width: 10),
              _FinanceControlButton(
                icon: Icons.swap_vert_rounded,
                label: sortAscending ? 'Oldest' : 'Latest',
                onTap: onSortTap,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _FinanceFilterPill extends StatelessWidget {
  const _FinanceFilterPill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: DimiMotion.fast,
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: selected ? AppColors.textPrimary : AppColors.info,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.textPrimary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _FinanceControlButton extends StatelessWidget {
  const _FinanceControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 3),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 16,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    ),
  );
}

class _FinancePickerSheet<T> extends StatelessWidget {
  const _FinancePickerSheet({
    required this.title,
    required this.selected,
    required this.items,
    required this.label,
    required this.onSelected,
  });

  final String title;
  final T selected;
  final List<T> items;
  final String Function(T item) label;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
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
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                label(item),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: item == selected
                  ? const Icon(Icons.check_rounded, color: AppColors.accent)
                  : null,
              onTap: () => onSelected(item),
            ),
          ),
        ],
      ),
    ),
  );
}

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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = (constraints.maxWidth - 16) / 3;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: entries
                .map(
                  (entry) => SizedBox(
                    width: width,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.cardRadius,
                        ),
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
                            child: Icon(
                              _categoryIcon(entry.key),
                              size: 17,
                              color: AppColors.accent,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            entry.key,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _formatMoney(entry.value),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }

  static IconData _categoryIcon(String category) =>
      financeCategoryIcon(category);

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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
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
    final lentTransactions = _activeTransactionsOfType(allLoans, 'lent');
    final borrowedTransactions = _activeTransactionsOfType(
      allLoans,
      'borrowed',
    );
    final lent = _totalForTransactions(lentTransactions);
    final borrowed = _totalForTransactions(borrowedTransactions);
    final balance = income - spent - lent + borrowed;
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
                  child: _FinanceAmountText(
                    text: '₹${_fmt.format(balance)}',
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
                onTap: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  barrierColor: Colors.black54,
                  builder: (_) => _LoanTransactionsSheet(
                    type: 'lent',
                    transactions: lentTransactions,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _LoanCard(
                label: 'Borrowed',
                value: borrowed,
                icon: Icons.account_balance_wallet_outlined,
                color: AppColors.danger,
                onTap: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  barrierColor: Colors.black54,
                  builder: (_) => _LoanTransactionsSheet(
                    type: 'borrowed',
                    transactions: borrowedTransactions,
                  ),
                ),
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
                child: _FinanceAmountText(
                  text: value,
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
    required this.onTap,
  });
  final String label;
  final double value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
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
                      child: _FinanceAmountText(
                        text: '₹${_fmt.format(value)}',
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
      ),
    ),
  );
}

class _LoanTransactionsSheet extends StatelessWidget {
  const _LoanTransactionsSheet({
    required this.type,
    required this.transactions,
  });

  final String type;
  final List<MoneyTransaction> transactions;

  bool get _isLent => type == 'lent';
  String get _title => _isLent ? 'Lent money' : 'Borrowed money';
  String get _description => _isLent
      ? 'Money currently out with other people'
      : 'Money currently received from other people';
  Color get _color => AppColors.info;

  @override
  Widget build(BuildContext context) {
    final total = _totalForTransactions(transactions);
    final screenHeight = MediaQuery.sizeOf(context).height;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(top: 48),
        child: Container(
          constraints: BoxConstraints(maxHeight: screenHeight * .78),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 14, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: _color.withAlpha(26),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isLent
                            ? Icons.arrow_forward_rounded
                            : Icons.arrow_back_rounded,
                        color: _color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _title,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _description,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: _color.withAlpha(18),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Total ${_isLent ? 'lent' : 'borrowed'}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      _FinanceAmountText(
                        text: '₹${_fmt.format(total)}',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: _color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: transactions.isEmpty
                    ? _LoanEmptyState(isLent: _isLent)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
                        shrinkWrap: true,
                        itemCount: transactions.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, index) => _LoanTransactionRow(
                          transaction: transactions[index],
                          color: _color,
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

class _LoanEmptyState extends StatelessWidget {
  const _LoanEmptyState({required this.isLent});

  final bool isLent;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(22, 22, 22, 34),
    child: Column(
      children: [
        Icon(
          isLent
              ? Icons.person_search_rounded
              : Icons.account_balance_wallet_outlined,
          size: 34,
          color: AppColors.textSecondary,
        ),
        const SizedBox(height: 9),
        Text(
          'No active ${isLent ? 'lent' : 'borrowed'} transactions',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    ),
  );
}

class _LoanTransactionRow extends StatelessWidget {
  const _LoanTransactionRow({required this.transaction, required this.color});

  final MoneyTransaction transaction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final rowColor = AppColors.info;
    final title = transaction.note?.trim().isNotEmpty == true
        ? transaction.note!.trim()
        : transaction.category;
    final subtitle = transaction.counterparty?.trim().isNotEmpty == true
        ? '${transaction.counterparty} · ${DateFormat('d MMM yyyy').format(transaction.date)}'
        : DateFormat('d MMM yyyy').format(transaction.date);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: rowColor.withAlpha(22),
              shape: BoxShape.circle,
            ),
            child: Icon(
              transaction.type == 'lent'
                  ? Icons.arrow_forward_rounded
                  : Icons.arrow_back_rounded,
              size: 17,
              color: rowColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _FinanceAmountText(
            text: '₹${_fmt.format(_moneyMajorAmount(transaction.amount))}',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: rowColor,
            ),
            negative: transaction.type == 'lent',
          ),
        ],
      ),
    );
  }
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
          _FinanceAmountText(
            text: value,
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

class _TransactionTile extends ConsumerStatefulWidget {
  const _TransactionTile({required this.txn});
  final MoneyTransaction txn;

  @override
  ConsumerState<_TransactionTile> createState() => _TransactionTileState();
}

class _TransactionTileState extends ConsumerState<_TransactionTile> {
  MoneyTransaction get txn => widget.txn;

  @override
  Widget build(BuildContext context) {
    final dao = ref.read(moneyDaoProvider);
    final (color, icon) = _typeStyle(txn.type);
    final sign = txn.type == 'expense' || txn.type == 'lent' ? '-' : '+';

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showDetails(context, color, icon),
        splashColor: AppColors.accentSoft.withAlpha(80),
        highlightColor: AppColors.accentSoft.withAlpha(35),
        onLongPress: () async {
          if (!context.mounted) return;
          await _confirmDelete(context, dao);
        },
        child: Ink(
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
                    Row(
                      children: [
                        Icon(
                          financeCategoryIcon(txn.category),
                          size: 12,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            txn.category,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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
                      child: _FinanceAmountText(
                        text:
                            '$sign₹${_fmt.format(_moneyMajorAmount(txn.amount))}',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (Color, IconData) _typeStyle(String type) => switch (type) {
    'income' => (AppColors.success, Icons.arrow_downward_rounded),
    'borrowed' => (AppColors.info, Icons.arrow_back_rounded),
    'lent' => (AppColors.info, Icons.arrow_forward_rounded),
    _ => (AppColors.danger, Icons.arrow_upward_rounded),
  };

  Future<void> _showDetails(BuildContext context, Color color, IconData icon) {
    final sign = txn.type == 'expense' || txn.type == 'lent' ? '-' : '+';
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
              _FinanceAmountText(
                text: '$sign${_fmt.format(_moneyMajorAmount(txn.amount))}',
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
                txn.type == 'income'
                    ? 'Income'
                    : txn.type == 'lent'
                    ? 'Lent'
                    : txn.type == 'borrowed'
                    ? 'Borrowed'
                    : 'Expense',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 22),
              _DetailRow(
                label: 'Category',
                value: txn.category,
                icon: Icons.sell_outlined,
              ),
              const SizedBox(height: 14),
              _DetailRow(
                label: 'Date and time',
                value: DateFormat('EEEE, d MMM yyyy · h:mm a').format(txn.date),
                icon: Icons.calendar_today_outlined,
              ),
              const SizedBox(height: 14),
              _DetailRow(
                label: 'Description',
                value: description,
                icon: Icons.notes_rounded,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.textPrimary,
                    foregroundColor: AppColors.surface,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, MoneyDao dao) async {
    final ok = await showDimiActionDialog<bool>(
      context,
      title: 'Are you sure?',
      message:
          'Remove this ${txn.type} of ₹${_fmt.format(_moneyMajorAmount(txn.amount))}?',
      actions: const [
        DimiDialogAction(label: 'Cancel', value: false),
        DimiDialogAction(
          label: 'Delete',
          value: true,
          primary: true,
          destructive: true,
        ),
      ],
    );
    if (ok == true) await dao.deleteTransaction(txn.id);
  }

  Future<void> _confirmDeleteLegacy(BuildContext context, MoneyDao dao) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Are you sure?',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Remove this ${txn.type} of ₹${_fmt.format(_moneyMajorAmount(txn.amount))}?',
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.surface,
              shape: const StadiumBorder(),
            ),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.surface,
              shape: const StadiumBorder(),
            ),
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
  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
  });
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
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
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
