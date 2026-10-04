import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fitfat/src/database/app_database.dart' as db;
import 'package:fitfat/src/exercise/repositories/workout_repository.dart';
import 'package:fitfat/src/models/workout.dart';
import 'package:flutter_test/flutter_test.dart';

/// "Days trained" counts distinct calendar days, not workouts — two sessions on
/// one day are one day trained. That is easy to get wrong, and it is what the
/// dashboard's weekly card now shows, so it is pinned here.
void main() {
  late db.AppDatabase database;
  late WorkoutRepository workouts;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    workouts = WorkoutRepository(database);
  });

  tearDown(() => database.close());

  /// Inserts a completed workout on [day]. No sets — this is about the day
  /// counting, not the volume join.
  Future<void> complete(String id, DateTime day) async {
    await database
        .into(database.workouts)
        .insert(
          db.WorkoutsCompanion.insert(
            id: id,
            name: id,
            date: day.millisecondsSinceEpoch,
            startedAt: Value(day.millisecondsSinceEpoch),
            completedAt: Value(
              day.add(const Duration(minutes: 45)).millisecondsSinceEpoch,
            ),
            createdAt: day.millisecondsSinceEpoch,
          ),
        );
  }

  /// The window the dashboard uses: today and the six days before it.
  DateTime fromDay() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day - 6);
  }

  test('one workout is one day', () async {
    await complete('w1', DateTime.now().subtract(const Duration(days: 1)));
    final stats = await workouts.getVolumeAndMinutesSince(fromDay());
    expect(stats.daysTrained, 1);
    expect(stats.minutes, 45);
  });

  test('two workouts on the same day count as one day', () async {
    final day = DateTime.now().subtract(const Duration(days: 2));
    await complete('w1', day);
    await complete('w2', day.add(const Duration(hours: 5)));

    final stats = await workouts.getVolumeAndMinutesSince(fromDay());
    expect(
      stats.daysTrained,
      1,
      reason: 'a second session the same day is not another day trained',
    );
    // Both still contribute their duration.
    expect(stats.minutes, 90);
  });

  test('workouts on different days count separately', () async {
    await complete('w1', DateTime.now().subtract(const Duration(days: 1)));
    await complete('w2', DateTime.now().subtract(const Duration(days: 3)));
    await complete('w3', DateTime.now().subtract(const Duration(days: 5)));

    final stats = await workouts.getVolumeAndMinutesSince(fromDay());
    expect(stats.daysTrained, 3);
  });

  test('workouts outside the window are ignored', () async {
    await complete('old', DateTime.now().subtract(const Duration(days: 30)));
    expect((await workouts.getVolumeAndMinutesSince(fromDay())).daysTrained, 0);
  });

  test('no workouts is zero days', () async {
    final stats = await workouts.getVolumeAndMinutesSince(fromDay());
    expect(stats.daysTrained, 0);
    expect(stats.minutes, 0);
    expect(stats.volumeKg, 0);
  });
}
