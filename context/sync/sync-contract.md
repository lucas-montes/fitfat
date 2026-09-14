# FitFat — Data Sync Contract

**Version:** 1.0-draft (2026-08-22) · **Status:** design draft + MVP client implemented (2026-08-23)
**Scope of this document:** the contract a future sync server (and the client
sync engine) must implement. §11 records the *simpler first client* that
actually shipped, which diverges from the full `/v1/sync/{entity}` envelope
below (the full protocol remains the target once a server exists). It
intentionally avoids choosing transport frameworks, hosting, or auth vendors.

Related: [database/schema.md](../database/schema.md) (table names used below),
[network/network.md](../network/network.md) (`ApiClient` seam),
plans `network-client` (schema v19 FX columns), `ingredient-metadata`
(schema v20 stores/pictures/prices), `workout-replay` (planned schema v21
`workouts.routine_id`).

---

## 1. Principles

1. **Offline-first.** Every mutation writes to the local SQLite database first.
   Sync is a background reconciler that never blocks or gates a UI action. The
   app is fully functional with no network and no account.
2. **Client-owned identity.** All primary keys are client-generated UUID v7,
   globally unique by construction. The server never rewrites ids; relations
   survive sync unchanged.
3. **Delta synchronisation.** Both directions move *changes*, not snapshots:
   the client pulls `since=<cursor>` and pushes batches of local changes.
4. **Deterministic conflict resolution.** Last-write-wins (LWW) per row, with
   the exceptions in §6 — chosen because every repository today replaces rows
   wholesale on update; there is no field-level merge anywhere in the app.
5. **Idempotent, resumable batches.** Replaying any request must be safe
   (§7). A crashed sync resumes from persisted cursors without duplicates.

## 2. Entity inventory

Table names match `context/database/schema.md` exactly.

### 2.1 In scope (synced)

| Aggregate | Tables | Notes |
|-----------|--------|-------|
| workout | `workouts`, `workout_exercises`, `exercise_sets` | synced as one atomic unit keyed by `workouts.id`; includes v21 `routine_id` lineage when it lands |
| exercise | `exercises` | user edits + user-created rows; see OQ-5 for locked catalog rows |
| ingredient | `ingredients`, `ingredient_pictures`, `ingredient_prices` | pictures sync metadata only (§2.2); prices reference `stores.id` |
| store | `stores` | create + rename only (no delete exists) |
| meal | `meals`, `meal_ingredients` | atomic per meal |
| planner_item | `planner_items` | recurrence JSON round-trips verbatim |
| note | `notes` | |
| body_metric | `body_metrics` | upsert-by-day semantics preserved |
| account | `accounts` | budget accounts incl. opening balance |
| transaction | `transactions` | `amount_base` / `rate_used` are derived-but-persisted; synced as-is so history stays reproducible |
| receipt (metadata) | `receipts` | rows only — image binaries excluded (§2.2) |
| experiment | `experiments`, `experiment_checkins` | check-ins unique per `(experiment_id, day)` |

### 2.2 Out of scope (never synced)

- **`fx_rates`** — originally out of scope (a derived cache, and syncing it
  would fight the manual-edit flag and the base-currency setting). **Updated
  (2026-08-23):** `fx_rates` is now a *pull-only* synced resource (see §11);
  the client preserves any locally hand-edited `manual` flag so a sync never
  clobbers a user override. Push of local rate edits is still out of scope.
- **Receipt/ingredient picture binaries** — local files under the app documents
  directory. Metadata rows sync; bytes need a separate blob decision (OQ-2).
- **Settings/preferences** — device-local by nature (units, theme, locale).
  A future "preferences sync" would be its own contract version.
- **Derived caches** — anything computed at read time (dashboard aggregates).

## 3. Change tracking

The server enumerates changes per entity type via a monotonic per-row version:

- Every synced table gains an `updated_at` (epoch ms) column bumped on every
  local write, plus a soft `deleted_at` where hard deletes exist today
  (tombstones, §6). Today only `notes.updated_at` and `fx_rates.updated_at`
  exist — **a schema migration is required before sync ships** (future v22+;
  backfill existing rows from `created_at`).
