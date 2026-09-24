import 'dart:math' as math;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

import '../data/database.dart';
import '../providers/task_providers.dart';
import '../providers/reminder_providers.dart';
import '../providers/database_provider.dart';
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
  final saved = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: plannerEntry ? 'Add Event' : 'Add Task',
    barrierColor: const Color(0x99000000),
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (_, _, _) => _KeyboardPositionedDialog(
      child: _AddTaskSheet(
        initialDate: initialDate,
        existingTask: existingTask,
        plannerEntry: plannerEntry,
      ),
    ),
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
    await showDimiSuccessDialog(
      context,
      title: existingTask == null
          ? (plannerEntry ? 'Event Added!' : 'To-Do Added!')
          : (plannerEntry ? 'Event Updated!' : 'Task Updated!'),
    );
  }
}

class _KeyboardPositionedDialog extends StatefulWidget {
  const _KeyboardPositionedDialog({required this.child});
  final Widget child;

  @override
  State<_KeyboardPositionedDialog> createState() =>
      _KeyboardPositionedDialogState();
}

class _KeyboardPositionedDialogState extends State<_KeyboardPositionedDialog> {
  double? _restingHeight;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final restingHeight = _restingHeight ??= MediaQuery.sizeOf(context).height;
    const dialogExtent = 434.0;
    final defaultTop = math.max(
      media.padding.top + 8,
      (restingHeight - dialogExtent) / 2,
    );
    final keyboardTop = restingHeight - media.viewInsets.bottom;
    final dialogBottom = defaultTop + dialogExtent;
    final keyboardShift = math.max(0.0, dialogBottom - keyboardTop);
    final top = math.max(media.padding.top + 8, defaultTop - keyboardShift);

