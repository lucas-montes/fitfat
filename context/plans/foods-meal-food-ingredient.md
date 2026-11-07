# Plan: Foods — normalizing diet to `meal → food → ingredient`

## Change Summary

Replace the composite-ingredient model with a three-layer chain. The difference
between the layers is the **linkage**, and the layers divide ownership strictly:

| Layer | Owns | Explicitly does **not** own |
|---|---|---|
| **Meal** | `name`, `eaten_at`; N × (`food`, `amount`) | macros, metadata |
| **Food** | `name`, `created_at`, `archived_at`; N × (`ingredient`, `amount`) | **macros**, brand/barcode/pictures/prices |
| **Ingredient** | `name`, **macros per 100g**, sodium/fiber/sugar, `brand`, `barcode`, `is_archived`, pictures, prices | any composition |

Nutrition resolves by walking down — there is nowhere else for it to live:

```
log time:  food_per100g = Σ(ingredient.per100g × fi.amount) / Σ(fi.amount)
           portion      = food_per100g × mf.amount / 100  → written into meal_foods
browse:    food_per100g resolved live for the foods list / picker
```

Macros are **defined** only on `ingredients`. `meal_foods` records what the chain
resolved to at the moment of logging — an event snapshot, not a second copy of
master data. So editing an ingredient no longer rewrites past meals (the
pre-existing behaviour, which `doc/diet.md` documented as accepted, is
**inverted**).

## Schema v34

```
ingredients                     foods                     food_ingredients
  id PK, name                     id PK                     PK(food_id, ingredient_id)
  calories_per100g  ┐             name NOT NULL             food_id → foods  CASCADE
  protein_per100g   │ THE ONLY    created_at                ingredient_id → ingredients
  carbs_per100g     │ MACROS      archived_at?              amount REAL NOT NULL
  fat_per100g       │ ANYWHERE    ──────────
  sodium/fiber/sugar┘
  is_archived, brand, barcode
  ingredient_pictures, ingredient_prices

meals { id, name, eaten_at, created_at }
meal_foods { id, meal_id, food_id, amount,
             calories, protein, carbs, fat, sodium?, fiber?, sugar? }

DROPPED: ingredient_components, meal_ingredients, Ingredient.isComposite,
         MealIngredient, composite_macros.dart
```

Deliberate choices:

- **`food_ingredients` PK is `(food_id, ingredient_id)`** — an ingredient appears
  at most once per food, so duplicates are structurally impossible. Exactly the
  three columns specified: **no `sort_order`, no `created_at`** (components are
  displayed alphabetically by ingredient name, which falls out of the join we
  already do for names).
- **`ingredient_id` has no CASCADE.** A part is never implicitly detached; only
  an explicit edit removes it.
- **`archived_at` is a nullable timestamp**, not a bool — it records *when*, NULL
  means active, and it matches the server's `deleted_at` convention.
- **`meal_foods` keeps a surrogate `id`** because the same food can appear twice
  in one meal.
- **Auto-created 1:1 food per ingredient**, `id = 'i:' || ingredientId`, with one
  component row at `amount = 100`. `isDerived` is a prefix test, so it needs no
  query.

### The 1-ingredient case needs no special case

With one term, `Σ(p·a)/Σa` is just `p` for *any* amount. So a derived food is
exactly its ingredient at any logged amount — which is why `amount = 100` is the
convention and why a user-created food never needs to be single-ingredient.

## The 1:1 invariant and where it is enforced

> A single food–ingredient pair is always in sync; the user does not know the
> difference.

Structural, not a convention: **`IngredientRepository` is the only writer of
derived foods.** The food path refuses any id starting with `'i:'` (derived
foods are read-only), and every ingredient mutation — `insert`, `update`,
`archive`, `restore` — syncs the pair's `name` + `archived_at` through one
private helper inside the same transaction. One code path can write them, so
there is nothing to forget.

## Read paths

