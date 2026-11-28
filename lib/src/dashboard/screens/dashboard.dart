import 'dart:math' as math;

import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../body/providers/body_metrics.dart';
import '../../body/screens/body_metric_dialog.dart';
import '../../budget/providers/budget_overview.dart';
import '../../budget/widgets/money_widgets.dart';
import '../../diet/providers/calories.dart';
import '../../diet/providers/meals.dart';
import '../../diet/screens/ingredient_form.dart';
import '../../diet/screens/meal_form.dart';
import '../../exercise/providers/workouts.dart';
import '../../exercise/screens/workout_form.dart';
import '../../exercise/start_workout.dart';
import '../../goals/providers/goals.dart';
import '../../goals/services/goal_tracking.dart';
import '../../goals/widgets/goal_widgets.dart';
import '../../models/body_metrics_entry.dart';
import '../../models/body_weight_goal.dart';
import '../../models/goal.dart';
import '../../models/task.dart';
import '../../models/units.dart';
import '../../models/workout.dart';
import '../../planner/providers/planner.dart';
import '../../planner/screens/planner_item_detail.dart';
import '../../settings/providers/settings.dart';
import '../../sync/widgets/sync_chip.dart';
import '../../ui/date_formats.dart';
import '../../ui/theme_extensions.dart';
import '../../ui/tokens.dart';
import '../../ui/units.dart';
import '../../ui/widgets/macro_bar.dart';
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
    final locale = Localizations.localeOf(context).toLanguageTag();
    final today = DateFormat('EEE d MMM', locale).format(DateTime.now());

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // "Today" and the date sit on the same line as the sync chip and
          // the settings button.
          SliverAppBar(
            pinned: true,
            title: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: l10n.dashboardToday),
                  TextSpan(
                    text: '  $today',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
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
                    FitFatTokens.spaceXs,
                    FitFatTokens.spaceL,
                    FitFatTokens.spaceXxl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: FitFatTokens.spaceM,
                    children: [
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

/// The common card: a tinted icon, the title, an optional value and a ›
/// when the card opens a screen, then the body.
final class _DashCard extends StatelessWidget {
  const _DashCard({
    required this.icon,
    required this.label,
    required this.child,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? trailing;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            14,
            FitFatTokens.spaceM,
            FitFatTokens.spaceM,
            14,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: FitFatTokens.spaceM,
            children: [
              Row(
                spacing: 10,
                children: [
                  _IconBox(icon),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (trailing != null)
                    Text(
                      trailing!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: muted,
                        fontFeatures: _tabular,
                      ),
                    ),
                  if (onTap != null)
                    Icon(Icons.chevron_right, size: 20, color: muted),
                ],
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

final class _IconBox extends StatelessWidget {
  const _IconBox(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.primary;
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(FitFatTokens.radiusS),
      ),
      child: Icon(icon, size: 18, color: c),
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

String _whole(BuildContext context, num v) => NumberFormat.decimalPattern(
  Localizations.localeOf(context).toLanguageTag(),
).format(v.round());

// ---------------------------------------------------------------------------
// Nutrition
// ---------------------------------------------------------------------------

/// No sodium target is stored, so the card uses the common 2.3 g daily limit.
const _sodiumLimitG = 2.3;

/// A ring with the calories left (or over), then the five nutrients in the
/// fixed order, each with grams of target and its own bar. BMR and TDEE sit
/// under them. Carbs, fat and sodium turn to the error color when over;
/// protein and fiber are minimums, so going over is fine.
final class _NutritionCard extends ConsumerWidget {
  const _NutritionCard();

  Future<void> _logMeal(BuildContext context, WidgetRef ref) async {
    final saved = await _push(context, const MealFormScreen());
    if (saved == true) {
      ref.invalidate(mealListProvider);
      invalidateDashboard(ref);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final meta = ref.watch(calorieTargetMetaProvider).value;
    final today = ref.watch(todayNutritionProvider).value;
    final targets = ref.watch(macroTargetsProvider).value;
    final consumed = today?.calories ?? 0;
    final target = meta?.target ?? 0;
    final colors = MacroColors.of(context);
    final labels = macroLabels(l10n);
    final values = today == null ? MacroValues.zero : MacroValues.of(today);
    final goals = [
      targets?.protein,
      targets?.carbs,
      targets?.fat,
      targets?.fiber,
      _sodiumLimitG,
    ];

    return _DashCard(
      icon: Icons.restaurant_outlined,
      label: l10n.dashboardNutrition,
      trailing: target > 0
          ? '${_whole(context, consumed)} / ${_whole(context, target)} kcal'
          : null,
      onTap: () => context.go('/diet'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: FitFatTokens.spaceM,
        children: [
          Row(
            spacing: 14,
            children: [
              _CalorieRing(consumed: consumed, target: target),
              Expanded(
                child: Column(
                  spacing: 7,
                  children: [
                    for (var i = 0; i < 5; i++)
                      _MacroRow(
                        index: i,
                        label: labels[i],
                        color: colors.base[i],
                        consumed: values.values[i],
                        target: goals[i],
                        overIsBad: i == 1 || i == 2 || i == 4,
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (meta != null)
            Container(
              padding: const EdgeInsets.only(top: FitFatTokens.spaceS),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
              ),
              child: Text(
                [
                  '${l10n.settingsBmrLabel} ${_whole(context, meta.bmr)}',
                  '${l10n.settingsTdeeLabel} ${_whole(context, meta.tdee)}',
                  if (meta.isEstimated) l10n.settingsEstimatedSuffix,
                ].join(' · '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: muted,
                  fontFeatures: _tabular,
                ),
              ),
            ),
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

final class _CalorieRing extends StatelessWidget {
  const _CalorieRing({required this.consumed, required this.target});

  final double consumed;
  final double target;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final kcal = macroRowState(consumed: consumed, target: target);
    final color = kcal.over ? scheme.error : scheme.primary;
    return SizedBox.square(
      dimension: 88,
      child: CustomPaint(
        painter: _RingPainter(
          value: kcal.ratio,
          color: color,
          track: scheme.surfaceContainerHighest,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _whole(context, (target - consumed).abs()),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: kcal.over ? scheme.error : null,
                  fontFeatures: _tabular,
                  height: 1.1,
                ),
              ),
              Text(
                kcal.over
                    ? l10n.dashboardKcalOverShort
                    : l10n.dashboardKcalLeftShort,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.value,
    required this.color,
    required this.track,
  });

  final double value;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 9.0;
    final rect = Offset.zero & size;
    final arc = rect.deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(arc, 0, 2 * math.pi, false, paint..color = track);
    if (value > 0) {
      canvas.drawArc(
        arc,
        -math.pi / 2,
        2 * math.pi * value,
        false,
        paint..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color || old.track != track;
}

/// One nutrient: color dot, name, "104/160 g" and a thin bar.
final class _MacroRow extends StatelessWidget {
  const _MacroRow({
    required this.index,
    required this.label,
    required this.color,
    required this.consumed,
    required this.target,
    required this.overIsBad,
  });

  final int index;
  final String label;
  final Color color;
  final double consumed;
  final double? target;
  final bool overIsBad;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final t = target ?? 0;
    final state = macroRowState(consumed: consumed, target: t);
    final bad = overIsBad && state.over;
    final error = theme.colorScheme.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(color: muted),
              ),
            ),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: formatMacro(index, consumed),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: bad ? error : null,
                    ),
                  ),
                  TextSpan(
                    text: target == null ? ' g' : '/${formatMacro(index, t)} g',
                    style: TextStyle(color: muted),
                  ),
                ],
              ),
              maxLines: 1,
              style: theme.textTheme.labelSmall?.copyWith(
                fontFeatures: _tabular,
              ),
            ),
          ],
        ),
        _Bar(state.ratio, color: bad ? error : color, height: 4),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tasks
// ---------------------------------------------------------------------------

Future<void> _setDone(WidgetRef ref, Task task, bool done) async {
  await ref
      .read(taskRepositoryProvider)
      .update(
        task.copyWith(
          done: done,
          taskStatus: done ? TaskStatus.done : TaskStatus.pending,
        ),
      );
  invalidateDashboard(ref);
}

String _minutes(BuildContext context, int m) =>
    DateFormats.formatTime(context, TimeOfDay(hour: m ~/ 60, minute: m % 60));

/// "Now and next": a segment per task for the day's progress, a tinted strip
/// for the task on now (else the next one), then the rest of the day.
final class _TasksCard extends ConsumerWidget {
  const _TasksCard();

  static const _maxRows = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final tasks = ref.watch(todayTasksProvider).value ?? const <Task>[];
    final done = tasks.where((t) => t.done).length;
    final open = tasks.where((t) => !t.done).toList();
    final now = TimeOfDay.now();
    final nowMin = now.hour * 60 + now.minute;
    // On now: started and not yet ended. Else the next timed one, else the
    // first open task.
    final current = open
        .where(
          (t) =>
              t.startTimeMinutes != null &&
              t.endTimeMinutes != null &&
              t.startTimeMinutes! <= nowMin &&
              nowMin < t.endTimeMinutes!,
        )
        .firstOrNull;
    final next =
        current ??
        open
            .where(
              (t) => t.startTimeMinutes != null && t.startTimeMinutes! > nowMin,
            )
            .firstOrNull ??
        open.firstOrNull;
    final rest = [
      for (final t in open)
        if (t.id != next?.id) t,
    ];

    return _DashCard(
      icon: Icons.task_alt,
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
              spacing: FitFatTokens.spaceS,
              children: [
                _Segments(done: done, total: tasks.length),
                if (next == null)
                  Row(
                    spacing: 10,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: theme.colorScheme.primary,
                      ),
                      Text(
                        l10n.dashboardAllDoneToday,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )
                else
                  _NowStrip(
                    task: next,
                    label: next == current
                        ? l10n.dashboardNowUntil(
                            _minutes(context, next.endTimeMinutes!),
                          )
                        : next.startTimeMinutes != null
                        ? l10n.dashboardNextAt(
                            _minutes(context, next.startTimeMinutes!),
                          )
                        : l10n.dashboardNextUp,
                  ),
                if (rest.isNotEmpty)
                  Column(
                    children: [
                      for (final t in rest.take(_maxRows)) _TaskLine(task: t),
                    ],
                  ),
                if (rest.length > _maxRows)
                  Text(
                    l10n.dashboardTasksMore(rest.length - _maxRows),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
              ],
            ),
    );
  }
}

/// One segment per task, filled for the done ones; a plain bar past twelve.
final class _Segments extends StatelessWidget {
  const _Segments({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (total > 12) return _Bar(done / total, height: 5);
    return Row(
      spacing: 3,
      children: [
        for (var i = 0; i < total; i++)
          Expanded(
            child: Container(
              height: 5,
              decoration: BoxDecoration(
                color: i < done
                    ? scheme.primary
                    : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
      ],
    );
  }
}

final class _NowStrip extends ConsumerWidget {
  const _NowStrip({required this.task, required this.label});

  final Task task;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: Color.lerp(scheme.surface, scheme.primary, 0.13),
      borderRadius: BorderRadius.circular(FitFatTokens.radiusS),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _push(context, PlannerItemDetailScreen(itemId: task.id)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 1,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontFeatures: _tabular,
                      ),
                    ),
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Checkbox(
                value: task.done,
                onChanged: (v) => _setDone(ref, task, v ?? false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A later task on one line: its start time (or "Anytime") and title.
final class _TaskLine extends StatelessWidget {
  const _TaskLine({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final start = task.startTimeMinutes;
    return InkWell(
      borderRadius: BorderRadius.circular(FitFatTokens.radiusS),
      onTap: () => _push(context, PlannerItemDetailScreen(itemId: task.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          spacing: FitFatTokens.spaceS,
          children: [
            SizedBox(
              width: 56,
              child: Text(
                start == null ? l10n.plannerAnytime : _minutes(context, start),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: muted,
                  fontFeatures: _tabular,
                ),
              ),
            ),
            Expanded(
              child: Text(
                task.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            if (task.workoutId != null)
              Icon(Icons.fitness_center, size: 14, color: muted),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Training
// ---------------------------------------------------------------------------

/// The next planned workout (with Start) or, when none, the latest finished
/// one (with ↻ to do it again); then a dot per training day this week and
/// the week's totals. A workout in progress is not shown here.
final class _TrainingCard extends ConsumerWidget {
  const _TrainingCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final pending = ref.watch(nextPendingWorkoutProvider).value;
    final latest = ref.watch(latestWorkoutProvider).value;
    final stats = ref.watch(weeklyWorkoutStatsProvider).value;
    final days = ref.watch(weekTrainingDaysProvider).value ?? const <int>{};
    final weightUnit = ref.watch(settingsProvider).weightUnit;
    final workout = pending ?? latest;

    Future<void> addWorkout() async {
      final saved = await _push(context, const WorkoutFormScreen());
      if (saved == true) {
        ref.invalidate(workoutListProvider);
        invalidateDashboard(ref);
      }
    }

    if (workout == null && (stats?.daysTrained ?? 0) == 0) {
      return _DashCard(
        icon: Icons.fitness_center,
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
      icon: Icons.fitness_center,
      label: l10n.dashboardTraining,
      trailing: l10n.dashboardThisWeek,
      onTap: () => context.go('/exercise'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: FitFatTokens.spaceM,
        children: [
          if (workout != null) _WorkoutRow(workout: workout),
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
                _Stat(l10n.trainingWorkouts, '${stats.workouts}'),
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

final class _WorkoutRow extends ConsumerWidget {
  const _WorkoutRow({required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final planned = workout.isPending;
    final date = DateFormats.formatDate(context, workout.date);
    return InkWell(
      borderRadius: BorderRadius.circular(FitFatTokens.radiusS),
      onTap: planned
          ? null
          : () => context.go('/workout-summary/${workout.id}'),
      child: Row(
        spacing: 10,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  workout.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  planned
                      ? l10n.dashboardPlannedOn(date)
                      : [
                          date,
                          if (workout.duration > Duration.zero)
                            l10n.dashboardDurationMin(
                              workout.duration.inMinutes,
                            ),
                        ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
              ],
            ),
          ),
          if (planned)
            FilledButton.tonal(
              onPressed: () => startWorkoutNow(
                context,
                ref,
                workoutId: workout.id,
                name: workout.name,
              ),
              child: Text(l10n.trainingStart),
            )
          else
            IconButton(
              icon: const Icon(Icons.replay),
              color: theme.colorScheme.primary,
              tooltip: l10n.trainingStartAgain,
              onPressed: () =>
                  startRoutine(context, ref, sourceWorkoutId: workout.id),
            ),
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

/// Latest weight with its change as a pill, Add weight next to it, then the
/// last 30 days as a line. Height is set in Settings › Profile.
final class _WeightCard extends ConsumerWidget {
  const _WeightCard();

  Future<void> _add(BuildContext context, WidgetRef ref) async {
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
      icon: Icons.monitor_weight_outlined,
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
          : _WeightSummary(
              entries: entries,
              unit: settings.weightUnit,
              goal: goal,
              onAdd: () => _add(context, ref),
            ),
    );
  }
}

final class _WeightSummary extends StatelessWidget {
  final List<BodyMetricsEntry> entries;
  final WeightUnit unit;
  final BodyWeightGoal? goal;
  final VoidCallback onAdd;
  const _WeightSummary({
    required this.entries,
    required this.unit,
    required this.onAdd,
    this.goal,
  });

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
    final muted = theme.colorScheme.onSurfaceVariant;
    final points = _points;
    final now = DateTime.now();
    final delta7 = _computeDelta(points, now, 7);
    final delta30 = _computeDelta(points, now, 30);
    final projection = _computeProjection(l10n, points, goal);
    final good = switch (goal) {
      BodyWeightGoal.gain => (double d) => d > 0,
      _ => (double d) => d < 0,
    };
    // The chart shows the last 30 days, or everything when that is too few.
    final cutoff = now.subtract(const Duration(days: 30));
    final recent = points.where((p) => p.$1.isAfter(cutoff)).toList();
    final shown = recent.length > 1 ? recent : points;
    final delta = delta30 ?? delta7;
    final deltaLabel = delta30 != null
        ? l10n.dashboardDelta30d(_deltaText(delta30, unit))
        : delta7 != null
        ? l10n.dashboardDelta7d(_deltaText(delta7, unit))
        : null;
    final pillColor = delta == null
        ? muted
        : good(delta)
        ? colors.success
        : colors.warning;
    final small = theme.textTheme.bodySmall?.copyWith(
      color: muted,
      fontFeatures: _tabular,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FitFatTokens.spaceS,
      children: [
        Row(
          spacing: FitFatTokens.spaceM,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: formatWeightValue(
                            entries
                                .lastWhere((e) => e.weightKg != null)
                                .weightKg!,
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
                            color: muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (deltaLabel != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: pillColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(
                          FitFatTokens.radiusFull,
                        ),
                      ),
                      child: Text(
                        deltaLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: pillColor,
                          fontWeight: FontWeight.w600,
                          fontFeatures: _tabular,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.bodyMetricsAddWeight),
            ),
          ],
        ),
        if (shown.length > 1) ...[
          SizedBox(height: 58, child: _WeightLineChart(points: shown)),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${DateFormats.formatDate(context, shown.first.$1)} · '
                  '${shown.first.$2.toStringAsFixed(1)}',
                  style: small,
                ),
              ),
              if (projection != null) Text(projection, style: small),
            ],
          ),
        ],
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
        ..color = color.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    final last = points.last;
    canvas.drawCircle(
      project(last.$1.millisecondsSinceEpoch.toDouble(), last.$2),
      3.5,
      Paint()..color = color,
    );
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

/// How far [g] is behind a straight line from its start to its end date
/// (0..1, negative when ahead); null without an end date or progress.
double? goalPaceGap(Goal g, double? progress, DateTime now) {
  final end = g.endDate;
  if (end == null || progress == null) return null;
  final span = end.difference(g.startDate).inMinutes;
  if (span <= 0) return null;
  final expected = (now.difference(g.startDate).inMinutes / span).clamp(
    0.0,
    1.0,
  );
  return expected - progress;
}

/// The goal most behind its pace, with what it takes to catch up, then the
/// other active goals as one-line rows.
final class _GoalsCard extends ConsumerWidget {
  const _GoalsCard();

  static const _maxRows = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final goals = ref.watch(goalListProvider).value ?? const <Goal>[];
    final active = goals.where((g) => g.isActive).toList();
    final now = DateTime.now();
    final statuses = {
      for (final g in active) g.id: ref.watch(goalStatusProvider(g.id)).value,
    };
    Goal? featured;
    var worst = double.negativeInfinity;
    for (final g in active) {
      final gap = goalPaceGap(g, statuses[g.id]?.progress, now);
      if (gap != null && gap > worst) {
        worst = gap;
        featured = g;
      }
    }
    featured ??= active.firstOrNull;
    final others = [
      for (final g in active)
        if (g.id != featured?.id) g,
    ];
    return _DashCard(
      icon: Icons.flag_outlined,
      label: l10n.dashboardGoalsTitle,
      trailing: active.isEmpty
          ? null
          : l10n.dashboardGoalsActive(active.length),
      onTap: () => context.go('/plan'),
      child: featured == null
          ? _EmptyStart(
              message: l10n.dashboardGoalsEmptyHint,
              actionLabel: l10n.dashboardSetGoal,
              icon: Icons.flag_outlined,
              onAction: () => context.go('/plan'),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: FitFatTokens.spaceS,
              children: [
                _FeaturedGoal(goal: featured, status: statuses[featured.id]),
                for (final g in others.take(_maxRows))
                  _GoalLine(goal: g, status: statuses[g.id]),
                if (others.length > _maxRows)
                  Text(
                    l10n.dashboardTasksMore(others.length - _maxRows),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
              ],
            ),
    );
  }
}

final class _FeaturedGoal extends StatelessWidget {
  const _FeaturedGoal({required this.goal, required this.status});

  final Goal goal;
  final GoalStatusView? status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = theme.extension<FitFatColors>()!;
    final s = status;
    final end = goal.endDate;
    final gap = goalPaceGap(goal, s?.progress, DateTime.now());
    Widget? pace;
    if (gap != null && s != null) {
      final behind = gap > 0.05;
      String text = l10n.dashboardGoalOnPace;
      if (behind) {
        final weeks = end!.difference(DateTime.now()).inDays / 7;
        final left = (goal.targetValue ?? 0) - (s.current ?? 0);
        final unit = goalUnit(goal);
        final perWeek = weeks >= 1 ? left / weeks : left;
        final amount =
            '${perWeek >= 0 ? '+' : ''}${formatGoalNumber(context, perWeek)}'
            '${unit.isEmpty ? '' : ' $unit'}';
        text = l10n.dashboardGoalBehind(amount);
      }
      final color = behind ? colors.warning : colors.success;
      pace = Row(
        spacing: 4,
        children: [
          Icon(
            behind ? Icons.error_outline : Icons.check_circle_outline,
            size: 14,
            color: color,
          ),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
      );
    } else if (s != null) {
      pace = GoalSourceLine(goal: goal, status: s);
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(FitFatTokens.radiusS),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 6,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            spacing: FitFatTokens.spaceS,
            children: [
              Expanded(
                child: Text(
                  goal.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (end != null)
                Text(
                  l10n.dashboardGoalBy(
                    MaterialLocalizations.of(context).formatMonthYear(end),
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          if (s != null) GoalProgressBar(goal: goal, status: s),
          ?pace,
        ],
      ),
    );
  }
}

final class _GoalLine extends StatelessWidget {
  const _GoalLine({required this.goal, required this.status});

  final Goal goal;
  final GoalStatusView? status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final s = status;
    final p = s?.progress;
    return Row(
      spacing: FitFatTokens.spaceS,
      children: [
        Expanded(
          child: Text(
            goal.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        if (s != null)
          Flexible(
            child: Text(
              goalValueText(context, goal, s),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: muted,
                fontFeatures: _tabular,
              ),
            ),
          ),
        SizedBox(
          width: 38,
          child: Text(
            p == null ? '–' : '${(p * 100).round()}%',
            textAlign: TextAlign.right,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontFeatures: _tabular,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Money
// ---------------------------------------------------------------------------

/// This month's spending against income: the filled part of the bar is split
/// by category (the Money tab's colors), the top three are named, then net
/// worth and the days left in the month. Accounts come from the server, so
/// the empty state offers a sync.
final class _MoneyCard extends ConsumerWidget {
  const _MoneyCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurfaceVariant;
    final overview = ref.watch(budgetOverviewProvider).value;
    final currency = ref.watch(settingsProvider).baseCurrency;
    final now = DateTime.now();
    final month = MaterialLocalizations.of(context).formatMonthYear(now);

    if (overview == null || overview.accounts.isEmpty) {
      return _DashCard(
        icon: Icons.account_balance_wallet_outlined,
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
    final cats = overview.monthExpenseByCategory;
    final daysLeft = DateTime(now.year, now.month + 1, 0).day - now.day;
    final small = theme.textTheme.bodySmall?.copyWith(
      color: muted,
      fontFeatures: _tabular,
    );
    String catName(String c) => c.isEmpty ? l10n.dashboardSpent : c;
    return _DashCard(
      icon: Icons.account_balance_wallet_outlined,
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
                formatMoneyIn(context, spent, currency),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: _tabular,
                ),
              ),
              Text(
                l10n.dashboardSpent,
                style: theme.textTheme.bodyMedium?.copyWith(color: muted),
              ),
              const Spacer(),
              if (income > 0)
                Flexible(
                  child: Text(
                    l10n.dashboardOfIncome(
                      formatMoneyIn(context, income, currency),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: small,
                  ),
                ),
            ],
          ),
          if (spent > 0 || income > 0)
            _SpendBar(
              spent: spent,
              income: income,
              categories: cats,
              label: income <= 0
                  ? null
                  : spent > income
                  ? l10n.dashboardAmountOver(
                      formatMoneyIn(context, spent - income, currency),
                    )
                  : l10n.dashboardAmountLeft(
                      formatMoneyIn(context, income - spent, currency),
                    ),
            ),
          if (cats.isNotEmpty)
            Wrap(
              spacing: 10,
              runSpacing: 2,
              children: [
                for (final (c, v) in cats.take(3))
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 4,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: categoryColor(context, c),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Text('${catName(c)} ${_whole(context, v)}', style: small),
                    ],
                  ),
                if (cats.length > 3)
                  Text(l10n.dashboardTasksMore(cats.length - 3), style: small),
              ],
            ),
          Container(
            padding: const EdgeInsets.only(top: FitFatTokens.spaceS),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: scheme.outlineVariant)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${l10n.budgetNetWorth} '
                    '${formatMoneyIn(context, overview.netWorth, currency)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: small,
                  ),
                ),
                Text(l10n.dashboardDaysLeftInMonth(daysLeft), style: small),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Spending as a share of income, the filled part split by category; with
/// no income the categories fill the bar.
final class _SpendBar extends StatelessWidget {
  const _SpendBar({
    required this.spent,
    required this.income,
    required this.categories,
    this.label,
  });

  final double spent;
  final double income;
  final List<(String, double)> categories;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final share = income > 0 ? (spent / income).clamp(0.0, 1.0) : 1.0;
    final over = income > 0 && spent > income;
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: SizedBox(
        height: 18,
        child: LayoutBuilder(
          builder: (context, box) => Stack(
            children: [
              Positioned.fill(
                child: ColoredBox(color: scheme.surfaceContainerHighest),
              ),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: box.maxWidth * share,
                child: Row(
                  spacing: 1,
                  children: [
                    for (final (c, v) in categories)
                      if (v > 0)
                        Expanded(
                          flex: math.max(1, v.round()),
                          child: ColoredBox(
                            color: Color.lerp(
                              scheme.surface,
                              categoryColor(context, c),
                              0.65,
                            )!,
                          ),
                        ),
                  ],
                ),
              ),
              if (label != null)
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        label!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: over ? scheme.error : scheme.onSurfaceVariant,
                          fontWeight: over ? FontWeight.w600 : null,
                          fontFeatures: _tabular,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
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
