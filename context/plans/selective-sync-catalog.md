# Plan: selective-sync-catalog

## Change summary

The sync icons in `IngredientListScreen` and `ExerciseListScreen` currently bulk-import every available server row via `SyncService.syncIngredients` / `syncExercises`. This change keeps that bulk path but adds a fine-grained path: a minimal local catalog (`exercises: id + name`; `ingredients: id + name + barcode`) browsed through the existing shared `showSelectSheet` picker, importing only the chosen IDs into the real user tables. The `exercises` / `ingredients` tables remain the imported-data store; two new catalog tables hold the available-data index.

Client stays thin on purpose: catalog refresh runs in the background, picker hides already-imported rows and blocks when the server is unreachable, thumbnails are fetched live from the server for display (no media stored on refresh), and assets are downloaded for offline only at import time. Filtering / lightweight shapes live on the server. The duplicate hub fetch code (`_fetchServerItems`, second `GET ?since=0` + banner-only filter, dual `Map -> DisplayItem` mappers) is deleted.

## Acceptance criteria

- [ ] AC1: Tapping sync in exercise list offers bulk vs selective, selective lets the user check exactly which catalog rows to import and imports only the checked set with offline assets
  - Validate: `flutter test test/exercise_media_sync_test.dart` (10/10 passed 2026-09-13); manual device part unrun (see Validation Report)
- [ ] AC2: Tapping sync in ingredient list offers bulk vs selective, selective lets the user check exactly which rows to import and imports minimal aggregate only (image + name + metadata + barcode)
  - Validate: `flutter test` full suite blocked by env (see Validation Report); manual device part unrun
- [ ] AC3: Bulk import still imports everything and advances the cursor; selective import never advances the bulk cursor; deletions stay local only
  - Validate: `grep -r "setLastSyncedAt" lib/src/sync/sync_service.dart` shows cursor write only on bulk paths (lines 65/95/132) — passed 2026-09-13; manual prefs part unrun (see Validation Report)
- [ ] AC4: Catalog refreshes in background, picker blocks offline, duplicate hub fetch code is gone
  - Validate: `grep -r "_fetchServerItems" lib/src/sync/screens/sync_hub_screen.dart` shows 0 — passed 2026-09-13; manual background/airplane parts unrun (see Validation Report)

### Full validation

- `flutter analyze`
- `flutter test`

### Context sync

- `context/sync/sync-contract.md` — selective vs bulk semantics + catalog cache + local-only deletions
- `context/database/schema.md` — v31 catalog tables (minimal columns)
- `context/exercise/exercise-crud.md` — list sync menu
- `context/diet/ingredient-crud.md` — list sync menu

## Task context synchronization lifecycle

- **Task context synchronization:** every task carries `pending | synced | blocked`. A completed task must be `synced` before another task can start or the plan can finish.
- For `blocked`, record **Blocker**, **Required action**, and **Retry condition** beside the status. Never infer `synced` from conversation history; write every lifecycle transition to the plan file.

## Constraints and non-goals

- **In scope:** `lib/src/database/tables.dart`, `app_database.dart` (v31), catalog repositories (minimal columns + `hide-imported` search), `lib/src/sync/sync_service.dart`, `exercise_sync_client.dart`, `ingredient_sync_client.dart`, background catalog refresh, live server-image thumbnails in picker, download-on-import for offline, `lib/src/diet/screens/ingredient_list.dart`, `lib/src/exercise/screens/exercise_list.dart`, `lib/src/exercise/widgets/select_sheet.dart` reuse, `sync_hub_screen.dart` picker reuse + deletion of `_fetchServerItems` / double-fetch / dual mappers, ARB strings; server lightweight catalog + per-id selective shapes + asset URLs (`server/sync-server/src/handlers/pull.rs`, `media.rs`, `server.rs`)
- **Out of scope:** video in picker tile, server pagination, currencies selective, push flows, per-field merge
- **Constraints:** reuse `showSelectSheet` + `DisplayItem` as multi-select (search + per-item check + Select-all/Clear + confirm imports only checked set, cancel imports nothing); client thin (no catalog-side filtering logic beyond `hide-imported`); catalog refresh in background (never blocks picker open); picker blocks on unreachable with `showTopBanner`; selective never calls `setLastSyncedAt`; selective deletions local-only (ignore server `deleted[]`, send nothing); success silent + error `showTopBanner`; net code deletion in hub
- **Non-goal:** per-field merge / conflict UI

## Assumptions