| Path | Before | After |
|---|---|---|
| Meal list | 2 queries **per meal** (N+1) | 3 fixed queries for the whole history |
| Dashboard calories | full `getAll()`, and it runs **twice** (calories + macros) | 1 `SUM(calories)` |
| Dashboard macros | same duplicate walk | 1 `SUM(protein)` |
| Foods list (browse) | 2 queries | 1 join, still live, small bounded list |

The expensive path (history, unbounded) becomes join-free; the small path stays
live so recipes never show stale numbers.

Also fixed: `_getItemsForMeal:44` uses a non-null assertion on a joined id, so a
dangling reference crashes. The new loaders skip unknown ids.

## Constraints & Non-Goals

- **Non-goal: nested foods.** `food_ingredients.ingredient_id` references
  `ingredients`, so recipes are structurally flat — the old cycle guard is not
  needed.
- **Non-goal: units/portions.** Grams throughout (`amount`).
- **Non-goal: macro snapshots on foods.** They stay macro-free; only the event
  row is snapshotted.
- **Non-goal: composition ordering.** No drag-reorder, by decision.
- **A food must have ≥1 ingredient.** Nothing more is enforced; the UI guides
  toward 2+.
- **Migration is destructive** — dropping `meal_ingredients` and
  `ingredient_components` loses v33 meals on any device that has them. Accepted
  ("nothing to migrate — recreate"); the desktop `maia.db` is empty (verified: 0
  rows in every diet table). Worth eyeballing before running on a phone with
  data.
- **Nothing to migrate**, so no data-copy migration steps.

## Task Stack

- [x] T01: `Schema v34 — foods, food_ingredients, meal_foods`
  - Task ID: T01
  - Goal: Land the three-layer storage shape.
  - Boundaries (in/out of scope):
    - In: `lib/src/database/tables.dart` — `Foods` (id, name, created_at,
      nullable archived_at), `FoodIngredients` (composite PK, amount),
      `MealFoods` (id, meal_id FK, food_id FK, amount, 4 required macros,
      3 nullable nutriments); delete `IngredientComponents` and
      `MealIngredients`; `app_database.dart` — register, `schemaVersion` 33 → 34,
      `from < 34` migration (create new tables, drop the two obsolete ones),
      `beforeOpen` indexes on both `food_ingredients` FKs and `meal_foods.food_id`;
      build_runner.
    - Out: models, repositories, UI, sync.
  - Done when: tables exist post-migration and the old ones are gone; codegen
    regenerated; `flutter analyze lib` clean.
  - Verification notes: `flutter pub run build_runner build`; `flutter analyze lib`.

- [x] T02: `Domain models + nutrition resolution`
  - Task ID: T02
  - Goal: The three-layer models plus the pure per-100g resolution.
  - Boundaries (in/out of scope):
    - In: `lib/src/models/food.dart` (`Food`, `FoodIngredient`),
      `lib/src/models/meal_food.dart` (`MealFood` replacing `MealIngredient`),
      delete `models/ingredient_component.dart`;
      `Ingredient.isComposite` removed from `models/ingredient.dart`;
      `lib/src/diet/services/food_nutrition.dart` replacing
      `composite_macros.dart` — `resolveFoodPer100g(List<ComponentNutrition>)`
      returning a `FoodNutrition` record, same math, plus
      `scaleToAmount(nutrition, amount)` for the portion snapshot; the existing
      `computeCompositePer100g` tests repurposed.
    - Out: repositories.
  - Done when: math tests pass; models compile; `flutter analyze lib` clean.
  - Verification notes: `flutter test test/food_nutrition_test.dart`.

