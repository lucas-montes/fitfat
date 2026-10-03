# Ingredient CRUD — Diet Domain

Feature: create, read, update, and **soft-archive** food ingredients (items with macros per 100g plus optional extra nutriments), plus **shopping metadata** (v20): brand + barcode, multiple pictures per ingredient, and per-store price history with cost-per-100g — and **composite ingredients** (v33), where an ingredient is built from other ingredients and its macros are derived from them.

## Files

| File | Purpose |
|------|---------|
| `lib/src/diet/repositories/ingredient_repository.dart` | Drift DAO wrapping `ingredients` + `stores` + `ingredient_pictures` + `ingredient_prices` + `ingredient_components`; `newIngredient()` / `newStore()` / `newIngredientPicture()` / `newIngredientPrice()` helpers |
| `lib/src/diet/providers/ingredients.dart` | Riverpod providers (`databaseProvider`, `ingredientRepositoryProvider`, `ingredientListProvider`, `ingredientByIdProvider`, `storesProvider`, `ingredientPicturesProvider.family`, `ingredientPricesProvider.family`, `ingredientComponentsProvider.family`) |
| `lib/src/models/ingredient.dart` | Domain model (macros, nutriments, `brand`, `barcode`, `isComposite`) |
| `lib/src/models/store.dart` | Domain model for a store |
| `lib/src/models/ingredient_picture.dart` | Domain model for a picture row (`sortOrder` gallery order) |
| `lib/src/models/ingredient_price.dart` | Price observation + `costPer100gInBase()` (FX-converted via budget's `convertToBase`) |
| `lib/src/models/ingredient_component.dart` | Domain model for a recipe component (carries a denormalized `componentName`); `ComponentInput` typedef |
| `lib/src/diet/services/composite_macros.dart` | Pure `computeCompositePer100g` — the per-100g derivation, free of Drift so it is directly testable |
| `lib/src/diet/screens/ingredient_list.dart` | ListView with FAB, tap → detail screen, swipe-to-archive + Undo banner, recipe icon on composites |
| `lib/src/diet/screens/ingredient_form.dart` | Name + macros + nutriments + brand + barcode + scan tile + reorderable picture strip **+ simple/recipe toggle with a components editor** |
| `lib/src/diet/screens/ingredient_detail_screen.dart` | Read-mostly detail: chips, macro card, picture gallery + full-screen viewer, **recipe section**, prices section (latest per store + history + price sheet), manage-stores entry |
| `lib/src/diet/screens/store_manager_screen.dart` | Store list with FAB add + tap-to-rename; exports `promptStoreName()` dialog reused by the price sheet |

## Key behavior

- **Repository** (`ingredient_repository.dart`): Uses `IngredientsCompanion.insert()` for inserts and `IngredientsCompanion()` for updates. Converts domain ↔ Drift rows via `_toDomain()` helpers; nulls round-trip unchanged (nutriments, brand, barcode). `update` writes only named fields, so `isArchived` is preserved on edits.
- **Soft-archive (T05, schema v4)**: `getAll()` filters `is_archived == false`; `archive(id)` / `restore(id)` flip the flag. **No hard delete exists** — no code path can hit an FK violation from deleting a referenced ingredient.
- **Stores (v20)**: `getStores()` (name-ordered), `getStoreById()`, `insertStore()`, `updateStore()` (rename only — prices reference the store id, so renames propagate to every price row).
- **Pictures (v20)**: `getPictures(ingredientId)` ordered by `sort_order` then `created_at`; `insertPicture()`; `deletePicture()`; `reorderPictures(ingredientId, orderedIds)` rewrites `sort_order` densely (0..n-1) in a batch. Image files are copied to `<docs>/ingredient_pictures/<uuid>.ext` (receipts pattern).
- **Prices (v20)**: `upsertPrice()` uses drift `insertOnConflictUpdate` against the unique `(ingredient_id, store_id, recorded_at)` — one observation per product/store/day; same-day re-record replaces in place. `deletePrice(id)` supports "move to another day" edits (delete old row, insert new). `getPrices(ingredientId)` joins `stores` and returns `(IngredientPrice, Store)` records newest-first; `latestPricesPerStore()` keeps the first entry per store from that list.
- **Providers**: `databaseProvider` (singleton `AppDatabase`), `ingredientRepositoryProvider`, `ingredientListProvider` (async list), `ingredientByIdProvider.family` (null when missing — detail not-found state), `storesProvider`, plus autoDispose families `ingredientPicturesProvider` / `ingredientPricesProvider` keyed by ingredient id.
- **List screen**: Macro subtitle per ingredient plus an optional extra-nutriment line (sodium mg / fiber g / sugar g, joined with " · "). `Dismissible` (end-to-start) → `archive` + top banner `ingredientArchived` ("Ingredient \"{name}\" archived") with Undo → `restore`; `Haptics.mediumImpact` on dismiss. **No confirm dialog** (archive is non-destructive). FAB opens the form for a new ingredient; tapping a tile opens the **detail screen** (edits go through the detail appbar). Empty state = `EmptyState` (`soup_kitchen_outlined`, `emptyIngredients*` ARB keys) whose CTA opens the form.
- **List sync menu (selective-sync-catalog T05)**: the AppBar sync action is a `PopupMenuButton` — **Sync all** runs the bulk `SyncService.syncIngredients` pull and **Select…** refreshes the `IngredientCatalog` (unreachable → blocking banner), opens `showSelectSheet` over `searchHideImported` rows (barcode subtitles, fallback icon — no thumbnails in V1), and imports only the checked ids as minimal aggregates (image metadata + name + macros/nutriments + brand/barcode, no stores/prices) via `importSelectedIngredients`. Both paths invalidate `ingredientListProvider`. ARB: `syncAll`, `syncSelect`, `selectServerIngredients`, `syncNothingNew`, `ingredientListSearchHint`.
- **Form screen**: Validates name (required), calories (positive), macros (non-negative); optional nutriment fields: blank → stored `null`. New in v20:
  - **Brand** + **Barcode** optional text fields (barcode restricted to digits/`Xx-`); blank → null.
  - **Mock scan tile**: ListTile with `qr_code_scanner` icon — shows a spinner ~700 ms then fills the field with the fake EAN `_mockScannedBarcode` (`3017620422003`). Real camera scanning + Open Food Facts lookup deferred (will use the network-client `ApiClient`).
  - **Picture strip**: horizontal `ReorderableListView` of thumbnails — add via camera/gallery bottom sheet (`image_picker`, copied into `ingredient_pictures/`), remove (deletes the DB row immediately when persisted, best-effort file delete), drag to reorder. Pending pictures get rows after the ingredient row is written (`_persistPictures`: insert new at their list position, then re-fetch ids by image path and normalize `sort_order` densely).
- **Detail screen**: AppBar title = name with a single edit action (AppBar budget rule). Body: brand/barcode `Chip`s (when set), macro card (kcal/P/C/F + optional nutriment line), picture thumbnails (tap → full-screen `_PictureViewerScreen`: black background, swipeable `PageView` + pinch-zoom `InteractiveViewer`), then the prices section: header with a "Manage stores" `TextButton` (→ `StoreManagerScreen`), latest-per-store cards (store name, trailing price formatted via `bf.formatMoney(price, currencyCode)`, subtitle = cost-per-100g + package grams; tap → price sheet), an `ExpansionTile` with the full newest-first history (tap → price sheet), and an "Add price" tonal button.
- **Cost-per-100g**: computed by `IngredientPrice.costPer100gInBase(baseCode:, ratesToBase:)` = `convertToBase(price, code, base, rates) * 100 / grams`; hidden when `package_grams` is unknown. Rates come from `fxRatesProvider` + base currency from `settingsProvider` (same snapshot semantics as transactions).
- **Price sheet** (`showIngredientPriceSheet`): modal bottom sheet with store dropdown (validator requires a store), inline "Add store" action (`promptStoreName` dialog → `insertStore` → invalidate `storesProvider`), price + currency dropdown (base + common codes + fetched rate keys, like the transaction form), optional package grams, date picker. Save: moving an existing observation to another day deletes the original row first; same-day saves upsert over it.
- **Store manager screen**: FAB add + tap tile to rename via shared `promptStoreName` dialog; renames invalidate `storesProvider` so open price sheets/list tiles reflect them.

## Composite ingredients (v33)

An ingredient built from other **atomic** ingredients plus gram amounts — "Granola = 80 g oats + 20 g honey". It is selectable in the meal form exactly like an atomic ingredient.

### Materialized macros (the central design decision)

`meal_ingredients` stores only `(id, mealId, ingredientId, grams)` and **joins the live `ingredients` row** for macros (`meal_repository._getItemsForMeal`). So a composite's nutrition must be readable from that one row. Rather than reworking every consumer to expand recipes, `saveComponents` / `clearComponents` **materialize** the derived per-100g values into the `ingredients` row inside the same transaction as the recipe write. Consequences:

- `meal_repository`, the dashboard aggregator, the list screen and the meal-form picker are all unchanged and recipe-unaware.
- Editing a component's macros retroactively changes every composite that uses it — the same pre-existing "edit an ingredient, history shifts" behaviour that already applies to atomic ingredients. Not addressed by v33.
- The server and the desktop app need no derivation logic either: both receive the composite's macros with the aggregate.

### Composite-ness is derived, never stored

`Ingredient.isComposite` is not a column. `IngredientRepository._compositeIds()` reads the `ingredient_components` table (optionally narrowed to one id) and `getAll`/`getById` mark rows from it. There is no column to drift out of sync with the recipe, and no sync payload to keep consistent.

### Derivation

`computeCompositePer100g(List<ComponentMacroInput>)` in `diet/services/composite_macros.dart` is pure — no Drift, no `Ingredient` — so it is unit-tested directly. Each term accumulates `per100g * grams`, an **absolute** amount; dividing the totals by the total weight lands directly on a per-100g figure (there is no extra `/100` or `*100` factor). Sodium/fiber/sugar stay `null` only when *no* component ever provided a value; otherwise missing values count as zero. An empty list yields zeroes, not a division by zero.

### Recipe rules

- **Flat only.** A component must be atomic — `saveComponents` re-checks this and throws, and the form's picker filters composites out.
- A component cannot be the ingredient itself; duplicates and non-positive amounts are rejected.
- Archived components are rejected.
- Every rejection throws `ArgumentError` and the surrounding transaction rolls back, so a failed save leaves the previous recipe *and* its macros untouched.

### Repository API

| Method | Purpose |
|--------|---------|
| `getComponents(ingredientId)` | Recipe in display order, joined for `componentName` (resolved live, so renaming a part propagates without a rewrite) |
| `saveComponents(ingredientId, components)` | Replace the recipe + re-derive macros, one transaction. Empty list delegates to `clearComponents` |
| `clearComponents(ingredientId)` | Drop the recipe and zero the macros — turns a composite back into an atomic ingredient |
| `replaceComponentsFromServer(...)` | Sync path: replace rows **without** re-deriving (server macros are authoritative); skips components whose part has not been synced yet |

### Form and detail screens

The ingredient form opens on a **Simple / Recipe** `SegmentedButton` seeded from `ingredient.isComposite`, placed directly under the name field (the type decides what the rest of the form means, so it is asked before brand/barcode/price). A hint line under the toggle explains the active mode.

**Layout.** `body` is a `Column`: the calculated nutrition band (recipe mode only) followed by `Expanded(Form(ListView(...)))`. The band is a plain `Column` sibling rather than a sliver header, so its height is intrinsic — the optional nutriments and large text scales need no manual extent, `Form`/`validate()` are untouched, and there is no `NestedScrollView` to fight the keyboard. The tradeoff is ~64px permanently reserved.

- **Band** (`_ComputedNutritionBand`): three short lines — title, the four macros `kcal · P · C · F per 100g`, then total weight plus any optional nutriments. Every string is localized (`ingredientNutrientSodium/Fiber/Sugar`), and numbers go through `formatDecimal`. When the recipe is empty it shows the empty-state body instead of a bare em dash.
- **Recipe editor** (`_buildComponentsSection`): a `ReorderableListView` (`shrinkWrap` + `NeverScrollableScrollPhysics` + `primary: false` to nest inside the form's own `ListView`, as the picture strip does) with `buildDefaultDragHandles: false` and an explicit `ReorderableDragStartListener` handle — the default long-press drag would fight the amount field's text selection. Rows carry an inline amount field and the part's **contribution** to the batch (`Ingredient.macrosForGrams(grams)`, rendered via `ingredientCompositeContribution`) rather than the part's own per-100g density, which answers "why is my recipe 380 kcal?". Remove uses `delete_outline` + `commonRemove`. Haptics: `selection()` on reorder, `mediumImpact()` on remove.
- **Empty state** uses the shared `EmptyState` widget (per the design system), with the body switching to `ingredientCompositeAddUnavailable` when there are no eligible candidates at all.
- **Picker** (`_ComponentPickerSheet`): a `StatefulWidget` owning its search query and per-row amount controllers — the previous inline version had to call `markNeedsBuild()` on every keystroke. It **stays open** across adds so a whole recipe can be built in one visit, tracks added rows in a local `Set`, and reports each add through `addComponent` (which returns false for a duplicate so the row stays spendable). Closes with `commonOk`.
- **Save** is disabled — and additionally guarded in `_save` — while a recipe has no components, since the macro fields are absent in composite mode and the form validator cannot catch it.

**Amount editing.** Amounts live on `_ComponentDraft.grams` with a `Map<String, TextEditingController>` of field controllers, following `settings_screen.dart`. The controllers are required: rows rebuild on every keystroke (the summary must recompute), so a `TextFormField(initialValue: …)` would be recreated each rebuild and drop the caret. `_syncAmountControllers()` creates/updates/prunes them after any structural change. Per-field "amount must be positive" state uses a `Map<String, ValueNotifier<String?>>` because `FormFieldState.errorText` is final; a blank or unparseable field keeps the last valid amount and surfaces the error rather than zeroing the part.

**Detail screen** gains a "Made from" section: every part with its amount, its contribution to the batch, a total-weight line, and an "Edit recipe" button that reuses the existing appbar edit path (the form opens in recipe mode because `isComposite` seeds the toggle). Contributions need each part's own row, which `getComponents` returns via its join; when a part has not been synced yet the row falls back to the amount alone rather than showing zeros.

**List screen** marks composites with the shared `StatusBadge` pill (`colorScheme.primary`) instead of a bare icon, which is easy to miss in a long list.

## Archive semantics

- Archiving hides the ingredient from the list **and** the meal-form picker — the picker reads `ingredientListProvider` (no separate query), so the repo-level `getAll` filter covers every consumer.
- Past meals keep rendering archived ingredient names/macros: `meal_repository._getItemsForMeal` joins **all** ingredient rows (no `is_archived` filter) — intentionally untouched.
- A composite already containing an archived part keeps working: its macros are materialized, and `getComponents` joins ingredient rows without an archive filter.
- No restore surface beyond the immediate Undo top banner (user decision). Undo is ephemeral — a restart during the window loses it (accepted).

## Nutriments (ingredient-only)

Sodium (mg), fiber (g), sugar (g) are **optional per-100g values on the ingredient only** — they are not propagated to `meal_ingredients` or meal breakdowns. `Ingredient.copyWith` uses a sentinel pattern so an explicit `null` clears a value on edit (the same pattern covers `brand`/`barcode`).

## Wiring

The Diet tab (`lib/src/app/tabs/diet_tab.dart`) renders `IngredientListScreen` directly; navigation between list/detail/form/store-manager is plain `Navigator.push(MaterialPageRoute(...))`. The app is wrapped in `ProviderScope` in `lib/src/app/app.dart`.

See also: [overview.md](../overview.md), [architecture.md](../architecture.md), [database/schema.md](../database/schema.md)
