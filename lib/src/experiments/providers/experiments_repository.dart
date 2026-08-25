import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/database_provider.dart';
import '../repositories/experiment_repository.dart';

/// Repository provider for experiments. Kept separate from the aggregate
/// [experiments.dart] providers so the planner timeline can depend on it
/// without importing the whole experiments feature graph.
final experimentRepositoryProvider = Provider<ExperimentRepository>((ref) {
  return ExperimentRepository(ref.watch(databaseProvider));
});
