# Plan: Sync contract design — offline-first design only, no server (Phase H)

## Change Summary

Design and document the **data-sync contract** for future server sync —
**contract design only, no server implementation**. Produce a written contract
(`context/sync/sync-contract.md`) that any future server/sync implementation
can implement against.

The contract covers:

- **Offline-first principle**: all mutations write locally first; sync
  reconciles later.
- **Delta protocol**: client pulls changes with a `since=` cursor; client pushes
  batches of local changes.
- **Entities in scope**: workouts, exercises, sets, meals/ingredients (+ the new
  stores/prices), planner items, notes, body metrics, experiments + check-ins,
  and the derived (FX) caches that are excluded.
- **Change tracking**: monotonic per-entity row versions / updated-at columns so
  changed rows can be enumerated.
- **Conflict policy**: last-write-wins per entity (matching the app's current
  replace semantics), documented per entity where it differs.
- **Auth/bootstrap**: minimal account identity + device id, first-sync seed.
- **Limits/guards**: batch sizes, retries, idempotency keys, failure/rollback
  semantics.

## Success Criteria

- A `context/sync/sync-contract.md` document (versioned, with a concrete
  JSON example for one entity push + pull).
- Clearly lists in-scope/out-of-scope entities (FX caches out).
- No application code changed; no new dependencies.
- Every open question that would block an implementation is captured.

## Constraints & Non-Goals

- **Design/documentation only** — no code changes, no schema migration in this
  plan.
- Future implementation should reuse the network-client plan's `ApiClient` and
  the sync workstream's repository seams; nothing here blocks that.
- Non-goal: transport encryption/auth specifics beyond a documented requirement,
  server deployment, migration of existing local data.

## Task Stack

- [ ] T01: `Write the sync contract document` (status:todo)
  - Task ID: T01
  - Goal: Produce `context/sync/sync-contract.md`.
  - Boundaries (in/out of scope):
    - In: write the contract covering the sections in the Change Summary —
      offline-first, delta protocol (`since=`), entity list with which tables
      are synced vs excluded, change-tracking (updated-at per synced table),
      LWW conflict policy + per-entity exceptions, identity/bootstrap, batch
      limits/retries/idempotency, and a concrete JSON example for one entity
      push and one pull; link related plans (network-client, ingredient-metadata
      schema v20, fx-display schema v19).
    - Out: any implementation, schema changes, dependencies.
  - Done when: the document exists, is internally consistent with the current
    schema, and lists unresolved questions for implementers.
  - Verification notes (commands or checks):
    - Read the document; confirm every synced table name matches
      `context/database/schema.md`; confirm no Dart/`lib/` files changed
      (`git status`).

- [ ] T02: `Review pass + decision log` (status:todo)
  - Task ID: T02
  - Goal: Validate the contract against the codebase and record decisions.
  - Boundaries (in/out of scope):
    - In: cross-check each synced entity against its repository (that an
      updated-at / row-version source exists or is needed), record decisions
      and open questions in the document, ensure `context/sync/` is linked from
      `context/overview.md`/`context-map.md`.
    - Out: writing implementation code, adopting any tooling.
  - Done when: every synced entity has a documented change-tracking source (or an
    explicit note that one must be added later); decisions logged.
  - Verification notes (commands or checks):
    - Re-read the document end-to-end; `git status` shows only `context/`
      changes.

## Next Command

/next-task sync-contract T01
