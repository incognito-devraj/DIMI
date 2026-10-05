import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/database.dart';
import '../theme/app_theme.dart';

const heatmapColors = [
  Color(0xFFF5F0E6), // 0 - none / 0%
  Color(0xFFF8E8C5), // 1 - 1–24%
  Color(0xFFF9C85B), // 2 - 25–49%
  Color(0xFFF5A623), // 3 - 50–74%
  Color(0xFFD96A0B), // 4 - 75–99%
  Color(0xFF9C3D0A), // 5 - 100%
];

/// A lightweight GitHub-style activity heatmap.
///
/// The first row is Sunday and each following column is one calendar week.
/// Dates are supplied by DIMI's task stream; no activity is generated here.
class DimiActivityHeatmap extends StatefulWidget {
  const DimiActivityHeatmap({
    required this.tasks,
    this.title = 'Completion rhythm',
    this.subtitle = 'Activity over the last year',
    this.showCard = true,
    this.onViewDetails,
    super.key,
  });

  final List<Task> tasks;
  final String title;
  final String subtitle;
  final bool showCard;
  final ValueChanged<DateTime>? onViewDetails;

  static const _monthCount = 12;
  static const _cellSize = 12.0;
  static const _gap = 3.0;
  static const _monthGap = 12.0;
  static const _labelWidth = 30.0;

  @override
  State<DimiActivityHeatmap> createState() => _DimiActivityHeatmapState();
}

class _DimiActivityHeatmapState extends State<DimiActivityHeatmap> {
  final _heatmapKey = GlobalKey();
  _HeatmapSelection? _selection;
  Offset? _cellOffset;

  static const _popupWidth = 224.0;
  static const _popupHeight = 104.0;
  static const _popupGap = 9.0;

  void _selectCell(BuildContext cellContext, DateTime date, int completed, int total) {
    final cell = cellContext.findRenderObject()! as RenderBox;
    final host = _heatmapKey.currentContext!.findRenderObject()! as RenderBox;
    setState(() {
      _selection = _HeatmapSelection(date, completed, total);
      _cellOffset = host.globalToLocal(cell.localToGlobal(Offset.zero));
    });
  }

  void _dismissPopup() {
    if (mounted && _selection != null) setState(() => _selection = null);
  }

  @override
  Widget build(BuildContext context) {
    final today = _dateOnly(DateTime.now());
    final firstMonth = DateTime(
      today.year,
      today.month - (DimiActivityHeatmap._monthCount - 1),
      1,
    );
    final months = List.generate(
      DimiActivityHeatmap._monthCount,
      (index) => DateTime(firstMonth.year, firstMonth.month + index, 1),
    );
    final totals = <DateTime, int>{};
    final completed = <DateTime, int>{};
    for (final task in widget.tasks) {
      final day = _dateOnly(task.dueDate);
      totals[day] = (totals[day] ?? 0) + 1;
      if (task.isCompleted) completed[day] = (completed[day] ?? 0) + 1;
    }

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title.isNotEmpty)
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                widget.subtitle,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        if (widget.title.isNotEmpty) const SizedBox(height: 10),
        SizedBox(
          height: 7 * DimiActivityHeatmap._cellSize +
              6 * DimiActivityHeatmap._gap +
              16,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                width: DimiActivityHeatmap._labelWidth,
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
                          totals: totals,
                          completed: completed,
                          onTap: (cell, day) => _selectCell(cell, day, completed[day] ?? 0, totals[day] ?? 0),
                        ),
                        const SizedBox(
                          width: DimiActivityHeatmap._monthGap,
                        ),
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
              heatmapColors.length,
              (level) => Padding(
                padding: const EdgeInsets.only(left: 3),
                child: SizedBox(
                  width: 10,
                  height: 10,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: heatmapColors[level],
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

    if (!widget.showCard) return content;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.divider),
      ),
      child: TapRegion(
        onTapOutside: (_) => _dismissPopup(),
        child: Stack(
          key: _heatmapKey,
          clipBehavior: Clip.hardEdge,
          children: [
            content,
            if (_selection != null && _cellOffset != null)
              _buildPopup(context, _cellOffset!, _selection!),
          ],
        ),
      ),
    );
  }

  Widget _buildPopup(BuildContext context, Offset cell, _HeatmapSelection selection) {
    final host = _heatmapKey.currentContext!.findRenderObject()! as RenderBox;
    final bounds = Offset.zero & host.size;
    final cellCenter = Offset(cell.dx + DimiActivityHeatmap._cellSize / 2, cell.dy + DimiActivityHeatmap._cellSize / 2);
    final canLeft = cellCenter.dx - _popupGap - _popupWidth >= bounds.left;
    final canRight = cellCenter.dx + _popupGap + _popupWidth <= bounds.right;
    late final double left;
    late final _PopupSide side;
    if (canLeft) {
      left = cellCenter.dx - _popupGap - _popupWidth;
      side = _PopupSide.right;
    } else if (canRight) {
      left = cellCenter.dx + _popupGap;
      side = _PopupSide.left;
    } else {
      left = (cellCenter.dx - _popupWidth / 2).clamp(bounds.left, bounds.right - _popupWidth).toDouble();
      side = cellCenter.dy > bounds.center.dy ? _PopupSide.bottom : _PopupSide.top;
    }
    final top = (cellCenter.dy - _popupHeight / 2).clamp(bounds.top, bounds.bottom - _popupHeight).toDouble();
    final arrow = side == _PopupSide.left || side == _PopupSide.right
        ? (cellCenter.dy - top).clamp(16.0, _popupHeight - 16.0).toDouble()
        : (cellCenter.dx - left).clamp(18.0, _popupWidth - 18.0).toDouble();
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      left: left, top: top, width: _popupWidth, height: _popupHeight,
      child: _HeatmapPopup(
        date: selection.date, completed: selection.completed, total: selection.total,
        side: side, arrowOffset: arrow,
        onDismiss: _dismissPopup,
        onViewDetails: widget.onViewDetails == null ? null : () {
          final callback = widget.onViewDetails!;
          _dismissPopup();
          callback(selection.date);
        },
      ),
    );
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

}

