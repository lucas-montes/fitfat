# Plan: Composite ingredients — recipes from other ingredients

## Change Summary

Restore the composite-ingredient capability that was lost in the `2893826`
"delete all" wipe, re-implemented against the current architecture (and with
the write path that the old code never had).

A **composite ingredient** is a recipe: an ingredient whose per-100g macros are
derived from other ingredients ("components") plus their gram amounts. It is
selectable in the meal form exactly like an atomic ingredient, because its
macros are **materialized** into the `ingredients` row on every save — the same
`meal_ingredients` → `ingredients` join at
`diet/repositories/meal_repository.dart:43-56` already reads for atomic
ingredients keeps working untouched.

Scope: mobile (schema, model, repository, UI, sync client) + `sync-server`
(schema + sync contract) + `maia-ui` desktop.

## Success Criteria

- Schema v33 adds `ingredient_components`; existing DBs migrate cleanly.
- A composite's per-100g macros equal the gram-weighted sum of its components,
  scaled to 100g over the total component weight.
- Component rows are **written and persisted** (the old implementation only ever
  read them) and survive a restart.
- Ingredient form: switch between atomic macros and a components editor;
  computed macros preview live; save blocked while a composite has no
  components.
- Components must be atomic, non-archived, and not the ingredient itself.
- `POST/GET /ingredients` round-trips a nested `components[]` array; pushing the
  same aggregate twice is idempotent; removing a component server-side happens
  by omission (replace semantics), not tombstones.
- `maia-ui` can list/add/remove components.
- `flutter analyze lib` clean; `cargo test -p sync-server` green;
  `pnpm --dir maia-ui build` exit 0.

## Decisions

| Question | Decision | Rationale |
|---|---|---|
| Per-100g denominator | **sum of component grams** | Matches the old `fromComponents`; no extra column |
| Nesting | **flat only** — components must be non-composite | No cycle detection needed; pickers just filter |
| Macros | **materialized** on save into `ingredients` | `meal_ingredients` joins the live `ingredients` row; computing on read would force changes in `meal_repository`, the dashboard aggregator, the list screen and the sync pull |
| Composite-ness | **derived** via `EXISTS`, not a stored column | Single source of truth; nothing to drift |
| Sync shape | **nested inside the `/ingredients` aggregate** | Mirrors `pictures[]`/`prices[]`; no new route or endpoint setting |

## Constraints & Non-Goals

- **Non-goal: nested composites.** Enforced in the picker and re-checked in
  `saveComponents`.
- **Non-goal: explicit yield / output weight.** Denominator is always the sum.
- **Non-goal: fixing the retroactive-macro problem.** `meal_ingredients` stores
  no macro snapshot, so editing an ingredient's macros already rewrites the
  history of every meal that used it. That is pre-existing for all ingredients;
  this plan does not change it.
- **Non-goal: serving-size units.** Components are grams only, as before.
- Additive schema change only: one new table, one new index, no column edits on
  existing tables.
- Server-side, `PRAGMA foreign_keys = ON` (`sync-server/src/db.rs:18`) and push
  uses `.unwrap()`, so an FK violation is a 500 rather than a 400. Component
  rows referencing an ingredient the server does not have are **skipped**, not
  inserted as stubs — the composite's materialized macros still push, so the
  server copy stays usable, just not expandable.

## Task Stack

- [x] T01: `Schema v33 + domain models + composite macro math`
  - Task ID: T01
  - Goal: Land the storage shape and the pure per-100g computation.
  - Boundaries (in/out of scope):
    - In: `lib/src/database/tables.dart` — `IngredientComponents` (id,
      `ingredient_id` FK CASCADE, `component_id` FK, grams, sort_order,
      created_at); `lib/src/database/app_database.dart` — register in
      `@DriftDatabase`, `schemaVersion` 32 → 33, `from < 33` migration,
      idempotent `ingredient_id`/`component_id` indexes in `beforeOpen`; new
      `lib/src/models/ingredient_component.dart`; `Ingredient.isComposite` +
      `copyWith`; new
      `lib/src/diet/services/composite_macros.dart` with the pure
      `computeCompositePer100g`.
    - Out: repository, UI, sync.
  - Done when: `ingredient_components` exists post-migration; codegen
    regenerated; `flutter analyze lib` clean.
  - Verification notes (commands or checks):
    - `flutter pub run build_runner build`;
      `flutter analyze lib`.
  - Status: done. Drift initially warned about two FKs onto `Ingredients`;
    resolved with `@ReferenceName('ownedComponents')` /
    `@ReferenceName('usedInComponents')`, matching the `Transactions` pattern.

