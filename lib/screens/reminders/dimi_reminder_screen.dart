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
// Screen widget — all logic untouched
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
    final isYoutube = widget.kind == DimiNotificationKind.youtube;
    return Scaffold(
      backgroundColor: const Color(0xFFFAF5ED),
      body: SafeArea(
        child: _result == null
            ? SizedBox.expand(child: _activeContent(isYoutube))
            : SizedBox.expand(child: _resultContent(isYoutube)),
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
        // YouTube has a large thumbnail so needs more card space — shrink other elements
        final mountainH = isYoutube
            ? (availH * 0.19).clamp(90.0, 150.0)
            : (availH * 0.235).clamp(110.0, 175.0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: availH * 0.008),
            padded(const _DimiBrand()),
            SizedBox(height: availH * 0.006),
            _MountainArt(height: mountainH),
            SizedBox(height: availH * 0.005),
            padded(_HeroHeadline(kind: widget.kind)),
            SizedBox(height: availH * 0.008),
            padded(
              ConstrainedBox(
                // Hard cap so the card + thumbnail never overflows the screen
                constraints: BoxConstraints(
                  maxHeight: isYoutube
                      ? (availH * 0.42).clamp(200.0, 340.0)
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
            const Spacer(),
            SizedBox(height: availH * 0.005),
            padded(
              DimiSlideToAction(
                label: action,
                color: sliderColor,
                onComplete: _complete,
              ),
            ),
            SizedBox(height: availH * 0.016),
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
// Mountain art — shown on all 3 screens
// ─────────────────────────────────────────────────────────────────────────────

class _MountainArt extends StatelessWidget {
  const _MountainArt({this.height = 155});
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
        width: 58,
        height: 58,
        fit: BoxFit.contain,
      ),
      Transform.translate(
        offset: const Offset(0, -5),
        child: const Text(
          'DIMI',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: Color(0xFF302A24),
            height: 1.0,
          ),
        ),
      ),
      Transform.translate(
        offset: const Offset(0, -5),
        child: const Text(
          'Plan  ·  Track  ·  Grow',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
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
  const _HeroHeadline({required this.kind});
  final DimiNotificationKind kind;

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
      height: 138,
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
                    fontSize: 38,
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
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 3,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5A623),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          Positioned(
            right: -10,
            top: -8,
            child: Image.asset(
              asset,
              width: 150,
              height: 150,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Unified notification card dispatcher
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
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 20,
            offset: Offset(0, 8),
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
        DimiNotificationKind.planner => _PlannerReminderCard(
          kind: kind,
          title: title,
          scheduledTime: scheduledTime,
          actions: actions,
        ),
        DimiNotificationKind.reminder => _PlannerReminderCard(
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
// Planner + Reminder: title left, floating time widget right
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
    // Planner: warm orange widget. Reminder: lavender/purple widget.
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
    final indicatorIcon = isPlanner
        ? Icons.wb_sunny_outlined
        : Icons.nightlight_round;

    final timeStr = DateFormat('h:mm').format(scheduledTime);
    final ampm = DateFormat('a').format(scheduledTime);

    // Strip any "category:" prefix the service might prepend
    final raw = title.trim().isEmpty
        ? (isPlanner ? 'Session' : 'Reminder')
        : title.trim();
    // Truncate gracefully — never touch the DB value
    final displayTitle = raw.length > 42
        ? '${raw.substring(0, 42).trimRight()}…'
        : raw;

    return Stack(
      children: [
        // Card blob background
        Positioned.fill(child: CustomPaint(painter: _CardBlobPainter())),

        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: /// marks
              CustomPaint(
                size: const Size(26, 18),
                painter: _AccentHashPainter(),
              ),
              const SizedBox(height: 8),

              // Title + floating time widget side by side
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title — left side, takes available space
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Text(
                        displayTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF171717),
                          height: 1.25,
                        ),
                      ),
                    ),
                  ),

                  // Floating time widget — right side
                  Container(
                    width: 88,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: widgetBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: widgetBorder, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: widgetBorder.withValues(alpha: .4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(indicatorIcon, size: 16, color: ampmColor),
                        const SizedBox(height: 2),
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: widgetTextColor,
                            height: 1.0,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        Text(
                          ampm,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: ampmColor,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              actions,
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// YouTube card — thumbnail in original 16:9 ratio, no crop
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
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      return Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _CardBlobPainter())),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // /// accent
                CustomPaint(
                  size: const Size(26, 18),
                  painter: _AccentHashPainter(),
                ),
                const SizedBox(height: 6),

                // Title row with YouTube logo
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        title.trim().isEmpty
                            ? 'Daily Watch Reminder'
                            : title.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF171717),
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // YouTube logo badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ],
                ),

                // Channel name
                if (channel.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    channel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Color(0xFF81766B),
                      height: 1.3,
                    ),
                  ),
                ],

                const SizedBox(height: 10),

                // Thumbnail — full card width, 16:9, cover (no black bars)
                if (thumbnailUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network(
                        thumbnailUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: const Color(0xFFF0E8DF),
                          child: const Center(
                            child: Icon(
                              Icons.play_circle_outline_rounded,
                              size: 36,
                              color: Color(0xFFE53935),
                            ),
                          ),
                        ),
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: const Color(0xFFF5EDD8),
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFE53935),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  )
                else
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        color: const Color(0xFFF0E8DF),
                        child: const Center(
                          child: Icon(
                            Icons.play_circle_outline_rounded,
                            size: 36,
                            color: Color(0xFFE53935),
                          ),
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 10),

                // Progress bar + percentage
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: (progress / 100).clamp(0, 1),
                          minHeight: 7,
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
                        fontSize: 12,
                        color: Color(0xFF3A332C),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$watched of $total video${total == 1 ? '' : 's'} watched',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: Color(0xFF81766B),
                  ),
                ),

                const SizedBox(height: 14),
                actions,
              ],
            ),
          ),
        ],
      );
    },
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Action buttons — unchanged logic
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
    height: 48,
    child: OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
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
// Slide-to-action — unchanged logic, slide-only
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
      child: Container(
        height: 62,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [widget.color.withValues(alpha: .65), widget.color],
          ),
          borderRadius: BorderRadius.circular(31),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: .3),
              blurRadius: 16,
              offset: const Offset(0, 8),
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
              top: 3,
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  size: 26,
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
// Result screen — centered, animated, with blob bg
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
      Positioned.fill(
        child: CustomPaint(painter: _ResultBlobPainter(color: widget.color)),
      ),
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
// Card blob background painter (shared)
// ─────────────────────────────────────────────────────────────────────────────

