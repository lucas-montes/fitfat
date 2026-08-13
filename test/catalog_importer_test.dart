import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:fitfat/src/database/app_database.dart' show AppDatabase;
import 'package:fitfat/src/exercise/repositories/exercise_repository.dart';
import 'package:fitfat/src/exercise/services/catalog_importer.dart';
import 'package:fitfat/src/models/exercise.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late ExerciseRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = ExerciseRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  /// Builds a minimal catalog DB (Exercises schema) with the given rows.
  Future<Uint8List> catalogBytes(List<(String, String, bool)> rows) async {
    final file = File('${Directory.systemTemp.path}/test_catalog.db');
    if (file.existsSync()) file.deleteSync();
    final db = sqlite3.open(file.path);
    db.execute('''
      CREATE TABLE exercises (
        id TEXT NOT NULL PRIMARY KEY,
        name TEXT NOT NULL,
        exerciseType TEXT NOT NULL,
        isLocked INTEGER NOT NULL DEFAULT 0,
        bodyPart TEXT, equipment TEXT, primaryMuscle TEXT, secondaryMuscle TEXT,
        instructions TEXT, tips TEXT, faqs TEXT, keywords TEXT,
        imagePath TEXT, videoPath TEXT, createdAt INTEGER NOT NULL
      )
    ''');
    final insert = db.prepare('''
      INSERT INTO exercises (
        id, name, exerciseType, isLocked, bodyPart, equipment, primaryMuscle,
        secondaryMuscle, instructions, tips, faqs, keywords, imagePath,
        videoPath, createdAt
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''');
    for (final (id, name, locked) in rows) {
      insert.execute([
        id,
        name,
        'weightlifting',
        locked ? 1 : 0,
        'Chest',
        'Barbell',
        'Pecs',
        'Triceps',
        '["step 1"]',
        '["tip 1"]',
        'faq text',
        '["kw"]',
        'assets/exercises/images/$id.png',
        null,
        1767225600000,
      ]);
    }
    insert.dispose();
    db.dispose();
    final bytes = file.readAsBytesSync();
    file.deleteSync();
    return bytes;
  }

  test('imports new rows, skips existing names, marks locked', () async {
    await repository.insert(
      Exercise(
        id: 'user-bench',
        name: 'Bench Press',
        exerciseType: 'weightlifting',
        createdAt: DateTime(2026, 1, 1),
      ),
    );

    final bytes = await catalogBytes([
      ('catalog-bench', 'Bench Press', true),
      ('catalog-squat', 'Squat', true),
    ]);
    final prefs = await SharedPreferences.getInstance();
    final imported = await CatalogImporter(prefs).importInto(database, bytes);

    expect(imported, 1);

    final all = await repository.getAll();
    final squat = all.singleWhere((e) => e.id == 'catalog-squat');
    expect(squat.name, 'Squat');
    expect(squat.isLocked, isTrue);
    expect(squat.bodyPart, 'Chest');
    expect(squat.instructions, ['step 1']);
    expect(squat.imagePath, 'assets/exercises/images/catalog-squat.png');

    final userBench = all.singleWhere((e) => e.id == 'user-bench');
    expect(userBench.name, 'Bench Press');
    expect(userBench.isLocked, isFalse);
  });

  test('is idempotent via one-time flag and skip-by-name', () async {
    final bytes = await catalogBytes([('catalog-squat', 'Squat', true)]);
    final prefs = await SharedPreferences.getInstance();

    expect(await CatalogImporter(prefs).importInto(database, bytes), 1);
    // Second run: flag is set, nothing happens.
    expect(await CatalogImporter(prefs).importInto(database, bytes), 0);
    expect((await repository.getAll()).length, 1);
    expect(prefs.getBool(CatalogImporter.flagKey), isTrue);
  });

  test(
    'refresh updates locked rows in place, never touches user rows',
    () async {
      // A previously-imported locked catalog row with stale metadata, plus a
      // user-created row. The one-time flag is NOT set, so the import merges.
      await repository.insert(
        Exercise(
          id: 'catalog-squat',
          name: 'Old Squat',
          exerciseType: 'weightlifting',
          isLocked: true,
          bodyPart: 'Old',
          equipment: 'Old',
          createdAt: DateTime(2026, 1, 1),
        ),
      );
      await repository.insert(
        Exercise(
          id: 'user-row',
          name: 'My Custom',
          exerciseType: 'weightlifting',
          createdAt: DateTime(2026, 1, 1),
        ),
      );

      final bytes = await catalogBytes([('catalog-squat', 'Squat', true)]);
      final prefs = await SharedPreferences.getInstance();
      final imported = await CatalogImporter(prefs).importInto(database, bytes);

      expect(imported, 0); // no new rows inserted

      final all = await repository.getAll();
      final refreshed = all.singleWhere((e) => e.id == 'catalog-squat');
      expect(refreshed.name, 'Squat');
      expect(refreshed.bodyPart, 'Chest');
      expect(refreshed.equipment, 'Barbell');
      expect(refreshed.isLocked, isTrue);

      final userRow = all.singleWhere((e) => e.id == 'user-row');
      expect(userRow.name, 'My Custom');
      expect(userRow.isLocked, isFalse);
    },
  );
}
