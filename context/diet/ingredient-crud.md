# Ingredient CRUD — Diet Domain

Feature: create, read, update, and delete food ingredients (items with macros per 100g).

## Files

| File | Purpose |
|------|---------|
| `lib/src/diet/repositories/ingredient_repository.dart` | Drift DAO wrapping the `ingredients` table |
| `lib/src/diet/providers/ingredients.dart` | Riverpod providers (`databaseProvider`, `ingredientRepositoryProvider`, `ingredientListProvider`) |
| `lib/src/diet/screens/ingredient_list.dart` | ListView with FAB, edit-on-tap, swipe-to-delete |
| `lib/src/diet/screens/ingredient_form.dart` | Form with name + 4 macro fields (calories, protein, carbs, fat) |

## Key behavior

- **Repository** (`ingredient_repository.dart`): Uses `IngredientsCompanion.insert()` for inserts and `IngredientsCompanion()` for updates. Converts domain `Ingredient` ↔ Drift `Ingredient` via `_toDomain()`.
- **Helper** `newIngredient()`: Creates a domain `Ingredient` with a fresh UUID v7 and `DateTime.now()`. Lives in the repository file.
- **Providers** (`ingredients.dart`): `databaseProvider` (singleton `AppDatabase`), `ingredientRepositoryProvider` (wires database to repo), `ingredientListProvider` (async list).
- **List screen**: Shows macro subtitle per ingredient. `Dismissible` with confirmation dialog for delete. FAB navigates to form.
- **Form screen**: Validates name (required), calories (positive), macros (non-negative). Calls `repo.insert()` or `repo.update()` depending on edit mode. Invalidates `ingredientListProvider` on save.

## Wiring

The Diet tab (`lib/src/app/tabs/diet_tab.dart`) renders `IngredientListScreen` directly. The app is wrapped in `ProviderScope` in `lib/src/app/app.dart`.

See also: [overview.md](../overview.md), [architecture.md](../architecture.md), [database/schema.md](../database/schema.md)
