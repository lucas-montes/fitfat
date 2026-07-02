# Exercise Definition CRUD — Exercise Domain

Feature: create, read, update, and delete exercise definitions (name + type: weightlifting/cardio).

## Files

| File | Purpose |
|------|---------|
| `lib/src/exercise/repositories/exercise_repository.dart` | Drift DAO wrapping the `exercises` table |
| `lib/src/exercise/providers/exercises.dart` | Riverpod providers (`exerciseRepositoryProvider`, `exerciseListProvider`) |
| `lib/src/exercise/screens/exercise_list.dart` | ListView with type icon, swipe-to-delete |
| `lib/src/exercise/screens/exercise_form.dart` | Form with name + type dropdown |

## Key behavior

- **Repository** (`exercise_repository.dart`): Uses `ExercisesCompanion.insert()` for inserts and `ExercisesCompanion()` for updates. Orders results alphabetically by name.
- **Helper** `newExercise()`: Creates a domain `Exercise` with a fresh UUID v7 and `DateTime.now()`.
- **Providers** (`exercises.dart`): `exerciseRepositoryProvider`, `exerciseListProvider` (FutureProvider). Uses shared `databaseProvider` from `lib/src/database/database_provider.dart`.
- **List screen**: Shows exercise name with type icon (weightlifting → `fitness_center`, cardio → `directions_run`). `Dismissible` with confirmation dialog for delete. FAB navigates to form.
- **Form screen**: Text field for name, `DropdownButtonFormField` with `'weightlifting'` / `'cardio'` options. Uses `Exercise.copyWith()` for edit mode.

## Wiring

The Exercise tab (`lib/src/app/tabs/exercise_tab.dart`) renders `ExerciseListScreen` directly.

See also: [overview.md](../overview.md), [architecture.md](../architecture.md), [database/schema.md](../database/schema.md)
