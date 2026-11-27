import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../body/providers/body_metrics.dart';
import '../../body/screens/body_metric_dialog.dart';
import '../../budget/format.dart';
import '../../budget/providers/budget_overview.dart';
import '../../diet/providers/calories.dart';
import '../../diet/providers/meals.dart';
import '../../diet/screens/ingredient_form.dart';
import '../../diet/screens/meal_form.dart';
import '../../exercise/providers/workouts.dart';
import '../../exercise/screens/workout_form.dart';
import '../../goals/providers/goals.dart';
import '../../models/body_metrics_entry.dart';
import '../../models/body_weight_goal.dart';
import '../../models/task.dart';
import '../../models/units.dart';
import '../../planner/providers/planner.dart';
import '../../planner/screens/planner_item_detail.dart';
import '../../settings/providers/settings.dart';
import '../../sync/widgets/sync_chip.dart';
import '../../ui/date_formats.dart';
import '../../ui/theme_extensions.dart';
import '../../ui/tokens.dart';
import '../../ui/units.dart';
import '../../ui/widgets/section_header.dart';
import '../../ui/widgets/status_badge.dart';
import '../providers/dashboard.dart';
import '../providers/dashboard_layout.dart';
import 'wizard.dart';

/// The "today stack": one column of cards in the order set in
/// Settings › Dashboard (nutrition and tasks first by default). Everything
/// here is local, so cards never wait or fail; sync lives in the top-bar chip.
final class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final mealsAsync = ref.watch(mealListProvider);
    final workoutsAsync = ref.watch(workoutListProvider);
    final hasNoData =
        (mealsAsync.value?.isEmpty ?? false) &&
        (workoutsAsync.value?.isEmpty ?? false);
    final settings = ref.watch(settingsProvider);
    if (!settings.hasSeenWizard && hasNoData) {
      return const OnboardingWizardScreen();
    }
    final cards = ref.watch(dashboardLayoutProvider).visible;
    final today = DateFormats.formatFullDate(context, DateTime.now());

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text(l10n.dashboardToday),
            actions: [
              const SyncChip(),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: l10n.settingsAppBar,
                onPressed: () => context.go('/settings'),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: FitFatTokens.kContentMaxWidth,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    FitFatTokens.spaceL,
                    0,
                    FitFatTokens.spaceL,
                    FitFatTokens.spaceXxl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: FitFatTokens.spaceM,
                    children: [
                      Text(
                        today,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      for (final card in cards)
                        switch (card) {
                          DashboardCard.nutrition => const _NutritionCard(),
                          DashboardCard.tasks => const _TasksCard(),
                          DashboardCard.training => const _TrainingCard(),
                          DashboardCard.weight => const _WeightCard(),
                          DashboardCard.goals => const _GoalsCard(),
                          DashboardCard.money => const _MoneyCard(),
                        },
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

// ---------------------------------------------------------------------------
// Card shell
// ---------------------------------------------------------------------------

/// The common card: small-caps label with an optional value on the right,
/// then the body. Tapping the card opens its full screen.
final class _DashCard extends StatelessWidget {
  const _DashCard({
    required this.label,
    required this.child,
    this.trailing,
    this.onTap,
  });

  final String label;
  final String? trailing;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            FitFatTokens.spaceL,
            FitFatTokens.spaceXs,
            FitFatTokens.spaceL,
            FitFatTokens.spaceL,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(label, trailing: trailing),
              const SizedBox(height: FitFatTokens.spaceXs),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// An empty card's body: one line saying what goes here, and the action that
/// starts it.
final class _EmptyStart extends StatelessWidget {
  const _EmptyStart({
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.icon = Icons.add,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      spacing: FitFatTokens.spaceM,
      children: [
        Expanded(
          child: Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        FilledButton.tonalIcon(
          onPressed: onAction,
          icon: Icon(icon, size: 18),
          label: Text(actionLabel),
        ),
      ],
    );
  }
}

/// Thin rounded progress bar used by every card.
final class _Bar extends StatelessWidget {
  const _Bar(this.value, {this.color, this.height = 6});

  final double value;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(FitFatTokens.radiusFull),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: scheme.surfaceContainerHighest,
        valueColor: AlwaysStoppedAnimation(color ?? scheme.primary),
      ),
    );
  }
}

const _tabular = [FontFeature.tabularFigures()];

Future<bool?> _push(BuildContext context, Widget screen) =>
    Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => screen));

