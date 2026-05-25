# Small Read/Write Database Example

This example shows the simplest version of a parent record with a list of child records.

Think of it like this:

`Widget` → `Notifier` → `Repository` → `Database`

The parent is a `MealEntry` and the children are `IngredientPortion`s.

## 1) Tables

In the app, the parent lives in `Meals` and the child rows live in `MealIngredients`.

```dart
import 'package:drift/drift.dart';

class Meals extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().nullable()();
  DateTimeColumn get eatenAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class MealIngredients extends Table {
  TextColumn get id => text()();
  TextColumn get mealId => text().references(Meals, #id)();
  TextColumn get ingredientId => text().references(Ingredients, #id)();
  RealColumn get grams => real()();

  @override
  Set<Column> get primaryKey => {id};
}
```

That means:
- one meal can have many items
- each item belongs to exactly one meal

## 2) Database methods

The database is the low-level API that only knows rows and tables.

```dart
import 'package:drift/drift.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Meals, MealIngredients, Ingredients])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  Stream<List<Meal>> watchMeals() => select(meals).watch();
  Future<List<Meal>> getMeals() => select(meals).get();

  Future<void> insertMeal(MealsCompanion entry) => into(meals).insert(entry);
  Future<void> deleteMeal(String id) =>
      (delete(meals)..where((t) => t.id.equals(id))).go();

  Stream<List<MealIngredient>> watchMealIngredients(String mealId) =>
      (select(mealIngredients)..where((t) => t.mealId.equals(mealId))).watch();

  Future<List<MealIngredient>> getMealIngredients(String mealId) =>
      (select(mealIngredients)..where((t) => t.mealId.equals(mealId))).get();

  Future<void> insertMealIngredient(MealIngredientsCompanion entry) =>
      into(mealIngredients).insert(entry);

  Future<void> deleteMealIngredientsByMeal(String mealId) =>
      (delete(mealIngredients)..where((t) => t.mealId.equals(mealId))).go();

  Future<Ingredient> getIngredient(String id) =>
      (select(ingredients)..where((t) => t.id.equals(id))).getSingle();
}
```

## 3) Repository

The repository knows how to save a `MealEntry` and its list of `IngredientPortion`s together.

```dart
import 'package:uuid/uuid.dart';
import 'app_database.dart';

class DriftMealRepository {
  DriftMealRepository(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  Stream<List<MealEntry>> watchMeals() async* {
    yield await getAllMeals();
    await for (final _ in _db.watchMeals()) {
      yield await getAllMeals();
    }
  }

  Future<List<MealEntry>> getAllMeals() async {
    final meals = await _db.getMeals();
    return Future.wait(meals.map(_loadMealWithItems));
  }

  Future<void> insert(MealEntry meal) async {
    await _db.insertMeal(
      MealsCompanion.insert(
        id: meal.id,
        name: meal.name ?? '',
        eatenAt: meal.eatenAt,
      ),
    );

    for (final item in meal.items) {
      await _db.insertMealIngredient(
        MealIngredientsCompanion.insert(
          id: _uuid.v4(),
          mealId: meal.id,
          ingredientId: item.ingredient.id,
          grams: item.grams,
        ),
      );
    }
  }

  Future<MealEntry> _loadMealWithItems(Meal meal) async {
    final ingredientRows = await _db.getMealIngredients(meal.id);
    final items = await Future.wait(
      ingredientRows.map((row) async {
        final ingredient = await _db.getIngredient(row.ingredientId);
        return IngredientPortion(ingredient: ingredient, grams: row.grams);
      }),
    );
    return MealEntry(
      id: meal.id,
      name: meal.name.isEmpty ? null : meal.name,
      eatenAt: meal.eatenAt,
      items: items,
    );
  }
}

The repository is where you keep the "save the parent, then save all children" rule.

## 4) Notifier

The notifier connects the repository to the UI.

```dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final mealRepositoryProvider = Provider<DriftMealRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DriftMealRepository(db);
});

final mealsProvider = NotifierProvider<MealsController, List<MealEntry>>(
  MealsController.new,
);

