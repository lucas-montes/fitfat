import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/app_database.dart' as db;
import '../../database/database_provider.dart';
import '../../exercise/widgets/select_sheet.dart';

final class ExerciseCatalogEntry {
  final String id;
  final String name;
  final bool hasImage;
  const ExerciseCatalogEntry({
    required this.id,
    required this.name,
    this.hasImage = false,
  });
}

final class IngredientCatalogEntry {
  final String id;
  final String name;
  final String? barcode;
  const IngredientCatalogEntry({required this.id, required this.name, this.barcode});
}

final class ExerciseCatalogRepository {
  final db.AppDatabase _database;
  const ExerciseCatalogRepository(this._database);

  Future<List<ExerciseCatalogEntry>> getAll() async {
    final rows =
        await (_database.select(_database.exerciseCatalog)..orderBy([
              (t) => OrderingTerm(expression: t.name, mode: OrderingMode.asc),
            ]))
            .get();
    return rows
        .map(
          (r) => ExerciseCatalogEntry(
            id: r.id,
            name: r.name,
            hasImage: r.hasImage,
          ),
        )
        .toList();
  }

  /// Replaces the whole cache in one batch (single transaction) instead of
  /// N sequential statements — refresh stays off the tap path's budget.
  Future<void> upsertAll(List<ExerciseCatalogEntry> entries) async {
    await _database.batch((b) {
      b.deleteAll(_database.exerciseCatalog);
      b.insertAll(
        _database.exerciseCatalog,
        [
          for (final e in entries)
            db.ExerciseCatalogCompanion.insert(
              id: e.id,
              name: e.name,
              hasImage: Value(e.hasImage),
            ),
        ],
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  Future<void> clear() async {
    await _database.delete(_database.exerciseCatalog).go();
  }

  /// Hide-imported search in a single query: no full-table loads, no
  /// Dart-side filtering. Matches the picker's `contains` semantics.
  Future<List<ExerciseCatalogEntry>> searchHideImported(String query) async {
    final like = '%${_escapeLike(query.trim().toLowerCase())}%';
    final rows = await _database
        .customSelect(
          'SELECT id, name, has_image FROM exercise_catalog '
          "WHERE id NOT IN (SELECT id FROM exercises) AND (? = '' OR lower(name) LIKE ? ESCAPE '\\') "
          'ORDER BY name',
          variables: [Variable.withString(''), Variable.withString(like)],
        )
        .get();
    return [
      for (final r in rows)
        ExerciseCatalogEntry(
          id: r.read<String>('id'),
          name: r.read<String>('name'),
          hasImage: r.read<int>('has_image') != 0,
        ),
    ];
  }
}

final class IngredientCatalogRepository {
  final db.AppDatabase _database;
  const IngredientCatalogRepository(this._database);

  Future<List<IngredientCatalogEntry>> getAll() async {
    final rows =
        await (_database.select(_database.ingredientCatalog)..orderBy([
              (t) => OrderingTerm(expression: t.name, mode: OrderingMode.asc),
            ]))
            .get();
    return rows
        .map((r) => IngredientCatalogEntry(id: r.id, name: r.name, barcode: r.barcode))
        .toList();
  }

  /// Replaces the whole cache in one batch (single transaction).
  Future<void> upsertAll(List<IngredientCatalogEntry> entries) async {
    await _database.batch((b) {
      b.deleteAll(_database.ingredientCatalog);
      b.insertAll(
        _database.ingredientCatalog,
        [
          for (final e in entries)
            db.IngredientCatalogCompanion.insert(
              id: e.id,
              name: e.name,
              barcode: Value(e.barcode),
            ),
        ],
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  Future<void> clear() async {
    await _database.delete(_database.ingredientCatalog).go();
  }

  /// Hide-imported search in a single query (name or barcode).
  Future<List<DisplayItem>> searchHideImported(String query) async {
    final like = '%${_escapeLike(query.trim().toLowerCase())}%';
    final rows = await _database
        .customSelect(
          'SELECT id, name, barcode FROM ingredient_catalog '
          "WHERE id NOT IN (SELECT id FROM ingredients) AND (? = '' OR lower(name) LIKE ? ESCAPE '\\' OR lower(coalesce(barcode, '')) LIKE ? ESCAPE '\\') "
          'ORDER BY name',
          variables: [
            Variable.withString(''),
            Variable.withString(like),
            Variable.withString(like),
          ],
        )
        .get();
    return [
      for (final r in rows)
        DisplayItem(
          id: r.read<String>('id'),
          name: r.read<String>('name'),
          subtitle: r.readNullable<String>('barcode'),
        ),
    ];
  }
}

/// Escapes SQL LIKE wildcards so picker search keeps `contains` semantics.
String _escapeLike(String input) =>
    input.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_');

final exerciseCatalogRepositoryProvider = Provider<ExerciseCatalogRepository>((ref) {
  return ExerciseCatalogRepository(ref.watch(databaseProvider));
});

final ingredientCatalogRepositoryProvider = Provider<IngredientCatalogRepository>((ref) {
  return IngredientCatalogRepository(ref.watch(databaseProvider));
});
