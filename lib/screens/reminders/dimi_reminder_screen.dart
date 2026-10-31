import 'dart:async';

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
        await NotificationService.instance.cancelReminder(widget.notifId);
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
      if (mounted) {
        setState(() {
          _busy = false;
          _result = 'Could not complete this notification.';
        });
      }
    }
  }

  Future<void> _snooze() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
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
      if (mounted) {
        setState(() {
          _busy = false;
          _result = 'Could not snooze this notification.';
        });
      }
    }
  }

  Future<void> _dismiss() async {
    if (_busy) return;
    setState(() => _busy = true);
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
    final red = widget.kind == DimiNotificationKind.youtube;
    return Scaffold(
      backgroundColor: const Color(0xFFFAF5ED),
      body: SafeArea(
        child: _result == null
            ? SizedBox.expand(child: _activeContent(red))
            : SizedBox.expand(child: _resultContent(red)),
      ),
    );
  }

  Widget _activeContent(bool red) {
    final action = switch (widget.kind) {
      DimiNotificationKind.planner => 'Slide to start session',
      DimiNotificationKind.youtube => 'Slide to continue learning',
      DimiNotificationKind.reminder => 'Slide to mark as done',
    };
    final accent = red ? const Color(0xFFE53935) : const Color(0xFFF5A623);
    final isYoutube = widget.kind == DimiNotificationKind.youtube;

    Widget padded(Widget child) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: child,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final availH = constraints.maxHeight;
        // Mountain height: 24% of available, clamped
        final mountainH = (availH * 0.24).clamp(120.0, 180.0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: availH * 0.012),
            padded(const _DimiBrand()),
            SizedBox(height: availH * 0.010),
            if (!isYoutube) ...[
              _MountainArt(height: mountainH),
              SizedBox(height: availH * 0.008),
            ] else
              SizedBox(height: availH * 0.016),
            padded(_HeroHeadline(red: red, kind: widget.kind)),
            SizedBox(height: availH * 0.010),
            // Card — shared for all 3 variants
            padded(
              _NotifCard(
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
            const Spacer(),
            _BottomDecor(height: (availH * 0.06).clamp(28.0, 52.0)),
            SizedBox(height: availH * 0.008),
            padded(
              DimiSlideToAction(
                label: action,
                color: accent,
                onComplete: _complete,
              ),
            ),
            SizedBox(height: availH * 0.020),
          ],
        );
      },
    );
  }

  Widget _resultContent(bool red) {
    final color = red ? const Color(0xFFE53935) : const Color(0xFFF5A623);
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
// Mountain art
// ─────────────────────────────────────────────────────────────────────────────

class _MountainArt extends StatelessWidget {
  const _MountainArt({this.height = 165});
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
        width: 62,
        height: 62,
        fit: BoxFit.contain,
      ),
      Transform.translate(
        offset: const Offset(0, -6),
        child: const Text(
          'DIMI',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: Color(0xFF302A24),
            height: 1.0,
          ),
        ),
      ),
      Transform.translate(
        offset: const Offset(0, -6),
        child: const Text(
          'Plan  ·  Track  ·  Grow',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
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
  const _HeroHeadline({required this.red, required this.kind});
  final bool red;
  final DimiNotificationKind kind;

  @override
  Widget build(BuildContext context) {
    final accent = red ? const Color(0xFFE53935) : const Color(0xFFF5A623);
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
      height: 148,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 40,
                    height: 1.06,
                    fontWeight: FontWeight.w800,
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
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 3.5,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5A623),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          Positioned(
            right: -10,
            top: -10,
            child: Image.asset(
              asset,
              width: 160,
              height: 160,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Unified notification card — same design for planner, reminder, youtube
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
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: kind == DimiNotificationKind.youtube
          ? _YoutubeCardContent(
              title: title,
              channel: channel,
              thumbnailUrl: thumbnailUrl,
              progress: progress,
              watched: watched,
              total: total,
              actions: actions,
            )
          : _DimiNotifCard(
              title: title,
              scheduledTime: scheduledTime,
              actions: actions,
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Planner + Reminder card content (shared design)
// ─────────────────────────────────────────────────────────────────────────────

class _DimiNotifCard extends StatelessWidget {
  const _DimiNotifCard({
    required this.title,
    required this.scheduledTime,
    required this.actions,
  });

  final String title;
  final DateTime scheduledTime;
  final Widget actions;

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('h:mm').format(scheduledTime);
    final ampm = DateFormat('a').format(scheduledTime);

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        // Title font: responsive to card width
        final titleFontSize = w < 300 ? 20.0 : 28.0;
        // Cap title to ~42 chars to prevent overflow without "..."
        final raw = title.trim().isEmpty ? 'Reminder' : title.trim();
        final displayTitle = raw.length > 42
            ? '${raw.substring(0, 42).trimRight()}…'
            : raw;

        return Stack(
          children: [
            // Decorative blobs fill the full card (clipped by container)
            Positioned.fill(child: CustomPaint(painter: _CardBlobPainter())),

            // Content with its own padding
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Orange /// accent marks
                  CustomPaint(
                    size: const Size(28, 20),
                    painter: _AccentHashPainter(),
                  ),
                  const SizedBox(height: 6),

                  // Title — dark, bold
                  Text(
                    displayTitle,
                    maxLines: 2,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF171717),
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Time — centered with cream capsule
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5EDD8),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            timeStr,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: w < 320 ? 50.0 : 62.0,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF171717),
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            ampm,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF8A8A8A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Buttons
                  actions,
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// YouTube card content
// ─────────────────────────────────────────────────────────────────────────────

class _YoutubeCardContent extends StatelessWidget {
  const _YoutubeCardContent({
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
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(child: CustomPaint(painter: _CardBlobPainter())),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomPaint(
              size: const Size(28, 20),
              painter: _AccentHashPainter(),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 20,
                          height: 1.18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF171717),
                        ),
                      ),
                      if (channel.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          channel,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: Color(0xFF81766B),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (thumbnailUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      thumbnailUrl,
                      width: 100,
                      height: 66,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (progress / 100).clamp(0, 1),
                      minHeight: 8,
                      backgroundColor: const Color(0xFFF0E8DF),
                      color: const Color(0xFFE53935),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$progress%',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              '$watched of $total videos watched',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: Color(0xFF81766B),
              ),
            ),
            const SizedBox(height: 16),
            actions,
          ],
        ),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Action buttons
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
    height: 50,
    child: OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 17),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: destructive ? Colors.white : const Color(0xFF3A332C),
        backgroundColor: destructive
            ? const Color(0xFFE5242A)
            : Colors.white.withValues(alpha: .90),
        side: BorderSide(
          color: destructive
              ? const Color(0xFFE5242A)
              : const Color(0xFFE4D9CF),
        ),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
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
      const SizedBox(width: 12),
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
// Slide-to-action
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
              if (_progress >= .92) {
                _finish();
              } else {
                setState(() => _progress = 0);
              }
            },
      // Tap intentionally removed — slide only.
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [widget.color.withValues(alpha: .65), widget.color],
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: .3),
              blurRadius: 20,
              offset: const Offset(0, 10),
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
              left: 4 + _progress * (constraints.maxWidth - 64),
              top: 4,
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  size: 27,
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
// Result screen — session started / snoozed / done
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
      duration: const Duration(milliseconds: 620),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _slideUp = Tween<double>(begin: 24, end: 0).animate(
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
      // Decorative blob background
      Positioned.fill(
        child: CustomPaint(painter: _ResultBlobPainter(color: widget.color)),
      ),
      // Centered content
      Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _scale,
              child: Icon(widget.icon, size: 88, color: widget.color),
            ),
            const SizedBox(height: 28),
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
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF27221D),
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
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF81766B),
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
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
// Bottom decorative strip above slider
// ─────────────────────────────────────────────────────────────────────────────

