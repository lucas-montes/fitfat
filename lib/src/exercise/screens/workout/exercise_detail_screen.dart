import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitfat/l10n/app_localizations.dart';

import '../../providers/active_workout.dart';
import '../../providers/exercise_history.dart';
import '../../providers/exercises.dart';
import '../../providers/exercise_detail.dart';
import '../../../models/workout.dart';
import 'widgets/cardio_set_tile.dart';
import 'widgets/exercise_set_form.dart';
import 'widgets/rest_elapsed_card.dart';
import 'widgets/weight_set_tile.dart';

/// Per-exercise set management within an active workout.
///
/// This screen is the main interaction point during a workout:
/// - **Swipe** left/right between exercises via `PageView`
/// - **Add sets** via an inline form at the top of each exercise page
/// - **Tap** an existing set to copy its values into the form for quick entry
/// - **Toggle completion** by tapping the check icon on a set tile
/// - **Edit/Delete** via long-press (PopupMenuButton on each tile)
/// - **Rest timer** shows elapsed time since last completed set
///
/// ### Exercise derivation
///
/// The list of exercises shown is **derived from existing sets** in the
/// workout, plus any initial exercise passed via [exerciseId] (needed when
/// the exercise was just added via the Add Exercise sheet and has no sets).
/// This avoids maintaining a separate exercise-workout mapping table.
///
/// ### Form strategy
///
/// The four `TextEditingController`s are **shared** across all exercise pages.
/// They are cleared on page change and when a set is successfully added.
/// This means the form values are per-session, not per-exercise.
class ExerciseWorkoutDetailScreen extends ConsumerStatefulWidget {
  final String workoutId;
  final String exerciseId;

  /// [exerciseId] is the initial exercise to display. The user can swipe
  /// to other exercises in the workout using the chip tabs or swiping.
  const ExerciseWorkoutDetailScreen({
    super.key,
    required this.workoutId,
    required this.exerciseId,
  });

  @override
  ConsumerState<ExerciseWorkoutDetailScreen> createState() =>
      _ExerciseWorkoutDetailScreenState();
}

