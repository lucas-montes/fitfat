import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../adapters/drift/workout_repository.dart';
import '../../models/workout.dart';

final workoutListProvider =
    NotifierProvider<WorkoutListNotifier, AsyncValue<List<Workout>>>(
      WorkoutListNotifier.new,
    );

/// Manages the list of workouts for calendar/schedule views.
/// State: `AsyncValue<List<Workout>>`
class WorkoutListNotifier extends Notifier<AsyncValue<List<Workout>>> {
  DriftWorkoutRepository? _repo;

  @override
  AsyncValue<List<Workout>> build() {
    _repo = ref.read(workoutRepositoryProvider);
    loadUpcoming();
    return const AsyncValue.loading();
  }

  /// Load upcoming workouts (scheduledDate >= today, startedAt IS NULL).
  Future<void> loadUpcoming() async {
    try {
      final workouts = await _repo!.listUpcoming();
      state = AsyncValue.data(workouts);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Load workouts for a specific date.
  Future<void> loadByDate(DateTime date) async {
    try {
      final workouts = await _repo!.listByDate(date);
      state = AsyncValue.data(workouts);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Create a new scheduled workout with pre-filled sets.
  Future<Workout> create(
    String name,
    List<WeightSet> weightSets,
    List<CardioSet> cardioSets, {
    DateTime? scheduledDate,
    WorkoutSource source = WorkoutSource.manual,
  }) async {
    final workout = Workout(
      id: _generateId(),
      name: name,
      scheduledDate: scheduledDate,
      startedAt: null,
      completedAt: null,
      source: source,
    );
    await _repo!.save(workout, weightSets: weightSets, cardioSets: cardioSets);
    await loadUpcoming();
    return workout;
  }

  Future<void> delete(String id) async {
    await _repo!.delete(id);
    await loadUpcoming();
  }

  String _generateId() {
    // Use a simple timestamp-based ID; uuid can be added later if needed
    return 'wo_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }
}
