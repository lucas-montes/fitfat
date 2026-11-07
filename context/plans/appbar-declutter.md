# Plan: AppBar decluttering (Phase A)

## Change Summary

Stop the appbar from becoming a dumping ground as features grow. Adopt the rule
**"≤1 always-visible action + one `PopupMenuButton` (⋮ More) per screen; create
actions live in FABs; search opens a dedicated search route"** and apply it where
the appbar is currently busiest.

## Success Criteria

- Planner appbar shows only the contextual view-toggle icon; "copy previous day"
  moves into a `PopupMenuButton`.
- The pattern is documented in `context/ui/design-system.md` so future screens
  follow it.
- Other appbars unchanged (Dashboard keeps its single gear, Meals keeps
  manage-ingredients, Budget/Notes/Experiments/Exercise stay as-is).
- `dart analyze lib/` clean; touched files format-clean.

## Constraints & Non-Goals

- No behavior change beyond the copy-previous-day relocation (same handler).
- Non-goal: converting any screen's search/filter into a route, adding new
  appbar items, overflow menus with no items (skip until items exist).

## Task Stack

- [x] T01: `Planner appbar — More menu (copy previous day)` (status:done)
  - Task ID: T01
  - Goal: Reduce the Planner appbar to a single always-visible action by moving
    the copy-previous-day `IconButton` into a `PopupMenuButton`.
  - Boundaries (in/out of scope):
    - In: `lib/src/planner/screens/planner_screen.dart` — keep the
      view-mode-toggle `IconButton`; replace the copy-previous-day `IconButton`
      with a `PopupMenuButton` whose only item is copy-previous-day (same
      `_copyFromPreviousDay` handler + tooltip/l10n preserved).
    - Out: view-toggle behavior, day navigation, l10n key changes.
  - Done when: appbar shows one icon; copy-previous-day reachable via the ⋮ menu;
    `dart analyze lib/` clean.
  - Verification notes (commands or checks):
    - `dart analyze lib/src/planner/screens/planner_screen.dart`.

- [x] T02: `Pattern note + validation` (status:done)
  - Task ID: T02
  - Goal: Document the appbar rule and run the final checks.
  - Boundaries (in/out of scope):
    - In: `context/ui/design-system.md` — "AppBar action budget" section
      (≤1 visible action + ⋮ More; creates in FAB; search via route);
      full analyze/format/test pass.
    - Out: applying the rule to other screens, commit.
  - Done when: doc updated; `flutter analyze lib` clean; `flutter test`
    `+39 -4` (pre-existing sqlite env failures).
  - Verification notes (commands or checks):
    - `flutter analyze lib`; `flutter test`; `dart format --output=none --set-exit-if-changed lib/src/planner`.

## Validation Report (2026-08-20)

- `flutter gen-l10n` — `plannerMoreActions` added (en/fr/es).
- `dart analyze lib` — No issues found.
- `dart format --output=none --set-exit-if-changed lib/src/planner` — clean.
- `flutter test` — `+42 -4` (4 pre-existing sqlite-env failures only).
- Context synced: `context/ui/design-system.md` "AppBar action budget" section.

## Next Command

/next-task appbar-declutter T01
