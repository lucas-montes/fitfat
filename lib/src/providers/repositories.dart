import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database_providers.dart';
import '../repositories/interfaces/ingredient_repository.dart';
import '../database/app_database.dart' as db;

final ingredientRepositoryProvider = Provider<IngredientRepository>((ref) {
  final db = ref.read(databaseProvider);
  return DriftIngredientRepository(db);
});

/// Development provider that uses a separate, file-backed database so
/// development and tests can use a real SQLite DB without touching the
/// production database file.
final devIngredientRepositoryProvider = Provider<IngredientRepository>((ref) {
  final db = ref.read(devDatabaseProvider);
  return DriftIngredientRepository(db);
});
