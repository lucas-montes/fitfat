import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart' show rootBundle;
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../database/app_database.dart' show AppDatabase;
import '../../models/exercise.dart';
import '../repositories/exercise_repository.dart';

/// Imports the bundled exercise catalog (`assets/exercises.db`) into the live
/// database on first launch.
///
/// Idempotent: guarded by a one-time prefs flag plus skip-by-name, so re-runs
/// are no-ops and existing user exercises are never touched. Runs at startup
/// before `runApp` so the catalog rows exist before the first query.
final class CatalogImporter {
  static const flagKey = 'catalog_imported_v10';
  static const assetPath = 'assets/exercises.db';

  final SharedPreferences _prefs;
  final Logger _log = Logger('CatalogImporter');

  CatalogImporter(this._prefs);

  Future<void> run() async {
    if (_prefs.getBool(flagKey) ?? false) return;

    final Uint8List bytes;
    try {
      final data = await rootBundle.load(assetPath);
      bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } catch (e) {
      // Asset not bundled (e.g. tooling not run) — degrade silently and retry
      // on the next launch rather than burning the one-time flag.
      _log.warning('Catalog asset "$assetPath" missing; skipping import ($e)');
      return;
    }

    final database = AppDatabase();
    try {
      await importInto(database, bytes);
    } finally {
      await database.close();
    }
  }

  /// Core import step: materializes [bytes] as a temp SQLite file, reads the
  /// catalog rows, and merges them into [database].
  ///
  /// Locked rows are **upserted by id** — an existing locked row is refreshed
  /// in place (name, type and all metadata), a missing one is inserted. User
  /// rows (unlocked) are never touched, and an insert is skipped when a
  /// different row already uses the same name (skip-by-name guard). Sets the
  /// one-time flag when done. Returns the number of rows newly inserted.
  @visibleForTesting
  Future<int> importInto(AppDatabase database, Uint8List bytes) async {
    if (_prefs.getBool(flagKey) ?? false) return 0;

    Directory tempDir;
    try {
      tempDir = await getTemporaryDirectory();
    } catch (_) {
      tempDir = Directory.systemTemp;
    }
    final catalogFile = File('${tempDir.path}/fitfat_exercises_catalog.db');
    await catalogFile.writeAsBytes(bytes);

    final List<Exercise> catalogExercises;
    try {
      final catalog = sqlite3.open(catalogFile.path);
      try {
        catalogExercises = _readRows(catalog);
      } finally {
        catalog.dispose();
      }
    } finally {
      if (catalogFile.existsSync()) await catalogFile.delete();
    }
    if (catalogExercises.isEmpty) return 0;

    final repository = ExerciseRepository(database);
    // The whole merge runs in one transaction so 3,799 per-row statements
    // commit once instead of one-by-one (this is what the background startup
    // waits on the very first launch).
    var inserted = 0;
    var refreshed = 0;
    await database.transaction(() async {
      final existingById = {for (final e in await repository.getAll()) e.id: e};
      final existingNames = existingById.values.map((e) => e.name).toSet();
      for (final exercise in catalogExercises) {
        final existing = existingById[exercise.id];
        if (existing != null) {
          if (existing.isLocked) {
            await repository.updateCatalog(exercise);
            refreshed++;
          }
          continue;
        }
        if (existingNames.contains(exercise.name)) continue;
        await repository.insert(exercise);
        existingById[exercise.id] = exercise;
        existingNames.add(exercise.name);
        inserted++;
      }
    });
    await _prefs.setBool(flagKey, true);
    _log.info('Catalog import: $inserted new, $refreshed refreshed');
    return inserted;
  }

  static List<Exercise> _readRows(Database db) {
    final rows = db.select('SELECT * FROM exercises');
    final exercises = <Exercise>[];
    for (final row in rows) {
      exercises.add(
        Exercise(
          id: row['id'] as String,
          name: row['name'] as String,
          exerciseType: row['exerciseType'] as String,
          isLocked: (row['isLocked'] as int) == 1,
          bodyPart: row['bodyPart'] as String?,
          equipment: row['equipment'] as String?,
          primaryMuscle: row['primaryMuscle'] as String?,
          secondaryMuscle: row['secondaryMuscle'] as String?,
          instructions: _decode(row['instructions'] as String?),
          tips: _decode(row['tips'] as String?),
          faqs: row['faqs'] as String?,
          keywords: _decode(row['keywords'] as String?),
          imagePath: row['imagePath'] as String?,
          videoPath: row['videoPath'] as String?,
          createdAt: DateTime.fromMillisecondsSinceEpoch(
            row['createdAt'] as int,
          ),
        ),
      );
    }
    return exercises;
  }

  static List<String>? _decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded.cast<String>();
    } catch (_) {}
    return null;
  }
}