    return Align(
      alignment: Alignment.topCenter,
      child: AnimatedPadding(
        padding: EdgeInsets.only(top: top),
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: Material(
          type: MaterialType.transparency,
          child: MediaQuery(
            data: media.copyWith(
              size: Size(media.size.width, restingHeight),
              viewInsets: EdgeInsets.zero,
            ),
            child: widget.child,
          ),
        ),
      ),
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
  String? _timeError;

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
    final initialDate = t?.dueDate ?? widget.initialDate ?? DateTime.now();
    _dueDate = DateTime(initialDate.year, initialDate.month, initialDate.day);
    _category = t?.category ?? 'Personal';
    _reminderMinutes = null;

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
    await _dismissKeyboardForPicker();
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
          dialogTheme: Theme.of(ctx).dialogTheme.copyWith(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 500),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 22,
              vertical: 24,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
        child: MediaQuery.removeViewInsets(
          context: ctx,
          removeBottom: true,
          child: child!,
        ),
      ),
    );
    if (picked != null && mounted) {
      setState(
        () => _dueDate = DateTime(picked.year, picked.month, picked.day),
      );
    }
  }

  Future<void> _pickTime() async {
    await _dismissKeyboardForPicker();
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme
              .copyWith(primary: AppColors.accent),
          dialogTheme: Theme.of(ctx).dialogTheme.copyWith(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 560),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 22,
              vertical: 24,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
        child: MediaQuery.removeViewInsets(
          context: ctx,
          removeBottom: true,
          child: child!,
        ),
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _dueTime = picked;
        _timeError = null;
      });
    }
  }

  String? _timeStr() {
    if (_dueTime == null) return null;
    return '${_dueTime!.hour.toString().padLeft(2, '0')}:'
        '${_dueTime!.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _dismissKeyboardForPicker() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.plannerEntry && _dueTime == null) {
      setState(() => _timeError = 'Select a time before creating the event.');
      return;
    }
    setState(() => _saving = true);

    final dao = ref.read(taskDaoProvider);
    final savedTitle = widget.plannerEntry
        ? _titleCtrl.text.trim()
        : formatTodoTitle(_titleCtrl.text);
    final dueDate = DateTime(_dueDate.year, _dueDate.month, _dueDate.day);

    int? savedTaskId;
    Reminder? reminderToSchedule;
    final db = ref.read(databaseProvider);
    await db.transaction(() async {
      if (_isEditing) {
        await dao.updateTask(
        TasksCompanion(
          id: Value(widget.existingTask!.id),
          title: Value(savedTitle),
          description: Value(
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          ),
          category: Value(_category),
          dueDate: Value(dueDate),
          dueTime: Value(_timeStr()),
          isCompleted: Value(widget.existingTask!.isCompleted),
          completedAt: Value(widget.existingTask!.completedAt),
          createdAt: Value(widget.existingTask!.createdAt),
          isPlannerEntry: Value(widget.existingTask!.isPlannerEntry),
        ),
        );
        savedTaskId = widget.existingTask!.id;
      } else {
        savedTaskId = await dao.insertTask(
        TasksCompanion(
          title: Value(savedTitle),
          description: Value(
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          ),
          category: Value(_category),
          dueDate: Value(dueDate),
          dueTime: Value(_timeStr()),
          isCompleted: const Value(false),
          isPlannerEntry: Value(widget.plannerEntry),
          createdAt: Value(DateTime.now()),
        ),
        );
      }

    // Planner reminders are real reminders as well as task metadata, so they
    // appear in the Reminders tab and can be completed there.
    if (widget.plannerEntry && savedTaskId != null) {
      final taskTime = _dueTime!;
      final taskDueAt = DateTime(
        dueDate.year,
        dueDate.month,
        dueDate.day,
        taskTime.hour,
        taskTime.minute,
      );
      final reminderDueAt = taskDueAt.add(
        Duration(minutes: _reminderMinutes ?? 0),
      );
      final reminderDao = ref.read(reminderDaoProvider);
      if (_isEditing) {
        reminderToSchedule = await reminderDao.updateByTaskId(
          savedTaskId!, title: savedTitle, dueAt: reminderDueAt,
        );
      } else {
        final reminderId = await reminderDao.insertReminder(
          RemindersCompanion.insert(taskId: Value(savedTaskId!), title: savedTitle, dueAt: reminderDueAt),
        );
        reminderToSchedule = await reminderDao.getById(reminderId);
      }
    }
    });
    if (reminderToSchedule != null) {
      await NotificationService.instance.scheduleReminder(reminderToSchedule!);
    }

    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return Container(
      width: math.min(media.size.width - 44, 500),
      height: widget.plannerEntry ? 410 : null,
      margin: const EdgeInsets.only(top: 12, bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 18,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
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
              const SizedBox(height: 8),
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
                                ? (widget.plannerEntry
                                      ? 'Edit Event'
                                      : 'Edit To-Do')
                                : (widget.plannerEntry
                                      ? 'Add Event'
                                      : 'Add To-Do'),
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          if (widget.plannerEntry) ...[
                            const SizedBox(height: 2),
                            const Text(
                              'Plan today. A better you tomorrow.',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 9,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _titleCtrl,
                            autofocus: !_isEditing,
                            onChanged: (_) => setState(() {}),
                            textCapitalization: TextCapitalization.sentences,
                            maxLength: 60,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(60),
                            ],
                            decoration: InputDecoration(
                              hintText: 'New task...',
                              counterText: '',
                              suffixText: widget.plannerEntry
                                  ? '${_titleCtrl.text.length}/60'
                                  : null,
                              suffixStyle: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 9,
                                color: AppColors.textSecondary,
                              ),
                              errorStyle: TextStyle(fontSize: 0, height: 0),
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
              const SizedBox(height: 6),
              // Form
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!widget.plannerEntry) ...[
                      _FieldLabel('Description (optional)'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _descCtrl,
                        maxLines: 2,
                        maxLength: 120,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(120),
                        ],
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
                      _FieldLabel('Date · Time · Reminder'),
                      const SizedBox(height: 6),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: _PickerBtn(
                            icon: Icons.calendar_today_outlined,
                            label: DateFormat(
                              widget.plannerEntry ? 'd MMM' : 'd MMM yyyy',
                            ).format(_dueDate),
                            onTap: _pickDate,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _PickerBtn(
                            icon: Icons.schedule_outlined,
                            label: _dueTime != null
                                ? _dueTime!.format(context)
                                : 'No time',
                            onTap: _pickTime,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ReminderPicker(
                            selected: _reminderMinutes,
                            options: _reminderOptions,
                            onSelected: (value) =>
                                setState(() => _reminderMinutes = value),
                          ),
                        ),
                      ],
                    ),
                    if (widget.plannerEntry)
                      SizedBox(
                        height: 18,
                        child: _timeError == null
                            ? null
                            : Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Text(
                                  _timeError!,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 9,
                                    color: AppColors.danger,
                                  ),
                                ),
                              ),
                      ),
                    const SizedBox(height: 6),
                    _FieldLabel('Category'),
                    const SizedBox(height: 6),
                    _TaskCategoryPicker(
                      categories: _categories,
                      selected: _category,
                      onSelected: (category) =>
                          setState(() => _category = category),
                    ),
                    const SizedBox(height: 10),
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
                                              ? 'Create Event'
                                              : 'Create To-Do'),
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 19,
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _DatePickerSheet extends StatefulWidget {
  const _DatePickerSheet({required this.initialDate});
  final DateTime initialDate;

  @override
  State<_DatePickerSheet> createState() => _DatePickerSheetState();
}

