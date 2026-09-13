import 'package:fl_chart/fl_chart.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'dart:io';

import '../../data/database.dart';
import '../../core/widgets/dimi_fade_slide.dart';
import '../../core/motion/dimi_motion.dart';
import '../../providers/money_providers.dart';
import '../../providers/profile_providers.dart';
import '../../providers/reminder_providers.dart';
import '../../providers/task_providers.dart';
import '../../routing/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/section_card.dart';
import '../../widgets_modals/add_expense_sheet.dart';
import '../../utils/time_format.dart';
import '../../widgets_modals/add_reminder_sheet.dart';
import '../../widgets_modals/add_task_sheet.dart';
import '../../widgets/dimi_activity_heatmap.dart';
import '../../widgets/youtube_playlist_card.dart';

final _currencyFmt = NumberFormat('#,##0', 'en_IN');

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final plannerEntriesAsync = ref.watch(allPlannerEntriesProvider);
    final upcomingRemindersAsync = ref.watch(upcomingRemindersProvider);

    final fullName = profileAsync.valueOrNull?.name ?? 'Student';
    final name = fullName.trim().split(RegExp(r'\s+')).first;
    const homeCardInset = 12.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── App bar + greeting hero (no card, bleeds into bg) ─────
            SliverToBoxAdapter(
              child: DimiFadeSlide(
                child: _GreetingHero(
                  name: name,
                  profileAsync: profileAsync,
                  onNotificationTap: () => context.go(AppRoutes.reminders),
                  onProfileTap: () => context.push(AppRoutes.profile),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // ── YouTube playlist card (replaces dark stats card) ───────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: homeCardInset,
                ),
                child: DimiFadeSlide(
                  delay: const Duration(milliseconds: 45),
                  child: const YoutubePlaylistCard(),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // ── Today's tasks ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: homeCardInset,
                ),
                child: DimiFadeSlide(
                  delay: const Duration(milliseconds: 90),
                  child: const _HomeContentGrid(),
                ) /*
                child: todaysTasksAsync.when(
                  data: (t) => plannerTasksAsync.when(
                    data: (plannerTasks) => Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _TodayTasksCard(tasks: t, compact: true),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _PlannerPreviewCard(
                            tasks: plannerTasks,
                            compact: true,
                          ),
                        ),
                      ],
                    ),
                    loading: () => const _Shimmer(height: 280),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                  loading: () => const _Shimmer(height: 280),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // ── Weekly spending ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: homeCardInset,
                ),
                child: allTxnAsync.when(
                  data: (all) => weeklyTxnAsync.when(
                    data: (weekly) => Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _SpendingCard(
                            transactions: weekly,
                            compact: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _BalanceCard(transactions: all, compact: true),
                        ),
                      ],
                    ),
                    loading: () => const _Shimmer(height: 190),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                  loading: () => const _Shimmer(height: 190),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ),
            ),
            */,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // ── Upcoming reminders ─────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: homeCardInset,
                ),
                child: upcomingRemindersAsync.when(
                  data: (r) => _RemindersCard(reminders: r),
                  loading: () => const _Shimmer(height: 90),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // Adaptive GitHub-style completion history.
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: homeCardInset,
                ),
                child: plannerEntriesAsync.when(
                  data: (tasks) => _HomeHeatmapCard(tasks: tasks),
                  loading: () => const _Shimmer(height: 155),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
          ],
        ),
      ),
    );
  }
}

class _HomeHeatmapCard extends StatelessWidget {
  const _HomeHeatmapCard({required this.tasks});
  final List<Task> tasks;

