# In-app refactor plan — structure and abstractions (no external packages)

Goal: restructure the app so diet and exercise domain logic is cleanly separated and stored behind repository interfaces, without creating standalone packages. Keep widgets and platform code in the app. Minimize on-disk DB schema changes by mapping existing Drift tables in adapters.

Why this approach
- Keeps the codebase monorepo/simple while improving separation-of-concerns.
- Makes the domain logic easier to test (in-memory adapters) and to reuse inside other apps by copying a well-defined `lib/src/domain` folder if needed.
- Avoids immediate complexity of publishing packages while delivering most benefits of modularization.

High-level folder layout (recommendation)

lib/
  src/
    domain/                # Pure domain code (models, DTOs, pure helpers)
      models/
        food_models.dart
        exercise_models.dart
        seance_models.dart
        dashboard_models.dart
      services/             # Pure business logic not tied to storage (macros, templating)
        nutrition_service.dart
        seance_service.dart
    repositories/           # Interfaces for storage & repository patterns
      interfaces/
        meal_repository.dart
        ingredient_repository.dart
        seance_repository.dart
        goal_repository.dart
        user_profile_repository.dart
    adapters/               # Concrete adapters mapping to AppDatabase (Drift)
      drift/
        drift_meal_repository.dart
        drift_ingredient_repository.dart
        drift_seance_repository.dart
    providers/              # Riverpod provider wiring (construction of adapters, services)
      repositories.dart
      services.dart
    widgets/                # app widgets (leave as-is)

Design / API sketches

1) Generic repository (optional base)

```dart
abstract class Repository<T, ID> {
  Future<List<T>> getAll();
  Stream<List<T>> watchAll();
  Future<T?> getById(ID id);
  Future<T> save(T entity);
  Future<void> delete(ID id);
}
```

2) Domain-specific interface example (`lib/src/repositories/interfaces/meal_repository.dart`)

```dart
import '../../domain/models/food_models.dart';

abstract class MealRepository implements Repository<Meal, String> {
  Future<List<Meal>> getMealsForDay(DateTime day);
  Stream<List<Meal>> watchMealsForDay(DateTime day);
}
```

3) In-memory adapter (for tests) — keep under `lib/src/adapters/in_memory/`

```dart
class InMemoryMealRepository implements MealRepository {
  final Map<String, Meal> _store = {};
  final _controller = StreamController<List<Meal>>.broadcast();

  @override
  Future<Meal> save(Meal entity) async {
    _store[entity.id] = entity;
    _controller.add(_store.values.toList());
    return entity;
  }

  @override
  Future<List<Meal>> getAll() async => _store.values.toList();

  @override
  Stream<List<Meal>> watchAll() => _controller.stream;

  // ... day-specific helpers
}
```

4) Drift adapter sketch (`lib/src/adapters/drift/drift_meal_repository.dart`)

```dart
import '../../repositories/interfaces/meal_repository.dart';
import '../../domain/models/food_models.dart';
import '../../database/app_database.dart';

class DriftMealRepository implements MealRepository {
  final AppDatabase db;

  DriftMealRepository(this.db);

  @override
  Stream<List<Meal>> watchMealsForDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(Duration(days: 1));
    // Use existing Drift table/query and map rows to domain Meal
    return db.select(db.meals)
      .watch()
      .map((rows) => rows
        .where((r) => r.eatenAt.isAfter(start) && r.eatenAt.isBefore(end))
        .map(_mapRowToMeal)
        .toList());
  }

  @override
  Future<Meal> save(Meal entity) async {
    final companion = _mealToCompanion(entity);
    await db.into(db.meals).insertOnConflictUpdate(companion);
    return entity;
  }

  // map helpers omitted
}
```

Provider wiring example (`lib/src/providers/repositories.dart`)

```dart
final appDatabaseProvider = Provider<AppDatabase>((ref) => throw UnimplementedError());

final mealRepositoryProvider = Provider<MealRepository>((ref) {
  final db = ref.read(appDatabaseProvider);
  return DriftMealRepository(db);
});

final mealsStreamProvider = StreamProvider.family<List<Meal>, DateTime>((ref, day) {
  final repo = ref.read(mealRepositoryProvider);
  return repo.watchMealsForDay(day);
});
```

Incremental migration strategy (low-risk)

1. Create `domain/`, `repositories/interfaces/`, and `adapters/` folders and move the pure model files into `domain/models/`. Do not change their shape initially.
2. Add repository interfaces (or reuse the existing ones under `lib/src/repositories/interfaces/`).
3. Implement `InMemory*` adapters for quick unit tests and to validate API shapes.
4. Implement `Drift*Repository` adapters mapping existing Drift rows to domain models — put mapping logic only inside adapters.
5. Replace direct `AppDatabase` use in a single feature (MealsTab recommended). Wire `mealRepositoryProvider` and switch the screen to use `mealsStreamProvider`.
6. Verify behavior on device/emulator and run tests.
7. Continue replacing features one-by-one.

Notes about migrations and your concern
- You do not need to change the on-disk schema to do this refactor. Implementing adapters that map the current Drift schema to the domain models means zero migrations.
- Only if you choose to rename columns, remove tables, or change data types will you need a Drift migration strategy. We can avoid that for now.

Testing recommendations
- Write unit tests for `nutrition_service.dart` and `seance_service.dart` using `InMemory*` adapters.
- For adapter tests, add small integration tests that use a temporary Drift database file (or an in-memory Drift database) to confirm mappings are correct.

Next concrete options (pick one)
- A: I draft the full API sketches for the most-used repositories and the domain model barrel files (`context/plans/in-app-refactor-api.md`).
- B: I scaffold the `lib/src/domain`, `lib/src/repositories/interfaces`, and `lib/src/adapters` file list and suggested file moves (plan only). No code changes yet.
- C: I generate a concrete `DriftMealRepository` mapping by reading your Drift table definitions (I will need to inspect `lib/src/database/app_database.dart` and the generated tables). This is the first adapter to implement and test.

Pick which you want me to do next. If you want (C), I'll read `lib/src/database/app_database.dart` and the related table definitions to create a precise adapter implementation.
