# Plan: Network client — decoupled mockable HTTP (Phase E)

## Change Summary

Introduce a small, decoupled network layer so the app can fetch remote data in
production while staying fully testable:

1. **`ApiClient`** — one low-level class that does the actual HTTP requests
   (`getJson`, `postJson`, `putJson`, `deleteJson`), with a production
   `HttpApiClient` (via `package:http`) and a scripted `MockApiClient` for tests,
   exposed through an overridable `apiClientProvider`.
2. **`FxRateRemoteService`** — a separate class that *uses* `ApiClient` to fetch
   live FX rates, implementing the existing `RemoteFxService` interface behind a
   configurable base URL (actual endpoint provider chosen later — "other/later").
   Replaces `MockRemoteFxService` in `remoteFxProvider`.

## Success Criteria

- `ApiClient` decoupled: `HttpApiClient` performs real GET/POST/PUT/DELETE with
  timeout + User-Agent; `MockApiClient` returns scripted responses; both exposed
  via `apiClientProvider` overridable in `ProviderScope`.
- `FxRateRemoteService implements RemoteFxService` takes an `ApiClient` + base
  URL const; `remoteFxProvider` uses it; `MockRemoteFxService` kept for tests.
- `flutter analyze lib/` clean; `flutter test` stays `+39 -4` (pre-existing
  sqlite env failures only); touched files format-clean.

## Constraints & Non-Goals

- One new dependency: `http` (add to pubspec). No `dio`, no interceptors.
- Non-goal: sync protocol (separate plan), auth, retry/backoff, caching,
  Open Food Facts wiring, choosing the real FX endpoint (configurable seam only).

## Task Stack

- [x] T01: `ApiClient core + Http + Mock + provider` (status:done)
  - Task ID: T01
  - Goal: Add `lib/src/network/api_client.dart` with the abstract `ApiClient`
    (`getJson`/`postJson`/`putJson`/`deleteJson` → decoded JSON), `HttpApiClient`
    (timeout, User-Agent, injected base URL), `MockApiClient` (scripted
    in-memory responses), and `apiClientProvider`. Add `http` to pubspec.
  - Boundaries (in/out of scope):
    - In: new `lib/src/network/` dir, pubspec dependency, `apiClientProvider`.
    - Out: consumers (T02+), interceptors, auth, streaming.
  - Done when: `apiClientProvider` returns `HttpApiClient`; `MockApiClient`
    returns canned JSON; `dart analyze lib/` clean.
  - Verification notes (commands or checks):
    - `flutter pub get`; `dart analyze lib/src/network/`.

- [x] T02: `FxRateRemoteService — real impl behind RemoteFxService` (status:done)
  - Task ID: T02
  - Goal: Implement a real FX-rates service on top of `ApiClient` and wire it
    into `remoteFxProvider`, keeping the mock for tests.
  - Boundaries (in/out of scope):
    - In: `lib/src/budget/services/remote_fx.dart` — `FxRateRemoteService(
      ApiClient, {baseUrl})` returning `Map<String,double>` rates for the base
      currency; `budget/providers/services.dart` `remoteFxProvider` now returns
      it; `MockRemoteFxService` retained.
    - Out: the actual endpoint/provider choice (const seam only), FX settings UI
      (fx-display plan), sync.
  - Done when: `remoteFxProvider` serves real (or mock-injectable) rates; a test
    can override `apiClientProvider` with `MockApiClient` and have the service
    parse rates; `dart analyze lib/` clean.
  - Verification notes (commands or checks):
    - `dart analyze lib/src/budget/`; `flutter test test/` (existing suites).

- [x] T03: `Validation and context sync` (status:done)
  - Task ID: T03
  - Goal: Full checks + document the network layer.
  - Boundaries (in/out of scope): in — analyze/format/tests, new
    `context/network/network.md`, architecture.md + glossary.md updates; out —
    commit.
  - Done when: `flutter analyze lib` clean; `flutter test` `+39 -4`; context
    reads back accurate.
  - Verification notes (commands or checks):
    - `flutter analyze lib`; `flutter test`; `dart format --output=none --set-exit-if-changed lib/src/network lib/src/budget`.

## Validation Report (2026-08-20)

- `flutter pub get` — `http: ^1.2.0` added (1 dependency changed).
- `dart analyze lib` — No issues found.
- `dart format --output=none --set-exit-if-changed` on `lib/src/network`,
  `remote_fx.dart`, `services.dart` — clean.
- `flutter test` — `+42 -4` (baseline `+39 -4` + 3 new network-client tests;
  the 4 failures are the pre-existing `libsqlite3.so` env-only DB tests).
- Context synced: new `context/network/network.md`; architecture.md (Network
  section), glossary.md (`apiClientProvider`, `MockApiClient`, `HttpApiClient`,
  `FxRateRemoteService`), context-map.md.

## Next Command

/next-task network-client T01