- [x] T02: `Repository — read, write, and isComposite hydration`
  - Task ID: T02
  - Goal: The missing write path. Persist components and materialize macros
    atomically.
  - Boundaries (in/out of scope):
    - In: `lib/src/diet/repositories/ingredient_repository.dart` —
      `_compositeIds()` + `isComposite` hydration in `getAll()`/`getById()`;
      `getComponents(ingredientId)` (sorted, joined for `componentName`);
      `saveComponents(ingredientId, drafts)` in one transaction (delete rows,
      insert fresh ids, recompute + write macros, reject
      composite/self/duplicate/non-positive/unknown components);
      `clearComponents(ingredientId)`;
      `replaceComponentsFromServer(...)` for the sync path.
    - Out: UI, sync client, server.
  - Done when: components round-trip; composite macros materialized on save;
    invalid components rejected; `flutter analyze lib` clean.
  - Verification notes (commands or checks):
    - `flutter analyze lib`; `flutter test test/composite_ingredients_test.dart`.
  - Status: done. 18 → 21 tests in `test/composite_ingredients_test.dart`, all
    passing. Drift's `select(..).addColumns(..)` row type would not resolve
    (`readTable`/`read` missing), so composite-ness is hydrated from a
    dedicated `_compositeIds()` `selectOnly` read instead of an `EXISTS`
    expression.

- [x] T03: `Ingredient form — atomic vs composite editor`
  - Task ID: T03
  - Goal: Create and edit composites.
  - Boundaries (in/out of scope):
    - In: `lib/src/diet/screens/ingredient_form.dart` — a "type" toggle;
      when composite, the 7 macro inputs are replaced by a read-only computed
      summary (per-100g + total weight); a components editor (rows with
      name/grams, edit + remove, search-to-add sheet filtered to atomic
      non-archived ingredients excluding self); save disabled at zero
      components; recipe written after the parent row in `_save`.
    - Out: detail screen, list badge, l10n keys (T04).
  - Done when: a composite can be created and edited end-to-end; the atomic
    path is unchanged in behaviour; `flutter analyze lib` clean.
  - Verification notes (commands or checks): `flutter analyze lib`.
  - Status: done. Macro fields are dropped from the tree in composite mode, so
    `Form.validate()` cannot cover the "recipe has no components" case — hence
    both a disabled save button and an explicit guard in `_save`.

- [x] T04: `Recipe section on detail, list badge, l10n`
  - Task ID: T04
  - Goal: Make composites legible outside the editor.
  - Boundaries (in/out of scope):
    - In: `lib/src/diet/screens/ingredient_detail_screen.dart` — `_RecipeSection`
      listing components with grams, gated on `isComposite`;
      `lib/src/diet/screens/ingredient_list.dart` — recipe icon on composite
      tiles; `lib/src/diet/providers/ingredients.dart` —
      `ingredientComponentsProvider.family`; `lib/l10n/app_{en,es,fr}.arb` +
      `flutter gen-l10n`.
    - Out: composite-specific layout elsewhere.
  - Done when: composites are identifiable from the list and expandable on the
    detail screen; `flutter gen-l10n` exit 0; `flutter analyze lib` clean.
  - Verification notes (commands or checks): `flutter gen-l10n`; `flutter analyze lib`.
  - Status: done. 23 new ARB keys × 3 locales.

- [x] T05: `Server — ingredient_components table`
  - Task ID: T05
  - Goal: Server-side storage for components.
  - Boundaries (in/out of scope):
    - In: `sync-server/src/db.rs` — `ingredient_components` DDL inside the
      `create_schema` batch, following `meal_ingredients` (`db.rs:94-101`):
      `id TEXT PRIMARY KEY`, `ingredient_id` CASCADE, `component_id` FK,
      `grams REAL NOT NULL`, `sort_order`, `created_at`, `updated_at`,
      `deleted_at`; plus indexes on both FK columns.
    - Out: handlers.
  - Done when: `migrations_idempotent` green; table created on fresh and
    pre-existing DBs.
  - Verification notes (commands or checks): `cargo test -p sync-server`.
  - Status: done.