- `ingredients.is_archived` stays the domain-level soft delete; it syncs as a
  normal column and does not replace tombstones for other tables.
- The client keeps one **cursor per entity type** (server-assigned, strictly
  increasing), persisted locally after each successful pull.
- Pushes do not advance pull cursors; the server echoes applied versions so
  the client can ignore its own echo in pulls (§5).

## 4. Identity & bootstrap

1. **Device id:** UUID v7 generated once, stored in prefs
   (`sync_device_id`). Sent with every request (`device_id` header/field);
   used as the LWW tie-breaker and for audit.
2. **Account:** minimal identity = server-issued account id + bearer token.
   Auth mechanism itself is out of scope (OQ-3); the contract only requires:
   - `POST /v1/accounts/bootstrap` → `{ account_id }` after auth, creating the
     server account on first use.
   - All subsequent calls carry the token; the server scopes every query to
     the authenticated account.
3. **First-sync seed:** a device that has never synced pushes its full local
   state as ordinary push batches (client-generated ids make this collision-
   free), then pulls. The server applies seed batches under the same LWW rules,
   so a second device seeding overlapping data converges instead of failing.
4. One account may have many devices; there is no "primary" device.

## 5. Protocol

### 5.1 Pull — `GET /v1/sync/{entity}?since=<cursor>&limit=<n>`

Response:

```json
{
  "entity": "workout",
  "changes": [
    {
      "id": "018f6a2e-…",
      "version": 4812,
      "deleted_at": null,
      "data": { /* full aggregate payload, §8 */ }
    }
  ],
  "next_cursor": 4899,
  "has_more": false
}
```

- `since` is the client's persisted cursor for that entity type; omitting it
  means "everything" (fresh device).
- Rows are returned ordered by `version`; the client persists
  `next_cursor` **only after** applying the batch locally in one transaction.
- Deleted rows appear as entries with non-null `deleted_at` and no `data`.
- The client skips rows whose `id` matches a pending un-pushed local change
  whose local `updated_at` is newer (LWW pre-filter); otherwise it applies the
  server row over the local one.

### 5.2 Push — `POST /v1/sync/{entity}`

Request: one batch of up to N ops (§7):

```json
{
  "device_id": "018f11…",
  "idempotency_key": "018f77aa-…",
  "ops": [
    {
      "op": "upsert",
      "id": "018f6a2e-…",
      "updated_at": 1755850000000,
      "data": { /* full aggregate payload, §8 */ }
    },
    {
      "op": "delete",
      "id": "019001bb-…",
      "updated_at": 1755850100000
    }
  ]
}
```

Response:

```json
{
  "applied": [
    { "id": "018f6a2e-…", "version": 5120 },
    { "id": "019001bb-…", "version": 5121 }
  ],
  "rejected": []
}
```

- `applied[].version` lets the client stamp the server-assigned versions onto
  its own rows, so its own changes don't come back as pulls (echo suppression)
  and cursors stay meaningful.
- Per-op failure semantics: a batch is applied **all-or-nothing inside one
  server transaction**; on rejection the response carries a machine-readable
  `reason` per op index and the client retries after backoff (§7). Partial
  application never happens.

## 6. Conflict policy — LWW + exceptions

Default rule for every entity: compare `updated_at` (client-supplied wall
clock, monotonic enough in practice); higher wins. Tie-breakers, in order:
higher `device_id` (lexicographic), then higher `id`.

Documented exceptions:

1. **Aggregates are atomic.** A workout/meals/experiment batch replaces the
   whole aggregate (parent + children) — never parent-from-one-device,
   children-from-another. Children inherit the winning parent's `updated_at`.
2. **Delete beats update only if the delete is newer.** Deletes are tombstone
   writes carrying their own `updated_at`, so an older delete arriving late
   loses against a newer edit (the row resurrects server-side and propagates).
3. **`experiment_checkins` upsert-by-day** mirrors the local unique
   `(experiment_id, day)` constraint; same-day conflicts resolve LWW like any
   row.
4. **`ingredient_prices` upsert-by-(store, day)** likewise; the unique key is
   `(ingredient_id, store_id, recorded_at)`.