- [x] T03: `FoodRepository — composition CRUD + live nutrition`
  - Task ID: T03
  - Goal: Foods as a first-class entity.
  - Boundaries (in/out of scope):
    - In: `lib/src/diet/repositories/food_repository.dart` —
      `getAllWithNutrition()` (live resolve, one join), `getById`,
      `getComponents(foodId)` (alphabetical by ingredient name, joined for
      names), `insert(food, components)`, `update(food, components)` (replace
      semantics), `archive`/`restore`, `newFood()` /
      `newFoodIngredients()` helpers, and the `isDerived` write-guard that
      refuses ids beginning `i:`.
    - Out: sync, UI.
  - Done when: composition round-trips; a 1-ingredient food resolves to exactly
      its ingredient's per-100g; derived ids cannot be written;
      `flutter analyze lib` clean.
  - Verification notes: `flutter test test/food_repository_test.dart`.

- [x] T04: `IngredientRepository — remove composite API, add derived-food sync`
  - Task ID: T04
  - Goal: Make `IngredientRepository` the single writer of derived foods.
  - Boundaries (in/out of scope):
    - In: delete `saveComponents`, `clearComponents`, `getComponents`,
      `replaceComponentsFromServer`, `_compositeIds`, `_isComposite`,
      `_replaceComponentRows` and the `isComposite` hydration in
      `getAll`/`getById`; add `_syncDerivedFood(ingredient)` called from
      `insert`, `update`, `archive` and `restore` inside the same transaction so
      the pair's `name` + `archived_at` cannot drift; `upsert` also syncs.
    - Out: UI, sync client.
  - Done when: inserting/renaming/archiving/restoring an ingredient keeps its
      derived food in sync; no composite API remains; `flutter analyze lib` clean.
  - Verification notes: `flutter test test/ingredient_repository_test.dart`.

- [x] T05: `MealRepository — fixed-query load + portion snapshots`
  - Task ID: T05
  - Goal: Join-free history and stable numbers.
  - Boundaries (in/out of scope):
    - In: `lib/src/diet/repositories/meal_repository.dart` — replace the N+1 with
      a fixed 3-query load (meals, meal_foods, foods); on `insert`/`update`
      resolve each food's per-100g and write the portion snapshot into
      `meal_foods`; on an amount-only change rescale the stored macros by
      `newAmount / oldAmount`; refuse to log a food whose components cannot be
      resolved; drop the non-null assertion at line 44 and skip unknown ids.
    - Out: dashboard providers.
  - Done when: a logged meal's macros survive an ingredient edit; amount edits
      rescale exactly; a dangling food id is skipped, not fatal;
      `flutter analyze lib` clean.
  - Verification notes: `flutter test test/meal_repository_test.dart`.

- [x] T06: `Dashboard — single aggregation query`
  - Task ID: T06
  - Goal: Stop walking the graph twice.
  - Boundaries (in/out of scope):
    - In: `lib/src/dashboard/providers/dashboard.dart` — `todayCaloriesProvider`
      and `todayMacrosProvider` become direct `SUM` aggregates over
      `meal_foods` joined to `meals` for the day window, sharing one query
      helper; keep the `dashboardRefreshProvider` and `startupGateProvider`
      behaviour.
    - Out: the dashboard UI.
  - Done when: both providers issue one aggregate query each and agree with the
      meal list totals.
  - Verification notes: `flutter analyze lib`; assert totals match `getAll()`.

- [x] T07: `Providers`
  - Task ID: T07
  - Goal: Riverpod surface for foods.
  - Boundaries (in/out of scope):
    - In: `lib/src/diet/providers/foods.dart` — `foodRepositoryProvider`,
      `foodListProvider`, `foodByIdProvider.family`,
      `foodIngredientsProvider.family`; delete
      `ingredientComponentsProvider` from `providers/ingredients.dart`.
    - Out: screens.
  - Done when: providers compile and nothing references the deleted one.
  - Verification notes: `flutter analyze lib`.

