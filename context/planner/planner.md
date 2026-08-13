# FitFat — Planner (Daily Todo)

Per-day planning/todo list for tracking the user's daily routine. Lives in `lib/src/planner/`.

## Current state

Implemented so far (plan: `plans/daily-planner.md`):

- `planner_items` table + schema v2 migration (T01) — see [database/schema.md](../database/schema.md)
- `PlannerItem` domain model (`lib/src/models/planner_item.dart`)
- `PlannerRepository` (`lib/src/planner/repositories/planner_repository.dart`)
- Riverpod providers (`lib/src/planner/providers/planner.dart`)
- Planner l10n strings in en/fr/es ARB files (`tabPlan` + `planner*` keys)
- "Plan" tab wired into the navigation shell (5th branch)
- Planner screen: `PlannerScreen` + `showPlannerItemDialog` (day navigation, toggle, edit, swipe-delete, FAB, drag-to-reorder, copy from previous day)
- Optional task due date (app-improvements T05): data + display only — no reminders/scheduling
- Optional task due **time** (schema v8): due-date + time picker in the dialog, tile subtitle shows date + alarm time, carried by copy-from-previous-day and delete+undo, and drives the task-reminder notifications (see [notifications/notifications.md](../notifications/notifications.md))
- Optional free-text task notes (app-polish-batch T04, schema v6): entered/edited in the add/edit dialog, shown under the task title, carried by copy-from-previous-day and delete+undo
- Day swipe (app-polish-batch T05): the day body is an infinite horizontal `PageView` — swiping left/right changes the selected day; the chevrons + Today button animate the same pager; a swipe starting on a task tile still deletes it (`Dismissible` wins on tiles)

## Domain model

`PlannerItem` (`lib/src/models/planner_item.dart`):

| Field | Type | Notes |
|-------|------|-------|
| id | String | UUID v7 |
| day | DateTime | start-of-day |
| title | String | required |
| done | bool | persisted as `0`/`1` |
| sortOrder | int | display order within the day |
| dueDate | DateTime? | optional due date (v3 `due_date`, epoch millis) |
| dueTimeMinutes | int? | optional due time-of-day (v8 `due_time_minutes`), minutes since midnight; meaningful with `dueDate`; drives reminders |
| notes | String? | optional free-text note (v6 `notes`); trimmed, empty → null |
| createdAt | DateTime | |

## Repository API

`PlannerRepository` (`lib/src/planner/repositories/planner_repository.dart`) wraps the `planner_items` table:

- `getByDay(DateTime day)` — items for a day, normalized to start-of-day, ordered by `sort_order`
- `getUpcomingWithDueTime(DateTime from)` — pending tasks with a due time, due on/after `from` (inclusive), ordered by due date then due time; feeds the dashboard's upcoming-tasks card and the reminder rescheduler
- `insert(PlannerItem)`
- `update(PlannerItem)` — writes `title` + `done` + `due_date` + `due_time_minutes` + `notes` (sort changes go through `updateSortOrder`)
- `delete(String id)`
- `restore(PlannerItem)` — re-inserts a deleted item with its original id (T06); delegates to `insert`
- `updateSortOrder(String id, int sortOrder)` — used by drag-to-reorder
- `copyFromPreviousDay(DateTime day)` — copies yesterday's unchecked (`done == false`) items into `day` with fresh UUID v7 ids and `done=false`, preserving relative `sort_order` and carrying `due_date` + `due_time_minutes` + `notes`; returns the number copied (0 when nothing pending)

Factory: `newPlannerItem({required DateTime day, required String title, int sortOrder = 0, DateTime? dueDate, int? dueTimeMinutes, String? notes})` — fresh UUID v7, `day` normalized to start-of-day.

## Providers

`lib/src/planner/providers/planner.dart`:

- `plannerRepositoryProvider` — `Provider<PlannerRepository>` built on `databaseProvider`.
- `plannerItemsProvider` — `FutureProvider.family<List<PlannerItem>, DateTime>`; keyed by the (normalized) day, calls `getByDay(day)`. Screens refresh it with `ref.invalidate(plannerItemsProvider(day))` after mutations.

## Screens