  @override
  Widget build(BuildContext context) {
    return DimiActivityHeatmap(
      tasks: tasks,
      title: 'Completion rhythm',
      subtitle: 'Activity over the last year',
    );
    /*
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bar_chart_rounded, size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Completion Heatmap',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Your planning rhythm at a glance',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '$average%',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const SizedBox(width: 29),
              Expanded(
                child: Row(
                  children: List.generate(
                    weekCount,
                    (week) => Expanded(
                      child: Text(
                        days[week * 7].day <= 7
                            ? DateFormat('MMM').format(days[week * 7])
                            : '',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 8,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                width: 24,
                height: 86,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text('Mon', style: _homeHeatmapLabelStyle),
                    Text('Wed', style: _homeHeatmapLabelStyle),
                    Text('Fri', style: _homeHeatmapLabelStyle),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: SizedBox(
                  height: 86,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: weekCount,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                    ),
                    itemCount: days.length,
                    itemBuilder: (_, index) {
                      final day = days[(index % 7) * weekCount + index ~/ 7];
                      final total = totals[day] ?? 0;
                      final ratio = total == 0
                          ? 0.0
                          : (completed[day] ?? 0) / total;
                      return AnimatedContainer(
                        duration: DimiMotion.normal,
                        curve: DimiMotion.curve,
                        decoration: BoxDecoration(
                          color: _homeHeatColor(ratio, total, day.isAfter(today)),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('Less', style: _homeHeatmapLabelStyle),
              const SizedBox(width: 5),
              ...[0.0, .25, .5, .75, 1.0].map(
                (ratio) => Padding(
                  padding: const EdgeInsets.only(left: 3),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _homeHeatColor(ratio, 1, false),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 5),
              const Text('More', style: _homeHeatmapLabelStyle),
            ],
          ),
        ],
      ),
    ); */
  }
}

// ignore: unused_element
const _homeHeatmapLabelStyle = TextStyle(
  fontFamily: 'Poppins',
  fontSize: 9,
  color: AppColors.textSecondary,
);

// ignore: unused_element
DateTime _homeDateOnly(DateTime date) =>
    DateTime(date.year, date.month, date.day);

// ignore: unused_element
Color _homeHeatColor(double ratio, int total, bool future) {
  if (future || total == 0 || ratio == 0) return AppColors.accentSoft;
  if (ratio < .25) return AppColors.accent.withAlpha(70);
  if (ratio < .5) return AppColors.accent.withAlpha(120);
  if (ratio < .75) return AppColors.accent.withAlpha(180);
  return AppColors.accent;
}

class _HomeContentGrid extends ConsumerWidget {
  const _HomeContentGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final tasks = ref.watch(todaysTasksProvider);
    final planner = ref.watch(
      tasksForDateProvider(DateTime(now.year, now.month, now.day)),
    );
    final weekly = ref.watch(thisWeeksTransactionsProvider);
    final all = ref.watch(allTransactionsProvider);