- [x] T06: `Server sync — push + pull components`
  - Task ID: T06
  - Goal: Round-trip components through the existing `/ingredients` aggregate.
  - Boundaries (in/out of scope):
    - In: `sync-server/src/handlers/push.rs` — `IngredientComponentPush`,
      `#[serde(default)] components` on `IngredientContribution`,
      delete-then-insert (replace semantics) inside the existing transaction,
      skip unknown `component_id`s, add `ingredient_components` to the
      `deleted[]` loop; `sync-server/src/handlers/pull.rs` —
      `IngredientComponent` + `Ingredient.components`, second query per
      ingredient; `get_ingredient_item` includes `components`.
    - Out: `ingredients/catalog` (stays minimal), `maia-ui`.
  - Done when: `push_ingredient_idempotent` and `pull_ingredients_nested` cover
    components; push is idempotent and replace-exact; `catalog_and_item_routes`
    still asserts the catalog has no `components` key.
  - Verification notes (commands or checks): `cargo test -p sync-server`.
  - Status: done. The `pull_ingredients_nested` / `catalog_and_item_routes`
    fixtures gained a second ingredient (the part), so their item-count
    assertions moved from 1 to 2.

- [x] T07: `Mobile sync client — push and parse components`
  - Task ID: T07
  - Goal: Send and receive components.
  - Boundaries (in/out of scope):
    - In: `lib/src/sync/ingredient_sync_client.dart` — `push()` takes
      `components` and nests them; `upsertAggregate` parses `components[]` via
      `_parseComponent` and applies them with `replaceComponentsFromServer`;
      `lib/src/sync/sync_service.dart` `pushIngredient` plumbing;
      `ingredient_detail_screen._pushToServer` sends the recipe.
    - Out: contract rewrite beyond the components rows (T09).
  - Done when: components survive a push/pull round-trip in the sync tests;
    `flutter analyze lib` clean.
  - Verification notes (commands or checks):
    - `flutter analyze lib`; `flutter test test/composite_sync_test.dart`.
  - Status: done. `test/composite_sync_test.dart` adds 7 tests. `MockApiClient`
    is `final`, so the recording fake implements `ApiClient` directly.

- [x] T08: `Desktop (maia-ui) — commands + components UI`
  - Task ID: T08
  - Goal: Author composites from the desktop app.
  - Boundaries (in/out of scope):
    - In: `maia-ui/src-tauri/src/lib.rs` —
      `recompute_composite_macros` (shared derivation),
      `list_ingredient_components`, `add_ingredient_component`,
      `delete_ingredient_component` (dense renumber + re-derive), registration
      in `generate_handler!`, and `isComposite`/`components` on
      `list_ingredients`; `maia-ui/src/main.ts` — `renderRecipeModal`, handlers,
      recipe badge + inline component chips on list rows, recipe search,
      Escape handling.
    - Out: new CSS classes — reuse the approved set in `styles/CATALOG.md`.
  - Done when: components can be listed/added/removed from the desktop UI;
    `pnpm --dir maia-ui build` exit 0.
  - Verification notes (commands or checks): `pnpm --dir maia-ui build`; `cargo check -p maia-ui`.
  - Status: done.

- [x] T09: `Validation and context sync`
  - Task ID: T09
  - Goal: Full checks and accurate documentation.
  - Boundaries (in/out of scope): in — build_runner, gen-l10n, analyze, format,
    tests, `context/database/schema.md`, `context/diet/ingredient-crud.md`,
    `context/glossary.md`, `context/sync/sync-contract.md`, and a rewrite of
    `doc/diet.md`; out — commit.
  - Done when: `flutter analyze lib` clean; `flutter test` green;
    `cargo test --workspace` green; context reads back accurate.
  - Verification notes (commands or checks): see Validation Report.
  - Status: done.

- [x] T10: `Composite-ingredient UI redesign`
  - Task ID: T10
  - Goal: Make the composite UI consistent with the design system and finish
    the surfaces T03–T08 left rough.
  - Boundaries (in/out of scope):
    - In: the six surfaces the user picked (type selector, component row,
      pinned nutrition, picker sheet, list marker, detail provenance); the
      dead/hardcoded-string defects; `commonDelete`; context sync of
      `context/ui/design-system.md` + `context/diet/ingredient-crud.md`.
    - Out: schema, repository, sync, server, desktop — **no behaviour change**.
  - Done when: every ARB key has a call site; no hardcoded user-facing string
    in the composite UI; `flutter analyze lib` at the 61-issue baseline;
    `flutter test` 112/112.
  - Verification notes (commands or checks): gen-l10n, analyze, test, format,
    dead-key sweep.
  - Status: done. See Validation Report.

