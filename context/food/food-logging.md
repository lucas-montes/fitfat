# Food Logging (Phase 1)

Food logging in Phase 1 is UI-only with mock data and in-memory state. The Food tab lists meals eaten with time, calories, and macro totals. Meals are built from ingredients with per-100g nutrition values.

## Core concepts

- **Ingredient**: Base nutrition unit with calories, protein, carbs, and fat per 100g. Ingredients can be composite (handmade) and derived from other ingredients with gram amounts.
- **Meal**: A list of ingredient portions with an optional name and an eaten time.

## Current UI flow

1. Food tab shows a single list of meals (name optional), with time and macro totals.
2. FAB opens **Add Meal** screen.
3. Add Meal lets users:
   - Search and add ingredients with grams.
   - Create a custom ingredient (manual macros or built from ingredients).
4. Tapping a meal opens a detail sheet with ingredient breakdown and edit/delete.

## Data model snapshot

- `Ingredient` in `lib/src/models/food_models.dart`
  - `id`, `name`, `caloriesPer100g`, `proteinPer100g`, `carbsPer100g`, `fatPer100g`
  - `components` (optional list of ingredient portions for composite ingredients)
- `MealEntry` in `lib/src/models/food_models.dart`
  - `id`, `name`, `eatenAt`, `items` (ingredient portions)

## Mock providers

- `ingredientListProvider` — seeded ingredients list
- `mealLogProvider` — in-memory meals with add/update/delete

See also: [overview.md](../overview.md), [context-map.md](../context-map.md)