enum _PopupSide { left, right, top, bottom }

class _HeatmapSelection {
  const _HeatmapSelection(this.date, this.completed, this.total);
  final DateTime date;
  final int completed;
  final int total;
}

class _HeatmapPopup extends StatelessWidget {
  const _HeatmapPopup({required this.date, required this.completed, required this.total, required this.side, required this.arrowOffset, required this.onDismiss, this.onViewDetails});
  final DateTime date;
  final int completed;
  final int total;
  final _PopupSide side;
  final double arrowOffset;
  final VoidCallback onDismiss;
  final VoidCallback? onViewDetails;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: CustomPaint(
        painter: _HeatmapPopupPainter(side, arrowOffset),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 9, 12, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(DateFormat('EEEE, MMMM d, yyyy').format(date), maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, color: AppColors.textPrimary)),
            const SizedBox(height: 5),
            Text('$completed / $total tasks completed', style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const Spacer(),
            Align(alignment: Alignment.centerLeft, child: TextButton(onPressed: onViewDetails, style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 20), tapTargetSize: MaterialTapTargetSize.shrinkWrap), child: const Text('View details', style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: AppColors.accent)))),
          ]),
        ),
      ),
    );
  }
}

class _HeatmapPopupPainter extends CustomPainter {
  const _HeatmapPopupPainter(this.side, this.arrowOffset);
  final _PopupSide side;
  final double arrowOffset;
  @override
  void paint(Canvas canvas, Size size) {
    const arrow = 7.0;
    final rect = side == _PopupSide.left ? Rect.fromLTWH(arrow, 0, size.width - arrow, size.height)
        : side == _PopupSide.right ? Rect.fromLTWH(0, 0, size.width - arrow, size.height)
        : side == _PopupSide.top ? Rect.fromLTWH(0, 0, size.width, size.height - arrow)
        : Rect.fromLTWH(0, arrow, size.width, size.height - arrow);
    final path = Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(12)));
    if (side == _PopupSide.left) {
      path.moveTo(arrow, arrowOffset - 7); path.lineTo(0, arrowOffset); path.lineTo(arrow, arrowOffset + 7);
    } else if (side == _PopupSide.right) {
      path.moveTo(size.width - arrow, arrowOffset - 7); path.lineTo(size.width, arrowOffset); path.lineTo(size.width - arrow, arrowOffset + 7);
    } else if (side == _PopupSide.top) {
      path.moveTo(arrowOffset - 7, size.height - arrow); path.lineTo(arrowOffset, size.height); path.lineTo(arrowOffset + 7, size.height - arrow);
    } else {
      path.moveTo(arrowOffset - 7, arrow); path.lineTo(arrowOffset, 0); path.lineTo(arrowOffset + 7, arrow);
    }
    canvas.drawPath(path, Paint()..color = AppColors.surface);
    canvas.drawPath(path, Paint()..color = AppColors.divider..style = PaintingStyle.stroke..strokeWidth = 1.2);
  }
  @override
  bool shouldRepaint(covariant _HeatmapPopupPainter old) => old.arrowOffset != arrowOffset || old.side != side;
}

class _ActivityMonthGroup extends StatelessWidget {
  const _ActivityMonthGroup({
    required this.month,
    required this.today,
    required this.totals,
    required this.completed,
    required this.onTap,
  });

  final DateTime month;
  final DateTime today;
  final Map<DateTime, int> totals;
  final Map<DateTime, int> completed;
  final void Function(BuildContext, DateTime) onTap;

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
                    final total = totals[day] ?? 0;
                    final done = completed[day] ?? 0;
                    final ratio = total == 0 ? 0.0 : done / total;
                    final color = day.isAfter(today)
                        ? heatmapColors[0]
                        : _completionHeatColor(ratio);
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: row == 6 ? 0 : DimiActivityHeatmap._gap,
                      ),
                      child: Builder(builder: (cellContext) => GestureDetector(
                        onTap: () => onTap(cellContext, day),
                        child: Semantics(
                          label:
                            '${DateFormat('MMMM d, yyyy').format(day)}: $total ${total == 1 ? 'activity' : 'activities'}',
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
                      )),
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

Color _completionHeatColor(double ratio) {
  if (ratio <= 0) return heatmapColors[0];
  if (ratio < .25) return heatmapColors[1];
  if (ratio < .5) return heatmapColors[2];
  if (ratio < .75) return heatmapColors[3];
  if (ratio < 1) return heatmapColors[4];
  return heatmapColors[5];
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