## Validation Report

- **Commands run:**
  - `flutter pub run build_runner build` — regenerated `app_database.g.dart`.
  - `flutter gen-l10n` — exit 0, 23 keys × en/es/fr.
  - `flutter analyze lib` — **61 issues, 0 errors**, identical to the
    pre-change baseline (57 infos + 4 pre-existing warnings); none in any
    touched file.
  - `flutter test` — **112/112 pass**, up from 92. New: 21 in
    `test/composite_ingredients_test.dart`, 7 in
    `test/composite_sync_test.dart`.
  - `dart format --output=none --set-exit-if-changed` on the touched files —
    clean. One pre-existing violation left alone in `ingredient_list.dart:52`
    (`refreshIngredientCatalog` chain) to keep this diff free of unrelated
    reformatting.
  - `cargo test --workspace` — all suites green (`sync-server` 37 passed,
    1 ignored; the ignore is the pre-existing live-Gemini OCR test).
  - `cargo check --workspace` — clean (41 pre-existing warnings in `maia-ui`).
  - `pnpm --dir maia-ui build` — exit 0 (`tsc && vite build`).
  - `rustfmt --check` on the four touched Rust files shows only pre-existing
    import-ordering deviations on line 1, so the files were left unformatted
    rather than producing a whole-file reformat diff.

- **Environment finding (worth keeping):** the seven previously-reported
  `Failed to load dynamic library 'libsqlite3.so'` test failures were *not* a
  code problem — the Nix devshell does not put sqlite on the loader path.
  `export LD_LIBRARY_PATH=/nix/store/p0070ky52z5qq0s7815dc93v1xh9bnd4-sqlite-3.50.4/lib`
  makes the whole suite run. That is why this plan can report 112/112 instead
  of a partial count, and the DB-backed tests are now actually exercised.

- **Success criteria:** met — schema v33 creates `ingredient_components` on
  both fresh installs and upgrades; per-100g macros are the gram-weighted
  component totals normalized to the batch weight; rows persist and survive a
  restart; the form toggles Simple/Recipe with a live calculated-nutrition card
  and a components editor; components must be atomic, non-archived (unless
  already present), non-duplicate and non-self; `POST/GET /ingredients`
  round-trips `components[]` idempotently with replace-exact removal; the
  desktop app can author recipes.

- **Deviations:**
  - `isComposite` is **derived** from `ingredient_components` rather than
    stored, and hydrated by a dedicated `_compositeIds()` read instead of an
    `EXISTS` subquery — Drift's `select(..).addColumns(..)` row type did not
    resolve for this query, and a stored column could drift from the recipe.
  - **No nesting.** Confirmed with the user; recipes are flat. Enforced in the
    form picker, `saveComponents`, and the desktop command. Not a cycle guard —
    cycles are unrepresentable.
  - **No yield/cook-weight field.** Confirmed with the user; the denominator is
    always the sum of component grams.
  - Components whose ingredient the server (or client) has never seen are
    **skipped**, not stub-inserted. `PRAGMA foreign_keys` is ON and push
    `.unwrap()`s, so a stub or a hard failure were the alternatives; the
    composite's macros still travel, so the row stays usable.
  - `GET /ingredients/item/:id` now includes `components` (it already carried
    the materialized macros, so this costs nothing and makes a selectively
    imported recipe expandable). `GET /ingredients/catalog` deliberately stays
    minimal.

- **Bugs found and fixed while implementing:**
  - **The derivation was 100× wrong on the first pass.** `Σ(per100g × grams)` is
    already an absolute amount, so it must be *divided* by the total weight; the
    first version multiplied by `100 / totalGrams` and reported `38000` kcal per
    100 g instead of `380`. Caught by `computeCompositePer100g`'s unit tests
    before any UI existed.
  - **Archiving a part would have silently emptied it from the recipe.** The
    form resolved components from `ingredientListProvider`, which hides archived
    ingredients, so re-saving would drop the part; and `saveComponents` would
    then have rejected it and dead-ended the form. Fixed on both sides:
    `_loadComponents` falls back to `getById` (no archive filter), and
    `saveComponents` only rejects an archived component when it is *newly*
    added, so an existing part stays editable.
  - The server DDL was missing `sort_order`/`created_at` on the first write;
    caught immediately by `pull_ingredients_nested`.

