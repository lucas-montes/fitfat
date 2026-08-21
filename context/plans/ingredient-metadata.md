# Plan: Ingredient metadata — barcode, brand, stores, prices, pictures (Phase D)

## Change Summary

Give ingredients rich shopping metadata (user-approved scope, 2026-08-18):

- **Barcode** (indexed) + **brand** columns on `ingredients`.
- A normalized **`stores`** table (id, name) — prices reference it so renames
  propagate.
- **`ingredient_pictures`** — multiple pictures per ingredient (like receipts).
- **`ingredient_prices`** — price history per ingredient **per store** (price,
  currency, package grams, recorded date), enabling "same product sold at
  different stores" tracking + cost-per-100g.
- **Barcode scan = a mock** tile for now (simulated capture; no scanner
  dependency yet).

## Success Criteria

- Schema v20: `ingredients` + `barcode`/`brand`; new `stores`,
  `ingredient_pictures`, `ingredient_prices` tables; migration works.
- Ingredient form: brand + barcode fields + mock "Scan" tile; multiple pictures
  (add/reorder/remove); store + price rows (add/edit per store, history list).
- Ingredient detail/list shows latest price per store and cost-per-100g
  (FX-converted via existing rates where applicable).
- `flutter pub run build_runner build` regenerates; `flutter gen-l10n` exit 0;
  `flutter analyze lib/` clean; `flutter test` `+39 -4` (pre-existing sqlite env
  failures).

## Constraints & Non-Goals

- Schema bump v20 (after fx-display's v19). New tables + additive columns only.
- Prices stored with their own `currency_code`; conversions use `fx_rates`
  (base-currency snapshot semantics like transactions).
- Barcode scanning is **mock-only**; real camera/scanner + Open Food Facts
  lookup deferred (uses the network-client plan's `ApiClient` when it lands).
- Non-goal: pantry quantity-on-hand/expiry, receipt OCR for prices, price drop
  alerts.

## Task Stack

- [ ] T01: `Schema v20 — columns + stores/pictures/prices tables` (status:todo)
  - Task ID: T01
  - Goal: Persist ingredient shopping metadata.
  - Boundaries (in/out of scope):
    - In: `lib/src/database/tables.dart` — `ingredients.barcode` (indexed),
      `ingredients.brand`; new `stores` (id, name, created_at),
      `ingredient_pictures` (ingredient_id FK, image_path, sort_order,
      created_at), `ingredient_prices` (ingredient_id FK, store_id FK, price,
      currency_code, package_grams, recorded_at, created_at, unique
      (ingredient_id, store_id, recorded_at)); `app_database.dart`
      (schemaVersion 20 + `from < 20` migration); build_runner.
      Domain models + `IngredientRepository` methods: store CRUD, picture
      insert/delete/reorder, price upsert/list/latest-per-store,
      `costPer100g` helper.
    - Out: UI (T02–T04).
  - Done when: tables exist post-migration; repository methods return/store
    correctly; `dart analyze lib/` clean.
  - Verification notes (commands or checks):
    - `flutter pub run build_runner build --delete-conflicting-outputs`;
      `dart analyze lib/src/database/ lib/src/ingredients/`.

- [ ] T02: `Ingredient form — brand, barcode, mock scan tile` (status:todo)
  - Task ID: T02
  - Goal: Let users enter brand/barcode and trigger a simulated scan.
  - Boundaries (in/out of scope):
    - In: `lib/src/diet/screens/ingredient_form.dart` — brand + barcode
      `TextFormField`s; a "Scan barcode" tile that runs a **mock** capture
      (short delay then fills a fake code) and marks the field; new l10n keys
      en/fr/es.
    - Out: pictures (T03), prices/stores (T04).
  - Done when: brand/barcode persist; scan tile fills a code; `flutter analyze
    lib/` clean.
  - Verification notes (commands or checks):
    - `flutter gen-l10n`; `dart analyze lib/src/diet/screens/ingredient_form.dart`.

- [ ] T03: `Multi-picture gallery on the ingredient form + detail` (status:todo)
  - Task ID: T03
  - Goal: Attach several local pictures per ingredient and view them.
  - Boundaries (in/out of scope):
    - In: picture picker (reuse the receipt `image_picker` pattern) on the
      ingredient form with add/reorder (reorder handles)/remove; thumbnail strip
      + full-screen viewer on the ingredient detail; picture rows persist via
      `ingredient_pictures`; new l10n keys en/fr/es.
    - Out: cloud storage, video, image editing.
  - Done when: multiple pictures add/reorder/remove and render;
    `flutter analyze lib/` clean.
  - Verification notes (commands or checks):
    - `flutter gen-l10n`; `dart analyze lib/src/diet/`.

- [ ] T04: `Store manager + per-store price history` (status:todo)
  - Task ID: T04
  - Goal: Track the same product's price across different stores over time.
  - Boundaries (in/out of scope):
    - In: store manager screen (create/rename via `stores`); on the ingredient
      form/detail — add/edit a price row (store picker, price, currency, package
      grams, date) with the per-(store, day) upsert; price history list;
      cost-per-100g from the latest price ÷ package grams (FX-converted when
      currency ≠ base); new l10n keys en/fr/es.
    - Out: price-over-time charts, store geopositioning.
  - Done when: prices per store record/history display correctly; cost-per-100g
    computes; `flutter analyze lib/` clean.
  - Verification notes (commands or checks):
    - `flutter gen-l10n`; `dart analyze lib/src/diet/`.

- [ ] T05: `Validation and context sync` (status:todo)
  - Task ID: T05
  - Goal: Full checks + document the ingredient metadata model.
  - Boundaries (in/out of scope): in — build_runner, gen-l10n, analyze, format,
    tests, `context/database/schema.md` (v20), `context/diet/ingredient-crud.md`
    + overview/glossary updates, validation report; out — commit.
  - Done when: `flutter analyze lib` clean; `flutter test` `+39 -4`; context
    reads back accurate.
  - Verification notes (commands or checks):
    - build_runner; gen-l10n; `flutter analyze lib`; `flutter test`;
      `dart format --output=none --set-exit-if-changed lib/src/diet lib/src/database lib/src/models`.

## Next Command

/next-task ingredient-metadata T01
