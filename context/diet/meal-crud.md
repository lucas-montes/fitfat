# Meal CRUD — Diet Domain

Feature: create, read, update, and delete meals (collections of **foods** with amounts eaten).

## Files

| File | Purpose |
|------|---------|
| `lib/src/diet/repositories/meal_repository.dart` | Drift DAO wrapping `meals` + `meal_foods`; owns the portion snapshot |
| `lib/src/diet/providers/meals.dart` | Riverpod providers (`mealRepositoryProvider`, `mealListProvider`) |
| `lib/src/diet/screens/meal_list.dart` | Grouped by date, expandable tiles showing the logged foods |
| `lib/src/diet/screens/meal_form.dart` | Form with name, date/time picker, food picker with amount input and live totals |

## Key behavior

- **A meal logs foods, not ingredients.** The chain is `meal → food → ingredient`, so a
  recipe can be corrected later without rewriting what was already eaten.
- **The portion is snapshotted.** `meal_foods` stores calories/protein/carbs/fat (and
  nullable sodium/fiber/sugar) resolved at log time and read verbatim. Reading a meal is
  therefore join-free. The food **name** is not snapshotted — it is joined live, so a rename
  shows up in old meals.
- **The snapshot is a cache, not a record.** It is refreshed when the food behind it
  changes, so editing an ingredient or a recipe *does* move the numbers on meals already
  logged — see `meal_resnapshot.dart`. Keeping the columns anyway is what lets reads stay
  one flat `SUM` instead of walking the ingredient graph on every dashboard load.
- **Fixed-query history.** `getAll()` loads the entire meal history in **three queries**
  (meals, then the `meal_foods` for all of them, then the food names) regardless of meal
  count. This replaced a per-meal `meal_ingredients` + `ingredients` pair that was N+1.
  A row whose food is missing is skipped rather than crashing the read.
- **`insert` / `update` re-snapshot.** Callers hand in each food's **live** per-100g
  profile (`MealFoodDraft`), which the repository scales to the amount and freezes.
  Throws `ArgumentError` when a draft's nutrition is null — a food that cannot be resolved
  would record a zero-calorie meal, so the log is refused instead.
- **`updateAmounts` rescales instead.** Adjusting only the grams rescales the snapshot by
  `newAmount / oldAmount`, which is exact because the derivation is linear in the amount.
  This is deliberately *not* a re-snapshot: a portion tweak must not silently pick up a food
  that changed since it was logged. Use `update` when the foods themselves were edited.
- **Providers** (`meals.dart`): `mealRepositoryProvider`, `mealListProvider` (FutureProvider).
- **List screen** (the Food tab, `meal_list.dart`, Phase FG): every meal, one card per
  day (`MealDayCard`): a tinted header with the date, kcal, grams and the five macros
  (protein · carbs · fat · fiber · sodium) in labeled columns, then one `MealRow` per meal in
  time order: time · kcal · grams · N foods · ⌄ · ↻, and the `MacroBar` underneath. Meal
  names are never shown (users never fill them). Tapping a row opens it: each food with name,
  grams, kcal and a thinner bar, plus **Edit meal**. **↻ logs the same foods and grams again
  now**, re-resolved from the foods' live profiles like any new log, with Undo (refused when a
  food no longer resolves). Filter with `DateFilterChips` (month chips + Range) and search by
  food name (`groupMealDays`). App-bar actions open Recipes and Ingredients; + opens a new meal.
- **Form screen** (`meal_form.dart`): no name field (the column is written as an empty string,
  or the existing name when editing). The title is the date · time; tapping it opens the date
  and time pickers. Pinned on top: kcal, grams, the day's total against the calorie target, and
  the `MacroBar`. Foods are rows with a grams field (✕ or swipe to remove). A search field at
  the end suggests foods as you type (recipes and single ingredients; foods logged before come
  first, each with "last N g"); an empty meal shows the most recently logged foods. A food is
  added at the grams used last time (else 100 g). The barcode button looks the code up among
  local ingredients. Save is refused when a food does not resolve. Delete is the danger row
  (`confirmDelete`, Undo via `restore`).

## Wiring

The Diet tab (`lib/src/app/tabs/diet_tab.dart`) renders `MealListScreen`. Ingredient and
recipe management are reachable from its AppBar actions.

## Data model

`MealEntry` (domain) maps to two database tables:
- `meals` — id, name, eaten_at, created_at
- `meal_foods` — id, meal_id, food_id, amount, plus the frozen portion macros

`MealFood` carries the snapshot numbers and a **transient** `nutrition` field holding the
live per-100g profile. It is null on anything read back from the database — re-deriving one
would defeat the snapshot.

See also: [food-crud.md](food-crud.md), [ingredient-crud.md](ingredient-crud.md),
[database/schema.md](../database/schema.md)