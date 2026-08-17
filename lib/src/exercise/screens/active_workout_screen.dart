import 'dart:async';

import 'package:flutter/material.dart';
import '../../ui/widgets/top_banner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../models/exercise.dart';
import '../../models/exercise_set.dart';
import '../../models/workout.dart';
import '../../notifications/active_workout_notifier.dart';
import '../../notifications/rest_timer.dart';
import '../../dashboard/providers/dashboard.dart';
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

/// Guards against a second "Complete" tap racing the first (the teardown of
/// the foreground notification service used to throw and abort completion).
/// Module-level because the active-workout route is a single instance.
bool _completingWorkout = false;

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

final class _ActiveWorkoutContent extends StatefulWidget {
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
  State<_ActiveWorkoutContent> createState() => _ActiveWorkoutContentState();
}

final class _ActiveWorkoutContentState extends State<_ActiveWorkoutContent> {
  // Vertical pager over exercises: one exercise per swipe (one at a time).
  final PageController _pageController = PageController();
  int _page = 0;

  Workout get _workout => widget.workout;
  WorkoutWithDetails get _detail => widget.detail;
  AppLocalizations get _l10n => widget.l10n;
  WidgetRef get _ref => widget.ref;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_ActiveWorkoutContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Clamp the page when exercises are added/removed (e.g. add-exercise).
    final count = _detail.exercises.length;
    if (count == 0) {
      _page = 0;
    } else if (_page >= count) {
      _page = count - 1;
      _pageController.jumpToPage(_page);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColors = theme.extension<FitFatColors>()!;
    final l10n = _l10n;
    final workout = _workout;
    final detail = _detail;
    final elapsed = workout.startedAt == null
        ? Duration.zero
        : widget.now.difference(workout.startedAt!);

    return Scaffold(
      appBar: AppBar(
        title: Text(workout.name),
        leading: _activeWorkoutBackButton(context),
        actions: [
          IconButton(
            tooltip: l10n.activeWorkoutAddExerciseTooltip,
            icon: const Icon(Icons.add),
            onPressed: () => _showAddExerciseSheet(context),
          ),
          TextButton.icon(
            onPressed: () => _completeWorkout(context, _ref, workout.id),
            icon: const Icon(Icons.check),
            label: Text(l10n.workoutDetailBtnComplete),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: active badge + live elapsed time.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Card(
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
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _RestStrip(),
          ),
          if (detail.exercises.isEmpty)
            Expanded(
              child: EmptyState(
                icon: Icons.fitness_center,
                title: l10n.emptyWorkoutDetailTitle,
                description: l10n.emptyWorkoutDetailBody,
              ),
            )
          else ...[
            const SizedBox(height: 8),
            _buildPagerBar(theme),
            const SizedBox(height: 4),
            // Horizontal pager: swipe left/right to move between exercises.
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.horizontal,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: detail.exercises.length,
                itemBuilder: (_, i) => _ExercisePage(
                  block: detail.exercises[i],
                  workout: workout,
                  l10n: l10n,
                  ref: _ref,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPagerBar(ThemeData theme) {
    final l10n = _l10n;
    final count = _detail.exercises.length;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          tooltip: l10n.activeWorkoutPrevExercise,
          icon: const Icon(Icons.keyboard_arrow_left),
          onPressed: _page > 0
              ? () => _pageController.previousPage(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                  )
              : null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '${_page + 1} / $count',
            style: theme.textTheme.labelLarge?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        IconButton(
          tooltip: l10n.activeWorkoutNextExercise,
          icon: const Icon(Icons.keyboard_arrow_right),
          onPressed: _page < count - 1
              ? () => _pageController.nextPage(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                  )
              : null,
        ),
      ],
    );
  }

  Future<void> _completeWorkout(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    // Ignore a second tap while the first completion is in flight.
    if (_completingWorkout) return;
    _completingWorkout = true;
    try {
      // Persist completion first so the workout is stopped even if the
      // best-effort notification teardown below fails.
      await ref.read(workoutRepositoryProvider).complete(id);
      ref.invalidate(workoutDetailProvider(id));
      ref.invalidate(workoutListProvider);
      invalidateDashboard(ref);
      if (context.mounted) {
        showTopBanner(context, message: _l10n.workoutCompleted);
        // Redirect to the completed workout's summary (T07). Done before the
        // foreground-service teardown so stopping the service can't race the
        // navigation and leave the user on a still-"active" screen.
        context.go('/workout-summary/$id');
      }
    } finally {
      _completingWorkout = false;
      // Best-effort teardown after navigation, so a throw here can never block
      // completion. These are intentionally fire-and-forget.
      unawaited(
        ref.read(restTimerProvider.notifier).cancelRest().catchError((_) {}),
      );
      unawaited(
        ref
            .read(activeWorkoutNotifierProvider)
            .stopWorkoutNotification()
            .catchError((_) {}),
      );
    }
  }

  Future<void> _showAddExerciseSheet(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _ActiveWorkoutExerciseSearchSheet(
        l10n: l10n,
        ref: _ref,
        workoutId: _workout.id,
        currentExercises: _detail.exercises.map((b) => b.exercise.id).toSet(),
      ),
    );
    // Invalidate to refresh the workout detail if exercises were added
    _ref.invalidate(workoutDetailProvider(_workout.id));
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

/// One exercise occupying a full vertical pager page: header plus a
/// scrollable list of its sets. Only a single exercise is shown at a time —
/// swipe up/down in the pager (or the ↑/↓ buttons) to move between them.
final class _ExercisePage extends StatelessWidget {
  final ExerciseBlock block;
  final Workout workout;
  final AppLocalizations l10n;
  final WidgetRef ref;

  const _ExercisePage({
    required this.block,
    required this.workout,
    required this.l10n,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: SizedBox.expand(
        child: Card(
          margin: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.fitness_center, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            block.exercise.exerciseName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.workoutDetailSetCount(block.sets.length),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 8),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 8),
                  children: [
                    for (final set in block.sets)
                      _SetRow(set: set, workout: workout, l10n: l10n, ref: ref),
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

    var actual = set.actualReps != null || set.actualWeightKg != null
        ? (set.actualReps != null
            ? l10n.workoutDetailActualSetReps(
                set.actualReps.toString(),
                set.actualWeightKg == null
                    ? '?'
                    : formatDecimal(set.actualWeightKg!),
              )
            : l10n.workoutDetailActualSetWeight(
                formatDecimal(set.actualWeightKg!),
              ))
        : set.actualDurationMinutes != null || set.actualDistanceMeters != null
        ? [
            if (set.actualDurationMinutes != null)
              l10n.workoutDetailActualSetDuration(
                set.actualDurationMinutes.toString(),
              ),
            if (set.actualDistanceMeters != null)
              l10n.workoutDetailActualSetDistance(
                formatDecimal(set.actualDistanceMeters!),
              ),
          ].join(' · ')
        : l10n.workoutDetailActualSetEmpty;
    // "Time done": the HH:mm the set's actuals were saved.
    if (set.completedAt != null) {
      actual = l10n.workoutDetailActualSetTime(
        actual,
        DateFormats.formatTime(
          context,
          TimeOfDay.fromDateTime(set.completedAt!),
        ),
      );
    }

    return InkWell(
      onTap: isEditable ? () => _editActuals(context) : null,
      borderRadius: BorderRadius.circular(FitFatTokens.radiusM),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Set number
            SizedBox(
              width: 28,
              child: Text(
                '${set.setNumber}',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Planned
            Expanded(
              flex: 5,
              child: Text(
                planned,
                style: TextStyle(
                  color: set.isCompleted
                      ? theme.colorScheme.onSurfaceVariant
                      : null,
                  decoration: set.isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                Icons.arrow_forward,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            // Actual
            Expanded(
              flex: 5,
              child: Text(
                actual,
                style: TextStyle(
                  fontWeight: set.isCompleted ? FontWeight.w600 : null,
                  color: set.isCompleted
                      ? theme.extension<FitFatColors>()!.success
                      : null,
                ),
              ),
            ),
            // Completed indicator (tap the row to edit — no pencil needed).
            // The saved HH:mm is shown inline in the actual line above.
            if (set.completedAt != null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.check_circle,
                  size: 18,
                  color: theme.extension<FitFatColors>()!.success,
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
          actualDurationMinutes: result.actualDurationMinutes,
          actualDistanceMeters: result.actualDistanceMeters,
        );
    unawaited(Haptics.lightImpact());
    // T05: auto-start the rest timer with this set's planned rest, unless it
    // was the last incomplete set or has no planned rest.
    final savedActuals =
        result.reps != null ||
        result.weightKg != null ||
        result.actualDurationMinutes != null ||
        result.actualDistanceMeters != null;
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
  final int? actualDurationMinutes;
  final double? actualDistanceMeters;
  const _SetActuals({
    this.reps,
    this.weightKg,
    this.actualDurationMinutes,
    this.actualDistanceMeters,
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
      text: s.actualDurationMinutes?.toString() ?? '',
    );
    _distanceCtrl = TextEditingController(
      text: s.actualDistanceMeters?.toStringAsFixed(0) ?? '',
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
                actualDurationMinutes: int.tryParse(_durationCtrl.text),
                actualDistanceMeters: double.tryParse(_distanceCtrl.text),
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
      showTopBanner(context, message: '${exercise.name} added');
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
