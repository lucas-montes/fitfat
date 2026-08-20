# FitFat — Network Layer

## Overview

A small, decoupled HTTP layer (`lib/src/network/`) so higher-level services can
fetch remote data while staying fully unit-testable without a socket. There is
**no real endpoint configured yet** — the FX endpoint is a configurable seam
("other/later", decision 2026-08-19).

## `ApiClient`

Abstract interface with four decoded-JSON verbs:

- `getJson(path, {query})`
- `postJson(path, {body, query})`
- `putJson(path, {body, query})`
- `deleteJson(path, {query})`

`ApiClient` returns `Future<Object?>` (decoded JSON) or throws
`ApiException(statusCode, body)` for non-2xx responses.

### Implementations

- **`HttpApiClient`** (`lib/src/network/api_client.dart`) — production client
  backed by `package:http`: joins requests onto a `baseUrl`, 15 s timeout,
  JSON `Content-Type` + `User-Agent: FitFat/1.0`, UTF-8 JSON decode.
- **`MockApiClient`** — scripted in-memory client for tests: a single
  `onRequest(method, path, body)` callback returns the canned decoded JSON (or
  throws to simulate an HTTP failure); no handler yields `null`.

### Provider

`apiClientProvider` (`Provider<ApiClient>`) defaults to `HttpApiClient` with a
compile-time `API_BASE_URL`. Tests override it in `ProviderScope`:

```dart
apiClientProvider.overrideWithValue(MockApiClient(onRequest: ...))
```

## FX rates seam

- `remoteFxProvider` (`lib/src/budget/providers/services.dart`) now returns
  `FxRateRemoteService(apiClientProvider, baseUrl: fxRatesApiBaseUrl)` instead
  of the mock.
- `fxRatesApiBaseUrl` (`lib/src/budget/services/remote_fx.dart`) is a
  compile-time `String.fromEnvironment('FX_API_BASE_URL')` const, **empty until a
  provider is chosen**. Calling `fetchRates` while unconfigured throws a clear
  `StateError` ("FX endpoint not configured…"), which surfaces as the standard
  error banner in the Settings refresh flow.
- Expected payload: `{"base": "<base>", "rates": {"<CODE>": rate, …}}` at
  `{baseUrl}/rates?base=<base>`.
- `MockRemoteFxService` is retained for tests.
- `remoteReceiptOcrProvider` is still a mock (unchanged).

## Tests

`test/network_client_test.dart` verifies `FxRateRemoteService` parses
`MockApiClient` responses and fails clearly while unconfigured.

## Future work

- Choose the real FX endpoint and set `FX_API_BASE_URL`.
- Wire Open Food Facts lookups (ingredient-metadata plan) and the sync contract
  (sync-contract plan) through `ApiClient`.
- Retries/backoff and auth are explicitly non-goals today.