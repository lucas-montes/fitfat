# Plan: Settings additions — FX auto-refresh, experiment reminders, units, backup (Phase G)

## Change Summary

Fill the settings gaps surfaced in the 2026-08-18 review:

1. **FX auto-refresh** toggle + interval (re-fetches cached rates in the
   background via the network-client `ApiClient`).
2. **App-wide experiment reminder toggle** (complements the per-experiment
   switch; cancel/reschedule via `ExperimentReminderScheduler`).
3. **Units preference** — kg/lb for weight/volume, cm/in for height, applied to
   workout + body displays.
4. **Backup/export** — export a copy of the local SQLite database (share via
   `share_plus`).

## Success Criteria

- New settings persist exactly like existing ones (shared_preferences
  `settings_*` keys).
- FX auto-refresh toggles a periodic refresh respecting the chosen interval and
  the app-wide/network availability; experiment toggle cancels/reschedules.
- Units preference flows into workout weight/volume and body-metric displays.
- Backup exports a working DB copy (restore is out of scope this round).
- `flutter gen-l10n` exit 0; `flutter analyze lib/` clean; `flutter test`
  `+39 -4` (pre-existing sqlite env failures).

## Constraints & Non-Goals

- Depends on **network-client** plan (T01: `ApiClient` + real FX service) —
  implement after it.
- No schema changes.
- Non-goal: restore/import, scheduled-notification overhaul, currency per
  transaction default, theme-color picker.

## Task Stack

- [ ] T01: `FX auto-refresh toggle + interval` (status:todo)
  - Task ID: T01
  - Goal: Periodically refresh cached FX rates while enabled.
  - Boundaries (in/out of scope):
    - In: `SettingsState` + `SettingsNotifier` gain `fxAutoRefresh` (bool,
      default off) and `fxRefreshIntervalHours` (int, default 24); a periodic
      refresh mechanism (timer/`WidgetsBindingObserver`-safe, gated on the
      toggle) calling `RemoteFxService.fetchRates` → `FxRepository.replaceAll`
      then `fxRatesProvider.invalidate`; UI in Settings → Budget & Currency
      (switch + interval selector); new l10n keys en/fr/es.
    - Out: manual refresh button changes (unchanged), background isolate work.
  - Done when: toggling schedules/cancels the refresh and rates update;
    `flutter analyze lib/` clean.
  - Verification notes (commands or checks):
    - `flutter gen-l10n`; `dart analyze lib/src/settings/ lib/src/budget/`.

- [ ] T02: `App-wide experiment reminder toggle` (status:todo)
  - Task ID: T02
  - Goal: Master switch for experiment check-in reminders.
  - Boundaries (in/out of scope):
    - In: `SettingsState` + notifier `experimentRemindersEnabled` (default on);
      when off → cancel all scheduled experiment reminders (needs the active
      experiment ids — read `experimentListProvider`, cancel via
      `ExperimentReminderScheduler.cancelForExperiment`), when on → reschedule
      the active ones; Settings → Notifications switch; new l10n keys en/fr/es.
    - Out: changing the per-experiment toggle behavior.
  - Done when: the switch cancels/reschedules deterministically; `flutter analyze
    lib/` clean.
  - Verification notes (commands or checks):
    - `flutter gen-l10n`; `dart analyze lib/src/settings/ lib/src/experiments/`.

- [ ] T03: `Units preference (kg/lb, cm/in)` (status:todo)
  - Task ID: T03
  - Goal: Let users switch weight/length units across displays.
  - Boundaries (in/out of scope):
    - In: `SettingsState` + notifier `weightUnit` (`kg`/`lb`) and `lengthUnit`
      (`cm`/`in`); a shared conversion helper (kg↔lb, cm↔in) used by workout
      weight/volume and body-weight/height displays; Settings → Profile (or new
      General) segment; new l10n keys en/fr/es.
    - Out: stored data conversion, chart re-baselining.
  - Done when: changing units re-renders the affected displays; `flutter analyze
    lib/` clean.
  - Verification notes (commands or checks):
    - `flutter gen-l10n`; `dart analyze lib/src/settings/`.

- [ ] T04: `Backup/export SQLite database` (status:todo)
  - Task ID: T04
  - Goal: Export a copy of the local database from Settings.
  - Boundaries (in/out of scope):
    - In: Settings → Data gains "Export database" — copy the app DB file
      (`path_provider` documents dir) to a temp/cache path and share via
      `share_plus`; error path via the standard banner; new l10n keys en/fr/es.
    - Out: import/restore, scheduled backups, JSON export.
  - Done when: tapping export shares a valid DB copy; `flutter analyze lib/`
    clean.
  - Verification notes (commands or checks):
    - `flutter gen-l10n`; `dart analyze lib/src/settings/screens/settings_screen.dart`.

- [ ] T05: `Validation and context sync` (status:todo)
  - Task ID: T05
  - Goal: Full checks + document the new settings.
  - Boundaries (in/out of scope): in — analyze/format/tests,
    `context/settings/settings.md` update; out — commit.
  - Done when: `flutter analyze lib` clean; `flutter test` `+39 -4`; context
    accurate.
  - Verification notes (commands or checks):
    - `flutter analyze lib`; `flutter test`;
      `dart format --output=none --set-exit-if-changed lib/src/settings`.

## Next Command

/next-task settings-additions T01
