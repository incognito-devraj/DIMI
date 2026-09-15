import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

import '../data/database.dart';
import '../providers/task_providers.dart';
import '../providers/reminder_providers.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../utils/todo_text.dart';
import '../widgets/dimi_success_dialog.dart';

/// Opens the Add/Edit Task modal bottom sheet.
/// Pass [existingTask] to enter edit mode.
Future<void> showAddTaskSheet(
  BuildContext context, {
  DateTime? initialDate,
  Task? existingTask,
  bool plannerEntry = false,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AddTaskSheet(
      initialDate: initialDate,
      existingTask: existingTask,
      plannerEntry: plannerEntry,
    ),
  );
  if (saved == true && context.mounted) {
    await showDimiSuccessDialog(
      context,
      title: existingTask == null
          ? (plannerEntry ? 'Task Added!' : 'To-Do Added!')
          : 'Task Updated!',
    );
  }
}

class _AddTaskSheet extends ConsumerStatefulWidget {
  const _AddTaskSheet({
    this.initialDate,
    this.existingTask,
    this.plannerEntry = false,
  });
  final DateTime? initialDate;
  final Task? existingTask;
  final bool plannerEntry;

  @override
  ConsumerState<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends ConsumerState<_AddTaskSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;

  late DateTime _dueDate;
  TimeOfDay? _dueTime;
  late String _category;
  int? _reminderMinutes;
  bool _saving = false;

  bool get _isEditing => widget.existingTask != null;

  static const _categories = [
    'Study',
    'Personal',
    'College',
    'Health',
    'Finance',
    'Other',
  ];

  static const _reminderOptions = [
    (label: 'At time', value: null),
    (label: '10 min', value: 10),
    (label: '30 min', value: 30),
    (label: '1 hour', value: 60),
    (label: '1 day', value: 1440),
  ];

