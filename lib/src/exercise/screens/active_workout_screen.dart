import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../../l10n/app_localizations.dart';
import '../../models/exercise.dart';
import '../../models/exercise_set.dart';
import '../../models/units.dart';
import '../../models/workout.dart';
import '../../notifications/active_workout_notifier.dart';
import '../../notifications/rest_timer.dart';
import '../../dashboard/providers/dashboard.dart';
import '../../settings/providers/settings.dart';
import '../../ui/date_formats.dart';
import '../../ui/format.dart';
import '../../ui/haptics.dart';
import '../../ui/units.dart';
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

final class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        ref.read(activeWorkoutProvider) != null) {
      // Recompute + refresh the ongoing notification on foreground resume so it
      // is current at interaction points even if the background tick stalled
      // while the process was backgrounded (notification-timers T03).
      unawaited(refreshActiveWorkoutNotification());
    }
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
  final AppLocalizations l10n;
  final WidgetRef ref;

  const _ActiveWorkoutContent({
    required this.workout,
    required this.detail,
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
  // Start time of the rest whose completion already triggered a pager jump
  // (one-shot per rest session, T05).
  DateTime? _lastJumpedRestStart;

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

    // Rest → current exercise (T05): when a rest transitions to overdue,
    // one-shot jump the pager back to the exercise the resting set belongs to.
    // Keyed on the rest's start time so it fires once per rest session; the
    // manual pager stays independent otherwise.
    final rest = _ref.watch(restTimerProvider);
    if (rest.isResting && rest.isOverdue(DateTime.now())) {
      final startedAt = rest.startedAt;
      if (startedAt != null && _lastJumpedRestStart != startedAt) {
        _lastJumpedRestStart = startedAt;
        final index = _pageIndexForSet(rest.setId);
        if (index != null && index != _page) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _pageController.jumpToPage(index);
          });
        }
      }
    }

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
          // Info strip: the single top card holding status, live elapsed,
          // started-at, the rest countdown and the exercise page indicator.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
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
                        if (detail.exercises.isNotEmpty)
                          Text(
                            '${_page + 1} / ${detail.exercises.length}',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _ElapsedText(workout: workout),
                        const Spacer(),
                        if (workout.startedAt != null)
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
                    ),
                    _RestLine(exerciseName: _exerciseNameForSet(rest.setId)),
                  ],
                ),
              ),
            ),
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
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Page index of the exercise owning [setId], or null when unknown.
  int? _pageIndexForSet(String? setId) {
    if (setId == null) return null;
    for (var i = 0; i < _detail.exercises.length; i++) {
      for (final set in _detail.exercises[i].sets) {
        if (set.id == setId) return i;
      }
    }
    return null;
  }

  /// Exercise name owning [setId] — shown in the rest line when the user has
  /// swiped away from that exercise while its rest is running.
  String? _exerciseNameForSet(String? setId) {
    if (setId == null) return null;
    for (final block in _detail.exercises) {
      for (final set in block.sets) {
        if (set.id == setId) return block.exercise.exerciseName;
      }
    }
    return null;
  }

  Widget _buildPagerBar(ThemeData theme) {
    final l10n = _l10n;
    final count = _detail.exercises.length;
    // Prev/next only — the N / M indicator moved into the top info strip.
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
        const SizedBox(width: FitFatTokens.spaceL),
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
/// Live elapsed-time text for the active-header card. Owns its own 1 s ticker
/// so the per-second rebuild is scoped to this leaf widget and never rebuilds
/// the page/tree (performance T01).
final class _ElapsedText extends StatefulWidget {
  final Workout workout;

  const _ElapsedText({required this.workout});

  @override
  State<_ElapsedText> createState() => _ElapsedTextState();
}

final class _ElapsedTextState extends State<_ElapsedText> {
  Timer? _ticker;
  DateTime _now = DateTime.now();

  Workout get _workout => widget.workout;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
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
    final elapsed = _workout.startedAt == null
        ? Duration.zero
        : _now.difference(_workout.startedAt!);
    return Text(
      formatRestDuration(elapsed),
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

/// Rest countdown line inside the top info strip. Hidden when no rest is
/// running; otherwise shows a count-up (own scoped 1 s ticker so only this
/// leaf rebuilds) with an overdue highlight, plus the exercise the rest
/// belongs to when the user has swiped away from it.
final class _RestLine extends ConsumerStatefulWidget {
  final String? exerciseName;

  const _RestLine({required this.exerciseName});

  @override
  ConsumerState<_RestLine> createState() => _RestLineState();
}

final class _RestLineState extends ConsumerState<_RestLine> {
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
    final exerciseName = widget.exerciseName;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: overdue
              ? statusColors.warning.withValues(alpha: 0.14)
              : theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(FitFatTokens.radiusM),
        ),
        child: Row(
          children: [
            Icon(Icons.timer_outlined, size: 16, color: statusColors.warning),
            const SizedBox(width: FitFatTokens.spaceS),
            Expanded(
              child: Text(
                exerciseName == null
                    ? l10n.activeWorkoutRestLabel
                    : '${l10n.activeWorkoutRestLabel} · $exerciseName',
                style: theme.textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              formatRestDuration(rest.elapsedAt(now)),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: overdue ? statusColors.warning : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One exercise occupying a full vertical pager page: header (name, note
/// affordance, fact chips, compact media), a collapsible history section, and
/// a scrollable list of its sets with a completion progress bar. Only a single
/// exercise is shown at a time — swipe up/down in the pager (or the ↑/↓
/// buttons) to move between them.
final class _ExercisePage extends ConsumerWidget {
  final ExerciseBlock block;
  final Workout workout;
  final AppLocalizations l10n;

  const _ExercisePage({
    required this.block,
    required this.workout,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final unit = ref.watch(settingsProvider).weightUnit;
    final exercise = ref
        .watch(exerciseByIdProvider(block.exercise.exerciseId))
        .value;
    final completedSets = block.sets.where((s) => s.isCompleted).length;
    final note = block.exercise.notes;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: SizedBox.expand(
        child: Card(
          margin: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (exercise != null &&
                  (exercise.imagePath != null || exercise.videoPath != null))
                _CompactMedia(exercise: exercise),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                block.exercise.exerciseName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l10n.workoutDetailSetCount(block.sets.length),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: l10n.activeWorkoutExerciseInfo,
                          icon: const Icon(Icons.info_outline),
                          onPressed: exercise == null
                              ? null
                              : () => _showInfoSheet(context, exercise),
                        ),
                        IconButton(
                          tooltip: l10n.exerciseDetailTabHistory,
                          icon: const Icon(Icons.history),
                          onPressed: () => _showHistorySheet(context),
                        ),
                        IconButton(
                          tooltip: l10n.activeWorkoutExerciseNotes,
                          icon: Icon(
                            note == null || note.trim().isEmpty
                                ? Icons.add_comment_outlined
                                : Icons.comment,
                          ),
                          onPressed: () => _editNote(context, ref),
                        ),
                      ],
                    ),
                    if (note != null && note.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      InkWell(
                        borderRadius: BorderRadius.circular(
                          FitFatTokens.radiusM,
                        ),
                        onTap: () => _editNote(context, ref),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.comment, size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  note.trim(),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Divider(height: 8),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 8),
                  children: [
                    _SetsProgressBar(
                      completed: completedSets,
                      total: block.sets.length,
                    ),
                    for (final set in block.sets)
                      _SetRow(
                        set: set,
                        workout: workout,
                        l10n: l10n,
                        ref: ref,
                        unit: unit,
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

  Future<void> _editNote(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) =>
          _NoteDialog(initialText: block.exercise.notes, l10n: l10n),
    );
    if (result == null || !context.mounted) return;
    await ref
        .read(workoutRepositoryProvider)
        .updateExerciseNotes(
          workoutExerciseId: block.exercise.id,
          notes: result.isEmpty ? null : result,
        );
    ref.invalidate(workoutDetailProvider(workout.id));
  }

  /// Fact chips (type / body part / equipment) behind the info icon.
  void _showInfoSheet(BuildContext context, Exercise exercise) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                block.exercise.exerciseName,
                style: Theme.of(
                  ctx,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              _CardFactChips(exercise: exercise, l10n: l10n),
            ],
          ),
        ),
      ),
    );
  }

  /// Past sessions for this exercise behind the history icon.
  void _showHistorySheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (ctx, scrollController) => _HistorySheet(
          exerciseId: block.exercise.exerciseId,
          l10n: l10n,
          scrollController: scrollController,
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
  final WeightUnit unit;

  const _SetRow({
    required this.set,
    required this.workout,
    required this.l10n,
    required this.ref,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // On the active screen sets are always editable (the workout is running).
    final isEditable = !workout.isPending;
    final status = _setProgress(set);
    final (icon, color) = _statusVisuals(theme, status);

    final planned = _plannedString(context);
    final actual = _actualString(context);

    return InkWell(
      onTap: isEditable ? () => _editActuals(context) : null,
      borderRadius: BorderRadius.circular(FitFatTokens.radiusM),
      child: Ink(
        // Subtle tint by completion status; pending rows stay un-tinted.
        color: status == _SetProgress.pending
            ? null
            : color.withValues(alpha: 0.06),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Leading status icon (progress-driven; no number column).
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Planned, small/muted subtext (no strikethrough).
                  Text(
                    planned,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Actual, prominent headline in the status color.
                  Text(
                    actual,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: status == _SetProgress.pending
                          ? FontWeight.w500
                          : FontWeight.w600,
                      color: status == _SetProgress.pending
                          ? theme.colorScheme.onSurface
                          : color,
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

  String _plannedString(BuildContext context) {
    var planned = set.reps != null
        ? l10n.workoutDetailPlannedSetReps(
            set.reps.toString(),
            set.weightKg == null ? '?' : formatWeightValue(set.weightKg!, unit),
            weightUnitLabel(unit),
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
    return planned;
  }

  String _actualString(BuildContext context) {
    var actual = set.actualReps != null || set.actualWeightKg != null
        ? (set.actualReps != null
              ? l10n.workoutDetailActualSetReps(
                  set.actualReps.toString(),
                  set.actualWeightKg == null
                      ? '?'
                      : formatWeightValue(set.actualWeightKg!, unit),
                  weightUnitLabel(unit),
                )
              : l10n.workoutDetailActualSetWeight(
                  formatWeightValue(set.actualWeightKg!, unit),
                  weightUnitLabel(unit),
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
    return actual;
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
    // Push the notification text so a set-save is reflected immediately even if
    // the background tick stalls (notification-timers T02).
    unawaited(refreshActiveWorkoutNotification());
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

/// A single planned-set row's text controllers (disposed with the dialog).
final class _PlannedSetRow {
  final TextEditingController repsCtrl = TextEditingController();
  final TextEditingController weightCtrl = TextEditingController();

  void dispose() {
    repsCtrl.dispose();
    weightCtrl.dispose();
  }
}

/// Editor for one [_PlannedSetRow]: planned reps + weight, with an optional
/// remove affordance (hidden when it is the only row).
final class _PlannedSetRowEditor extends StatelessWidget {
  final int index;
  final _PlannedSetRow row;
  final AppLocalizations l10n;
  final VoidCallback? onRemove;

  const _PlannedSetRowEditor({
    required this.index,
    required this.row,
    required this.l10n,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: row.repsCtrl,
              decoration: InputDecoration(
                labelText: l10n.activeWorkoutPlannedRepsLabel,
                isDense: true,
              ),
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: row.weightCtrl,
              decoration: InputDecoration(
                labelText: l10n.activeWorkoutPlannedWeightLabel,
                isDense: true,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ),
          if (onRemove != null)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              tooltip: l10n.commonRemove,
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}

/// Dialog shown when adding an exercise to an active workout so the user can
/// seed planned sets (reps + weight) up front. Returns `null` when cancelled or
/// a non-empty list of [PlannedSet] (one per row) when confirmed.
final class _PlannedSetsDialog extends StatefulWidget {
  final AppLocalizations l10n;
  final String exerciseName;

  const _PlannedSetsDialog({required this.l10n, required this.exerciseName});

  @override
  State<_PlannedSetsDialog> createState() => _PlannedSetsDialogState();
}

final class _PlannedSetsDialogState extends State<_PlannedSetsDialog> {
  final List<_PlannedSetRow> _rows = [_PlannedSetRow()];

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return AlertDialog(
      title: Text(l10n.activeWorkoutPlannedSetsTitle(widget.exerciseName)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < _rows.length; i++)
              _PlannedSetRowEditor(
                index: i,
                row: _rows[i],
                l10n: l10n,
                onRemove: _rows.length > 1
                    ? () => setState(() => _rows.removeAt(i))
                    : null,
              ),
            TextButton.icon(
              onPressed: () => setState(() => _rows.add(_PlannedSetRow())),
              icon: const Icon(Icons.add),
              label: Text(l10n.workoutFormAddSet),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () {
            final sets = _rows
                .map(
                  (r) => PlannedSet(
                    reps: int.tryParse(r.repsCtrl.text),
                    weightKg: double.tryParse(r.weightCtrl.text),
                  ),
                )
                .toList();
            Navigator.of(context).pop(sets);
          },
          child: Text(l10n.activeWorkoutAddExercise),
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
  Timer? _debounce;
  String _query = '';
  final Set<String> _types = {};
  final Set<String> _bodyParts = {};
  final Set<String> _equipments = {};
  final Set<String> _muscles = {};
  late final Set<String> _addedIds;

  // Memoized filter options (perf T02): `exerciseFilterOptions` scans the
  // whole exercise catalog, so recompute only when the list instance changes.
  ExerciseFilterOptions? _cachedOptions;
  List<Exercise>? _cachedOptionsFor;

  @override
  void initState() {
    super.initState();
    _addedIds = {...widget.currentExercises};
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  ExerciseFilterOptions _optionsFor(List<Exercise> exercises) {
    if (_cachedOptions == null || !identical(_cachedOptionsFor, exercises)) {
      _cachedOptions = exerciseFilterOptions(exercises);
      _cachedOptionsFor = exercises;
    }
    return _cachedOptions!;
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
                onChanged: (v) {
                  _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 250), () {
                    if (!mounted) return;
                    setState(() => _query = v);
                  });
                },
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
                  final options = _optionsFor(exercises);
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
    final sets = await showDialog<List<PlannedSet>>(
      context: context,
      builder: (ctx) =>
          _PlannedSetsDialog(l10n: widget.l10n, exerciseName: exercise.name),
    );
    if (sets == null || !context.mounted) return;
    final repo = ref.read(workoutRepositoryProvider);
    await repo.addExerciseToWorkout(
      workoutId: widget.workoutId,
      exerciseId: exercise.id,
      plannedSets: sets,
    );
    if (context.mounted) {
      setState(() => _addedIds.add(exercise.id));
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
      return Image.file(
        File(exercise.imagePath!),
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

// ---------------------------------------------------------------------------
// Exercise-card header bits (notes, fact chips, compact media, history,
// sets progress)
// ---------------------------------------------------------------------------

/// Per-set completion status used for the leading icon, the actual-line color,
/// and the row tint. `pending` = unlogged, `partial` = 0 < logged < planned,
/// `done` = logged >= planned, `failed` = logged at zero.
enum _SetProgress { pending, partial, done, failed }

/// Colors/icon per [SetProgress.status]. Neutral for pending; success/warning/
/// error otherwise (uses `FitFatColors` + `colorScheme.error`).
(IconData, Color) _statusVisuals(ThemeData theme, _SetProgress status) {
  final statusColors = theme.extension<FitFatColors>()!;
  return switch (status) {
    _SetProgress.pending => (
      Icons.radio_button_unchecked,
      theme.colorScheme.outline,
    ),
    _SetProgress.partial => (Icons.timelapse, statusColors.warning),
    _SetProgress.done => (Icons.check_circle, statusColors.success),
    _SetProgress.failed => (Icons.cancel, theme.colorScheme.error),
  };
}

/// Progress classification for one set (planned vs logged actuals).
///
/// Weightlifting compares reps **and** weight (either below planned marks the
/// set partial); cardio compares duration/distance against their planned
/// values. "Failed" = the set was logged but at zero every actual value.
_SetProgress _setProgress(ExerciseSet set) {
  if (!set.isCompleted) return _SetProgress.pending;
  final reps = set.reps;
  final weightKg = set.weightKg;
  if (reps != null || weightKg != null) {
    final actualReps = set.actualReps;
    if (actualReps == null || actualReps == 0) return _SetProgress.failed;
    if (reps != null && actualReps < reps) return _SetProgress.partial;
    final actualWeight = set.actualWeightKg;
    if (weightKg != null && actualWeight != null && actualWeight < weightKg) {
      return _SetProgress.partial;
    }
    return _SetProgress.done;
  }
  final actualDuration = set.actualDurationMinutes;
  final actualDistance = set.actualDistanceMeters;
  final loggedZero =
      (actualDuration == null || actualDuration == 0) &&
      (actualDistance == null || actualDistance == 0);
  if (loggedZero) return _SetProgress.failed;
  if (set.durationMinutes != null &&
      actualDuration != null &&
      actualDuration < set.durationMinutes!) {
    return _SetProgress.partial;
  }
  if (set.distanceMeters != null &&
      actualDistance != null &&
      actualDistance < set.distanceMeters!) {
    return _SetProgress.partial;
  }
  return _SetProgress.done;
}

/// Per-exercise completion bar: `completed/total` sets.
final class _SetsProgressBar extends StatelessWidget {
  final int completed;
  final int total;

  const _SetsProgressBar({required this.completed, required this.total});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColors = theme.extension<FitFatColors>()!;
    final ratio = total == 0 ? 0.0 : completed / total;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(FitFatTokens.radiusFull),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 6,
                color: statusColors.success,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$completed/$total',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// History sheet for one exercise (past sessions via
/// `exerciseHistoryProvider`), opened from the card's history icon. Shows a
/// short empty state when there is nothing completed yet.
final class _HistorySheet extends ConsumerWidget {
  final String exerciseId;
  final AppLocalizations l10n;
  final ScrollController scrollController;

  const _HistorySheet({
    required this.exerciseId,
    required this.l10n,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(exerciseHistoryProvider(exerciseId));
    final unit = ref.watch(settingsProvider).weightUnit;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              l10n.exerciseDetailTabHistory,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: historyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text(l10n.errorWithMessage('$e')),
              data: (history) => history.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          l10n.exerciseDetailHistoryEmpty,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    )
                  : ListView(
                      controller: scrollController,
                      children: [
                        for (final entry in history)
                          _ExerciseHistoryRow(
                            entry: entry,
                            l10n: l10n,
                            unit: unit,
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

/// Compact per-workout history row: name + date, then volume (or duration for
/// cardio) + completed/total sets.
final class _ExerciseHistoryRow extends StatelessWidget {
  final ExerciseHistoryEntry entry;
  final AppLocalizations l10n;
  final WeightUnit unit;

  const _ExerciseHistoryRow({
    required this.entry,
    required this.l10n,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sets = entry.sets;
    final usesWeight = sets.any(
      (s) => s.weightKg != null || s.actualWeightKg != null,
    );
    var volume = 0.0;
    var duration = 0;
    for (final set in sets) {
      volume += set.totalVolume;
      duration += set.effectiveDurationMinutes;
    }
    final completed = sets.where((s) => s.isCompleted).length;
    final primary = usesWeight
        ? l10n.workoutSummaryValueKg(
            formatWeightValue(volume, unit),
            weightUnitLabel(unit),
          )
        : formatRestDuration(Duration(minutes: duration));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.workout.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormats.formatShortDate(context, entry.workout.date),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(primary, style: theme.textTheme.titleSmall),
              Text(
                '$completed/${sets.length}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Compact metadata pills (type/body-part/equipment) under the card title.
final class _CardFactChips extends StatelessWidget {
  final Exercise exercise;
  final AppLocalizations l10n;

  const _CardFactChips({required this.exercise, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final typeLabel = exercise.isWeightlifting
        ? l10n.exerciseTypeWeightlifting
        : l10n.exerciseTypeCardio;
    final bodyParts = splitTags(exercise.bodyPart);
    final equipments = splitTags(
      exercise.equipment,
    ).map(canonicalEquipmentTag).toList();
    final labels = [typeLabel, ...bodyParts, ...equipments];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [for (final label in labels) _CardFactChip(label: label)],
    );
  }
}

final class _CardFactChip extends StatelessWidget {
  final String label;

  const _CardFactChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(FitFatTokens.radiusFull),
      ),
      child: Text(label, style: theme.textTheme.labelSmall),
    );
  }
}

/// Compact media strip at the top of the exercise card: the bundled thumbnail
/// (tap → full-screen zoomable viewer) or, when a bundled video asset
/// initializes, an inline video with a play/pause overlay. Graceful fallbacks.
final class _CompactMedia extends StatefulWidget {
  final Exercise exercise;

  const _CompactMedia({required this.exercise});

  @override
  State<_CompactMedia> createState() => _CompactMediaState();
}

final class _CompactMediaState extends State<_CompactMedia> {
  static const double _height = 110;

  VideoPlayerController? _controller;
  bool _videoFailed = false;

  @override
  void initState() {
    super.initState();
    final path = widget.exercise.videoPath;
    if (path == null) return;
    final controller = VideoPlayerController.file(File(path));
    _controller = controller;
    controller
        .initialize()
        .then((_) {
          if (!mounted) return;
          setState(() {});
        })
        .catchError((_) {
          if (!mounted) return;
          setState(() => _videoFailed = true);
        });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exercise = widget.exercise;

    final Widget? image = exercise.imagePath == null
        ? null
        : GestureDetector(
            onTap: () => _openViewer(context),
            child: Container(
              height: _height,
              width: double.infinity,
              color: theme.colorScheme.surfaceContainerHighest,
              alignment: Alignment.center,
              child: Image.file(
                File(exercise.imagePath!),
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => _placeholder(theme),
              ),
            ),
          );

    final Widget? video = _controller != null && !_videoFailed
        ? Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: _height,
                width: double.infinity,
                child: VideoPlayer(_controller!),
              ),
              _CardVideoPlayPause(controller: _controller!),
            ],
          )
        : null;

    final child = video ?? image;
    if (child == null) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(FitFatTokens.radiusL),
      ),
      child: child,
    );
  }

  void _openViewer(BuildContext context) {
    final imagePath = widget.exercise.imagePath;
    if (imagePath == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _CardImageViewer(
          imagePath: imagePath,
          exerciseName: widget.exercise.name,
        ),
      ),
    );
  }

  Widget _placeholder(ThemeData theme) => Container(
    height: _height,
    color: theme.colorScheme.surfaceContainerHighest,
    alignment: Alignment.center,
    child: Icon(
      widget.exercise.isWeightlifting
          ? Icons.fitness_center
          : Icons.directions_run,
      size: 40,
      color: theme.colorScheme.onSurfaceVariant,
    ),
  );
}

/// Play/pause overlay for the compact video strip.
final class _CardVideoPlayPause extends StatelessWidget {
  final VideoPlayerController controller;

  const _CardVideoPlayPause({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final playing = value.isPlaying;
        return IconButton(
          style: IconButton.styleFrom(
            backgroundColor: Colors.black54,
            foregroundColor: Colors.white,
          ),
          onPressed: () => playing ? controller.pause() : controller.play(),
          icon: Icon(playing ? Icons.pause : Icons.play_arrow),
        );
      },
    );
  }
}

/// Full-screen, zoomable/panable image viewer for the compact strip.
final class _CardImageViewer extends StatelessWidget {
  final String imagePath;
  final String exerciseName;

  const _CardImageViewer({required this.imagePath, required this.exerciseName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(exerciseName, style: const TextStyle(color: Colors.white)),
      ),
      body: InteractiveViewer(
        minScale: 1,
        maxScale: 6,
        child: Center(
          child: Image.file(
            File(imagePath),
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Icon(
              Icons.broken_image_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

/// Exercise-level note editor (multiline). Returns the trimmed text, or an
/// empty string is not possible (Save pops null when empty via trim, the
/// caller maps empty → null).
final class _NoteDialog extends StatefulWidget {
  final String? initialText;
  final AppLocalizations l10n;

  const _NoteDialog({required this.initialText, required this.l10n});

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

final class _NoteDialogState extends State<_NoteDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialText ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return AlertDialog(
      title: Text(l10n.activeWorkoutExerciseNotesDialogTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 4,
        minLines: 2,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          hintText: l10n.activeWorkoutExerciseNotesHint,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}
