import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../adapters/drift/workout_repository.dart';
import 'set_management_service.dart';
import 'workout_lifecycle_service.dart';
import 'workout_services.dart';

// ---------------------------------------------------------------------------
// Existing services — pure-Dart, stateless, no dependencies
// ---------------------------------------------------------------------------

final workoutSessionServiceProvider = Provider<WorkoutSessionService>((ref) {
  return WorkoutSessionService();
});

final exerciseLibraryServiceProvider = Provider<ExerciseLibraryService>((ref) {
  return ExerciseLibraryService();
});

final progressionServiceProvider = Provider<ProgressionService>((ref) {
  return ProgressionService();
});

// ---------------------------------------------------------------------------
// New services
// ---------------------------------------------------------------------------

final setManagementServiceProvider = Provider<SetManagementService>((ref) {
  return SetManagementService(ref.read(workoutRepositoryProvider));
});

final workoutLifecycleServiceProvider = Provider<WorkoutLifecycleService>((
  ref,
) {
  return WorkoutLifecycleService(ref.read(workoutRepositoryProvider));
});
