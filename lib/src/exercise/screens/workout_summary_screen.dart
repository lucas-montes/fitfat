import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../body/providers/body_metrics.dart';
import '../../models/exercise_set.dart';
import '../../notifications/rest_timer.dart';
import '../../settings/providers/settings.dart';
import '../../ui/theme_extensions.dart';
import '../../ui/units.dart';
import '../../ui/widgets/empty_state.dart';
import '../../ui/widgets/status_badge.dart';
import '../../ui/widgets/top_banner.dart';
import '../../dashboard/providers/dashboard.dart';
import '../providers/exercises.dart';
import '../providers/workout_templates.dart';
import '../providers/workouts.dart';
import '../repositories/workout_repository.dart';
import '../services/workout_energy.dart';
import '../widgets/set_actuals_dialog.dart';
import '../../dashboard/screens/dashboard.dart' show formatWeeklyDuration;
import '../../models/workout.dart';
import '../../ui/date_formats.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets/confirm_delete.dart';
import '../../ui/widgets/form_scaffold.dart';
import '../providers/training.dart';
import '../start_workout.dart';
import '../widgets/training_widgets.dart';
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
        body: const SizedBox.shrink(),
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

  Future<void> _saveAsTemplate(BuildContext context, WidgetRef ref) async {
    try {
      final templateId = await ref
          .read(workoutRepositoryProvider)
          .saveAsTemplate(workoutId: detail.workout.id);
      ref.invalidate(workoutTemplateListProvider);
      ref.invalidate(workoutTemplateDetailsProvider(templateId));
    } catch (e) {
      if (!context.mounted) return;
      showTopBanner(context, message: l10n.errorWithMessage('$e'));
    }
  }

  Future<void> _duplicate(WidgetRef ref) async {
    await ref
        .read(workoutRepositoryProvider)
        .copyWorkout(sourceWorkoutId: detail.workout.id);
    ref.invalidate(workoutListProvider);
  }

  /// Opens the completed workout in the form, which edits its **actuals** while
  /// preserving ids and planned values.
  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => WorkoutFormScreen(initial: detail)),
    );
    if (saved == true) {
      ref.invalidate(workoutDetailProvider(detail.workout.id));
      ref.invalidate(workoutListProvider);
      invalidateDashboard(ref);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, int sets) async {
    final w = detail.workout;
    final router = GoRouter.of(context);
    WorkoutSnapshot? snapshot;
    final deleted = await confirmDelete(
      context,
      itemName: w.name,
      cascade: [(label: l10n.trainingCascadeSetsDone, count: sets)],
      delete: () async {
        snapshot = await ref
            .read(workoutRepositoryProvider)
            .deleteWithSnapshot(w.id);
        ref.invalidate(workoutListProvider);
        invalidateDashboard(ref);
      },
      undo: () async {
        if (snapshot == null) return;
        await ref.read(workoutRepositoryProvider).restore(snapshot!);
        ref.invalidate(workoutListProvider);
        invalidateDashboard(ref);
      },
    );
    if (deleted) router.go('/exercise');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final w = detail.workout;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = theme.extension<FitFatColors>()!;
    final muted = scheme.onSurfaceVariant;
    final unit = ref.watch(settingsProvider).weightUnit;
    final energy = estimateWorkoutEnergy(
      detail: detail,
      exerciseById: (id) => ref.watch(exerciseByIdProvider(id)).value,
      weightKg: ref.watch(latestBodyMetricsProvider).value?.weightKg,
    );
    final prSets =
        ref.watch(workoutPrSetsProvider(w.id)).value ?? const <String>{};
    final template = w.templateId == null
        ? null
        : ref.watch(workoutTemplateDetailsProvider(w.templateId!)).value;

    // Totals across exercises.
    final metrics = [
      for (final b in detail.exercises) _ExerciseMetrics.fromBlock(b),
    ];
    final volume = metrics.fold(0.0, (a, m) => a + m.totalVolume);
    final distanceKm =
        metrics.fold(0.0, (a, m) => a + m.totalDistanceMeters) / 1000;
    final setsDone = detail.exercises.fold(
      0,
      (a, b) => a + b.sets.where((s) => s.isCompleted).length,
    );
    final rests = [
      for (final b in detail.exercises)
        for (final s in b.sets)
          if (s.actualRestSeconds != null) s.actualRestSeconds!,
    ];
    final avgRest = rests.isEmpty
        ? null
        : Duration(
            seconds: (rests.reduce((a, b) => a + b) / rests.length).round(),
          );

    // Change vs the previous workout of the same routine (or name).
    final workouts = ref.watch(workoutListProvider).value ?? const <Workout>[];
    final summaries = ref.watch(workoutRowSummariesProvider).value;
    Workout? previous;
    for (final o in workouts) {
      final same = w.routineId != null
          ? o.routineId == w.routineId
          : o.name.trim().toLowerCase() == w.name.trim().toLowerCase();
      if (o.id == w.id || !o.isCompleted || !same || !o.date.isBefore(w.date)) {
        continue;
      }
      if (previous == null || o.date.isAfter(previous.date)) previous = o;
    }
    final prevVolume = previous == null
        ? null
        : summaries?[previous.id]?.volumeKg;
    final change = prevVolume == null || prevVolume <= 0 || volume <= 0
        ? null
        : (volume - prevVolume) / prevVolume;

    // PR line: the best PR set of the workout.
    String? prLine;
    if (prSets.isNotEmpty) {
      ExerciseSet? best;
      String? bestName;
      for (final b in detail.exercises) {
        for (final s in b.sets) {
          if (!prSets.contains(s.id)) continue;
          if (best == null || s.effectiveWeightKg > best.effectiveWeightKg) {
            best = s;
            bestName = b.exercise.exerciseName;
          }
        }
      }
      prLine = l10n.workoutDetailPrLine(
        prSets.length,
        '$bestName ${formatWeightValue(best!.effectiveWeightKg, unit)} '
        '${weightUnitLabel(unit)} × ${best.effectiveReps}',
      );
    }

    final time = TimeOfDay.fromDateTime;
    final range = w.startedAt != null && w.completedAt != null
        ? '${DateFormats.formatTime(context, time(w.startedAt!))}–'
              '${DateFormats.formatTime(context, time(w.completedAt!))}'
        : null;

    Widget stat(String label, String value) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 2,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            style: theme.textTheme.labelSmall?.copyWith(
              color: muted,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          Text(
            value,
            maxLines: 1,
            style: theme.textTheme.titleSmall?.copyWith(fontFeatures: _tab),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(w.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        leading: BackButton(
          onPressed: () {
            final navigator = Navigator.of(context);
            navigator.canPop() ? navigator.pop() : context.go('/exercise');
          },
        ),
        actions: [
          IconButton(
            tooltip: l10n.trainingStartAgain,
            icon: const Icon(Icons.repeat),
            onPressed: () => startRoutine(context, ref, sourceWorkoutId: w.id),
          ),
          PopupMenuButton<VoidCallback>(
            onSelected: (f) => f(),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: () => _edit(context, ref),
                child: Text(l10n.commonEdit),
              ),
              PopupMenuItem(
                value: () => _saveAsTemplate(context, ref),
                child: Text(l10n.workoutDetailSaveTemplate),
              ),
              PopupMenuItem(
                value: () => _duplicate(ref),
                child: Text(l10n.workoutActionDuplicate),
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: FitFatTokens.kContentMaxWidth,
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              FitFatTokens.spaceL,
              FitFatTokens.spaceS,
              FitFatTokens.spaceL,
              FitFatTokens.spaceXxl,
            ),
            children: [
              // Summary of the whole workout.
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(FitFatTokens.spaceL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: FitFatTokens.spaceM,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              [
                                DateFormats.formatDate(context, w.date),
                                ?range,
                              ].join(' · '),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: muted,
                              ),
                            ),
                          ),
                          StatusBadge(
                            label: l10n.statusCompleted,
                            color: colors.success,
                          ),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        spacing: FitFatTokens.spaceS,
                        children: [
                          Text(
                            volume > 0
                                ? formatVolume(volume, unit)
                                : '${distanceKm.toStringAsFixed(1)} km',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontFeatures: _tab,
                            ),
                          ),
                          if (change != null)
                            Flexible(
                              child: Text(
                                l10n.workoutDetailVsLast(
                                  '${change >= 0 ? '+' : '−'}'
                                  '${(change.abs() * 100).round()}%',
                                ),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: change >= 0
                                      ? colors.success
                                      : colors.warning,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Row(
                        children: [
                          stat(
                            l10n.workoutDetailTime,
                            formatWeeklyDuration(l10n, w.duration.inMinutes),
                          ),
                          stat(l10n.workoutDetailSets, '$setsDone'),
                          stat(
                            l10n.workoutDetailAvgRest,
                            avgRest == null ? '–' : formatRestDuration(avgRest),
                          ),
                          stat(
                            l10n.workoutDetailBurned,
                            energy == null
                                ? '–'
                                : l10n.workoutSummaryEnergyValue(
                                    energy.kcal.round(),
                                  ),
                          ),
                        ],
                      ),
                      if (energy != null && energy.notCounted.isNotEmpty)
                        Text(
                          l10n.workoutSummaryEnergyNotCounted(
                            energy.notCounted.join(', '),
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: muted,
                          ),
                        ),
                      if (volume > 0 && detail.exercises.length > 1)
                        _VolumeSplit(
                          parts: [
                            for (var i = 0; i < detail.exercises.length; i++)
                              (
                                detail.exercises[i].exercise.exerciseName,
                                metrics[i].totalVolume,
                              ),
                          ],
                        ),
                      if (prLine != null) ...[
                        const Divider(height: 1),
                        Row(
                          spacing: FitFatTokens.spaceS,
                          children: [
                            Icon(
                              Icons.emoji_events_outlined,
                              size: 18,
                              color: colors.success,
                            ),
                            Expanded(
                              child: Text(
                                prLine,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: FitFatTokens.spaceM),
              if (detail.exercises.isEmpty)
                EmptyState(
                  icon: Icons.fitness_center,
                  title: l10n.emptyWorkoutDetailTitle,
                  description: l10n.emptyWorkoutDetailBody,
                )
              else
                for (var i = 0; i < detail.exercises.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: FitFatTokens.spaceM),
                    child: _ExerciseCard(
                      block: detail.exercises[i],
                      metrics: metrics[i],
                      prSets: prSets,
                      l10n: l10n,
                    ),
                  ),
              const SizedBox(height: FitFatTokens.spaceM),
              DangerRow(
                action: FormDeleteAction(
                  label: l10n.workoutDetailDelete,
                  consequence: setsDone == 0
                      ? null
                      : l10n.workoutDetailDeleteConsequence(setsDone),
                  onDelete: () => _delete(context, ref, setsDone),
                ),
              ),
              if (template != null)
                Padding(
                  padding: const EdgeInsets.only(top: FitFatTokens.spaceM),
                  child: Text(
                    l10n.workoutDetailFromTemplate(template.template.name),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

const _tab = [FontFeature.tabularFigures()];

/// Where the volume went: one segment per exercise (top three + the rest).
final class _VolumeSplit extends StatelessWidget {
  const _VolumeSplit({required this.parts});

  final List<(String, double)> parts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = theme.extension<FitFatColors>()!;
    final sorted = [...parts.where((p) => p.$2 > 0)]
      ..sort((a, b) => b.$2.compareTo(a.$2));
    final total = sorted.fold(0.0, (a, p) => a + p.$2);
    final top = sorted.take(3).toList();
    final rest = sorted.skip(3).fold(0.0, (a, p) => a + p.$2);
    final palette = [
      scheme.primary,
      Color.lerp(scheme.primary, scheme.surface, 0.45)!,
      colors.warning,
      scheme.surfaceContainerHighest,
    ];
    final segments = [
      for (var i = 0; i < top.length; i++) (top[i].$1, top[i].$2, palette[i]),
      if (rest > 0)
        (AppLocalizations.of(context)!.workoutDetailOther, rest, palette[3]),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FitFatTokens.spaceS,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(FitFatTokens.radiusFull),
          child: SizedBox(
            height: 8,
            child: Row(
              spacing: 2,
              children: [
                for (final (_, v, c) in segments)
                  Expanded(
                    flex: (v / total * 1000).round().clamp(1, 1000),
                    child: ColoredBox(color: c),
                  ),
              ],
            ),
          ),
        ),
        Wrap(
          spacing: FitFatTokens.spaceM,
          runSpacing: 2,
          children: [
            for (final (name, v, c) in segments)
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 4,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Text(
                    '$name ${(v / total * 100).round()}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

/// One exercise: name, "N sets · volume · avg rest", then a bar per set
/// (filled by reps done against planned) with the rest after it.
final class _ExerciseCard extends ConsumerWidget {
  const _ExerciseCard({
    required this.block,
    required this.metrics,
    required this.prSets,
    required this.l10n,
  });

  final ExerciseBlock block;
  final _ExerciseMetrics metrics;
  final Set<String> prSets;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final unit = ref.watch(settingsProvider).weightUnit;
    final exercise = ref
        .watch(exerciseByIdProvider(block.exercise.exerciseId))
        .value;
    final isCardio =
        exercise?.isCardio ??
        block.sets.any(
          (s) =>
              s.durationMinutes != null ||
              s.distanceMeters != null ||
              s.actualDurationMinutes != null ||
              s.actualDistanceMeters != null,
        );
    final isWeightlifting = exercise?.isWeightlifting ?? !isCardio;
    final done = block.sets.where((s) => s.isCompleted).length;
    final summary = [
      l10n.workoutDetailSetsDone(done),
      if (isCardio) ...[
        if (metrics.totalDurationMinutes > 0)
          '${metrics.totalDurationMinutes} min',
        if (metrics.totalDistanceMeters > 0)
          '${(metrics.totalDistanceMeters / 1000).toStringAsFixed(1)} km',
      ] else if (metrics.totalVolume > 0)
        formatVolume(metrics.totalVolume, unit),
      if (metrics.averageRestSeconds != null)
        l10n.workoutDetailAvgRestShort(
          formatRestDuration(Duration(seconds: metrics.averageRestSeconds!)),
        ),
    ].join(' · ');

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(FitFatTokens.spaceL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: FitFatTokens.spaceS,
          children: [
            Row(
              spacing: FitFatTokens.spaceM,
              children: [
                TrainingIcon(cardio: isCardio),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        block.exercise.exerciseName,
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        summary,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontFeatures: _tab,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            for (var i = 0; i < block.sets.length; i++)
              _SetBar(
                block: block,
                set: block.sets[i],
                isLast: i == block.sets.length - 1,
                isPr: prSets.contains(block.sets[i].id),
                isWeightlifting: isWeightlifting,
                isCardio: isCardio,
                l10n: l10n,
              ),
          ],
        ),
      ),
    );
  }
}

/// A set as a bar filled by reps done ÷ planned, labelled "80 kg × 7", the
/// difference from plan at the end, and the rest taken after it on the
/// right. Tap to edit the logged values.
final class _SetBar extends ConsumerWidget {
  const _SetBar({
    required this.block,
    required this.set,
    required this.isLast,
    required this.isPr,
    required this.isWeightlifting,
    required this.isCardio,
    required this.l10n,
  });

  final ExerciseBlock block;
  final ExerciseSet set;
  final bool isLast;
  final bool isPr;
  final bool isWeightlifting;
  final bool isCardio;
  final AppLocalizations l10n;

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final unit = ref.read(settingsProvider).weightUnit;
    final result = await showSetActualsDialog(
      context,
      set: set,
      l10n: l10n,
      isWeightlifting: isWeightlifting,
      isCardio: isCardio,
      unit: unit,
      hasDistanceHistory:
          ref
              .read(exerciseDistanceHistoryProvider)
              .value
              ?.contains(block.exercise.exerciseId) ??
          false,
    );
    if (result == null) return;
    await ref
        .read(workoutRepositoryProvider)
        .saveSetActuals(
          setId: set.id,
          actualReps: result.reps,
          actualWeightKg: result.weightKg,
          actualDurationMinutes: result.actualDurationMinutes,
          actualDistanceMeters: result.actualDistanceMeters,
        );
    ref.invalidate(workoutDetailProvider(block.exercise.workoutId));
    ref.invalidate(workoutListProvider);
    invalidateDashboard(ref);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = theme.extension<FitFatColors>()!;
    final unit = ref.watch(settingsProvider).weightUnit;
    final done = set.isCompleted;

    final String label;
    double fill;
    int? delta;
    if (isWeightlifting) {
      final reps = set.actualReps ?? 0;
      label =
          '${formatWeightValue(set.actualWeightKg ?? set.weightKg ?? 0, unit)} '
          '${weightUnitLabel(unit)} × $reps';
      final planned = set.reps;
      fill = !done
          ? 0
          : planned == null || planned == 0
          ? 1
          : (reps / planned).clamp(0.0, 1.0);
      if (done && planned != null && reps != planned) delta = reps - planned;
    } else {
      label = [
        if (set.actualDurationMinutes != null)
          '${set.actualDurationMinutes} min',
        if (set.actualDistanceMeters != null)
          '${(set.actualDistanceMeters! / 1000).toStringAsFixed(1)} km',
      ].join(' · ');
      final planned = set.durationMinutes;
      fill = !done
          ? 0
          : planned == null || planned == 0
          ? 1
          : ((set.actualDurationMinutes ?? 0) / planned).clamp(0.0, 1.0);
    }

    final barColor = isPr
        ? colors.success
        : (delta ?? 0) < 0
        ? Color.lerp(colors.warning, scheme.surface, 0.3)!
        : Color.lerp(scheme.primary, scheme.surface, 0.35)!;
    final onBar = isPr ? scheme.surface : scheme.onSurface;
    final rest = set.actualRestSeconds;

    return InkWell(
      onTap: () => _edit(context, ref),
      borderRadius: BorderRadius.circular(FitFatTokens.radiusS),
      child: Row(
        spacing: FitFatTokens.spaceS,
        children: [
          Expanded(
            child: SizedBox(
              height: 28,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(FitFatTokens.radiusS),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: scheme.surfaceContainerHighest),
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: fill,
                      child: ColoredBox(color: barColor),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: FitFatTokens.spaceS,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              done
                                  ? (isPr ? '$label · PR' : label)
                                  : l10n.workoutDetailNotDone,
                              maxLines: 1,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: done && fill > 0.5
                                    ? onBar
                                    : scheme.onSurfaceVariant,
                                fontFeatures: _tab,
                              ),
                            ),
                          ),
                          if (delta != null)
                            Text(
                              '${delta > 0 ? '+' : '−'}${delta.abs()}',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: scheme.onSurface,
                                fontFeatures: _tab,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            width: 64,
            child: isLast || rest == null
                ? null
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      spacing: 3,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: scheme.onSurfaceVariant,
                        ),
                        Text(
                          formatRestDuration(Duration(seconds: rest)),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontFeatures: _tab,
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
