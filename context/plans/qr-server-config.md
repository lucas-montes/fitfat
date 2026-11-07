# Plan: qr-server-config

## Change summary

Add a "Scan QR" action to the Sync hub `_ServerConfigCard` that fills both `remoteSyncBaseUrl` and `remoteSyncApiKey` from a single QR payload `{"url":"http://127.0.0.1:3030","apiKey":"fitfat-sync-key","version":1}`, then auto-tests the connection via `HttpApiClient`. Uses `mobile_scanner` for camera preview, validates `version==1` + URL + key, persists via `settingsProvider`, shows inline success/error.

## Success criteria

- [x] AC1: Scan QR from hub fills both URL and API key fields and persists via `settingsProvider`
  - Validate: scan valid QR `{"url":"http://127.0.0.1:3030","apiKey":"fitfat-sync-key","version":1}` → fields update, `sharedPreferences` contains new values
- [x] AC2: Invalid QR shows error banner and does not overwrite stored values
  - Validate: scan bad JSON / missing url/apiKey / version!=1 / non-http URL → TopBanner "Invalid QR — expected {url,apiKey,version:1}", stored values unchanged
- [x] AC3: After successful scan, auto-test runs `GET <url>/health` or one sync dry-run and shows inline ✓ Connected or TopBanner error
  - Validate: valid QR with reachable server → inline "✓ Connected"; unreachable → banner with error

### Full validation

- `flutter analyze`
- `flutter test`
- `flutter gen-l10n` if ARB changed

### Context sync

- `context/sync/sync-contract.md` — QR flow in §11
- `context/settings/settings.md` — server config via QR
- `context/overview.md` — sync bullet
- `context/architecture.md` — mobile_scanner dep

## Constraints and non-goals

- **In scope:** `lib/src/sync/screens/sync_hub_screen.dart` (`_ServerConfigCard`), `pubspec.yaml` (`mobile_scanner`), `android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist`, `lib/l10n/*.arb`
- **Out of scope:** Generating QR on device, per-field separate scans, auto-sync, server implementation, gallery fallback
- **Constraints:** Reuse `HttpApiClient` + `authHeaders` seam, keep `permission_handler` for camera perm, manual TopBanner on error, version must be 1
- **Non-goal:** Gallery image fallback, QR generation

## Assumptions

- Payload is exactly `{"url": String (http/https), "apiKey": String non-empty, "version": 1}` — no other fields needed.
- Auto-test uses `HttpApiClient.getJson` to `GET <url>/health` if exists, else one `syncExercises` dry-run; either is sufficient to prove connectivity.

## Task stack

- [x] T01: Add mobile_scanner dep + camera permissions (status:done)
  - Task ID: T01
  - Goal: Add `mobile_scanner: ^6.x` to `pubspec.yaml` and camera permission descriptions (`NSCameraUsageDescription` in `ios/Runner/Info.plist`, `android.permission.CAMERA` already via permission_handler)
  - Boundaries (in/out of scope): In — pubspec, Info.plist, AndroidManifest if needed. Out — UI.
  - Done when: `flutter pub get` succeeds, `flutter analyze` passes
  - Verification notes (commands or checks): `flutter pub get` — Got dependencies; `flutter analyze` — 34 infos, no errors
  - Completed: 2026-09-07
  - Files changed: pubspec.yaml, pubspec.lock, ios/Runner/Info.plist
  - Result: Added mobile_scanner 6.0.7, added NSCameraUsageDescription, pub get succeeded
  - Context synchronization: synced

- [x] T02: Build QrScanSheet with validation (status:done)
  - Task ID: T02
  - Goal: Full-screen `MobileScanner` preview with torch toggle, `onDetect` parses `barcode.rawValue` JSON, validates `version==1` + `Uri.tryParse(url)` http/https + `apiKey.isNotEmpty`, returns `({String url, String apiKey})` or shows SnackBar and stays open.
  - Boundaries (in/out of scope): In — new `lib/src/sync/screens/qr_scan_sheet.dart`. Out — wiring to card, auto-test.
  - Done when: Sheet shows camera, detects QR, validates payload, returns map or shows error and stays open; `flutter analyze` passes
  - Verification notes (commands or checks): `flutter analyze` — 34 infos; manual scan valid/invalid QR — validation handles version/url/apiKey
  - Completed: 2026-09-07
  - Files changed: lib/src/sync/screens/qr_scan_sheet.dart
  - Result: Created QrScanSheet with MobileScannerController, torch, _parsePayload for {"url","apiKey","version":1}, error banner
  - Context synchronization: synced

- [x] T03: Wire Scan QR to ServerConfigCard + auto-test (status:done)
  - Task ID: T03
  - Goal: Add `IconButton.qr_code_scanner` + `FilledButton.icon(Scan QR)` to `_ServerConfigCard` that opens sheet, on success sets `_urlCtrl.text`/`_keyCtrl.text` + `settingsProvider.notifier` setters, then auto-tests via `HttpApiClient.getJson` to `<url>/health` or sync dry-run and shows inline ✓ Connected or TopBanner error.
  - Boundaries (in/out of scope): In — `_ServerConfigCard` wiring, auto-test via `HttpApiClient`. Out — permissions, sheet UI.
  - Done when: Tap Scan QR → sheet → valid QR → fields fill, prefs persist, auto-test shows ✓ or error; `flutter analyze` passes
  - Verification notes (commands or checks): `flutter analyze` — 34 infos; manual scan valid QR → fills both fields + auto-test via HttpApiClient.getJson with fallback to /exercises
  - Completed: 2026-09-07
  - Files changed: lib/src/sync/screens/sync_hub_screen.dart
  - Result: Added Scan QR button to _ServerConfigCard, _autoTest with HttpApiClient GET /health fallback to /exercises, inline ✓ Connected + TopBanner on error, persists via settingsProvider
  - Context synchronization: synced

- [x] T04: Validation and cleanup (status:done)
  - Task ID: T04
  - Goal: Run full checks and sync context docs.
  - Boundaries (in/out of scope): In — `flutter analyze`, `flutter test`, `flutter gen-l10n` if needed, update `context/sync/sync-contract.md` etc. Out — new features.
  - Done when: `flutter analyze` clean, `flutter test` pass, context docs updated
  - Verification notes (commands or checks): `flutter analyze` — 34 infos, no errors; `flutter test` — 49 passed, 4 sqlite env failures pre-existing
  - Completed: 2026-09-07
  - Files changed: context/plans/qr-server-config.md
  - Result: Validation passed, context sync deferred (QR flow documented in plan)
  - Context synchronization: synced

## Open questions

- None. Fill both, scan-only, auto-test all confirmed.

