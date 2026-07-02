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

- **Repository** (`meal_repository.dart`): Loads meals with their ingredient items via two-step query (meal_ingredients then batch-load ingredients). Uses transactions for insert/update/delete. Delete cascades to `meal_ingredients` before deleting the meal.
- **Helper** `newMeal()`: Creates a `MealEntry` with fresh UUID v7 and current timestamp.
- **Providers** (`meals.dart`): `mealRepositoryProvider`, `mealListProvider` (FutureProvider). Reuses `databaseProvider` from `ingredients.dart`.
- **List screen**: Groups meals by date (day-level). Each meal is an `ExpansionTile` showing ingredient breakdown with macro values. Shows daily calorie subtotal per date group. AppBar action navigates to `IngredientListScreen`. Swipe-to-delete with confirmation dialog.
- **Form screen**: Name field, date/time picker (`showDatePicker` + `showTimePicker`), ingredient selection via checkboxes with gram input fields. Validates name (required) and at least one ingredient with grams > 0. Calls `repo.insert()` or `repo.update()`.

## Wiring

The Diet tab (`lib/src/app/tabs/diet_tab.dart`) renders `MealListScreen`. Ingredient management is accessible via the AppBar action (`restaurant_menu` icon) which pushes `IngredientListScreen`.

## Data model

`MealEntry` (domain) maps to two database tables:
- `meals` — stores id, name, eaten_at, created_at
- `meal_ingredients` — stores the many-to-many relationship with gram amounts

`MealIngredient` (domain) includes denormalized ingredient data (name, macros per 100g) loaded via join at query time. The `fromIngredient()` factory builds from an `Ingredient` domain model.

See also: [overview.md](../overview.md), [architecture.md](../architecture.md), [database/schema.md](../database/schema.md), [ingredient-crud.md](ingredient-crud.md)
