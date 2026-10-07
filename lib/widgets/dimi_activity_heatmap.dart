import 'dart:async';
import 'dart:math' as math;

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
  // Used only to decide whether the naturally-sized popover fits above the
  // selected cell. The card itself has no fixed height.
  static const _estimatedTooltipHeight = 100.0;
  static const _screenPadding = 16.0;
  static const _tooltipGap = 8.0;

  final Map<DateTime, LayerLink> _cellLinks = {};
  _HeatmapSelection? _selection;
  _HeatmapPlacement? _placement;
  OverlayEntry? _overlayEntry;
  Timer? _popupTimer;

  LayerLink _linkFor(DateTime date) =>
      _cellLinks.putIfAbsent(date, LayerLink.new);

  void _selectCell(
    BuildContext cellContext,
    DateTime date,
    int completed,
    int total,
  ) {
    final box = cellContext.findRenderObject()! as RenderBox;
    final cellTopLeft = box.localToGlobal(Offset.zero);
    final cellRect = cellTopLeft & box.size;
    final screen = MediaQuery.sizeOf(context);
    final dateStyle = AppTextStyles.caption(context).copyWith(fontSize: 12);
    final mainStyle = AppTextStyles.cardTitle(context)
        .copyWith(fontSize: 12, fontWeight: FontWeight.w600);
    final buttonStyle = AppTextStyles.body(context)
        .copyWith(fontSize: 12, fontWeight: FontWeight.w600);
    final dateWidth = _measureText(
      DateFormat('EEE, MMM d').format(date),
      dateStyle,
    );
    final mainWidth = _measureText(
      '$completed / $total tasks completed',
      mainStyle,
    );
    final buttonWidth = _measureText('View details', buttonStyle);
    final contentWidth = <double>[
      dateWidth + 18,
      mainWidth + 24,
      buttonWidth + 24 + 14 + 6,
    ].reduce(math.max);
    final width = math.min(
      contentWidth + 24,
      screen.width - _screenPadding * 2,
    );
    final centerX = cellRect.center.dx;
    final left = (centerX - width / 2).clamp(
      _screenPadding,
      screen.width - _screenPadding - width,
    );
    final aboveFits =
        cellRect.top - _tooltipGap - _estimatedTooltipHeight >= _screenPadding;
    final vertical = aboveFits
        ? _TooltipVertical.above
        : _TooltipVertical.below;

    _popupTimer?.cancel();
    setState(() {
      _selection = _HeatmapSelection(date, completed, total);
      _placement = _HeatmapPlacement(
        vertical: vertical,
        width: width,
        offsetX: left - (centerX - width / 2),
        arrowX: centerX - left,
        cellHeight: cellRect.height,
      );
    });
    if (_overlayEntry == null) {
      _overlayEntry = OverlayEntry(builder: (_) => _buildOverlay());
      Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
    } else {
      _overlayEntry!.markNeedsBuild();
    }
    _popupTimer = Timer(const Duration(seconds: 2), _dismissPopup);
  }

  double _measureText(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      maxLines: 1,
    )..layout();
    return painter.width;
  }

  void _dismissPopup() {
    _popupTimer?.cancel();
    _popupTimer = null;
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() {
        _selection = null;
        _placement = null;
      });
    }
  }

  @override
  void dispose() {
    _popupTimer?.cancel();
    _overlayEntry?.remove();
    super.dispose();
  }

  Widget _buildOverlay() {
    final selection = _selection;
    final placement = _placement;
    if (selection == null || placement == null) return const SizedBox.shrink();
    return Positioned.fill(
      child: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.loose,
        children: [
          CompositedTransformFollower(
            link: _linkFor(selection.date),
            showWhenUnlinked: false,
            targetAnchor: placement.targetAnchor,
            followerAnchor: placement.followerAnchor,
            offset: placement.offset,
            child: TapRegion(
              onTapOutside: (_) => _dismissPopup(),
              child: _HeatmapTooltip(
                selection: selection,
                placement: placement,
                onViewDetails: widget.onViewDetails == null
                    ? null
                    : () {
                        final callback = widget.onViewDetails!;
                        final date = selection.date;
                        _dismissPopup();
                        callback(date);
                      },
              ),
            ),
          ),
        ],
      ),
    );
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
          height:
              7 * DimiActivityHeatmap._cellSize +
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
                          linkFor: _linkFor,
                          onTap: (cellContext, day) => _selectCell(
                            cellContext,
                            day,
                            completed[day] ?? 0,
                            totals[day] ?? 0,
                          ),
                        ),
                        const SizedBox(width: DimiActivityHeatmap._monthGap),
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
      child: content,
    );
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}

class _HeatmapSelection {
  const _HeatmapSelection(this.date, this.completed, this.total);
  final DateTime date;
  final int completed;
  final int total;
}

enum _TooltipVertical { above, below }

class _HeatmapPlacement {
  const _HeatmapPlacement({
    required this.vertical,
    required this.width,
    required this.offsetX,
    required this.arrowX,
    required this.cellHeight,
  });