- [x] T08: `Strip composite UI from the ingredient screens`
  - Task ID: T08
  - Goal: The ingredient form goes back to being purely atomic.
  - Boundaries (in/out of scope):
    - In: `ingredient_form.dart` — remove the Simple/Recipe toggle, the pinned
      nutrition band, the components editor, the picker sheet, the amount
      controllers/notifiers and the `_isComposite` save branches;
      `ingredient_detail_screen.dart` — remove `_RecipeSection`/`_RecipePartRow`;
      `ingredient_list.dart` — remove the recipe pill; delete the ARB keys that
      become unused.
    - Out: the new food screens (T09).
  - Done when: no `isComposite` reference remains in `lib/`; the atomic form is
      unchanged otherwise; `flutter analyze lib` clean.
  - Verification notes: `flutter gen-l10n`; `flutter analyze lib`; dead-key sweep.

- [x] T09: `Food screen + composition editor`
  - Task ID: T09
  - Goal: Browse/log foods, and build combinations.
  - Boundaries (in/out of scope):
    - In: new `lib/src/diet/screens/food_list.dart` and `food_form.dart`,
      re-homing the composition editor (inline amount fields, contribution
      lines, alphabetical order, no drag handle) out of `ingredient_form.dart`;
      "add ingredient" opens the existing ingredient form and relies on T04's
      auto-creation; combined with the Foods list from T08's navigation.
    - Out: the meal picker (T10).
  - Done when: a combination can be created, edited, archived; a 1-ingredient
      food is read-only; `flutter analyze lib` clean.
  - Verification notes: `flutter gen-l10n`; `flutter analyze lib`.

- [x] T10: `Meal screens — food picker`
  - Task ID: T10
  - Goal: Log amounts of foods.
  - Boundaries (in/out of scope):
    - In: `meal_form.dart` — the picker watches `foodListProvider` instead of
      `ingredientListProvider`, shows each food's live per-100g and previews the
      portion calories as the amount is typed; `meal_list.dart` — read the
      snapshot macros instead of joined ingredient macros; drop the unused
      `MealIngredient.fromIngredient` dead code.
    - Out: sync.
  - Done when: a meal can be logged from foods and the totals match;
      `flutter analyze lib` clean.
  - Verification notes: `flutter analyze lib`.

- [x] T11: `Sync — foods endpoint on the client`
  - Task ID: T11
  - Goal: User-created foods sync; composites stop riding the ingredient payload.
  - Boundaries (in/out of scope):
    - In: `lib/src/sync/food_sync_client.dart` — `GET /foods?since=` and
      `POST /foods`; only user-created foods (never `isDerived` ones) are pushed;
      a pull applies **ingredients before foods** and auto-imports any ingredient
      a pulled recipe needs but does not have (via the existing selective import);
      remove `components[]` from `ingredient_sync_client.dart` push + parse and
      the `components` parameter from `sync_service.pushIngredient`; add
      `endpointFoods` to settings; tighten
      `local_backup.dart:84` — `key.contains('meal')` also matches `mealFoods`.
    - Out: server.
  - Done when: a recipe round-trips push/pull; `flutter analyze lib` clean.
  - Verification notes: `flutter analyze lib`; `flutter test test/food_sync_test.dart`.

- [x] T12: `Server — foods tables + endpoints`
  - Task ID: T12
  - Goal: Shareable recipes on the server.
  - Boundaries (in/out of scope):
    - In: `sync-server/src/db.rs` — `foods` and `food_ingredients` DDL, drop
      `ingredient_components`; `push.rs` — remove `IngredientComponentPush` and
      the `components` field/loop, add `push_foods` with replace semantics that
      skips unknown `ingredient_id`s (FK is on and push unwraps);
      `pull.rs` — remove `Ingredient.components`, add `pull_foods`;
      `server.rs` — route `GET`/`POST /foods`; tests.
    - Out: desktop UI.
  - Done when: `cargo test -p sync-server` green with foods coverage.
  - Verification notes: `cargo test -p sync-server`; `cargo check --workspace`.