5. **No field merging anywhere.** If silent LWW loss proves unacceptable later
   (OQ-4), that is a new contract version.

## 7. Limits, guards, retries

| Guard | Value |
|-------|-------|
| Max ops per push batch | 500 rows (aggregate counts as one op) |
| Max payload size | 1 MiB per request |
| Idempotency | `idempotency_key` (UUID v7 per batch attempt-series); server caches the result for 24 h — retries replay the cached outcome instead of double-applying |
| Retry policy | exponential backoff starting 2 s, ×2, jittered, max 5 min; retry on network errors, 429, 5xx; give up (and surface a banner) after ~30 min of continuous failure, keeping data queued |
| Ordering | within an entity, ops apply in server-version order regardless of arrival order |
| Rollback | failed batch ⇒ whole-batch transaction rollback server-side; client state untouched |
| Clock skew | client clocks may drift; the server records receive time separately but LWW uses client `updated_at` (accepted limitation, OQ-6) |

## 8. Concrete example — workout aggregate

### Push (one completed workout with two exercises)

```json
{
  "device_id": "018f11c0-4b2f-7ae1-9d3a-1f2e3d4c5b6a",
  "idempotency_key": "018f77ab-9c1d-7e2f-8a3b-2f3e4d5c6b7a",
  "ops": [
    {
      "op": "upsert",
      "id": "018f6a2e-8c44-7a01-9f2b-3c4d5e6f7081",
      "updated_at": 1755850000123,
      "data": {
        "workout": {
          "name": "Push Day",
          "date": 1755798000000,
          "started_at": 1755798300000,
          "completed_at": 1755802800000,
          "notes": null,
          "created_at": 1755795000000
        },
        "exercises": [
          {
            "row": {
              "exercise_id": "bench-press-flat",
              "sort_order": 0,
              "notes": "felt heavy"
            },
            "sets": [
              {
                "set_number": 1,
                "reps": 8, "weight_kg": 80.0, "rest_seconds": 150,
                "actual_reps": 8, "actual_weight_kg": 80.0,
                "actual_rest_seconds": 163, "completed_at": 1755799000000,
                "duration_minutes": null, "distance_meters": null,
                "actual_duration_minutes": null,
                "actual_distance_meters": null, "notes": null
              }
            ]
          }
        ]
      }
    }
  ]
}
```

### Pull (another device receives the same aggregate)

```json
{
  "entity": "workout",
  "changes": [
    {
      "id": "018f6a2e-8c44-7a01-9f2b-3c4d5e6f7081",
      "version": 5120,
      "deleted_at": null,
      "data": {
        "workout": {
          "name": "Push Day",
          "date": 1755798000000,
          "started_at": 1755798300000,
          "completed_at": 1755802800000,
          "notes": null,
          "created_at": 1755795000000,
          "routine_id": null
        },
        "exercises": [
          {
            "row": { "exercise_id": "bench-press-flat", "sort_order": 0, "notes": "felt heavy" },
            "sets": [ { "set_number": 1, "reps": 8, "weight_kg": 80.0 } ]
          }
        ]
      }
    }
  ],
  "next_cursor": 5120,
  "has_more": false
}
```

Payloads carry **domain fields only** (snake_case, matching Drift column
names); envelope fields (`op`, `version`, cursors) are contract-level.

## 9. Client engine sketch (non-binding)

- One `SyncEngine` driving: collect local changes (dirty rows by
  `updated_at > last_pushed_at`) → push per entity → pull per entity → apply →
  persist cursors → repeat on connectivity regain + periodic timer.
- Trigger points: app start (after `_BackgroundStartup`), connectivity
  regained, after each repository mutation (debounced).
- All HTTP through the existing `ApiClient` seam (`context/network/network.md`).

## 11. Implemented MVP (2026-08-23)

 A first client shipped that pulls three resources from a user-configured sync
 server (Settings → Budget & Currency → "Sync server" URL + API key). It is a
 deliberately simpler shape than §5, chosen to match the agreed decisions:
 server-side `since` cursor for content resources, Bearer API-key auth, full
 payloads for exercises and ingredients (server authority on content; LWW by
 `updated_at`), a daily snapshot for currencies, an ingredient **push** to the
 shared catalogue, and a currencies sync button in Settings.

