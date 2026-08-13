import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/database_provider.dart';
import '../../models/exercise.dart';
import '../repositories/exercise_repository.dart';

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  return ExerciseRepository(ref.watch(databaseProvider));
});

// ---------------------------------------------------------------------------
// Exercise list provider
// ---------------------------------------------------------------------------

final exerciseListProvider = FutureProvider<List<Exercise>>((ref) async {
  return ref.watch(exerciseRepositoryProvider).getAll();
});

/// Loads a single exercise by id; resolves to `null` when it doesn't exist.
final exerciseByIdProvider = FutureProvider.family<Exercise?, String>((
  ref,
  id,
) async {
  return ref.watch(exerciseRepositoryProvider).getById(id);
});