- `lib/src/planner/screens/planner_screen.dart` — `PlannerScreen` (`ConsumerStatefulWidget`). Holds the selected day (start-of-day, default today). Layout: AppBar (`plannerAppBar`), day-nav header (chevron-left with `plannerPreviousDay` tooltip / `MaterialLocalizations.formatMediumDate` label / chevron-right with `plannerNextDay` tooltip / "Today" button, disabled on today), day-body `PageView`, FAB add.
- Task tile: checkbox toggles `done` (strikethrough style when done; fires `Haptics.selection`, T04), tapping the tile opens the edit dialog, swipe-to-delete → hard `delete` + `plannerDeleted(title)` SnackBar with Undo (`commonUndo`) → `restore(PlannerItem)` + invalidate; no confirm dialog (T07); `Haptics.mediumImpact` on delete (T04).
- List is a `ReorderableListView.builder` — drag to reorder; `_reorderItems` persists the new order by writing each changed item's `sort_order` (index) via `updateSortOrder`, then invalidates.
- Day body (T05): an infinite horizontal `PageView.builder` anchored at `DateTime(2000)` (index = whole-day offset from the anchor, computed with UTC day arithmetic so DST cannot skew the index/initial page). Each page is a `_DayPage` (`ConsumerWidget`) that watches `plannerItemsProvider(day)` for its own day and renders the loading/error/empty/`ReorderableListView.builder` of tiles. `onPageChanged` updates `_selectedDay`; `_previousDay`/`_nextDay`/`_goToday` animate the pager (`animateToPage`, 250 ms easeOutCubic). Horizontal drags starting on a tile are claimed by the tile's endToStart `Dismissible` (delete); drags elsewhere change the day.
- Empty day = `EmptyState` (`event_note`, `emptyPlanner*` ARB keys) with a CTA that opens the add-task dialog (`_addItem`) (T03).
- AppBar copy action: peeks yesterday's pending items via `getByDay(yesterday)`; if none → SnackBar `plannerCopyNothing` (no rows created); else confirms with the pending count, calls `copyFromPreviousDay(day)`, and shows SnackBar `plannerCopyDone(copied)`.
- New tasks are appended with `sort_order = max(existing) + 1` so order stays deterministic.
- Task tile shows a due subtitle when `dueDate` is set (event icon + `MaterialLocalizations.formatMediumDate`) and, when `dueTimeMinutes` is set, an alarm icon + `MaterialLocalizations.formatTimeOfDay` next to it; a free-text notes subtitle line (`maxLines: 2`, ellipsis, `onSurfaceVariant`) renders when `notes` is non-empty (T04).
- `lib/src/planner/screens/planner_item_dialog.dart` — `showPlannerItemDialog(context, {dialogTitle, initialTitle, initialDueDate, initialDueTimeMinutes, initialNotes})` returns a `(String title, DateTime? dueDate, int? dueTimeMinutes, String? notes)` record or `null` on cancel; inline validation with `plannerTaskRequired`. Due-date row: `showDatePicker` (2020–2035), defaults to `initialDueDate`, clear button (`plannerDueDateClear`) → null (also clears the time). Due-time row: `showTimePicker`, disabled when no due date is set, clear button (`plannerDueTimeClear`) → null. Notes: multiline `TextField` (`plannerNotesLabel`, `maxLines: 3`). Add flow passes `initialDueDate: _selectedDay`; edit passes the item's current values.
- Mutations call the repository then `ref.invalidate(plannerItemsProvider(_selectedDay))`.
- **Task reminders (T11)** — every mutation keeps notifications in sync via `TaskReminderScheduler` (`lib/src/notifications/task_reminders.dart`), gated on the app-wide `plannerNotifications` setting: add/undo/copy → schedule; edit → cancel + re-schedule (so a cleared time drops its reminders); toggle-done → cancel on done, cancel + re-schedule on un-done; delete → cancel. The dialog's time picker prompts for the notification permission on Android 13+/iOS at user-initiated scheduling time.

## Key semantics

- A "day" is stored as start-of-day epoch milliseconds (`DateTime(y,m,d)`); all queries normalize via the shared `_startOfDay` helper so each day is a stable key.
- Copy carries over only pending items (carry-over behavior) and never touches the source day.

See also: [overview.md](../overview.md), [context-map.md](../context-map.md)
