import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../providers/class_providers.dart';
import '../../providers/profile_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';

class ClassesScreen extends ConsumerStatefulWidget {
  const ClassesScreen({super.key});

  @override
  ConsumerState<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends ConsumerState<ClassesScreen> {
  // ISO weekday: 1=Mon … 7=Sun. Default to today (capped at Fri for display).
  late int _selectedDay;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now().weekday; // 1-7
    _selectedDay = today.clamp(1, 7);
  }

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(classesForDayProvider(_selectedDay));
    final profileAsync = ref.watch(profileProvider);
    final semesterLabel = profileAsync.valueOrNull?.semester ?? 'Semester 5';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── App bar ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                20,
                AppSpacing.screenHorizontal,
                0,
              ),
              child: Text(
                'Classes',
                style: Theme.of(context).textTheme.displayMedium,
              ),
            ),
            const SizedBox(height: 12),

            // ── Semester label ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      semesterLabel,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Day-of-week strip ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
              ),
              child: _DayStrip(
                selectedDay: _selectedDay,
                onDaySelected: (d) => setState(() => _selectedDay = d),
              ),
            ),
            const SizedBox(height: 12),

            // ── Class list ────────────────────────────────────────────
            Expanded(
              child: classesAsync.when(
                data: (classes) {
                  if (classes.isEmpty) {
                    return const EmptyState(
                      icon: Icons.school_outlined,
                      title: 'No classes today',
                      subtitle: 'Select a different day to view your schedule.',
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenHorizontal,
                      vertical: 4,
                    ),
                    itemCount: classes.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.cardGap),
                    itemBuilder: (context, i) =>
                        _ClassCard(session: classes[i]),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.accent,
                    strokeWidth: 2,
                  ),
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

// ── Day strip ─────────────────────────────────────────────────────────────────

class _DayStrip extends StatelessWidget {
  const _DayStrip({required this.selectedDay, required this.onDaySelected});

  final int selectedDay;
  final ValueChanged<int> onDaySelected;

  static const _labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final todayIdx = DateTime.now().weekday - 1; // 0-based (0=Mon)
    return Row(
      children: List.generate(7, (i) {
        final dayNum = i + 1; // ISO 1–7
        final isSelected = dayNum == selectedDay;
        final isToday = i == todayIdx;
        return Expanded(
          child: GestureDetector(
            onTap: () => onDaySelected(dayNum),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accent : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? AppColors.accent
                      : isToday
                      ? AppColors.accent.withAlpha(100)
                      : AppColors.divider,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _labels[i],
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.surface
                          : AppColors.textSecondary,
                    ),
                  ),
                  if (isToday && !isSelected) ...[
                    const SizedBox(height: 3),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ── Class card ────────────────────────────────────────────────────────────────

class _ClassCard extends StatelessWidget {
  const _ClassCard({required this.session});
  final ClassSession session;

  @override
  Widget build(BuildContext context) {
    // Determine status based on current time vs class time
    final status = _computeStatus(session);
    final tagColor = _parseColor(session.colorTag);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          // Left color bar
          Container(
            width: 4,
            height: 72,
            decoration: BoxDecoration(
              color: tagColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSpacing.cardRadius),
                bottomLeft: Radius.circular(AppSpacing.cardRadius),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Time column
          SizedBox(
            width: 72,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  session.startTime,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  session.endTime,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Vertical divider
          Container(width: 1, height: 40, color: AppColors.divider),
          const SizedBox(width: 12),
          // Course info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.courseName,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    session.room ?? 'No room',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Status badge
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _StatusBadge(status: status),
          ),
        ],
      ),
    );
  }

  _ClassStatus _computeStatus(ClassSession session) {
    final now = DateTime.now();
    final startParts = session.startTime.split(':');
    final endParts = session.endTime.split(':');
    if (startParts.length < 2 || endParts.length < 2) {
      return _ClassStatus.upcoming;
    }

    final start = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(startParts[0]),
      int.parse(startParts[1]),
    );
    final end = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(endParts[0]),
      int.parse(endParts[1]),
    );

    if (now.isBefore(start)) return _ClassStatus.upcoming;
    if (now.isAfter(end)) return _ClassStatus.completed;
    return _ClassStatus.ongoing;
  }

  Color _parseColor(String hex) {
    try {
      final cleaned = hex.replaceFirst('#', '');
      return Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {
      return AppColors.accent;
    }
  }
}

enum _ClassStatus { upcoming, ongoing, completed }

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final _ClassStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (status) {
      _ClassStatus.ongoing => (
        'Ongoing',
        AppColors.success,
        AppColors.success.withAlpha(26),
      ),
      _ClassStatus.completed => (
        'Done',
        AppColors.textSecondary,
        AppColors.divider,
      ),
      _ClassStatus.upcoming => (
        'Upcoming',
        AppColors.info,
        AppColors.info.withAlpha(26),
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ── Small icon button — kept for future use ───────────────────────────────────
// ignore: unused_element
class _SmallIconBtn extends StatelessWidget {
  const _SmallIconBtn({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.divider),
      ),
      child: Icon(icon, size: 15, color: AppColors.textPrimary),
    );
  }
}
