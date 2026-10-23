import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:fitfat/src/database/app_database.dart';
import 'package:fitfat/src/sync/local_backup.dart';
import 'package:flutter_test/flutter_test.dart';

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
    final dump = await dumpTables(source, {'Tasks'});
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
}
