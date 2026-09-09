import 'package:drift/drift.dart' show Value;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../providers/study_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';

// ── Study session timer state ─────────────────────────────────────────────────

class _TimerState {
  const _TimerState({
    this.isRunning = false,
    this.startedAt,
    this.selectedCourse = '',
  });

  final bool isRunning;
  final DateTime? startedAt;
  final String selectedCourse;

  _TimerState copyWith({
    bool? isRunning,
    DateTime? startedAt,
    String? selectedCourse,
  }) {
    return _TimerState(
      isRunning: isRunning ?? this.isRunning,
      startedAt: startedAt ?? this.startedAt,
      selectedCourse: selectedCourse ?? this.selectedCourse,
    );
  }

  Duration get elapsed => isRunning && startedAt != null
      ? DateTime.now().difference(startedAt!)
      : Duration.zero;
}

class _TimerNotifier extends StateNotifier<_TimerState> {
  _TimerNotifier() : super(const _TimerState());

  void start(String course) {
    state = _TimerState(
      isRunning: true,
      startedAt: DateTime.now(),
      selectedCourse: course,
    );
  }

  /// Stops the timer and returns the elapsed minutes. Returns null if not running.
  int? stop() {
    if (!state.isRunning || state.startedAt == null) return null;
    final mins = DateTime.now().difference(state.startedAt!).inMinutes;
    state = const _TimerState();
    return mins < 1 ? 1 : mins; // minimum 1 minute
  }

  void cancel() {
    state = const _TimerState();
  }
}

final _timerProvider = StateNotifierProvider<_TimerNotifier, _TimerState>((
  ref,
) {
  return _TimerNotifier();
});

// ── Screen ────────────────────────────────────────────────────────────────────

class StudyScreen extends ConsumerStatefulWidget {
  const StudyScreen({super.key});

  @override
  ConsumerState<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends ConsumerState<StudyScreen> {
  // Ticker for updating elapsed display
  bool _tickerActive = false;

  @override
  void dispose() {
    _tickerActive = false;
    super.dispose();
  }

  void _startTicker() {
    _tickerActive = true;
    _tick();
  }

  void _tick() {
    if (!_tickerActive || !mounted) return;
    Future.delayed(const Duration(seconds: 1), () {
      if (_tickerActive && mounted) {
        setState(() {});
        _tick();
      }
    });
  }

  Future<void> _startSession(BuildContext context) async {
    final courses = ref.read(allCoursesProvider).valueOrNull ?? [];
    if (courses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No courses found. Add a course first.')),
      );
      return;
    }

    // Pick course
    final selected = await _pickCourse(context, courses);
    if (selected == null || !mounted) return;

    ref.read(_timerProvider.notifier).start(selected);
    _startTicker();
  }

