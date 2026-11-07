import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:fitfat/src/app/startup_gate.dart';
import 'package:fitfat/src/dashboard/providers/dashboard.dart';
import 'package:fitfat/src/database/app_database.dart' as db;
import 'package:fitfat/src/database/database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pins the *window the provider chooses*.
///
/// The repository tests pass an explicit range, so they cannot catch a provider
/// that builds the wrong range — which is exactly where the reported bug was:
/// the dashboard showed last weekend's sessions as the current week. These
/// tests read `weeklyWorkoutStatsProvider` itself, so the window and the query
/// are exercised together.
void main() {
  late db.AppDatabase database;
  late ProviderContainer container;

  Future<({double totalVolumeKg, int totalMinutes, int daysTrained})> stats()
      async => container.read(weeklyWorkoutStatsProvider.future);

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(database),
      ],
    );
    // The gate is false until real preferences load; the aggregate returns
    // zeroes behind it, which would make every assertion below vacuous. The
    // gate class is final, so it is opened through its own API rather than
    // substituted.
    container.read(startupGateProvider.notifier).complete();
  });

  tearDown(() {
    container.dispose();
    database.close();
  });

  /// A completed workout on [day], with no sets.
  Future<void> complete(String id, DateTime day) async {
    await database.into(database.workouts).insert(
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

  /// The window the provider is expected to use, restated independently so the
  /// assertions do not simply echo the implementation back at themselves.
  DateTime mondayOf(DateTime day) =>
      DateTime(day.year, day.month, day.day)
          .subtract(Duration(days: day.weekday - DateTime.monday));

  test('counts a session earlier in the current week', () async {
    final monday = mondayOf(DateTime.now());
    // The most recent day in the current week that has certainly happened.
    final elapsedDays = DateTime.now().weekday - DateTime.monday;
    await complete('thisWeek', monday.add(Duration(days: elapsedDays)));

    expect((await stats()).daysTrained, 1);
  });

  test('excludes the day before this week\'s Monday', () async {
    final now = DateTime.now();
    final monday = mondayOf(now);
    final lastWeekSunday = monday.subtract(const Duration(days: 1));

    // That day is inside a rolling seven-day window on every weekday except
    // Sunday, where the rolling window and the calendar week coincide and there
    // is nothing to distinguish.
    final rollingStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 6));
    if (lastWeekSunday.isBefore(rollingStart)) {
      markTestSkipped(
        'today is Sunday: a rolling seven-day window equals the calendar week',
      );
    }

    await complete('lastWeek', lastWeekSunday);

    expect(
      (await stats()).daysTrained,
      0,
      reason: 'the day before this week\'s Monday is last week, not this week',
    );
  });

  test('excludes a whole previous week', () async {
    final now = DateTime.now();
    final monday = mondayOf(now);
    for (var i = 1; i <= 7; i++) {
      await complete('last$i', monday.subtract(Duration(days: i)));
    }

    expect((await stats()).daysTrained, 0);
  });

  test('reports zero on a week with nothing logged', () async {
    final result = await stats();
    expect(result.daysTrained, 0);
    expect(result.totalMinutes, 0);
    expect(result.totalVolumeKg, 0);
  });
}
