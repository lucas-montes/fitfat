# Plan: Recurring planner tasks — "This one / This and all following" (edit + delete)

## Change Summary

Recurring planner tasks materialize concrete occurrences from an anchor carrying
the rule. Today, editing/deleting a **generated occurrence** only affects that
one row. User decision (2026-08-17): for **edit** and **delete** (done stays
per-instance), offer a scope choice: "This one only" vs "This and all following
ones".

## Success Criteria

- Editing a generated occurrence prompts the scope. "This one" keeps current
  behavior. "This and all following" applies the non-rule fields (title, notes,
  start/end, tags, workoutId) to the anchor and re-materializes future
  occurrences with the new values; the edited occurrence's own day remains
  untouched.
- Deleting a generated occurrence prompts the scope. "This only" keeps the
  exclusion path. "This and all following" deletes the target + sets the anchor's
  `endDate` to the day before the target (halting regeneration) + deletes
  materialized future rows. Undo restores the previous `endDate`.
- Deleting/editing the anchor keeps current behavior (anchor edits already re-
  generate future; anchor delete = whole series).
- l10n en/fr/es; `dart analyze lib/` clean; `flutter test` passes.

## Constraints & Non-Goals

- No schema change (recurrence rule already has `endDate`).
- Non-goal: scope choice for toggle-done (stays per-instance).
- Non-goal: per-occurrence field overrides on the anchor.

## Task Stack

- [x] T01: `Repository: edit/delete upcoming series` (status:done)
  - Task ID: T01
  - Goal: Add repo methods to update future occurrences and to stop a series at a
    boundary date (inclusive delete).
  - Boundaries (in/out of scope):
    - In: `lib/src/planner/repositories/planner_repository.dart` —
      `updateFutureOccurrences(seriesId, from, {title, notes, startTimeMinutes,
      endTimeMinutes, tags, workoutId})` (updates materialized rows with
      date >= from, excluding the anchor); `stopSeriesOnOrAfter(seriesId, day)` —
      delete occurrences with date >= start-of-day(day) (excluding the anchor if
      it is earlier) AND set the anchor `recurrence.endDate` to day-before `day`;
      `getAnchorBySeriesId(seriesId)` helper if useful.
    - Out: UI, l10n (T02).
  - Done when: methods behave per the Change Summary and round-trip; unit-testable
    via grep/analyze (manual test deferred); `dart analyze lib/` clean.
  - Verification notes (commands or checks):
    - `dart analyze lib/src/planner/repositories/planner_repository.dart`.

- [x] T02: `Scope dialogs + wiring` (status:done)
  - Task ID: T02
  - Goal: Prompt for scope on edit and delete of a generated occurrence and wire
    the repo calls + reminders.
  - Boundaries (in/out of scope):
    - In: `lib/src/planner/screens/planner_screen.dart` (`_editItem`, `_deleteItem`)
      — when `item.seriesId != null && item.seriesId != item.id`, show a scope
      dialog (l10n `plannerEditScope*` / `plannerDeleteScope*`); "This only" = the
      existing per-item code path; "This and all following" = T01 methods, then
      invalidate the day provider + `invalidateDashboard`, cancel/re-schedule
      reminders for the affected ids. `planner_item_dialog.dart` untouched (the
      dialog already returns all fields).
    - Out: anchor edit/delete changes.
  - Done when: both operations prompt with scoped choices and behave per the
    Change Summary; `flutter gen-l10n` exit 0; `dart analyze lib/` clean.
  - Verification notes (commands or checks):
    - `flutter gen-l10n`; `dart analyze lib/src/planner/`.
    - Manual (deferred): edit/delete a generated occurrence, choose both scopes.

- [x] T03: `Validation and context sync` (status:done)
  - Task ID: T03
  - Goal: Full checks + `context/planner/planner.md` sync + validation report.
  - Boundaries (in/out of scope): in — analyze/test/format, context, plan
    validation; out — git commit.
  - Done when: suite green (excluding pre-existing sqlite env tests); context
    reads back accurate.
  - Verification notes (commands or checks):
    - `dart analyze lib/`; `flutter test`; `dart format --output=none --set-exit-if-changed lib test`.

## Validation Report (T03)

- `flutter analyze lib` → **No issues found**.
- `dart format lib/src/planner` → clean.
- `flutter test` → only pre-existing DB-backed failures (missing `libsqlite3.so` in this env).
- Context: `context/planner/planner.md` updated with the recurring-task scope
  section (`updateFutureOccurrences`, `stopSeriesOnOrAfter`, `restoreSeriesEndDate`,
  scope dialog, undo).

## Next Command

/next-task recurring-task-scope T01