  final _TooltipVertical vertical;
  final double width;
  final double offsetX;
  final double arrowX;
  final double cellHeight;

  Alignment get targetAnchor => vertical == _TooltipVertical.below
      ? Alignment.bottomCenter
      : Alignment.topCenter;

  Alignment get followerAnchor => vertical == _TooltipVertical.below
      ? Alignment.topCenter
      : Alignment.bottomCenter;

  Offset get offset => Offset(
    offsetX,
    vertical == _TooltipVertical.above ? cellHeight / 2 : -cellHeight / 2,
  );
}

class _HeatmapTooltip extends StatelessWidget {
  const _HeatmapTooltip({
    required this.selection,
    required this.placement,
    this.onViewDetails,
  });

  final _HeatmapSelection selection;
  final _HeatmapPlacement placement;
  final VoidCallback? onViewDetails;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: .96, end: 1),
    duration: const Duration(milliseconds: 180),
    curve: Curves.easeOutCubic,
    builder: (context, scale, child) => Opacity(
      opacity: (scale - .96) / .04,
      child: Transform.scale(scale: scale, child: child),
    ),
    child: CustomPaint(
      painter: _HeatmapTooltipPainter(
        vertical: placement.vertical,
        arrowX: placement.arrowX,
      ),
      child: Container(
        width: placement.width,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.zero,
                  child: Text(
                    DateFormat('EEE, MMM d').format(selection.date),
                    style: AppTextStyles.caption(context).copyWith(
                      fontSize: 12,
                      height: 16 / 12,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${selection.completed} / ${selection.total} tasks completed',
                  maxLines: 1,
                  softWrap: false,
                  style: AppTextStyles.cardTitle(context).copyWith(
                    fontSize: 12,
                    height: 18 / 14,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                  ),
                ),
                if (onViewDetails != null) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onViewDetails,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: AppColors.textPrimary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'View details',
                            style: AppTextStyles.body(context).copyWith(
                              fontSize: 12,
                              height: 1,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _HeatmapTooltipPainter extends CustomPainter {
  const _HeatmapTooltipPainter({required this.vertical, required this.arrowX});
  final _TooltipVertical vertical;
  final double arrowX;

  @override
  void paint(Canvas canvas, Size size) {
    const arrowWidth = 12.0;
    const arrowHeight = 7.0;
    final top = vertical == _TooltipVertical.below ? arrowHeight : 0.0;
    final bottom = vertical == _TooltipVertical.above
        ? size.height - arrowHeight
        : size.height;
    final rect = Rect.fromLTRB(0, top, size.width, bottom);
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16)));
    final clampedArrow = arrowX.clamp(14.0, size.width - 14.0).toDouble();
    if (vertical == _TooltipVertical.below) {
      path.moveTo(clampedArrow - arrowWidth / 2, arrowHeight);
      path.lineTo(clampedArrow, 0);
      path.lineTo(clampedArrow + arrowWidth / 2, arrowHeight);
    } else {
      path.moveTo(clampedArrow - arrowWidth / 2, size.height - arrowHeight);
      path.lineTo(clampedArrow, size.height);
      path.lineTo(clampedArrow + arrowWidth / 2, size.height - arrowHeight);
    }
    canvas.drawShadow(path, const Color(0x40000000), 8, false);
    canvas.drawPath(path, Paint()..color = AppColors.surface);
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.divider
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _HeatmapTooltipPainter old) =>
      old.vertical != vertical || old.arrowX != arrowX;
}

class _ActivityMonthGroup extends StatelessWidget {
  const _ActivityMonthGroup({
    required this.month,
    required this.today,
    required this.totals,
    required this.completed,
    required this.linkFor,
    required this.onTap,
  });

  final DateTime month;
  final DateTime today;
  final Map<DateTime, int> totals;
  final Map<DateTime, int> completed;
  final LayerLink Function(DateTime) linkFor;
  final void Function(BuildContext, DateTime) onTap;

  @override
  Widget build(BuildContext context) {
    final monthEnd = DateTime(month.year, month.month + 1, 0);
    final groupStart = month.subtract(Duration(days: month.weekday % 7));
    final groupEnd = monthEnd.add(Duration(days: 6 - (monthEnd.weekday % 7)));
    final weekCount = (groupEnd.difference(groupStart).inDays ~/ 7) + 1;

    return SizedBox(
      width:
          weekCount *
              (DimiActivityHeatmap._cellSize + DimiActivityHeatmap._gap) -
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
                  right: week == weekCount - 1 ? 0 : DimiActivityHeatmap._gap,
                ),
                child: Column(
                  children: List.generate(7, (row) {
                    final day = weekStart.add(Duration(days: row));
                    final inMonth =
                        day.month == month.month && day.year == month.year;
                    if (!inMonth) {
                      return SizedBox(
                        width: DimiActivityHeatmap._cellSize,
                        height:
                            DimiActivityHeatmap._cellSize +
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
                      child: Builder(
                        builder: (cellContext) => CompositedTransformTarget(
                          link: linkFor(day),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
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