- Catalog rows are minimal with no FK to user tables: `ExerciseCatalog{id, name}`, `IngredientCatalog{id, name, barcode}`.
- Server owns lightweight shapes: catalog list (`id/name`, `id/name/barcode`), per-id selective payloads (exercise full + `hasImage/hasVideo`; ingredient image + name + metadata + barcode), and stable asset URLs for live thumbnails.
- Catalog refresh never stores media; picker thumbnails are live server fetches (server must be reachable — picker blocks otherwise).
- Offline assets are written only on bulk sync / selective import.
- `SyncStateStore` per-resource cursors belong to the bulk path only.
- Picker hides rows already present in `exercises` / `ingredients`; no pre-check / badge variant.
- Selective ingredient import is minimal (no stores/prices); bulk import keeps full aggregate.

## Task stack

- [x] T01: Minimal catalog tables + hide-imported repositories (status:done)
  - Task ID: T01
  - Scope: In — `ExerciseCatalog{id, name}` + `IngredientCatalog{id, name, barcode}` drift tables, v30→v31 migration, `getAll/search/upsertAll/clear` repos plus `searchHideImported` and `toDisplayItem` (no stored image paths, no raw server `Map` in UI), drift codegen. Out — sync engine, background refresh, UI, server.
  - Dependencies: none
  - Done when: fresh install creates catalog tables, upgrade from v30 preserves user rows, repos round-trip minimal columns and `search` excludes already-imported ids.
  - Verify: codegen wrote 340 outputs incl. `$ExerciseCatalogTable`/`$IngredientCatalogTable` managers; `flutter analyze` 51 infos, 0 errors, none in new files; `flutter test test/exercise_media_sync_test.dart` 10/10 passed; catalog round-trip sqlite test blocked by env missing `libsqlite3.so` (same failure on existing `planner_repository_test.dart`), code-reviewed `upsertAll`/`searchHideImported`/migration instead.
  - Completed: 2026-09-13
  - Files changed: mobile/lib/src/database/tables.dart, mobile/lib/src/database/app_database.dart, mobile/lib/src/database/app_database.g.dart, mobile/lib/src/sync/repositories/catalog_repository.dart
  - Result: v31 with `exercise_catalog` + `ingredient_catalog` tables, `m.createTable` migration from v30, `ExerciseCatalogRepository`/`IngredientCatalogRepository` with `getAll/upsertAll/clear/searchHideImported` returning picker-ready `DisplayItem` (ingredient subtitle = barcode, no stored image paths).
  - Context impact: `context/database/schema.md` needs v31 catalog tables + version bump (still says 23/30-era); `context/sync/sync-contract.md` selective-vs-bulk catalog cache note pending T03.
  - Context synchronization: synced

- [x] T02: Server lightweight catalog + selective shapes + assets (status:done)
  - Task ID: T02
  - Scope: In — server catalog endpoints (exercises `id/name`, ingredients `id/name/barcode`), per-id selective fetch (exercise full + media flags; ingredient image + name + metadata + barcode), stable thumbnail/asset URLs with Bearer auth (`pull.rs`, `media.rs`, `server.rs`). Out — mobile UI.
  - Dependencies: T01
  - Done when: catalog endpoints return minimal rows; per-id fetch returns selective shapes; thumbnail URLs work with Bearer and 404 cleanly; existing bulk `?since=` + `deleted[]` unchanged.
  - Verify: `cargo test -p sync-server` 18/18 passed (incl. new `catalog_and_item_routes`: catalog minimal shapes, item 200s, deleted/missing 404s, catalog 401 without Bearer; pre-existing `exercise_media_not_found_and_found` covers asset 200/404/401); bulk `?since=` + `deleted[]` code untouched.
  - Completed: 2026-09-13
  - Files changed: server/sync-server/src/handlers/pull.rs, server/sync-server/src/server.rs, server/sync-server/src/lib.rs
  - Result: `GET /exercises/catalog` (`{id,name}`), `GET /ingredients/catalog` (`{id,name,barcode?}`), `GET /exercises/item/:id` (full shape + `hasImage/hasVideo`, 404 when missing/deleted), `GET /ingredients/item/:id` (minimal: full columns + `pictures`, no `prices`/`stores`, 404 when missing/deleted); exercise thumbnails stay on existing Bearer `/exercises/<id>.jpg` + `/media/:id` routes; bulk pulls unchanged.
  - Context impact: server sync contract (catalog + item routes, ingredient pictures remain metadata strings with no binary serving in V1); mobile `context/sync/sync-contract.md` selective section pending T03.
  - Context synchronization: synced

