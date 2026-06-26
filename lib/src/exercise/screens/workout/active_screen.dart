import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitfat/l10n/app_localizations.dart';

import '../../providers/active_workout.dart';
import '../../providers/exercises.dart';
import '../../services/providers.dart';
import '../../../models/workout.dart';
import 'add_exercise_sheet.dart';
import 'exercise_detail_screen.dart';
import 'widgets/exercise_group_info.dart';

/// Full-screen active workout with elapsed timer, exercise list grouped from
/// sets, an Add Exercise button, and Complete/Cancel actions.
///
/// This screen is shown at route `/active-workout` (outside the tab shell so
/// there's no bottom nav bar). It can be reached by:
/// 1. Starting a free-form or scheduled workout from the Training tab
/// 2. Tapping the persistent notification
/// 3. Deep link from outside the app
///
/// State strategy:
/// - The `activeWorkoutProvider` holds the current Workout (or null). We watch
///   it via `ref.watch` so the UI reacts to state changes (e.g. null → dashboard).
/// - Sets are loaded separately via `_loadSets()` because they change
///   independently (add/complete sets while the workout itself stays the same).
/// - A 1-second Timer forces rebuilds so `workout.duration` (which reads
///   `DateTime.now()`) stays current.
class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() =>
      _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  /// Periodic timer to update the elapsed time display every second.
  /// `workout.duration` is computed from `DateTime.now() - startedAt`, so
  /// we need a `setState` to trigger rebuilds.
  Timer? _timer;

  /// All weight sets for the current workout, loaded from DB.
  List<WeightSet> _weightSets = [];

  /// All cardio sets for the current workout, loaded from DB.
  List<CardioSet> _cardioSets = [];

  bool _loadingSets = true;
  String? _setsError;

  /// Cached workout ID used to detect when the active workout changes.
  String? _workoutId;

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

  /// Fetch all sets (weight + cardio) for this workout from the repository.
  ///
  /// Called on initial load and whenever the user returns from the exercise
  /// detail screen (where sets may have been added or modified).
  Future<void> _loadSets(String workoutId) async {
    setState(() {
      _loadingSets = true;
      _setsError = null;
    });
    try {
      final service = ref.read(setManagementServiceProvider);
      final (weight, cardio) = await service.loadSets(workoutId);
      if (mounted) {
        setState(() {
          _weightSets = weight;
          _cardioSets = cardio;
          _loadingSets = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _setsError = e.toString();
          _loadingSets = false;
        });
      }
    }
  }

  /// Group sets by exercise and compute completion counts.
  ///
  /// Each group shows the exercise name, icon, and a "X/Y sets · done" label.
  /// Only exercises that appear in `exerciseListProvider` are included
  /// (exercises deleted from the library won't show, but their orphan sets
  /// remain in the DB for data integrity).
  List<ExerciseGroupInfo> _buildExerciseGroups() {
    final exercises = ref.read(exerciseListProvider);
    final Map<String, int> totalCount = {};
    final Map<String, int> completedCount = {};

    for (final set in _weightSets) {
      totalCount[set.exerciseId] = (totalCount[set.exerciseId] ?? 0) + 1;
      if (set.isCompleted) {
        completedCount[set.exerciseId] =
            (completedCount[set.exerciseId] ?? 0) + 1;
      }
    }
    for (final set in _cardioSets) {
      totalCount[set.exerciseId] = (totalCount[set.exerciseId] ?? 0) + 1;
      if (set.isCompleted) {
        completedCount[set.exerciseId] =
            (completedCount[set.exerciseId] ?? 0) + 1;
      }
    }

    final groups = <ExerciseGroupInfo>[];
    for (final entry in totalCount.entries) {
      final exercise = exercises.where((e) => e.id == entry.key).firstOrNull;
      if (exercise != null) {
        groups.add(
          ExerciseGroupInfo(
            exercise: exercise,
            totalSets: entry.value,
            completedSets: completedCount[entry.key] ?? 0,
          ),
        );
      }
    }
    groups.sort((a, b) => a.exercise.name.compareTo(b.exercise.name));
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final activeAsync = ref.watch(activeWorkoutProvider);

    // When the workout ID changes (new workout started, or we loaded from DB),
    // trigger a fresh set load. This is done in a post-frame callback because
    // we're already inside a build method — async work in build is forbidden.
    final currentWorkoutId = activeAsync.asData?.value?.id;
    if (currentWorkoutId != null && currentWorkoutId != _workoutId) {
      _workoutId = currentWorkoutId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadSets(currentWorkoutId);
      });
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: activeAsync.when(
          loading: () => Text(l10n.activeWorkout),
          error: (e, _) => Text(l10n.activeWorkout),
          data: (workout) {
            if (workout == null) return Text(l10n.activeWorkout);
            return Text(workout.name);
          },
        ),
      ),
      body: activeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (workout) {
          // ── Case 1: No active workout → redirect to dashboard ──
          // This happens when:
          // - Workout was cancelled (state = null)
          // - Deep link to /active-workout with no active workout in DB
          // We use addPostFrameCallback because context.go inside build() is
          // not allowed (would cause a build-in-progress error).
          if (workout == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) context.go('/dashboard');
            });
            return const SizedBox.shrink();
          }

          // ── Loading state ──
          if (_loadingSets) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_setsError != null) {
            return Center(child: Text('Error: $_setsError'));
          }

          // ── Main workout UI ──
          final groups = _buildExerciseGroups();
          final hasExercises = groups.isNotEmpty;

          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            children: [
              // Timer display (large, centered)
              Center(
                child: Text(
                  _formatDuration(workout.duration),
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Exercise list — each card navigates to the exercise detail screen
              if (hasExercises) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    l10n.exercises,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ...groups.map(
                  (group) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        group.exercise.type == ExerciseType.cardio
                            ? Icons.directions_run
                            : Icons.fitness_center,
                      ),
                      title: Text(group.exercise.name),
                      subtitle: Text(_setCountLabel(l10n, group)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          _navigateToExercise(workout.id, group.exercise.id),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Empty state — shown when the workout has no sets yet
              if (!hasExercises) ...[
                const SizedBox(height: 48),
                Center(
                  child: Icon(
                    Icons.fitness_center,
                    size: 48,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    l10n.noExercisesAdded,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Add Exercise — opens a bottom sheet to pick from the library
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openAddExerciseSheet(workout.id),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addExercise),
                ),
              ),
              const SizedBox(height: 12),

              // Complete Workout — marks the workout as done, goes to summary
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _complete(workout.id),
                  child: Text(l10n.completeSeance),
                ),
              ),
              const SizedBox(height: 12),

              // Cancel Workout — deletes everything, goes back
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _cancel(workout.id),
                  child: Text(l10n.cancelSeance),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Build a localized label like "3 sets · done" or "1/3 sets".
  String _setCountLabel(AppLocalizations l10n, ExerciseGroupInfo group) {
    if (group.completedSets == group.totalSets) {
      return '${l10n.setsCount(group.totalSets)} · ${l10n.done}';
    }
    return '${group.completedSets}/${group.totalSets} ${l10n.setsLower}';
  }

  /// Open the exercise detail screen for a specific exercise.
  ///
  /// Uses `Navigator.push` (not GoRouter) since this is a sub-navigation
  /// within the active workout flow. Returns when the user pops back.
  Future<void> _navigateToExercise(String workoutId, String exerciseId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExerciseWorkoutDetailScreen(
          workoutId: workoutId,
          exerciseId: exerciseId,
        ),
      ),
    );
    // Refresh sets when returning from detail screen
    if (mounted) _loadSets(workoutId);
  }

  /// Complete the current workout and navigate to the summary screen.
  ///
  /// DESIGN NOTE: The notifier's `complete()` updates `completedAt` on the
  /// in-memory workout (so watchers see it as inactive) but does NOT set
  /// `state = null`. If it set `state = null`, the build method above would
  /// schedule a dashboard redirect via postFrameCallback. That redirect would
  /// race with the summary navigation below and the dashboard would win.
  ///
  /// Instead, `complete()` only does DB work, updates the in-memory workout's
  /// completedAt, and stops the foreground service. We navigate directly to
  /// the summary here with no competing state change.
  Future<void> _complete(String workoutId) async {
    await ref.read(activeWorkoutProvider.notifier).complete();
    if (context.mounted) context.go('/workout-summary/$workoutId');
  }

  /// Open the Add Exercise bottom sheet, then navigate to the detail screen.
  ///
  /// The flow:
  /// 1. showModalBottomSheet → user picks an exercise
  /// 2. Navigator.push → ExerciseWorkoutDetailScreen for that exercise
  ///    (so they can immediately add their first set)
  /// 3. On return, refresh the set list so the new exercise appears
  Future<void> _openAddExerciseSheet(String workoutId) async {
    final exercise = await showModalBottomSheet<ExerciseDefinition>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddExerciseSheet(),
    );
    if (exercise != null && mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ExerciseWorkoutDetailScreen(
            workoutId: workoutId,
            exerciseId: exercise.id,
          ),
        ),
      );
      if (mounted) _loadSets(workoutId);
    }
  }

  /// Cancel (delete) the workout and pop back.
  Future<void> _cancel(String workoutId) async {
    await ref.read(activeWorkoutProvider.notifier).cancel();
    if (context.mounted) context.pop();
  }

  /// Format a Duration as mm:ss or hh:mm:ss.
  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
