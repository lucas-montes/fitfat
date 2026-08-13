# Ingredient CRUD — Diet Domain

Feature: create, read, update, and **soft-archive** food ingredients (items with macros per 100g plus optional extra nutriments).

## Files

| File | Purpose |
|------|---------|
| `lib/src/diet/repositories/ingredient_repository.dart` | Drift DAO wrapping the `ingredients` table |
| `lib/src/diet/providers/ingredients.dart` | Riverpod providers (`databaseProvider`, `ingredientRepositoryProvider`, `ingredientListProvider`) |
| `lib/src/diet/screens/ingredient_list.dart` | ListView with FAB, edit-on-tap, swipe-to-archive + Undo |
| `lib/src/diet/screens/ingredient_form.dart` | Form with name + 4 macro fields + 3 optional nutriment fields |

## Key behavior

- **Repository** (`ingredient_repository.dart`): Uses `IngredientsCompanion.insert()` for inserts and `IngredientsCompanion()` for updates. Converts domain `Ingredient` ↔ Drift `Ingredient` via `_toDomain()`. Maps the optional `sodium_per100g` / `fiber_per100g` / `sugar_per100g` columns (nulls round-trip unchanged).
- **Soft-archive (T05, schema v4)**: `getAll()` filters `is_archived == false`; `archive(id)` / `restore(id)` flip the `is_archived` flag. **No hard delete exists** — the old `delete()` was removed so no code path can hit an FK violation from deleting a referenced ingredient.
- **Helper** `newIngredient()`: Creates a domain `Ingredient` with a fresh UUID v7 and `DateTime.now()`. Optional nutriment params. `isArchived` defaults to `false`. Lives in the repository file.
- **Providers** (`ingredients.dart`): `databaseProvider` (singleton `AppDatabase`), `ingredientRepositoryProvider` (wires database to repo), `ingredientListProvider` (async list).
- **List screen**: Shows macro subtitle per ingredient plus an optional second line with the set extra nutriments (sodium mg / fiber g / sugar g, joined with " · ", only present values). `Dismissible` (end-to-start) → `archive` + SnackBar `ingredientArchived` ("Ingredient \"{name}\" archived") with Undo → `restore` + provider invalidate; `Haptics.mediumImpact` on dismiss (T04). **No confirm dialog** (archive is non-destructive). FAB navigates to form. Empty state = `EmptyState` (`soup_kitchen_outlined`, `emptyIngredients*` ARB keys) with a CTA that opens the ingredient form (T03).
- **Form screen**: Validates name (required), calories (positive), macros (non-negative). Optional nutriment fields: blank → stored `null`, non-blank must be non-negative. Calls `repo.insert()` or `repo.update()` depending on edit mode. `update` writes only named fields, so `isArchived` is preserved on edits. Invalidates `ingredientListProvider` on save.

## Archive semantics

- Archiving hides the ingredient from the list **and** the meal-form picker — the picker reads `ingredientListProvider` (no separate query), so the repo-level `getAll` filter covers every consumer.
- Past meals keep rendering archived ingredient names/macros: `meal_repository._getItemsForMeal` joins **all** ingredient rows (no `is_archived` filter) — intentionally untouched.
- No restore surface beyond the immediate Undo SnackBar (user decision). Undo is ephemeral — a restart during the window loses it (accepted).

## Nutriments (ingredient-only)

Sodium (mg), fiber (g), sugar (g) are **optional per-100g values on the ingredient only** — they are not propagated to `meal_ingredients` or meal breakdowns. `Ingredient.copyWith` uses a sentinel pattern so an explicit `null` clears a value on edit.

## Wiring

The Diet tab (`lib/src/app/tabs/diet_tab.dart`) renders `IngredientListScreen` directly. The app is wrapped in `ProviderScope` in `lib/src/app/app.dart`.

See also: [overview.md](../overview.md), [architecture.md](../architecture.md), [database/schema.md](../database/schema.md)
