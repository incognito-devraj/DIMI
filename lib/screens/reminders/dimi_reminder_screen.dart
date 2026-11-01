import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/database.dart';
import '../../providers/database_provider.dart';
import '../../services/notification_service.dart';
import '../../services/sync_service.dart';

enum DimiNotificationKind { reminder, planner, youtube }

// ─────────────────────────────────────────────────────────────────────────────
// Screen widget
// ─────────────────────────────────────────────────────────────────────────────

class DimiReminderScreen extends ConsumerStatefulWidget {
  const DimiReminderScreen({
    super.key,
    required this.reminderId,
    required this.accountId,
    required this.title,
    required this.body,
    required this.scheduledTime,
    required this.notifId,
    this.kind = DimiNotificationKind.reminder,
    this.taskId,
    this.channel = '',
    this.note = '',
    this.startTime = '',
    this.endTime = '',
    this.durationMinutes = 0,
    this.playlistId,
    this.playlistProgress = 0,
    this.videosWatched = 0,
    this.videosTotal = 0,
    this.thumbnailUrl = '',
  });

  final int reminderId;
  final int accountId;
  final int notifId;
  final int? taskId;
  final int? playlistId;
  final String title;
  final String body;
  final String channel;
  final String note;
  final String startTime;
  final String endTime;
  final String thumbnailUrl;
  final DateTime scheduledTime;
  final int durationMinutes;
  final int playlistProgress;
  final int videosWatched;
  final int videosTotal;
  final DimiNotificationKind kind;

  @override
  ConsumerState<DimiReminderScreen> createState() => _DimiReminderScreenState();
}

class _DimiReminderScreenState extends ConsumerState<DimiReminderScreen> {
  bool _busy = false;
  String? _result;

