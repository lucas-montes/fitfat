import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database_providers.dart';
import '../adapters/drift/drift_meal_repository.dart';
import '../repositories/interfaces/meal_repository.dart';

final mealRepositoryProvider = Provider<MealRepository>((ref) {
  final db = ref.read(databaseProvider);
  return DriftMealRepository(db);
});

/// Development provider that uses a separate, file-backed database so
/// development and tests can use a real SQLite DB without touching the
/// production database file.
final devMealRepositoryProvider = Provider<MealRepository>((ref) {
  final db = ref.read(devDatabaseProvider);
  return DriftMealRepository(db);
});
