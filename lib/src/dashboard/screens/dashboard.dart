import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../body/providers/body_metrics.dart';
import '../../body/screens/body_metric_dialog.dart';
import '../../diet/providers/calories.dart';
import '../../diet/providers/meals.dart';
import '../../diet/screens/ingredient_form.dart';
import '../../diet/screens/meal_form.dart';
import '../../exercise/providers/workouts.dart';
import '../../exercise/screens/workout_form.dart';
import '../../models/body_metrics_entry.dart';
import '../../models/body_weight_goal.dart';
import '../../models/task.dart';
import '../../models/units.dart';
import '../../planner/screens/planner_item_detail.dart';
import '../../models/workout.dart';
import '../../settings/providers/settings.dart';
import '../../ui/date_formats.dart';
import '../../ui/units.dart';
import '../../ui/theme_extensions.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets/metric_card.dart';
import '../../ui/widgets/status_badge.dart';
import '../providers/dashboard.dart';

final class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final mealsAsync = ref.watch(mealListProvider);
    final workoutsAsync = ref.watch(workoutListProvider);

    // First-run state: the welcome hub replaces the data cards when there
    // is no meal and no workout at all.
    final hasNoData =
        (mealsAsync.value?.isEmpty ?? false) &&
        (workoutsAsync.value?.isEmpty ?? false);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dashboardAppBar),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: l10n.settingsAppBar,
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(FitFatTokens.spaceL),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: FitFatTokens.kContentMaxWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _GreetingHeader(now: DateTime.now()),
                  const SizedBox(height: FitFatTokens.spaceL),
                  if (hasNoData)
                    const _WelcomeHub()
                  else ...[
                    const _CalorieRingCard(),
                    const SizedBox(height: FitFatTokens.spaceL),
                    const _MacroTargetsCard(),
                    const SizedBox(height: FitFatTokens.spaceL),
                    const _WeightTrendCard(),
                    const SizedBox(height: FitFatTokens.spaceL),
                    const _WeeklyWorkoutCard(),
                    const SizedBox(height: FitFatTokens.spaceL),
                    const _UpcomingTasksCard(),
                    const SizedBox(height: FitFatTokens.spaceL),
                    const _LatestWorkoutCard(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Time-based greeting (morning / afternoon / evening) + the locale-aware
/// current date.
final class _GreetingHeader extends StatelessWidget {
  final DateTime now;

  const _GreetingHeader({required this.now});

  String _greeting(AppLocalizations l10n) {
    final hour = now.hour;
    if (hour < 12) return l10n.dashboardGreetingMorning;
    if (hour < 18) return l10n.dashboardGreetingAfternoon;
    return l10n.dashboardGreetingEvening;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _greeting(l10n),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: FitFatTokens.spaceXs),
        Text(
          DateFormats.formatDate(context, now),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Hero card: calorie progress ring (consumed vs target + remaining). Hidden
/// until the target can be computed (age/gender/weight/height all present).
final class _CalorieRingCard extends ConsumerWidget {
  const _CalorieRingCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final consumedAsync = ref.watch(todayCaloriesProvider);
    final targetAsync = ref.watch(calorieTargetProvider);

    return targetAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => Text(l10n.dashboardError('$e')),
      data: (target) {
        // Hidden until age/gender/weight/height are present.
        if (target == null) return const SizedBox.shrink();
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(FitFatTokens.spaceL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: FitFatTokens.spaceS),
                    Text(
                      l10n.dashboardCalorieTarget,
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: FitFatTokens.spaceM),
                consumedAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text(l10n.dashboardError('$e')),
                  data: (consumed) =>
                      _CalorieRing(consumed: consumed, target: target),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

final class _CalorieRing extends StatelessWidget {
  final double consumed;
  final double target;

  const _CalorieRing({required this.consumed, required this.target});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final remaining = math.max(0.0, target - consumed);
    final progress = (consumed / target).clamp(0.0, 1.0);

    return Column(
      children: [
        SizedBox(
          height: 180,
          width: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 180,
                height: 180,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 14,
                  strokeCap: StrokeCap.round,
                  backgroundColor: scheme.surfaceContainerHighest,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.dashboardRemaining,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: FitFatTokens.spaceXs),
                  Text(
                    '${remaining.toStringAsFixed(0)} kcal',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: FitFatTokens.spaceM),
        Text(
          l10n.dashboardConsumedOfTarget(
            consumed.toStringAsFixed(0),
            target.toStringAsFixed(0),
          ),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        if (consumed > target) ...[
          const SizedBox(height: FitFatTokens.spaceXs),
          Text(
            l10n.dashboardOverTarget((consumed - target).toStringAsFixed(0)),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.extension<FitFatColors>()!.warning,
            ),
          ),
        ],
      ],
    );
  }
}

/// Macro-targets progress: today's P/C/F grams against the 30/40/30 targets
/// derived from the daily calorie target. Hidden while the target is unknown.
final class _MacroTargetsCard extends ConsumerWidget {
  const _MacroTargetsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final macrosAsync = ref.watch(todayMacrosProvider);
    final targetsAsync = ref.watch(macroTargetsProvider);

    return targetsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => Text(l10n.dashboardError('$e')),
      data: (targets) {
        if (targets == null) return const SizedBox.shrink();
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(FitFatTokens.spaceL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.pie_chart_outline,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: FitFatTokens.spaceS),
                    Text(
                      l10n.dashboardMacroTargets,
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: FitFatTokens.spaceM),
                macrosAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text(l10n.dashboardError('$e')),
                  data: (macros) => Column(
                    children: [
                      _MacroTargetRow(
                        label: l10n.dashboardMacroProtein,
                        color: theme.colorScheme.primary,
                        consumed: macros.protein,
                        target: targets.protein,
                      ),
                      const SizedBox(height: FitFatTokens.spaceM),
                      _MacroTargetRow(
                        label: l10n.dashboardMacroCarbs,
                        color: theme.colorScheme.tertiary,
                        consumed: macros.carbs,
                        target: targets.carbs,
                      ),
                      const SizedBox(height: FitFatTokens.spaceM),
                      _MacroTargetRow(
                        label: l10n.dashboardMacroFat,
                        color: theme.extension<FitFatColors>()!.warning,
                        consumed: macros.fat,
                        target: targets.fat,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// One macro's consumed-vs-target progress row (grams).
final class _MacroTargetRow extends StatelessWidget {
  final String label;
  final Color color;
  final double consumed;
  final double target;

  const _MacroTargetRow({
    required this.label,
    required this.color,
    required this.consumed,
    required this.target,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final ratio = target <= 0 ? 0.0 : (consumed / target).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
            Text(
              l10n.dashboardMacroProgress(
                consumed.toStringAsFixed(0),
                target.toStringAsFixed(0),
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: FitFatTokens.spaceXs),
        ClipRRect(
          borderRadius: BorderRadius.circular(FitFatTokens.radiusFull),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

/// Weight trend card: owns the Add weight/height buttons and shows the weight
/// evolution over time (absorbed from the removed bottom BodyMetricsCard).
final class _WeightTrendCard extends ConsumerWidget {
  const _WeightTrendCard();

  Future<void> _addWeight(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showBodyMetricDialog(
      context,
      dialogTitle: l10n.bodyMetricsDialogWeightTitle,
      valueLabel: l10n.bodyMetricsWeightLabel,
      valueSuffix: 'kg',
    );
    if (result == null || !context.mounted) return;
    final (day, value) = result;
    await ref.read(bodyMetricsRepositoryProvider).upsert(day, weightKg: value);
    _invalidate(ref);
  }

  Future<void> _addHeight(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showBodyMetricDialog(
      context,
      dialogTitle: l10n.bodyMetricsDialogHeightTitle,
      valueLabel: l10n.bodyMetricsHeightLabel,
      valueSuffix: 'cm',
    );
    if (result == null || !context.mounted) return;
    final (day, value) = result;
    await ref.read(bodyMetricsRepositoryProvider).upsert(day, heightCm: value);
    _invalidate(ref);
  }

  void _invalidate(WidgetRef ref) {
    ref.invalidate(bodyMetricsProvider);
    ref.invalidate(latestBodyMetricsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final entriesAsync = ref.watch(bodyMetricsProvider);
    final latestAsync = ref.watch(latestBodyMetricsProvider);
    final settings = ref.watch(settingsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(FitFatTokens.spaceL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.monitor_weight_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: FitFatTokens.spaceS),
                Expanded(
                  child: Text(
                    l10n.dashboardWeightTrend,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                if (settings.bodyWeightGoal != null)
                  Text(
                    l10n.bodyMetricsGoal(switch (settings.bodyWeightGoal!) {
                      BodyWeightGoal.lose => l10n.settingsGoalLose,
                      BodyWeightGoal.maintain => l10n.settingsGoalMaintain,
                      BodyWeightGoal.gain => l10n.settingsGoalGain,
                    }),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: FitFatTokens.spaceM),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _addWeight(context, ref),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.bodyMetricsAddWeight),
                  ),
                ),
                const SizedBox(width: FitFatTokens.spaceS),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _addHeight(context, ref),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.bodyMetricsAddHeight),
                  ),
                ),
              ],
            ),
            const SizedBox(height: FitFatTokens.spaceM),
            latestAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (e, _) => Text(l10n.dashboardError('$e')),
              data: (latest) {
                if (latest == null) return const SizedBox.shrink();
                final parts = <String>[
                  if (latest.weightKg != null)
                    l10n.bodyMetricsLatestWeight(
                      formatWeightValue(latest.weightKg!, settings.weightUnit),
                      weightUnitLabel(settings.weightUnit),
                    ),
                  if (latest.heightCm != null)
                    l10n.bodyMetricsLatestHeight(
                      formatLengthValue(latest.heightCm!, settings.lengthUnit),
                      lengthUnitLabel(settings.lengthUnit),
                    ),
                ];
                if (parts.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: FitFatTokens.spaceM),
                  child: Text(
                    parts.join('  ·  '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
            entriesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text(l10n.dashboardError('$e')),
              data: (entries) =>
                  _WeightEvolution(entries: entries, unit: settings.weightUnit),
            ),
          ],
        ),
      ),
    );
  }
}

/// Weight evolution over time: empty text, a single-value text, or a line
/// chart (height stays recordable via the Add button; only weight trends here).
final class _WeightEvolution extends StatelessWidget {
  final List<BodyMetricsEntry> entries;
  final WeightUnit unit;

  const _WeightEvolution({required this.entries, required this.unit});

  List<(DateTime, double)> get _points => [
    for (final entry in entries)
      if (entry.weightKg != null)
        (entry.day, weightFromKg(entry.weightKg!, unit)),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final points = _points;
    final color = theme.colorScheme.primary;

    if (points.isEmpty) {
      return Text(
        l10n.bodyMetricsEmptyWeight,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }
    if (points.length == 1) {
      return Text(
        l10n.bodyMetricsValueKg(
          formatWeightValue(entries.first.weightKg!, unit),
          weightUnitLabel(unit),
        ),
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: color,
        ),
      );
    }
    return SizedBox(height: 160, child: _WeightLineChart(points: points));
  }
}

final class _WeightLineChart extends StatelessWidget {
  final List<(DateTime, double)> points; // chronological, ≥ 2 points

  const _WeightLineChart({required this.points});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    final values = points.map((s) => s.$2).toList();
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    // Ensure a non-empty Y range even when all values are equal.
    final padding = maxValue == minValue ? 1.0 : (maxValue - minValue) * 0.2;

    return CustomPaint(
      size: Size.infinite,
      painter: _WeightLinePainter(
        points: points,
        color: color,
        gridColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        minY: minValue - padding,
        maxY: maxValue + padding,
      ),
    );
  }
}

final class _WeightLinePainter extends CustomPainter {
  final List<(DateTime, double)> points;
  final Color color;
  final Color gridColor;
  final double minY;
  final double maxY;

  const _WeightLinePainter({
    required this.points,
    required this.color,
    required this.gridColor,
    required this.minY,
    required this.maxY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final startEpoch = points.first.$1.millisecondsSinceEpoch.toDouble();
    final endEpoch = points.last.$1.millisecondsSinceEpoch.toDouble();
    final epochSpan = math.max(1.0, endEpoch - startEpoch);
    final ySpan = maxY - minY;

    Offset project(double epoch, double value) {
      final x = (epoch - startEpoch) / epochSpan * size.width;
      final y = size.height - (value - minY) / ySpan * size.height;
      return Offset(x, y);
    }

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final o = project(p.$1.millisecondsSinceEpoch.toDouble(), p.$2);
      if (i == 0) {
        path.moveTo(o.dx, o.dy);
      } else {
        path.lineTo(o.dx, o.dy);
      }
    }

    // Baseline grid: three horizontal rules.
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i <= 2; i++) {
      final y = size.height * i / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Fill under the line.
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..color = color.withValues(alpha: 0.08)
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    for (final p in points) {
      canvas.drawCircle(
        project(p.$1.millisecondsSinceEpoch.toDouble(), p.$2),
        3.5,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_WeightLinePainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.color != color ||
      oldDelegate.minY != minY ||
      oldDelegate.maxY != maxY;
}

/// Weekly workout volume + minutes from completed workouts in the last 7 days.
final class _WeeklyWorkoutCard extends ConsumerWidget {
  const _WeeklyWorkoutCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final statsAsync = ref.watch(weeklyWorkoutStatsProvider);
    final weightUnit = ref.watch(settingsProvider).weightUnit;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(FitFatTokens.spaceL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.fitness_center,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: FitFatTokens.spaceS),
                Text(
                  l10n.dashboardWeeklyWorkout,
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: FitFatTokens.spaceM),
            statsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text(l10n.dashboardError('$e')),
              data: (stats) => Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      icon: Icons.calculate_outlined,
                      title: l10n.dashboardVolume,
                      value: l10n.dashboardVolumeKg(
                        formatWeightValue(stats.totalVolumeKg, weightUnit),
                        weightUnitLabel(weightUnit),
                      ),
                    ),
                  ),
                  const SizedBox(width: FitFatTokens.spaceS),
                  Expanded(
                    child: MetricCard(
                      icon: Icons.timer_outlined,
                      title: l10n.dashboardMinutes,
                      value: stats.totalMinutes.toString(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Upcoming timed tasks: pending planner items with a due time, today or
/// later. Tapping a row (or the card footer) opens the Plan tab.
final class _UpcomingTasksCard extends ConsumerWidget {
  const _UpcomingTasksCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final tasksAsync = ref.watch(upcomingTasksProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(FitFatTokens.spaceL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.alarm_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: FitFatTokens.spaceS),
                Text(
                  l10n.dashboardUpcomingTasks,
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: FitFatTokens.spaceM),
            tasksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text(l10n.dashboardError('$e')),
              data: (tasks) {
                if (tasks.isEmpty) {
                  return Text(
                    l10n.dashboardNoUpcomingTasks,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  );
                }
                final today = DateTime.now();
                final todayStart = DateTime(today.year, today.month, today.day);
                return Column(
                  children: [
                    for (final task in tasks.take(5)) ...[
                      _TaskRow(
                        task: task,
                        today: todayStart,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                PlannerItemDetailScreen(itemId: task.id),
                          ),
                        ),
                      ),
                      const SizedBox(height: FitFatTokens.spaceS),
                    ],
                    if (tasks.length > 5) ...[
                      const SizedBox(height: FitFatTokens.spaceXs),
                      TextButton.icon(
                        onPressed: () => context.go('/plan'),
                        icon: const Icon(Icons.chevron_right, size: 18),
                        label: Text(
                          l10n.dashboardSeeAllTasks(tasks.length.toString()),
                        ),
                      ),
                    ] else ...[
                      // Even when every task fits, keep a visible path into
                      // the planner (previously the link needed >5 tasks).
                      const SizedBox(height: FitFatTokens.spaceXs),
                      TextButton.icon(
                        onPressed: () => context.go('/plan'),
                        icon: const Icon(Icons.chevron_right, size: 18),
                        label: Text(l10n.plannerAppBar),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

final class _TaskRow extends StatelessWidget {
  final Task task;
  final DateTime today;
  final VoidCallback onTap;

  const _TaskRow({
    required this.task,
    required this.today,
    required this.onTap,
  });

  String _timeLabel(BuildContext context) {
    final minutes = task.startTimeMinutes;
    // Untimed tasks surface here too now; they read as "Anytime" instead of
    // a clock time.
    if (minutes == null) {
      return AppLocalizations.of(context)!.plannerAnytime;
    }
    final time = TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
    return DateFormats.formatTime(context, time);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dueDay = task.day;
    final isToday =
        dueDay.year == today.year &&
        dueDay.month == today.month &&
        dueDay.day == today.day;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Icon(
            task.workoutId != null ? Icons.fitness_center : Icons.alarm,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: FitFatTokens.spaceS),
          Expanded(
            child: Text(
              task.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: FitFatTokens.spaceS),
          Text(
            '${isToday ? '' : '${DateFormats.formatShortDate(context, dueDay)} · '}'
            '${_timeLabel(context)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Latest workout card. When a workout is active it promotes to a
/// highlighted "Continue workout" affordance; otherwise it shows the latest
/// completed workout with its status badge.
final class _LatestWorkoutCard extends ConsumerWidget {
  const _LatestWorkoutCard();

  void _openDetail(BuildContext context, Workout workout) {
    if (workout.isActive) {
      context.go('/active-workout');
      return;
    }
    // Completed workouts open their read-only summary.
    context.go('/workout-summary/${workout.id}');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final activeWorkout = ref.watch(activeWorkoutProvider);
    final latestAsync = ref.watch(latestWorkoutProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(FitFatTokens.spaceL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.fitness_center,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: FitFatTokens.spaceS),
                Text(
                  l10n.dashboardLatestWorkout,
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: FitFatTokens.spaceM),
            if (activeWorkout != null)
              _ActiveWorkoutCardBody(
                workout: activeWorkout,
                onTap: () => _openDetail(context, activeWorkout),
              )
            else
              latestAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text(l10n.dashboardError('$e')),
                data: (workout) {
                  if (workout == null) {
                    return Text(
                      l10n.dashboardNoWorkouts,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    );
                  }
                  return _WorkoutCardBody(
                    workout: workout,
                    onTap: () => _openDetail(context, workout),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// Body of the latest-workout card when a workout is active: name + status
/// badge + highlighted "Continue workout" button.
final class _ActiveWorkoutCardBody extends StatelessWidget {
  final Workout workout;
  final VoidCallback onTap;

  const _ActiveWorkoutCardBody({required this.workout, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final statusColors = theme.extension<FitFatColors>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                workout.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            StatusBadge(label: l10n.statusActive, color: statusColors.warning),
          ],
        ),
        const SizedBox(height: FitFatTokens.spaceM),
        FilledButton.tonalIcon(
          onPressed: onTap,
          icon: const Icon(Icons.play_arrow),
          label: Text(l10n.dashboardContinueWorkout),
        ),
      ],
    );
  }
}

/// Body of the latest-workout card for a completed workout: name, date,
/// duration and a "Completed" badge.
final class _WorkoutCardBody extends StatelessWidget {
  final Workout workout;
  final VoidCallback onTap;

  const _WorkoutCardBody({required this.workout, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final statusColors = theme.extension<FitFatColors>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                workout.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            StatusBadge(
              label: l10n.statusCompleted,
              color: statusColors.success,
            ),
          ],
        ),
        const SizedBox(height: FitFatTokens.spaceXs),
        Text(
          DateFormats.formatDate(context, workout.date),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (workout.duration > Duration.zero) ...[
          const SizedBox(height: FitFatTokens.spaceXs),
          Text(
            l10n.dashboardDurationMin(workout.duration.inMinutes),
            style: theme.textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: FitFatTokens.spaceM),
        OutlinedButton(
          onPressed: onTap,
          child: Text(l10n.dashboardOpenWorkout),
        ),
      ],
    );
  }
}

/// First-run welcome hub shown on the dashboard when there are no meals and no
/// workouts. Three quick actions push the respective create forms.
final class _WelcomeHub extends ConsumerWidget {
  const _WelcomeHub();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      children: [
        const SizedBox(height: FitFatTokens.spaceXl),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.rocket_launch,
            size: 36,
            color: scheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: FitFatTokens.spaceL),
        Text(
          l10n.dashboardWelcomeTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: FitFatTokens.spaceS),
        Text(
          l10n.dashboardWelcomeBody,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: FitFatTokens.spaceXl),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.soup_kitchen_outlined),
                title: Text(l10n.dashboardWelcomeActionIngredients),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    _openForm(context, ref, const IngredientFormScreen()),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.restaurant_outlined),
                title: Text(l10n.dashboardWelcomeActionMeals),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openForm(
                  context,
                  ref,
                  const MealFormScreen(),
                  onSaved: () {
                    ref.invalidate(mealListProvider);
                    ref.invalidate(todayCaloriesProvider);
                    ref.invalidate(todayMacrosProvider);
                  },
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.fitness_center),
                title: Text(l10n.dashboardWelcomeActionWorkouts),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openForm(
                  context,
                  ref,
                  const WorkoutFormScreen(),
                  onSaved: () {
                    ref.invalidate(workoutListProvider);
                    ref.invalidate(latestWorkoutProvider);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref,
    Widget form, {
    VoidCallback? onSaved,
  }) async {
    final saved = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => form));
    if (saved == true) onSaved?.call();
  }
}