  AppDatabase get _db => ref.read(databaseProvider);

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFFFAF5ED),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  void _restoreAccount() {
    if (widget.accountId > 0) _db.setActiveAccountId(widget.accountId);
  }

  Future<void> _complete() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      // Cancel the notification first so it vanishes immediately
      await NotificationService.instance.cancelReminder(widget.notifId);

      if (widget.kind == DimiNotificationKind.youtube) {
        await NotificationService.instance.completeFromFullScreen({
          'notification_id': widget.notifId,
          'playlist_id': widget.playlistId,
          'reminder_id': widget.reminderId,
          'account_id': widget.accountId,
        });
      } else {
        _restoreAccount();
        if (widget.kind == DimiNotificationKind.planner &&
            widget.taskId != null) {
          await _db.taskDao.completeFromNotification(widget.taskId!);
        } else {
          await _db.reminderDao.toggleEnabled(widget.reminderId, false);
        }
        NotificationService.instance.onLocalActionCommitted?.call();
        unawaited(SyncService(_db).syncNow());
      }
      if (!mounted) return;
      setState(() {
        _result = switch (widget.kind) {
          DimiNotificationKind.planner => 'Session started',
          DimiNotificationKind.youtube => 'Playlist updated',
          DimiNotificationKind.reminder => 'Marked as done',
        };
      });
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (mounted) _closeActivity();
    } catch (_) {
      if (mounted)
        setState(() {
          _busy = false;
        });
    }
  }

  Future<void> _snooze() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      // Cancel current notification immediately
      await NotificationService.instance.cancelReminder(widget.notifId);

      await NotificationService.instance.snoozeFromFullScreen(widget.notifId, {
        'reminder_id': widget.reminderId,
        'task_id': widget.taskId,
        'account_id': widget.accountId,
      });
      if (!mounted) return;
      setState(() => _result = 'Snoozed for 5 minutes');
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (mounted) _closeActivity();
    } catch (_) {
      if (mounted)
        setState(() {
          _busy = false;
        });
    }
  }

  Future<void> _dismiss() async {
    if (_busy) return;
    setState(() => _busy = true);
    // Cancel notification and close — no DB change, just dismiss
    await NotificationService.instance.cancelReminder(widget.notifId);
    if (mounted) _closeActivity();
  }

  void _closeActivity() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isYoutube = widget.kind == DimiNotificationKind.youtube;
    return Scaffold(
      backgroundColor: const Color(0xFFFAF5ED),
      body: Stack(
        children: [
          // ── Full-page scribble background (task 2) ──────────────────────
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _FullPageScribblePainter(kind: widget.kind),
              ),
            ),
          ),
          SafeArea(
            child: _result == null
                ? SizedBox.expand(child: _activeContent(isYoutube))
                : SizedBox.expand(child: _resultContent(isYoutube)),
          ),
        ],
      ),
    );
  }

  Widget _activeContent(bool isYoutube) {
    final action = switch (widget.kind) {
      DimiNotificationKind.planner => 'Slide to start session',
      DimiNotificationKind.youtube => 'Slide to continue learning',
      DimiNotificationKind.reminder => 'Slide to mark as done',
    };
    final sliderColor = isYoutube
        ? const Color(0xFFE53935)
        : const Color(0xFFF5A623);

    Widget padded(Widget child) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: child,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final availH = constraints.maxHeight;
        final mountainH = isYoutube
            ? (availH * 0.17).clamp(82.0, 136.0)
            : (availH * 0.19).clamp(92.0, 150.0);
        final headlineH = (availH * 0.16).clamp(122.0, 136.0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            padded(const _DimiBrand()),
            _MountainArt(height: mountainH),
            padded(_HeroHeadline(kind: widget.kind, height: headlineH)),
            padded(
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: isYoutube
                      ? (availH * 0.52).clamp(300.0, 430.0)
                      : double.infinity,
                ),
                child: _NotifCard(
                  kind: widget.kind,
                  title: widget.title,
                  body: widget.body,
                  note: widget.note,
                  channel: widget.channel,
                  thumbnailUrl: widget.thumbnailUrl,
                  scheduledTime: widget.scheduledTime,
                  progress: widget.playlistProgress,
                  watched: widget.videosWatched,
                  total: widget.videosTotal,
                  actions: _ActionRow(
                    busy: _busy,
                    onSnooze: _snooze,
                    onDismiss: _dismiss,
                  ),
                ),
              ),
            ),
            padded(
              DimiSlideToAction(
                label: action,
                color: sliderColor,
                onComplete: _complete,
              ),
            ),
            SizedBox(height: (availH * 0.014).clamp(10.0, 18.0)),
          ],
        );
      },
    );
  }

  Widget _resultContent(bool isYoutube) {
    final color = isYoutube ? const Color(0xFFE53935) : const Color(0xFFF5A623);
    final isSnoozed = _result!.startsWith('Snoozed');
    final icon = isSnoozed ? Icons.access_time_rounded : Icons.check_rounded;
    final label = switch (widget.kind) {
      DimiNotificationKind.planner =>
        isSnoozed ? 'Snoozed 5 min' : 'Session started!',
      DimiNotificationKind.youtube =>
        isSnoozed ? 'Snoozed 5 min' : 'Playlist updated!',
      DimiNotificationKind.reminder =>
        isSnoozed ? 'Snoozed 5 min' : 'Marked as done!',
    };
    final sublabel = isSnoozed
        ? "We'll remind you again in 5 minutes."
        : switch (widget.kind) {
            DimiNotificationKind.planner =>
              "Let's make it count. You've got this.",
            DimiNotificationKind.youtube => 'Keep up the great learning habit.',
            DimiNotificationKind.reminder =>
              'Great job staying on top of things.',
          };
    return _ResultScreen(
      color: color,
      icon: icon,
      label: label,
      sublabel: sublabel,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Full-page decorative scribble background — task 2
// Organic lines, loops, dots scattered across the warm cream background,
// matching the reference design aesthetic.
// ─────────────────────────────────────────────────────────────────────────────

class _FullPageScribblePainter extends CustomPainter {
  const _FullPageScribblePainter({required this.kind});
  final DimiNotificationKind kind;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final accent = kind == DimiNotificationKind.youtube
        ? const Color(0xFFE53935)
        : const Color(0xFFF5A623);

    Paint stroke(Color c, double opacity, double width) => Paint()
      ..color = c.withAlpha((255 * opacity).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    Paint fill(Color c, double opacity) =>
        Paint()..color = c.withAlpha((255 * opacity).round());

    // ── Bottom-right large decorative loop ────────────────────────────────
    final loopBR = Path()
      ..moveTo(w * 0.78, h * 0.82)
      ..cubicTo(w * 1.08, h * 0.72, w * 1.10, h * 0.95, w * 0.85, h * 0.98)
      ..cubicTo(w * 0.65, h * 1.00, w * 0.60, h * 0.88, w * 0.78, h * 0.82);
    canvas.drawPath(loopBR, stroke(accent, 0.13, 2.0));

    // ── Bottom-left curl ──────────────────────────────────────────────────
    final curlBL = Path()
      ..moveTo(w * 0.05, h * 0.88)
      ..cubicTo(w * -0.05, h * 0.82, w * -0.02, h * 0.94, w * 0.08, h * 0.96)
      ..cubicTo(w * 0.14, h * 0.97, w * 0.16, h * 0.92, w * 0.10, h * 0.90);
    canvas.drawPath(curlBL, stroke(accent, 0.15, 1.6));

    // ── Right edge wavy line ──────────────────────────────────────────────
    final waveR = Path()
      ..moveTo(w * 0.92, h * 0.52)
      ..quadraticBezierTo(w * 1.02, h * 0.60, w * 0.94, h * 0.68)
      ..quadraticBezierTo(w * 0.86, h * 0.76, w * 0.95, h * 0.84);
    canvas.drawPath(waveR, stroke(accent, 0.12, 1.4));

    // ── Left edge gentle arc ──────────────────────────────────────────────
    final arcL = Path()
      ..moveTo(w * 0.04, h * 0.60)
      ..quadraticBezierTo(w * -0.04, h * 0.70, w * 0.06, h * 0.78);
    canvas.drawPath(arcL, stroke(accent, 0.11, 1.3));

    // ── Bottom centre scallop ─────────────────────────────────────────────
    final scallop = Path()
      ..moveTo(w * 0.28, h * 0.96)
      ..quadraticBezierTo(w * 0.38, h * 0.90, w * 0.50, h * 0.94)
      ..quadraticBezierTo(w * 0.62, h * 0.98, w * 0.72, h * 0.93);
    canvas.drawPath(scallop, stroke(accent, 0.10, 1.2));

    // ── Small cross marks ─────────────────────────────────────────────────
    void cross(double cx, double cy, double r, double op) {
      final p = stroke(accent, op, 1.1);
      canvas.drawLine(Offset(cx - r, cy - r), Offset(cx + r, cy + r), p);
      canvas.drawLine(Offset(cx + r, cy - r), Offset(cx - r, cy + r), p);
    }

    cross(w * 0.12, h * 0.72, 5, 0.18);
    cross(w * 0.88, h * 0.68, 4, 0.15);
    cross(w * 0.50, h * 0.89, 4, 0.13);

    // ── Scattered dots ────────────────────────────────────────────────────
    final dots = [
      (w * 0.08, h * 0.82, 3.0, 0.20),
      (w * 0.18, h * 0.95, 2.0, 0.16),
      (w * 0.32, h * 0.86, 2.5, 0.14),
      (w * 0.66, h * 0.88, 2.0, 0.14),
      (w * 0.82, h * 0.76, 3.0, 0.18),
      (w * 0.94, h * 0.90, 2.2, 0.15),
      (w * 0.44, h * 0.98, 1.8, 0.12),
      (w * 0.90, h * 0.56, 2.0, 0.13),
    ];
    for (final (dx, dy, r, op) in dots) {
      canvas.drawCircle(Offset(dx, dy), r, fill(accent, op));
    }

    // ── Tiny tick marks (like hand-drawn emphasis) ────────────────────────
    final tick = stroke(accent, 0.14, 1.0);
    for (var i = 0; i < 3; i++) {
      final x = w * 0.76 + i * 8.0;
      canvas.drawLine(Offset(x, h * 0.94), Offset(x + 4, h * 0.97), tick);
    }
    for (var i = 0; i < 3; i++) {
      final x = w * 0.18 + i * 8.0;
      canvas.drawLine(Offset(x, h * 0.86), Offset(x + 4, h * 0.89), tick);
    }

    // ── Purple/lavender accent blobs for reminder type ────────────────────
    if (kind == DimiNotificationKind.reminder) {
      canvas.drawCircle(
        Offset(w * 0.88, h * 0.92),
        28,
        fill(const Color(0xFFBBA6F4), 0.10),
      );
      canvas.drawCircle(
        Offset(w * 0.14, h * 0.96),
        20,
        fill(const Color(0xFFBBA6F4), 0.08),
      );
    }

    // ── Warm amber blobs ──────────────────────────────────────────────────
    canvas.drawCircle(
      Offset(w * 0.96, h * 0.78),
      36,
      fill(const Color(0xFFFFCB8E), 0.13),
    );
    canvas.drawCircle(
      Offset(w * 0.04, h * 0.90),
      28,
      fill(const Color(0xFFFFCB8E), 0.11),
    );
    canvas.drawCircle(
      Offset(w * 0.50, h * 1.02),
      42,
      fill(const Color(0xFFFBD7C0), 0.12),
    );
  }

  @override
  bool shouldRepaint(covariant _FullPageScribblePainter old) =>
      old.kind != kind;
}

// ─────────────────────────────────────────────────────────────────────────────
// Mountain art
// ─────────────────────────────────────────────────────────────────────────────

class _MountainArt extends StatelessWidget {
  const _MountainArt({this.height = 140});
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: height,
    child: ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Colors.black,
          Colors.black,
          Colors.transparent,
        ],
        stops: [0.0, 0.14, 0.84, 1.0],
      ).createShader(bounds),
      blendMode: BlendMode.dstIn,
      child: Image.asset(
        'assets/Greeting/GreetingsBG.png',
        fit: BoxFit.cover,
        alignment: const Alignment(-0.35, -0.1),
        width: double.infinity,
        height: height,
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Brand
// ─────────────────────────────────────────────────────────────────────────────

class _DimiBrand extends StatelessWidget {
  const _DimiBrand();

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Image.asset(
        'assets/logos/dimi_splash_logo.png',
        width: 52,
        height: 52,
        fit: BoxFit.contain,
      ),
      Transform.translate(
        offset: const Offset(0, -4),
        child: const Text(
          'DIMI',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: Color(0xFF302A24),
            height: 1.0,
          ),
        ),
      ),
      Transform.translate(
        offset: const Offset(0, -4),
        child: const Text(
          'Plan  ·  Track  ·  Grow',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 9,
            fontWeight: FontWeight.w400,
            color: Color(0xFF81766B),
            height: 1.2,
          ),
        ),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero headline
// ─────────────────────────────────────────────────────────────────────────────

class _HeroHeadline extends StatelessWidget {
  const _HeroHeadline({required this.kind, this.height = 120});
  final DimiNotificationKind kind;
  final double height;

  @override
  Widget build(BuildContext context) {
    final isYoutube = kind == DimiNotificationKind.youtube;
    final accent = isYoutube
        ? const Color(0xFFE53935)
        : const Color(0xFFF5A623);

    final lines = switch (kind) {
      DimiNotificationKind.planner => ['Your', 'session', 'starts now.'],
      DimiNotificationKind.youtube => ['Ready to', 'continue', 'learning?'],
      DimiNotificationKind.reminder => ['A', 'reminder', 'for you.'],
    };
    final asset = switch (kind) {
      DimiNotificationKind.planner => 'assets/illustrations/Planner.png',
      DimiNotificationKind.youtube => 'assets/illustrations/Todo.png',
      DimiNotificationKind.reminder => 'assets/illustrations/Reminder.png',
    };

    return SizedBox(
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _HeroDecorationPainter(kind: kind),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 38,
                    height: 1.03,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    color: Color(0xFF27221D),
                  ),
                  children: [
                    TextSpan(text: '${lines[0]}\n'),
                    TextSpan(
                      text: '${lines[1]}\n',
                      style: TextStyle(color: accent),
                    ),
                    TextSpan(text: lines[2]),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 36,
                height: 3,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5A623),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          Positioned(
            right: -8,
            top: -4,
            child: Image.asset(
              asset,
              width: 132,
              height: 132,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroDecorationPainter extends CustomPainter {
  const _HeroDecorationPainter({required this.kind});
  final DimiNotificationKind kind;

  @override
  void paint(Canvas canvas, Size size) {
    final accent = kind == DimiNotificationKind.youtube
        ? const Color(0xFFE53935)
        : const Color(0xFFF5A623);

    Paint fill(Color color, double opacity) => Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;
    Paint stroke(Color color, double opacity, double width) => Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;

    // Soft, offset blobs echo the shapes inside the reminder card without
    // competing with the headline or illustration.
    canvas.drawCircle(
      Offset(size.width * .88, size.height * .28),
      size.width * .18,
      fill(accent, .08),
    );
    canvas.drawCircle(
      Offset(size.width * .78, size.height * .86),
      size.width * .13,
      fill(const Color(0xFFBBA6F4), .08),
    );
    canvas.drawCircle(
      Offset(size.width * .06, size.height * .78),
      size.width * .10,
      fill(const Color(0xFFFFCB8E), .12),
    );

    final arc = Path()
      ..moveTo(size.width * .62, size.height * .90)
      ..quadraticBezierTo(
        size.width * .78,
        size.height * .64,
        size.width * 1.02,
        size.height * .72,
      );
    canvas.drawPath(arc, stroke(accent, .22, 1.5));

    for (var i = 0; i < 3; i++) {
      final x = size.width * (.72 + i * .055);
      canvas.drawLine(
        Offset(x, size.height * .12),
        Offset(x + 5, size.height * .18),
        stroke(accent, .28, 1.4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HeroDecorationPainter old) => old.kind != kind;
}

// ─────────────────────────────────────────────────────────────────────────────
// Notification card dispatcher
// ─────────────────────────────────────────────────────────────────────────────

class _NotifCard extends StatelessWidget {
  const _NotifCard({
    required this.kind,
    required this.title,
    required this.body,
    required this.note,
    required this.channel,
    required this.thumbnailUrl,
    required this.scheduledTime,
    required this.progress,
    required this.watched,
    required this.total,
    required this.actions,
  });

  final DimiNotificationKind kind;
  final String title, body, note, channel, thumbnailUrl;
  final DateTime scheduledTime;
  final int progress, watched, total;
  final Widget actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 30,
            spreadRadius: 1,
            offset: Offset(0, 12),
          ),
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: switch (kind) {
        DimiNotificationKind.youtube => _YoutubeCard(
          title: title,
          channel: channel,
          thumbnailUrl: thumbnailUrl,
          progress: progress,
          watched: watched,
          total: total,
          actions: actions,
        ),
        _ => _PlannerReminderCard(
          kind: kind,
          title: title,
          scheduledTime: scheduledTime,
          actions: actions,
        ),
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Planner + Reminder card — task 2 scribble blob inside card too
// ─────────────────────────────────────────────────────────────────────────────

class _PlannerReminderCard extends StatelessWidget {
  const _PlannerReminderCard({
    required this.kind,
    required this.title,
    required this.scheduledTime,
    required this.actions,
  });

  final DimiNotificationKind kind;
  final String title;
  final DateTime scheduledTime;
  final Widget actions;

  @override
  Widget build(BuildContext context) {
    final isPlanner = kind == DimiNotificationKind.planner;
    final widgetBg = isPlanner
        ? const Color(0xFFFFF3E0)
        : const Color(0xFFF0EEFF);
    final widgetBorder = isPlanner
        ? const Color(0xFFFFCC80)
        : const Color(0xFFD0C8FF);
    final widgetTextColor = isPlanner
        ? const Color(0xFFE65100)
        : const Color(0xFF5C4FCC);
    final ampmColor = isPlanner
        ? const Color(0xFFF5A623)
        : const Color(0xFF7B6FE8);

    final hourStr = DateFormat('hh').format(scheduledTime);
    final minStr = DateFormat('mm').format(scheduledTime);
    final ampm = DateFormat('a').format(scheduledTime);

    final raw = title.trim().isEmpty
        ? (isPlanner ? 'Session' : 'Reminder')
        : title.trim();
    return Stack(
      children: [
        Positioned.fill(child: CustomPaint(painter: _CardBlobPainter())),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomPaint(
                size: const Size(26, 16),
                painter: _AccentHashPainter(),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          raw,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF171717),
                            height: 1.25,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Time widget — hour stacked over minutes
                  Container(
                    width: 72,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: widgetBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: widgetBorder, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: widgetBorder.withValues(alpha: .35),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          hourStr,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: widgetTextColor,
                            height: 1.0,
                            letterSpacing: -1,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          height: 1.5,
                          width: 32,
                          decoration: BoxDecoration(
                            color: widgetBorder,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                        Text(
                          minStr,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: widgetTextColor,
                            height: 1.0,
                            letterSpacing: -0.5,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          ampm,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: ampmColor,
                            height: 1.0,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              actions,
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// YouTube notification card — task 3 overflow fix
// Compact layout: /// header + title + channel + ratio-preserving thumbnail +
// progress row + watched count + action buttons.
// ─────────────────────────────────────────────────────────────────────────────

class _YoutubeCard extends StatelessWidget {
  const _YoutubeCard({
    required this.title,
    required this.channel,
    required this.thumbnailUrl,
    required this.progress,
    required this.watched,
    required this.total,
    required this.actions,
  });

  final String title, channel, thumbnailUrl;
  final int progress, watched, total;
  final Widget actions;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: CustomPaint(painter: _CardBlobPainter())),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // /// accent + YouTube badge in same row
              Row(
                children: [
                  CustomPaint(
                    size: const Size(26, 16),
                    painter: _AccentHashPainter(),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Title
              Text(
                title.trim().isEmpty ? 'Daily Watch Reminder' : title.trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF171717),
                  height: 1.2,
                ),
              ),
              // Channel
              if (channel.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  channel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: Color(0xFF81766B),
                    height: 1.3,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              // Keep the full thumbnail visible at its native 16:9 ratio.
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FractionallySizedBox(
                  widthFactor: 1.0,
                  alignment: Alignment.center,
                  child: AspectRatio(
                    // Crop the source letterbox bars and use the normal
                    // YouTube thumbnail ratio so the card stays compact.
                    aspectRatio: 16 / 9,
                    child: thumbnailUrl.isNotEmpty
                        ? Image.network(
                            thumbnailUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _thumbPlaceholder(),
                            loadingBuilder: (_, child, prog) {
                              if (prog == null) return child;
                              return _thumbLoading();
                            },
                          )
                        : _thumbPlaceholder(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Progress bar + percentage
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: LinearProgressIndicator(
                        value: (progress / 100).clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: const Color(0xFFF0E8DF),
                        color: const Color(0xFFE53935),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$progress%',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: Color(0xFF3A332C),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              // Watched count
              Text(
                '$watched of $total video${total == 1 ? '' : 's'} watched',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  color: Color(0xFF81766B),
                ),
              ),
              const SizedBox(height: 10),
              actions,
            ],
          ),
        ),
      ],
    );
  }

  Widget _thumbPlaceholder() => Container(
    color: const Color(0xFFF0E8DF),
    child: const Center(
      child: Icon(
        Icons.play_circle_outline_rounded,
        size: 32,
        color: Color(0xFFE53935),
      ),
    ),
  );

  Widget _thumbLoading() => Container(
    color: const Color(0xFFF5EDD8),
    child: const Center(
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Color(0xFFE53935),
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Action buttons — task 5: cancel notification before acting
// ─────────────────────────────────────────────────────────────────────────────

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.destructive = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 46,
    child: OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 15),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: destructive ? Colors.white : const Color(0xFF3A332C),
        backgroundColor: destructive
            ? const Color(0xFFE5242A)
            : Colors.white.withValues(alpha: .92),
        side: BorderSide(
          color: destructive
              ? const Color(0xFFE5242A)
              : const Color(0xFFE4D9CF),
        ),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.busy,
    required this.onSnooze,
    required this.onDismiss,
  });
  final bool busy;
  final VoidCallback onSnooze;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _PillButton(
          icon: Icons.access_time_rounded,
          label: 'Snooze 5 min',
          onPressed: busy ? null : onSnooze,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _PillButton(
          icon: Icons.close_rounded,
          label: 'Not now',
          destructive: true,
          onPressed: busy ? null : onDismiss,
        ),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Slide to action
// ─────────────────────────────────────────────────────────────────────────────

class DimiSlideToAction extends StatefulWidget {
  const DimiSlideToAction({
    super.key,
    required this.label,
    required this.color,
    required this.onComplete,
  });
  final String label;
  final Color color;
  final VoidCallback onComplete;

  @override
  State<DimiSlideToAction> createState() => _DimiSlideToActionState();
}

class _DimiSlideToActionState extends State<DimiSlideToAction> {
  double _progress = 0;
  bool _dragging = false;
  bool _done = false;

  void _setProgress(Offset local, double width) {
    final max = width - 64;
    setState(() => _progress = ((local.dx - 32) / max).clamp(0, 1));
  }

  void _finish() {
    if (_done) return;
    setState(() {
      _done = true;
      _progress = 1;
    });
    Future<void>.delayed(const Duration(milliseconds: 280), widget.onComplete);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => GestureDetector(
      onHorizontalDragStart: _done
          ? null
          : (_) => setState(() => _dragging = true),
      onHorizontalDragUpdate: _done
          ? null
          : (details) => _setProgress(
              (context.findRenderObject() as RenderBox).globalToLocal(
                details.globalPosition,
              ),
              constraints.maxWidth,
            ),
      onHorizontalDragEnd: _done
          ? null
          : (_) {
              setState(() => _dragging = false);
              if (_progress >= .88) {
                _finish();
              } else {
                setState(() => _progress = 0);
              }
            },
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [widget.color.withValues(alpha: .70), widget.color],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: .28),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: (1 - _progress * 1.6).clamp(0, 1),
              child: Text(
                widget.label,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            AnimatedPositioned(
              duration: _dragging
                  ? Duration.zero
                  : const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              left: 4 + _progress * (constraints.maxWidth - 62),
              top: 3,
              child: Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  size: 24,
                  color: Color(0xFF3A332C),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Result screen
// ─────────────────────────────────────────────────────────────────────────────

class _ResultScreen extends StatefulWidget {
  const _ResultScreen({
    required this.color,
    required this.icon,
    required this.label,
    required this.sublabel,
  });
  final Color color;
  final IconData icon;
  final String label;
  final String sublabel;

  @override
  State<_ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<_ResultScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  late final Animation<double> _slideUp;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _slideUp = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
      ),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: CustomPaint(painter: _ResultBlobPainter(color: widget.color)),
      ),
      Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _scale,
              child: Icon(widget.icon, size: 80, color: widget.color),
            ),
            const SizedBox(height: 24),
            AnimatedBuilder(
              animation: _ctrl,
              builder: (context, child) => Opacity(
                opacity: _fade.value,
                child: Transform.translate(
                  offset: Offset(0, _slideUp.value),
                  child: child,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF27221D),
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      widget.sublabel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: Color(0xFF81766B),
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      3,
                      (i) => _Dot(
                        color: widget.color,
                        delay: i * 0.12,
                        controller: _ctrl,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _Dot extends StatelessWidget {
  const _Dot({
    required this.color,
    required this.delay,
    required this.controller,
  });
  final Color color;
  final double delay;
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    final anim = CurvedAnimation(
      parent: controller,
      curve: Interval(delay, (delay + 0.4).clamp(0, 1), curve: Curves.easeOut),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (context, _) => Container(
        width: 7,
        height: 7,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: anim.value),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card blob background painter
// ─────────────────────────────────────────────────────────────────────────────

class _CardBlobPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
      Offset(size.width * 1.04, size.height * 0.06),
      size.width * 0.38,
      Paint()..color = const Color(0xFFFBD7C0).withValues(alpha: .50),
    );
    canvas.drawCircle(
      Offset(size.width * -0.07, size.height * 0.86),
      size.width * 0.32,
      Paint()..color = const Color(0xFFFFF0DC).withValues(alpha: .55),
    );
    canvas.drawCircle(
      Offset(size.width * 0.88, size.height * 0.66),
      size.width * 0.16,
      Paint()..color = const Color(0xFFF5C88A).withValues(alpha: .25),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Orange /// accent hash marks
// ─────────────────────────────────────────────────────────────────────────────

class _AccentHashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFFF5A623)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 3; i++) {
      final x = 3.0 + i * 8.0;
      canvas.drawLine(Offset(x, size.height), Offset(x + 4.0, 0), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Result screen blob background
// ─────────────────────────────────────────────────────────────────────────────

class _ResultBlobPainter extends CustomPainter {
  const _ResultBlobPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
      Offset(-40, size.height * 0.20),
      110,
      Paint()..color = const Color(0xFFFFCB8E).withValues(alpha: .16),
    );
    canvas.drawCircle(
      Offset(size.width + 40, size.height * 0.15),
      90,
      Paint()..color = color.withValues(alpha: .10),
    );
    canvas.drawCircle(
      Offset(size.width + 50, size.height * 0.36),
      140,
      Paint()..color = const Color(0xFFBBA6F4).withValues(alpha: .13),
    );
    canvas.drawCircle(
      Offset(-30, size.height * 0.85),
      120,
      Paint()..color = color.withValues(alpha: .09),
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height + 50),
      130,
      Paint()..color = const Color(0xFFFFCB8E).withValues(alpha: .14),
    );
    // scribble strokes on result screen too
    final stroke = Paint()
      ..color = color.withValues(alpha: .16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.60, size.height * 0.10)
        ..quadraticBezierTo(
          size.width * 0.80,
          size.height * 0.17,
          size.width * 0.90,
          size.height * 0.11,
        ),
      stroke,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.08, size.height * 0.72)
        ..quadraticBezierTo(
          size.width * 0.18,
          size.height * 0.65,
          size.width * 0.28,
          size.height * 0.73,
        ),
      stroke,
    );
    final dot = Paint()..color = color.withValues(alpha: .28);
    canvas.drawCircle(Offset(size.width * 0.72, size.height * 0.22), 3.5, dot);
    canvas.drawCircle(Offset(size.width * 0.18, size.height * 0.55), 3.0, dot);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.60), 4.0, dot);
    canvas.drawCircle(Offset(size.width * 0.35, size.height * 0.88), 3.0, dot);
  }

  @override
  bool shouldRepaint(covariant _ResultBlobPainter old) => old.color != color;
}

// Keep the math import used by _FullPageScribblePainter
// ignore: unused_element
final _kPi = math.pi;
