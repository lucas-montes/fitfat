import 'package:drift/native.dart';
import 'package:fitfat/src/database/app_database.dart' show AppDatabase;
import 'package:fitfat/src/planner/repositories/task_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late TaskRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = TaskRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('insert, update and read back a planner task', () async {
    final day = DateTime(2026, 8, 23);
    final created = newTask(
      day: day,
      title: 'Water the plants',
      sortOrder: 0,
      notes: 'Kitchen + balcony',
    );
    await repository.insert(created);

    final byDay = await repository.getByDay(day);
    expect(byDay.map((t) => t.title), ['Water the plants']);
    expect(byDay.first.notes, 'Kitchen + balcony');

    final updated = created.copyWith(title: 'Water all plants', done: true);
    await repository.update(updated);

    final reloaded = await repository.getById(created.id);
    expect(reloaded, isNotNull);
    expect(reloaded!.title, 'Water all plants');
    expect(reloaded.done, isTrue);

    final byDayAfter = await repository.getByDay(day);
    expect(byDayAfter.first.title, 'Water all plants');
    expect(byDayAfter.first.done, isTrue);
  });

  test(
    'rollover carries a past task to today and keeps dueDate in step',
    () async {
      final now = DateTime.now();
      final yesterday = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: 1));
      final created = newTask(
        day: yesterday,
        title: 'Carry me',
        dueDate: yesterday,
      );
      await repository.insert(created);

      await repository.rolloverPastTasks();

      final reloaded = await repository.getById(created.id);
      expect(reloaded, isNotNull);
      final today = DateTime(now.year, now.month, now.day);
      // The task itself moved to today…
      expect(reloaded!.day, today);
      // …and its due date moved with it, so a later no-change edit cannot
      // regress the row back to yesterday.
      expect(reloaded.dueDate, today);
    },
  );

  test('getUpcoming surfaces untimed tasks after timed ones', () async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    await repository.insert(
      newTask(day: today, title: 'Anytime errand', sortOrder: 0),
    );
    await repository.insert(
      newTask(
        day: today,
        title: 'Timed run',
        startTimeMinutes: 7 * 60,
        sortOrder: 1,
      ),
    );

    final upcoming = await repository.getUpcoming(today);

    expect(upcoming.map((t) => t.title), ['Timed run', 'Anytime errand']);
  });
}