// ---------------------------------------------------------------------------
// Nutrition
// ---------------------------------------------------------------------------

/// Calories against the target, then protein, carbs and fat as three columns
/// with their own bars. Calories are the one value you can meaningfully
/// overshoot, so only that bar turns to the error color.
final class _NutritionCard extends ConsumerWidget {
  const _NutritionCard();

  Future<void> _logMeal(BuildContext context, WidgetRef ref) async {
    final saved = await _push(context, const MealFormScreen());
    if (saved == true) {
      ref.invalidate(mealListProvider);
      ref.invalidate(todayCaloriesProvider);
      ref.invalidate(todayMacrosProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = theme.extension<FitFatColors>()!;
    final meta = ref.watch(calorieTargetMetaProvider).value;
    final consumed = ref.watch(todayCaloriesProvider).value ?? 0;
    final macros = ref.watch(todayMacrosProvider).value;
    final targets = ref.watch(macroTargetsProvider).value;
    final target = meta?.target ?? 0;
    final kcal = macroRowState(consumed: consumed, target: target);
    final left = (target - consumed).round();

    return _DashCard(
      label: l10n.dashboardNutrition,
      trailing: meta == null
          ? null
          : '${l10n.settingsBmrLabel} ${meta.bmr.round()} · '
                '${l10n.settingsTdeeLabel} ${meta.tdee.round()}',
      onTap: () => context.go('/diet'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: FitFatTokens.spaceS,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            spacing: FitFatTokens.spaceXs,
            children: [
              Text(
                consumed.round().toString(),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: _tabular,
                ),
              ),
              Text(
                '/ ${target.round()} kcal',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontFeatures: _tabular,
                ),
              ),
              const Spacer(),
              if (target > 0)
                Text(
                  left >= 0
                      ? l10n.dashboardKcalLeft(left)
                      : l10n.dashboardKcalOver(-left),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: left >= 0 ? colors.success : scheme.error,
                    fontFeatures: _tabular,
                  ),
                ),
            ],
          ),
          _Bar(kcal.ratio, color: kcal.over ? scheme.error : null),
          if (macros != null && targets != null) ...[
            const SizedBox(height: FitFatTokens.spaceXs),
            Row(
              spacing: FitFatTokens.spaceM,
              children: [
                _MacroColumn(
                  label: l10n.dashboardMacroProtein,
                  color: scheme.primary,
                  consumed: macros.protein,
                  target: targets.protein,
                ),
                _MacroColumn(
                  label: l10n.dashboardMacroCarbs,
                  color: Color.lerp(scheme.primary, scheme.surface, 0.45)!,
                  consumed: macros.carbs,
                  target: targets.carbs,
                ),
                _MacroColumn(
                  label: l10n.dashboardMacroFat,
                  color: colors.warning,
                  consumed: macros.fat,
                  target: targets.fat,
                ),
              ],
            ),
            Text(
              '${l10n.dashboardMacroFiber} '
              '${l10n.dashboardMacroProgress(macros.fiber.toStringAsFixed(0), targets.fiber.toStringAsFixed(0))}'
              '${meta?.isEstimated == true ? ' · ${l10n.settingsEstimatedSuffix}' : ''}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          if (consumed == 0)
            _EmptyStart(
              message: l10n.dashboardNoMealsToday,
              actionLabel: l10n.dashboardLogMeal,
              onAction: () => _logMeal(context, ref),
            ),
        ],
      ),
    );
  }
}

final class _MacroColumn extends StatelessWidget {
  const _MacroColumn({
    required this.label,
    required this.color,
    required this.consumed,
    required this.target,
  });

  final String label;
  final Color color;
  final double consumed;
  final double target;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final state = macroRowState(consumed: consumed, target: target);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 3,
        children: [
          Row(
            spacing: 5,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(color: muted),
                ),
              ),
            ],
          ),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: consumed.toStringAsFixed(0),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text: '/${target.toStringAsFixed(0)} g',
                  style: TextStyle(color: muted),
                ),
              ],
            ),
            maxLines: 1,
            style: theme.textTheme.bodySmall?.copyWith(fontFeatures: _tabular),
          ),
          _Bar(state.ratio, color: color, height: 4),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tasks
// ---------------------------------------------------------------------------

/// Today's tasks as a checklist: open ones first, by time.
final class _TasksCard extends ConsumerWidget {
  const _TasksCard();