### 11.1 Endpoints & auth

| Resource | Endpoint | Query |
|----------|----------|-------|
| exercises | `GET /exercises` | `?since=<cursor ms>` |
| ingredients | `GET /ingredients` | `?since=<cursor ms>` |
 | currencies | `GET /fx-rates` | `?base=<ISO base>&date=YYYY-MM-DD` |
 | ingredient push | `POST /ingredients` | body (see §11.3) |

All calls send `Authorization: Bearer <apiKey>`. The URL and key live in
`SettingsState.remoteSyncBaseUrl` / `remoteSyncApiKey` (SharedPreferences).

### 11.2 Pull envelope (actual, not §5)

 Exercises return full item rows plus two media-presence flags; the only
 removal signal is `deleted[]` (hard-deleted server-side):

 ```json
 {
   "items": [ { "id": "id-1", "name": "Squat", "updated_at": 1755850000000, "hasImage": true, "hasVideo": true, "…" } ],
   "deleted": [ "id-9" ],
   "server_time": 1755850000000
 }
 ```

  **Exercise media (2026-08-25; public since 2026-09-14).** The payload never carries media paths or
  binaries. Media lives on the sync server at URLs *derived* from the exercise
  id. Plain `<img>` / `<video>` tags cannot send an `Authorization` header, so
  `GET /media/*` and `GET /exercises/*.{jpg,mp4}` are exempt from Bearer auth
  (shared catalog assets, not user data); every JSON route stays protected.
  Authenticated clients may keep sending the key — it is simply not required
  for these two shapes:

 - image: `GET <baseUrl>/exercises/<id>.jpg`
 - video: `GET <baseUrl>/exercises/<id>.mp4`

 Client rules:

 - `hasImage` / `hasVideo` (bool) say whether those files exist server-side;
   without them the client would have to 404-probe every exercise every sync.
 - On pull the client downloads any advertised medium missing on disk and
   stores it under `<documents>/exercise_media/<id>.<ext>`; the absolute local
   path is persisted in the row's `imagePath` / `videoPath` columns (null =
   not downloaded / no media — this doubles as the "already downloaded" mark,
   so no extra schema columns exist).
 - Pulls never clobber an existing local media path; a failed download keeps
   the last good cursor so the whole resource retries next sync.
 - When a flag turns false (or the exercise appears in `deleted[]`) the local
   file is removed and the column cleared.
 - **Known limitation:** media is assumed immutable per exercise id — the
   client has no way to notice new bytes at the same derived URL. Replacing an
   image/video means deleting the exercise (or flipping its flag) and
   re-advertising it, until a future contract version adds content hashing.

 Ingredients return full item rows with **nested** `pictures[]` and `prices[]`,
 plus a top-level `stores[]` array the items reference:

 ```json
 {
   "items": [ {
     "id": "id-1", "name": "Oats", "updated_at": 1755850000000, "…",
     "pictures": [ { "id": "p-1", "ingredientId": "id-1", "imagePath": "…", "sortOrder": 0, "createdAt": 1755850000000 } ],
     "prices": [ { "id": "pr-1", "ingredientId": "id-1", "storeId": "s-1", "price": 2.4, "currencyCode": "EUR", "packageGrams": 500, "recordedAt": 1755850000000 } ]
   } ],
   "stores": [ { "id": "s-1", "name": "Carrefour", "updated_at": 1755850000000 } ],
   "deleted": [ "id-9" ],
   "server_time": 1755850000000
 }
 ```

 Currencies are pulled per **day** (a full day's rate table), so each request
 carries `date=YYYY-MM-DD` and rows are keyed by that date:

 ```json
 {
   "items": [ { "code": "EUR", "rateToBase": 0.92, "date": "2026-08-23", "updated_at": 1755850000000 } ],
   "server_time": 1755850000000
 }
 ```

 - `server_time` (epoch ms) is persisted as the next `since` cursor **per
   resource** in `SyncStateStore` (SharedPreferences keys
   `sync_last_exercises` / `sync_last_ingredients` / `sync_last_currencies`).
 - Exercises/ingredients: every `items[]` row is **upserted** (server
   authority on content); `deleted[]` is applied (exercises → hard delete via
   `ExerciseRepository.delete`, ingredients → soft-archive `isArchived = true`
   via `IngredientRepository.archive`). Nested `pictures[]`/`prices[]` and the
   top-level `stores[]` are upserted for ingredients.
 - Currencies: each `items[]` row is upserted into `fx_rates` keyed by
   `(code, baseCode, date)`; there are no deletions.

### 11.3 Apply rules

  - **Exercises / ingredients:** full upsert of content; `deleted[]` removes
    rows locally (hard / soft-archive as above). Local content edits are
    overwritten by the server (server authority) — conflict UI is deferred (§5).
    Exercise media is the exception to "full upsert": `imagePath`/`videoPath`
    are client-local download state, reconciled per §11.2 rather than taken
    from the payload.
 - **Currencies:** upsert into `fx_rates` but **preserve** the local `manual`
   flag for the exact `(code, baseCode, date)` row, so a hand-edited rate is
   never overwritten by a sync. Snapshots are daily, so `rateDate` history is
   retained.
 - **Ingredient push:** `POST /ingredients` (Bearer) with the full ingredient
   plus nested `pictures[]` and `prices[]`; idempotent by ingredient `id` so
   re-pushing the same ingredient is safe. Triggered from the ingredient detail
   screen ("Push to shared catalogue" action). This is how a user contributes
   a new ingredient to the shared pool.
 - **Idempotency:** safe to replay — content resources re-request only `since`
   the last persisted cursor; currencies re-request the current `date`.
 - **Errors:** network/HTTP failures return a `SyncResult.error`; the UI shows a
   banner via `showTopBanner` and keeps the last good cursor (no partial
   advancement). Success is silent (notebook rule: no success banners).

### 11.4 Client files

 - `lib/src/sync/sync_models.dart` — `SyncResource`, `SyncResult`, `toSyncDateTime`.
 - `lib/src/sync/sync_state_store.dart` — per-resource cursor persistence.
  - `lib/src/sync/exercise_sync_client.dart` — full-payload pull → upsert +
    hard-delete `deleted[]`; reconciles local media paths and drives
    `ExerciseMediaDownloader` (download missing, remove dropped/deleted).
  - `lib/src/sync/exercise_media_sync.dart` — `ExerciseMediaDownloader` +
    `ExerciseMediaKind`: derived media URLs (`<base>/exercises/<id>.jpg|.mp4`,
    Bearer auth via `ApiClient.getBytes`), storage under
    `<documents>/exercise_media/`, best-effort file removal.
 - `lib/src/sync/ingredient_sync_client.dart` — full-payload pull → upsert
   (items + stores + nested pictures/prices) + soft-archive `deleted[]`; plus
   `push()` → `POST /ingredients`.
 - `lib/src/sync/currency_sync_client.dart` — `date`-scoped full-rate pull →
   `FxRepository.upsertRate(rateDate)`.
 - `lib/src/sync/sync_service.dart` — `SyncService` + `syncServiceProvider`
   orchestrator (reads cursor, builds `HttpApiClient`, persists cursor, exposes
   `pushIngredient`).
 - `lib/src/sync/sync_button.dart` — `SyncButton` (spinner + error banner).
 - Wiring: `exercise_list.dart`, `ingredient_list.dart` app-bar `SyncButton`;
   `ingredient_detail_screen.dart` "Push to shared catalogue" action;
   `settings_screen.dart` `_SyncServerCard` (URL/key + currencies sync).
 - Repository seams: `ExerciseRepository.delete` / `upsert`,
   `IngredientRepository.upsert` / `upsertStore` / `upsertPicture` /
   `upsertPrice` / `archive`, `FxRepository.upsertRate`.
  - Schema: `fx_rates` now carries `rateDate` and a composite PK
    `(code, baseCode, rateDate)` (migration v22 rebuilds the table).

### 11.5 Selective catalog + per-id fetch (selective-sync-catalog T02)

  Thin-client selective import reads a lightweight server index, then fetches
  only chosen rows. All calls use the same Bearer key as §11.1:

  | Resource | Endpoint | Shape |
  |----------|----------|-------|
  | exercise catalog | `GET /exercises/catalog` | `{server_time, items: [{id, name, has_image}]}` (name-ordered, excludes soft-deleted; no `since`, no `deleted`; `has_image` lets the picker skip thumbnail fetches for imageless rows) |
  | ingredient catalog | `GET /ingredients/catalog` | `{server_time, items: [{id, name, barcode?}]}` (same semantics) |
  | exercise item | `GET /exercises/item/:id` | single full exercise shape incl. `hasImage`/`hasVideo`; `404 {message}` when missing or soft-deleted |
  | ingredient item | `GET /ingredients/item/:id` | minimal selective shape (full scalar columns + `pictures`, no `prices`/`stores`); `404 {message}` when missing or soft-deleted |

  Notes:

  - Item routes live at `/item/:id` because `/exercises/:id` is already the
    media route (`GET /exercises/<id>.jpg|.mp4`, Bearer, `404` when absent —
    unchanged, and the stable thumbnail URL the picker fetches live).
  - Bulk pulls (`GET /exercises`, `GET /ingredients` with `?since=` +
    `deleted[]`) are unchanged; selective import ignores server `deleted[]`
    and local selective deletions are never pushed.
  - Ingredient picture `imagePath` values remain metadata strings in V1 (no
    binary upload/serving); the client persists them as-is.

  **Client engine (selective-sync-catalog T03).** `CatalogSyncClient`
  (`lib/src/sync/catalog_sync_client.dart`) owns refresh (cache replace, no
  user-table/media/cursor touch) and per-id import (upsert + offline-asset
  download only at import time; `404` ids skipped). Bulk loops share
  `ExerciseSyncClient.importItem` / `IngredientSyncClient.upsertAggregate`.
  `SyncService` exposes `refreshExerciseCatalog` / `refreshIngredientCatalog`
  / `importSelectedExercises` / `importSelectedIngredients` — none of which
  calls `setLastSyncedAt` — plus silent `refreshSelectiveCatalogs`.
  `_BackgroundStartup` fires throttled (15 min) background refresh on start +
  resume; an unconfigured server is a no-op. The picker tap path never
  downloads the catalog: it pings `GET /health` (unreachable → blocking
  banner, preserving offline-block), reads `searchHideImported` from cache,
  and offers on-demand refresh via the sheet's refresh button (single-transaction
  batch rewrite). Picker thumbnails are live server fetches for `has_image`
  rows only, so the picker blocks with an unreachable banner when the
  server is down.