class _BottomDecor extends StatelessWidget {
  const _BottomDecor({this.height = 40});
  final double height;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: SizedBox(
      height: height,
      child: CustomPaint(painter: _BottomBlobPainter()),
    ),
  );
}

class _BottomBlobPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final orange = Paint()
      ..color = const Color(0xFFF5A623).withValues(alpha: .18);
    final peach = Paint()
      ..color = const Color(0xFFFFCB8E).withValues(alpha: .22);
    final lavender = Paint()
      ..color = const Color(0xFFBBA6F4).withValues(alpha: .20);

    canvas.drawCircle(Offset(size.width * 0.12, size.height * 0.6), 38, peach);
    canvas.drawCircle(Offset(size.width * 0.88, size.height * 0.5), 44, orange);
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.3),
      18,
      lavender,
    );

    final paint = Paint()
      ..color = const Color(0xFFF5A623).withValues(alpha: .25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.18, size.height * 0.8)
        ..quadraticBezierTo(
          size.width * 0.3,
          size.height * 0.2,
          size.width * 0.42,
          size.height * 0.7,
        ),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.62, size.height * 0.9)
        ..quadraticBezierTo(
          size.width * 0.75,
          size.height * 0.3,
          size.width * 0.85,
          size.height * 0.75,
        ),
      paint,
    );

    final dot = Paint()..color = const Color(0xFFF5A623).withValues(alpha: .40);
    canvas.drawCircle(Offset(size.width * 0.55, size.height * 0.25), 4, dot);
    canvas.drawCircle(Offset(size.width * 0.22, size.height * 0.35), 3, dot);
    canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.7), 5, dot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Card blob background painter
