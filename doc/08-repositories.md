# Repository Pattern (Ports & Adapters)

## What is a port?

A **port** is an abstract interface (Dart `abstract class`) that defines how the app communicates with a data source. The **adapter** is the concrete implementation.

```
Provider → [Port Interface] → Adapter (Drift) → SQLite
                           → Adapter (InMemory) → Tests
```

## Repository interfaces

All interfaces are in `lib/src/repositories/interfaces/`:

| Interface | Methods | Used by |
|---|---|---|
| `ExerciseRepository` | `getAll()` | `exerciseListProvider` |
| `IngredientRepository` | `getAll()`, `insert()`, `update()`, `delete()` | `IngredientListNotifier` |
| `MealRepository` | `getByDate()`, `insert()`, `delete()` | Food providers (partially implemented) |
| `FullSeanceRepository` | `insertSeance()`, `getAll()`, `delete()` | (future use) |
| `GoalRepository` | `upsertBodyWeight()`, `addStrength()`, `removeStrength()`, `loadAll()` | `GoalsNotifier` |
| `ProfileRepository` | `get()`, `upsert()` | `UserProfileNotifier` |
| `SeanceRepository` | `listTemplates()`, `createTemplate()`, `updateTemplate()`, `deleteTemplate()`, `cloneTemplate()` | `templateListProvider` |

## Implementations

### Drift implementations (`lib/src/repositories/drift/`)

Each interface has a Drift implementation that delegates to `AppDatabase`:

```dart
class DriftExerciseRepository implements ExerciseRepository {
  DriftExerciseRepository(this._db);
  final AppDatabase _db;

  @override
  Future<List<ExerciseDefinition>> getAll() async {
    final rows = await _db.getAllExercises();
    return rows.map((e) => ExerciseDefinition(
      id: e.id, name: e.name, category: e.category,
    )).toList();
  }
}
```

### In-memory implementation

The `InMemorySeanceRepository` is used in tests to avoid needing a database.

## Wiring in providers

```dart
// In seance_providers.dart:
final seanceRepositoryProvider = Provider<SeanceRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DriftSeanceRepository(db);
});
```

Tests can override this:

```dart
ProviderContainer(
  overrides: [
    seanceRepositoryProvider.overrideWithValue(InMemorySeanceRepository()),
  ],
);
```

## When to add a new repository

1. Define the `abstract class` interface in `repositories/interfaces/`
2. Implement it in `repositories/drift/`
3. Create a `Provider<YourRepository>` in the relevant provider file
4. Override in tests when needed