- **Notes:** the old implementation's failure mode was the write path, so T02
  (repository) and its tests were deliberately done before any UI. The
  pre-existing gaps noted during design were **not** touched:
  `ingredient_repository.update()` still omits `isArchived`; `upsertAggregate`
  still reads `updated_at`/`recorded_at` for nested pictures/prices where the
  server sends `createdAt`/`recordedAt` (components use camelCase correctly, as
  documented); `meal_ingredients` still stores no macro snapshot; the server
  `deleted[]` loop is still a flat namespace across ingredient tables.

## Next Command

None — all tasks complete.

## Validation Report — T10 UI redesign

- **Commands run:** `flutter gen-l10n` (exit 0); `flutter analyze lib` —
  **61 issues, 0 errors**, unchanged from the pre-redesign baseline, none in
  any touched file; `flutter test` — **112/112**; `dart format
  --output=none --set-exit-if-changed` on the touched files — clean;
  dead-key sweep — **zero dead keys** across `ingredient*` and `common*`.

- **Choices confirmed with the user:** 1-A labelled segmented, 2-A inline amount
  + contribution, **3-B pinned nutrition** (implemented as an always-visible
  `Column` band rather than a sliver, after the fixed-extent problem was
  identified), 4-A picker stays open with inline amounts, 5-A `StatusBadge`
  pill, 6-A full detail provenance. Contribution line = `kcal · P · C · F`
  (grams dropped — already in the field).

- **Defects fixed:**
  - **4 dead ARB keys** (`ingredientFormTypeLabel`, `ingredientListCompositeBadge`,
    `ingredientCompositeEditTitle`, `ingredientCompositeNoComponents`) plus
    **5 retired** by the redesign and **1 pre-existing** (`ingredientFormScanning`
    from the ingredient-metadata feature). Every `ingredient*`/`common*` key now
    has a call site; the sweep is in `context/ui/design-system.md` as a contract.
  - **`commonDelete` rendered as the tooltip "Common Delete"** (the literal en
    value, used in 10 places app-wide). Now "Delete"/"Supprimer"/"Eliminar", and
    the composite rows use `commonRemove`, which was already correct.
  - **Hardcoded English** in the nutrition card (`'P '`, `'C '`, `'F '`,
    `'Fiber '`, `'Sugar '`, `'Na '`, `'—'`) replaced with the existing
    `ingredientNutrientSodium/Fiber/Sugar` + new localized keys.
  - **`(sheetCtx as Element).markNeedsBuild()`** per keystroke removed — the
    picker is a `StatefulWidget` owning its query and controllers.

- **Deviations from the plan (all forced by a platform constraint):**
  - The pinned band is a `Column` sibling of `Expanded(ListView)`, **not** a
    `SliverPersistentHeader`. Both sliver options require a fixed extent, and
    this card's height varies (the nutrient line appears/disappears) and scales
    with text size. The app's only pinned-header precedent
    (`exercise_detail_screen.dart:90`) sidesteps this only because its header
    height is a constant. Documented in `context/ui/design-system.md` as the
    general rule.
  - `FormFieldState.errorText` is **final**, so per-field amount validation uses a
    `ValueNotifier<String?>` map consumed by each field's decoration instead of
    assigning to the field state.
  - `TextFormField(initialValue:)` was replaced with a controller + plain
    `TextField`: rows rebuild on every keystroke (the summary must recompute),
    which would recreate the field and drop the caret mid-edit.

- **Notes:** no behaviour, schema, repository, sync or server change. Reorder
  persists through the existing `saveComponents` list ordering; contributions are
  display-only and derived from `Ingredient.macrosForGrams`. Manual checks still
  wanted on a real device: reorder dragging with the keyboard open, and the
  band competing with the keyboard for space (mitigation available — hide the
  band while `viewInsets.bottom > 0`). Pre-existing and untouched:
  `meal_ingredients` still stores no macro snapshot, so editing a recipe
  retroactively changes past meals' nutrition.