// ─────────────────────────────────────────────────────────────────────────────

class _CardBlobPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Large peach blob — top right
    canvas.drawCircle(
      Offset(size.width * 1.05, size.height * 0.05),
      size.width * 0.42,
      Paint()..color = const Color(0xFFFBD7C0).withValues(alpha: .65),
    );
    // Cream blob — bottom left
    canvas.drawCircle(
      Offset(size.width * -0.08, size.height * 0.85),
      size.width * 0.38,
      Paint()..color = const Color(0xFFFFF0DC).withValues(alpha: .70),
    );
    // Pale orange — center right
    canvas.drawCircle(
      Offset(size.width * 0.92, size.height * 0.60),
      size.width * 0.20,
      Paint()..color = const Color(0xFFF5C88A).withValues(alpha: .30),
    );
    // Swirl stroke
    final swirl = Paint()
      ..color = const Color(0xFFF5A623).withValues(alpha: .12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 28
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.72, size.height * 0.90)
        ..quadraticBezierTo(
          size.width * 0.92,
          size.height * 0.80,
          size.width * 1.02,
          size.height * 0.95,
        ),
      swirl,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Orange /// accent hash marks (top-left of card title)
// ─────────────────────────────────────────────────────────────────────────────

class _AccentHashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFFF5A623)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 3; i++) {
      final x = 4.0 + i * 9.0;
      canvas.drawLine(Offset(x, size.height), Offset(x + 5, 0), p);
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
      Offset(-40, size.height * 0.2),
      130,
      Paint()..color = const Color(0xFFFFCB8E).withValues(alpha: .18),
    );
    canvas.drawCircle(
      Offset(size.width + 40, size.height * 0.15),
      110,
      Paint()..color = color.withValues(alpha: .12),
    );
    canvas.drawCircle(
      Offset(size.width + 50, size.height * 0.35),
      160,
      Paint()..color = const Color(0xFFBBA6F4).withValues(alpha: .16),
    );
    canvas.drawCircle(
      Offset(-30, size.height * 0.85),
      140,
      Paint()..color = color.withValues(alpha: .12),
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height + 60),
      150,
      Paint()..color = const Color(0xFFFFCB8E).withValues(alpha: .18),
    );

    final stroke = Paint()
      ..color = color.withValues(alpha: .20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.6, size.height * 0.1)
        ..quadraticBezierTo(
          size.width * 0.8,
          size.height * 0.18,
          size.width * 0.9,
          size.height * 0.12,
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

    final dot = Paint()..color = color.withValues(alpha: .35);
    canvas.drawCircle(Offset(size.width * 0.72, size.height * 0.22), 5, dot);
    canvas.drawCircle(Offset(size.width * 0.18, size.height * 0.55), 4, dot);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.6), 6, dot);
    canvas.drawCircle(Offset(size.width * 0.35, size.height * 0.88), 4, dot);
  }

  @override
  bool shouldRepaint(covariant _ResultBlobPainter old) => old.color != color;
}
