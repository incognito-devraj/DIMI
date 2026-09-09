import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/database.dart';
import '../../providers/note_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/pill_segmented_control.dart';
import '../../widgets_modals/add_note_sheet.dart';

const _kTabs = ['All', 'Lecture', 'Personal', 'Ideas'];

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Note>> notesAsync = switch (_tabIndex) {
      0 => ref.watch(allNotesProvider),
      1 => ref.watch(notesByCategoryProvider('Lecture')),
      2 => ref.watch(notesByCategoryProvider('Personal')),
      3 => ref.watch(notesByCategoryProvider('Ideas')),
      _ => ref.watch(allNotesProvider),
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                20,
                AppSpacing.screenHorizontal,
                0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notes',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  GestureDetector(
                    onTap: () => showAddNoteSheet(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.buttonRadius,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_rounded,
                            size: 16,
                            color: AppColors.surface,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Add Note',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.surface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // ── Filter tabs ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: PillSegmentedControl(
                  options: _kTabs,
                  selected: _tabIndex,
                  onSelected: (i) => setState(() => _tabIndex = i),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // ── Note list ────────────────────────────────────────────────────
            Expanded(
              child: notesAsync.when(
                data: (notes) {
                  if (notes.isEmpty) {
                    return const EmptyState(
                      icon: Icons.sticky_note_2_outlined,
                      title: 'No notes yet',
                      subtitle: 'Tap "Add Note" to write your first note.',
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenHorizontal,
                      vertical: 4,
                    ),
                    itemCount: notes.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.cardGap),
                    itemBuilder: (context, i) => _NoteCard(note: notes[i]),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Note card ─────────────────────────────────────────────────────────────────

class _NoteCard extends ConsumerWidget {
  const _NoteCard({required this.note});
  final Note note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dao = ref.read(noteDaoProvider);

    return GestureDetector(
      onLongPress: () => _showDeleteDialog(context, dao),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row with category pill
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    note.title,
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _CategoryPill(category: note.category),
              ],
            ),
            const SizedBox(height: 6),
            // Content snippet
            Text(
              note.content,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(fontSize: 12, color: AppColors.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            // Timestamp
            Text(
              _formatDate(note.updatedAt),
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateDay = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(dateDay).inDays;

    if (diff == 0) return 'Today · ${DateFormat('h:mm a').format(dt)}';
    if (diff == 1) return 'Yesterday · ${DateFormat('h:mm a').format(dt)}';
    return DateFormat('d MMM yyyy').format(dt);
  }

  Future<void> _showDeleteDialog(BuildContext context, dynamic dao) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        title: const Text('Delete note?'),
        content: Text('This will permanently remove "${note.title}".'),
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
    if (confirmed == true) await dao.deleteNote(note.id);
  }
}

// ── Category pill ─────────────────────────────────────────────────────────────

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.category});
  final String category;

  Color get _color => switch (category) {
    'Lecture' => AppColors.info,
    'Personal' => AppColors.success,
    'Ideas' => AppColors.accent,
    _ => AppColors.textSecondary,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withAlpha(26),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        category,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: _color,
        ),
      ),
    );
  }
}