class _DatePickerSheetState extends State<_DatePickerSheet> {
  late DateTime _selectedDate = widget.initialDate;

  @override
  Widget build(BuildContext context) {
    return _PickerSheetFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PickerSheetHeader(
            title: 'Select date',
            onClose: () => Navigator.of(context).pop(),
          ),
          Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.accent,
                onPrimary: AppColors.surface,
              ),
            ),
            child: CalendarDatePicker(
              initialDate: _selectedDate,
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
              onDateChanged: (date) => setState(() => _selectedDate = date),
            ),
          ),
          _PickerConfirmButton(
            label: 'Select date',
            onPressed: () => Navigator.of(context).pop(_selectedDate),
          ),
        ],
      ),
    );
  }
}

class _TimePickerSheet extends StatefulWidget {
  const _TimePickerSheet({required this.initialTime});
  final TimeOfDay? initialTime;

  @override
  State<_TimePickerSheet> createState() => _TimePickerSheetState();
}

class _TimePickerSheetState extends State<_TimePickerSheet> {
  late TimeOfDay _selectedTime = widget.initialTime ?? TimeOfDay.now();

  @override
  Widget build(BuildContext context) {
    final initial = DateTime(
      2020,
      1,
      1,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    return _PickerSheetFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PickerSheetHeader(
            title: 'Select time',
            onClose: () => Navigator.of(context).pop(),
          ),
          SizedBox(
            height: 150,
            child: CupertinoTheme(
              data: const CupertinoThemeData(
                brightness: Brightness.light,
                primaryColor: AppColors.accent,
              ),
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: initial,
                use24hFormat: false,
                onDateTimeChanged: (value) => setState(
                  () => _selectedTime = TimeOfDay.fromDateTime(value),
                ),
              ),
            ),
          ),
          _PickerConfirmButton(
            label: 'Select time',
            onPressed: () => Navigator.of(context).pop(_selectedTime),
          ),
        ],
      ),
    );
  }
}

class _PickerSheetFrame extends StatelessWidget {
  const _PickerSheetFrame({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 110, bottom: 12),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
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
      child: SafeArea(top: false, child: child),
    );
  }
}

class _PickerSheetHeader extends StatelessWidget {
  const _PickerSheetHeader({required this.title, required this.onClose});
  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 42,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.divider,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ],
    );
  }
}

class _PickerConfirmButton extends StatelessWidget {
  const _PickerConfirmButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 21, color: AppColors.surface),
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.surface,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
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
}

class _ReminderPicker extends StatelessWidget {
  const _ReminderPicker({
    required this.selected,
    required this.options,
    required this.onSelected,
  });

  final int? selected;
  final List<({String label, int? value})> options;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    final selectedLabel = options
        .firstWhere(
          (option) => option.value == selected,
          orElse: () => options.first,
        )
        .label;
    return PopupMenuButton<int>(
      tooltip: 'Reminder',
      onSelected: (value) => onSelected(value < 0 ? null : value),
      itemBuilder: (_) => options
          .map(
            (option) => PopupMenuItem<int>(
              value: option.value ?? -1,
              child: Text(option.label),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.notifications_none_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  selectedLabel,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.surface,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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
                child: Icon(
                  _taskCategoryIcon(category),
                  size: 28,
                  color: color,
                ),
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
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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
