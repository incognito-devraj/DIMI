import 'dart:ui' as ui;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/database.dart';
import '../../data/daos/money_dao.dart';
import '../../providers/money_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/dimi_activity_heatmap.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/dimi_add_action_button.dart';
import '../../widgets/dimi_action_dialog.dart';
import '../../core/motion/dimi_motion.dart';
import '../../widgets/pill_segmented_control.dart';
import '../../widgets/section_card.dart';
import '../../widgets_modals/add_expense_sheet.dart';
import '../../widgets_modals/fixed_dialog.dart';

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
  Set<String> _categoryFilters = <String>{};
  String _searchQuery = '';
  bool _searchActive = false;
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  String _transactionTypeFilter = 'all';
  DateTime? _transactionMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );
  DateTimeRange? _transactionDateRange;
  final _tooltipOpen = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _tooltipOpen.dispose();
    super.dispose();
  }

  void _openSearch() {
    setState(() {
      _searchActive = true;
      // The keyboard owns the lower part of the screen while searching.
      // Hide the floating action and remove its reserved list space so the
      // transaction list reads as one continuous surface behind the keyboard.
      _showAddButton = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocusNode.requestFocus();
    });
  }

  void _closeSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() {
      _searchActive = false;
      _searchQuery = '';
      _showAddButton = true;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  Future<void> _openFilter(List<String> categories) async {
    final selected = await showGeneralDialog<Set<String>>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Filter expenses',
      barrierColor: const Color(0x99000000),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, _, _) => DimiFixedDialog(
        height: 540,
        child: _FinanceCategoryFilterDialog(
          categories: categories,
          selected: _categoryFilters,
        ),
      ),
      transitionBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
    if (selected != null && mounted) {
      setState(() => _categoryFilters = selected);
    }
  }

  Future<void> _openMonthSelector() async {
    final selected = await showGeneralDialog<DateTimeRange?>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Date period',
      barrierColor: const Color(0x99000000),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, _, _) => DimiFixedDialog(
        height: 560,
        child: _FinanceDatePeriodDialog(selectedRange: _transactionDateRange),
      ),
      transitionBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
    if (selected != null && mounted) {
      final isAllDates = selected.start.year == 1900;
      setState(() {
        _transactionMonth = isAllDates
            ? null
            : DateTime(selected.start.year, selected.start.month);
        _transactionDateRange = isAllDates ? null : selected;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final allAsync = ref.watch(allTransactionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: !_searchActive,
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
                child: AnimatedSwitcher(
                  duration: DimiMotion.smooth,
                  reverseDuration: DimiMotion.fast,
                  switchInCurve: DimiMotion.transitionCurve,
                  switchOutCurve: DimiMotion.transitionCurve,
                  transitionBuilder: (child, animation) {
                    final curved = CurvedAnimation(
                      parent: animation,
                      curve: DimiMotion.transitionCurve,
                      reverseCurve: DimiMotion.curve,
                    );
                    return FadeTransition(
                      opacity: curved,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.025, 0),
                          end: Offset.zero,
                        ).animate(curved),
                        child: child,
                      ),
                    );
                  },
                  child: _searchActive
                      ? _FinanceSearchHeader(
                          key: const ValueKey('finance-search'),
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          onChanged: (value) =>
                              setState(() => _searchQuery = value.trim()),
                          onBack: _closeSearch,
                          onCancel: _closeSearch,
                          onClear: _clearSearch,
                        )
                      : Row(
                          key: const ValueKey('finance-header'),
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
                            if (_tabIndex == 1) ...[
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
                                icon: Icon(
                                  Icons.bar_chart_rounded,
                                  color: _categoryFilters.isNotEmpty
                                      ? AppColors.accent
                                      : AppColors.textSecondary,
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
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Tabs ──────────────────────────────────────────────────
              if (!_searchActive) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenHorizontal,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: PillSegmentedControl(
                      options: _kTabs,
                      selected: _tabIndex,
                      onSelected: (i) => setState(() {
                        _tabIndex = i;
                        if (i != 1) {
                          _categoryFilters.clear();
                          _searchActive = false;
                          _searchController.clear();
                          _searchQuery = '';
                          _showAddButton = true;
                        }
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              if (_tabIndex == 2)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenHorizontal,
                  ),
                  child: _FinanceExpenseHeatmap(
                    transactions: allAsync.maybeWhen(
                      data: (items) => items,
                      orElse: () => const <MoneyTransaction>[],
                    ),
                    selectedMonth: _transactionMonth ?? DateTime.now(),
                    tooltipOpen: _tooltipOpen,
                  ),
                ),
              if (_tabIndex == 2) const SizedBox(height: 14),

              // ── Content ───────────────────────────────────────────────
              if (_tabIndex == 1 && !_searchActive)
                _TransactionFilterToolbar(
                  selectedType: _transactionTypeFilter,
                  onTypeSelected: (type) =>
                      setState(() => _transactionTypeFilter = type),
                ),
              Expanded(
                child: ColoredBox(
                  color: _searchActive ? AppColors.surface : Colors.transparent,
                  child: LayoutBuilder(
                    builder: (context, constraints) => ListView(
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
                              categoryFilters: _categoryFilters,
                              searchQuery: _searchQuery,
                              typeFilter: _transactionTypeFilter,
                              selectedMonth: _transactionMonth,
                              dateRange: _transactionDateRange,
                              onMonthTap: _openMonthSelector,
                              onClearSearch: _clearSearch,
                              availableHeight: constraints.maxHeight,
                            ),
                            _ => _OverviewContent(
                              tooltipOpen: _tooltipOpen,
                              transactions: transactions,
                              selectedMonth: _transactionMonth ?? DateTime.now(),
                              onMonthTap: _openMonthSelector,
                            ),
                          },
                          loading: () => const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.screenHorizontal,
                            ),
                            child: _SkeletonCard(height: 270),
                          ),
                          error: (error, _) =>
                              Center(child: Text('Error: $error')),
                        ),
                        SizedBox(
                          height: (!_searchActive && _showAddButton) ? 80 : 0,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _searchActive
          ? null
          : IgnorePointer(
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

class _FinanceSearchHeader extends StatelessWidget {
  const _FinanceSearchHeader({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onBack,
    required this.onCancel,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onBack;
  final VoidCallback onCancel;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton(
        onPressed: onBack,
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        visualDensity: VisualDensity.compact,
      ),
      Expanded(
        child: Container(
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.divider),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: true,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'Search transactions',
              prefixIcon: const Icon(Icons.search_rounded, size: 18),
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, _) => value.text.isEmpty
                    ? const SizedBox.shrink()
                    : IconButton(
                        onPressed: onClear,
                        icon: const Icon(Icons.close_rounded, size: 16),
                        visualDensity: VisualDensity.compact,
                      ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 11),
            ),
          ),
        ),
      ),
      TextButton(
        onPressed: onCancel,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.only(left: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text(
          'Cancel',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
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
    required this.categoryFilters,
    required this.searchQuery,
    required this.typeFilter,
    required this.selectedMonth,
    required this.dateRange,
    required this.onMonthTap,
    required this.onClearSearch,
    required this.availableHeight,
  });

  final List<MoneyTransaction> transactions;
  final Set<String> categoryFilters;
  final String searchQuery;
  final String typeFilter;
  final DateTime? selectedMonth;
  final DateTimeRange? dateRange;
  final VoidCallback onMonthTap;
  final VoidCallback onClearSearch;
  final double availableHeight;

  @override
  Widget build(BuildContext context) {
    final query = searchQuery.toLowerCase();
    final numericQuery = query.replaceAll(RegExp(r'[₹,\s]'), '');
    final numericValue = double.tryParse(numericQuery);
    final isExactNumericSearch =
        numericValue != null &&
        numericQuery.isNotEmpty &&
        RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(numericQuery);
    final filtered = transactions.where((transaction) {
      final matchesCategory =
          categoryFilters.isEmpty ||
          categoryFilters.contains(transaction.category);
      final matchesType =
          typeFilter == 'all' ||
          (typeFilter == 'loan'
              ? transaction.type == 'lent' || transaction.type == 'borrowed'
              : transaction.type == typeFilter);
      final matchesMonth = dateRange != null
          ? !transaction.date.isBefore(dateRange!.start) &&
                !transaction.date.isAfter(dateRange!.end)
          : selectedMonth == null ||
                (transaction.date.year == selectedMonth!.year &&
                    transaction.date.month == selectedMonth!.month);
      final amount = _moneyMajorAmount(transaction.amount);
      final matchesExactAmount =
          isExactNumericSearch && (amount - numericValue!).abs() < 0.001;
      final matchesSearch = isExactNumericSearch
          ? matchesExactAmount
          : (query.isEmpty ||
                transaction.category.toLowerCase().contains(query) ||
                (transaction.note?.toLowerCase().contains(query) ?? false) ||
                (transaction.counterparty?.toLowerCase().contains(query) ??
                    false) ||
                transaction.type.toLowerCase().contains(query) ||
                DateFormat('d MMM yyyy')
                    .format(transaction.date)
                    .toLowerCase()
                    .contains(query) ||
                [
                  transaction.amount.toString(),
                  _moneyMajorAmount(transaction.amount).toString(),
                  _moneyMajorAmount(transaction.amount).toStringAsFixed(2),
                  _formatAbsoluteFinanceAmount(
                    _moneyMajorAmount(transaction.amount),
                  ),
                ].any(
                  (amount) => amount
                      .replaceAll(RegExp(r'[₹,\s]'), '')
                      .contains(numericQuery),
                ));
      return matchesCategory && matchesType && matchesMonth && matchesSearch;
    }).toList()..sort((a, b) => b.date.compareTo(a.date));

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
          child: Row(
            children: [
              Expanded(
                child: Text(
                  searchQuery.isEmpty ? 'Transactions' : 'Search Results',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _FinanceControlButton(
                icon: Icons.calendar_today_outlined,
                label: selectedMonth == null
                    ? 'All dates'
                    : DateFormat('MMM yyyy').format(selectedMonth!),
                onTap: onMonthTap,
              ),
            ],
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          reverseDuration: const Duration(milliseconds: 170),
          switchInCurve: DimiMotion.transitionCurve,
          switchOutCurve: Curves.easeInCubic,
          layoutBuilder: (currentChild, previousChildren) => Stack(
            alignment: Alignment.topCenter,
            children: <Widget>[
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          ),
          transitionBuilder: (child, animation) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return ClipRect(
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.2, end: 1).animate(curved),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.07),
                    end: Offset.zero,
                  ).animate(curved),
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.985, end: 1).animate(curved),
                    alignment: Alignment.topCenter,
                    child: child,
                  ),
                ),
              ),
            );
          },
          child: searchQuery.isNotEmpty && filtered.isEmpty
              ? SizedBox(
                  key: const ValueKey('search-empty'),
                  height: (availableHeight - 64)
                      .clamp(300.0, double.infinity)
                      .toDouble(),
                  child: Center(
                    child: _FinanceSearchEmptyState(onClear: onClearSearch),
                  ),
                )
              : _GroupedTransactionList(
                  key: ValueKey(
                    '${filtered.length}-${typeFilter}-${searchQuery.isEmpty ? 'all' : 'search'}',
                  ),
                  transactions: filtered,
                  emptyTitle: 'No matching transactions',
                  emptySubtitle: 'Try changing your search or category filter.',
                  useRelativeDates: false,
                  summaryFilter: typeFilter,
                ),
        ),
      ],
    );
  }
}

