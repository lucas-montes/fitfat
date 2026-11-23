import 'package:drift/native.dart';
import 'package:fitfat/src/database/app_database.dart';
import 'package:fitfat/src/exercise/repositories/exercise_repository.dart';
import 'package:fitfat/src/sync/exercise_sync_client.dart';
import 'package:flutter_test/flutter_test.dart';

/// The server rates each catalogue exercise with a MET (energy cost). The
/// phone only stores what it pulls; null means "not rated".
void main() {
  test('the pull payload carries met, integer or decimal', () {
    final (walking, _, _) = ExerciseSyncClient.parseExercise({
      'id': 'walking',
      'name': 'Walking',
      'exerciseType': 'cardio',
      'met': 3.5,
    }, 1000)!;
    expect(walking.met, 3.5);

    // JSON has one number type; a whole value can arrive as an int.
    final (rowing, _, _) = ExerciseSyncClient.parseExercise({
      'id': 'rowing',
      'name': 'Rowing',
      'met': 7,
    }, 1000)!;
    expect(rowing.met, 7.0);

    // Older servers send no field at all.
    final (custom, _, _) = ExerciseSyncClient.parseExercise({
      'id': 'custom',
      'name': 'Skating',
    }, 1000)!;
    expect(custom.met, isNull);
  });

  test('met survives the database and a server refresh', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final repo = ExerciseRepository(database);

    final (pulled, _, _) = ExerciseSyncClient.parseExercise({
      'id': 'jump_rope',
      'name': 'Jump Rope',
      'exerciseType': 'cardio',
    }, 1000)!;
    await repo.upsert(pulled);
    expect((await repo.getById('jump_rope'))!.met, isNull);

    // The next pull carries the newly rated value and refreshes the row.
    await repo.upsert(pulled.copyWith(met: 11.8));
    expect((await repo.getById('jump_rope'))!.met, 11.8);
  });
}
