import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/database.dart';
import '../../data/daos/note_dao.dart';
import '../../data/daos/task_dao.dart';
import '../../providers/note_providers.dart';
import '../../providers/task_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/todo_text.dart';
import '../../widgets/dimi_add_action_button.dart';
import '../../widgets/section_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/dimi_success_dialog.dart';
import '../../widgets/dimi_delete_dialog.dart';
import '../../widgets_modals/fixed_dialog.dart';

class TodosScreen extends ConsumerStatefulWidget {
  const TodosScreen({super.key});

  @override
  ConsumerState<TodosScreen> createState() => _TodosScreenState();
}

class _TodosScreenState extends ConsumerState<TodosScreen> {
  int _tab = 0;
  bool _showAction = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: NotificationListener<UserScrollNotification>(
          onNotification: (notification) {
            final show = notification.direction == ScrollDirection.reverse
                ? false
                : notification.direction == ScrollDirection.forward
                ? true
                : _showAction;
            if (show != _showAction) setState(() => _showAction = show);
            return false;
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "To-Do's",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _TabSwitch(
                  selected: _tab,
                  onSelected: (value) => setState(() => _tab = value),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: _tab == 0
                    ? const _TodosTaskList()
                    : const _TodosNotesList(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: AnimatedSlide(
        offset: _showAction ? Offset.zero : const Offset(0, 1.5),
        duration: const Duration(milliseconds: 180),
        child: AnimatedOpacity(
          opacity: _showAction ? 1 : 0,
          duration: const Duration(milliseconds: 140),
          child: DimiAddActionButton(
            label: _tab == 0 ? 'Add To-Do' : 'Add Note',
            onPressed: () => _tab == 0
                ? _showMinimalTodoDialog(context, ref)
                : _showNoteAddDialog(context, ref),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _TabSwitch extends StatelessWidget {
  const _TabSwitch({required this.selected, required this.onSelected});
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Container(
    height: 50,
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: AppColors.accentSoft,
      borderRadius: BorderRadius.circular(28),
    ),
    child: Row(
      children: [
        _Tab(
          label: 'Tasks',
          selected: selected == 0,
          onTap: () => onSelected(0),
        ),
        _Tab(
          label: 'Notes',
          selected: selected == 1,
          onTap: () => onSelected(1),
        ),
      ],
    ),
  );
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.textPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.surface : AppColors.textSecondary,
          ),
        ),
      ),
    ),
  );
}

class _TodosTaskList extends ConsumerWidget {
  const _TodosTaskList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(allTodosProvider);
    return todos.when(
      data: (items) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Long-term tasks',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '${items.length} tasks',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            const EmptyState(
              icon: Icons.checklist_outlined,
              asset: 'assets/illustrations/Todo.png',
              title: 'No To-Do\'s yet',
              subtitle: 'Add a task to keep it for later.',
            )
          else
            ...items.map((task) => _TodoRow(task: task)),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          Center(child: Text('Could not load To-Do\'s: $error')),
    );
  }
}

class _TodoRow extends ConsumerWidget {
  const _TodoRow({required this.task});
  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: SectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Checkbox(
            value: task.isCompleted,
            activeColor: AppColors.accent,
            onChanged: (value) => ref
                .read(taskDaoProvider)
                .toggleCompleted(task.id, value ?? false),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: task.isCompleted
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    decorationThickness: 1.6,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Created ${DateFormat('d MMM yyyy').format(task.createdAt)}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Delete To-Do',
            icon: const Icon(Icons.delete_outline_rounded),
            color: AppColors.textSecondary,
            onPressed: () => ref.read(taskDaoProvider).deleteTask(task.id),
          ),
        ],
      ),
    ),
  );
}

class _TodosNotesList extends ConsumerWidget {
  const _TodosNotesList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(allNotesProvider);
    return notes.when(
      data: (items) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Saved notes',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '${items.length} notes',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            const EmptyState(
              icon: Icons.note_alt_outlined,
              asset: 'assets/illustrations/Todo.png',
              title: 'No notes yet',
              subtitle: 'Add a note for future reference.',
            )
          else
            ...items.map((note) => _NoteCard(note: note)),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Could not load notes: $error')),
    );
  }
}

class _NoteCard extends ConsumerWidget {
  const _NoteCard({required this.note});
  final Note note;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: GestureDetector(
      onTap: () => _showNoteViewer(context, note, ref),
      child: SectionCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.note_alt_outlined,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    note.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${note.updatedAt.day}/${note.updatedAt.month}/${note.updatedAt.year}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'edit')
                  await _showNoteEditor(
                    context,
                    note: note,
                    dao: ref.read(noteDaoProvider),
                  );
                if (value == 'delete' &&
                    await showDimiDeleteConfirmation(
                      context,
                      itemLabel: 'note',
                    )) {
                  await ref.read(noteDaoProvider).deleteNote(note.id);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _showNoteAddDialog(BuildContext context, WidgetRef ref) async {
  if (await ref.read(noteDaoProvider).countNotes() >= 15) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have reached the 15-note limit.')),
      );
    }
    return;
  }
  await _showNoteEditor(context, dao: ref.read(noteDaoProvider));
}

Future<void> _showMinimalTodoDialog(BuildContext context, WidgetRef ref) async {
  final saved = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Add To-Do',
    barrierColor: const Color(0x99000000),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, _, _) => DimiFixedDialog(
      height: 320,
      maxWidth: 420,
      child: _TodoAddDialog(dao: ref.read(taskDaoProvider)),
    ),
    transitionBuilder: (_, animation, _, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: SlideTransition(
        position:
            Tween<Offset>(
              begin: const Offset(0, -0.025),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
        child: child,
      ),
    ),
  );
  if (saved == true && context.mounted) {
    await showDimiSuccessDialog(context, title: 'To-Do Added!');
  }
}