class _FinanceSearchEmptyState extends StatelessWidget {
  const _FinanceSearchEmptyState({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.screenHorizontal,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: AppColors.accentSoft,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.search_off_rounded,
            size: 38,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'No transactions found',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'We couldn’t find any transactions\nmatching your search.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 18),
        TextButton(
          onPressed: onClear,
          style: TextButton.styleFrom(
            backgroundColor: AppColors.accentSoft,
            foregroundColor: AppColors.textPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          ),
          child: const Text(
            'Clear Search',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class _OverviewContent extends StatelessWidget {
  const _OverviewContent({
    required this.tooltipOpen,
    required this.transactions,
    required this.selectedMonth,
    required this.onMonthTap,
  });

  final List<MoneyTransaction> transactions;
  final DateTime selectedMonth;
  final VoidCallback onMonthTap;
  final ValueNotifier<bool> tooltipOpen;

  @override
  Widget build(BuildContext context) {
    final monthTransactions = transactions.where((transaction) {
      return transaction.date.year == selectedMonth.year &&
          transaction.date.month == selectedMonth.month;
    }).toList();
    final expenses = monthTransactions
        .where((transaction) => transaction.type == 'expense')
        .toList();
    final totalSpent = _totalForTransactions(expenses);
    final dailyAverage =
        totalSpent /
        DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;
    final byDay = <DateTime, double>{};
    for (final transaction in expenses) {
      final day = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      byDay[day] = (byDay[day] ?? 0) + _moneyMajorAmount(transaction.amount);
    }
    final highestDay = byDay.entries.isEmpty
        ? null
        : (byDay.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
              .first;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      child: ValueListenableBuilder<bool>(
        valueListenable: tooltipOpen,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.divider),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Overview',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _FinanceControlButton(
                    icon: Icons.calendar_today_outlined,
                    label: DateFormat('MMM yyyy').format(selectedMonth),
                    onTap: onMonthTap,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _OverviewMetric(
                      label: 'Total Spent',
                      value: '₹${_formatAbsoluteFinanceAmount(totalSpent)}',
                      color: AppColors.danger,
                    ),
                  ),
                  Expanded(
                    child: _OverviewMetric(
                      label: 'Daily Average',
                      value: '₹${_formatAbsoluteFinanceAmount(dailyAverage)}',
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Expanded(
                    child: _OverviewMetric(
                      label: 'Highest Day',
                      value: highestDay == null
                          ? '—'
                          : '₹${_formatAbsoluteFinanceAmount(highestDay.value)}',
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const Text(
                'Spending by category',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              _OverviewCategoryGrid(expenses: expenses, totalSpent: totalSpent),
            ],
          ),
        ),
        builder: (context, isTooltipOpen, child) => Stack(
          clipBehavior: Clip.none,
          children: [
            child!,
            if (isTooltipOpen)
              Positioned.fill(
                child: IgnorePointer(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                      child: const ColoredBox(color: Color(0x04000000)),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OverviewCategoryGrid extends StatelessWidget {
  const _OverviewCategoryGrid({
    required this.expenses,
    required this.totalSpent,
  });

  final List<MoneyTransaction> expenses;
  final double totalSpent;

  @override
  Widget build(BuildContext context) {
    final totals = <String, double>{};
    for (final transaction in expenses) {
      totals[transaction.category] =
          (totals[transaction.category] ?? 0) +
          _moneyMajorAmount(transaction.amount);
    }
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (entries.isEmpty) {
      return const Text(
        'No expenses for this month',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.9,
      ),
      itemBuilder: (context, index) {
        final entry = entries[index];
        final percentage = totalSpent <= 0 ? 0 : entry.value / totalSpent * 100;
        return Container(
          padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: AppColors.divider),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            child: Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(painter: _PercentageCornerPainter()),
                  ),
                ),
                Positioned(
                  top: 5,
                  right: 7,
                  child: Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        financeCategoryIcon(entry.key),
                        size: 34,
                        color: _catIconColor(entry.key),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        entry.key,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₹${_formatAbsoluteFinanceAmount(entry.value)}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PercentageCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * .57, 0)
      ..lineTo(size.width - 7, 0)
      ..quadraticBezierTo(size.width, 0, size.width, 7)
      ..lineTo(size.width, size.height * .36)
      ..cubicTo(
        size.width * .84,
        size.height * .37,
        size.width * .67,
        size.height * .24,
        size.width * .57,
        0,
      )
      ..close();

    canvas.drawPath(path, Paint()..color = AppColors.accentSoft);

    final fold = Paint()
      ..color = AppColors.accent.withAlpha(105)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final foldPath = Path()
      ..moveTo(size.width * .57, 0)
      ..cubicTo(
        size.width * .67,
        size.height * .24,
        size.width * .84,
        size.height * .37,
        size.width,
        size.height * .36,
      );
    canvas.drawPath(foldPath, fold);
  }

  @override
  bool shouldRepaint(covariant _PercentageCornerPainter oldDelegate) => false;
}

class _FinanceExpenseHeatmap extends StatefulWidget {
  const _FinanceExpenseHeatmap({
    required this.transactions,
    required this.selectedMonth,
    required this.tooltipOpen,
  });

  final List<MoneyTransaction> transactions;
  final DateTime selectedMonth;
  final ValueNotifier<bool> tooltipOpen;

  static const _cellSize = 12.0;
  static const _gap = 3.0;
  static const _labelWidth = 30.0;

  @override
  State<_FinanceExpenseHeatmap> createState() => _FinanceExpenseHeatmapState();
}

class _FinanceExpenseHeatmapState extends State<_FinanceExpenseHeatmap> {
  final Map<DateTime, LayerLink> _cellLinks = {};
  _FinanceHeatmapSelection? _selection;
  _FinanceHeatmapPlacement? _placement;
  OverlayEntry? _overlayEntry;

  LayerLink _linkFor(DateTime date) =>
      _cellLinks.putIfAbsent(date, LayerLink.new);

  List<MoneyTransaction> get transactions => widget.transactions;
  DateTime get selectedMonth => widget.selectedMonth;

  @override
  void dispose() {
    _overlayEntry?.remove();
    widget.tooltipOpen.value = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expenses = transactions
        .where((transaction) => transaction.type == 'expense')
        .toList();
    final totals = <DateTime, double>{};
    for (final transaction in expenses) {
      final day = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      totals[day] = (totals[day] ?? 0) + _moneyMajorAmount(transaction.amount);
    }
    final months = List.generate(
      12,
      (index) => DateTime(selectedMonth.year, selectedMonth.month - 11 + index),
    );
    final maxSpend = totals.values.isEmpty
        ? 0.0
        : totals.values.reduce((a, b) => a > b ? a : b);

    return Container(
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
              const Expanded(
                child: Text(
                  'Expense rhythm',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                DateFormat('MMM yyyy').format(selectedMonth),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height:
                7 * _FinanceExpenseHeatmap._cellSize +
                6 * _FinanceExpenseHeatmap._gap +
                16,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  width: _FinanceExpenseHeatmap._labelWidth,
                  child: Column(
                    children: [
                      SizedBox(height: _FinanceExpenseHeatmap._cellSize + 4),
                      _FinanceHeatmapLabel('Sun'),
                      _FinanceHeatmapLabel('Mon'),
                      _FinanceHeatmapLabel('Tue'),
                      _FinanceHeatmapLabel('Wed'),
                      _FinanceHeatmapLabel('Thu'),
                      _FinanceHeatmapLabel('Fri'),
                      _FinanceHeatmapLabel('Sat', last: true),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final month in months)
                          _FinanceExpenseMonthGroup(
                            month: month,
                            totals: totals,
                            maxSpend: maxSpend,
                            linkFor: _linkFor,
                            onDayTap: (cellContext, day) =>
                                _selectCell(cellContext, day, expenses),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text('Less', style: _financeHeatmapLabelStyle),
              const SizedBox(width: 5),
              for (final color in heatmapColors)
                Padding(
                  padding: const EdgeInsets.only(left: 3),
                  child: SizedBox(
                    width: 10,
                    height: 10,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 5),
              const Text('More', style: _financeHeatmapLabelStyle),
            ],
          ),
        ],
      ),
    );
  }

  void _selectCell(
    BuildContext cellContext,
    DateTime day,
    List<MoneyTransaction> expenses,
  ) {
    final box = cellContext.findRenderObject()! as RenderBox;
    final cellTopLeft = box.localToGlobal(Offset.zero);
    final cellRect = cellTopLeft & box.size;
    final screen = MediaQuery.sizeOf(context);
    const width = 220.0;
    final centerX = cellRect.center.dx;
    final left = (centerX - width / 2)
        .clamp(16.0, screen.width - width - 16)
        .toDouble();
    // Finance tooltips intentionally open below the heatmap cell. Keeping the
    // anchor on the tooltip head makes the interaction predictable across all
    // month columns and matches the requested Finance layout.
    const above = false;
    final dayExpenses = expenses.where((transaction) {
      return transaction.date.year == day.year &&
          transaction.date.month == day.month &&
          transaction.date.day == day.day;
    }).toList();

    setState(() {
      _selection = _FinanceHeatmapSelection(
        day,
        _totalForTransactions(dayExpenses),
        dayExpenses,
      );
      _placement = _FinanceHeatmapPlacement(
        above: above,
        width: width,
        offsetX: left - (centerX - width / 2),
        arrowX: centerX - left,
        cellHeight: cellRect.height,
      );
    });
    widget.tooltipOpen.value = true;
    if (_overlayEntry == null) {
      _overlayEntry = OverlayEntry(builder: (_) => _buildOverlay());
      Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
    } else {
      _overlayEntry!.markNeedsBuild();
    }
  }

  Widget _buildOverlay() {
    final selection = _selection;
    final placement = _placement;
    if (selection == null || placement == null) {
      return const SizedBox.shrink();
    }
    return Positioned.fill(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.scale(
                scale: 0.96 + (value * 0.04),
                alignment: Alignment.topCenter,
                child: child,
              ),
            ),
            child: CompositedTransformFollower(
              link: _linkFor(selection.date),
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomCenter,
              followerAnchor: Alignment.topCenter,
              offset: placement.offset,
              child: TapRegion(
                onTapOutside: (_) => _dismissTooltip(),
                child: _FinanceExpenseTooltip(
                  width: placement.width,
                  arrowX: placement.arrowX,
                  above: placement.above,
                  day: selection.date,
                  total: selection.total,
                  expenses: selection.expenses,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _dismissTooltip() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    widget.tooltipOpen.value = false;
    if (mounted) {
      setState(() {
        _selection = null;
        _placement = null;
      });
    }
  }

  void _showAnchoredDayTooltip(
    BuildContext cellContext,
    DateTime day,
    List<MoneyTransaction> expenses,
  ) {
    final box = cellContext.findRenderObject()! as RenderBox;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    final screen = MediaQuery.sizeOf(cellContext);
    const width = 220.0;
    final left = (rect.center.dx - width / 2)
        .clamp(16.0, screen.width - width - 16)
        .toDouble();
    final above = rect.top > 170;
    final top = above ? rect.top - 148 : rect.bottom + 10;
    final dayExpenses = expenses.where((transaction) {
      return transaction.date.year == day.year &&
          transaction.date.month == day.month &&
          transaction.date.day == day.day;
    }).toList();
    final total = _totalForTransactions(dayExpenses);

    showGeneralDialog<void>(
      context: cellContext,
      barrierDismissible: true,
      barrierLabel: 'Dismiss expense details',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, _, _) => Stack(
        children: [
          Positioned(
            left: left,
            top: top,
            child: _FinanceExpenseTooltip(
              width: width,
              arrowX: rect.center.dx - left,
              above: above,
              day: day,
              total: total,
              expenses: dayExpenses,
            ),
          ),
        ],
      ),
      transitionBuilder: (_, animation, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        child: ScaleTransition(
          scale: Tween<double>(begin: .96, end: 1).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      ),
    );
  }

  void _showDayTooltip(
    BuildContext cellContext,
    DateTime day,
    List<MoneyTransaction> expenses,
  ) {
    final box = cellContext.findRenderObject()! as RenderBox;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    final dayExpenses = expenses.where((transaction) {
      return transaction.date.year == day.year &&
          transaction.date.month == day.month &&
          transaction.date.day == day.day;
    }).toList();
    final total = _totalForTransactions(dayExpenses);
    showMenu<void>(
      context: cellContext,
      position: RelativeRect.fromRect(
        rect,
        Offset.zero & MediaQuery.sizeOf(cellContext),
      ),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppColors.surface,
      items: [
        PopupMenuItem<void>(
          enabled: false,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: SizedBox(
            width: 210,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEE, MMM d').format(day),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '₹${_formatAbsoluteFinanceAmount(total)} spent',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (dayExpenses.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  for (final transaction in dayExpenses.take(3))
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(
                            financeCategoryIcon(transaction.category),
                            size: 15,
                            color: _catIconColor(transaction.category),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              transaction.note?.isNotEmpty == true
                                  ? transaction.note!
                                  : transaction.category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                              ),
                            ),
                          ),
                          Text(
                            '₹${_formatAbsoluteFinanceAmount(_moneyMajorAmount(transaction.amount))}',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                ] else
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'No expenses recorded',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showDayDetails(
    BuildContext context,
    DateTime day,
    List<MoneyTransaction> expenses,
  ) {
    final dayExpenses = expenses.where((transaction) {
      return transaction.date.year == day.year &&
          transaction.date.month == day.month &&
          transaction.date.day == day.day;
    }).toList();
    final total = _totalForTransactions(dayExpenses);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('EEEE, d MMM yyyy').format(day),
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Total spent  ₹${_formatAbsoluteFinanceAmount(total)}',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            for (final transaction in dayExpenses)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      financeCategoryIcon(transaction.category),
                      size: 18,
                      color: _catIconColor(transaction.category),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        transaction.note?.isNotEmpty == true
                            ? transaction.note!
                            : transaction.category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text(
                      '₹${_formatAbsoluteFinanceAmount(_moneyMajorAmount(transaction.amount))}',
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
            if (dayExpenses.isEmpty)
              const Text(
                'No expenses recorded',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FinanceHeatmapSelection {
  const _FinanceHeatmapSelection(this.date, this.total, this.expenses);
  final DateTime date;
  final double total;
  final List<MoneyTransaction> expenses;
}

class _FinanceHeatmapPlacement {
  const _FinanceHeatmapPlacement({
    required this.above,
    required this.width,
    required this.offsetX,
    required this.arrowX,
    required this.cellHeight,
  });

  final bool above;
  final double width;
  final double offsetX;
  final double arrowX;
  final double cellHeight;

  Offset get offset =>
      Offset(offsetX, above ? cellHeight / 2 : -cellHeight / 2);
}

class _FinanceExpenseTooltip extends StatefulWidget {
  const _FinanceExpenseTooltip({
    required this.width,
    required this.arrowX,
    required this.above,
    required this.day,
    required this.total,
    required this.expenses,
  });

  final double width;
  final double arrowX;
  final bool above;
  final DateTime day;
  final double total;
  final List<MoneyTransaction> expenses;

  @override
  State<_FinanceExpenseTooltip> createState() => _FinanceExpenseTooltipState();
}

class _FinanceExpenseTooltipState extends State<_FinanceExpenseTooltip> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: .96, end: 1),
    duration: const Duration(milliseconds: 180),
    curve: Curves.easeOutCubic,
    builder: (context, scale, child) => Opacity(
      opacity: (scale - .96) / .04,
      child: Transform.scale(scale: scale, child: child),
    ),
    child: CustomPaint(
      painter: _FinanceTooltipPainter(
        above: widget.above,
        arrowX: widget.arrowX,
      ),
      child: Container(
        width: widget.width,
        padding: const EdgeInsets.fromLTRB(12, 11, 12, 13),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('EEE, MMM d').format(widget.day),
              style: AppTextStyles.caption(context).copyWith(
                fontSize: 12,
                height: 16 / 12,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '₹${_formatAbsoluteFinanceAmount(widget.total)} spent',
              style: AppTextStyles.cardTitle(context).copyWith(
                fontSize: 13,
                height: 18 / 13,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.none,
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: widget.expenses.length > 10 ? 212 : double.infinity,
              ),
              child: ScrollbarTheme(
                data: ScrollbarThemeData(
                  thumbColor: WidgetStatePropertyAll(
                    AppColors.textSecondary.withAlpha(150),
                  ),
                  trackColor: WidgetStatePropertyAll(
                    AppColors.divider.withAlpha(90),
                  ),
                ),
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: widget.expenses.length > 10,
                  thickness: 3,
                  radius: const Radius.circular(3),
                  trackVisibility: widget.expenses.length > 10,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.only(right: 5),
                    child: Column(
                      children: [
                        for (final transaction in widget.expenses)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              children: [
                                Icon(
                                  financeCategoryIcon(transaction.category),
                                  size: 15,
                                  color: _catIconColor(transaction.category),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    transaction.note?.isNotEmpty == true
                                        ? transaction.note!
                                        : transaction.category,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.body(context).copyWith(
                                      fontSize: 10,
                                      height: 14 / 10,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ),
                                Text(
                                  '₹${_formatAbsoluteFinanceAmount(_moneyMajorAmount(transaction.amount))}',
                                  style: AppTextStyles.body(context).copyWith(
                                    fontSize: 10,
                                    height: 14 / 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.danger,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (widget.expenses.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 7),
                child: Text(
                  'No expenses recorded',
                  style: AppTextStyles.body(context).copyWith(
                    fontSize: 10,
                    height: 14 / 10,
                    color: AppColors.textSecondary,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _FinanceTooltipPainter extends CustomPainter {
  const _FinanceTooltipPainter({required this.above, required this.arrowX});
  final bool above;
  final double arrowX;

  @override
  void paint(Canvas canvas, Size size) {
    const arrowWidth = 12.0;
    const arrowHeight = 7.0;
    final top = above ? 0.0 : arrowHeight;
    final bottom = above ? size.height - arrowHeight : size.height;
    final rect = Rect.fromLTRB(0, top, size.width, bottom);
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16)));
    final x = arrowX.clamp(14.0, size.width - 14.0).toDouble();
    if (above) {
      path.moveTo(x - arrowWidth / 2, size.height - arrowHeight);
      path.lineTo(x, size.height);
      path.lineTo(x + arrowWidth / 2, size.height - arrowHeight);
    } else {
      path.moveTo(x - arrowWidth / 2, arrowHeight);
      path.lineTo(x, 0);
      path.lineTo(x + arrowWidth / 2, arrowHeight);
    }
    canvas.drawShadow(path, const Color(0x40000000), 8, false);
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.surface
        ..isAntiAlias = true,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.divider
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _FinanceTooltipPainter oldDelegate) =>
      oldDelegate.above != above || oldDelegate.arrowX != arrowX;
}

class _FinanceHeatmapLabel extends StatelessWidget {
  const _FinanceHeatmapLabel(this.label, {this.last = false});
  final String label;
  final bool last;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: _FinanceExpenseHeatmap._cellSize + (last ? 0 : 3),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(label, style: _financeHeatmapLabelStyle),
    ),
  );
}

class _FinanceExpenseMonthGroup extends StatelessWidget {
  const _FinanceExpenseMonthGroup({
    required this.month,
    required this.totals,
    required this.maxSpend,
    required this.linkFor,
    required this.onDayTap,
  });

  final DateTime month;
  final Map<DateTime, double> totals;
  final double maxSpend;
  final LayerLink Function(DateTime) linkFor;
  final void Function(BuildContext, DateTime) onDayTap;

  @override
  Widget build(BuildContext context) {
    final monthEnd = DateTime(month.year, month.month + 1, 0);
    final gridStart = month.subtract(Duration(days: month.weekday % 7));
    final gridEnd = monthEnd.add(Duration(days: 6 - monthEnd.weekday % 7));
    final weekCount = gridEnd.difference(gridStart).inDays ~/ 7 + 1;

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          SizedBox(
            width: weekCount * (_FinanceExpenseHeatmap._cellSize + 3) - 3,
            height: 16,
            child: Center(
              child: Text(
                DateFormat('MMM').format(month),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 9,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(weekCount, (week) {
              final weekStart = gridStart.add(Duration(days: week * 7));
              return Padding(
                padding: EdgeInsets.only(
                  right: week == weekCount - 1
                      ? 0
                      : _FinanceExpenseHeatmap._gap,
                ),
                child: Column(
                  children: List.generate(7, (row) {
                    final day = weekStart.add(Duration(days: row));
                    final inMonth =
                        day.month == month.month && day.year == month.year;
                    final amount = totals[day] ?? 0;
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: row == 6 ? 0 : _FinanceExpenseHeatmap._gap,
                      ),
                      child: Builder(
                        builder: (cellContext) => CompositedTransformTarget(
                          link: linkFor(day),
                          child: GestureDetector(
                            onTap: inMonth
                                ? () => onDayTap(cellContext, day)
                                : null,
                            child: inMonth
                                ? DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: _expenseHeatColor(
                                        amount,
                                        maxSpend,
                                      ),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    child: const SizedBox(
                                      width: _FinanceExpenseHeatmap._cellSize,
                                      height: _FinanceExpenseHeatmap._cellSize,
                                    ),
                                  )
                                : const SizedBox(
                                    width: _FinanceExpenseHeatmap._cellSize,
                                    height: _FinanceExpenseHeatmap._cellSize,
                                  ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

const _financeHeatmapLabelStyle = TextStyle(
  fontFamily: 'Poppins',
  fontSize: 8,
  color: AppColors.textSecondary,
);

Color _expenseHeatColor(double amount, double maxAmount) {
  if (amount <= 0 || maxAmount <= 0) return heatmapColors[0];
  final ratio = amount / maxAmount;
  if (ratio < .2) return heatmapColors[1];
  if (ratio < .4) return heatmapColors[2];
  if (ratio < .6) return heatmapColors[3];
  if (ratio < .8) return heatmapColors[4];
  return heatmapColors[5];
}

class _LegacyOverviewContent extends StatelessWidget {
  const _LegacyOverviewContent({required this.transactions});

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
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
    margin: const EdgeInsets.symmetric(horizontal: 3),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.divider),
      boxShadow: const [
        BoxShadow(
          color: Color(0x16000000),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Column(
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
    ),
  );
}

class _GroupedTransactionList extends StatelessWidget {
  const _GroupedTransactionList({
    super.key,
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

class _DailyTransactionGroup extends StatefulWidget {
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
  State<_DailyTransactionGroup> createState() => _DailyTransactionGroupState();
}

class _DailyTransactionGroupState extends State<_DailyTransactionGroup> {
  bool _isCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final income = widget.transactions.fold(0.0, (sum, transaction) {
      final isIncome =
          transaction.type == 'income' || transaction.type == 'borrowed';
      return isIncome ? sum + _moneyMajorAmount(transaction.amount) : sum;
    });
    final expense = widget.transactions.fold(0.0, (sum, transaction) {
      final isExpense =
          transaction.type == 'expense' || transaction.type == 'lent';
      return isExpense ? sum + _moneyMajorAmount(transaction.amount) : sum;
    });
    final net = income - expense;

    final headerSummary = switch (widget.summaryFilter) {
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
      child: AnimatedSize(
        duration: DimiMotion.smooth,
        curve: DimiMotion.transitionCurve,
        alignment: Alignment.topCenter,
        child: _isCollapsed
            ? _buildCollapsedCard(income, expense)
            : Container(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _isCollapsed = true),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceDark,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(15),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _dateLabel(
                                  widget.date,
                                  widget.useRelativeDates,
                                ),
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            if (widget.summaryFilter == 'all') ...[
                              _FinanceAmountText(
                                text:
                                    '+₹${_formatAbsoluteFinanceAmount(income)}',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.success,
                                ),
                              ),
                              const SizedBox(width: 7),
                              _FinanceAmountText(
                                text:
                                    '-₹${_formatAbsoluteFinanceAmount(expense)}',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.danger,
                                ),
                              ),
                            ] else
                              _FinanceAmountText(
                                text:
                                    headerSummary ?? _formatFinanceAmount(net),
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      (widget.summaryFilter == 'expense' ||
                                          (widget.summaryFilter == 'loan' &&
                                              net < 0))
                                      ? AppColors.danger
                                      : AppColors.success,
                                ),
                              ),
                            const SizedBox(width: 3),
                            const Icon(
                              Icons.keyboard_arrow_up_rounded,
                              size: 21,
                              color: Colors.white70,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    for (final transaction in widget.transactions)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
                        child: _TransactionTile(txn: transaction),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildCollapsedCard(double income, double expense) => GestureDetector(
    onTap: () => setState(() => _isCollapsed = false),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: _buildDateSummary(
        dateLabel: _dateLabel(widget.date, false),
        income: income,
        expense: expense,
        icon: Icons.keyboard_arrow_down_rounded,
      ),
    ),
  );

  Widget _buildDateSummary({
    required String dateLabel,
    required double income,
    required double expense,
    required IconData icon,
  }) => Row(
    children: [
      Expanded(
        child: Text(
          dateLabel,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      _FinanceAmountText(
        text: '+₹${_formatAbsoluteFinanceAmount(income)}',
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.success,
        ),
      ),
      const SizedBox(width: 8),
      _FinanceAmountText(
        text: '-₹${_formatAbsoluteFinanceAmount(expense)}',
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.danger,
        ),
      ),
      const SizedBox(width: 5),
      Icon(icon, size: 22, color: Colors.white70),
    ],
  );
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
    required this.onTypeSelected,
  });

  final String selectedType;
  final ValueChanged<String> onTypeSelected;

  @override
  Widget build(BuildContext context) {
    const filters = [
      ('all', 'All', Icons.grid_view_rounded),
      ('income', 'Income', Icons.arrow_downward_rounded),
      ('expense', 'Expense', Icons.arrow_upward_rounded),
      ('loan', 'Lent/Borrowed', Icons.swap_horiz_rounded),
    ];

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final filter in filters)
              _FinanceFilterPill(
                label: filter.$2,
                icon: filter.$3,
                selected: selectedType == filter.$1,
                onTap: () => onTypeSelected(filter.$1),
              ),
          ],
        ),
      ),
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
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: DimiMotion.fast,
        curve: DimiMotion.transitionCurve,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: _filterIconColor(label, selected)),
            const SizedBox(width: 5),
            Text(
              label,
              maxLines: 1,
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
  );
}

Color _filterIconColor(String label, bool selected) {
  if (selected || label == 'All') return AppColors.textPrimary;
  return switch (label) {
    'Income' => AppColors.success,
    'Expense' => AppColors.danger,
    _ => AppColors.info,
  };
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

// ── Filter Expenses Dialog ────────────────────────────────────────────────────

// Fixed canonical category order — drives the no-scroll grid.
const _kFilterCategories = [
  'All categories',
  'Food & Dining',
  'Grocery',
  'Shopping',
  'Transport',
  'Utilities',
  'Entertainment',
  'Health',
  'Education',
  'Sundries',
  'Gift',
  'Salary',
  'Allowance',
  'Freelance',
  'Borrowed',
  'Lent',
  'Other',
];

Color _catIconColor(String category) => switch (category) {
  'All categories' => AppColors.accent,
  'Allowance' => const Color(0xFF7C4DFF),
  'Education' => const Color(0xFF5C6BC0),
  'Entertainment' => const Color(0xFFE64A19),
  'Food & Dining' => const Color(0xFFF5A623),
  'Freelance' => const Color(0xFF2E7D32),
  'Gift' => const Color(0xFFE91E63),
  'Grocery' => const Color(0xFF43A047),
  'Health' => const Color(0xFFE53935),
  'Lent' => const Color(0xFF1E88E5),
  'Borrowed' => const Color(0xFF1E88E5),
  'Other' => const Color(0xFF757575),
  'Salary' => const Color(0xFF2E7D32),
  'Shopping' => const Color(0xFF8E24AA),
  'Sundries' => const Color(0xFFFF8F00),
  'Transport' => const Color(0xFF1976D2),
  'Utilities' => const Color(0xFFFBC02D),
  _ => AppColors.textSecondary,
};

class _FinanceCategoryFilterDialog extends StatefulWidget {
  const _FinanceCategoryFilterDialog({
    required this.categories,
    required this.selected,
  });

  final List<String> categories;
  final Set<String> selected;

  @override
  State<_FinanceCategoryFilterDialog> createState() =>
      _FinanceCategoryFilterDialogState();
}

class _FinanceCategoryFilterDialogState
    extends State<_FinanceCategoryFilterDialog> {
  late final Set<String> _selected = {...widget.selected};

  @override
  Widget build(BuildContext context) {
    // Merge canonical list with any DB categories not in it
    final extras =
        widget.categories.where((c) => !_kFilterCategories.contains(c)).toList()
          ..sort();
    final allCats = [..._kFilterCategories, ...extras];

    final visible = allCats;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x28000000),
            blurRadius: 32,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // handle
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 8),

          // header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 40,
                  height: 50,
                  child: const Icon(
                    Icons.bar_chart_rounded,
                    color: AppColors.accent,
                    size: 42,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Filter Expenses',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Select categories to filter your transactions.',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),

          // grid — shrinkWrap, no scroll
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: visible.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 4,
                mainAxisSpacing: 3,
                childAspectRatio: .9,
              ),
              itemBuilder: (context, i) {
                final cat = visible[i];
                final isAll = cat == 'All categories';
                final isSel = isAll
                    ? _selected.isEmpty
                    : _selected.contains(cat);
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() {
                    if (isAll) {
                      _selected.clear();
                    } else if (isSel) {
                      _selected.remove(cat);
                    } else {
                      _selected.add(cat);
                    }
                  }),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: DimiMotion.fast,
                        width: 48,
                        height: 48,
                        decoration: isSel
                            ? BoxDecoration(
                                color: AppColors.accentSoft,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.accent,
                                  width: 1.5,
                                ),
                              )
                            : null,
                        child: Center(
                          child: Icon(
                            isAll
                                ? Icons.apps_rounded
                                : financeCategoryIcon(cat),
                            size: isSel ? 21 : 27,
                            color: isSel
                                ? AppColors.accent
                                : _catIconColor(cat),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isAll
                            ? 'All'
                            : cat == 'Food & Dining'
                            ? 'Food'
                            : cat,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 9.5,
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                          color: isSel
                              ? AppColors.accent
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // footer
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selected.clear()),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: const Center(
                        child: Text(
                          'Reset',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, _selected),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.tune_rounded,
                            size: 17,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            'Apply (${_selected.length})',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
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
}

// ── Date Period Dialog ────────────────────────────────────────────────────────

enum _DatePeriodKind {
  allDates,
  today,
  thisWeek,
  thisMonth,
  lastMonth,
  thisYear,
  custom,
}

class _FinanceDatePeriodDialog extends StatefulWidget {
  const _FinanceDatePeriodDialog({required this.selectedRange});
  final DateTimeRange? selectedRange;

  @override
  State<_FinanceDatePeriodDialog> createState() =>
      _FinanceDatePeriodDialogState();
}

class _FinanceDatePeriodDialogState extends State<_FinanceDatePeriodDialog> {
  late _DatePeriodKind _selected;
  late DateTimeRange? _customRange;

  @override
  void initState() {
    super.initState();
    _customRange = widget.selectedRange;
    _selected = _inferKind(widget.selectedRange);
  }

  _DatePeriodKind _inferKind(DateTimeRange? range) {
    if (range == null) return _DatePeriodKind.allDates;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final s = range.start;
    if (s.year == 1900) return _DatePeriodKind.allDates;
    if (s == today) return _DatePeriodKind.today;
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    if (s == weekStart) return _DatePeriodKind.thisWeek;
    if (s == DateTime(now.year, now.month)) return _DatePeriodKind.thisMonth;
    final lm = DateTime(now.year, now.month - 1);
    if (s == DateTime(lm.year, lm.month)) return _DatePeriodKind.lastMonth;
    if (s == DateTime(now.year)) return _DatePeriodKind.thisYear;
    return _DatePeriodKind.custom;
  }

  DateTimeRange _rangeForKind(_DatePeriodKind kind) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return switch (kind) {
      _DatePeriodKind.allDates => DateTimeRange(
        start: DateTime(1900),
        end: DateTime(1900),
      ),
      _DatePeriodKind.today => DateTimeRange(
        start: today,
        end: DateTime(today.year, today.month, today.day, 23, 59, 59, 999),
      ),
      _DatePeriodKind.thisWeek => () {
        final s = today.subtract(Duration(days: today.weekday - 1));
        final e = s.add(const Duration(days: 6));
        return DateTimeRange(
          start: s,
          end: DateTime(e.year, e.month, e.day, 23, 59, 59, 999),
        );
      }(),
      _DatePeriodKind.thisMonth => DateTimeRange(
        start: DateTime(now.year, now.month),
        end: DateTime(
          now.year,
          now.month + 1,
        ).subtract(const Duration(microseconds: 1)),
      ),
      _DatePeriodKind.lastMonth => () {
        final lm = DateTime(now.year, now.month - 1);
        return DateTimeRange(
          start: DateTime(lm.year, lm.month),
          end: DateTime(
            lm.year,
            lm.month + 1,
          ).subtract(const Duration(microseconds: 1)),
        );
      }(),
      _DatePeriodKind.thisYear => DateTimeRange(
        start: DateTime(now.year),
        end: DateTime(now.year + 1).subtract(const Duration(microseconds: 1)),
      ),
      _DatePeriodKind.custom =>
        _customRange ?? DateTimeRange(start: today, end: today),
    };
  }

  String _subtitle(_DatePeriodKind kind) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return switch (kind) {
      _DatePeriodKind.allDates => 'View all your transactions',
      _DatePeriodKind.today => DateFormat('d MMM yyyy').format(today),
      _DatePeriodKind.thisWeek => () {
        final s = today.subtract(Duration(days: today.weekday - 1));
        final e = s.add(const Duration(days: 6));
        return '${DateFormat('d').format(s)} – ${DateFormat('d MMM yyyy').format(e)}';
      }(),
      _DatePeriodKind.thisMonth => DateFormat('MMMM yyyy').format(now),
      _DatePeriodKind.lastMonth => DateFormat(
        'MMMM yyyy',
      ).format(DateTime(now.year, now.month - 1)),
      _DatePeriodKind.thisYear => '${now.year}',
      _DatePeriodKind.custom =>
        _customRange != null
            ? '${DateFormat('d MMM yyyy').format(_customRange!.start)}'
                  ' → ${DateFormat('d MMM yyyy').format(_customRange!.end)}'
            : 'Tap to set range',
    };
  }

  IconData _icon(_DatePeriodKind kind) => switch (kind) {
    _DatePeriodKind.allDates => Icons.calendar_today_outlined,
    _DatePeriodKind.today => Icons.wb_sunny_outlined,
    _DatePeriodKind.thisWeek => Icons.view_week_outlined,
    _DatePeriodKind.thisMonth => Icons.calendar_month_outlined,
    _DatePeriodKind.lastMonth => Icons.undo_rounded,
    _DatePeriodKind.thisYear => Icons.bar_chart_rounded,
    _DatePeriodKind.custom => Icons.date_range_outlined,
  };

  String _label(_DatePeriodKind kind) => switch (kind) {
    _DatePeriodKind.allDates => 'All dates',
    _DatePeriodKind.today => 'Today',
    _DatePeriodKind.thisWeek => 'This week',
    _DatePeriodKind.thisMonth => 'This month',
    _DatePeriodKind.lastMonth => 'Last month',
    _DatePeriodKind.thisYear => 'This year',
    _DatePeriodKind.custom => 'Custom date range',
  };

  Future<void> _pickCustomRange() async {
    final picked = await showDialog<DateTimeRange>(
      context: context,
      builder: (_) => _CustomDateRangeDialog(initialRange: _customRange),
    );
    if (picked != null && mounted) {
      setState(() {
        _customRange = picked;
        _selected = _DatePeriodKind.custom;
      });
      Navigator.pop(context, picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x28000000),
            blurRadius: 32,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // handle
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 16),

          // header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  height: 46,
                  child: const Icon(
                    Icons.calendar_today_rounded,
                    color: AppColors.accent,
                    size: 34,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Date Period',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // period list — shrinkWrap, no scroll
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: _DatePeriodKind.values.map((kind) {
                final isSel = _selected == kind;
                final isCustom = kind == _DatePeriodKind.custom;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: GestureDetector(
                    onTap: () {
                      if (isCustom) {
                        _pickCustomRange();
                      } else {
                        setState(() => _selected = kind);
                        final nav = Navigator.of(context);
                        Future.delayed(const Duration(milliseconds: 150), () {
                          nav.pop(_rangeForKind(kind));
                        });
                      }
                    },
                    child: AnimatedContainer(
                      duration: DimiMotion.fast,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSel
                            ? AppColors.accentSoft
                            : AppColors.surface.withValues(alpha: .65),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSel ? AppColors.accent : AppColors.divider,
                          width: isSel ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // plain icon — no box, no border
                          Icon(
                            _icon(kind),
                            size: 21,
                            color: isSel
                                ? AppColors.accent
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _label(kind),
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    fontWeight: isSel
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  _subtitle(kind),
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // edit pencil for custom
                          if (isCustom) ...[
                            GestureDetector(
                              onTap: _pickCustomRange,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Icon(
                                  Icons.edit_outlined,
                                  size: 17,
                                  color: isSel
                                      ? AppColors.accent
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                          // radio indicator
                          AnimatedContainer(
                            duration: DimiMotion.fast,
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.transparent,
                              border: Border.all(
                                color: isSel
                                    ? AppColors.accent
                                    : const Color(0xFFCCCCCC),
                                width: 1.8,
                              ),
                            ),
                            child: isSel
                                ? Center(
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                        color: AppColors.accent,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _CustomDateRangeDialog extends StatefulWidget {
  const _CustomDateRangeDialog({required this.initialRange});

  final DateTimeRange? initialRange;

  @override
  State<_CustomDateRangeDialog> createState() => _CustomDateRangeDialogState();
}

class _CustomDateRangeDialogState extends State<_CustomDateRangeDialog> {
  late DateTime _start;
  late DateTime _end;
  late DateTime _displayedMonth;
  bool _editingEnd = true;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _start =
        widget.initialRange?.start ??
        DateTime(today.year, today.month, today.day);
    _end = widget.initialRange?.end ?? _start.add(const Duration(days: 7));
    _displayedMonth = DateTime(_end.year, _end.month);
  }

  void _setDate(DateTime value) {
    final date = DateTime(value.year, value.month, value.day);
    setState(() {
      if (_editingEnd) {
        _end = date.isBefore(_start) ? _start : date;
      } else {
        _start = date.isAfter(_end) ? _end : date;
      }
      _displayedMonth = DateTime(date.year, date.month);
    });
  }

  String _format(DateTime value) => DateFormat('d MMM yyyy').format(value);

  @override
  Widget build(BuildContext context) {
    final firstDate = DateTime(2020);
    final lastDate = DateTime(DateTime.now().year + 2, 12, 31);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      backgroundColor: Colors.transparent,
      child: Container(
        height: 560,
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const SizedBox(
                  width: 48,
                  height: 54,
                  child: Icon(
                    Icons.calendar_month_rounded,
                    color: AppColors.accent,
                    size: 42,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Date Range',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _RangeDateField(
                    label: 'From',
                    value: _format(_start),
                    selected: !_editingEnd,
                    onTap: () => setState(() => _editingEnd = false),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 7),
                  child: Icon(Icons.arrow_forward_rounded, size: 16),
                ),
                Expanded(
                  child: _RangeDateField(
                    label: 'To',
                    value: _format(_end),
                    selected: _editingEnd,
                    onTap: () => setState(() => _editingEnd = true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            _RangeCalendar(
              month: _displayedMonth,
              start: _start,
              end: _end,
              firstDate: firstDate,
              lastDate: lastDate,
              onPreviousMonth: () => setState(() {
                _displayedMonth = DateTime(
                  _displayedMonth.year,
                  _displayedMonth.month - 1,
                );
              }),
              onNextMonth: () => setState(() {
                _displayedMonth = DateTime(
                  _displayedMonth.year,
                  _displayedMonth.month + 1,
                );
              }),
              onDateSelected: _setDate,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() {
                      final today = DateTime.now();
                      _start = DateTime(today.year, today.month, today.day);
                      _end = _start;
                      _displayedMonth = DateTime(today.year, today.month);
                    }),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      backgroundColor: AppColors.background,
                      side: const BorderSide(color: AppColors.divider),
                      minimumSize: const Size.fromHeight(46),
                    ),
                    child: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.surface,
                      minimumSize: const Size.fromHeight(46),
                    ),
                    onPressed: () => Navigator.pop(
                      context,
                      DateTimeRange(
                        start: _start,
                        end: DateTime(
                          _end.year,
                          _end.month,
                          _end.day,
                          23,
                          59,
                          59,
                          999,
                        ),
                      ),
                    ),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RangeCalendar extends StatelessWidget {
  const _RangeCalendar({
    required this.month,
    required this.start,
    required this.end,
    required this.firstDate,
    required this.lastDate,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onDateSelected,
  });

  final DateTime month;
  final DateTime start;
  final DateTime end;
  final DateTime firstDate;
  final DateTime lastDate;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onDateSelected;

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final firstWeekday = DateTime(month.year, month.month, 1).weekday % 7;
    final days = DateUtils.getDaysInMonth(month.year, month.month);
    final cells = firstWeekday + days;
    final totalCells = cells + ((7 - cells % 7) % 7);
    final weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                DateFormat('MMMM yyyy').format(month),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            IconButton(
              onPressed:
                  month.isAfter(DateTime(firstDate.year, firstDate.month))
                  ? onPreviousMonth
                  : null,
              icon: const Icon(Icons.chevron_left_rounded),
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              onPressed: month.isBefore(DateTime(lastDate.year, lastDate.month))
                  ? onNextMonth
                  : null,
              icon: const Icon(Icons.chevron_right_rounded),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        Row(
          children: weekdays
              .map(
                (day) => Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: totalCells,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.35,
          ),
          itemBuilder: (context, index) {
            if (index < firstWeekday || index >= firstWeekday + days) {
              return const SizedBox.shrink();
            }
            final date = DateTime(
              month.year,
              month.month,
              index - firstWeekday + 1,
            );
            final inRange = !date.isBefore(start) && !date.isAfter(end);
            final endpoint = _sameDay(date, start) || _sameDay(date, end);
            final column = index % 7;
            final enabled =
                !date.isBefore(firstDate) && !date.isAfter(lastDate);
            return GestureDetector(
              onTap: enabled ? () => onDateSelected(date) : null,
              child: Container(
                margin: EdgeInsets.zero,
                decoration: BoxDecoration(
                  color: inRange
                      ? AppColors.accent.withValues(alpha: .22)
                      : Colors.transparent,
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(
                      inRange && (column == 0 || _sameDay(date, start)) ? 8 : 0,
                    ),
                    right: Radius.circular(
                      inRange && (column == 6 || _sameDay(date, end)) ? 8 : 0,
                    ),
                  ),
                ),
                child: Center(
                  child: Container(
                    width: endpoint ? 30 : null,
                    height: endpoint ? 30 : null,
                    alignment: Alignment.center,
                    decoration: endpoint
                        ? const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          )
                        : null,
                    child: Text(
                      '${date.day}',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: endpoint
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: endpoint
                            ? AppColors.surface
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _RangeDateField extends StatelessWidget {
  const _RangeDateField({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? AppColors.accentSoft : AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? AppColors.accent : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_today_outlined,
            size: 16,
            color: AppColors.accent,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
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
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
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
                icon: Icons.arrow_forward_rounded,
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
                icon: Icons.arrow_back_rounded,
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
          boxShadow: const [
            BoxShadow(
              color: Color(0x16000000),
              blurRadius: 14,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: color),
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