- [x] T03: Background catalog refresh + thin selective import engine (status:done)
  - Task ID: T03
  - Scope: In — `refreshExerciseCatalog` / `refreshIngredientCatalog` run in background (app start / connectivity regain, never blocking picker), populate catalog only (no user-table touch, no media store, no cursor); `importSelectedExercises(ids)` / `importSelectedIngredients(ids)` call server selective shapes → upsert + download assets for offline only at this point (exercise `jpg/mp4`, ingredient image), ingredient selective stores image/name/metadata/barcode only; ignore server `deleted[]` on selective, send nothing on local delete. Out — UI wiring, hub deletion (T04/T05).
  - Dependencies: T02
  - Done when: background refresh fills minimal catalog without touching `exercises`/`ingredients`/media/cursors; import of 2 IDs upserts exactly those rows with offline assets; bulk cursors unchanged; selective with server down returns unreachable error.
  - Verify: `flutter analyze` 0 errors (51 infos, all pre-existing style, none in new engine files); `flutter test test/exercise_media_sync_test.dart` 10/10 passed (bulk refactor via shared `importItem`/`upsertAggregate` introduces no regression); new `test/catalog_selective_sync_test.dart` compiles clean but cannot execute here (`libsqlite3.so` missing — same env failure as existing DB tests; runs in CI).
  - Completed: 2026-09-13
  - Files changed: mobile/lib/src/sync/exercise_sync_client.dart, mobile/lib/src/sync/ingredient_sync_client.dart, mobile/lib/src/sync/catalog_sync_client.dart, mobile/lib/src/sync/sync_service.dart, mobile/lib/src/app/app.dart, mobile/test/catalog_selective_sync_test.dart
  - Result: `CatalogSyncClient` (refresh catalog-only via `/catalog` endpoints with cache replace; per-id import with 404-skip, no cursor, no `deleted[]` handling); bulk loops share `importItem`/`upsertAggregate`/`parseIngredient`; `SyncService` gains refresh/import/ background `refreshSelectiveCatalogs` (silent, empty-base no-op); `_BackgroundStartup` triggers throttled (15 min) background refresh on start + resume.
  - Context impact: `context/sync/sync-contract.md` §11.5 gains client engine + background-refresh behavior; `context/exercise/exercise-crud.md` + `context/diet/ingredient-crud.md` list-menu notes pending T04/T05.
  - Context synchronization: synced

- [x] T04: Exercise list sync menu + live-image picker (status:done)
  - Task ID: T04
  - Scope: In — replace exercise AppBar `SyncButton` with Sync-all / Select-menu, Select reads catalog repo (`searchHideImported`) → `showSelectSheet` with live server thumbnails → `importSelectedExercises` → invalidate `exerciseListProvider`, block with unreachable banner when server down, ARB strings. Out — ingredients screen, hub.
  - Dependencies: T03
  - Done when: menu shows both entries; Select shows searchable multi-select (check/uncheck, Select-all/Clear, confirm), hides imported rows, shows live images without storing them, blocks offline; cancel imports nothing and only checked exercises gain offline assets.
  - Verify: `flutter analyze` 0 errors (no new-file issues; +2 infos in generated l10n only); `flutter test test/exercise_media_sync_test.dart` 10/10 passed; manual with live server pending (same as prior plans).
  - Completed: 2026-09-13
  - Files changed: mobile/lib/src/exercise/screens/exercise_list.dart, mobile/lib/src/exercise/widgets/select_sheet.dart, mobile/lib/l10n/app_en.arb, mobile/lib/l10n/app_fr.arb, mobile/lib/l10n/app_es.arb, mobile/lib/l10n/app_localizations.dart + per-locale generated files
  - Result: AppBar sync `PopupMenuButton` (Sync all = bulk + invalidate, silent on success; Select = refresh-catalog-then-pick with unreachable/nothing-new banners, hide-imported, live `Image.network` thumbnails with Bearer headers, import-checked-only + invalidate); `DisplayItem.imageHeaders` extension in shared sheet (http → network with headers, else file, else fallback).
  - Context impact: `context/exercise/exercise-crud.md` gains list sync-menu note.
  - Context synchronization: synced

