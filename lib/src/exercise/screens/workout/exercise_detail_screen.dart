import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitfat/l10n/app_localizations.dart';

import '../../providers/active_workout.dart';
import '../../providers/exercises.dart';
import '../../../adapters/drift/workout_repository.dart';
import '../../../models/workout.dart';

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
  // ── All sets across ALL exercises (loaded once from DB per _loadSets call) ──
  // These are the master lists. _weightSets / _cardioSets are filtered views.
  List<WeightSet> _allWeightSets = [];
  List<CardioSet> _allCardioSets = [];

  // ── Sets for the CURRENT exercise (filtered by _filterForCurrentExercise) ──
  List<WeightSet> _weightSets = [];
  List<CardioSet> _cardioSets = [];

  // ── Exercise navigation ──
  /// IDs of all exercises that have sets in this workout, plus the initial
  /// exercise if it has no sets yet. This drives both the chip tabs and the
  /// PageView pages.
  List<String> _exerciseIds = [];
  int _currentIndex = 0;
  late PageController _pageController;

  bool _loading = true;
  String? _error;

  // ── Shared form controllers ──
  // These are reused across all exercise pages. They are cleared on page
  // change and after a successful set add. The values are NOT tied to a
  // specific exercise — they just hold whatever the user last typed.
  final _repsCtl = TextEditingController();
  final _weightCtl = TextEditingController();
  final _durationCtl = TextEditingController();
  final _notesCtl = TextEditingController();

  // ── Rest timer state ──
  // Tracks whether we're in a rest period (between completed sets).
  // The timer starts after any set is completed and resets when the user
  // adds a new set, switches exercises, or taps "Skip".
  bool _isResting = false;
  DateTime? _restStartedAt;

  /// The exercise ID of the currently visible page.
  String get _currentExerciseId =>
      _exerciseIds.isNotEmpty ? _exerciseIds[_currentIndex] : widget.exerciseId;

  @override
  void initState() {
    super.initState();
    // PageController starts at 0 by default. If the initial exercise is not
    // the first one (e.g. a newly added exercise at index > 0), we jump to
    // it after _loadSets completes. See _loadSets for the sync logic.
    _pageController = PageController();
    _loadSets(initialExerciseId: widget.exerciseId);
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
  // Data loading
  // ─────────────────────────────────────────────────────────────────────────

  /// Load all sets for this workout from the database and derive the list
  /// of exercises to display.
  ///
  /// [initialExerciseId] is the exercise that should be shown first. It's
  /// typically `widget.exerciseId` which comes from the constructor.
  /// When called after adding a set (without initialExerciseId), the first
  /// exercise is shown (index 0).
  ///
  /// IMPORTANT: Exercises are derived from sets. If an exercise has no sets
  /// yet, it won't appear in `_exerciseIds` unless [initialExerciseId] is
  /// explicitly passed. This is the case when the user just added an exercise
  /// from the sheet and hasn't created any sets yet.
  Future<void> _loadSets({String? initialExerciseId}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(workoutRepositoryProvider);
      final allWeight = await repo.getWeightSets(widget.workoutId);
      final allCardio = await repo.getCardioSets(widget.workoutId);

      // Extract unique exercise IDs from the sets that exist in the DB.
      final ids = <String>{
        ...allWeight.map((s) => s.exerciseId),
        ...allCardio.map((s) => s.exerciseId),
      }.toList();

      // If the initial exercise has no sets yet (e.g. just added from sheet),
      // include it so the add form is visible. Without this, the screen would
      // show "No exercises in this workout" and the user couldn't add sets.
      if (initialExerciseId != null && !ids.contains(initialExerciseId)) {
        ids.add(initialExerciseId);
      }

      // Determine which page to show first.
      // When initialExerciseId is provided (e.g. from initState), show that
      // exercise's page. When reloading (no initialExerciseId, e.g. after
      // adding/toggling/deleting a set), preserve the current index so the
      // user stays on the same exercise — otherwise they'd be jumped back
      // to the first exercise after every set operation.
      final initialIdx =
          initialExerciseId != null && ids.contains(initialExerciseId)
          ? ids.indexOf(initialExerciseId)
          : _currentIndex < ids.length
          ? _currentIndex
          : 0;

      setState(() {
        _allWeightSets = allWeight;
        _allCardioSets = allCardio;
        _exerciseIds = ids;
        _currentIndex = initialIdx;
        _filterForCurrentExercise();
        _updateRestState();
        _loading = false;
      });

      // Sync the PageController with _currentIndex.
      // PageController() defaults to page 0. If the initial exercise is at
      // index > 0 (e.g. a newly added exercise that has no sets), we need
      // to jump to it. Without this, the PageView shows page 0 (some other
      // exercise) while the chips show the correct exercise selected — and
      // the user would fill in the form for the wrong exercise.
      //
      // IMPORTANT: Do NOT guard with `_pageController.hasClients` here.
      // At this point `setState()` was just called — the widget hasn't
      // rebuilt yet, so the PageView hasn't laid out and the controller
      // doesn't have clients. Always schedule the callback; the client
      // check happens inside after the frame renders.
      if (initialIdx > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _pageController.hasClients) {
            _pageController.jumpToPage(initialIdx);
          }
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Exercise filtering & helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Filter `_allWeightSets` / `_allCardioSets` to only include sets for
  /// the currently selected exercise. Results are stored in `_weightSets` /
  /// `_cardioSets` and reversed (most recent first).
  void _filterForCurrentExercise() {
    final exId = _currentExerciseId;
    _weightSets = _allWeightSets
        .where((s) => s.exerciseId == exId)
        .toList()
        .reversed
        .toList();
    _cardioSets = _allCardioSets
        .where((s) => s.exerciseId == exId)
        .toList()
        .reversed
        .toList();
  }

  /// Scan ALL sets (not just current exercise) for the most recent completion
  /// timestamp. Used by the rest timer to know when the last set was done,
  /// regardless of which exercise it belongs to.
  DateTime? _computeLastCompletedAt() {
    DateTime? latest;
    for (final s in _allWeightSets) {
      if (s.completedAt != null &&
          (latest == null || s.completedAt!.isAfter(latest))) {
        latest = s.completedAt;
      }
    }
    for (final s in _allCardioSets) {
      if (s.completedAt != null &&
          (latest == null || s.completedAt!.isAfter(latest))) {
        latest = s.completedAt;
      }
    }
    return latest;
  }

  /// Start the rest timer based on the most recently completed set.
  /// Called after loading sets or after completing a new set.
  void _updateRestState() {
    final last = _computeLastCompletedAt();
    if (last != null) {
      _restStartedAt = last;
      _isResting = true;
    }
  }

  /// Dismiss the rest timer card (user tapped "Skip").
  void _dismissRest() {
    _isResting = false;
    _restStartedAt = null;
  }

  /// Called when the PageView page changes (swipe or chip tap).
  /// Resets the form fields, switches filtered sets, and dismisses rest.
  void _onPageChanged(int index) {
    if (!mounted) return;
    setState(() {
      _currentIndex = index;
      _filterForCurrentExercise();
      _isResting = false;
      _restStartedAt = null;
    });
    _repsCtl.clear();
    _weightCtl.clear();
    _durationCtl.clear();
    _notesCtl.clear();
  }

  /// Look up an ExerciseDefinition by ID from the exercise library provider.
  /// Uses [_currentExerciseId] when [exerciseId] is null.
  ExerciseDefinition? _findExercise([String? exerciseId]) {
    final eid = exerciseId ?? _currentExerciseId;
    final exercises = ref.read(exerciseListProvider);
    try {
      return exercises.firstWhere((e) => e.id == eid);
    } catch (_) {
      return null;
    }
  }

  /// Compute the next sort order for a new set (one more than the max
  /// existing sort order across both weight and cardio sets).
  int _nextSortOrder() {
    final maxWeight = _weightSets.isEmpty
        ? -1
        : _weightSets.map((s) => s.sortOrder).reduce((a, b) => a > b ? a : b);
    final maxCardio = _cardioSets.isEmpty
        ? -1
        : _cardioSets.map((s) => s.sortOrder).reduce((a, b) => a > b ? a : b);
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
    _loadSets();
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
    _loadSets();
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
            sortOrder: _nextSortOrder(),
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
            sortOrder: _nextSortOrder(),
          );
    }
    // Clear form on successful add so the user can immediately type the next set
    _repsCtl.clear();
    _weightCtl.clear();
    _durationCtl.clear();
    _notesCtl.clear();
    _loadSets();
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
    _loadSets();
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
    _loadSets();
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
      _loadSets();
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

  /// Build a horizontal row of `ChoiceChip` tabs — one per exercise.
  /// Tapping a chip scrolls the PageView to the matching page.
  Widget _buildExerciseChips() {
    final exercises = ref.read(exerciseListProvider);

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _exerciseIds.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final exId = _exerciseIds[index];
          final ex = exercises.where((e) => e.id == exId).firstOrNull;
          final icon = ex?.type == ExerciseType.cardio
              ? Icons.directions_run
              : Icons.fitness_center;

          return ChoiceChip(
            selected: index == _currentIndex,
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16),
                const SizedBox(width: 4),
                Text(ex?.name ?? exId),
              ],
            ),
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

  /// Build the inline add-set form for a given exercise.
  ///
  /// Shows:
  /// - Reps + Weight fields for weightlifting exercises
  /// - Duration field for cardio exercises
  /// - Optional notes field (always shown)
  /// - "Add Set" button at the bottom
  ///
  /// The form is empty by default — no pre-populated values. The user can
  /// tap an existing set tile to copy its values into these fields.
  Widget _buildAddForm(ExerciseDefinition exercise) {
    final isWeight = exercise.type == ExerciseType.weightlifting;
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.addSet, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            if (isWeight) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _repsCtl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Reps',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _weightCtl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Weight (kg)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              TextField(
                controller: _durationCtl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duration (min)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtl,
              maxLines: 1,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => _addSetFromForm(exercise),
                child: Text(l10n.addSet),
              ),
            ),
          ],
        ),
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
  Widget _buildExercisePage(String exerciseId) {
    final exercise = _findExercise(exerciseId);
    if (exercise == null) {
      return const Center(child: Text('Exercise not found'));
    }

    final hasWeightSets = _weightSets.isNotEmpty;
    final hasCardioSets = _cardioSets.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Rest timer — shows elapsed time since the last completed set
        if (_isResting && _restStartedAt != null) ...[
          _RestElapsedCard(
            startedAt: _restStartedAt!,
            onSkip: () => setState(_dismissRest),
          ),
          const SizedBox(height: 8),
        ],

        // Inline add-set form
        _buildAddForm(exercise),
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
          ..._weightSets.map(
            (set) => _WeightSetTile(
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
          ..._cardioSets.map(
            (set) => _CardioSetTile(
              set: set,
              onTap: () => _populateFromCardioSet(set),
              onEdit: () => _editCardioSet(set),
              onDelete: () => _deleteSet(set.id),
              onToggleComplete: () => _toggleCardioSetCompletion(set),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentExercise = _findExercise();

    return Scaffold(
      // AppBar title shows the current exercise name (from the visible page)
      appBar: AppBar(title: Text(currentExercise?.name ?? l10n.exercise)),
      body: _buildBody(),
    );
  }

  /// Build the main body: loading/error states or chips + PageView.
  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }
    if (_exerciseIds.isEmpty) {
      return Center(child: const Text('No exercises in this workout'));
    }

    return Column(
      children: [
        const SizedBox(height: 8),
        _buildExerciseChips(),
        const SizedBox(height: 8),
        const Divider(height: 1),

        // PageView with one page per exercise. The controller is synced
        // to the initial exercise in _loadSets.
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: [
              for (final exId in _exerciseIds) _buildExercisePage(exId),
            ],
          ),
        ),
      ],
    );
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

/// Format a [DateTime] as "HH:mm" for display on set tiles.
String _formatHHmm(DateTime dt) {
  return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

/// Build a subtitle widget showing an optional completed time and notes.
/// Time and notes are separated by " · " when both present.
/// Returns null when nothing to show (no time, no notes).
Widget? _setSubtitle({DateTime? completedTime, String? notes}) {
  final parts = <String>[];
  if (completedTime != null) parts.add(_formatHHmm(completedTime));
  if (notes != null && notes.isNotEmpty) parts.add(notes);
  if (parts.isEmpty) return null;
  return Text(parts.join(' · '), style: const TextStyle(fontSize: 12));
}

// ─────────────────────────────────────────────────────────────────────────────
// Weight set tile
// ─────────────────────────────────────────────────────────────────────────────

/// A single weight set row showing reps × weight, completion status,
/// completion time, and notes. Supports tap-to-copy, edit, delete, and
/// toggle-complete via the trailing popup menu.
class _WeightSetTile extends StatelessWidget {
  final WeightSet set;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleComplete;

  const _WeightSetTile({
    required this.set,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleComplete,
  });

  @override
  Widget build(BuildContext context) {
    final completed = set.isCompleted;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Opacity(
        opacity: completed ? 0.6 : 1.0,
        child: ListTile(
          leading: InkWell(
            onTap: onToggleComplete,
            borderRadius: BorderRadius.circular(20),
            child: Icon(
              completed ? Icons.check_circle : Icons.check_circle_outline,
              color: completed ? Colors.green : null,
            ),
          ),
          title: Text('${set.effectiveReps} × ${set.effectiveWeightKg} kg'),
          subtitle: _setSubtitle(
            completedTime: completed ? set.completedAt : null,
            notes: set.notes,
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') onEdit();
              if (value == 'toggle') onToggleComplete();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(
                value: 'toggle',
                child: Text(completed ? 'Mark incomplete' : 'Mark complete'),
              ),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rest elapsed timer card
// ─────────────────────────────────────────────────────────────────────────────

/// Shows the elapsed time since the last completed set (rest period).
///
/// Displayed as a card in `secondaryContainer` color above the add-set form.
/// Ticks every second. Has a "Skip" button to dismiss early.
/// Auto-resets when a new set is completed or the user switches exercises.
class _RestElapsedCard extends StatefulWidget {
  final DateTime startedAt;
  final VoidCallback onSkip;

  const _RestElapsedCard({required this.startedAt, required this.onSkip});

  @override
  State<_RestElapsedCard> createState() => _RestElapsedCardState();
}

class _RestElapsedCardState extends State<_RestElapsedCard> {
  /// 1-second timer to update the elapsed time display.
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Duration get _elapsed => DateTime.now().difference(widget.startedAt);

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.timer_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rest',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                  Text(
                    _formatDuration(_elapsed),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(onPressed: widget.onSkip, child: const Text('Skip')),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cardio set tile
// ─────────────────────────────────────────────────────────────────────────────

/// A single cardio set row showing duration, completion status, and notes.
/// Same interaction pattern as [_WeightSetTile] but for duration-based sets.
class _CardioSetTile extends StatelessWidget {
  final CardioSet set;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleComplete;

  const _CardioSetTile({
    required this.set,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleComplete,
  });

  @override
  Widget build(BuildContext context) {
    final completed = set.isCompleted;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Opacity(
        opacity: completed ? 0.6 : 1.0,
        child: ListTile(
          leading: InkWell(
            onTap: onToggleComplete,
            borderRadius: BorderRadius.circular(20),
            child: Icon(
              completed ? Icons.check_circle : Icons.check_circle_outline,
              color: completed ? Colors.green : null,
            ),
          ),
          title: Text('${set.effectiveDurationMinutes} min'),
          subtitle: _setSubtitle(
            completedTime: completed ? set.completedAt : null,
            notes: set.notes,
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') onEdit();
              if (value == 'toggle') onToggleComplete();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(
                value: 'toggle',
                child: Text(completed ? 'Mark incomplete' : 'Mark complete'),
              ),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
