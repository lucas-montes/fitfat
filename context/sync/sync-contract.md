# FitFat — Data Sync Contract

**Version:** 1.0-draft (2026-08-22) · **Status:** design only, no server exists yet
**Scope of this document:** the contract a future sync server (and the client
sync engine) must implement. It intentionally avoids choosing transport
frameworks, hosting, or auth vendors.

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

- **`fx_rates`** — a derived cache, refetchable from the rates endpoint;
  syncing it would fight the manual-edit flag and the base-currency setting.
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

## 10. Open questions (blockers for implementation)

- **OQ-1 Server stack & hosting** — undecided; contract is runtime-agnostic.
- **OQ-2 Picture/blob transport** — direct-to-storage presigned upload vs
  base64-in-contract; affects `receipts`/`ingredient_pictures` completeness.
- **OQ-3 Auth mechanism** — email/password vs magic-link vs OAuth; also token
  refresh policy.
- **OQ-4 Silent LWW loss UX** — acceptable for v1? Any per-entity merge UI?
- **OQ-5 Locked catalog exercises** — sync user rows only and let each device
  re-seed locked rows from the bundled asset, or sync them too (risking asset
  refresh fighting server rows)?
- **OQ-6 Clock trust** — keep client-clock LWW or move to server-receive-time
  ordering?
- **OQ-7 Cursor granularity** — per-entity-type cursors (this doc) vs one
  global cursor; per-type allows partial syncs but more bookkeeping.
- **OQ-8 Schema evolution** — how server stores payloads across app schema
  bumps (raw JSON passthrough vs normalized tables); needed before first
  server commit.
