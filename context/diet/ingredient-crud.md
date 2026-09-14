# Ingredient CRUD — Diet Domain

Feature: create, read, update, and **soft-archive** food ingredients (items with macros per 100g plus optional extra nutriments), plus **shopping metadata** (v20): brand + barcode, multiple pictures per ingredient, and per-store price history with cost-per-100g.

## Files

| File | Purpose |
|------|---------|
| `lib/src/diet/repositories/ingredient_repository.dart` | Drift DAO wrapping `ingredients` + `stores` + `ingredient_pictures` + `ingredient_prices`; `newIngredient()` / `newStore()` / `newIngredientPicture()` / `newIngredientPrice()` helpers |
| `lib/src/diet/providers/ingredients.dart` | Riverpod providers (`databaseProvider`, `ingredientRepositoryProvider`, `ingredientListProvider`, `ingredientByIdProvider`, `storesProvider`, `ingredientPicturesProvider.family`, `ingredientPricesProvider.family`) |
| `lib/src/models/ingredient.dart` | Domain model (macros, nutriments, `brand`, `barcode`) |
| `lib/src/models/store.dart` | Domain model for a store |
| `lib/src/models/ingredient_picture.dart` | Domain model for a picture row (`sortOrder` gallery order) |
| `lib/src/models/ingredient_price.dart` | Price observation + `costPer100gInBase()` (FX-converted via budget's `convertToBase`) |
| `lib/src/diet/screens/ingredient_list.dart` | ListView with FAB, tap → detail screen, swipe-to-archive + Undo banner |
| `lib/src/diet/screens/ingredient_form.dart` | Name + macros + nutriments + brand + barcode + mock scan tile + reorderable picture strip |
| `lib/src/diet/screens/ingredient_detail_screen.dart` | Read-mostly detail: chips, macro card, picture gallery + full-screen viewer, prices section (latest per store + history + price sheet), manage-stores entry |
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

## Archive semantics

- Archiving hides the ingredient from the list **and** the meal-form picker — the picker reads `ingredientListProvider` (no separate query), so the repo-level `getAll` filter covers every consumer.
- Past meals keep rendering archived ingredient names/macros: `meal_repository._getItemsForMeal` joins **all** ingredient rows (no `is_archived` filter) — intentionally untouched.
- No restore surface beyond the immediate Undo top banner (user decision). Undo is ephemeral — a restart during the window loses it (accepted).

## Nutriments (ingredient-only)

Sodium (mg), fiber (g), sugar (g) are **optional per-100g values on the ingredient only** — they are not propagated to `meal_ingredients` or meal breakdowns. `Ingredient.copyWith` uses a sentinel pattern so an explicit `null` clears a value on edit (the same pattern covers `brand`/`barcode`).

## Wiring

The Diet tab (`lib/src/app/tabs/diet_tab.dart`) renders `IngredientListScreen` directly; navigation between list/detail/form/store-manager is plain `Navigator.push(MaterialPageRoute(...))`. The app is wrapped in `ProviderScope` in `lib/src/app/app.dart`.

See also: [overview.md](../overview.md), [architecture.md](../architecture.md), [database/schema.md](../database/schema.md)
