# Food CRUD — Diet Domain

Feature: create, read, update and archive **foods** — named recipes built from ingredients
with amounts. This is the middle layer of `meal → food → ingredient` and owns composition
only. See [meal-crud.md](meal-crud.md) and [ingredient-crud.md](ingredient-crud.md).

## Files

| File | Purpose |
|------|---------|
| `lib/src/models/food.dart` | `Food`, `FoodIngredient`, `derivedFoodId` / `isDerivedFoodId`, `newFood()` |
| `lib/src/diet/services/food_nutrition.dart` | Pure `resolveFoodPer100g` / `scaleToAmount` — the whole derivation, free of Drift |
| `lib/src/diet/repositories/food_repository.dart` | Drift DAO over `foods` + `food_ingredients` |
| `lib/src/diet/providers/foods.dart` | `foodRepositoryProvider`, `foodListProvider`, `foodCombinationProvider`, `invalidateFoods` |
| `lib/src/diet/screens/food_list.dart` | Recipes list: live per-100g, part count, swipe/restore |
| `lib/src/diet/screens/food_form.dart` | Composition editor with a live nutrition preview |
| `lib/src/sync/food_sync_client.dart` | Push/pull of foods with composition nested per food |

## The central design decision: foods carry no nutrition

There is no per-100g macro column on `foods`. Nutrition is **always resolved** through
`foods → food_ingredients → ingredients` on read.

A stored copy would go stale the moment an ingredient is edited, and there would be two
sources of truth to reconcile. Because nothing is cached, an ingredient edit is immediately
visible in every food built from it — with no recompute step, no invalidation to get wrong,
and no sync payload that has to agree about the derived value. The sync server and the
desktop app inherit this for free: neither needs any derivation logic, because neither ever
sees a number.

## Derivation

`food_per100g = Σ(ingredient.per100g × amount) / Σ(amount)`

Each term accumulates `per100g * amount`, an **absolute** amount, so dividing the totals by
the total weight lands directly on a per-100g figure — there is no extra `/100` or `*100`
factor. The denominator is the sum of component amounts; there is no separate yield or
cook-weight input. `resolveFoodPer100g` is pure (no Drift, no models) and unit-tested on its
own, so the form preview, the foods list, the meal snapshot and the server cannot drift.

Sodium/fiber/sugar stay null only when *no* component ever provided a value; otherwise
components that omit it count as zero so the total stays meaningful. An empty composition
yields zeroes, not a division by zero.

## Resolution is all-or-nothing

A food missing **one** ingredient returns no nutrition at all, rather than summing whatever
happens to be present. Partial sums are wrong twice over: they under-report calories, and
they drop the missing part from the weight denominator, which silently inflates the
remaining parts. The meal form refuses to log such a food rather than record the error
permanently in a snapshot.

`getComponents` therefore **left-joins** ingredient rows, surfacing a part whose ingredient is
missing (with an empty name) instead of dropping it. An incomplete recipe must look
incomplete, not smaller.

## Composition rules

- **No sort order.** Components carry no meaningful order and are presented alphabetically
  by ingredient name; unresolved parts sort last. There is nothing to renumber.
- **At least one ingredient.** The UI guides toward two or more, since that is what makes a
  recipe worth having over logging the parts directly.
- **Amounts are absolute amounts in the batch**, not percentages, and must be greater than
  zero — they are the denominator.
- **The same ingredient cannot appear twice in one food.** The composite primary key
  `(food_id, ingredient_id)` enforces this, so it is impossible rather than merely rejected.
- Composition is written **wholesale** on save. Part deletion travels by omission, which is
  why the whole list is replaced instead of diffed.

## Derived foods

Each ingredient also owns a 1:1 derived food (`id = "i:" + ingredientId`, one component at
`amount = 100`) so it stays individually loggable. `IngredientRepository` is the only
writer; `FoodRepository` refuses derived ids. `foodCombinationProvider` filters them out of
the recipes list, and `FoodSyncClient.shareable` filters them out of what gets pushed —
they mirror an ingredient and are not something the user authored.

## Repository API

| Method | Purpose |
|--------|---------|
| `getAllWithNutrition({includeArchived})` | Every food with its live profile, name-ordered |
| `getById(id)` | One food with its composition attached |
| `getComponents(foodId)` | Composition, alphabetical, missing parts included |
| `resolveNutrition(foodId)` | The live per-100g profile, or null if unresolvable |
| `insert` / `insertAndReturn` | Create with composition; `insertAndReturn` gives back the stored row |
| `update(food, components)` | Rename + replace composition, one transaction |
| `archive` / `restore` | Soft-delete, so logged meals keep rendering from their snapshot |
| `applyFromServer(food, components)` | Sync path: upsert the row, replace the composition |

## Keeping logged portions honest

`MealResnapshot` (repositories/meal_resnapshot.dart) re-derives the `meal_foods` rows
that a change invalidates. It is triggered from three places, and only three:

- `IngredientRepository.update` — the ingredient changed, so every food listing it
  does, plus its own derived food
- `FoodRepository.update`
- `FoodRepository.applyFromServer`

It deliberately is **not** in `insert` (a brand-new id cannot be referenced by a
logged meal) or in `archive`/`restore` (resolution ignores the archived flag, so
neither changes what a food resolves to).

It lives outside `MealRepository` so `FoodRepository` and `IngredientRepository` can
both reach it without making the import graph cyclic.

**Degradation:** a food that stops resolving — a part whose ingredient row is gone, an
emptied composition — leaves its rows at their last known numbers instead of being zeroed.
Those figures still describe a portion that was genuinely eaten, whereas zero would
invent a claim, and an unresolvable food has no new value to write anyway. The rows pick
up correct numbers as soon as it resolves again.

## Sync

`FoodSyncClient` treats foods as their own resource (`SyncResource.foods`, `/foods`) with
composition **nested inside each food**, so one pull yields a usable recipe instead of a
second round trip per food. A pull collects the ingredient ids it does not have and asks for
them before applying, because `food_ingredients` has a real FK. A tombstone archives rather
than deletes, for the same reason meals do.