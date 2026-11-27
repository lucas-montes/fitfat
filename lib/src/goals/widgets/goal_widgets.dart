import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../budget/providers/accounts.dart';
import '../../exercise/providers/exercises.dart';
import '../../models/goal.dart';
import '../../ui/theme_extensions.dart';
import '../../ui/tokens.dart';
import '../providers/goals.dart';
import '../services/goal_tracking.dart';

/// "85", "6.5", "1,860": whole numbers without decimals, else one.
String formatGoalNumber(BuildContext context, double v) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  final f = NumberFormat.decimalPattern(locale)
    ..maximumFractionDigits = v.abs() >= 100 ? 0 : 1;
  return f.format(v);
}

String goalUnit(Goal g) =>
    g.unit ?? TrackSource.parse(g.trackSource)?.unit ?? '';

/// "85 / 100 kg", or "Done" for a finished goal.
String goalValueText(BuildContext context, Goal g, GoalStatusView s) {
  final l10n = AppLocalizations.of(context)!;
  if (g.targetType == GoalTargetType.boolean) {
    return (s.current ?? 0) >= 1 ? l10n.goalsAchieved : l10n.goalsNotAchieved;
  }
  final unit = goalUnit(g);
  final cur = s.current == null ? '–' : formatGoalNumber(context, s.current!);
  if (g.targetValue == null) return unit.isEmpty ? cur : '$cur $unit';
  final tgt = formatGoalNumber(context, g.targetValue!);
  return unit.isEmpty ? '$cur / $tgt' : '$cur / $tgt $unit';
}

/// The goal's progress as a bar with the value inside and the % at the end.
class GoalProgressBar extends StatelessWidget {
  const GoalProgressBar({
    super.key,
    required this.goal,
    required this.status,
    this.height = 20,
  });

