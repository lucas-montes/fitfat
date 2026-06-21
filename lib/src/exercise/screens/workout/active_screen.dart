import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitfat/l10n/app_localizations.dart';

import '../../providers/active_workout.dart';
import '../../providers/exercises.dart';
import '../../../adapters/drift/workout_repository.dart';
import '../../../models/workout.dart';
import 'add_exercise_sheet.dart';
import 'exercise_detail_screen.dart';

/// Active workout screen showing elapsed timer in the app bar, a scrollable
/// list of exercises (grouped from sets in the workout), an Add Exercise
/// button, and Complete/Cancel actions.
class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() =>
      _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  Timer? _timer;
  List<WeightSet> _weightSets = [];
  List<CardioSet> _cardioSets = [];
  bool _loadingSets = true;
  String? _setsError;
  String? _workoutId;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      // Force rebuild so workout.duration (which reads DateTime.now()) updates
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadSets(String workoutId) async {
    setState(() {
      _loadingSets = true;
      _setsError = null;
    });
    try {
      final repo = ref.read(workoutRepositoryProvider);
      final weight = await repo.getWeightSets(workoutId);
      final cardio = await repo.getCardioSets(workoutId);
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

  List<_ExerciseGroupInfo> _buildExerciseGroups() {
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

    final groups = <_ExerciseGroupInfo>[];
    for (final entry in totalCount.entries) {
      final exercise = exercises.where((e) => e.id == entry.key).firstOrNull;
      if (exercise != null) {
        groups.add(
          _ExerciseGroupInfo(
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

    // Trigger set loading when the active workout ID changes
    final currentWorkoutId = activeAsync.asData?.value?.id;
    if (currentWorkoutId != null && currentWorkoutId != _workoutId) {
      _workoutId = currentWorkoutId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadSets(currentWorkoutId);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: activeAsync.when(
          loading: () => Text(l10n.activeWorkout),
          error: (e, _) => Text(l10n.activeWorkout),
          data: (workout) {
            if (workout == null) return Text(l10n.activeWorkout);
            return Row(
              children: [
                Expanded(child: Text(workout.name)),
                Text(
                  _formatDuration(workout.duration),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      body: activeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (workout) {
          if (workout == null) {
            // No active workout — go to dashboard instead of pop
            // (pop fails when there's no previous route, e.g. direct deep-link)
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) context.go('/dashboard');
            });
            return const SizedBox.shrink();
          }

          if (_loadingSets) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_setsError != null) {
            return Center(child: Text('Error: $_setsError'));
          }

          final groups = _buildExerciseGroups();
          final hasExercises = groups.isNotEmpty;

          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            children: [
              // Timer display
              Center(
                child: Text(
                  _formatDuration(workout.duration),
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Exercise list
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

              // Empty state
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

              // Add Exercise button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openAddExerciseSheet(workout.id),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addExercise),
                ),
              ),
              const SizedBox(height: 12),

              // Complete Workout button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _complete(workout.id),
                  child: Text(l10n.completeSeance),
                ),
              ),
              const SizedBox(height: 12),

              // Cancel Workout button
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

  String _setCountLabel(AppLocalizations l10n, _ExerciseGroupInfo group) {
    if (group.completedSets == group.totalSets) {
      return '${l10n.setsCount(group.totalSets)} · ${l10n.done}';
    }
    return '${group.completedSets}/${group.totalSets} ${l10n.setsLower}';
  }

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

  Future<void> _complete(String workoutId) async {
    await ref.read(activeWorkoutProvider.notifier).complete();
    if (context.mounted) context.go('/workout-summary/$workoutId');
  }

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
      // Refresh sets when returning
      if (mounted) _loadSets(workoutId);
    }
  }

  Future<void> _cancel(String workoutId) async {
    await ref.read(activeWorkoutProvider.notifier).cancel();
    if (context.mounted) context.pop();
  }

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

/// Helper to describe one exercise's group of sets in the active workout.
class _ExerciseGroupInfo {
  final ExerciseDefinition exercise;
  final int totalSets;
  final int completedSets;

  const _ExerciseGroupInfo({
    required this.exercise,
    required this.totalSets,
    required this.completedSets,
  });
}