class _TodoAddDialog extends StatefulWidget {
  const _TodoAddDialog({required this.dao});
  final TaskDao dao;

  @override
  State<_TodoAddDialog> createState() => _TodoAddDialogState();
}

class _TodoAddDialogState extends State<_TodoAddDialog> {
  static const _maxTodoCharacters = 60;
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final title = formatTodoTitle(_controller.text);
    if (title.isEmpty) return;
    setState(() => _saving = true);
    await widget.dao.insertTask(
      TasksCompanion(
        title: Value(title),
        description: const Value(null),
        category: const Value('Personal'),
        dueDate: Value(DateTime.now()),
        dueTime: const Value(null),
        isCompleted: const Value(false),
        isPlannerEntry: const Value(false),
        createdAt: Value(DateTime.now()),
      ),
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) => Container(
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 108,
                  height: 94,
                  child: Image.asset(
                    'assets/illustrations/Todo.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add To-Do',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Capture it now, get it done later.',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
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
            const SizedBox(height: 10),
            TextField(
              controller: _controller,
              autofocus: true,
              maxLength: _maxTodoCharacters,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Type a To-Do',
                counterText: '',
                suffixText: '${_controller.text.length}/60',
                suffixStyle: TextStyle(fontFamily: 'Poppins', fontSize: 10),
              ),
            ),
            const SizedBox(height: 18),
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
                          color: AppColors.surface,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Save To-Do',
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
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}

Future<void> _showNoteViewer(
  BuildContext context,
  Note note,
  WidgetRef ref,
) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      contentPadding: EdgeInsets.zero,
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(26),
              ),
              child: SizedBox(
                height: 120,
                width: double.infinity,
                child: Image.asset(
                  'assets/Greeting/GreetingsBG.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    note.content,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Updated ${DateFormat('d MMM yyyy').format(note.updatedAt)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(dialogContext);
                          await _showNoteEditor(
                            context,
                            note: note,
                            dao: ref.read(noteDaoProvider),
                          );
                        },
                        child: const Text('Edit Note'),
                      ),
                      FilledButton.tonal(
                        onPressed: () async {
                          final confirmed = await showDimiDeleteConfirmation(
                            dialogContext,
                            itemLabel: 'note',
                          );
                          if (!confirmed) return;
                          await ref.read(noteDaoProvider).deleteNote(note.id);
                          if (dialogContext.mounted)
                            Navigator.pop(dialogContext);
                        },
                        child: const Text('Delete'),
                      ),
                    ],
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

Future<void> _showNoteEditor(
  BuildContext context, {
  Note? note,
  required NoteDao dao,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (_) => _NoteEditorSheet(note: note, dao: dao),
  );
  if (saved == true && context.mounted) {
    await showDimiSuccessDialog(
      context,
      title: note == null ? 'Note Added!' : 'Note Updated!',
    );
  }
}

class _NoteEditorSheet extends StatefulWidget {
  const _NoteEditorSheet({required this.note, required this.dao});
  final Note? note;
  final NoteDao dao;

  @override
  State<_NoteEditorSheet> createState() => _NoteEditorSheetState();
}

class _NoteEditorSheetState extends State<_NoteEditorSheet> {
  late final TextEditingController _title = TextEditingController(
    text: widget.note?.title ?? '',
  );
  late final TextEditingController _content = TextEditingController(
    text: widget.note?.content ?? '',
  );
  bool _saving = false;
  bool _saved = false;

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || _content.text.trim().isEmpty) return;
    if (countWords(_content.text) > 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notes are limited to 50 words.')),
      );
      return;
    }
    setState(() => _saving = true);
    final now = DateTime.now();
    if (widget.note == null) {
      if (await widget.dao.countNotes() >= 15) {
        if (mounted) {
          setState(() => _saving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You can save up to 15 notes.')),
          );
        }
        return;
      }
      await widget.dao.insertNote(
        NotesCompanion.insert(
          title: _title.text.trim().isEmpty ? 'Note' : _title.text.trim(),
          content: _content.text.trim(),
          category: 'To-Do',
          createdAt: now,
          updatedAt: now,
        ),
      );
    } else {
      await widget.dao.updateNote(
        NotesCompanion(
          id: Value(widget.note!.id),
          title: Value(
            _title.text.trim().isEmpty ? 'Note' : _title.text.trim(),
          ),
          content: Value(_content.text.trim()),
          category: Value(widget.note!.category),
          createdAt: Value(widget.note!.createdAt),
          updatedAt: Value(now),
        ),
      );
    }
    if (!mounted) return;
    setState(() => _saved = true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (mounted && (ModalRoute.of(context)?.isCurrent ?? false))
      Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 18, 20, bottom + 20),
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
            Text(
              widget.note == null ? 'Add Note' : 'Edit Note',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _title,
              enabled: !_saving,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _content,
              builder: (context, value, _) {
                final words = countWords(value.text);
                return TextField(
                  controller: _content,
                  enabled: !_saving,
                  minLines: 3,
                  maxLines: 6,
                  decoration: InputDecoration(
                    labelText: 'Note',
                    helperText: '$words/50 words',
                    errorText: words > 50 ? 'Limit is 50 words' : null,
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _saved
                      ? const Icon(
                          Icons.check_rounded,
                          key: ValueKey('note-saved'),
                        )
                      : const Icon(
                          Icons.save_outlined,
                          key: ValueKey('note-save'),
                        ),
                ),
                label: Text(
                  _saved
                      ? 'Saved'
                      : widget.note == null
                      ? 'Add Note'
                      : 'Save Note',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
