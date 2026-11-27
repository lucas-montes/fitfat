import 'package:drift/native.dart';
import 'package:fitfat/src/database/app_database.dart' as db;
import 'package:fitfat/src/diet/repositories/meal_repository.dart';
import 'package:fitfat/src/models/meal_entry.dart';
import 'package:flutter_test/flutter_test.dart';

/// Meals have no name in the UI; the column stays and stores an empty string.
void main() {
  late db.AppDatabase database;
  late MealRepository meals;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    meals = MealRepository(database);
  });

  tearDown(() => database.close());

  test('an unnamed meal persists with an empty name', () async {
    await meals.insert(
      MealEntry(
        id: 'm1',
        name: '',
        eatenAt: DateTime(2026, 3, 12, 14, 30),
        createdAt: DateTime(2026, 3, 12, 14, 30),
        items: const [],
      ),
    );
    final loaded = await meals.getAll();
    expect(loaded, hasLength(1));
    expect(loaded.single.name, isEmpty);
  });

  test('a named meal still round-trips', () async {
    await meals.insert(
      MealEntry(
        id: 'm2',
        name: 'Breakfast',
        eatenAt: DateTime(2026, 3, 12, 8),
        createdAt: DateTime(2026, 3, 12, 8),
        items: const [],
      ),
    );
    expect((await meals.getAll()).single.name, 'Breakfast');
  });
}
