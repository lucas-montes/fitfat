import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../models/exercise.dart';
import '../../models/exercise_set.dart';
import '../../models/workout.dart';
import '../../notifications/active_workout_notifier.dart';
import '../../notifications/rest_timer.dart';
import '../../ui/date_formats.dart';
import '../../ui/format.dart';
import '../../ui/haptics.dart';
import '../../ui/theme_extensions.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets/empty_state.dart';
import '../../ui/widgets/status_badge.dart';
import '../exercise_filter.dart';
import '../providers/exercises.dart';
import '../providers/workouts.dart';
import '../repositories/workout_repository.dart';

/// The single dedicated view for a running workout (active-workout-flow T04).
/// Lives on the top-level `/active-workout` GoRouter route, outside the shell,
/// so the floating bar and `NavigationBar` are not rendered while it is open.
/// Watches [activeWorkoutProvider] (identity) and [workoutDetailProvider]
/// (sets); renders live elapsed time, per-exercise set lists with the actuals
/// dialog, the rest-timer card, and the Complete action. Rest auto-start and
/// actual-rest recording arrive in T05.
final class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() =>
      _ActiveWorkoutScreenState();
}

final class _ActiveWorkoutScreenState
    extends ConsumerState<ActiveWorkoutScreen> {
  Timer? _ticker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    // 1 s ticker for the live elapsed time. No-op while no workout is active
    // (the provider watch rebuilds and swaps the body out).
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (ref.read(activeWorkoutProvider) == null) return;
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final activeWorkout = ref.watch(activeWorkoutProvider);
    if (activeWorkout == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.workoutDetailAppBar),
          leading: _activeWorkoutBackButton(context),
        ),
        body: Center(child: Text(l10n.workoutDetailNotFound)),
      );
    }

    final detailAsync = ref.watch(workoutDetailProvider(activeWorkout.id));
    return detailAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(
          title: Text(activeWorkout.name),
          leading: _activeWorkoutBackButton(context),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(
          title: Text(activeWorkout.name),
          leading: _activeWorkoutBackButton(context),
        ),
        body: Center(child: Text(l10n.errorWithMessage('$e'))),
      ),
      data: (detail) {
        if (detail == null) {
          return Scaffold(
            appBar: AppBar(
              title: Text(activeWorkout.name),
              leading: _activeWorkoutBackButton(context),
            ),
            body: Center(child: Text(l10n.workoutDetailNotFound)),
          );
        }
        return _ActiveWorkoutContent(
          workout: activeWorkout,
          detail: detail,
          now: _now,
          l10n: l10n,
          ref: ref,
        );
      },
    );
  }
}

/// Leading back affordance shared by every `AppBar` state on this screen
/// (not-found, loading, error, data): pops when a route is below, else
/// returns to the exercise tab. Mirrors the summary screen's back pattern.
Widget _activeWorkoutBackButton(BuildContext context) {
  return IconButton(
    icon: const Icon(Icons.arrow_back),
    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
    onPressed: () {
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop();
      } else {
        context.go('/exercise');
      }
    },
  );
}

final class _ActiveWorkoutContent extends StatelessWidget {
  final Workout workout;
  final WorkoutWithDetails detail;
  final DateTime now;
  final AppLocalizations l10n;
  final WidgetRef ref;

