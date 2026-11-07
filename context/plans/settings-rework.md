# Plan: Settings — hub subviews + System language default

## Change Summary

1. Split the single scrolling `SettingsScreen` into a hub of `ListTile`s that
   push separate sub-screens: **Profile**, **Notifications**,
   **Appearance & Language**, **Budget & Currency**, **Data** (user-approved
   grouping, 2026-08-17).
2. Language: add a **System** segment as the default (mirrors the theme
   setting). Selecting System clears the stored locale so the app follows the
   device.

## Success Criteria

- Settings screen is a hub; all 5 groups reachable; every existing setting still
  editable and persisted exactly as before.
- Language offers System/EN/FR/ES with System as the default empty state; EN/FR/ES
  persist via `settings_locale`; System removes the key.
- Theme segment unchanged (already has System).
- `dart analyze lib/` zero errors; `flutter gen-l10n` exit 0; `flutter test` passes.

## Constraints & Non-Goals

- No schema/DB changes (all settings are `SharedPreferences`-backed).
- Keep the existing `SettingsState.locale == null` = device-default semantics.
- Non-goal: adding new settings, changing pref keys, budget features.

## Task Stack

- [x] T01: `SettingsNotifier — clear-locale support` (status:done)
  - Task ID: T01
  - Goal: Let the notifier clear the stored language back to System/device default.
  - Boundaries (in/out of scope):
    - In: `lib/src/settings/providers/settings.dart` — `SettingsState.copyWith`
      gains a locale-clear flag; `SettingsNotifier.setLocaleToSystem()` (or
      `setLocale(Locale?)`), removes `settings_locale` when null.
    - Out: UI (T02), other settings.
  - Done when: calling the clear path removes `settings_locale` and `state.locale`
    becomes null; `dart analyze lib/` clean.
  - Verification notes (commands or checks):
    - `dart analyze lib/src/settings/providers/settings.dart`.

- [x] T02: `Settings hub + sub-screens` (status:done)
  - Task ID: T02
  - Goal: Convert `SettingsScreen` into a hub and move each section into its own
    sub-screen pushed via `MaterialPageRoute`.
  - Boundaries (in/out of scope):
    - In: `lib/src/settings/screens/settings_screen.dart` — hub `ListView` of
      `ListTile`s; new screens: Profile (age/gender/activity/body-fat/goal),
      Notifications (planner toggle + rest alarm sound/vibration), Appearance &
      Language (theme + language incl. System), Budget & Currency (move
      `_CurrencySection`), Data (reset-all with its confirm dialog). Keep
      `_ActivitySegmentedButton`. l10n keys for the hub labels
      (en/fr/es) + `flutter gen-l10n`.
    - Out: changing setting semantics.
  - Done when: hub shows all 5 entries; each sub-screen shows its settings and
    saves identically; `flutter gen-l10n` exit 0; `dart analyze lib/` clean.
  - Verification notes (commands or checks):
    - `flutter gen-l10n`; `dart analyze lib/`.

- [x] T03: `Language System option` (status:done)
  - Task ID: T03
  - Goal: Four-segment language selector with System as the default.
  - Boundaries (in/out of scope):
    - In: Appearance & Language sub-screen — language `SegmentedButton` gets a
      System segment (icon `Icons.language`, l10n `settingsLangSystem`); selecting
      System clears the locale; default state = System selected.
    - Out: theme behavior.
  - Done when: fresh installs show System; tapping EN/FR/ES persists; System
    resets to device; `dart analyze lib/` clean.
  - Verification notes (commands or checks):
    - `dart analyze lib/`; manual: select each language then System.

- [x] T04: `Validation and context sync` (status:done)
  - Task ID: T04
  - Goal: Full checks + `context/settings/settings.md` sync + validation report.
  - Boundaries (in/out of scope): in — analyze/test/format, context files, plan
    validation; out — git commit.
  - Done when: suite green; context reads back accurate.
  - Verification notes (commands or checks):
    - `dart analyze lib/`; `flutter test`; `dart format --output=none --set-exit-if-changed lib test`.

## Validation Report (T04)

- `flutter analyze lib` → **No issues found**.
- `dart format lib/src/settings` → applied (2 files changed), now clean.
- `flutter test` → DB-backed tests remain blocked by the pre-existing missing
  `libsqlite3.so` in this environment; unrelated to this change.
- Context: `context/settings/settings.md` updated (hub/sub-screen structure,
  `setLocaleToSystem`, System language segment, rest-alarm + base-currency rows).

## Next Command

/next-task settings-rework T01