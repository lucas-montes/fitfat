import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/database_provider.dart';
import '../repositories/workout_template_repository.dart';

final workoutTemplateRepositoryProvider = Provider<WorkoutTemplateRepository>((
  ref,
) {
  return WorkoutTemplateRepository(ref.watch(databaseProvider));
});

/// All workout templates, alphabetical.
final workoutTemplateListProvider = FutureProvider((ref) {
  return ref.watch(workoutTemplateRepositoryProvider).getAll();
});

/// A single template with its full blueprint, or null when missing.
final workoutTemplateDetailsProvider = FutureProvider.family((ref, String id) {
  return ref.watch(workoutTemplateRepositoryProvider).getWithDetails(id);
});
