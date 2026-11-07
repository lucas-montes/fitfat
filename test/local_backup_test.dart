import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:fitfat/src/database/app_database.dart';
import 'package:fitfat/src/sync/local_backup.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

TasksCompanion _task(String id, String title, {int sortOrder = 0}) =>
    TasksCompanion.insert(
      id: id,
      date: 100,
      title: title,
      done: 0,
      taskStatus: const Value(0),
      carryOver: const Value(false),
      sortOrder: sortOrder,
      createdAt: 50,
    );

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
    await source.into(source.tasks).insert(_task('t1', 'Round trip', sortOrder: 3));
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
    final link = await target.select(target.taskGoals).getSingle();
    expect(link.taskId, 't1');
    // Notes were not selected, so nothing leaks across.
    expect(await (target.select(target.notes)).get(), isEmpty);
  });

  test('import upserts an existing row in the target database', () async {
    await target.into(target.tasks).insert(_task('t1', 'Stale target copy'));
    final imported = await importJson(target, {'Tasks'}, {
      'tasks': [
        {
          'id': 't1',
          'date': 100,
          'title': 'Fresh copy',
          'done': 1,
          'task_status': 0,
          'carry_over': 0,
          'sort_order': 0,
          'created_at': 50,
        },
      ],
    });
    expect(imported, 1);
    final task = await (target.select(
      target.tasks,
    )..where((t) => t.id.equals('t1'))).getSingle();
    expect(task.title, 'Fresh copy');
    expect(task.done, 1);
  });

  test('a replace import clears rows the backup does not contain', () async {
    await target.into(target.tasks).insert(_task('t1', 'Stale target copy'));
    await target.into(target.tasks).insert(_task('t2', 'Deleted elsewhere'));

    final imported = await importJson(target, {'Tasks'}, {
      'tasks': [
        {
          'id': 't1',
          'date': 100,
          'title': 'Fresh copy',
          'done': 0,
          'task_status': 0,
          'carry_over': 0,
          'sort_order': 0,
          'created_at': 50,
        },
      ],
    }, replace: true);

    expect(imported, 1);
    final tasks = await target.select(target.tasks).get();
    expect(tasks.single.id, 't1');
    expect(tasks.single.title, 'Fresh copy');
  });

  test('a partial selection pulls in the groups it references', () async {
    expect(expandEntities({'Tasks'}), {'Tasks', 'Tags'});
    expect(expandEntities({'Meals'}), {'Meals', 'Foods', 'Ingredients'});
    expect(expandEntities({'Workouts'}), {'Workouts', 'Exercises'});
  });

  test('gzip archive round-trips and is sniffed without a suffix', () async {
    final dump = <String, Object?>{
      'tasks': [
        {'id': 't1', 'title': 'Compressed'},
      ],
    };
    final bytes = encodeBackup(dump);
    expect(bytes.sublist(0, 2), [0x1F, 0x8B]);
    expect(decodeBackupBytes(bytes), dump);

    final dir = await Directory.systemTemp.createTemp('fitfat-backup-test');
    addTearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });
    // WhatsApp strips the suffix entirely; content sniffing must still work.
    final whatsapp = File(p.join(dir.path, 'DOC-20261026-WA0003.'));
    await whatsapp.writeAsBytes(bytes);
    expect(await detectBackupFile(whatsapp), BackupFormat.jsonGzip);
  });

  test('plain JSON is still accepted', () {
    expect(
      decodeBackupBytes(utf8.encode('{"tasks": []}')),
      {'tasks': <dynamic>[]},
    );
    expect(detectBackupFormat(utf8.encode('\uFEFF\n {"tasks": []}')),
        BackupFormat.json);
    expect(detectBackupFormat(utf8.encode('just text')), BackupFormat.unknown);
  });
}
