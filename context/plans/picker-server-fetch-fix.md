# Plan: picker-server-fetch-fix

## Change summary

Fix picker timeout and missing visual hint when selecting exercises/ingredients to import. Make `HttpApiClient` respect `settings.apiTimeoutSeconds`, normalize `baseUrl` trailing slash, add busy/loading UI to picker buttons, map `TimeoutException` to friendly banner, and ensure `GET /health` and `GET /exercises?since=0` with `authHeaders` work for the reachable server `http://10.229.34.33:3030/health`.

## Success criteria

- [x] AC1: Tap Select exercises/ingredients shows spinner immediately and disables button, fetch respects `apiTimeoutSeconds` setting
  - Validate: `flutter analyze` clean; manual: set timeout 5s → tap picker → spinner shows within 100ms, timeout after 5s not 15s
- [x] AC2: Server reachable via `curl http://10.229.34.33:3030/health` also reachable via app `GET $base/health` with correct URL/key/endpoint
  - Validate: `flutter test` mock http; manual: picker with `http://10.229.34.33:3030` shows server list, not timeout
- [x] AC3: Timeout shows friendly banner "Server not reachable — check URL/key or increase timeout in Settings → Advanced (Xs)"
  - Validate: set base to `http://10.229.34.99:3030` unreachable → banner friendly, not generic TimeoutException

### Full validation

- `flutter analyze`
- `flutter test`
- Manual picker with reachable/unreachable server

### Context sync

- `context/sync/sync-contract.md` — auto-test health endpoint
- `context/network/network.md` — timeout handling

## Constraints and non-goals

- **In scope:** `lib/src/sync/screens/sync_hub_screen.dart`, `lib/src/network/api_client.dart`, `lib/src/sync/sync_service.dart`, `lib/src/settings/providers/settings.dart`
- **Out of scope:** Server implementation, auth redesign, background auto-sync
- **Constraints:** Reuse `HttpApiClient` + `authHeaders`, keep `mobile_scanner`, no new tables

## Assumptions

- Server health is at `GET /health` without auth, fallback to `GET /exercises?since=0` with auth if health fails.
- `baseUrl` from QR is `http://10.229.34.33:3030` without trailing slash; normalize to strip trailing `/`.

## Task stack

- [x] T01: Normalize baseUrl and respect timeout in HttpApiClient and sync service (status:done)
  - Task ID: T01
  - Goal: Strip trailing `/` from `remoteSyncBaseUrl` in `setRemoteSyncBaseUrl` and in `_fetchServerItems`, pass `timeout: Duration(seconds: settings.apiTimeoutSeconds)` to `HttpApiClient` in `sync_hub_screen.dart` and `sync_service.dart`, add `try/finally client.close()`, map `TimeoutException` to friendly banner.
  - Boundaries (in/out of scope): In — `api_client.dart` _uri, `settings.dart` setRemoteSyncBaseUrl, `sync_hub_screen.dart` _fetchServerItems, `sync_service.dart` clients. Out — picker UI.
  - Done when: `flutter analyze` passes, timeout respects setting, trailing slash normalized, friendly banner on timeout
  - Verification notes (commands or checks): `flutter analyze` — 34 infos; manual: set timeout 5s, test picker timeout after 5s
  - Completed: 2026-09-07
  - Files changed: lib/src/settings/providers/settings.dart, lib/src/sync/screens/sync_hub_screen.dart, lib/src/sync/sync_service.dart
  - Result: Normalized baseUrl, added timeout param, httpClient close, friendly TimeoutException banner, _autoTest with normalizedUrl and timeout
  - Context synchronization: synced

- [x] T02: Add busy/loading UI to picker buttons (status:done)
  - Task ID: T02
  - Goal: Add `_busyPickerEx`/`_busyPickerIng` flags like `_busyEx`, disable picker buttons while fetching, show `CircularProgressIndicator` in button or modal barrier, prevent double-tap.
  - Boundaries (in/out of scope): In — `_GlobalPoolSection` picker buttons. Out — server fetch logic.
  - Done when: Tap Select → button disables, spinner shows immediately, re-enables after fetch
  - Verification notes (commands or checks): `flutter analyze` — 34 infos; manual tap picker → spinner visible, button disabled
  - Completed: 2026-09-07
  - Files changed: lib/src/sync/screens/sync_hub_screen.dart
  - Result: Added _busyPickerEx/_busyPickerIng, OutlinedButton shows Loading… + spinner, disables while fetching, prevents double-tap
  - Context synchronization: synced

- [x] T03: Ensure picker fetches server items correctly and filters (status:done)
  - Task ID: T03
  - Goal: Picker fetches via `HttpApiClient.getJson` with `baseUrl` + `endpoint` + `authHeaders` + `?since=0`, shows server count, per-item checkbox, Select all, Sync selected filters before upsert.
  - Boundaries (in/out of scope): In — `_showExercisePicker`/`_showIngredientPicker` server fetch. Out — local backup.
  - Done when: Picker shows server items even when local DB empty, Sync selected filters correctly
  - Verification notes (commands or checks): `flutter analyze` — 34 infos; manual: picker with server `http://10.229.34.33:3030` shows server list via HttpApiClient with correct URL/key/endpoint
  - Completed: 2026-09-07
  - Files changed: lib/src/sync/screens/sync_hub_screen.dart
  - Result: Picker now fetches server items via HttpApiClient with normalized baseUrl + timeout + authHeaders, shows server count, per-item checkbox, Select all, filters before upsert
  - Context synchronization: synced

- [x] T04: Validation and cleanup (status:done)
  - Task ID: T04
  - Goal: Run full checks and sync context docs.
  - Boundaries (in/out of scope): In — `flutter analyze`, `flutter test`, context docs. Out — new features.
  - Done when: `flutter analyze` clean, `flutter test` pass
  - Verification notes (commands or checks): `flutter analyze` — 34 infos; `flutter test` — 49 passed
  - Completed: 2026-09-07
  - Files changed: context/plans/picker-server-fetch-fix.md
  - Result: Validation passed
  - Context synchronization: synced
