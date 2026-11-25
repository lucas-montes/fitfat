import 'dart:io';

import 'package:drift/native.dart';
import 'package:fitfat/src/database/app_database.dart' hide Exercise;
import 'package:fitfat/src/exercise/repositories/exercise_repository.dart';
import 'package:fitfat/src/models/exercise.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  unusedServerIdsTests();

  late AppDatabase database;
  late ExerciseRepository repo;

  Exercise ex(String id, {String? imagePath}) => Exercise(
    id: id,
    name: id,
    exerciseType: 'weightlifting',
    imagePath: imagePath,
    createdAt: DateTime.fromMillisecondsSinceEpoch(1000),
  );

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repo = ExerciseRepository(database);
  });

  tearDown(() => database.close());

  test('removes from device without writing a sync tombstone', () async {
    final dir = await Directory.systemTemp.createTemp('ex_media');
    final image = File('${dir.path}/a.jpg')..writeAsStringSync('x');
    await repo.insert(ex('a', imagePath: image.path));
    await repo.insert(ex('b'));

    final removed = await repo.removeFromDevice({'a', 'b', 'missing'});

    expect(removed, 2);
    expect(await repo.getAll(), isEmpty);
    expect(image.existsSync(), isFalse);
    // No tombstone: a later exercise push must not delete them server-side.
    expect(await database.select(database.syncDeletes).get(), isEmpty);
    await dir.delete(recursive: true);
  });

  test('keeps exercises used by a workout or a template', () async {
    await repo.insert(ex('inWorkout'));
    await repo.insert(ex('inTemplate'));
    await repo.insert(ex('free'));
    await database.customStatement(
      "INSERT INTO workouts (id, name, date, created_at) VALUES ('w1', 'W', 0, 0)",
    );
    await database.customStatement(
      "INSERT INTO workout_exercises (id, workout_id, exercise_id, sort_order) "
      "VALUES ('we1', 'w1', 'inWorkout', 0)",
    );
    await database.customStatement(
      "INSERT INTO workout_templates (id, name, start_date, created_at, updated_at) VALUES ('t1', 'T', 0, 0, 0)",
    );
    await database.customStatement(
      "INSERT INTO workout_template_exercises (id, template_id, exercise_id, sort_order) "
      "VALUES ('te1', 't1', 'inTemplate', 0)",
    );

    expect(await repo.referencedIds(), {'inWorkout', 'inTemplate'});
    final removed = await repo.removeFromDevice({
      'inWorkout',
      'inTemplate',
      'free',
    });

    expect(removed, 1);
    expect((await repo.getAll()).map((e) => e.id).toSet(), {
      'inWorkout',
      'inTemplate',
    });
  });
}

void unusedServerIdsTests() {
  test('unusedServerIds keeps used and phone-made exercises', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    final repo = ExerciseRepository(database);
    Exercise ex(String id) => Exercise(
      id: id,
      name: id,
      exerciseType: 'weightlifting',
      createdAt: DateTime.fromMillisecondsSinceEpoch(1000),
    );
    for (final id in ['inWorkout', 'inTemplate', 'custom', 'unused']) {
      await repo.insert(ex(id));
    }
    await database.customStatement(
      "INSERT INTO workouts (id, name, date, created_at) VALUES ('w1', 'W', 0, 0)",
    );
    await database.customStatement(
      "INSERT INTO workout_exercises (id, workout_id, exercise_id, sort_order) "
      "VALUES ('we1', 'w1', 'inWorkout', 0)",
    );
    await database.customStatement(
      "INSERT INTO workout_templates (id, name, start_date, created_at, updated_at) "
      "VALUES ('t1', 'T', 0, 0, 0)",
    );
    await database.customStatement(
      "INSERT INTO workout_template_exercises (id, template_id, exercise_id, sort_order) "
      "VALUES ('te1', 't1', 'inTemplate', 0)",
    );

    // 'custom' is not in the server catalog: made on this phone, kept.
    final ids = await repo.unusedServerIds({
      'inWorkout',
      'inTemplate',
      'unused',
    });

    expect(ids, {'unused'});
    await database.close();
  });
}
