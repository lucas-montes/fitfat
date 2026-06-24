import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../adapters/drift/workout_repository.dart';
import '../../adapters/interfaces/workout_repository.dart';
import '../../models/workout.dart';

final workoutHistoryProvider =
    NotifierProvider<WorkoutHistoryNotifier, AsyncValue<List<Workout>>>(
      WorkoutHistoryNotifier.new,
    );

/// Manages completed workouts for history views.
/// State: `AsyncValue<List<Workout>>`
class WorkoutHistoryNotifier extends Notifier<AsyncValue<List<Workout>>> {
  WorkoutRepository? _repo;

  @override
  AsyncValue<List<Workout>> build() {
    _repo = ref.read(workoutRepositoryProvider);
    load();
    return const AsyncValue.loading();
  }

  /// Load all completed workouts.
  Future<void> load() async {
    try {
      final workouts = await _repo!.listCompleted();
      state = AsyncValue.data(workouts);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Load completed workouts in a date range.
  Future<void> loadByDateRange(DateTime from, DateTime to) async {
    try {
      final workouts = await _repo!.listCompleted(from: from, to: to);
      state = AsyncValue.data(workouts);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => load();
}