class _CardBlobPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
      Offset(size.width * 1.05, size.height * 0.05),
      size.width * 0.40,
      Paint()..color = const Color(0xFFFBD7C0).withValues(alpha: .55),
    );
    canvas.drawCircle(
      Offset(size.width * -0.08, size.height * 0.85),
      size.width * 0.35,
      Paint()..color = const Color(0xFFFFF0DC).withValues(alpha: .60),
    );
    canvas.drawCircle(
      Offset(size.width * 0.90, size.height * 0.65),
      size.width * 0.18,
      Paint()..color = const Color(0xFFF5C88A).withValues(alpha: .28),
    );
    final swirl = Paint()
      ..color = const Color(0xFFF5A623).withValues(alpha: .10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.74, size.height * 0.88)
        ..quadraticBezierTo(
          size.width * 0.92,
          size.height * 0.78,
          size.width * 1.02,
          size.height * 0.94,
        ),
      swirl,
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
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 3; i++) {
      final x = 3.0 + i * 8.5;
      canvas.drawLine(Offset(x, size.height), Offset(x + 4.5, 0), p);
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
      120,
      Paint()..color = const Color(0xFFFFCB8E).withValues(alpha: .18),
    );
    canvas.drawCircle(
      Offset(size.width + 40, size.height * 0.15),
      100,
      Paint()..color = color.withValues(alpha: .12),
    );
    canvas.drawCircle(
      Offset(size.width + 50, size.height * 0.35),
      150,
      Paint()..color = const Color(0xFFBBA6F4).withValues(alpha: .15),
    );
    canvas.drawCircle(
      Offset(-30, size.height * 0.85),
      130,
      Paint()..color = color.withValues(alpha: .11),
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height + 55),
      140,
      Paint()..color = const Color(0xFFFFCB8E).withValues(alpha: .16),
    );
    final stroke = Paint()
      ..color = color.withValues(alpha: .18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.6, size.height * 0.1)
        ..quadraticBezierTo(
          size.width * 0.8,
          size.height * 0.17,
          size.width * 0.9,
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
    final dot = Paint()..color = color.withValues(alpha: .32);
    canvas.drawCircle(Offset(size.width * 0.72, size.height * 0.22), 4, dot);
    canvas.drawCircle(Offset(size.width * 0.18, size.height * 0.55), 3.5, dot);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.6), 5, dot);
    canvas.drawCircle(Offset(size.width * 0.35, size.height * 0.88), 3.5, dot);
  }

  @override
  bool shouldRepaint(covariant _ResultBlobPainter old) => old.color != color;
}