  @override
  void initState() {
    super.initState();
    final t = widget.existingTask;
    _titleCtrl = TextEditingController(text: t?.title ?? '');
    _descCtrl = TextEditingController(text: t?.description ?? '');
    _dueDate = t?.dueDate ?? widget.initialDate ?? DateTime.now();
    _category = t?.category ?? 'Personal';
    _reminderMinutes = t?.reminderMinutesBefore;

    if (t?.dueTime != null && t!.dueTime!.isNotEmpty) {
      final parts = t.dueTime!.split(':');
      if (parts.length == 2) {
        _dueTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
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
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme
              .copyWith(primary: AppColors.accent),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dueTime = picked);
  }

  String? _timeStr() {
    if (_dueTime == null) return null;
    return '${_dueTime!.hour.toString().padLeft(2, '0')}:'
        '${_dueTime!.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.plannerEntry && _dueTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time for the planner task.')),
      );
      return;
    }
    setState(() => _saving = true);

    final dao = ref.read(taskDaoProvider);
    final savedTitle = widget.plannerEntry
        ? _titleCtrl.text.trim()
        : formatTodoTitle(_titleCtrl.text);

    int? savedTaskId;
    if (_isEditing) {
      await dao.updateTask(
        TasksCompanion(
          id: Value(widget.existingTask!.id),
          title: Value(savedTitle),
          description: Value(
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          ),
          category: Value(_category),
          dueDate: Value(_dueDate),
          dueTime: Value(_timeStr()),
          reminderMinutesBefore: Value(_reminderMinutes),
          isCompleted: Value(widget.existingTask!.isCompleted),
          completedAt: Value(widget.existingTask!.completedAt),
          createdAt: Value(widget.existingTask!.createdAt),
          isPlannerEntry: Value(widget.existingTask!.isPlannerEntry),
          plannedMinutes: Value(widget.existingTask!.plannedMinutes),
          completedMinutes: Value(widget.existingTask!.completedMinutes),
        ),
      );
    } else {
      savedTaskId = await dao.insertTask(
        TasksCompanion(
          title: Value(savedTitle),
          description: Value(
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          ),
          category: Value(_category),
          dueDate: Value(_dueDate),
          dueTime: Value(_timeStr()),
          reminderMinutesBefore: Value(_reminderMinutes),
          isCompleted: const Value(false),
          isPlannerEntry: Value(widget.plannerEntry),
          createdAt: Value(DateTime.now()),
        ),
      );
    }

    // Planner reminders are real reminders as well as task metadata, so they
    // appear in the Reminders tab and can be completed there.
    if (!_isEditing && widget.plannerEntry && savedTaskId != null) {
      final taskTime = _dueTime!;
      final taskDueAt = DateTime(
        _dueDate.year,
        _dueDate.month,
        _dueDate.day,
        taskTime.hour,
        taskTime.minute,
      );
      final reminderDueAt = taskDueAt.add(
        Duration(minutes: _reminderMinutes ?? 0),
      );
      final reminderDao = ref.read(reminderDaoProvider);
      final reminderId = await reminderDao.insertReminder(
        RemindersCompanion.insert(
          title: savedTitle,
          dueAt: reminderDueAt,
        ),
      );
      final reminder = await reminderDao.getById(reminderId);
      if (reminder != null) {
        await NotificationService.instance.scheduleReminder(reminder);
      }
    }

    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottomInset = media.viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.only(top: 28),
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: media.size.height - 28),
          child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
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
            child: Form(
              key: _formKey,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 108,
                  height: 94,
                  child: Image.asset(
                    'assets/illustrations/Planner.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEditing
                            ? (widget.plannerEntry ? 'Edit Task' : 'Edit To-Do')
                            : (widget.plannerEntry ? 'Add Task' : 'Add To-Do'),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 7),
                      TextFormField(
                        controller: _titleCtrl,
                        autofocus: !_isEditing,
                        textCapitalization: TextCapitalization.sentences,
                        maxLength: 60,
                        inputFormatters: [LengthLimitingTextInputFormatter(60)],
                        decoration: const InputDecoration(
                          hintText: 'New task...',
                          counterText: '',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (value.isEmpty) return 'Title is required';
                          if (value.split(RegExp(r'\s+')).length > 10) {
                            return 'Keep it to 10 words or fewer';
                          }
                          return null;
                        },
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
                    child: const Icon(Icons.close_rounded, size: 18),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Form
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel('Description (optional)'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 2,
                      maxLength: 120,
                      inputFormatters: [LengthLimitingTextInputFormatter(120)],
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Add details…',
                      ),
                      validator: (v) {
                        final value = v?.trim() ?? '';
                        if (value.isNotEmpty &&
                            value.split(RegExp(r'\s+')).length > 20) {
                          return 'Keep the note to 20 words or fewer';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FieldLabel('Date'),
                              const SizedBox(height: 6),
                              _PickerBtn(
                                icon: Icons.calendar_today_outlined,
                                label: DateFormat('d MMM yyyy')
                                    .format(_dueDate),
                                onTap: _pickDate,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FieldLabel('Time *'),
                              const SizedBox(height: 6),
                              _PickerBtn(
                                icon: Icons.schedule_outlined,
                                label: _dueTime != null
                                    ? _dueTime!.format(context)
                                    : 'No time',
                                onTap: _pickTime,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _FieldLabel('Category'),
                    const SizedBox(height: 8),
                    _TaskCategoryPicker(
                      categories: _categories,
                      selected: _category,
                      onSelected: (category) =>
                          setState(() => _category = category),
                    ),
                    const SizedBox(height: 14),
                    _FieldLabel('Reminder'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _reminderOptions
                          .map(
                            (r) => _Chip(
                              label: r.label,
                              selected: _reminderMinutes == r.value,
                              onTap: () =>
                                  setState(() => _reminderMinutes = r.value),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.buttonRadius,
                            ),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.surface,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _isEditing
                                        ? 'Save Changes'
                                        : (widget.plannerEntry
                                            ? 'Create Task'
                                            : 'Create To-Do'),
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_rounded, size: 19),
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

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge
          ?.copyWith(color: AppColors.textSecondary, fontSize: 12),
    );
  }
}

class _PickerBtn extends StatelessWidget {
  const _PickerBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
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
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.surfaceDark : AppColors.accentSoft,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? AppColors.surface : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _TaskCategoryPicker extends StatelessWidget {
  const _TaskCategoryPicker({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 86,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final category = categories[index];
            final isSelected = category == selected;
            final color = isSelected
                ? AppColors.accent
                : AppColors.textSecondary;
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
                        color: isSelected
                            ? AppColors.accent
                            : AppColors.divider,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Icon(_taskCategoryIcon(category), color: color),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 66,
                    child: Text(
                      category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 9.5,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: color,
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

IconData _taskCategoryIcon(String category) => switch (category) {
  'Study' => Icons.menu_book_rounded,
  'Personal' => Icons.person_rounded,
  'College' => Icons.school_rounded,
  'Health' => Icons.favorite_rounded,
  'Finance' => Icons.account_balance_wallet_rounded,
  _ => Icons.more_horiz_rounded,
};