    return tasks.when(
      data: (taskItems) => planner.when(
        data: (plannerItems) => weekly.when(
          data: (weeklyItems) => all.when(
            data: (allItems) => _AdaptiveMasonry(
              children: [
                _TodayTasksCard(tasks: taskItems, compact: true),
                _PlannerPreviewCard(tasks: plannerItems, compact: true),
                _SpendingCard(transactions: weeklyItems, compact: true),
                _BalanceCard(transactions: allItems, compact: true),
              ],
            ),
            loading: () => const _Shimmer(height: 220),
            error: (_, _) => const SizedBox.shrink(),
          ),
          loading: () => const _Shimmer(height: 220),
          error: (_, _) => const SizedBox.shrink(),
        ),
        loading: () => const _Shimmer(height: 280),
        error: (_, _) => const SizedBox.shrink(),
      ),
      loading: () => const _Shimmer(height: 280),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

/// Places cards in stable priority order, always assigning the next card to
/// the column with the least accumulated height. Children are laid out first,
/// so their real content height drives placement without fixed-height guesses.
class _AdaptiveMasonry extends MultiChildRenderObjectWidget {
  const _AdaptiveMasonry({required super.children});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderAdaptiveMasonry();
  }
}

class _MasonryParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderAdaptiveMasonry extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _MasonryParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _MasonryParentData> {
  static const double _gap = 8;
  static const double _singleColumnBreakpoint = 320;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _MasonryParentData) {
      child.parentData = _MasonryParentData();
    }
  }

  @override
  void performLayout() {
    final width = constraints.maxWidth;
    final columnCount = width < _singleColumnBreakpoint ? 1 : 2;
    final columnWidth = columnCount == 1 ? width : (width - _gap) / 2;
    final heights = List<double>.filled(columnCount, 0);

    RenderBox? child = firstChild;
    while (child != null) {
      child.layout(
        BoxConstraints.tightFor(width: columnWidth),
        parentUsesSize: true,
      );

      var targetColumn = 0;
      for (var i = 1; i < heights.length; i++) {
        if (heights[i] < heights[targetColumn]) targetColumn = i;
      }

      final parentData = child.parentData! as _MasonryParentData;
      parentData.offset = Offset(
        targetColumn == 0 ? 0 : columnWidth + _gap,
        heights[targetColumn],
      );
      heights[targetColumn] += child.size.height + _gap;
      child = parentData.nextSibling;
    }

    final contentHeight = heights.isEmpty
        ? 0.0
        : heights.reduce((a, b) => a > b ? a : b) - _gap;
    size = constraints.constrain(Size(width, contentHeight));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }
}

// ── Unified greeting hero — no card, bleeds into app background ──────────────

class _GreetingHero extends StatelessWidget {
  const _GreetingHero({
    required this.name,
    required this.profileAsync,
    required this.onNotificationTap,
    required this.onProfileTap,
  });

  final String name;
  final AsyncValue<dynamic> profileAsync;
  final VoidCallback onNotificationTap;
  final VoidCallback onProfileTap;