  const _ActiveWorkoutContent({
    required this.workout,
    required this.detail,
    required this.now,
    required this.l10n,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColors = theme.extension<FitFatColors>()!;
    final elapsed = workout.startedAt == null
        ? Duration.zero
        : now.difference(workout.startedAt!);

    return Scaffold(
      appBar: AppBar(
        title: Text(workout.name),
        leading: _activeWorkoutBackButton(context),
        actions: [
          TextButton.icon(
            onPressed: () => _completeWorkout(context, ref, workout.id),
            icon: const Icon(Icons.check),
            label: Text(l10n.workoutDetailBtnComplete),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header: active badge + live elapsed time.
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      StatusBadge(
                        label: l10n.statusActive,
                        color: statusColors.warning,
                      ),
                      const Spacer(),
                      Text(
                        formatRestDuration(elapsed),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  if (workout.startedAt != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.workoutDetailStartedAt(
                        DateFormats.formatTime(
                          context,
                          TimeOfDay.fromDateTime(workout.startedAt!),
                        ),
                      ),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const _RestStrip(),
          const SizedBox(height: 16),

          // Exercises
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
              _ExerciseBlockCard(
                block: block,
                workout: workout,
                l10n: l10n,
                ref: ref,
              ),
          const SizedBox(height: 16),
          // Add Exercise button
          FilledButton.icon(
            onPressed: () => _showAddExerciseSheet(context),
            icon: const Icon(Icons.add),
            label: Text(l10n.activeWorkoutAddExercise),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _completeWorkout(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    // Run independent operations in parallel to reduce completion latency
    await Future.wait([
      ref.read(restTimerProvider.notifier).cancelRest(),
      ref.read(activeWorkoutNotifierProvider).stopWorkoutNotification(),
      ref.read(workoutRepositoryProvider).complete(id),
    ]);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.workoutCompleted)));
    }
    ref.invalidate(workoutDetailProvider(id));
    ref.invalidate(workoutListProvider);
    // Redirect to the completed workout's summary (T07).
    if (context.mounted) context.go('/workout-summary/$id');
  }

  Future<void> _showAddExerciseSheet(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _ActiveWorkoutExerciseSearchSheet(
        l10n: l10n,
        ref: ref,
        workoutId: workout.id,
        currentExercises: detail.exercises.map((b) => b.exercise.id).toSet(),
      ),
    );
    // Invalidate to refresh the workout detail if exercises were added
    ref.invalidate(workoutDetailProvider(workout.id));
  }
}

/// Slim rest strip under the workout header: shows the elapsed rest time
/// (`⏱ Rest 1:23`) while a rest is running, with no stop button. The count-up
/// rest keeps running past the planned duration until the next set is logged
/// or the workout completes; the strip highlights once the planned rest has
/// been reached.
final class _RestStrip extends ConsumerStatefulWidget {
  const _RestStrip();

  @override
  ConsumerState<_RestStrip> createState() => _RestStripState();
}

final class _RestStripState extends ConsumerState<_RestStrip> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (ref.read(restTimerProvider).isResting) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rest = ref.watch(restTimerProvider);
    if (!rest.isResting) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final statusColors = theme.extension<FitFatColors>()!;
    final now = DateTime.now();
    final overdue = rest.isOverdue(now);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: overdue
            ? statusColors.warning.withValues(alpha: 0.14)
            : theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, size: 18, color: statusColors.warning),
          const SizedBox(width: FitFatTokens.spaceM),
          Expanded(
            child: Text(
              l10n.activeWorkoutRestLabel,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Text(
            formatRestDuration(rest.elapsedAt(now)),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

final class _ExerciseBlockCard extends StatelessWidget {
  final ExerciseBlock block;
  final Workout workout;
  final AppLocalizations l10n;
  final WidgetRef ref;

  const _ExerciseBlockCard({
    required this.block,
    required this.workout,
    required this.l10n,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        title: Text(block.exercise.exerciseName),
        leading: const Icon(Icons.fitness_center),
        subtitle: Text(l10n.workoutDetailSetCount(block.sets.length)),
        initiallyExpanded: true,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    l10n.workoutDetailSetHeaderHash,
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Text(
                    l10n.workoutDetailSetHeaderPlanned,
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Text(
                    l10n.workoutDetailSetHeaderActual,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 8),
          for (final set in block.sets)
            _SetRow(set: set, workout: workout, l10n: l10n, ref: ref),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

final class _SetRow extends StatelessWidget {
  final ExerciseSet set;
  final Workout workout;
  final AppLocalizations l10n;
  final WidgetRef ref;

  const _SetRow({
    required this.set,
    required this.workout,
    required this.l10n,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // On the active screen sets are always editable (the workout is running).
    final isEditable = !workout.isPending;

    var planned = set.reps != null
        ? l10n.workoutDetailPlannedSetReps(
            set.reps.toString(),
            set.weightKg == null ? '?' : formatDecimal(set.weightKg!),
          )
        : set.durationMinutes != null
        ? l10n.workoutDetailPlannedSetDuration(set.durationMinutes.toString())
        : l10n.workoutDetailPlannedSetEmpty;
    final restSeconds = set.restSeconds;
    if (restSeconds != null) {
      planned = l10n.workoutDetailPlannedSetRest(
        planned,
        formatRestDuration(Duration(seconds: restSeconds)),
      );
    }

    final actual = set.actualReps != null
        ? l10n.workoutDetailActualSetReps(
            set.actualReps.toString(),
            set.actualWeightKg == null
                ? '?'
                : formatDecimal(set.actualWeightKg!),
          )
        : set.actualWeightKg != null
        ? l10n.workoutDetailActualSetWeight(formatDecimal(set.actualWeightKg!))
        : set.durationMinutes != null && set.actualReps != null
        ? l10n.workoutDetailActualSetDuration(set.actualReps.toString())
        : l10n.workoutDetailActualSetEmpty;

    return InkWell(
      onTap: isEditable ? () => _editActuals(context) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                '${set.setNumber}',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ),
            Expanded(
              flex: 5,
              child: Text(
                planned,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: set.isCompleted
                      ? theme.colorScheme.onSurfaceVariant
                      : null,
                  decoration: set.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
            ),
            Expanded(
              flex: 5,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actual,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: set.isCompleted ? FontWeight.w600 : null,
                      color: set.isCompleted
                          ? theme.extension<FitFatColors>()!.success
                          : null,
                    ),
                  ),
                  // v7: completion time (HH:mm, locale-aware) stamped when
                  // actuals were saved; shown only for completed sets.
                  if (set.completedAt != null)
                    Text(
                      DateFormats.formatTime(
                        context,
                        TimeOfDay.fromDateTime(set.completedAt!),
                      ),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            if (isEditable)
              Tooltip(
                message: l10n.commonEdit,
                child: Icon(
                  Icons.edit,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _editActuals(BuildContext context) async {
    final result = await showDialog<_SetActuals>(
      context: context,
      builder: (ctx) => _SetActualsDialog(set: set, l10n: l10n),
    );
    if (result == null) return;

    await ref
        .read(workoutRepositoryProvider)
        .updateSetActuals(
          setId: set.id,
          actualReps: result.reps,
          actualWeightKg: result.weightKg,
          durationMinutes: result.durationMinutes,
          distanceMeters: result.distanceMeters,
        );
    unawaited(Haptics.lightImpact());
    // T05: auto-start the rest timer with this set's planned rest, unless it
    // was the last incomplete set or has no planned rest.
    final savedActuals =
        result.reps != null ||
        result.weightKg != null ||
        result.durationMinutes != null ||
        result.distanceMeters != null;
    final detail = ref.read(workoutDetailProvider(workout.id)).value;
    final hasOtherIncomplete =
        detail != null &&
        detail.exercises.any(
          (b) => b.sets.any((s) => s.id != set.id && !s.isCompleted),
        );
    final restSeconds = set.restSeconds;
    if (savedActuals && hasOtherIncomplete && restSeconds != null) {
      await ref
          .read(restTimerProvider.notifier)
          .startRest(Duration(seconds: restSeconds), setId: set.id);
    }
    ref.invalidate(workoutDetailProvider(workout.id));
  }
}

final class _SetActuals {
  final int? reps;
  final double? weightKg;
  final int? durationMinutes;
  final double? distanceMeters;
  const _SetActuals({
    this.reps,
    this.weightKg,
    this.durationMinutes,
    this.distanceMeters,
  });
}

final class _SetActualsDialog extends StatefulWidget {
  final ExerciseSet set;
  final AppLocalizations l10n;
  const _SetActualsDialog({required this.set, required this.l10n});

  @override
  State<_SetActualsDialog> createState() => _SetActualsDialogState();
}

final class _SetActualsDialogState extends State<_SetActualsDialog> {
  late final TextEditingController _repsCtrl;
  late final TextEditingController _weightCtrl;
  late final TextEditingController _durationCtrl;
  late final TextEditingController _distanceCtrl;

  @override
  void initState() {
    super.initState();
    final s = widget.set;
    _repsCtrl = TextEditingController(
      text: (s.actualReps ?? s.reps)?.toString() ?? '',
    );
    _weightCtrl = TextEditingController(
      text: (s.actualWeightKg ?? s.weightKg)?.toStringAsFixed(1) ?? '',
    );
    _durationCtrl = TextEditingController(
      text:
          (s.actualWeightKg != null ? s.durationMinutes : null)?.toString() ??
          '',
    );
    _distanceCtrl = TextEditingController(
      text: s.distanceMeters?.toStringAsFixed(0) ?? '',
    );
  }

  @override
  void dispose() {
    _repsCtrl.dispose();
    _weightCtrl.dispose();
    _durationCtrl.dispose();
    _distanceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final s = widget.set;
    final isWeightlifting = s.reps != null || s.weightKg != null;
    final isCardio = s.durationMinutes != null || s.distanceMeters != null;

    return AlertDialog(
      title: Text(l10n.workoutDetailSetActualsTitle(s.setNumber)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isWeightlifting) ...[
              TextField(
                controller: _repsCtrl,
                decoration: InputDecoration(
                  labelText: l10n.workoutDetailActualRepsLabel,
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _weightCtrl,
                decoration: InputDecoration(
                  labelText: l10n.workoutDetailActualWeightLabel,
                ),
                keyboardType: TextInputType.number,
              ),
            ],
            if (isCardio) ...[
              TextField(
                controller: _durationCtrl,
                decoration: InputDecoration(
                  labelText: l10n.workoutDetailActualDurationLabel,
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _distanceCtrl,
                decoration: InputDecoration(
                  labelText: l10n.workoutDetailActualDistanceLabel,
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(
              _SetActuals(
                reps: int.tryParse(_repsCtrl.text),
                weightKg: double.tryParse(_weightCtrl.text),
                durationMinutes: int.tryParse(_durationCtrl.text),
                distanceMeters: double.tryParse(_distanceCtrl.text),
              ),
            );
          },
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}

/// Bottom sheet for searching and adding exercises during an active workout.
/// Shows current workout exercises first (with checkmark), then all exercises
/// with images/thumbnails. No "Create Exercise" option.
final class _ActiveWorkoutExerciseSearchSheet extends ConsumerStatefulWidget {
  final AppLocalizations l10n;
  final WidgetRef ref;
  final String workoutId;
  final Set<String> currentExercises;

  const _ActiveWorkoutExerciseSearchSheet({
    required this.l10n,
    required this.ref,
    required this.workoutId,
    required this.currentExercises,
  });

  @override
  ConsumerState<_ActiveWorkoutExerciseSearchSheet> createState() =>
      _ActiveWorkoutExerciseSearchSheetState();
}

final class _ActiveWorkoutExerciseSearchSheetState
    extends ConsumerState<_ActiveWorkoutExerciseSearchSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  final Set<String> _types = {};
  final Set<String> _bodyParts = {};
  final Set<String> _equipments = {};
  final Set<String> _muscles = {};
  late final Set<String> _addedIds;

  @override
  void initState() {
    super.initState();
    _addedIds = {...widget.currentExercises};
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exercisesAsync = ref.watch(exerciseListProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollCtrl) => Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.4,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.l10n.activeWorkoutAddExercise,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: widget.l10n.commonCancel,
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  labelText: widget.l10n.exerciseListSearchHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                ),
                onChanged: (v) => setState(() => _query = v),
                autofocus: true,
              ),
            ),
            const SizedBox(height: 8),
            // Exercise list
            Expanded(
              child: exercisesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (exercises) {
                  final options = exerciseFilterOptions(exercises);
                  final hasFilters =
                      _query.trim().isNotEmpty ||
                      _types.isNotEmpty ||
                      _bodyParts.isNotEmpty ||
                      _equipments.isNotEmpty ||
                      _muscles.isNotEmpty;

                  // Exercises already in this workout (seeded + added live).
                  final inWorkoutAll = exercises
                      .where((e) => _addedIds.contains(e.id))
                      .toList();
                  final inWorkout = hasFilters
                      ? filterExercises(
                          inWorkoutAll,
                          query: _query,
                          types: _types,
                          bodyParts: _bodyParts,
                          equipments: _equipments,
                          muscles: _muscles,
                        )
                      : inWorkoutAll;

                  // Remaining exercises, filtered + ranked by relevance.
                  final othersPool = exercises
                      .where((e) => !_addedIds.contains(e.id))
                      .toList();
                  final others = hasFilters
                      ? DefaultSearchRanker()
                            .rank(
                              _query.trim(),
                              filterExercises(
                                othersPool,
                                query: _query,
                                types: _types,
                                bodyParts: _bodyParts,
                                equipments: _equipments,
                                muscles: _muscles,
                              ),
                            )
                            .map((se) => se.exercise)
                            .toList()
                      : <Exercise>[];

                  final itemCount =
                      (inWorkout.isNotEmpty ? 1 + inWorkout.length : 0) +
                      (others.isNotEmpty ? 1 + others.length : 0);

                  return Column(
                    children: [
                      if (!options.isEmpty) _buildFilterChips(options),
                      Expanded(
                        child: itemCount == 0
                            ? Center(
                                child: Text(
                                  hasFilters
                                      ? widget.l10n.exerciseFilterNoResults
                                      : widget.l10n.activeWorkoutSearchPrompt,
                                ),
                              )
                            : ListView.builder(
                                controller: scrollCtrl,
                                itemCount: itemCount,
                                itemBuilder: (_, i) =>
                                    _buildSearchRow(i, inWorkout, others),
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(ExerciseFilterOptions options) {
    final l10n = widget.l10n;
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _filterChip(l10n.exerciseFilterType, _types, options.types),
          const SizedBox(width: 8),
          _filterChip(
            l10n.exerciseFilterBodyPart,
            _bodyParts,
            options.bodyParts,
          ),
          const SizedBox(width: 8),
          _filterChip(
            l10n.exerciseFilterEquipment,
            _equipments,
            options.equipments,
          ),
          const SizedBox(width: 8),
          _filterChip(l10n.exerciseFilterMuscle, _muscles, options.muscles),
        ],
      ),
    );
  }

  Widget _filterChip(
    String label,
    Set<String> selection,
    List<String> options,
  ) {
    return FilterChip(
      label: Text(
        selection.isNotEmpty ? '$label (${selection.length})' : label,
      ),
      selected: selection.isNotEmpty,
      showCheckmark: selection.isNotEmpty,
      onSelected: (_) =>
          _pickFilter(label: label, options: options, selection: selection),
    );
  }

  Future<void> _pickFilter({
    required String label,
    required List<String> options,
    required Set<String> selection,
  }) async {
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _FilterOptionsSheet(
        title: label,
        options: options,
        selected: selection,
      ),
    );
    if (result != null && mounted) {
      setState(() {
        selection
          ..clear()
          ..addAll(result);
      });
    }
  }

  Widget _buildSearchRow(
    int i,
    List<Exercise> inWorkout,
    List<Exercise> others,
  ) {
    int index = 0;
    if (inWorkout.isNotEmpty) {
      if (i == 0) {
        return _SectionHeader(
          title: widget.l10n.activeWorkoutInThisWorkout,
          count: inWorkout.length,
        );
      }
      if (i <= inWorkout.length) {
        final ex = inWorkout[i - 1];
        return _ExerciseSearchTile(
          exercise: ex,
          isInWorkout: true,
          onTap: () {},
        );
      }
      index = inWorkout.length + 1;
    }
    final otherIndex = i - index;
    if (others.isNotEmpty) {
      if (otherIndex == 0) {
        return _SectionHeader(
          title: widget.l10n.activeWorkoutAllExercises,
          count: others.length,
        );
      }
      final ex = others[otherIndex - 1];
      return _ExerciseSearchTile(
        exercise: ex,
        isInWorkout: false,
        onTap: () => _addExercise(context, ex),
      );
    }
    return const SizedBox.shrink();
  }

  Future<void> _addExercise(BuildContext context, Exercise exercise) async {
    final repo = ref.read(workoutRepositoryProvider);
    await repo.addExerciseToWorkout(
      workoutId: widget.workoutId,
      exerciseId: exercise.id,
    );
    if (context.mounted) {
      setState(() => _addedIds.add(exercise.id));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${exercise.name} added')));
    }
  }
}

/// Multi-select filter bottom sheet (shared shape with the exercise list's
/// picker) used by the active-workout search chips.
final class _FilterOptionsSheet extends StatefulWidget {
  final String title;
  final List<String> options;
  final Set<String> selected;

  const _FilterOptionsSheet({
    required this.title,
    required this.options,
    required this.selected,
  });

  @override
  State<_FilterOptionsSheet> createState() => _FilterOptionsSheetState();
}

final class _FilterOptionsSheetState extends State<_FilterOptionsSheet> {
  late final Set<String> _selected = {...widget.selected};
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final q = _search.trim().toLowerCase();
    final visible = q.isEmpty
        ? widget.options
        : widget.options.where((o) => o.toLowerCase().contains(q)).toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: l10n.exerciseFilterSearchOptions,
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final option in visible)
                      CheckboxListTile(
                        dense: true,
                        title: Text(option),
                        value: _selected.contains(option),
                        onChanged: (checked) => setState(() {
                          if (checked ?? false) {
                            _selected.add(option);
                          } else {
                            _selected.remove(option);
                          }
                        }),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () => setState(_selected.clear),
                      child: Text(l10n.exerciseFilterClear),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(_selected),
                      child: Text(l10n.exerciseFilterApply),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tile for an exercise in the active workout search sheet.
/// Shows image/thumbnail, name, type, and checkmark if already in workout.
final class _ExerciseSearchTile extends StatelessWidget {
  final Exercise exercise;
  final bool isInWorkout;
  final VoidCallback onTap;

  const _ExerciseSearchTile({
    required this.exercise,
    required this.isInWorkout,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: SizedBox(width: 48, height: 48, child: _buildThumbnail(context)),
      title: Text(exercise.name),
      subtitle: Text(
        exercise.exerciseType == 'weightlifting' ? 'Weightlifting' : 'Cardio',
        style: theme.textTheme.bodySmall,
      ),
      trailing: isInWorkout
          ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
          : const Icon(Icons.add),
      onTap: isInWorkout ? null : onTap,
      enabled: !isInWorkout,
    );
  }

  Widget _buildThumbnail(BuildContext context) {
    if (exercise.imagePath != null) {
      return Image.asset(
        exercise.imagePath!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => _typeIcon(context),
      );
    }
    return _typeIcon(context);
  }

  Widget _typeIcon(BuildContext context) {
    final theme = Theme.of(context);
    final icon = exercise.exerciseType == 'weightlifting'
        ? Icons.fitness_center
        : Icons.directions_run;
    return Icon(icon, color: theme.colorScheme.onSurfaceVariant, size: 28);
  }
}

/// Section header for exercise search sheet.
final class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '($count)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