class _ExerciseWorkoutDetailScreenState
    extends ConsumerState<ExerciseWorkoutDetailScreen> {
  // ── PageView controller ──
  late PageController _pageController;

  // ── Shared form controllers ──
  // These are reused across all exercise pages. They are cleared on page
  // change and after a successful set add. The values are NOT tied to a
  // specific exercise — they just hold whatever the user last typed.
  final _repsCtl = TextEditingController();
  final _weightCtl = TextEditingController();
  final _durationCtl = TextEditingController();
  final _notesCtl = TextEditingController();

  /// Provider key for this screen instance.
  (String, String) get _providerKey => (widget.workoutId, widget.exerciseId);

  @override
  void initState() {
    super.initState();
    // PageController starts at 0 by default. If the initial exercise is not
    // the first one, we sync it via ref.listen in build().
    _pageController = PageController();
    // Initial data load happens automatically in ExerciseDetailNotifier.build().
  }

  @override
  void dispose() {
    _repsCtl.dispose();
    _weightCtl.dispose();
    _durationCtl.dispose();
    _notesCtl.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Look up an ExerciseDefinition by ID from the exercise library provider.
  ExerciseDefinition? _findExercise(String exerciseId) {
    final exercises = ref.read(exerciseListProvider);
    try {
      return exercises.firstWhere((e) => e.id == exerciseId);
    } catch (_) {
      return null;
    }
  }

  /// Compute the next sort order from the current state.
  int _nextSortOrder(ExerciseDetailState state) {
    final ws = state.weightSets;
    final cs = state.cardioSets;
    final maxWeight = ws.isEmpty
        ? -1
        : ws.map((s) => s.sortOrder).reduce((a, b) => a > b ? a : b);
    final maxCardio = cs.isEmpty
        ? -1
        : cs.map((s) => s.sortOrder).reduce((a, b) => a > b ? a : b);
    return (maxWeight > maxCardio ? maxWeight : maxCardio) + 1;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Set operations
  // ─────────────────────────────────────────────────────────────────────────

  /// Toggle a weight set between completed and incomplete.
  ///
  /// When completing: copies planned values to actual values and sets
  /// completedAt = now. This is the standard "I did what I planned" path.
  /// When un-completing: clears completedAt (and actual values via copyWith).
  Future<void> _toggleWeightSetCompletion(WeightSet set) async {
    if (set.isCompleted) {
      await ref
          .read(activeWorkoutProvider.notifier)
          .updateWeightSet(
            set.copyWith(completedAt: null, clearCompletedAt: true),
          );
    } else {
      await ref
          .read(activeWorkoutProvider.notifier)
          .updateWeightSet(
            set.copyWith(
              actualReps: set.plannedReps,
              actualWeightKg: set.plannedWeightKg,
              completedAt: DateTime.now(),
            ),
          );
    }
    ref.read(exerciseDetailProvider(_providerKey).notifier).reload();
  }

  /// Toggle a cardio set between completed and incomplete.
  /// Same pattern as [_toggleWeightSetCompletion] for duration-based sets.
  Future<void> _toggleCardioSetCompletion(CardioSet set) async {
    if (set.isCompleted) {
      await ref
          .read(activeWorkoutProvider.notifier)
          .updateCardioSet(
            set.copyWith(completedAt: null, clearCompletedAt: true),
          );
    } else {
      await ref
          .read(activeWorkoutProvider.notifier)
          .updateCardioSet(
            set.copyWith(
              actualDurationMinutes: set.plannedDurationMinutes,
              completedAt: DateTime.now(),
            ),
          );
    }
    ref.read(exerciseDetailProvider(_providerKey).notifier).reload();
  }

  /// Copy an existing weight set's values into the form (tap-to-populate).
  /// Uses effective values (actual ?? planned) so the user sees the actual
  /// performed values if they differ from the plan.
  void _populateFromWeightSet(WeightSet set) {
    _repsCtl.text = set.effectiveReps.toString();
    _weightCtl.text = set.effectiveWeightKg.toString();
    _notesCtl.text = set.notes ?? '';
  }

  /// Copy an existing cardio set's values into the form.
  void _populateFromCardioSet(CardioSet set) {
    _durationCtl.text = set.effectiveDurationMinutes.toString();
    _notesCtl.text = set.notes ?? '';
  }

  /// Add a new set from the inline form values.
  ///
  /// Auto-completes the set (sets actualReps/actualWeightKg = planned and
  /// completedAt = now) ONLY for free-form workouts. For scheduled workouts,
  /// the set is saved with planned values only — the user completes it
  /// manually by tapping the check icon.
  Future<void> _addSetFromForm(ExerciseDefinition exercise) async {
    final isFreeform =
        (ref.read(activeWorkoutProvider).asData?.value?.isFreeform) ?? false;

    if (exercise.type == ExerciseType.weightlifting) {
      final reps = int.tryParse(_repsCtl.text);
      final weight = double.tryParse(_weightCtl.text);
      if (reps == null || reps <= 0 || weight == null || weight < 0) return;
      await ref
          .read(activeWorkoutProvider.notifier)
          .addWeightSet(
            workoutId: widget.workoutId,
            exerciseId: exercise.id,
            plannedReps: reps,
            plannedWeightKg: weight,
            actualReps: isFreeform ? reps : null,
            actualWeightKg: isFreeform ? weight : null,
            completedAt: isFreeform ? DateTime.now() : null,
            notes: _nullIfEmpty(_notesCtl.text),
            sortOrder: _nextSortOrder(
              ref.read(exerciseDetailProvider(_providerKey)),
            ),
          );
    } else {
      final dur = int.tryParse(_durationCtl.text);
      if (dur == null || dur <= 0) return;
      await ref
          .read(activeWorkoutProvider.notifier)
          .addCardioSet(
            workoutId: widget.workoutId,
            exerciseId: exercise.id,
            plannedDurationMinutes: dur,
            actualDurationMinutes: isFreeform ? dur : null,
            completedAt: isFreeform ? DateTime.now() : null,
            notes: _nullIfEmpty(_notesCtl.text),
            sortOrder: _nextSortOrder(
              ref.read(exerciseDetailProvider(_providerKey)),
            ),
          );
    }
    // Clear form on successful add so the user can immediately type the next set
    _repsCtl.clear();
    _weightCtl.clear();
    _durationCtl.clear();
    _notesCtl.clear();
    ref.read(exerciseDetailProvider(_providerKey).notifier).reload();
  }

  /// Open a dialog to edit a weight set's planned values.
  Future<void> _editWeightSet(WeightSet set) async {
    final result = await _showSetFormDialog(
      title: 'Edit Set',
      isWeight: true,
      initialReps: set.plannedReps,
      initialWeight: set.plannedWeightKg,
      initialNotes: set.notes,
    );
    if (result == null || !mounted) return;
    await ref
        .read(activeWorkoutProvider.notifier)
        .updateWeightSet(
          set.copyWith(
            plannedReps: result.$1,
            plannedWeightKg: result.$2,
            notes: result.$3,
          ),
        );
    ref.read(exerciseDetailProvider(_providerKey).notifier).reload();
  }

  /// Open a dialog to edit a cardio set's planned values.
  Future<void> _editCardioSet(CardioSet set) async {
    final result = await _showSetFormDialog(
      title: 'Edit Set',
      isWeight: false,
      initialDuration: set.plannedDurationMinutes,
      initialNotes: set.notes,
    );
    if (result == null || !mounted) return;
    await ref
        .read(activeWorkoutProvider.notifier)
        .updateCardioSet(
          set.copyWith(plannedDurationMinutes: result.$1, notes: result.$3),
        );
    ref.read(exerciseDetailProvider(_providerKey).notifier).reload();
  }

  /// Confirm and delete a set by ID.
  Future<void> _deleteSet(String setId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete set'),
        content: const Text('Remove this set?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(ctx)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalizations.of(ctx)!.delete),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(activeWorkoutProvider.notifier).removeSet(setId);
      ref.read(exerciseDetailProvider(_providerKey).notifier).reload();
    }
  }

  /// Shared dialog for editing weight and cardio sets.
  ///
  /// Returns `(intValue, doubleValue, notes?)` for weight sets
  /// or `(intValue, 0.0, notes?)` for cardio (second value unused).
  Future<(int, double, String?)?> _showSetFormDialog({
    required String title,
    required bool isWeight,
    int initialReps = 10,
    double initialWeight = 20.0,
    int initialDuration = 10,
    String? initialNotes,
  }) async {
    final repsCtl = TextEditingController(text: initialReps.toString());
    final weightCtl = isWeight
        ? TextEditingController(text: initialWeight.toString())
        : null;
    final durationCtl = !isWeight
        ? TextEditingController(text: initialDuration.toString())
        : null;
    final notesCtl = TextEditingController(text: initialNotes ?? '');

    final result = await showDialog<_FormResult>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isWeight) ...[
                TextField(
                  controller: repsCtl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Reps',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: weightCtl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ] else ...[
                TextField(
                  controller: durationCtl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Duration (min)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: notesCtl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx)!.cancel),
          ),
          FilledButton(
            onPressed: () {
              final reps = int.tryParse(repsCtl.text);
              if (reps == null || reps <= 0) return;
              if (isWeight) {
                final weight = double.tryParse(weightCtl!.text);
                if (weight == null || weight < 0) return;
                Navigator.pop(
                  ctx,
                  _FormResult(reps, weight, _nullIfEmpty(notesCtl.text)),
                );
              } else {
                final dur = int.tryParse(durationCtl!.text);
                if (dur == null || dur <= 0) return;
                Navigator.pop(
                  ctx,
                  _FormResult(dur, 0, _nullIfEmpty(notesCtl.text)),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    repsCtl.dispose();
    weightCtl?.dispose();
    durationCtl?.dispose();
    notesCtl.dispose();

    if (result == null) return null;
    return (result.intValue, result.doubleValue, result.notes);
  }

  /// Convert empty string to null (for optional note fields).
  String? _nullIfEmpty(String s) => s.trim().isEmpty ? null : s.trim();

  // ─────────────────────────────────────────────────────────────────────────
  // Widget building
  // ─────────────────────────────────────────────────────────────────────────

  /// Build a horizontal row of compact `ChoiceChip` tabs — one per exercise.
  /// No icons or checkmarks; only the text label with highlight for selection.
  /// Tapping a chip scrolls the PageView to the matching page.
  Widget _buildExerciseChips(ExerciseDetailState state) {
    final exercises = ref.read(exerciseListProvider);

    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: state.exerciseIds.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final exId = state.exerciseIds[index];
          final ex = exercises.where((e) => e.id == exId).firstOrNull;

          return FilterChip(
            selected: index == state.currentIndex,
            showCheckmark: false,
            label: Text(ex?.name ?? exId),
            labelStyle: Theme.of(context).textTheme.labelMedium,
            visualDensity: VisualDensity.compact,
            onSelected: (_) {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
          );
        },
      ),
    );
  }

  /// Build a single exercise page for the PageView.
  ///
  /// Shows (top to bottom):
  /// 1. Rest timer card (if resting)
  /// 2. Inline add-set form
  /// 3. List of weight sets (most recent first)
  /// 4. List of cardio sets (most recent first)
  Widget _buildExercisePage(String exerciseId, ExerciseDetailState state) {
    final exercise = _findExercise(exerciseId);
    if (exercise == null) {
      return const Center(child: Text('Exercise not found'));
    }

    final hasWeightSets = state.weightSets.isNotEmpty;
    final hasCardioSets = state.cardioSets.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Rest timer — shows elapsed time since the last completed set
        if (state.isResting && state.restStartedAt != null) ...[
          RestElapsedCard(
            startedAt: state.restStartedAt!,
            onSkip: () => ref
                .read(exerciseDetailProvider(_providerKey).notifier)
                .dismissRest(),
          ),
          const SizedBox(height: 8),
        ],

        // Inline add-set form
        ExerciseSetForm(
          exercise: exercise,
          repsController: _repsCtl,
          weightController: _weightCtl,
          durationController: _durationCtl,
          notesController: _notesCtl,
          onAddSet: () => _addSetFromForm(exercise),
        ),
        const SizedBox(height: 8),

        // Existing weight sets (most recent first, reversed in _filterForCurrentExercise)
        if (hasWeightSets) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Weight Sets',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ...state.weightSets.map(
            (set) => WeightSetTile(
              set: set,
              onTap: () => _populateFromWeightSet(set),
              onEdit: () => _editWeightSet(set),
              onDelete: () => _deleteSet(set.id),
              onToggleComplete: () => _toggleWeightSetCompletion(set),
            ),
          ),
        ],
        if (hasWeightSets && hasCardioSets) const SizedBox(height: 16),
        // Existing cardio sets
        if (hasCardioSets) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Cardio Sets',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ...state.cardioSets.map(
            (set) => CardioSetTile(
              set: set,
              onTap: () => _populateFromCardioSet(set),
              onEdit: () => _editCardioSet(set),
              onDelete: () => _deleteSet(set.id),
              onToggleComplete: () => _toggleCardioSetCompletion(set),
            ),
          ),
        ],

        // Recent exercise history (last sessions' sets for reference)
        const SizedBox(height: 8),
        _ExerciseHistorySnippet(exerciseId: exerciseId),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(exerciseDetailProvider(_providerKey));
    final currentExercise = _findExercise(state.currentExerciseId);

    // Sync PageController to the correct page after data finishes loading.
    // Defer to a post-frame callback so the PageView is guaranteed to be
    // built and attached to the controller before we access it.
    ref.listen(exerciseDetailProvider(_providerKey), (prev, next) {
      if (prev?.status != ExerciseDetailStatus.data &&
          next.status == ExerciseDetailStatus.data) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients &&
              next.currentIndex != (_pageController.page?.round() ?? 0)) {
            _pageController.jumpToPage(next.currentIndex);
          }
        });
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(currentExercise?.name ?? l10n.exercise)),
      body: _buildBody(state),
    );
  }

  /// Build the main body: loading/error states or chips + PageView.
  Widget _buildBody(ExerciseDetailState state) {
    switch (state.status) {
      case ExerciseDetailStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case ExerciseDetailStatus.error:
        return Center(child: Text('Error: ${state.errorMessage}'));
      case ExerciseDetailStatus.data:
        if (state.exerciseIds.isEmpty) {
          return Center(child: const Text('No exercises in this workout'));
        }

        return Column(
          children: [
            const SizedBox(height: 8),
            _buildExerciseChips(state),
            const SizedBox(height: 8),
            const Divider(height: 1),

            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  ref
                      .read(exerciseDetailProvider(_providerKey).notifier)
                      .selectExercise(index);
                },
                children: [
                  for (final exId in state.exerciseIds)
                    _buildExercisePage(exId, state),
                ],
              ),
            ),
          ],
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Exercise history snippet — collapsible mini-tiles
// ─────────────────────────────────────────────────────────────────────────────

