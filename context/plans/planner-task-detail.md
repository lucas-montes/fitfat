# Plan: Planner task detail view + route-based editor (Phase B)

## Change Summary

Tasks currently open a **tall modal bottom sheet** (`planner_item_dialog.dart`)
that is hard to close — a top-edge swipe triggers the phone's notification shade
instead of dismissing the sheet. Replace the editor with a **dedicated
full-screen route (explicit X + Save)** and add a **read-mostly task detail
view** (title, date, times, full note, linked workout, tags, recurrence, done
toggle, delete) reachable from the planner list and the **dashboard's upcoming
tasks**.

## Success Criteria

- Add/edit both open a `PlannerItemFormScreen` (dedicated route, X close + Save,
  `pop` result); the modal sheet is gone.
- `PlannerItemDetailScreen` shows all task fields incl. the full note; Edit →
  form; done toggle + delete work; recurrence/notes display correctly.
- Dashboard `_TaskRow` is tappable → task detail; planner tiles: tap → detail,
  edit affordance → form.
- `flutter gen-l10n` exit 0; `flutter analyze lib/` clean; `flutter test`
  `+39 -4` (pre-existing sqlite env failures).

## Constraints & Non-Goals

- No schema changes; persistence path (repo/providers) unchanged.
- Reuses the existing recurrence/tags/workout picker fields verbatim inside the
  new form.
- Non-goal: quick-add bottom sheet, task comments, sub-tasks, reordering in the
  new detail view.

## Task Stack

- [x] T01 `PlannerItemFormScreen — dedicated route (X + Save)` (status:done)
  - Task ID: T01
  - Goal: Replace the modal sheet with a full-screen add/edit form route.
  - Boundaries (in/out of scope):
    - In: new `lib/src/planner/screens/planner_item_form.dart` — move the
      existing `_PlannerItemSheet` fields into a `Scaffold` with AppBar
      (title + close X + Save), returning the same
      `(title, dueDate, startTimeMinutes, endTimeMinutes, notes, workoutId,
      tags, recurrence)?` record via `Navigator.pop`; update both callers in
      `planner_screen.dart` to push the route (add + edit) instead of
      `showPlannerItemDialog`; delete `planner_item_dialog.dart` sheet wrapper
      (or keep a thin push helper with the same signature).
    - Out: detail view (T02), dashboard wiring (T03).
  - Done when: add + edit open as full-screen routes; X closes without saving,
    Save validates + returns the record; no drag-to-dismiss anywhere; **Save is
    reachable without scrolling** (AppBar/sticky — review 2026-08-19: the sheet
    required scrolling to the bottom to save); `dart analyze lib/` clean.
  - Verification notes (commands or checks):
    - `dart analyze lib/src/planner/`; manual: open add/edit, close via X, save.

- [x] T02 `PlannerItemDetailScreen — read-mostly view` (status:done)
  - Task ID: T02
  - Goal: Show a task's full details including the note.
  - Boundaries (in/out of scope):
    - In: new `lib/src/planner/screens/planner_item_detail.dart` — header (title,
      done checkbox, date, times), note (full, scrollable), linked workout tile
      (tap → workout detail where applicable), tags, recurrence summary, Edit
      button (→ T01 form), Delete (confirm → repo delete + invalidate, no
      banner/undo needed here since delete flows elsewhere), invalidate on
      return; new l10n keys en/fr/es.
    - Out: editing fields inline (Edit delegates to the form).
  - Done when: detail opens with every field, note fully readable, Edit opens the
    form, done toggle + delete work and invalidate providers;
    `flutter gen-l10n`; `dart analyze lib/` clean.
  - Verification notes (commands or checks):
    - `dart analyze lib/src/planner/screens/planner_item_detail.dart`.

- [x] T03 `Entry points — planner tile + dashboard row` (status:done)
  - Task ID: T03
  - Goal: Route to the detail view from both surfaces.
  - Boundaries (in/out of scope):
    - In: `planner_screen.dart` tile — tap opens detail (edit affordance opens
      the form); `dashboard.dart` `_TaskRow` — make tappable → detail (keep
      "See all" → `/plan`).
    - Out: any dashboard cards beyond the upcoming-tasks rows.
  - Done when: tapping a task row on the dashboard and a tile on the planner both
    open the detail view; `dart analyze lib/` clean.
  - Verification notes (commands or checks):
    - `dart analyze lib/src/planner/ lib/src/dashboard/screens/dashboard.dart`.

- [x] T04: `Validation and context sync` (status:done)
  - Task ID: T04
  - Goal: Full checks + document the task detail/editor model.
  - Boundaries (in/out of scope): in — analyze/format/tests,
    `context/planner/planner.md` update; out — commit.
  - Done when: `flutter analyze lib` clean; `flutter test` `+39 -4`; context
    accurate.
  - Verification notes (commands or checks):
    - `flutter analyze lib`; `flutter test`;
      `dart format --output=none --set-exit-if-changed lib/src/planner lib/src/dashboard`.

## Validation Report

- **T01** `dart analyze lib/src/planner` clean after converting the bottom
  sheet into `PlannerItemFormScreen` (AppBar X + always-visible Save; add/edit
  callers unchanged via the pushed `showPlannerItemDialog` helper).
- **T02** `flutter gen-l10n` exit 0; new detail view renders every field incl.
  full note + recurrence summary + status-routed workout tile; delete is
  occurrence-safe; edit delegates to the form and keeps reminders in sync.
- **T03** planner tile tap → detail (pencil = edit); dashboard upcoming-tasks
  rows tappable → detail; `dart analyze lib/src/planner lib/src/dashboard` clean.
- **T04** `flutter analyze lib` clean (0 issues); `flutter test` `+42 -4`
  (pre-existing libsqlite3 env failures); touched files format-check 0 changed
  after formatting.

## Next Command

/next-task planner-task-detail T01
