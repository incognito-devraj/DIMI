import 'dart:async';
import 'dart:math' as math;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/database.dart';
import '../../providers/database_provider.dart';
import '../../services/notification_service.dart';
import '../../services/sync_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DimiReminderScreen
//
// Full-screen reminder experience. Launched by DimiReminderActivity when the
// user has Full-screen notification mode enabled. Receives reminder data as
// route query parameters (reminderId, accountId, title, body, timeMillis,
// notifId) — all content is available immediately on first frame with no
// async DB load needed for display.
//
// Actions:
//   Mark Done  — disables reminder in Drift → cancels notification → sync
//   Snooze     — updates dueAt +5 min in Drift → reschedules → sync
//   Dismiss    — cancels notification only (reminder stays enabled)
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
  });

  final int reminderId;
  final int accountId;
  final String title;
  final String body;
  final DateTime scheduledTime;
  final int notifId;

  @override
  ConsumerState<DimiReminderScreen> createState() => _DimiReminderScreenState();
}

class _DimiReminderScreenState extends ConsumerState<DimiReminderScreen>
    with TickerProviderStateMixin {
  // Bell ring animation
  late final AnimationController _bellCtrl;
  late final Animation<double> _bellRing;

  // Glow pulse animation
  late final AnimationController _glowCtrl;
  late final Animation<double> _glowPulse;

  // Entrance animation
  late final AnimationController _entranceCtrl;
  late final Animation<double> _entranceFade;
  late final Animation<Offset> _entranceSlide;

  bool _busy = false;
  String? _feedback;

  @override
  void initState() {
    super.initState();

    // Keep status bar hidden — full-screen experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Bell: rocks left-right 5° then back, repeats
    _bellCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _bellRing = Tween<double>(
      begin: -0.09,
      end: 0.09,
    ).animate(CurvedAnimation(parent: _bellCtrl, curve: Curves.easeInOut));

    // Glow: outer ring pulses in opacity 0.3→0.7
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _glowPulse = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    // Entrance: content slides up from 24 px below + fades in
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    )..forward();
    _entranceFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    );
    _entranceSlide =
        Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(
          CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic),
        );
  }

  @override
  void dispose() {
    _bellCtrl.dispose();
    _glowCtrl.dispose();
    _entranceCtrl.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  AppDatabase get _db => ref.read(databaseProvider);

  /// Restore account context so account-scoped DAO methods work correctly.
  void _restoreAccount() {
    if (widget.accountId > 0) {
      _db.setActiveAccountId(widget.accountId);
    }
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _markDone() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      _restoreAccount();
      // 1. Update Drift first — local-first
      await _db.reminderDao.toggleEnabled(widget.reminderId, false);
      NotificationService.instance.onLocalActionCommitted?.call();
      // 2. Cancel the notification immediately
      await NotificationService.instance.cancelReminder(widget.notifId);
      // 3. Sync in background — never block UI on network
      unawaited(SyncService(_db).syncNow());
      if (mounted) {
        setState(() => _feedback = 'Done! ✓');
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) _closeActivity();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _feedback = 'Could not mark done.';
        });
      }
    }
  }

  Future<void> _snooze() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      _restoreAccount();
      final newDue = DateTime.now().add(const Duration(minutes: 5));
      // 1. Update Drift first — local-first
      final changed = await _db.reminderDao.updateReminder(
        RemindersCompanion(
          id: Value(widget.reminderId),
          dueAt: Value(newDue),
          isEnabled: const Value(true),
        ),
      );
      if (changed) {
        // The local row is the source of truth. Refresh visible Planner and
        // Reminder streams before doing any notification or network work.
        NotificationService.instance.onLocalActionCommitted?.call();
        // 2. Cancel current notification
        unawaited(NotificationService.instance.cancelReminder(widget.notifId));
        // 3. Reschedule at new time
        final updated = await _db.reminderDao.getById(widget.reminderId);
        if (updated != null) unawaited(NotificationService.instance.scheduleReminder(updated));
        // 4. Sync in background
        unawaited(SyncService(_db).syncNow());
      }
      if (mounted) {
        setState(() => _feedback = 'Snoozed 5 min ⏰');
        await Future.delayed(const Duration(milliseconds: 700));
        if (mounted) _closeActivity();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _feedback = 'Could not snooze.';
        });
      }
    }
  }

  Future<void> _dismiss() async {
    if (_busy) return;
    setState(() => _busy = true);
    // Cancel notification only — reminder stays enabled for future scheduling
    await NotificationService.instance.cancelReminder(widget.notifId);
    _closeActivity();
  }

  void _closeActivity() {
    // Pop back to whatever was below, or close the activity entirely if this
    // is the root route of DimiReminderActivity.
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      // DimiReminderActivity is a standalone task — finish it.
      SystemNavigator.pop();
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Warm cream background — fills entire screen including under status bar
      backgroundColor: const Color(0xFFFAF3EB),
      body: FadeTransition(
        opacity: _entranceFade,
        child: SlideTransition(
          position: _entranceSlide,
          child: SafeArea(child: _buildContent()),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final timeStr = DateFormat('h:mm a').format(widget.scheduledTime);

    return Column(
      children: [
        // ── Top: DIMI logo + "DIMI REMINDER" label ─────────────────────────
        const SizedBox(height: 28),
        _DimiLogoLabel(),

        const SizedBox(height: 32),

        // ── Reminder title ─────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            widget.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1C1C1E),
              height: 1.2,
            ),
          ),
        ),

        const SizedBox(height: 8),

        // ── Reminder body / description ────────────────────────────────────
        if (widget.body.isNotEmpty && widget.body != widget.title)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              widget.body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF8A8A8E),
                height: 1.45,
              ),
            ),
          ),

        const SizedBox(height: 16),

        // ── Time display ───────────────────────────────────────────────────
        Text(
          timeStr,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: Color(0xFFF5A623),
            letterSpacing: 1,
          ),
        ),

        const SizedBox(height: 32),

        // ── Animated bell with glow ────────────────────────────────────────
        Expanded(
          child: Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_bellCtrl, _glowCtrl]),
              builder: (context, _) => _GlowingBell(
                ringAngle: _bellRing.value,
                glowOpacity: _glowPulse.value,
              ),
            ),
          ),
        ),

        // ── Motivational tagline ───────────────────────────────────────────
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Stay consistent.\nSmall steps make big progress.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Color(0xFF8A8A8E),
              height: 1.6,
            ),
          ),
        ),

        const SizedBox(height: 32),

        // ── Feedback chip (shows briefly after action) ─────────────────────
        if (_feedback != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5A623).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              _feedback!,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFFF5A623),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ── Action buttons ─────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: Column(
            children: [
              // Mark Done — filled dark pill
              _ReminderButton(
                label: 'Mark Done',
                icon: Icons.check_circle_rounded,
                filled: true,
                onPressed: _busy ? null : _markDone,
              ),
              const SizedBox(height: 12),
              // Snooze — outlined amber pill
              _ReminderButton(
                label: 'Snooze 5 min',
                icon: Icons.access_time_rounded,
                filled: false,
                onPressed: _busy ? null : _snooze,
              ),
              const SizedBox(height: 20),
              // Dismiss — text link
              GestureDetector(
                onTap: _busy ? null : _dismiss,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Dismiss',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _busy
                          ? const Color(0xFF8A8A8E).withValues(alpha: 0.5)
                          : const Color(0xFF8A8A8E),
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DIMI logo + label at the top
// ─────────────────────────────────────────────────────────────────────────────

class _DimiLogoLabel extends StatelessWidget {
  const _DimiLogoLabel();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Rounded square badge with DIMI orange "D" logo
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8EE),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF5A623).withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/logos/dimi_splash_logo.png',
              width: 56,
              height: 56,
              fit: BoxFit.contain,
              // Graceful fallback if asset is missing
              errorBuilder: (_, _, _) => const Icon(
                Icons.notifications_active_rounded,
                color: Color(0xFFF5A623),
                size: 28,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'DIMI REMINDER',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF8A8A8E),
            letterSpacing: 2.5,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Glowing animated bell
// ─────────────────────────────────────────────────────────────────────────────

class _GlowingBell extends StatelessWidget {
  const _GlowingBell({required this.ringAngle, required this.glowOpacity});

  final double ringAngle; // radians, bell rock angle
  final double glowOpacity; // 0.3 → 0.7 pulsing

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring (largest, most transparent)
          Opacity(
            opacity: glowOpacity * 0.35,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF5A623).withValues(alpha: 0.15),
              ),
            ),
          ),

          // Middle glow ring
          Opacity(
            opacity: glowOpacity * 0.55,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF5A623).withValues(alpha: 0.18),
              ),
            ),
          ),

          // Inner white circle (card-like)
          Container(
            width: 118,
            height: 118,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF5A623).withValues(alpha: 0.22),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),

          // Bell icon — rocks left-right
          Transform.rotate(angle: ringAngle, child: const _BellIcon()),

          // Sound wave dots top-left and top-right of bell
          ..._buildSoundWaves(ringAngle),
        ],
      ),
    );
  }

  /// Three small arc dots either side of the bell to indicate ringing.
  List<Widget> _buildSoundWaves(double angle) {
    final waveColor = const Color(0xFFF5A623).withValues(alpha: 0.7);
    return [
      // Left arc dot
      Positioned(
        left: 34,
        top: 58,
        child: Transform.rotate(
          angle: angle * 1.5,
          child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(shape: BoxShape.circle, color: waveColor),
          ),
        ),
      ),
      // Right arc dot
      Positioned(
        right: 34,
        top: 58,
        child: Transform.rotate(
          angle: -angle * 1.5,
          child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(shape: BoxShape.circle, color: waveColor),
          ),
        ),
      ),
    ];
  }
}

