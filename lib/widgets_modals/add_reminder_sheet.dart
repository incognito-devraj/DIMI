import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/database.dart';
import '../providers/reminder_providers.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/dimi_success_dialog.dart';
import 'fixed_dialog.dart';

/// Opens the Add Reminder modal bottom sheet.
Future<void> showAddReminderSheet(BuildContext context) async {
  final saved = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Add Reminder',
    barrierColor: const Color(0x99000000),
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (_, _, _) =>
        _FixedReminderDialog(child: const _AddReminderSheet()),
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
    await showDimiSuccessDialog(context, title: 'Reminder Added!');
  }
}

/// Edits an existing normal reminder without changing its identity.
Future<void> showEditReminderSheet(
  BuildContext context,
  Reminder reminder,
) async {
  final saved = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Edit Reminder',
    barrierColor: const Color(0x99000000),
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (_, _, _) =>
        _FixedReminderDialog(child: _AddReminderSheet(existing: reminder)),
    transitionBuilder: (_, animation, __, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curvedAnimation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        ),
      );
    },
  );
  if (saved == true && context.mounted) {
    await showDimiSuccessDialog(context, title: 'Reminder Updated!');
  }
}

class _FixedReminderDialog extends StatelessWidget {
  const _FixedReminderDialog({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      DimiFixedDialog(height: 410, child: child);
}

class _AddReminderSheet extends ConsumerStatefulWidget {
  const _AddReminderSheet({this.existing});

  final Reminder? existing;

  @override
  ConsumerState<_AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends ConsumerState<_AddReminderSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();

  DateTime _dueDate = DateTime.now();
  TimeOfDay _dueTime = TimeOfDay.fromDateTime(DateTime.now());
  bool _saving = false;
  String _sound = 'default';

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _titleCtrl.text = existing.title;
      _dueDate = existing.dueAt;
      _dueTime = TimeOfDay.fromDateTime(existing.dueAt);
    }
  }

  static const _soundOptions = {
    'default': 'Default phone notification',
    'ringtone': 'Phone ringtone',
    'alarm': 'Alarm tone',
  };

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
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
      initialTime: _dueTime,
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

  DateTime get _combinedDateTime => DateTime(
    _dueDate.year,
    _dueDate.month,
    _dueDate.day,
    _dueTime.hour,
    _dueTime.minute,
  );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final dao = ref.read(reminderDaoProvider);
      final existing = widget.existing;
      final id = existing == null
          ? await dao.insertReminder(
              RemindersCompanion(
                title: Value(_titleCtrl.text.trim()),
                dueAt: Value(_combinedDateTime),
                isEnabled: const Value(true),
              ),
            )
          : existing.id;

      if (existing != null) {
        await dao.updateReminder(
          RemindersCompanion(
            id: Value(existing.id),
            title: Value(_titleCtrl.text.trim()),
            dueAt: Value(_combinedDateTime),
            isEnabled: Value(existing.isEnabled),
          ),
        );
      }

      await NotificationService.instance.setReminderSound(id, _sound);

      final reminder = await dao.getById(id);
      if (reminder != null) {
        if (reminder.isEnabled) {
          await NotificationService.instance.scheduleReminder(reminder);
        } else {
          await NotificationService.instance.cancelReminder(reminder.notificationId);
        }
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e, st) {
      debugPrint('[AddReminder] save failed: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save reminder: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 108,
                    height: 94,
                    child: Image.asset(
                      'assets/illustrations/Reminder.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Reminder',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Never miss what matters.',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
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
            const SizedBox(height: 8),
            // Form
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _titleCtrl,
                      autofocus: true,
                      onChanged: (_) => setState(() {}),
                      maxLength: 40,
                      inputFormatters: [LengthLimitingTextInputFormatter(40)],
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'e.g. Submit assignment',
                        counterText: '',
                        suffixText: '${_titleCtrl.text.length}/40',
                        suffixStyle: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 9,
                          color: AppColors.textSecondary,
                        ),
                        errorStyle: TextStyle(fontSize: 0, height: 0),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Title is required'
                          : null,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _PickerButton(
                            icon: Icons.calendar_today_outlined,
                            label: DateFormat('d MMM yyyy').format(_dueDate),
                            onTap: _pickDate,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _PickerButton(
                            icon: Icons.schedule_outlined,
                            label: _dueTime.format(context),
                            onTap: _pickTime,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _FieldLabel('Notification sound'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _sound,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.music_note_outlined),
                      ),
                      items: _soundOptions.entries
                          .map(
                            (entry) => DropdownMenuItem<String>(
                              value: entry.key,
                              child: Text(entry.value),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _sound = value);
                      },
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.surface,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Add Reminder',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
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

class _PickerButton extends StatelessWidget {
  const _PickerButton({
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
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 10),
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
