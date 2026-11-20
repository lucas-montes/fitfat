# FitFat — Network Layer

## Overview

A small, decoupled HTTP layer (`lib/src/network/`) so higher-level services can
fetch remote data while staying fully unit-testable without a socket. FX rates do
not go through it: the phone pulls them from the sync server (`GET /fx-rates`,
`CurrencySyncClient`, see [sync-contract.md](../sync/sync-contract.md) §11),
and the server fetches them from the ECB itself (server `src/fx.rs`).

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

## Remote services

- There is no phone-side FX endpoint any more. The old `FX_API_BASE_URL` seam
  (`remoteFxProvider`, `FxRateRemoteService`, `MockRemoteFxService`) was removed,
  and since 2026-11-20 the sync server is the only source of rates.
- `remoteReceiptOcrProvider` returns `HttpRemoteReceiptOcrService` (real backend). It POSTs the image to `/receipt-pictures/upload` and polls `/receipt-pictures/{id}/parse` until the status is terminal. `MockRemoteReceiptOcrService` is retained for tests/offline dev.

## Tests

The network layer is exercised through the sync clients' tests with
`MockApiClient`. The old `test/network_client_test.dart` went with the FX seam.

## Future work

- Wire Open Food Facts lookups (ingredient-metadata plan) and the sync contract
  (sync-contract plan) through `ApiClient`.
- Retries/backoff and auth are explicitly non-goals today.