class _BellIcon extends StatelessWidget {
  const _BellIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(52, 52), painter: _BellPainter());
  }
}

/// Hand-painted bell shape in DIMI amber to match the reference design.
class _BellPainter extends CustomPainter {
  static const _amber = Color(0xFFF5A623);
  static const _amberDark = Color(0xFFD4861A);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final fillPaint = Paint()
      ..color = _amber
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = _amberDark.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    // Bell body path
    final body = Path()
      ..moveTo(w * 0.50, h * 0.05)
      ..cubicTo(w * 0.28, h * 0.05, w * 0.15, h * 0.20, w * 0.15, h * 0.42)
      ..lineTo(w * 0.08, h * 0.75)
      ..quadraticBezierTo(w * 0.06, h * 0.82, w * 0.14, h * 0.82)
      ..lineTo(w * 0.86, h * 0.82)
      ..quadraticBezierTo(w * 0.94, h * 0.82, w * 0.92, h * 0.75)
      ..lineTo(w * 0.85, h * 0.42)
      ..cubicTo(w * 0.85, h * 0.20, w * 0.72, h * 0.05, w * 0.50, h * 0.05)
      ..close();

    // Shadow bottom of bell
    final shadow = Path()
      ..moveTo(w * 0.08, h * 0.73)
      ..lineTo(w * 0.92, h * 0.73)
      ..lineTo(w * 0.92, h * 0.82)
      ..lineTo(w * 0.08, h * 0.82)
      ..close();