/// Compact collapsible list of recent sessions for an exercise.
///
/// Each session shows the date and total volume as a header row with an
/// expand/collapse arrow. When expanded, individual sets render as compact
/// mini-tiles with weight, reps, and completion status.
class _ExerciseHistorySnippet extends ConsumerWidget {
  final String exerciseId;

  const _ExerciseHistorySnippet({required this.exerciseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(exerciseHistoryProvider(exerciseId));

    return historyAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (data) {
        if (data.sessions.isEmpty) return const SizedBox.shrink();
        return _CollapsibleSessionList(
          sessions: data.sessions.take(5).toList(),
        );
      },
    );
  }
}

/// Stateful list of collapsible session tiles, one per past workout.
class _CollapsibleSessionList extends StatefulWidget {
  final List<ExerciseHistorySession> sessions;

  const _CollapsibleSessionList({required this.sessions});

  @override
  State<_CollapsibleSessionList> createState() =>
      _CollapsibleSessionListState();
}

class _CollapsibleSessionListState extends State<_CollapsibleSessionList> {
  final Set<int> _expanded = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            for (int i = 0; i < widget.sessions.length; i++) ...[
              _buildSessionHeader(i, theme),
              if (_expanded.contains(i)) ...[
                const SizedBox(height: 4),
                ...widget.sessions[i].sets.map(
                  (s) => _buildMiniSetTile(s, theme),
                ),
              ],
              if (i < widget.sessions.length - 1) const SizedBox(height: 2),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSessionHeader(int index, ThemeData theme) {
    final session = widget.sessions[index];
    final isExpanded = _expanded.contains(index);
    final totalVolume = session.sets.fold<double>(
      0,
      (sum, s) => sum + s.totalWeight,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: () {
        setState(() {
          if (isExpanded) {
            _expanded.remove(index);
          } else {
            _expanded.add(index);
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          children: [
            Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              _formatDate(session.date),
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '${totalVolume.toStringAsFixed(1)} kg',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniSetTile(WeightSet set, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, top: 2, bottom: 2),
      child: Row(
        children: [
          Icon(
            set.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 14,
            color: set.isCompleted
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 6),
          Text(
            '${set.effectiveWeightKg} kg × ${set.effectiveReps} reps',
            style: theme.textTheme.bodySmall,
          ),
          if (set.isCompleted) ...[
            const Spacer(),
            Text(
              'done',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final day = days[date.weekday - 1];
    return '$day ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Form result helper
// ─────────────────────────────────────────────────────────────────────────────

/// Holds the result of the edit-set dialog.
/// [intValue] = reps or duration, [doubleValue] = weight (0 for cardio),
/// [notes] = optional notes.
class _FormResult {
  final int intValue;
  final double doubleValue;
  final String? notes;
  const _FormResult(this.intValue, this.doubleValue, this.notes);
}