  static const _maxRows = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final tasks = ref.watch(todayTasksProvider).value ?? const <Task>[];
    final done = tasks.where((t) => t.done).length;
    return _DashCard(
      label: l10n.dashboardTasks,
      trailing: tasks.isEmpty
          ? null
          : l10n.dashboardTasksDone(done, tasks.length),
      onTap: () => context.go('/plan'),
      child: tasks.isEmpty
          ? _EmptyStart(
              message: l10n.dashboardNoTasksToday,
              actionLabel: l10n.dashboardUpcomingEmptyCta,
              onAction: () => context.go('/plan'),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final task in tasks.take(_maxRows)) _TaskRow(task: task),
                if (tasks.length > _maxRows)
                  Padding(
                    padding: const EdgeInsets.only(top: FitFatTokens.spaceXs),
                    child: Text(
                      l10n.dashboardTasksMore(tasks.length - _maxRows),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

final class _TaskRow extends ConsumerWidget {
  const _TaskRow({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final time = task.startTimeMinutes;
    return InkWell(
      borderRadius: BorderRadius.circular(FitFatTokens.radiusS),
      onTap: () => _push(context, PlannerItemDetailScreen(itemId: task.id)),
      child: SizedBox(
        height: 40,
        child: Row(
          children: [
            Checkbox(
              value: task.done,
              visualDensity: VisualDensity.compact,
              onChanged: (v) async {
                final repo = ref.read(taskRepositoryProvider);
                await repo.update(
                  task.copyWith(
                    done: v ?? false,
                    taskStatus: (v ?? false)
                        ? TaskStatus.done
                        : TaskStatus.pending,
                  ),
                );
                invalidateDashboard(ref);
              },
            ),
            Expanded(
              child: Text(
                task.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: task.done ? muted : null,
                  decoration: task.done ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            if (task.workoutId != null)
              Padding(
                padding: const EdgeInsets.only(left: FitFatTokens.spaceS),
                child: Icon(Icons.fitness_center, size: 14, color: muted),
              ),
            if (time != null)
              Padding(
                padding: const EdgeInsets.only(left: FitFatTokens.spaceS),
                child: Text(
                  DateFormats.formatTime(
                    context,
                    TimeOfDay(hour: time ~/ 60, minute: time % 60),
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: muted,
                    fontFeatures: _tabular,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Training
// ---------------------------------------------------------------------------

/// The workout in progress (with Continue) or the latest one, a dot per
/// training day this week, and the week's totals.
final class _TrainingCard extends ConsumerWidget {
  const _TrainingCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.extension<FitFatColors>()!;
    final muted = theme.colorScheme.onSurfaceVariant;
    final active = ref.watch(activeWorkoutProvider);
    final latest = ref.watch(latestWorkoutProvider).value;
    final stats = ref.watch(weeklyWorkoutStatsProvider).value;
    final days = ref.watch(weekTrainingDaysProvider).value ?? const <int>{};
    final weightUnit = ref.watch(settingsProvider).weightUnit;
    final workout = active ?? latest;

    Future<void> addWorkout() async {
      final saved = await _push(context, const WorkoutFormScreen());
      if (saved == true) {
        ref.invalidate(workoutListProvider);
        invalidateDashboard(ref);
      }
    }

    if (workout == null && (stats?.daysTrained ?? 0) == 0) {
      return _DashCard(
        label: l10n.dashboardTraining,
        trailing: l10n.dashboardThisWeek,
        onTap: () => context.go('/exercise'),
        child: _EmptyStart(
          message: l10n.dashboardWeeklyEmptyBody,
          actionLabel: l10n.dashboardLatestEmptyCta,
          onAction: addWorkout,
        ),
      );
    }

    final todayIndex = DateTime.now().weekday - DateTime.monday;
    final weekdayLetters = DateFormats.narrowWeekdays(context);
    return _DashCard(
      label: l10n.dashboardTraining,
      trailing: l10n.dashboardThisWeek,
      onTap: () => context.go('/exercise'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: FitFatTokens.spaceM,
        children: [
          if (workout != null)
            Row(
              spacing: FitFatTokens.spaceM,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Row(
                        spacing: FitFatTokens.spaceS,
                        children: [
                          Flexible(
                            child: Text(
                              workout.name,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                          StatusBadge(
                            label: workout.isActive
                                ? l10n.statusActive
                                : l10n.statusCompleted,
                            color: workout.isActive
                                ? colors.warning
                                : colors.success,
                          ),
                        ],
                      ),
                      Text(
                        workout.isActive
                            ? l10n.dashboardStartedAt(
                                DateFormats.formatTime(
                                  context,
                                  TimeOfDay.fromDateTime(workout.startedAt!),
                                ),
                              )
                            : [
                                DateFormats.formatDate(context, workout.date),
                                if (workout.duration > Duration.zero)
                                  l10n.dashboardDurationMin(
                                    workout.duration.inMinutes,
                                  ),
                              ].join(' · '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (workout.isActive)
                  FilledButton(
                    onPressed: () => context.go('/active-workout'),
                    child: Text(l10n.dashboardContinue),
                  )
                else
                  OutlinedButton(
                    onPressed: () =>
                        context.go('/workout-summary/${workout.id}'),
                    child: Text(l10n.commonOpen),
                  ),
              ],
            ),
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Column(
                    spacing: 3,
                    children: [
                      Text(
                        weekdayLetters[i],
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: i == todayIndex
                              ? theme.colorScheme.primary
                              : muted,
                          fontWeight: i == todayIndex
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: days.contains(i)
                              ? theme.colorScheme.primary
                              : null,
                          border: days.contains(i)
                              ? null
                              : Border.all(
                                  color: theme.colorScheme.outlineVariant,
                                  width: 1.5,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (stats != null) ...[
            const Divider(height: 1),
            Row(
              children: [
                _Stat(
                  l10n.dashboardDaysTrained,
                  l10n.dashboardDaysTrainedValue(stats.daysTrained),
                ),
                _Stat(
                  l10n.dashboardHoursTrained,
                  formatWeeklyDuration(l10n, stats.totalMinutes),
                ),
                _Stat(
                  l10n.dashboardVolume,
                  formatVolume(stats.totalVolumeKg, weightUnit),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

final class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 2,
        children: [
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(fontFeatures: _tabular),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Weight
// ---------------------------------------------------------------------------

final class _WeightCard extends ConsumerWidget {
  const _WeightCard();

  Future<void> _add(
    BuildContext context,
    WidgetRef ref, {
    bool height = false,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showBodyMetricDialog(
      context,
      dialogTitle: height
          ? l10n.bodyMetricsDialogHeightTitle
          : l10n.bodyMetricsDialogWeightTitle,
      valueLabel: height
          ? l10n.bodyMetricsHeightLabel
          : l10n.bodyMetricsWeightLabel,
      valueSuffix: height ? 'cm' : 'kg',
    );
    if (result == null || !context.mounted) return;
    final (day, value) = result;
    final repo = ref.read(bodyMetricsRepositoryProvider);
    if (height) {
      await repo.upsert(day, heightCm: value);
    } else {
      await repo.upsert(day, weightKg: value);
    }
    ref.invalidate(bodyMetricsProvider);
    ref.invalidate(latestBodyMetricsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final entries =
        ref.watch(bodyMetricsProvider).value ?? const <BodyMetricsEntry>[];
    final goal = settings.bodyWeightGoal;
    final hasWeight = entries.any((e) => e.weightKg != null);
    return _DashCard(
      label: l10n.dashboardWeight,
      trailing: goal == null
          ? null
          : l10n.bodyMetricsGoal(switch (goal) {
              BodyWeightGoal.lose => l10n.settingsGoalLose,
              BodyWeightGoal.maintain => l10n.settingsGoalMaintain,
              BodyWeightGoal.gain => l10n.settingsGoalGain,
            }),
      child: !hasWeight
          ? _EmptyStart(
              message: l10n.bodyMetricsEmptyWeight,
              actionLabel: l10n.bodyMetricsAddWeight,
              onAction: () => _add(context, ref),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _WeightSummary(
                  entries: entries,
                  unit: settings.weightUnit,
                  goal: goal,
                ),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => _add(context, ref),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(l10n.bodyMetricsAddWeight),
                    ),
                    TextButton.icon(
                      onPressed: () => _add(context, ref, height: true),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(l10n.bodyMetricsAddHeight),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

/// Latest weight, the 30-day change and the trend line.
final class _WeightSummary extends StatelessWidget {
  final List<BodyMetricsEntry> entries;
  final WeightUnit unit;
  final BodyWeightGoal? goal;
  const _WeightSummary({required this.entries, required this.unit, this.goal});

  List<(DateTime, double)> get _points => [
    for (final entry in entries)
      if (entry.weightKg != null)
        (entry.day, weightFromKg(entry.weightKg!, unit)),
  ];

  String _deltaText(double delta, WeightUnit unit) {
    final sign = delta > 0 ? '+' : '−';
    // [delta] is already in [unit] (the points are converted).
    return '$sign${delta.abs().toStringAsFixed(1)} ${weightUnitLabel(unit)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final colors = theme.extension<FitFatColors>()!;
    final points = _points;
    final now = DateTime.now();
    final delta7 = _computeDelta(points, now, 7);
    final delta30 = _computeDelta(points, now, 30);
    final projection = _computeProjection(l10n, points, goal);
    final good = switch (goal) {
      BodyWeightGoal.gain => (double d) => d > 0,
      _ => (double d) => d < 0,
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      spacing: FitFatTokens.spaceM,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 2,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: formatWeightValue(
                      entries.lastWhere((e) => e.weightKg != null).weightKg!,
                      unit,
                    ),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontFeatures: _tabular,
                    ),
                  ),
                  TextSpan(
                    text: ' ${weightUnitLabel(unit)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (delta30 != null)
              Text(
                l10n.dashboardDelta30d(_deltaText(delta30, unit)),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: good(delta30) ? colors.success : colors.warning,
                  fontFeatures: _tabular,
                ),
              )
            else if (delta7 != null)
              Text(
                l10n.dashboardDelta7d(_deltaText(delta7, unit)),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: good(delta7) ? colors.success : colors.warning,
                ),
              ),
            if (projection != null)
              Text(
                projection,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        if (points.length > 1)
          Expanded(
            child: SizedBox(
              height: 56,
              child: _WeightLineChart(points: points),
            ),
          ),
      ],
    );
  }

  double? _computeDelta(
    List<(DateTime, double)> points,
    DateTime now,
    int days,
  ) {
    if (points.length < 2) return null;
    final cutoff = now.subtract(Duration(days: days));
    final recent = points.where((p) => p.$1.isAfter(cutoff)).toList();
    if (recent.length < 2) return null;
    return recent.last.$2 - recent.first.$2;
  }

  String? _computeProjection(
    AppLocalizations l10n,
    List<(DateTime, double)> points,
    BodyWeightGoal? goal,
  ) {
    if (goal == null || points.length < 2) return null;
    final first = points.first.$2;
    final last = points.last.$2;
    final days = points.last.$1.difference(points.first.$1).inDays;
    if (days <= 0) return null;
    final slopePerDay = (last - first) / days;
    if (slopePerDay == 0) return null;
    if (goal == BodyWeightGoal.lose && slopePerDay >= 0) return null;
    if (goal == BodyWeightGoal.gain && slopePerDay <= 0) return null;
    if (goal == BodyWeightGoal.maintain) return l10n.dashboardStableTrend;
    if ((last - first).abs() == 0) return null;
    return slopePerDay < 0
        ? l10n.dashboardTrendingDown
        : l10n.dashboardTrendingUp;
  }
}

final class _WeightLineChart extends StatelessWidget {
  final List<(DateTime, double)> points;
  const _WeightLineChart({required this.points});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    final values = points.map((s) => s.$2).toList();
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
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
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i <= 2; i++) {
      final y = size.height * i / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
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

// ---------------------------------------------------------------------------
// Goals
// ---------------------------------------------------------------------------

final class _GoalsCard extends ConsumerWidget {
  const _GoalsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final goals = ref.watch(goalListProvider).value ?? const [];
    final active = goals.where((g) => g.isActive).toList();
    return _DashCard(
      label: l10n.dashboardGoalsTitle,
      trailing: active.isEmpty
          ? null
          : l10n.dashboardGoalsActive(active.length),
      onTap: () => context.go('/plan'),
      child: active.isEmpty
          ? _EmptyStart(
              message: l10n.dashboardGoalsEmptyHint,
              actionLabel: l10n.dashboardSetGoal,
              icon: Icons.flag_outlined,
              onAction: () => context.go('/plan'),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: FitFatTokens.spaceM,
              children: [
                for (final goal in active.take(3)) _GoalRow(goal: goal),
              ],
            ),
    );
  }
}

final class _GoalRow extends ConsumerWidget {
  final dynamic goal;
  const _GoalRow({required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final value = ref
        .watch(latestGoalProgressProvider(goal.id as String))
        .value;
    final double? progress = goal.progressFrom(value) as double?;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FitFatTokens.spaceXs,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                goal.title as String,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            if (goal.targetValue != null)
              Text(
                '${value?.toStringAsFixed(1) ?? '–'} / ${goal.targetValue} ${goal.unit ?? ''}'
                    .trim(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: muted,
                  fontFeatures: _tabular,
                ),
              ),
            if (progress != null)
              Padding(
                padding: const EdgeInsets.only(left: FitFatTokens.spaceS),
                child: Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontFeatures: _tabular,
                  ),
                ),
              ),
          ],
        ),
        if (progress != null) _Bar(progress, height: 4),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Money
// ---------------------------------------------------------------------------

/// This month's spending against this month's income, plus net worth.
/// Accounts come from the server, so the empty state offers a sync.
final class _MoneyCard extends ConsumerWidget {
  const _MoneyCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final colors = theme.extension<FitFatColors>()!;
    final overview = ref.watch(budgetOverviewProvider).value;
    final currency = ref.watch(settingsProvider).baseCurrency;
    final month = MaterialLocalizations.of(
      context,
    ).formatMonthYear(DateTime.now());

    if (overview == null || overview.accounts.isEmpty) {
      return _DashCard(
        label: l10n.dashboardMoney,
        trailing: month,
        child: _EmptyStart(
          message: l10n.dashboardNoAccounts,
          actionLabel: l10n.syncNow,
          icon: Icons.sync,
          onAction: () => showSyncSheet(context),
        ),
      );
    }
    final income = overview.monthIncome;
    final spent = overview.monthExpense;
    return _DashCard(
      label: l10n.dashboardMoney,
      trailing: month,
      onTap: () => context.go('/budget'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: FitFatTokens.spaceS,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            spacing: FitFatTokens.spaceXs,
            children: [
              Text(
                formatMoney(spent, currency),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: _tabular,
                ),
              ),
              Text(
                l10n.dashboardSpent,
                style: theme.textTheme.bodyMedium?.copyWith(color: muted),
              ),
            ],
          ),
          if (income > 0)
            _Bar(
              spent / income,
              color: spent > income ? theme.colorScheme.error : colors.warning,
            ),
          Text(
            [
              l10n.dashboardIncome(formatMoney(income, currency)),
              '${l10n.budgetNetWorth} ${formatMoney(overview.netWorth, currency)}',
            ].join(' · '),
            style: theme.textTheme.bodySmall?.copyWith(
              color: muted,
              fontFeatures: _tabular,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared helpers (pinned by tests)
// ---------------------------------------------------------------------------

/// The two decisions a progress row makes, extracted so they can be pinned
/// without pumping a dashboard that needs a database.
///
/// [over] is deliberately separate from the fill: a row that is over its target
/// clamps to a full bar like any other, but the caller needs to know it crossed
/// so it can change colour. Collapsing the two would lose the overshoot.
({double ratio, bool over}) macroRowState({
  required double consumed,
  required double target,
}) => (
  ratio: target <= 0 ? 0.0 : (consumed / target).clamp(0.0, 1.0),
  over: target > 0 && consumed > target,
);

/// Renders a weekly duration in hours, keeping the minutes when they add
/// something.
///
/// The decision to keep minutes: `0.8 h` is technically correct and much harder
/// to read at a glance than `45 m`, and a sub-hour session is common enough to
/// be worth the branch.
/// The weekly card's Time tile, as whole units.
///
/// Deliberately never a fraction of an hour: `0.9 h` had to be read back into
/// 54 minutes, which is more work than the value it saved. Under an hour shows
/// as minutes, over one shows hours and the remainder.
///
/// Public so it can be pinned. It is a presentation rule about the user's own
/// time, so getting it wrong is immediately visible to them — the same reason
/// `macroRowState` and `formatVolume` are public.
String formatWeeklyDuration(AppLocalizations l10n, int minutes) {
  final hours = minutes ~/ 60;
  final mins = minutes % 60;
  if (hours == 0) return l10n.dashboardHoursTrainedMinutes('$mins');
  if (mins == 0) return l10n.dashboardHoursTrainedHours('$hours');
  return l10n.dashboardHoursTrainedHoursMinutes('$hours', '$mins');
}

// ignore: unused_element
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
