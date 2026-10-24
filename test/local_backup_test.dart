import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:fitfat/src/database/app_database.dart';
import 'package:fitfat/src/sync/local_backup.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  late AppDatabase source;
  late AppDatabase target;

  setUp(() {
    source = AppDatabase.forTesting(NativeDatabase.memory());
    target = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await source.close();
    await target.close();
  });

  test('dump → import round-trips selected entities including link rows',
      () async {
    await source.into(source.tasks).insert(
      TasksCompanion.insert(
        id: 't1',
        date: 100,
        title: 'Round trip',
        done: 0,
        taskStatus: const Value(0),
        carryOver: const Value(false),
        sortOrder: 3,
        createdAt: 50,
      ),
    );
    await source.into(source.taskGoals).insert(
      TaskGoalsCompanion.insert(taskId: 't1', goalId: 'g1'),
    );
    await source.into(source.goals).insert(
      GoalsCompanion.insert(
        id: 'g1',
        title: 'Fitness',
        startDate: 100,
        reminderTimeMinutes: const Value(480),
        description: const Value(null),
        createdAt: 50,
        updatedAt: 60,
      ),
    );
    await source.into(source.notes).insert(
      NotesCompanion.insert(
        id: 'n1',
        title: 'Local only',
        body: const Value('do not import'),
        updatedAt: 12,
        createdAt: 10,
      ),
    );

    final dump = await dumpTables(source, {'Tasks', 'Goals'});
    expect(dump.keys, containsAll(['tasks', 'task_tags', 'goals']));
    expect(dump.containsKey('notes'), isFalse);

    final imported = await importJson(target, {'Tasks', 'Goals'}, {
      for (final e in dump.entries) e.key: e.value,
    });
    expect(imported, 3);

    final task = await (target.select(
      target.tasks,
    )..where((t) => t.id.equals('t1'))).getSingle();
    expect(task.title, 'Round trip');
    expect(task.sortOrder, 3);
    final goal = await (target.select(
      target.goals,
    )..where((t) => t.id.equals('g1'))).getSingle();
    expect(goal.title, 'Fitness');
    final link =
        await target.select(target.taskGoals).getSingle();
    expect(link.taskId, 't1');
    // Notes were not selected, so nothing leaks across.
    expect(await (target.select(target.notes)).get(), isEmpty);
  });

  test('import upserts an existing row in the target database', () async {
    await target.into(target.tasks).insert(
      TasksCompanion.insert(
        id: 't1',
        date: 100,
        title: 'Stale target copy',
        done: 0,
        taskStatus: const Value(0),
        carryOver: const Value(false),
        sortOrder: 0,
        createdAt: 50,
      ),
    );
    final imported = await importJson(target, {'Tasks'}, {
      'tasks': [
        {'id': 't1', 'date': 100, 'title': 'Fresh copy', 'done': 1,
         'task_status': 0, 'carry_over': 0, 'sort_order': 0, 'created_at': 50},
      ],
    });
    expect(imported, 1);
    final task = await (target.select(
      target.tasks,
    )..where((t) => t.id.equals('t1'))).getSingle();
    expect(task.title, 'Fresh copy');
    expect(task.done, 1);
  });

  group('whole-database import', () {
    late Directory dir;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('fitfat-import-test');
    });

    tearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    Future<File> writeValidBackup() async {
      final path = p.join(dir.path, 'backup.sqlite');
      final db = AppDatabase.forTesting(NativeDatabase(File(path)));
      await db.into(db.tasks).insert(
        TasksCompanion.insert(
          id: 't1',
          date: 100,
          title: 'From backup',
          done: 0,
          taskStatus: const Value(0),
          carryOver: const Value(false),
          sortOrder: 0,
          createdAt: 50,
        ),
      );
      await db.close();
      return File(path);
    }

    test('sniffs content instead of the file extension', () async {
      // WhatsApp strips the suffix entirely; the picker must still accept it.
      final whatsapp = File(p.join(dir.path, 'DOC-20261023-WA0002.'));
      await whatsapp.writeAsBytes([
        ...'SQLite format 3\u0000'.codeUnits,
        0,
        0,
      ]);
      expect(await detectBackupFile(whatsapp), BackupFormat.sqlite);

      final json = File(p.join(dir.path, 'export'));
      await json.writeAsString('\uFEFF\n  {"tasks": []}');
      expect(await detectBackupFile(json), BackupFormat.json);

      final junk = File(p.join(dir.path, 'notes.sqlite'));
      await junk.writeAsString('just text');
      expect(await detectBackupFile(junk), BackupFormat.unknown);
    });

    test('accepts a database this build can migrate', () async {
      final backup = await writeValidBackup();
      expect(
        await validateSqliteBackup(backup, maxSchemaVersion: 37),
        isNull,
      );
    });

    test('rejects a file that is not a database', () async {
      final junk = File(p.join(dir.path, 'broken.sqlite'));
      await junk.writeAsString('not a database at all');
      expect(
        await validateSqliteBackup(junk, maxSchemaVersion: 37),
        isNotNull,
      );
      await expectLater(
        prepareWholeDbImport(junk, maxSchemaVersion: 37, tempDir: dir),
        throwsA(isA<BackupException>()),
      );
    });

    test('rejects a database from a newer app version', () async {
      final backup = await writeValidBackup();
      final db = AppDatabase.forTesting(NativeDatabase(backup));
      await db.customSelect('SELECT 1').get();
      await db.customStatement('PRAGMA user_version = 99');
      await db.close();
      expect(
        await validateSqliteBackup(backup, maxSchemaVersion: 37),
        contains('newer app version'),
      );
    });

    test('rejects an unrelated SQLite file', () async {
      final path = p.join(dir.path, 'other.sqlite');
      final raw = sqlite.sqlite3.open(path);
      raw.execute('CREATE TABLE unrelated (id TEXT)');
      raw.execute('PRAGMA user_version = 1');
      raw.dispose();
      expect(
        await validateSqliteBackup(File(path), maxSchemaVersion: 37),
        contains('not a FitFat backup'),
      );
    });

    test('prepares a migrated, self-contained copy', () async {
      final backup = await writeValidBackup();
      final ready = await prepareWholeDbImport(
        backup,
        maxSchemaVersion: 37,
        tempDir: dir,
      );
      expect(await ready.exists(), isTrue);
      expect(p.basename(ready.path), endsWith('-ready.sqlite'));

      final restored = AppDatabase.forTesting(NativeDatabase(ready));
      final tasks = await restored.select(restored.tasks).get();
      expect(tasks.single.title, 'From backup');
      await restored.close();
      // The snapshot is complete on its own: no WAL sidecar needed.
      expect(await File('${ready.path}-wal').exists(), isFalse);
    });
  });
}
