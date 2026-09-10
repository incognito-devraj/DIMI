import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/database.dart';
import '../providers/money_providers.dart';
import '../theme/app_theme.dart';

Future<void> showAddExpenseSheet(BuildContext context) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AddExpenseSheet(),
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

  String _type = 'expense'; // "expense" | "income" | "loan"
  String _category = 'Food & Dining';
  DateTime _date = DateTime.now();
  bool _saving = false;

  static const _types = [
    _TypeOption(value: 'expense', label: 'Expense', color: AppColors.danger),
    _TypeOption(value: 'income', label: 'Income', color: AppColors.success),
    _TypeOption(value: 'loan', label: 'Loan', color: AppColors.info),
  ];

  static const _expenseCategories = [
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

  static const _loanCategories = ['Lent', 'Borrowed', 'Other'];

  List<String> get _categories => switch (_type) {
    'income' => _incomeCategories,
    'loan' => _loanCategories,
    _ => _expenseCategories,
  };

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
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
    if (picked != null) setState(() => _date = picked);
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
            amount: Value(amount),
            category: Value(_category),
            note: Value(
              _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
            ),
            date: Value(_date),
          ),
        );

    if (mounted) Navigator.of(context).pop(true);
  }

  Future<String?> _showAllCategories() => showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _FullCategoryPicker(
      categories: _categories,
      selected: _category,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      margin: const EdgeInsets.only(top: 48),
      padding: EdgeInsets.only(bottom: inset),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: AppColors.accent,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Expense',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Keep your money picture clear.',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
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
          Flexible(
            child: SingleChildScrollView(
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
                                    _category = _categories.first;
                                  }),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 14),

                    // Amount
                    _Label('Amount'),
                    const SizedBox(height: 5),
                    TextFormField(
                      controller: _amountCtrl,
                      autofocus: true,
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
                    const SizedBox(height: 12),

                    const SizedBox(height: 12),
                    _Label('Description (optional)'),
                    const SizedBox(height: 5),
                    TextFormField(
                      controller: _noteCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'What was this for?',
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Compact horizontal category picker
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const _Label('Category'),
                        GestureDetector(
                          onTap: () async {
                            final category = await _showAllCategories();
                            if (category != null && mounted) setState(() => _category = category);
                          },
                          child: const Row(
                            children: [
                              Text('See all', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent)),
                              Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.accent),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    _CategoryPicker(
                      categories: _categories,
                      selected: _category,
                      onSelected: (category) =>
                          setState(() => _category = category),
                    ),
                    const SizedBox(height: 12),

                    if (mounted && !mounted) ...[
                    _Label('Description (optional)'),
                    const SizedBox(height: 5),
                    TextFormField(controller: _noteCtrl),
                    ],
                    const SizedBox(height: 12),

                    // Date
                    _Label('Date'),
                    const SizedBox(height: 5),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('d MMM yyyy').format(_date),
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit
                    SizedBox(
                      width: double.infinity,
                      height: 48,
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
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

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
          color: selected ? option.color.withAlpha(26) : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? option.color : AppColors.divider,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            option.label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? option.color : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
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
                  color: isSelected ? AppColors.accentSoft : AppColors.background,
                  shape: BoxShape.circle,
                  border: Border.all(color: isSelected ? AppColors.accent : AppColors.divider, width: isSelected ? 1.5 : 1),
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
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 9.5, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, color: isSelected ? AppColors.accent : AppColors.textSecondary),
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

class _FullCategoryPicker extends StatelessWidget {
  const _FullCategoryPicker({required this.categories, required this.selected});
  final List<String> categories;
  final String selected;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
    decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    child: SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 38, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(4)))),
          const SizedBox(height: 18),
          const Text('Choose a category', style: TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 12, mainAxisSpacing: 14, childAspectRatio: .9),
            itemBuilder: (_, index) {
              final category = categories[index];
              final isSelected = category == selected;
              return GestureDetector(
                onTap: () => Navigator.pop(context, category),
                child: Column(children: [
                  Container(width: 52, height: 52, decoration: BoxDecoration(color: isSelected ? AppColors.accentSoft : AppColors.background, shape: BoxShape.circle, border: Border.all(color: isSelected ? AppColors.accent : AppColors.divider, width: isSelected ? 1.5 : 1)), child: Icon(_categoryIcon(category), color: isSelected ? AppColors.accent : AppColors.textSecondary)),
                  const SizedBox(height: 5),
                  Text(_shortCategoryName(category), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, color: isSelected ? AppColors.accent : AppColors.textSecondary)),
                ]),
              );
            },
          ),
        ],
      ),
    ),
  );
}

IconData _categoryIcon(String category) => switch (category) {
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

String _shortCategoryName(String category) => category == 'Food & Dining'
    ? 'Food'
    : category;