---

## 10. Open questions (blockers for implementation)

- **OQ-1 Server stack & hosting** — undecided; contract is runtime-agnostic.
- **OQ-2 Picture/blob transport** — direct-to-storage presigned upload vs
  base64-in-contract; affects `receipts`/`ingredient_pictures` completeness.
- **OQ-3 Auth mechanism** — **Resolved (MVP):** a single Bearer API key header
  (`Authorization: Bearer <apiKey>`) configured per device in Settings. No
  account bootstrap yet; the full `/v1/accounts/bootstrap` flow (§4.2) remains
  the target for the complete protocol.
- **OQ-4 Silent LWW loss UX** — **Resolved (MVP):** accept silent LWW loss for
  v1; no per-entity merge UI. The server row wins on pull.
- **OQ-5 Locked catalog exercises** — **Resolved (MVP):** sync all exercise
  rows the server returns (user + catalog); conflict resolution is LWW by
  `updated_at`. Locked-row asset refresh fighting server rows is accepted as a
  future concern; the MVP client does not special-case `isLocked`.
- **OQ-6 Clock trust** — keep client-clock LWW or move to server-receive-time
  ordering?
- **OQ-7 Cursor granularity** — per-entity-type cursors (this doc) vs one
  global cursor; per-type allows partial syncs but more bookkeeping.
- **OQ-8 Schema evolution** — how server stores payloads across app schema
  bumps (raw JSON passthrough vs normalized tables); needed before first
  server commit.
