import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/database.dart';
import '../theme/app_theme.dart';

/// A lightweight GitHub-style activity heatmap.
///
/// The first row is Sunday and each following column is one calendar week.
/// Dates are supplied by DIMI's task stream; no activity is generated here.
class DimiActivityHeatmap extends StatelessWidget {
  const DimiActivityHeatmap({
    required this.tasks,
    this.title = 'Completion rhythm',
    this.subtitle = 'Activity over the last year',
    this.showCard = true,
    super.key,
  });

  final List<Task> tasks;
  final String title;
  final String subtitle;
  final bool showCard;

  static const _monthCount = 12;
  static const _cellSize = 12.0;
  static const _gap = 3.0;
  static const _monthGap = 12.0;
  static const _labelWidth = 30.0;

  @override
  Widget build(BuildContext context) {
    final today = _dateOnly(DateTime.now());
    final firstMonth = DateTime(today.year, today.month - (_monthCount - 1), 1);
    final months = List.generate(
      _monthCount,
      (index) => DateTime(firstMonth.year, firstMonth.month + index, 1),
    );
    final counts = <DateTime, int>{};
    for (final task in tasks) {
      final day = _dateOnly(task.dueDate);
      counts[day] = (counts[day] ?? 0) + 1;
    }

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        if (title.isNotEmpty) const SizedBox(height: 10),
        SizedBox(
          height: 7 * _cellSize + 6 * _gap + 16,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                width: _labelWidth,
                child: Column(
                  children: [
                    _DayLabel('Sun'),
                    _DayLabel('Mon'),
                    _DayLabel('Tue'),
                    _DayLabel('Wed'),
                    _DayLabel('Thu'),
                    _DayLabel('Fri'),
                    _DayLabel('Sat', last: true),
                    SizedBox(height: 16),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final month in months) ...[
                        _ActivityMonthGroup(
                          month: month,
                          today: today,
                          counts: counts,
                        ),
                        const SizedBox(width: _monthGap),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text('Less', style: _legendStyle),
            const SizedBox(width: 5),
            ...List.generate(
              5,
              (level) => Padding(
                padding: const EdgeInsets.only(left: 3),
                child: SizedBox(
                  width: 10,
                  height: 10,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: _activityColor(level == 0 ? 0 : level * 2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 5),
            const Text('More', style: _legendStyle),
          ],
        ),
      ],
    );

    if (!showCard) return content;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.divider),
      ),
      child: content,
    );
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static Color _activityColor(int count) {
    if (count == 0) return AppColors.background;
    if (count == 1) return AppColors.accent.withAlpha(75);
    if (count <= 3) return AppColors.accent.withAlpha(125);
    if (count <= 6) return AppColors.accent.withAlpha(180);
    return AppColors.accent;
  }
}

class _ActivityMonthGroup extends StatelessWidget {
  const _ActivityMonthGroup({
    required this.month,
    required this.today,
    required this.counts,
  });

  final DateTime month;
  final DateTime today;
  final Map<DateTime, int> counts;

  @override
  Widget build(BuildContext context) {
    final monthEnd = DateTime(month.year, month.month + 1, 0);
    final groupStart = month.subtract(Duration(days: month.weekday % 7));
    final groupEnd = monthEnd.add(
      Duration(days: 6 - (monthEnd.weekday % 7)),
    );
    final weekCount = (groupEnd.difference(groupStart).inDays ~/ 7) + 1;

    return SizedBox(
      width: weekCount * (DimiActivityHeatmap._cellSize + DimiActivityHeatmap._gap) -
          DimiActivityHeatmap._gap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 16,
            child: OverflowBox(
              alignment: Alignment.centerLeft,
              maxWidth: 34,
              child: Text(
                DateFormat('MMM').format(month),
                maxLines: 1,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 9,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(weekCount, (week) {
              final weekStart = groupStart.add(Duration(days: week * 7));
              return Padding(
                padding: EdgeInsets.only(
                  right: week == weekCount - 1
                      ? 0
                      : DimiActivityHeatmap._gap,
                ),
                child: Column(
                  children: List.generate(7, (row) {
                    final day = weekStart.add(Duration(days: row));
                    final inMonth = day.month == month.month &&
                        day.year == month.year;
                    if (!inMonth) {
                      return SizedBox(
                        width: DimiActivityHeatmap._cellSize,
                        height: DimiActivityHeatmap._cellSize +
                            (row == 6 ? 0 : DimiActivityHeatmap._gap),
                      );
                    }
                    final count = counts[day] ?? 0;
                    final color = day.isAfter(today)
                        ? AppColors.background
                        : DimiActivityHeatmap._activityColor(count);
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: row == 6 ? 0 : DimiActivityHeatmap._gap,
                      ),
                      child: Tooltip(
                        triggerMode: TooltipTriggerMode.tap,
                        message:
                            '${DateFormat('EEEE, MMMM d, yyyy').format(day)} - $count ${count == 1 ? 'activity' : 'activities'}',
                        child: Semantics(
                          label:
                              '${DateFormat('MMMM d, yyyy').format(day)}: $count ${count == 1 ? 'activity' : 'activities'}',
                          button: true,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: const SizedBox(
                              width: DimiActivityHeatmap._cellSize,
                              height: DimiActivityHeatmap._cellSize,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _DayLabel extends StatelessWidget {
  const _DayLabel(this.label, {this.last = false});
  final String label;
  final bool last;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 12 + (last ? 0 : 3),
        child: Text(label, style: _dayLabelStyle),
      );
}

const _dayLabelStyle = TextStyle(
  fontFamily: 'Poppins',
  fontSize: 8,
  color: AppColors.textSecondary,
);

const _legendStyle = TextStyle(
  fontFamily: 'Poppins',
  fontSize: 9,
  color: AppColors.textSecondary,
);
