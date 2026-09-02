import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../notifications/rest_timer.dart';
import '../../settings/providers/settings.dart';
import '../../ui/format.dart';
import '../../ui/theme_extensions.dart';
import '../../ui/units.dart';
import '../../ui/widgets/empty_state.dart';
import '../../ui/widgets/status_badge.dart';
import '../../ui/widgets/top_banner.dart';
import '../providers/workout_templates.dart';
import '../providers/workouts.dart';
import '../repositories/workout_repository.dart';
import 'workout_form.dart';

/// Read-only summary of a completed workout (active-workout-flow T07). Lives
/// on the top-level `/workout-summary/:id` GoRouter route, outside the shell,
/// so the floating bar and `NavigationBar` are not rendered on it. Watches
/// [workoutDetailProvider] and renders per-exercise metrics (average rest,
/// total volume, max weight, total reps — duration/distance for cardio)
/// computed from real logged data only.
final class WorkoutSummaryScreen extends ConsumerWidget {
  final String workoutId;

  const WorkoutSummaryScreen({super.key, required this.workoutId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final detailAsync = ref.watch(workoutDetailProvider(workoutId));

    return detailAsync.when(
      loading: () => _statusScaffold(
        context: context,
        l10n: l10n,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => _statusScaffold(
        context: context,
        l10n: l10n,
        body: Center(child: Text(l10n.errorWithMessage('$e'))),
      ),
      data: (detail) {
        if (detail == null) {
          return _statusScaffold(
            context: context,
            l10n: l10n,
            body: Center(child: Text(l10n.workoutDetailNotFound)),
          );
        }
        return _WorkoutSummaryContent(detail: detail, l10n: l10n);
      },
    );
  }
}

/// Scaffold for the loading / error / not-found states: summary title plus a
/// back affordance that pops when a route is below, else returns to the
/// workout list (the summary is usually reached via `context.go`, which leaves
/// nothing to pop to).
Scaffold _statusScaffold({
  required BuildContext context,
  required AppLocalizations l10n,
  required Widget body,
}) {
  return Scaffold(
    appBar: AppBar(
      title: Text(l10n.workoutSummaryAppBar),
      actions: [
        TextButton(
          onPressed: () => context.go('/exercise'),
          child: Text(l10n.workoutSummaryDone),
        ),
      ],
      leading: BackButton(
        onPressed: () {
          final navigator = Navigator.of(context);
          if (navigator.canPop()) {
            navigator.pop();
          } else {
            context.go('/exercise');
          }
        },
      ),
    ),
    body: body,
  );
}

final class _WorkoutSummaryContent extends ConsumerWidget {
  final WorkoutWithDetails detail;
  final AppLocalizations l10n;

  const _WorkoutSummaryContent({required this.detail, required this.l10n});

  /// Saves this session's current plan as a reusable template.
  Future<void> _saveAsTemplate(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final templateId = await ref
          .read(workoutRepositoryProvider)
          .saveAsTemplate(workoutId: detail.workout.id);
      ref.invalidate(workoutTemplateListProvider);
      ref.invalidate(workoutTemplateDetailsProvider(templateId));
      if (!context.mounted) return;
      showTopBanner(context, message: l10n.templatesSavedAsTemplate);
    } catch (e) {
      if (!context.mounted) return;
      showTopBanner(context, message: l10n.errorWithMessage('$e'));
    }
  }

  /// Creates the next replay occurrence (prefill per the replay-prefill
  /// setting) and opens it in the editable workout form.
  Future<void> _replay(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final prefill = ref.read(settingsProvider).replayPrefill;
      final created = await ref
          .read(workoutRepositoryProvider)
          .replayWorkout(sourceWorkoutId: detail.workout.id, prefill: prefill);
      ref.invalidate(workoutListProvider);
      if (!context.mounted) return;
      final newDetail = await ref.read(
        workoutDetailProvider(created.id).future,
      );
      if (newDetail == null || !context.mounted) return;
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => WorkoutFormScreen(initial: newDetail),
        ),
      );
      if (context.mounted) ref.invalidate(workoutListProvider);
    } catch (e) {
      if (context.mounted) {
        showTopBanner(context, message: l10n.errorWithMessage('$e'));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final w = detail.workout;
    final theme = Theme.of(context);
    final statusColors = theme.extension<FitFatColors>()!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.workoutSummaryAppBar),
        actions: [
          IconButton(
            tooltip: l10n.workoutSummaryDoAgain,
            icon: const Icon(Icons.replay),
            onPressed: () => _replay(context, ref),
          ),
          IconButton(
            tooltip: l10n.templatesTitle,
            icon: const Icon(Icons.bookmark_add_outlined),
            onPressed: () => _saveAsTemplate(context, ref),
          ),
          TextButton(
            onPressed: () => context.go('/exercise'),
            child: Text(l10n.workoutSummaryDone),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header: workout name, completed badge, total duration.
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          w.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      StatusBadge(
                        label: l10n.statusCompleted,
                        color: statusColors.success,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _MetricRow(
                    label: l10n.workoutSummaryDurationLabel,
                    value: formatRestDuration(w.duration),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(l10n.workoutDetailExercises, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (detail.exercises.isEmpty)
            EmptyState(
              icon: Icons.fitness_center,
              title: l10n.emptyWorkoutDetailTitle,
              description: l10n.emptyWorkoutDetailBody,
            )
          else
            for (final block in detail.exercises)
              _ExerciseSummaryCard(block: block, l10n: l10n),
        ],
      ),
    );
  }
}

final class _ExerciseSummaryCard extends ConsumerWidget {
  final ExerciseBlock block;
  final AppLocalizations l10n;

  const _ExerciseSummaryCard({required this.block, required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final metrics = _ExerciseMetrics.fromBlock(block);
    final unit = ref.watch(settingsProvider).weightUnit;
    final unitLabel = weightUnitLabel(unit);
    // Cardio classification: the app classifies per set (workout_detail /
    // active_workout_screen); the summary's natural unit is the exercise, so
    // an exercise is cardio when any of its sets logged duration or distance,
    // otherwise it is weightlifting.
    final isCardio = block.sets.any(
      (s) => s.durationMinutes != null || s.distanceMeters != null,
    );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              block.exercise.exerciseName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            // Hidden entirely when no set logged rest — a planned-only value
            // would suggest work that never happened.
            if (metrics.averageRestSeconds != null)
              _MetricRow(
                label: l10n.workoutSummaryAvgRest,
                value: formatRestDuration(
                  Duration(seconds: metrics.averageRestSeconds!),
                ),
              ),
            if (isCardio) ...[
              _MetricRow(
                label: l10n.workoutSummaryTotalDuration,
                value: formatRestDuration(
                  Duration(minutes: metrics.totalDurationMinutes),
                ),
              ),
              _MetricRow(
                label: l10n.workoutSummaryTotalDistance,
                value: l10n.workoutSummaryDistanceValue(
                  formatDecimal(metrics.totalDistanceMeters),
                ),
              ),
            ] else ...[
              _MetricRow(
                label: l10n.workoutSummaryVolume,
                value: l10n.workoutSummaryValueKg(
                  formatWeightValue(metrics.totalVolume, unit),
                  unitLabel,
                ),
              ),
              _MetricRow(
                label: l10n.workoutSummaryMaxWeight,
                value: l10n.workoutSummaryValueKg(
                  formatWeightValue(metrics.maxWeightKg, unit),
                  unitLabel,
                ),
              ),
              _MetricRow(
                label: l10n.workoutSummaryTotalReps,
                value: '${metrics.totalReps}',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Label/value row used for every summary metric (label on the left, value
/// right-aligned with tabular figures so numbers stay aligned).
final class _MetricRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetricRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Per-exercise summary metrics computed from the logged sets. All values are
/// derived from actual data only: a set with no logged actuals contributes 0
/// (it was not done at all), never its planned values.
final class _ExerciseMetrics {
  /// Mean rest in seconds over the sets that actually logged rest. Null when
  /// no set recorded an actual rest — planned rest never counts, and the
  /// metric row is hidden entirely instead of showing a placeholder.
  final int? averageRestSeconds;

  final double totalVolume;
  final double maxWeightKg;
  final int totalReps;
  final int totalDurationMinutes;
  final double totalDistanceMeters;

  const _ExerciseMetrics({
    required this.averageRestSeconds,
    required this.totalVolume,
    required this.maxWeightKg,
    required this.totalReps,
    required this.totalDurationMinutes,
    required this.totalDistanceMeters,
  });

  factory _ExerciseMetrics.fromBlock(ExerciseBlock block) {
    // Actual rest only: an unlogged set contributes nothing (its planned
    // rest is not evidence that any rest happened).
    final rests = <int>[
      for (final set in block.sets)
        if (set.actualRestSeconds != null) set.actualRestSeconds!,
    ];

    var totalVolume = 0.0;
    var maxWeightKg = 0.0;
    var totalReps = 0;
    var totalDurationMinutes = 0;
    var totalDistanceMeters = 0.0;
    for (final set in block.sets) {
      totalVolume += set.totalVolume;
      if (set.effectiveWeightKg > maxWeightKg) {
        maxWeightKg = set.effectiveWeightKg;
      }
      totalReps += set.effectiveReps;
      // Cardio actuals are stored in dedicated actual columns; summing the
      // effective (actual-only) values means unlogged sets contribute 0.
      totalDurationMinutes += set.effectiveDurationMinutes;
      totalDistanceMeters += set.effectiveDistanceMeters;
    }

    return _ExerciseMetrics(
      averageRestSeconds: rests.isEmpty
          ? null
          : (rests.reduce((a, b) => a + b) / rests.length).round(),
      totalVolume: totalVolume,
      maxWeightKg: maxWeightKg,
      totalReps: totalReps,
      totalDurationMinutes: totalDurationMinutes,
      totalDistanceMeters: totalDistanceMeters,
    );
  }
}
