import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/database.dart';
import '../providers/money_providers.dart';
import '../theme/app_theme.dart';

Future<void> showAddExpenseSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AddExpenseSheet(),
  );
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

    if (mounted) Navigator.of(context).pop();
  }

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add Transaction',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: AppColors.accentSoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 15,
                      color: AppColors.textSecondary,
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

                    // Category dropdown
                    _Label('Category'),
                    const SizedBox(height: 5),
                    _DropdownField<String>(
                      value: _category,
                      items: _categories,
                      onChanged: (v) =>
                          setState(() => _category = v ?? _category),
                    ),
                    const SizedBox(height: 12),

                    // Note
                    _Label('Note (optional)'),
                    const SizedBox(height: 5),
                    TextFormField(
                      controller: _noteCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Add a note (optional)',
                      ),
                    ),
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
                            : const Text('Add Transaction'),
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

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.value,
    required this.items,
    required this.onChanged,
  });
  final T value;
  final List<T> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: AppColors.textSecondary,
          ),
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: AppColors.textPrimary,
          ),
          items: items
              .map(
                (i) => DropdownMenuItem<T>(value: i, child: Text(i.toString())),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