  static String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning,';
    if (h < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  static String _tagline() {
    final h = DateTime.now().hour;
    if (h < 12) return '"Discipline today,\na better tomorrow."';
    if (h < 17) return 'Keep the momentum going.';
    return 'You showed up. That matters.';
  }

  @override
  Widget build(BuildContext context) {
    final photoPath = profileAsync.valueOrNull?.photoPath as String?;
    final initials = name.isEmpty ? 'DM' : name[0].toUpperCase();

    // The image zone starts below the DIMI title (~72px from top)
    // and extends to the bottom of the hero area.
    const double imageTopOffset = 72.0;
    const double totalHeight = 260.0;

    return SizedBox(
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Artwork — starts below the title row ──────────────────────
          Positioned(
            top: imageTopOffset,
            left: 0,
            right: 0,
            bottom: 0,
            child: Image.asset(
              'assets/Greeting/GreetingsBG.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              opacity: const AlwaysStoppedAnimation(0.75),
            ),
          ),

          // ── Top fade: bg colour → transparent (hides hard image edge) ─
          Positioned(
            top: imageTopOffset,
            left: 0,
            right: 0,
            height: 60,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.background,
                    AppColors.background.withAlpha(0),
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom fade: transparent → bg colour (melts into next card) ─
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 80,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.background.withAlpha(0),
                    AppColors.background,
                  ],
                ),
              ),
            ),
          ),

          // ── Left fade: keeps text legible over the artwork ────────────
          Positioned(
            top: imageTopOffset,
            left: 0,
            bottom: 0,
            width: 220,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    AppColors.background,
                    AppColors.background.withAlpha(180),
                    AppColors.background.withAlpha(0),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),

          // ── DIMI title + action buttons ───────────────────────────────
          Positioned(
            top: 20,
            left: AppSpacing.screenHorizontal,
            right: AppSpacing.screenHorizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DIMI',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 28,
                          height: 1,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: 1.5,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Plan  ·  Track  ·  Grow',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _HomeHeaderButton(
                      icon: Icons.notifications_none_rounded,
                      onTap: onNotificationTap,
                    ),
                    Positioned(
                      right: 7,
                      top: 6,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onProfileTap,
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.surfaceDark,
                    backgroundImage: photoPath == null
                        ? null
                        : FileImage(File(photoPath)),
                    child: Text(
                      photoPath == null ? initials : '',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.surface,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Greeting text — lower left ────────────────────────────────
          Positioned(
            bottom: 32,
            left: AppSpacing.screenHorizontal,
            right: 160,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _greeting(),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('👋', style: TextStyle(fontSize: 22)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _tagline(),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick actions ─────────────────────────────────────────────────────────────

// Retained for reuse on another dashboard surface; the Home screen now uses
// inline actions inside each data card.
// ignore: unused_element
class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QATile(
            icon: Icons.check_rounded,
            label: 'Task',
            subtitle: 'Stay on track',
            color: AppColors.accent,
            onTap: () => showAddTaskSheet(context),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QATile(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Expense',
            subtitle: 'Track spending',
            color: AppColors.danger,
            onTap: () => showAddExpenseSheet(context),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QATile(
            icon: Icons.notifications_outlined,
            label: 'Reminder',
            subtitle: 'Never forget',
            color: AppColors.success,
            onTap: () => showAddReminderSheet(context),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QATile(
            icon: Icons.calendar_today_outlined,
            label: 'Planner',
            subtitle: 'Plan your day',
            color: AppColors.info,
            onTap: () => context.go(AppRoutes.planner),
          ),
        ),
      ],
    );
  }
}

class _QATile extends StatelessWidget {
  const _QATile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.subtitle,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 132,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 21, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 8,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Today's tasks card ────────────────────────────────────────────────────────

class _HomeCardHeader extends StatelessWidget {
  const _HomeCardHeader({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final header = Row(
      children: [
        Container(
          width: compact ? 24 : 30,
          height: compact ? 24 : 30,
          decoration: BoxDecoration(
            color: AppColors.accentSoft,
            borderRadius: BorderRadius.circular(compact ? 8 : 10),
          ),
          child: Icon(icon, size: compact ? 14 : 17, color: AppColors.accent),
        ),
        SizedBox(width: compact ? 6 : 8),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: compact ? 11 : 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        ?trailing,
      ],
    );

    return onTap == null
        ? header
        : InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: header,
          );
  }
}

Future<void> _showHomeQuickTaskComposer(
  BuildContext context,
  WidgetRef ref,
) async {
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Add a new task',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 70),
    pageBuilder: (_, __, ___) => _HomeQuickTaskComposer(ref: ref),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(opacity: curved, child: child);
    },
  );
}

class _HomeQuickTaskComposer extends StatefulWidget {
  const _HomeQuickTaskComposer({required this.ref});

  final WidgetRef ref;

  @override
  State<_HomeQuickTaskComposer> createState() =>
      _HomeQuickTaskComposerState();
}

class _HomeQuickTaskComposerState extends State<_HomeQuickTaskComposer> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _saving = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _controller.text.trim();
    if (title.isEmpty || _saving) return;

    setState(() => _saving = true);
    final now = DateTime.now();
    await widget.ref.read(taskDaoProvider).insertTask(
      TasksCompanion(
        title: Value(title),
        description: const Value(null),
        category: const Value('Personal'),
        dueDate: Value(now),
        dueTime: const Value(null),
        reminderMinutesBefore: const Value(null),
        isCompleted: const Value(false),
        isPlannerEntry: const Value(false),
        createdAt: Value(now),
      ),
    );

    if (!mounted) return;
    setState(() {
      _saving = false;
      _saved = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 160));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: ColoredBox(color: Color(0x661C1C1E)),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(18, 18, 18, bottomInset + 86),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 520),
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x261C1C1E),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.accentSoft,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.task_alt_rounded,
                          color: AppColors.accent,
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          maxLength: 60,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _save(),
                          decoration: const InputDecoration(
                            hintText: "What's your task?",
                            counterText: '',
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 10,
                            ),
                          ),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _saving || _saved ? null : _save,
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.surface,
                          fixedSize: const Size(42, 42),
                        ),
                        icon: _saved
                            ? const Icon(Icons.check_rounded, size: 21)
                            : _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.surface,
                                ),
                              )
                            : const Icon(Icons.send_rounded, size: 19),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayTasksCard extends ConsumerWidget {
  const _TodayTasksCard({required this.tasks, this.compact = false});
  final List<Task> tasks;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dao = ref.read(taskDaoProvider);
    final done = tasks.where((t) => t.isCompleted).length;

    return SectionCard(
      padding: EdgeInsets.all(compact ? 8 : AppSpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HomeCardHeader(
            icon: Icons.check_circle_outline_rounded,
            title: "Today's Tasks",
            compact: compact,
            onTap: () => context.go(AppRoutes.planner),
            trailing: Text(
              '$done/${tasks.length} done',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: compact ? 8 : 11,
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (tasks.isEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'All clear today 🎉',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            ...tasks.map(
              (t) => _MiniTaskRow(task: t, dao: dao, compact: compact),
            ),
          ],
          const SizedBox(height: 3),
          GestureDetector(
            onTap: () => _showHomeQuickTaskComposer(context, ref),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 8 : 14,
                vertical: compact ? 8 : 12,
              ),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.add_rounded,
                    size: compact ? 16 : 20,
                    color: AppColors.textPrimary,
                  ),
                  SizedBox(width: compact ? 6 : 10),
                  Text(
                    'Add a new task',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: compact ? 9 : 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniTaskRow extends StatelessWidget {
  const _MiniTaskRow({
    required this.task,
    required this.dao,
    this.compact = false,
  });
  final Task task;
  final dynamic dao;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 5 : 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => dao.toggleCompleted(task.id, !task.isCompleted),
            child: AnimatedContainer(
              duration: DimiMotion.fast,
              curve: DimiMotion.curve,
              width: compact ? 16 : 20,
              height: compact ? 16 : 20,
              decoration: BoxDecoration(
                color: task.isCompleted ? AppColors.accent : Colors.transparent,
                border: Border.all(
                  color: task.isCompleted
                      ? AppColors.accent
                      : AppColors.textSecondary,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: AnimatedSwitcher(
                duration: DimiMotion.fast,
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: task.isCompleted
                    ? const Icon(
                        Icons.check_rounded,
                        key: ValueKey('home-mini-done'),
                        size: 12,
                        color: AppColors.surface,
                      )
                    : const SizedBox(key: ValueKey('home-mini-pending')),
              ),
            ),
          ),
          SizedBox(width: compact ? 5 : 10),
          Expanded(
            child: Text(
              task.title,
              maxLines: compact ? 2 : null,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: compact ? 10 : 13,
                color: task.isCompleted
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
                decoration: task.isCompleted
                    ? TextDecoration.lineThrough
                    : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!compact && task.dueTime != null)
            Text(
              formatTime12Hour(task.dueTime),
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Weekly spending card ──────────────────────────────────────────────────────

class _PlannerPreviewCard extends StatelessWidget {
  const _PlannerPreviewCard({required this.tasks, this.compact = false});
  final List<Task> tasks;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final sorted = [...tasks]
      ..sort((a, b) {
        if (compact && a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }
        return (a.dueTime ?? '99:99').compareTo(b.dueTime ?? '99:99');
      });
    return SectionCard(
      padding: EdgeInsets.all(compact ? 8 : AppSpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: compact ? 24 : 30,
                height: compact ? 24 : 30,
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(compact ? 8 : 10),
                ),
                child: Icon(
                  Icons.calendar_today_outlined,
                  size: compact ? 14 : 17,
                  color: AppColors.accent,
                ),
              ),
              SizedBox(width: compact ? 6 : 8),
              Expanded(
                child: Text(
                  'Today · ${DateFormat('d MMM').format(DateTime.now())}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: compact ? 11 : 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (sorted.isEmpty)
            Text(
              'Nothing planned today',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: compact ? 9 : 11,
                color: AppColors.textSecondary,
              ),
            )
          else
            ...sorted.map(
              (task) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: compact ? 31 : 52,
                      child: Text(
                        formatTime12Hour(task.dueTime),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: compact ? 8 : 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    SizedBox(width: compact ? 3 : 8),
                    Container(
                      width: 3,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _plannerColor(task.category),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    SizedBox(width: compact ? 3 : 8),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: compact ? 6 : 9,
                          vertical: compact ? 5 : 7,
                        ),
                        decoration: BoxDecoration(
                          color: _plannerColor(task.category).withAlpha(22),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          task.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: compact ? 9 : 11,
                            fontWeight: FontWeight.w500,
                            color: task.isCompleted
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => context.go(AppRoutes.planner),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text(
                  'Open Planner  ›',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _plannerColor(String category) => switch (category.toLowerCase()) {
    'college' => const Color(0xFF4A90D9),
    'study' => AppColors.accent,
    'health' => AppColors.danger,
    'personal' => AppColors.success,
    _ => AppColors.textSecondary,
  };
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.transactions, this.compact = false});
  final List<MoneyTransaction> transactions;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final expenses = transactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);
    final income = transactions
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);
    final loans = transactions
        .where((t) => t.type == 'loan')
        .fold(0.0, (sum, t) => sum + t.amount);
    final balance = income - expenses;

    return SectionCard(
      padding: EdgeInsets.all(compact ? 8 : AppSpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => context.go(AppRoutes.money),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Container(
                    width: compact ? 24 : 30,
                    height: compact ? 24 : 30,
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft,
                      borderRadius: BorderRadius.circular(compact ? 8 : 10),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_outlined,
                      size: compact ? 14 : 17,
                      color: AppColors.accent,
                    ),
                  ),
                  SizedBox(width: compact ? 4 : 8),
                  Expanded(
                    child: Text(
                      'Current Balance',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: compact ? 11 : 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: compact ? 15 : 18),
                ],
              ),
            ),
          ),
          SizedBox(height: compact ? 5 : 8),
          Text(
            '₹${_currencyFmt.format(balance)}',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: compact ? 17 : 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: compact ? 10 : 14),
          Row(
            children: [
              Expanded(
                child: _BalanceMetric(
                  value: '₹${_currencyFmt.format(expenses)}',
                  label: 'Total Expenses',
                  color: AppColors.success,
                  compact: compact,
                ),
              ),
              SizedBox(width: compact ? 5 : 8),
              Expanded(
                child: _BalanceMetric(
                  value: '₹${_currencyFmt.format(loans)}',
                  label: 'Loans',
                  color: AppColors.danger,
                  compact: compact,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceMetric extends StatelessWidget {
  const _BalanceMetric({
    required this.value,
    required this.label,
    required this.color,
    this.compact = false,
  });
  final String value;
  final String label;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(compact ? 6 : 9),
    decoration: BoxDecoration(
      color: color.withAlpha(24),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: compact ? 10 : 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 9,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    ),
  );
}

class _SpendingCard extends StatelessWidget {
  const _SpendingCard({required this.transactions, this.compact = false});
  final List<MoneyTransaction> transactions;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    // Build per-weekday buckets (0=Mon … 6=Sun)
    final dayAmounts = List.filled(7, 0.0);
    for (final t in transactions) {
      if (t.type == 'expense') {
        // weekday: 1=Mon … 7=Sun → index 0–6
        dayAmounts[t.date.weekday - 1] += t.amount;
      }
    }
    final maxAmt = dayAmounts.reduce((a, b) => a > b ? a : b);
    final todayIdx = DateTime.now().weekday - 1;
    final totalSpent = dayAmounts.fold(0.0, (a, b) => a + b);
    final todaySpent = transactions
        .where(
          (t) =>
              t.type == 'expense' &&
              t.date.year == DateTime.now().year &&
              t.date.month == DateTime.now().month &&
              t.date.day == DateTime.now().day,
        )
        .fold(0.0, (sum, t) => sum + t.amount);
    final weeklyIncome = transactions
        .where((t) => t.type == 'income')
        .fold(0.0, (s, t) => s + t.amount);

    return SectionCard(
      padding: EdgeInsets.all(compact ? 8 : AppSpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: compact ? 24 : 30,
                height: compact ? 24 : 30,
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(compact ? 8 : 10),
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  size: compact ? 14 : 17,
                  color: AppColors.accent,
                ),
              ),
              SizedBox(width: compact ? 6 : 8),
              Expanded(
                child: Text(
                  'Spending',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: compact ? 11 : 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => context.go(AppRoutes.money),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 4 : 14,
                    vertical: compact ? 0 : 9,
                  ),
                  child: Text(
                    compact ? '›' : 'View All',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: compact ? 16 : 12,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 0 : 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${_currencyFmt.format(todaySpent)}',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: compact ? 20 : 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              if (!compact && weeklyIncome > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withAlpha(26),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${(todaySpent / weeklyIncome * 100).toStringAsFixed(0)}% of income',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            "This week's spending ₹${_currencyFmt.format(totalSpent)}",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: compact ? 9 : 11,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: compact ? 4 : 12),
          if (maxAmt <= 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  'No spending recorded this week',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: compact ? 54 : 90,
              child: _HomeBarChart(
                dayAmounts: dayAmounts,
                maxAmt: maxAmt,
                todayIdx: todayIdx,
                compact: compact,
              ),
            ),
        ],
      ),
    );
  }
}

class _HomeBarChart extends StatelessWidget {
  const _HomeBarChart({
    required this.dayAmounts,
    required this.maxAmt,
    required this.todayIdx,
    this.compact = false,
  });
  final List<double> dayAmounts;
  final double maxAmt;
  final int todayIdx;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxAmt * 1.35,
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
                      fontSize: compact ? 8 : 10,
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
          final amt = dayAmounts[i];
          final isToday = i == todayIdx;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: amt <= 0 ? 1 : amt,
                color: isToday ? AppColors.accent : AppColors.accentSoft,
                width: compact ? 7 : 14,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(5),
                ),
              ),
            ],
            showingTooltipIndicators: const [],
          );
        }),
        barTouchData: BarTouchData(
          enabled: true,
          handleBuiltInTouches: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final amount = dayAmounts[group.x.toInt()];
              return BarTooltipItem(
                '₹${_currencyFmt.format(amount)}',
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

// ── Upcoming reminders card ───────────────────────────────────────────────────

class _RemindersCard extends StatelessWidget {
  const _RemindersCard({required this.reminders});
  final List<Reminder> reminders;

  @override
  Widget build(BuildContext context) {
    final upcoming = reminders
        .where((r) => r.isEnabled && r.dueAt.isAfter(DateTime.now()))
        .take(3)
        .toList();

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Upcoming Reminders',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              GestureDetector(
                onTap: () => context.go(AppRoutes.reminders),
                child: const Text(
                  'View All',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
          if (upcoming.isEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'No upcoming reminders',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            ...upcoming.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_active_outlined,
                        size: 16,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        r.title,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      DateFormat('d MMM · h:mm a').format(r.dueAt),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _HomeHeaderButton extends StatelessWidget {
  const _HomeHeaderButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.divider),
        ),
        child: Icon(icon, size: 22, color: AppColors.textPrimary),
      ),
    );
  }
}

class _Shimmer extends StatelessWidget {
  const _Shimmer({required this.height});
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
