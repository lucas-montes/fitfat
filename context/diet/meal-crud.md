# Meal CRUD — Diet Domain

Feature: create, read, update, and delete meals (collections of ingredients with gram amounts).

## Files

| File | Purpose |
|------|---------|
| `lib/src/diet/repositories/meal_repository.dart` | Drift DAO wrapping `meals` + `meal_ingredients` tables |
| `lib/src/diet/providers/meals.dart` | Riverpod providers (`mealRepositoryProvider`, `mealListProvider`) |
| `lib/src/diet/screens/meal_list.dart` | Grouped by date, expandable tiles showing ingredient breakdown |
| `lib/src/diet/screens/meal_form.dart` | Form with name, date/time picker, ingredient picker with gram input |

## Key behavior

- **Repository** (`meal_repository.dart`): Loads meals with their ingredient items via two-step query (meal_ingredients then batch-load ingredients). Uses transactions for insert/update/delete. Delete cascades to `meal_ingredients` before deleting the meal. `restore(MealEntry)` (T06) re-inserts a deleted meal with all items and original ids — it delegates to `insert` so the create and undo paths share one code path.
- **Helper** `newMeal()`: Creates a `MealEntry` with fresh UUID v7 and current timestamp, and stamps the generated meal id onto every item (fixes the pre-T02 bug where new-meal items kept `mealId: ''` and never loaded back).
- **Providers** (`meals.dart`): `mealRepositoryProvider`, `mealListProvider` (FutureProvider). Reuses `databaseProvider` from `ingredients.dart`.
- **List screen**: Groups meals by date (day-level). Each meal is an `ExpansionTile` showing ingredient breakdown with macro values. Shows daily calorie subtotal per date group. AppBar action navigates to `IngredientListScreen`. Swipe-to-delete → hard `delete` + `mealDeleted(name)` SnackBar with Undo (`commonUndo`) → `restore(MealEntry)` + invalidate; no confirm dialog (T07); `Haptics.mediumImpact` on delete (T04). Empty state = `EmptyState` (`restaurant_outlined`, `emptyMeals*` ARB keys) with a CTA that opens the meal form (T03).
- **Meal tile**: `_MealTile` is stateful — tapping the tile expands/collapses the ingredient breakdown; the trailing is an `AnimatedRotation` chevron (`expand_more`, 180° when expanded) driven by `onExpansionChanged`; **long-pressing the tile opens the meal edit form** (the `ExpansionTile` is wrapped in a `GestureDetector(onLongPress: ...)` — `ExpansionTile` has no `onLongPress` in Flutter 3.38.3; there is no trailing edit icon, active-workout-flow T02).
- **Form screen**: Name field, date/time picker (`showDatePicker` + `showTimePicker`), ingredient selection via checkboxes with gram input fields and a name-filter search box (case-insensitive `contains`, shown when the list is non-empty; filtering preserves selection). Validates name (required) and at least one ingredient with grams > 0. Calls `repo.insert()` or `repo.update()`; on success shows a `commonSaved` SnackBar (root `ScaffoldMessenger`, persists across the pop) then pops `true` (T04).

## Wiring

The Diet tab (`lib/src/app/tabs/diet_tab.dart`) renders `MealListScreen`. Ingredient management is accessible via the AppBar action (`restaurant_menu` icon) which pushes `IngredientListScreen`.

## Data model

`MealEntry` (domain) maps to two database tables:
- `meals` — stores id, name, eaten_at, created_at
- `meal_ingredients` — stores the many-to-many relationship with gram amounts

`MealIngredient` (domain) includes denormalized ingredient data (name, macros per 100g) loaded via join at query time. The `fromIngredient()` factory builds from an `Ingredient` domain model.

See also: [overview.md](../overview.md), [architecture.md](../architecture.md), [database/schema.md](../database/schema.md), [ingredient-crud.md](ingredient-crud.md)
