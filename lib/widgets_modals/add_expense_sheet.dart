import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/database.dart';
import '../providers/money_providers.dart';
import '../theme/app_theme.dart';
import 'fixed_dialog.dart';

Future<void> showAddExpenseSheet(BuildContext context) async {
  final saved = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Add Expense',
    barrierColor: const Color(0x99000000),
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (_, _, _) =>
        const DimiFixedDialog(height: 410, child: _AddExpenseSheet()),
    transitionBuilder: (_, animation, __, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      final slideAnimation = Tween<Offset>(
        begin: const Offset(0, 0.08),
        end: Offset.zero,
      ).animate(curvedAnimation);
      final fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(curvedAnimation);
      return FadeTransition(
        opacity: fadeAnimation,
        child: SlideTransition(position: slideAnimation, child: child),
      );
    },
  );
  if (saved == true && context.mounted) {
    await showDialog<void>(
      context: context,
      barrierColor: AppColors.textPrimary.withAlpha(150),
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.surface,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Expense Added!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            const Text(
              'Your money picture is up to date.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.background,
                  foregroundColor: AppColors.textPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
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

class _AddExpenseSheet extends ConsumerStatefulWidget {
  const _AddExpenseSheet();

  @override
  ConsumerState<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends ConsumerState<_AddExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _amountFocusNode = FocusNode();

  String _type = 'expense'; // "expense" | "income" | "lent" | "borrowed"
  String _category = 'Sundries';
  DateTime _date = DateTime.now();
  bool _saving = false;

  static const _types = [
    _TypeOption(value: 'expense', label: 'Expense', color: AppColors.danger),
    _TypeOption(value: 'income', label: 'Income', color: AppColors.success),
    _TypeOption(value: 'lent', label: 'Lent', color: AppColors.info),
    _TypeOption(value: 'borrowed', label: 'Borrowed', color: AppColors.info),
  ];

  static const _expenseCategories = [
    'Sundries',
    'Grocery',
    'Food & Dining',
    'Transport',
    'Shopping',
    'Entertainment',
    'Health',
    'Education',
    'Utilities',
    'Other',
  ];

  static const _incomeCategories = [
    'Allowance',
    'Salary',
    'Freelance',
    'Gift',
    'Other',
  ];

  bool get _isLoanType => _type == 'lent' || _type == 'borrowed';

  String get _loanCategory => _type == 'borrowed' ? 'Borrowed' : 'Lent';

  List<String> get _categories => switch (_type) {
    'income' => _incomeCategories,
    'lent' || 'borrowed' => [_loanCategory],
    _ => _expenseCategories,
  };

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
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
    if (picked != null) {
      setState(
        () => _date = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _date.hour,
          _date.minute,
        ),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final amount =
        double.tryParse(_amountCtrl.text.trim().replaceAll(',', '.')) ?? 0.0;

    await ref
        .read(moneyDaoProvider)
        .insertTransaction(
          MoneyTransactionsCompanion(
            type: Value(_type),
            amount: Value((amount * 100).round()),
            category: Value(_category),
            note: Value(
              _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
            ),
            date: Value(_date),
          ),
        );

    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 18,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 108,
                    height: 94,
                    child: Image.asset(
                      'assets/illustrations/Finance.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Add Expense',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 7),
                        TextFormField(
                          controller: _noteCtrl,
                          autofocus: true,
                          onChanged: (_) => setState(() {}),
                          maxLength: 40,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(40),
                          ],
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.sentences,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                          ),
                          decoration: InputDecoration(
                            hintText: 'What was this for?',
                            counterText: '',
                            suffixText: '${_noteCtrl.text.length}/40',
                            suffixStyle: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 9,
                              color: AppColors.textSecondary,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          onFieldSubmitted: (_) =>
                              _amountFocusNode.requestFocus(),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: AppColors.background,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Form
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type selector row
                    Row(
                      children: _types
                          .map(
                            (t) => Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: _TypeChip(
                                  option: t,
                                  selected: _type == t.value,
                                  onTap: () => setState(() {
                                    _type = t.value;
                                    _category = _isLoanType
                                        ? _loanCategory
                                        : _categories.first;
                                  }),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 14),

                    // Amount and date
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _amountCtrl,
                            autofocus: false,
                            focusNode: _amountFocusNode,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}'),
                              ),
                            ],
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                            ),
                            decoration: const InputDecoration(
                              hintText: '0.00',
                              errorStyle: TextStyle(fontSize: 0, height: 0),
                              prefixText: '₹ ',
                              prefixStyle: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Amount is required';
                              }
                              final n = double.tryParse(
                                v.trim().replaceAll(',', '.'),
                              );
                              if (n == null || n <= 0) {
                                return 'Enter a valid amount';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 132,
                          child: _ExpenseDateButton(
                            date: _date,
                            onTap: _pickDate,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Categories
                    if (_isLoanType)
                      _LockedCategory(
                        label: _loanCategory,
                        icon: _categoryIcon(_loanCategory),
                      )
                    else
                      _CategoryPicker(
                        categories: _categories,
                        selected: _category,
                        onSelected: (category) =>
                            setState(() => _category = category),
                      ),
                    const SizedBox(height: 4),

                    // Submit
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 0,
                          textStyle: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.surface,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Add Expense'),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded, size: 19),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _ExpenseDateButton extends StatelessWidget {
  const _ExpenseDateButton({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_today_outlined,
            size: 18,
            color: AppColors.surface,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                DateFormat('d MMM').format(date),
                maxLines: 1,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.surface,
                ),
              ),
            ),
          ),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: AppColors.surface,
          ),
        ],
      ),
    ),
  );
}

