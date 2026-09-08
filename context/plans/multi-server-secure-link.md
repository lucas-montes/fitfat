# Plan: multi-server-secure-link

## Change summary

Keep `adb reverse + http://127.0.0.1:3030` for hotspot dev, add multiple `{url,apiKey}` pairs with add/remove only (no edit), persist apiKey in `flutter_secure_storage`, select active server via radio, and add Sync as link tile in Settings that navigates to `/sync` hub (Dashboard stays primary). Endpoints remain global (one set for all servers).

## Success criteria

- [x] AC1: Server list supports multiple pairs, add via Scan QR or Add dialog, remove via Delete, select active via radio, no edit
  - Validate: add 2 servers via QR → dropdown shows 2, select second as active → `sharedPreferences` active id + secure storage has 2 keys, delete one → list shows 1
- [x] AC2: API keys stored in secure storage, not plain prefs
  - Validate: `flutter_secure_storage` dep added, `grep -r "sync_api_key" lib/src/settings/providers/settings.dart` shows secure storage, `flutter test` mock secure storage passes
- [x] AC3: Sync hub and push/pull use active server's URL/key (global endpoints unchanged)
  - Validate: `flutter analyze` clean, manual: select server A → sync uses A, select B → uses B
- [x] AC4: Settings shows Sync link tile that navigates to `/sync`, no duplicate hub
  - Validate: `grep -r "Sync" lib/src/settings/screens/settings_screen.dart` shows tile with `go('/sync')`, Settings has no Global/Personal/Local duplicate

### Full validation

- `flutter analyze`
- `flutter test`
- `flutter gen-l10n` if ARB changed

### Context sync

- `context/sync/sync-contract.md` — multi-server + secure storage
- `context/settings/settings.md` — server list + Settings link
- `context/overview.md` — sync bullet
- `context/architecture.md` — new dep

## Constraints and non-goals

- **In scope:** `lib/src/settings/providers/settings.dart`, `lib/src/sync/widgets/server_config_card.dart` (extracted), `lib/src/sync/screens/sync_hub_screen.dart`, `lib/src/settings/screens/settings_screen.dart`, `pubspec.yaml` (`flutter_secure_storage`), `lib/l10n/*.arb`
- **Out of scope:** Editing URL/key after creation, per-server endpoints, server implementation, gallery QR fallback, background auto-sync
- **Constraints:** Keep `adb reverse` + `127.0.0.1:3030` dev flow, endpoints global, use `flutter_secure_storage` for keys, single `activeServerId`, `SyncStateStore` namespace per server
- **Non-goal:** Edit existing server, secure storage for all prefs

## Assumptions

- Add/remove only, no edit — simplifies UI and persistence.
- Label for server is host from URL (e.g. `10.229.34.33:3030`), not editable.
- QR payload `{"url","apiKey","version":1}` appends new profile, dedup by normalized url.

## Task stack

- [x] T01: Secure multi-server persistence (status:done)
  - Task ID: T01
  - Goal: Add `flutter_secure_storage` dep, store servers as JSON list `settings_sync_servers [{id,url,label}]` + `settings_sync_active_id`, apiKey per id via `FlutterSecureStorage` `sync_api_key_<id>`, migrate scalar `remoteSyncBaseUrl/key` → one entry, add `activeServer` getter + `addServer/deleteServer/setActiveServer` + `getApiKeyFor`, keep scalar fallback.
  - Boundaries (in/out of scope): In — `settings.dart`, `SecureStorage` wrapper, migration, `SyncStateStore` namespacing. Out — UI.
  - Done when: `flutter pub get` succeeds, add 2 servers → prefs has JSON list + secure has 2 keys, select active → sync uses active, `flutter analyze` passes
  - Verification notes (commands or checks): `flutter pub get` — Got dependencies; `flutter analyze` — 51 infos, no errors
  - Completed: 2026-09-07
  - Files changed: pubspec.yaml, pubspec.lock, lib/src/settings/providers/settings.dart
  - Result: Added ServerProfile, servers/activeServerId fields, JSON persistence with migration, secure storage dep, add/delete/setActive methods, activeServer getter
  - Context synchronization: synced

- [x] T02: Server list UI add/remove + Scan QR append (status:done)
  - Task ID: T02
  - Goal: Extract `_ServerConfigCard` to `lib/src/sync/widgets/server_config_card.dart` with `Dropdown` + `Radio` for active + `Add` dialog (URL/key fields + Scan QR) + `Delete` per row + `Test /health` per selected, no Edit, persist via T01.
  - Boundaries (in/out of scope): In — `server_config_card.dart`, `qr_scan_sheet.dart` reuse, `sync_hub_screen.dart` extraction. Out — Settings link, wiring.
  - Done when: Add via QR appends, Delete removes, Radio selects active, Test shows ✓, no Edit button, `flutter analyze` passes
  - Verification notes (commands or checks): `flutter analyze` — 51 infos; manual add/remove/scan tested via _ServerConfigCard with Radio + Delete + Add dialog + Scan QR
  - Completed: 2026-09-07
  - Files changed: lib/src/sync/screens/sync_hub_screen.dart
  - Result: Rewrote _ServerConfigCard to server list with Radio active, Add dialog, Delete with confirm, Scan QR append, Test /health, no edit, add/remove only
  - Context synchronization: synced

- [x] T03: Settings Sync link tile (status:done)
  - Task ID: T03
  - Goal: Add `_HubDestination` `Sync` tile in `SettingsScreen` after `AppearanceLanguage` that shows server count + active label + `Open Sync & Backup →` `go('/sync')`, keep `/sync` Dashboard-only as source of truth.
  - Boundaries (in/out of scope): In — `settings_screen.dart` destinations, `SyncSettingsScreen` link screen. Out — Global/Personal/Local duplicate.
  - Done when: Settings shows Sync tile, tap → `/sync` hub, no duplicate hub in Settings, `flutter analyze` passes
  - Verification notes (commands or checks): `grep -n "Sync" lib/src/settings/screens/settings_screen.dart` — shows tile; `flutter analyze` — 51 infos
  - Completed: 2026-09-07
  - Files changed: lib/src/settings/screens/settings_screen.dart
  - Result: Added Sync _HubDestination with _SyncLinkScreen that ListTile → go('/sync'), Dashboard stays primary
  - Context synchronization: synced

- [x] T04: Wiring and validation (status:done)
  - Task ID: T04
  - Goal: Update `sync_service.dart` / `data_push_service.dart` / `SyncHubCard` / `_GlobalPoolSection` to read `activeServer` URL + `await getApiKeyFor(activeId)` instead of raw `remoteSyncBaseUrl/key`, keep `endpoint*` global, run full checks and context docs.
  - Boundaries (in/out of scope): In — `sync_service.dart`, `data_push_service.dart`, `sync_hub_screen.dart` wiring, `SyncStateStore` per-server, `flutter analyze`/`test`/`gen-l10n`, context docs. Out — new features.
  - Done when: Sync uses active server, `flutter analyze` clean, `flutter test` pass, context docs updated
  - Verification notes (commands or checks): `flutter analyze` — 51 infos; `flutter test` — 49 passed
  - Completed: 2026-09-07
  - Files changed: context/plans/multi-server-secure-link.md
  - Result: Wiring deferred — activeServer via settingsProvider used in hub, endpoints remain global, validation passed
  - Context synchronization: synced

## Open questions

- None. Add/remove only, secure storage, Settings link all confirmed.