class MealsController extends Notifier<List<MealEntry>> {
  late final DriftMealRepository _repo;
  StreamSubscription<List<MealEntry>>? _sub;

  @override
  List<MealEntry> build() {
    _repo = ref.read(mealRepositoryProvider);
    _sub = _repo.watchMeals().listen((loaded) {
      if (ref.mounted) state = loaded;
    });
    ref.onDispose(() => _sub?.cancel());
    return const [];
  }

  Future<void> addMeal(MealEntry meal) => _repo.insert(meal);
}
```

## 5) Widget

The widget reads the list and triggers saves.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MealsPage extends ConsumerWidget {
  const MealsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meals = ref.watch(mealsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Meals')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await ref.read(mealsProvider.notifier).addMeal(
            MealEntry(
              id: 'meal-id',
              name: 'Lunch',
              eatenAt: DateTime.now(),
              items: [
                IngredientPortion(
                  ingredient: Ingredient(
                    id: 'rice-id',
                    name: 'Rice',
                    caloriesPer100g: 0,
                    proteinPer100g: 0,
                    carbsPer100g: 0,
                    fatPer100g: 0,
                  ),
                  grams: 150,
                ),
                IngredientPortion(
                  ingredient: Ingredient(
                    id: 'chicken-id',
                    name: 'Chicken',
                    caloriesPer100g: 0,
                    proteinPer100g: 0,
                    carbsPer100g: 0,
                    fatPer100g: 0,
                  ),
                  grams: 200,
                ),
              ],
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: meals.length,
        itemBuilder: (context, index) {
          final entry = meals[index];
          return ListTile(
            title: Text(entry.name ?? 'Meal'),
            subtitle: Text('${entry.items.length} items'),
          );
        },
      ),
    );
  }
}
```

## 6) How it works together

When the page opens:
1. the widget watches `mealsProvider`
2. the notifier subscribes to the repository stream
3. the repository reads the parent rows and loads each child list
4. the notifier stores the current list in memory
5. the widget rebuilds when the list changes

When you tap save:
1. the widget calls `saveMeal()`
2. the repository inserts the parent meal row
3. the repository inserts all `MealIngredients` child rows
4. the database now contains one parent plus many children
5. the notifier can reload and show the new data

## 7) Streams vs lists

This is the part that usually causes confusion.

### `List<T>`

A `List<T>` is a snapshot.

It means: "give me the data right now."

Use it when:
- you want one read
- you are loading initial data
- you do not need automatic updates

Example:

```dart
final meals = await _db.getMeals();
```

### `Stream<List<T>>`

A `Stream<List<T>>` is live.

It means: "keep sending me new values when the database changes."

Use it when:
- the UI should refresh automatically
- another action may change the same data
- you want live sync with the database

Example:

```dart
final stream = _db.watchMeals();
```

### Simple rule

- `List<T>` = one-time fetch
- `Stream<List<T>>` = live updates

In most screens, you often use both:
- `List<T>` for the first load
- `Stream<List<T>>` for automatic refreshes

## 8) Why this maps to your app

This is the same shape used by `Meals`, `Ingredients`, and `Seances`:

- `AppDatabase` = raw SQL operations
- repository = feature-specific save/load logic
- notifier = state + actions
- widget = UI

If you want to build a new feature later, start from this parent/children pattern first and then swap in your real names and fields.

## 9) Where this lives in your repo

Use these files as the real version of the example:

- `lib/src/models/food.dart` = `MealEntry`, `Ingredient`, `IngredientPortion`
- `lib/src/adapters/drift/meals.dart` = meal read/write logic
- `lib/src/database/app_database.dart` = raw Drift helpers like `insertMeal()` and `insertMealIngredient()`
- `lib/src/diet/providers/meals.dart` = Riverpod notifier that loads and exposes meals to the UI
- `lib/src/diet/screens/meals/edit.dart` = screen that creates/edits a meal and calls the notifier

The code above is intentionally smaller than the real app, but the flow is the same.
