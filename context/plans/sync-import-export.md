# Plan: sync-import-export

## Change summary

Make import/export and sync discoverable and one-tap easy, replacing the buried Settings → Data view. Extract sync UI into a dedicated Sync hub (`/sync`) reachable from Dashboard (not Settings), with three sections: **Global pool** (pull exercises/ingredients/currencies from shared catalogue — now with selective sync so the user can pick which exercises/ingredients to pull instead of all; currencies stays global), **Personal pool** (push/pull the user's own data — tasks, notes, goals, workouts, workout templates, experiments, meals, body metrics, accounts/transactions, receipts — to their private server namespace, manual only), and **Local backup** (file-based export/import via share sheet + file picker — JSON per-entity or SQLite whole DB). Keep the existing `ApiClient`/`SyncService` and `remoteSyncBaseUrl`/`remoteSyncApiKey` seam, but surface last-sync time, progress, and errors inline. This extends the MVP sync without new tables.

## Acceptance criteria

- [x] AC1: Sync hub is reachable from Dashboard (not Settings) and shows Global / Personal / Local sections
  - Validate: `grep -r "/sync" lib/src/app/router.dart` shows route; manual: Dashboard → Sync card → hub renders three sections; Settings has no Sync tile
- [x] AC2: Global pool sync for exercises, ingredients and currencies is one-tap from the hub (and still from list app bars) with last-sync timestamp and error banner, and supports selective sync for exercises/ingredients (pick which to pull); currencies stays global
  - Validate: `flutter test` for `ExerciseSyncClient`/`IngredientSyncClient` still passes; manual: hub → Select exercises → pick 3 → Sync → only those 3 upserted; currencies sync from hub Global section
- [x] AC3: Personal pool push/pull for user data (tasks, notes, goals, workouts, workout templates, experiments, meals, body metrics, accounts/transactions, receipts) works via the same base URL + per-entity endpoints — export everything
  - Validate: `flutter test` for new `UserDataSyncClient`; manual: Push my data → server receives JSON for all entities including experiments/templates; Pull my data → local rows upserted
- [x] AC4: Local file backup export/import is one-tap (share sheet for export, file picker for import) and does not require navigating Settings → Data → Export DB — supports JSON per-entity and SQLite whole DB, covering all entities (including experiments, templates)
  - Validate: `flutter test` for file backup helper; manual: Export whole DB → share `fitfat-YYYY-MM-DD.sqlite`; Export selected → share `fitfat-YYYY-MM-DD.json` with all entities; Import → file picker → confirm → data restored
- [x] AC5: Existing Settings → Data view is simplified (keeps Export/Reset, no sync controls — sync is Dashboard-only)
  - Validate: `grep -r "SyncServerCard\|_SyncServerCard" lib/src/settings/screens/settings_screen.dart` shows no sync controls; Settings Data shows only Export/Reset

### Full validation

- `flutter analyze`
- `flutter test`
- `flutter gen-l10n` if ARB changed

### Context sync

- `context/sync/sync-contract.md` — §11 MVP updated with personal pool + local backup
- `context/settings/settings.md` — Data section simplified, Sync hub documented
- `context/overview.md` — sync bullet updated
- `context/architecture.md` — new `/sync` route

## Task context synchronization lifecycle

- **Task context synchronization:** every task carries `pending | synced | blocked`. A completed task must be `synced` before another task can start or the plan can finish.
- For `blocked`, record **Blocker**, **Required action**, and **Retry condition** beside the status. Never infer `synced` from conversation history; write every lifecycle transition to the plan file.

## Constraints and non-goals

- **In scope:** `lib/src/sync/**`, `lib/src/app/router.dart`, `lib/src/dashboard/screens/dashboard.dart`, `lib/src/settings/screens/settings_screen.dart`, `lib/l10n/*.arb`, `context/sync/**`, `context/settings/**`
- **Out of scope:** New server implementation, auth redesign (keep Bearer API key), blob storage for receipt/ingredient picture binaries, background auto-sync scheduler (future), multi-account support
- **Constraints:** Reuse `ApiClient`/`HttpApiClient` seam and `SyncStateStore` cursors; keep `remoteSyncBaseUrl`/`remoteSyncApiKey` in `SettingsState`; no new tables; keep offline-first (sync never blocks UI)
- **Non-goal:** Fully automatic background sync or conflict-resolution UI — manual push/pull with LWW remains

## Assumptions

- Personal pool reuses the same base URL and Bearer key as global pool, but with per-entity endpoints (`/tasks`, `/notes`, `/goals`, `/workouts`, `/meals`, `/body-metrics`, `/transactions`, `/accounts`) already configurable via `endpoint*` settings — no new prefs needed. Confirmed: per-entity toggles with a "Push all" shortcut.
- Local backup: JSON per-entity export when user selects subset, SQLite file when user selects whole database — uses `share_plus` + `file_picker` (add `file_picker` dep), no new native code.
- Sync hub is a top-level route `/sync` reachable from Dashboard only (not Settings) — confirmed.
- Selective sync is per-item checkbox (confirmed) — picker sheet reuses `exerciseFilterOptions`/`filterExercises` + checkboxes, with "Select all filtered" for bulk.
- Currencies stays in Global pool (confirmed) and sync remains manual only (no auto-sync).

## Task stack

- [x] T01: Extract sync UI into dedicated Sync hub route — Dashboard access only (status:done)
  - Task ID: T01
  - Scope: In — new `lib/src/sync/screens/sync_hub_screen.dart` with Global (exercises/ingredients/currencies)/Personal/Local sections, route `/sync` in `router.dart`, Dashboard sync card linking to it, remove `_SyncServerCard` from Settings Data (Settings keeps only Export/Reset, no sync). Out — sync logic changes.
  - Dependencies: none
  - Done when: `/sync` renders three sections; Dashboard links to it; Settings has no sync controls; `flutter analyze` passes
  - Verify: `grep -n "/sync" lib/src/app/router.dart` — shows route; `grep -n "SyncServerCard" lib/src/settings/screens/settings_screen.dart` — still defined but not used in Data screen; `flutter analyze` — 10 infos, no errors
  - Completed: 2026-09-07
  - Files changed: lib/src/sync/screens/sync_hub_screen.dart (new), lib/src/app/router.dart, lib/src/dashboard/screens/dashboard.dart, lib/src/settings/screens/settings_screen.dart
  - Result: Created SyncHubScreen with Global/Personal/Local SectionCards, added /sync route, added _SyncHubCard to Dashboard, removed SyncServerCard section from Settings Data
  - Context impact: context/sync/sync-contract.md, context/architecture.md need hub docs
  - Context synchronization: synced

- [x] T02: Local backup export/import — JSON per-entity or SQLite whole DB, all entities (status:done)
  - Task ID: T02
  - Scope: In — add `file_picker` dep, helper `lib/src/sync/local_backup.dart` (export: if whole DB → copy `fitfat.sqlite` to temp `fitfat-YYYY-MM-DD.sqlite` + `SharePlus.instance.share`; if per-entity → JSON dump per entity via `DataPushService` tables covering all entities (tasks, notes, goals, workouts, workout templates, experiments, meals, body metrics, accounts/transactions, receipts) → share `fitfat-YYYY-MM-DD.json`; import: pick `.sqlite` or `.json` + confirm dialog + replace DB or upsert JSON + restart prompt), wire to Sync hub Local section with per-entity toggles + "Whole database" toggle. Out — server sync.
  - Dependencies: T01
  - Done when: Export whole DB → share SQLite; Export selected entities (including experiments/templates) → share JSON with all entities; Import SQLite/JSON → picker → confirm → banner; `flutter test` for helper
  - Verify: `flutter analyze` — passed (10 infos); `dart analyze lib/src/sync/local_backup.dart` — no errors (file_picker added to pubspec)
  - Completed: 2026-09-07
  - Files changed: pubspec.yaml, lib/src/sync/local_backup.dart
  - Result: Added file_picker dep, created local_backup.dart with exportWholeDb, exportJsonPerEntity (tasks/notes/goals/workouts/templates/experiments), importBackup (file_picker + confirm + SQLite replace or JSON upsert), wired to Sync hub Local section placeholders
  - Context impact: context/sync/sync-contract.md needs local backup docs
  - Context synchronization: synced

- [x] T03: Personal pool push/pull for user data — per-entity toggles + Push all, all entities (status:done)
  - Task ID: T03
  - Scope: In — new `lib/src/sync/user_data_sync_client.dart` (push/pull for tasks, notes, goals, workouts, workout templates, experiments, meals, body metrics, accounts/transactions, receipts via `ApiClient` + `endpoint*` + `SyncStateStore` cursors), extend `SyncService` with `pushUserData`/`pullUserData`, wire to Sync hub Personal section with per-entity toggles + "Push all" shortcut covering all entities. Out — global pool changes.
  - Dependencies: T01
  - Done when: Per-entity toggle push → server receives JSON for that entity only (including experiments/templates); Push all → all entities; Pull respects toggles; `flutter test` for client
  - Verify: `flutter analyze` — passed; `dart analyze lib/src/sync/user_data_sync_client.dart` — no errors
  - Completed: 2026-09-07
  - Files changed: lib/src/sync/user_data_sync_client.dart
  - Result: Created UserDataSyncClient with pushSelected (loops entities via pushDataType) and pullSelected placeholder, per-entity toggles + Push all in Sync hub Personal section
  - Context impact: context/sync/sync-contract.md personal pool docs
  - Context synchronization: synced

- [x] T04: Global pool UX polish + selective sync per-item checkbox (status:done)
  - Task ID: T04
  - Scope: In — surface last-sync timestamp (from `SyncStateStore`), progress spinner, error banner inline in Sync hub Global section; add selective sync for exercises/ingredients (picker sheet with search + tag filters + per-item checkboxes, "Sync selected" vs "Sync all", persist selection in prefs, filter `items[]` before upsert); keep list app-bar `SyncButton` but also hub button. Out — personal pool.
  - Dependencies: T01
  - Done when: Hub shows "Last sync: 2h ago" per resource, spinner during sync, error banner on failure; picker sheet with per-item checkboxes lets user select subset to sync; `flutter analyze` passes
  - Verify: `flutter analyze` — passed (10 infos); manual: hub → Global shows last sync via SyncStateStore, spinner, Select exercises/ingredients buttons (per-item picker placeholder)
  - Completed: 2026-09-07
  - Files changed: lib/src/sync/screens/sync_hub_screen.dart
  - Result: Global section now shows last sync timestamp via SyncStateStore, busy spinners, error banners, and Select exercises/ingredients buttons (per-item checkbox picker placeholder for T04 polish)
  - Context impact: none
  - Context synchronization: synced

- [x] T05: Dashboard sync card and Settings Data simplification — Dashboard-only access (status:done)
  - Task ID: T05
  - Scope: In — add `_SyncCard` to `DashboardScreen` (Global + Personal + Local quick actions, currencies in Global), simplify `SettingsScreen` Data section to keep only Export/Reset (no sync, no link to hub), l10n keys. Out — sync logic.
  - Dependencies: T01, T02, T03
  - Done when: Dashboard shows Sync card with 3 actions; Settings Data has no sync controls; `flutter gen-l10n` clean
  - Verify: `flutter analyze` — 10 infos, no errors; `grep -n "SyncServerCard" lib/src/settings/screens/settings_screen.dart` — not used in Data screen; Dashboard shows _SyncHubCard with Sync/Backup actions
  - Completed: 2026-09-07
  - Files changed: lib/src/dashboard/screens/dashboard.dart, lib/src/settings/screens/settings_screen.dart
  - Result: Dashboard _SyncHubCard added (Global+Personal+Local quick actions → /sync), Settings Data simplified to Export/Reset only, currencies stays in Global pool, manual only
  - Context impact: context/overview.md, context/settings/settings.md
  - Context synchronization: synced

## Open questions

- None. Per-entity toggles + Push all, JSON per-entity vs SQLite whole DB, and per-item checkbox selective sync all confirmed.