- [x] T05: Ingredient list sync menu + hub keeps Select via catalog, delete hub network code (status:done)
  - Task ID: T05
  - Scope: In — same menu pattern on ingredient list (minimal import), `importSelectedIngredients`, invalidate `ingredientListProvider`, hub keeps its Select exercises / Select ingredients buttons (parity with lists, not bulk-only) pointed at catalog repos + new engine methods, delete `_fetchServerItems`, delete second `GET ?since=0` + banner-only filter block, delete dual `Map -> DisplayItem` mappers in `sync_hub_screen.dart`. Out — new widgets.
  - Dependencies: T04
  - Done when: ingredient Select shows the same searchable multi-select and imports minimal rows with offline image for checked ids only; hub retains both Select buttons and they perform the same selective import from catalog with live thumbnails and offline block; `grep -r "_fetchServerItems" lib/src/sync/screens/sync_hub_screen.dart` is empty.
  - Verify: `flutter analyze` 0 errors (`_fetchServerItems` count 0; one remaining `since: 0` is the `_autoTest` connectivity probe, not a picker fetch); `flutter test test/exercise_media_sync_test.dart` 10/10 passed; manual hub + list parity + offline block check pending live server.
  - Completed: 2026-09-13
  - Files changed: mobile/lib/src/diet/screens/ingredient_list.dart, mobile/lib/src/sync/screens/sync_hub_screen.dart, mobile/lib/l10n/app_en.arb, mobile/lib/l10n/app_fr.arb, mobile/lib/l10n/app_es.arb (+ generated l10n)
  - Result: ingredient list is a stateful sync menu (Sync all bulk + Select minimal-import with barcode subtitles, no V1 thumbnails, unreachable/nothing-new banners); hub keeps both Select buttons rewired to refresh-catalog → hide-imported → import engine with live exercise thumbnails; `_fetchServerItems`, double-fetch and banner-only blocks deleted.
  - Context impact: `context/diet/ingredient-crud.md` gains list sync-menu note.
  - Context synchronization: synced

## Open questions

None. Hub retains its Select buttons (user decision) — selective import stays available in hub + both lists.

## Validation Report

**Status:** failed  
**Date:** 2026-09-13

### Commands run

- `flutter analyze` (mobile) -> exit 0 (0 errors, 57 infos — all pre-existing style lints)
- `flutter test test/exercise_media_sync_test.dart` -> exit 0 (10/10 passed)
- `flutter test` (mobile, full suite) -> exit 1 (50 passed, 7 failed — all 7 fail loading `libsqlite3.so`, which is absent in this Nix shell)
- `cargo test -p sync-server` -> exit 0 (18/18 passed, incl. `catalog_and_item_routes`)
- `grep -r "setLastSyncedAt" lib/src/sync/sync_service.dart` -> passed (writes only at bulk paths, lines 65/95/132)
- `grep -rn "_fetchServerItems" lib/src/sync/` -> passed (0 matches)

### Success-criteria verification

- [ ] AC1: exercise selective import incl. offline assets -> automated part passed (media test 10/10); manual device part (pick 2, hide-imported, offline media) unrun — no live server/device here
- [ ] AC2: ingredient selective minimal import -> full-suite evidence blocked by env (new `catalog_selective_sync_test.dart` compiles clean per analyze but cannot execute without sqlite); manual device part unrun
- [ ] AC3: bulk cursor vs selective no-cursor, local-only deletions -> grep inspection passed; manual prefs part unrun
- [ ] AC4: background refresh, offline block, hub dedup -> grep inspection passed; manual background/airplane parts unrun

### Failed checks and follow-ups

- Full `flutter test`: 7 failures, all `Invalid argument(s): Failed to load dynamic library 'libsqlite3.so'`; evidence: 3 in pre-existing `planner_repository_test.dart`, 1 in pre-existing `note_repository_test.dart` (both fail identically without this plan's changes — confirmed pre-existing env gap), 3 in new `catalog_selective_sync_test.dart` (same cause); required: rerun the suite where sqlite is available (CI/device shell) — no code repair indicated.
- Manual live-server/device checks (AC1 pick-2 + media, AC2 pick-1 minimal, AC3 prefs unchanged, AC4 background + airplane block, hub/list parity): unrun here; required: point the app at `http://127.0.0.1:3030` and walk each AC's manual steps.
- No leftover scaffolding: `test/catalog_tmp_verify_test.dart` removed during T03; `android/build/` untracked output predates this plan.

### Residual risks

- New `catalog_selective_sync_test.dart` is compile-verified only in this env; first CI run is its first execution.
- Select-sheet live thumbnails fetch per-row `Image.network` with Bearer headers; large catalogs open many concurrent image requests (no prefetch/throttle in V1).

### Retry

After repairs, rerun:

`/validate mobile/context/plans/selective-sync-catalog.md`