  Future<void> _stopSession() async {
    final timerState = ref.read(_timerProvider);
    final minutes = ref.read(_timerProvider.notifier).stop();
    _tickerActive = false;

    if (minutes == null || minutes < 1) return;

    await ref
        .read(studyDaoProvider)
        .logSession(
          StudySessionsCompanion(
            courseName: Value(timerState.selectedCourse),
            startedAt: Value(timerState.startedAt ?? DateTime.now()),
            durationMinutes: Value(minutes),
          ),
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Session logged: $minutes min for ${timerState.selectedCourse}',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<String?> _pickCourse(
    BuildContext context,
    List<Course> courses,
  ) async {
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Select Course',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: courses.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, color: AppColors.divider),
            itemBuilder: (ctx, i) => ListTile(
              title: Text(
                courses[i].name,
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
              ),
              onTap: () => Navigator.pop(ctx, courses[i].name),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final weeklySessionsAsync = ref.watch(thisWeeksStudySessionsProvider);
    final coursesAsync = ref.watch(allCoursesProvider);
    final timerState = ref.watch(_timerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // ── App bar ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                20,
                AppSpacing.screenHorizontal,
                0,
              ),
              child: Row(
                children: [
                  Text(
                    'Study',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  _SmallIconBtn(icon: Icons.search_rounded),
                  const SizedBox(width: 6),
                  _SmallIconBtn(icon: Icons.more_vert_rounded),
                ],
              ),
            ),

            // ── Weekly summary card ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
              ),
              child: weeklySessionsAsync.when(
                data: (sessions) => _WeeklySummaryCard(
                  sessions: sessions,
                  timerState: timerState,
                ),
                loading: () => const _SkeletonCard(height: 180),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
            const SizedBox(height: 12),

            // ── Timer / Start button ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
              ),
              child: timerState.isRunning
                  ? _ActiveTimerCard(
                      timerState: timerState,
                      onStop: () => _stopSession(),
                      onCancel: () {
                        ref.read(_timerProvider.notifier).cancel();
                        _tickerActive = false;
                      },
                    )
                  : SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () => _startSession(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.play_arrow_rounded, size: 20),
                        label: const Text(
                          'Start Study Session',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 16),

            // ── Study Courses ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Study Courses',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _showAddCourseDialog(context),
                    child: const Text(
                      'Add Course',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            coursesAsync.when(
              data: (courses) {
                if (courses.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: EmptyState(
                      icon: Icons.menu_book_outlined,
                      title: 'No courses yet',
                      subtitle: 'Tap "Add Course" above to get started.',
                    ),
                  );
                }
                return Column(
                  children: courses
                      .map(
                        (c) => Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.screenHorizontal,
                            0,
                            AppSpacing.screenHorizontal,
                            8,
                          ),
                          child: _CourseProgressCard(course: c),
                        ),
                      )
                      .toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                child: _SkeletonCard(height: 80),
              ),
              error: (e, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddCourseDialog(BuildContext context) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Add Course',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Course name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.surface,
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (ok == true && ctrl.text.trim().isNotEmpty) {
      await ref
          .read(studyDaoProvider)
          .insertCourse(CoursesCompanion(name: Value(ctrl.text.trim())));
    }
    ctrl.dispose();
  }
}

// ── Weekly summary + bar chart card ──────────────────────────────────────────

class _WeeklySummaryCard extends StatelessWidget {
  const _WeeklySummaryCard({required this.sessions, required this.timerState});

  final List<StudySession> sessions;
  final _TimerState timerState;

  @override
  Widget build(BuildContext context) {
    final totalMins = sessions.fold(0, (s, e) => s + e.durationMinutes);
    final totalHours = (totalMins / 60).toStringAsFixed(1);

    final dayMins = List.filled(7, 0);
    for (final s in sessions) {
      dayMins[s.startedAt.weekday - 1] += s.durationMinutes;
    }
    final maxMins = dayMins.reduce((a, b) => a > b ? a : b).toDouble();
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
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Study Time',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '$totalHours h',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Text(
                    'This Week',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (timerState.isRunning)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withAlpha(26),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _formatElapsed(timerState.elapsed),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          sessions.isEmpty
              ? SizedBox(
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
                          'No sessions this week',
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
              : SizedBox(
                  height: 80,
                  child: _StudyBarChart(
                    dayMins: dayMins,
                    maxMins: maxMins,
                    todayIdx: todayIdx,
                  ),
                ),
        ],
      ),
    );
  }

  String _formatElapsed(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }
}

// ── Active timer card ─────────────────────────────────────────────────────────

class _ActiveTimerCard extends StatelessWidget {
  const _ActiveTimerCard({
    required this.timerState,
    required this.onStop,
    required this.onCancel,
  });

  final _TimerState timerState;
  final VoidCallback onStop;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final elapsed = timerState.elapsed;
    final h = elapsed.inHours;
    final m = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    final label = h > 0 ? '$h:$m:$s' : '$m:$s';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.success.withAlpha(20),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.success.withAlpha(60)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timerState.selectedCourse,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              GestureDetector(
                onTap: onStop,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Stop',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.surface,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: onCancel,
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Course progress card ──────────────────────────────────────────────────────

class _CourseProgressCard extends StatelessWidget {
  const _CourseProgressCard({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    // Target: 120 min (2h) per course per session block — adjustable
    const targetMins = 120;
    final ratio = (course.totalLoggedMinutes / targetMins).clamp(0.0, 1.0);
    final hours = (course.totalLoggedMinutes / 60).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          // Course initial circle
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                course.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        course.name,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${hours}h',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Progress bar
                Stack(
                  children: [
                    Container(
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: ratio,
                      child: Container(
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared bar chart for study ────────────────────────────────────────────────

class _StudyBarChart extends StatelessWidget {
  const _StudyBarChart({
    required this.dayMins,
    required this.maxMins,
    required this.todayIdx,
  });

  final List<int> dayMins;
  final double maxMins;
  final int todayIdx;

  @override
  Widget build(BuildContext context) {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxMins <= 0 ? 60 : maxMins * 1.3,
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 18,
              getTitlesWidget: (v, _) {
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
          final isToday = i == todayIdx;
          final mins = dayMins[i].toDouble();
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: mins <= 0 ? 1.5 : mins,
                color: isToday ? AppColors.accent : AppColors.accentSoft,
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
              final mins = dayMins[group.x];
              final h = mins ~/ 60;
              final m = mins % 60;
              return BarTooltipItem(
                m == 0 ? '${h}h' : '${h}h ${m}m',
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
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

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