class _TypeOption {
  const _TypeOption({
    required this.value,
    required this.label,
    required this.color,
  });
  final String value;
  final String label;
  final Color color;
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.option,
    required this.selected,
    required this.onTap,
  });
  final _TypeOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.surfaceDark : AppColors.background,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: selected ? AppColors.surfaceDark : AppColors.divider,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            option.label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? AppColors.surface : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selected;
          final color = isSelected ? AppColors.accent : AppColors.textSecondary;
          return GestureDetector(
            onTap: () => onSelected(category),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accentSoft
                        : AppColors.background,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.accent : AppColors.divider,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Icon(_categoryIcon(category), size: 22, color: color),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 66,
                  child: Text(
                    _shortCategoryName(category),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 9.5,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isSelected
                          ? AppColors.accent
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LockedCategory extends StatelessWidget {
  const _LockedCategory({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 86,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accent, width: 1.5),
            ),
            child: Icon(icon, size: 22, color: AppColors.accent),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

IconData financeCategoryIcon(String category) => switch (category) {
  'Sundries' => Icons.receipt_long_rounded,
  'Grocery' => Icons.shopping_cart_rounded,
  'Food & Dining' => Icons.restaurant_rounded,
  'Transport' => Icons.directions_car_filled_rounded,
  'Shopping' => Icons.shopping_bag_rounded,
  'Entertainment' => Icons.movie_rounded,
  'Health' => Icons.favorite_rounded,
  'Education' => Icons.school_rounded,
  'Utilities' => Icons.lightbulb_rounded,
  'Allowance' => Icons.account_balance_wallet_rounded,
  'Salary' => Icons.payments_rounded,
  'Freelance' => Icons.laptop_mac_rounded,
  'Gift' => Icons.card_giftcard_rounded,
  'Lent' => Icons.arrow_upward_rounded,
  'Borrowed' => Icons.arrow_downward_rounded,
  _ => Icons.more_horiz_rounded,
};

IconData _categoryIcon(String category) => financeCategoryIcon(category);

String _shortCategoryName(String category) =>
    category == 'Food & Dining' ? 'Food' : category;