    canvas.drawPath(body, fillPaint);
    canvas.drawPath(shadow, shadowPaint);

    // Clapper (small circle at bottom centre)
    canvas.drawCircle(Offset(w * 0.50, h * 0.90), w * 0.09, fillPaint);

    // Handle (small arc at top centre)
    final handlePaint = Paint()
      ..color = _amberDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.07
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.08),
        width: w * 0.22,
        height: h * 0.16,
      ),
      math.pi,
      math.pi,
      false,
      handlePaint,
    );
  }

  @override
  bool shouldRepaint(_BellPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Action button
// ─────────────────────────────────────────────────────────────────────────────

class _ReminderButton extends StatefulWidget {
  const _ReminderButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback? onPressed;

  @override
  State<_ReminderButton> createState() => _ReminderButtonState();
}

class _ReminderButtonState extends State<_ReminderButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _press, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  void _down(_) {
    if (widget.onPressed != null) _press.forward();
  }

  void _up(_) {
    _press.reverse().then((_) => widget.onPressed?.call());
  }

  void _cancel() => _press.reverse();

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final amber = const Color(0xFFF5A623);

    return GestureDetector(
      onTapDown: enabled ? _down : null,
      onTapUp: enabled ? _up : null,
      onTapCancel: _cancel,
      child: AnimatedBuilder(
        animation: _press,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: widget.filled
                ? (enabled ? const Color(0xFF1C1C1E) : const Color(0xFF8A8A8E))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(28),
            border: widget.filled
                ? null
                : Border.all(
                    color: enabled ? amber : amber.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 20,
                color: widget.filled
                    ? Colors.white
                    : (enabled ? amber : amber.withValues(alpha: 0.4)),
              ),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: widget.filled
                      ? Colors.white
                      : (enabled ? amber : amber.withValues(alpha: 0.4)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
