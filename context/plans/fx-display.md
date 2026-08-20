# Plan: Budget FX — rate display upgrade + manual override marker (Phase C)

## Change Summary

Make the FX rates the budget uses transparent and auditable:

1. **Display** in Settings → Budget & Currency: each row shows
   `1 {cur} = {rate} {base} (1 {base} = {inverse})` plus **when the rate was
   last updated** and a **"manual" badge** when it was set by hand.
2. **Manual override marker**: `fx_rates.manual` column (schema v19) so manual
   edits are distinguishable from fetched rates and a refresh can warn/preserve
   them.
3. **Transactions show the rate used**: converted amounts display the rate
   applied (via the existing `convertToBase` `rateUsed`), so totals can be
   audited.

## Success Criteria

- Rates rows render `cur → base` + inverse + updated date + manual badge.
- `fx_rates.manual` set on manual edits, cleared on a fresh `replaceAll`;
  repository exposes entries with `updatedAt` + `manual`.
- Transaction list/detail shows the conversion rate used.
- `flutter gen-l10n` exit 0; `flutter analyze lib/` clean; `flutter test`
  `+39 -4` (pre-existing sqlite env failures).

## Constraints & Non-Goals

- Schema bump v19: adds `fx_rates.manual` only (no new tables, no PK change —
  `code` PK retained; known edge case for same-code/different-base noted, out of
  scope).
- Non-goal: auto-refresh (settings-additions plan), real FX endpoint
  (network-client plan), editing the inverse directly.

## Task Stack

- [x] T01: `fx_rates.manual column (schema v19)` (status:done)
  - Task ID: T01
  - Goal: Add a persisted manual-override flag to cached FX rates.
  - Boundaries (in/out of scope):
    - In: `lib/src/database/tables.dart` (`FxRates.manual`,
      `BOOLEAN NOT NULL DEFAULT 0`), `app_database.dart` (schemaVersion 19 +
      `from < 19` addColumn), build_runner, `FxRepository.setRate` stamps manual
      = true, `replaceAll` inserts manual = false; new
      `FxRepository.getRateEntries(base)` returning
      `List<({String code, double rateToBase, DateTime updatedAt, bool manual})>`;
      `fxRatesProvider` (Map) unchanged for converters.
    - Out: UI (T02), transaction display (T03).
  - Done when: migration creates the column; manual set/clear behaves;
    `dart analyze lib/` clean.
  - Verification notes (commands or checks):
    - `flutter pub run build_runner build --delete-conflicting-outputs`;
      `dart analyze lib/src/budget/ lib/src/database/`.

- [x] T02: `Rates rows — inverse + updated + manual badge` (status:done)
  - Task ID: T02
  - Goal: Upgrade the Settings → Budget & Currency rate list with full context.
  - Boundaries (in/out of scope):
    - In: `lib/src/settings/screens/settings_screen.dart` `_CurrencySection` —
      rows read `getRateEntries`; each row shows `1 {cur} = {rate} {base}` +
      `1 {base} = {inverse}` + `updated {date}` (`DateFormats`) + a "manual"
      badge when `manual`; new l10n keys en/fr/es.
    - Out: refresh behavior, base-currency switch (unchanged).
  - Done when: rows render the three pieces of info + manual badge;
    `flutter gen-l10n`; `dart analyze lib/` clean.
  - Verification notes (commands or checks):
    - `flutter gen-l10n`; `dart analyze lib/src/settings/screens/settings_screen.dart`.

- [x] T03: `Transactions show the rate used` (status:done)
  - Task ID: T03
  - Goal: Surface the conversion rate applied to non-base-currency amounts.
  - Boundaries (in/out of scope):
    - In: transaction list rows + transaction detail — where a transaction is
      converted from a non-base currency, show the rate used
      (`convertToBase`'s `rateUsed`); new l10n keys en/fr/es.
    - Out: storing the rate historically (audit trail is a larger design; noted
      in plan open questions).
  - Done when: converted rows display the applied rate; `flutter analyze lib/` clean.
  - Verification notes (commands or checks):
    - `flutter gen-l10n`; `dart analyze lib/src/budget/`.

- [x] T04: `Validation and context sync` (status:done)
  - Task ID: T04
  - Goal: Full checks + document the FX display/override behavior.
  - Boundaries (in/out of scope): in — analyze/format/tests, schema.md v19
    note, settings.md + budget doc updates; out — commit.
  - Done when: `flutter analyze lib` clean; `flutter test` `+39 -4`; context
    accurate.
  - Verification notes (commands or checks):
    - `flutter analyze lib`; `flutter test`; `dart format --output=none --set-exit-if-changed lib/src/settings lib/src/budget`.

## Validation Report

- **T01** `flutter pub run build_runner build --delete-conflicting-outputs` OK;
  `dart analyze lib/src/database lib/src/budget` clean.
- **T02/T03** `flutter gen-l10n` exit 0; `dart analyze lib` clean (0 issues).
- **T04** `dart analyze lib` clean; `flutter test` `+42 -4` (baseline: the 4
  pre-existing failures are DB tests needing `libsqlite3.so`); touched files
  `dart format --output=none --set-exit-if-changed` report 0 changed.
- **Context synced:** schema.md v19 (fx_rates.manual, v18→v19 migration),
  glossary AppDatabase v19, settings.md Budget & Currency row description +
  `rateUsed` transaction display. Decision on the open question recorded in
  the plan: historical per-transaction rate persistence remained out of
  scope — the existing `transactions.rate_used` column (added with the budget
  tables in v14) already stores it, so list/detail surfaces it without a new
  migration.
- Note: `dart format --set-exit-if-changed` on whole `lib/src/budget`
  flags pre-existing drifted files (`budget_sync.dart`,
  `account_type_meta.dart`) — left untouched per repo formatting policy.

## Open Questions

- Audit trail: should each transaction persist the rate at conversion time
  (schema) rather than only display it? Deferred — record decision in context.

## Next Command

/next-task fx-display T01