- [x] T13: `Desktop (maia-ui) — foods`
  - Task ID: T13
  - Goal: Foods on the desktop app.
  - Boundaries (in/out of scope):
    - In: `maia-ui/src-tauri/src/lib.rs` — drop the composite commands
      (`list_ingredient_components`, `add_ingredient_component`,
      `delete_ingredient_component`, `recompute_composite_macros`) and the
      `isComposite`/`components` fields on `list_ingredients`; add
      `list_foods`, `list_food_components`, `upsert_food`,
      `delete_food_component`, registered in `generate_handler!`;
      `maia-ui/src/main.ts` — a foods list + combination editor replacing
      `renderRecipeModal`, reusing only the approved classes in
      `styles/CATALOG.md`.
    - Out: sync.
  - Done when: `pnpm --dir maia-ui build` exit 0; `cargo check -p maia-ui`.
  - Verification notes: `pnpm --dir maia-ui build`.

- [x] T14: `Tests`
  - Task ID: T14
  - Goal: Cover the new read path and the invariants.
  - Boundaries (in/out of scope):
    - In: repurpose `test/composite_ingredients_test.dart` →
      `test/ingredient_repository_test.dart` and `test/composite_sync_test.dart` →
      `test/food_sync_test.dart`; add `test/food_nutrition_test.dart`,
      `test/food_repository_test.dart`, `test/meal_repository_test.dart` for the
      snapshot/rescale/dangling-id behaviour and the 1:1 invariant.
    - Out: UI tests (none exist for these screens).
  - Done when: `flutter test` green and strictly more tests than the 112 baseline.
  - Verification notes: `flutter test`.

- [x] T15: `Validation and context sync`
  - Task ID: T15
  - Goal: Full checks and accurate documentation.
  - Boundaries (in/out of scope): in — build_runner, gen-l10n, analyze, format,
    tests, `context/database/schema.md` (v34),
    `context/diet/ingredient-crud.md`, `context/diet/meal-crud.md`,
    `context/glossary.md`, `context/sync/sync-contract.md`, and
    `doc/diet.md` — whose "editing an ingredient retroactively changes past meals"
    note is now **inverted** by the snapshot; out — commit.
  - Done when: `flutter analyze lib` clean; `flutter test` green;
    `cargo test -p sync-server` green; context reads back accurate.
  - Verification notes: full sweep + dead-key sweep.

## Validation Report

Run 2026-10-03.

| Check | Result |
|-------|--------|
| `flutter analyze lib` (mobile) | 0 errors, 0 warnings (66 pre-existing info-level lints) |
| `flutter test` (mobile) | **147 passed**, 0 failed |
| `cargo test` (sync-server) | **39 passed**, 0 failed, 1 ignored |
| `cargo check` (maia-ui) | clean |
| `npx tsc --noEmit` (maia-ui) | clean |
| `npx vite build` (maia-ui) | built |

New test coverage added: `test/food_nutrition_test.dart` (11),
`test/food_repository_test.dart` (14), `test/meal_repository_test.dart` (14),
`test/ingredient_repository_test.dart` (11, extended), `test/food_sync_test.dart` (12,
replacing `test/composite_sync_test.dart`). Server: `push_foods_idempotent_and_replaces_composition`,
`pull_foods_nests_composition_without_nutrition`.

Two behaviours were corrected during validation rather than shipped as first written:

- **Resolution is all-or-nothing.** `resolveNutrition`/`_nutritionOf` originally summed
  the components that happened to be present. That under-reported calories *and* dropped
  the missing part from the weight denominator, inflating the rest. Both now return null.
- **Composition reads keep unresolved parts.** `getComponents` inner-joined ingredients,
  so a recipe missing one part silently looked like a smaller recipe. It now left-joins.

Docs updated: `context/database/schema.md` (v34 tables + migration),
`context/diet/ingredient-crud.md`, `context/diet/meal-crud.md`, new
`context/diet/food-crud.md`, `context/glossary.md`, `context/architecture.md`,
`context/sync/sync-contract.md`, `doc/diet.md`, `context/ui/design-system.md`.

Commits: `e00d349`, `648895e`, `f8d98be` (mobile); `2df9f0c` (server); `5f9388f` (desktop).

## Next Command

T01