  final Goal goal;
  final GoalStatusView status;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final success = theme.extension<FitFatColors>()?.success ?? scheme.primary;
    final done = goal.status == GoalStatus.done;
    final p = done ? 1.0 : (status.progress ?? 0);
    final fill = Color.lerp(
      scheme.surface,
      done ? success : scheme.primary,
      0.58,
    )!;
    final style = theme.textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w600,
      fontFeatures: const [FontFeature.tabularFigures()],
      height: 1,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: SizedBox(
        height: height,
        child: LayoutBuilder(
          builder: (context, box) {
            // A small minimum keeps the value readable once there is any
            // progress; nothing recorded yet leaves the bar empty.
            final w = status.current == null && !done
                ? 0.0
                : (box.maxWidth * p).clamp(box.maxWidth * 0.18, box.maxWidth);
            return Stack(
              children: [
                Positioned.fill(
                  child: ColoredBox(color: scheme.surfaceContainerHighest),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: w,
                  child: ColoredBox(color: fill),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            goalValueText(context, goal, status),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: style,
                          ),
                        ),
                        if (status.progress != null)
                          Text(
                            '${(p * 100).round()}%',
                            style: style?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// "Auto · best Bench press set · updated Tue" or "Manual · last 6 days ago".
class GoalSourceLine extends ConsumerWidget {
  const GoalSourceLine({super.key, required this.goal, required this.status});

  final Goal goal;
  final GoalStatusView status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final source = TrackSource.parse(goal.trackSource);
    String? what;
    if (source != null && source.needsExercise && goal.trackParam != null) {
      what = ref.watch(exerciseByIdProvider(goal.trackParam!)).value?.name;
    }
    if (source != null && source.needsAccount && goal.trackParam != null) {
      what = ref
          .watch(accountListProvider)
          .value
          ?.where((a) => a.id == goal.trackParam)
          .firstOrNull
          ?.name;
    }
    final label = source == null
        ? l10n.goalSourceManual
        : trackSourceLabel(l10n, source, what);
    final when = status.updated == null
        ? null
        : relativeDay(context, status.updated!);
    return Row(
      spacing: 4,
      children: [
        Icon(
          source == null ? Icons.back_hand_outlined : Icons.bolt,
          size: 14,
          color: muted,
        ),
        Expanded(
          child: Text(
            [
              label,
              if (when != null)
                source == null ? l10n.goalLast(when) : l10n.goalUpdated(when),
            ].join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
        ),
      ],
    );
  }
}

/// "today", "yesterday", "Tue", "21 Nov".
String relativeDay(BuildContext context, DateTime d) {
  final l10n = AppLocalizations.of(context)!;
  final locale = Localizations.localeOf(context).toLanguageTag();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return l10n.goalToday;
  if (diff == 1) return l10n.goalYesterday;
  if (diff < 7) return DateFormat.E(locale).format(day);
  return DateFormat.MMMd(locale).format(day);
}

String trackSourceLabel(AppLocalizations l10n, TrackSource s, String? what) =>
    switch (s) {
      TrackSource.exerciseBest => l10n.goalSourceExerciseBest(what ?? '?'),
      TrackSource.exerciseDistance => l10n.goalSourceExerciseDistance(
        what ?? '?',
      ),
      TrackSource.workoutsCount => l10n.goalSourceWorkouts,
      TrackSource.bodyWeight => l10n.goalSourceBodyWeight,
      TrackSource.accountBalance => l10n.goalSourceAccount(what ?? '?'),
      TrackSource.mealsProtein => l10n.goalSourceProtein,
      TrackSource.tasksDone => l10n.goalSourceTasks,
    };

void invalidateGoal(WidgetRef ref, String goalId) {
  ref.invalidate(goalProgressProvider(goalId));
  ref.invalidate(latestGoalProgressProvider(goalId));
  ref.invalidate(goalStatusProvider(goalId));
}

/// Records [value] for a manual goal today (re-recording the same day
/// replaces it).
Future<void> recordGoalValue(
  WidgetRef ref,
  String goalId,
  double value, {
  DateTime? day,
}) async {
  await ref
      .read(goalRepositoryProvider)
      .recordProgress(goalId: goalId, day: day ?? DateTime.now(), value: value);
  invalidateGoal(ref, goalId);
}

/// The step button's action: +1 on a numeric goal, "achieved" on a yes/no one.
Future<void> stepGoal(WidgetRef ref, Goal g, GoalStatusView s) =>
    recordGoalValue(
      ref,
      g.id,
      g.targetType == GoalTargetType.boolean
          ? 1
          : (s.current ?? g.baselineValue ?? 0) + 1,
    );

/// Long-press: type an exact value and the day it was reached.
Future<void> showRecordValueSheet(
  BuildContext context,
  WidgetRef ref,
  Goal g,
  GoalStatusView s,
) async {
  final l10n = AppLocalizations.of(context)!;
  final ctrl = TextEditingController(
    text: s.current == null
        ? ''
        : (s.current! == s.current!.roundToDouble()
              ? s.current!.toStringAsFixed(0)
              : s.current!.toString()),
  );
  var day = DateTime.now();
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) => Padding(
        padding: EdgeInsets.fromLTRB(
          FitFatTokens.spaceL,
          0,
          FitFatTokens.spaceL,
          FitFatTokens.spaceL + MediaQuery.viewInsetsOf(ctx).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: FitFatTokens.spaceM,
          children: [
            Text(g.title, style: Theme.of(ctx).textTheme.titleMedium),
            TextField(
              key: const ValueKey('goalValueField'),
              controller: ctrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l10n.goalsCurrentValueLabel,
                suffixText: goalUnit(g),
              ),
            ),
            ActionChip(
              avatar: const Icon(Icons.event_outlined, size: 16),
              label: Text(relativeDay(ctx, day)),
              onPressed: () async {
                final d = await showDatePicker(
                  context: ctx,
                  initialDate: day,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (d != null) setSheet(() => day = d);
              },
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.commonSave),
            ),
          ],
        ),
      ),
    ),
  );
  final v = double.tryParse(ctrl.text.trim().replaceAll(',', '.'));
  ctrl.dispose();
  if (saved == true && v != null) {
    await recordGoalValue(ref, g.id, v, day: day);
  }
}

IconData trackSourceIcon(TrackSource s) => switch (s) {
  TrackSource.exerciseBest => Icons.fitness_center,
  TrackSource.exerciseDistance => Icons.directions_run,
  TrackSource.workoutsCount => Icons.event_repeat,
  TrackSource.bodyWeight => Icons.monitor_weight_outlined,
  TrackSource.accountBalance => Icons.savings_outlined,
  TrackSource.mealsProtein => Icons.restaurant_outlined,
  TrackSource.tasksDone => Icons.task_alt,
};

String trackSourceName(AppLocalizations l10n, TrackSource s) => switch (s) {
  TrackSource.exerciseBest => l10n.goalTrackExerciseBest,
  TrackSource.exerciseDistance => l10n.goalTrackExerciseDistance,
  TrackSource.workoutsCount => l10n.goalTrackWorkouts,
  TrackSource.bodyWeight => l10n.goalTrackBodyWeight,
  TrackSource.accountBalance => l10n.goalTrackAccount,
  TrackSource.mealsProtein => l10n.goalTrackProtein,
  TrackSource.tasksDone => l10n.goalTrackTasks,
};

String trackSourceHint(AppLocalizations l10n, TrackSource s) => switch (s) {
  TrackSource.exerciseBest => l10n.goalTrackExerciseBestHint,
  TrackSource.exerciseDistance => l10n.goalTrackExerciseDistanceHint,
  TrackSource.workoutsCount => l10n.goalTrackWorkoutsHint,
  TrackSource.bodyWeight => l10n.goalTrackBodyWeightHint,
  TrackSource.accountBalance => l10n.goalTrackAccountHint,
  TrackSource.mealsProtein => l10n.goalTrackProteinHint,
  TrackSource.tasksDone => l10n.goalTrackTasksHint,
};
