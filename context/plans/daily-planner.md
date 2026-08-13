# Plan: Daily Planner — per-day todo list for routine tracking

## Change Summary

Add a new "Plan" tab to FitFat that provides a per-day planning/todo list to track the user's daily routine. Each day has its own independent list of simple tasks (title, done state, sort order). Features: day navigation (previous/next arrows + "Today" button), add/edit/delete/toggle tasks, reorder tasks within a day, and "copy from previous day" to carry pending tasks forward. Follows the existing repo pattern: new Drift table + domain model, repository, Riverpod providers, screens, l10n via ARB (en/fr/es), and a 5th `StatefulShellBranch` in the router.

## Success Criteria

- Bottom navigation has a 5th tab "Plan" (localized en/fr/es), inserted between Diet and Settings.
- Each day is independent: navigating between days shows only that day's tasks.
- Task CRUD works: create (FAB + dialog), edit title (tap), toggle done (checkbox), delete (swipe with confirmation).
- Tasks can be reordered within a day; the order persists across restarts.
- "Copy from yesterday" duplicates yesterday's *pending* (unchecked) tasks into today with fresh UUIDs, `done=false`, preserving relative sort order; a SnackBar reports the count copied (or "nothing to copy").
- All data persists across app restarts via the local SQLite database.
- Existing installs migrate from schema v1 → v2 cleanly: the 7 existing tables keep their data and `planner_items` is created.
- `dart analyze lib/` — zero errors; `dart run build_runner build` — clean; `flutter gen-l10n` — clean; `flutter test` — passes.
- All new user-facing strings are localized in en/fr/es ARB files.

## Constraints & Non-Goals

- Per-day free-form tasks only. No reusable routine templates, no task categories, no task times (user decision).
- No notifications/reminders.
- No linking tasks to workouts or meals.
- No Dashboard integration (today's plan is not shown on the Dashboard tab).
- No new dependencies — `ReorderableListView` is part of the Flutter SDK; `uuid` is already used.
- Add/edit uses a lightweight dialog (single text field) instead of a full-screen form — deliberate deviation from the full-screen form pattern, justified by single-field input.
- No new tests beyond keeping the existing suite green (matches the repo's current testing posture).
- Light theme only, no dark mode.

## Assumptions

- Task title is required; uniqueness within a day is not enforced.
- "Copy from previous day" copies only yesterday's unchecked items (carry-over behavior), preserving their relative order.
- A day is stored as start-of-day epoch milliseconds (normalized `DateTime(y,m,d)`); all queries normalize the selected day the same way so each day is a stable key.
- Migration: bump `schemaVersion` 1 → 2 and add an explicit `MigrationStrategy` (`onCreate` → `createAll`, `onUpgrade` → `createTable(plannerItems)` for `from < 2`). Note: current code has no `MigrationStrategy` while `context/database/schema.md` claims "MigrateOnStartup" — fixing this stale note is part of T08.
- Generated row class for `PlannerItems` is `PlannerItem` (Drift default singularization, same as existing tables which do not use `@DataClass`); the domain model in `lib/src/models/planner_item.dart` is also named `PlannerItem`, referenced as `db.PlannerItem` inside the repository via the `as db` import alias (same pattern as the exercise domain).

## Task Stack

---

- [x] T01: `Add PlannerItems table, schema migration, and domain model` (status:done)
  - Task ID: T01
  - Goal: Define the `planner_items` table in Drift, register it in `AppDatabase`, bump the schema to v2 with a `MigrationStrategy`, regenerate drift code, and create the plain `PlannerItem` domain model.
  - Boundaries (in/out of scope):
    - In: `lib/src/database/tables.dart` (new `PlannerItems` table), `lib/src/database/app_database.dart` (register table, `schemaVersion => 2`, `MigrationStrategy`), `lib/src/models/planner_item.dart` (new domain model with `copyWith`).
    - Out: Repository, providers, UI, l10n.
  - Done when:
    - Table exists with columns: `id` (text PK, UUID v7), `date` (integer, start-of-day epoch millis), `title` (text), `done` (integer 0/1), `sort_order` (integer), `created_at` (integer).
    - `schemaVersion` is 2 and an explicit `MigrationStrategy` creates the table on upgrade from v1 without dropping existing data.
    - `PlannerItem` domain model compiles with `copyWith` and a `done` bool + `day` DateTime.
    - `dart analyze lib/src/database/ lib/src/models/` — zero errors.
  - Verification notes (commands or checks):
    - `dart run build_runner build` — exit 0.
    - `dart analyze lib/src/database/ lib/src/models/` — zero errors.
  - Completed: 2026-08-04
  - Files changed:
    - `lib/src/database/tables.dart` (modified — added `PlannerItems` table)
    - `lib/src/database/app_database.dart` (modified — registered table, `schemaVersion => 2`, added `MigrationStrategy`)
    - `lib/src/database/app_database.g.dart` (regenerated — `PlannerItem` DataClass + `plannerItems` table info)
    - `lib/src/models/planner_item.dart` (new — domain model with `copyWith`)
  - Evidence: `flutter pub run build_runner build` — exit 0 (59 outputs). `dart analyze lib/` — "No issues found!". `flutter test` — 1/1 passed. Note: `dart run build_runner build` fails in this Nix env ("Flutter SDK is not available" via dart pub); use `flutter pub run build_runner build` instead.

---

- [x] T02: `Planner repository` (status:done)
  - Task ID: T02
  - Goal: Implement `PlannerRepository` as the Drift DAO for the `planner_items` table, including day-scoped queries, CRUD, sort-order updates, and copy-from-previous-day.
  - Boundaries (in/out of scope):
    - In: `lib/src/planner/repositories/planner_repository.dart` (new).
    - Out: Providers, screens, UI.
  - Done when:
    - Methods exist: `getByDay(DateTime day)` (normalized to start-of-day, ordered by `sort_order`), `insert(PlannerItem)`, `update(PlannerItem)` (title + done), `delete(String id)`, `updateSortOrder(String id, int sortOrder)`, `copyFromPreviousDay(DateTime day)`.
    - `copyFromPreviousDay` copies yesterday's `done == false` items into `day` with fresh UUID v7 ids, `done=false`, preserving relative sort order, and returns the number copied.
    - Factory helper `newPlannerItem({required DateTime day, required String title, int sortOrder = 0})` exists (mirrors `newExercise`).
    - `dart analyze lib/src/planner/` — zero errors.
  - Verification notes (commands or checks):
    - `dart analyze lib/src/planner/repositories/` — zero errors.
  - Completed: 2026-08-04
  - Files changed:
    - `lib/src/planner/repositories/planner_repository.dart` (new — `PlannerRepository` + `newPlannerItem` factory)
  - Evidence: `dart analyze lib/src/planner/` — "No issues found!". `dart analyze lib/` — "No issues found!". `flutter test` — 1/1 passed. No codegen needed (no schema change).

---

- [x] T03: `Planner providers` (status:done)
  - Task ID: T03
  - Goal: Add Riverpod providers for the planner repository and per-day task lists.
  - Boundaries (in/out of scope):
    - In: `lib/src/planner/providers/planner.dart` (new) with `plannerRepositoryProvider` and `plannerItemsProvider` as a `FutureProvider.family<List<PlannerItem>, DateTime>` that watches the repository.
    - Out: Screens, UI.
  - Done when:
    - `plannerRepositoryProvider` returns a `PlannerRepository` built on `databaseProvider`.
    - `plannerItemsProvider(day)` returns that day's tasks and reacts to `ref.invalidate`.
    - `dart analyze lib/src/planner/providers/` — zero errors.
  - Verification notes (commands or checks):
    - `dart analyze lib/src/planner/providers/` — zero errors.
  - Completed: 2026-08-04
  - Files changed:
    - `lib/src/planner/providers/planner.dart` (new — `plannerRepositoryProvider`, `plannerItemsProvider` family)
  - Evidence: `dart analyze lib/src/planner/` — "No issues found!". `dart analyze lib/` — "No issues found!". `flutter test` — 1/1 passed.

---

- [x] T04: `Planner l10n strings (en/fr/es) + gen-l10n` (status:done)
  - Task ID: T04
  - Goal: Add all planner UI strings to the three ARB files and regenerate the l10n classes.
  - Boundaries (in/out of scope):
    - In: `lib/l10n/app_en.arb`, `lib/l10n/app_fr.arb`, `lib/l10n/app_es.arb` (new planner keys), `flutter gen-l10n` output.
    - Out: Any Dart code changes.
  - Done when:
    - New keys present in all 3 ARB files: `tabPlan`, `plannerAppBar`, `plannerToday`, `plannerEmpty`, `plannerTaskLabel`, `plannerTaskHint`, `plannerTaskRequired`, `plannerAddTask`, `plannerEditTask`, `plannerDeleteTitle`, `plannerDeleteConfirm` (placeholder `title`), `plannerCopyPrevious`, `plannerCopyConfirmTitle`, `plannerCopyConfirmBody` (+ `_plural`, placeholder `count`), `plannerCopyNothing`, `plannerCopyDone` (+ `_plural`, placeholder `count`).
    - Reuse existing `commonCancel`, `commonDelete`, `commonSave`, `errorWithMessage`.
    - `flutter gen-l10n` — exit 0; generated files updated.
  - Verification notes (commands or checks):
    - `flutter gen-l10n` — exit 0.
    - Generated `app_localizations*.dart` contain the new getters.
  - Completed: 2026-08-04
  - Files changed:
    - `lib/l10n/app_en.arb`, `lib/l10n/app_fr.arb`, `lib/l10n/app_es.arb` (modified — added `tabPlan` + planner block with plurals)
    - `lib/l10n/app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_fr.dart`, `app_localizations_es.dart` (regenerated)
  - Evidence: `flutter gen-l10n` — exit 0. Generated getters present (`tabPlan`, `plannerCopyDone(int count)`, etc.). `dart analyze lib/` — "No issues found!". `flutter test` — 1/1 passed.

---

- [x] T05: `Add Plan tab to navigation shell` (status:done)
  - Task ID: T05
  - Goal: Add the 5th "Plan" tab to the GoRouter shell and bottom navigation, with a placeholder tab screen.
  - Boundaries (in/out of scope):
    - In: `lib/src/app/router.dart` (new `StatefulShellBranch` with `GoRoute '/plan'`, inserted before Settings), `lib/src/app/tabs/plan_tab.dart` (new placeholder), nav `NavigationDestination` using `Icons.checklist_outlined` / `Icons.checklist` and label `l10n.tabPlan`.
    - Out: The real planner screen (T06), any business logic.
  - Done when:
    - App renders 5 tabs; tapping "Plan" shows the placeholder tab; other tabs unchanged.
    - `dart analyze lib/src/app/` — zero errors.
  - Verification notes (commands or checks):
    - `dart analyze lib/src/app/` — zero errors.
    - `flutter run` — 5 destinations visible, Plan tab navigates.
  - Completed: 2026-08-04
  - Files changed:
    - `lib/src/app/router.dart` (modified — added `/plan` branch before Settings + `NavigationDestination` with checklist icons and `l10n.tabPlan`)
    - `lib/src/app/tabs/plan_tab.dart` (new — placeholder `PlanTab`)
  - Evidence: `dart analyze lib/src/app/` — "No issues found!". `dart analyze lib/` — "No issues found!". `flutter test` — 1/1 passed. `flutter run` manual check not possible in headless env (deferred to T08 validation).

---

- [x] T06: `Planner screen core: day navigation + task list + add/edit dialog` (status:done)
  - Task ID: T06
  - Goal: Replace the Plan placeholder with the daily planner screen: day navigation header, task list with toggle and swipe-to-delete, FAB + add/edit dialog.
  - Boundaries (in/out of scope):
    - In: `lib/src/planner/screens/planner_screen.dart` (new, `ConsumerStatefulWidget` holding a selected day normalized to start-of-day, default today), `lib/src/planner/screens/planner_item_dialog.dart` (new, `showPlannerItemDialog` returning the entered non-empty title), update `lib/src/app/tabs/plan_tab.dart` to show `PlannerScreen`.
    - In: AppBar title, day-nav header (chevron-left / localized date label / chevron-right / "Today" button), `ListView` of task tiles (checkbox toggles done, tap opens edit dialog, `Dismissible` swipe-to-delete with confirmation dialog), empty state, FAB add.
    - Out: Reorder (T07), copy-from-previous-day (T07). The list is a plain `ListView` in this task.
  - Done when:
    - Selecting a day via arrows or "Today" reloads that day's tasks.
    - Add, edit, toggle, and swipe-delete all persist and the list refreshes (`ref.invalidate(plannerItemsProvider(selectedDay))`).
    - All strings come from `AppLocalizations`; `dart analyze lib/` — zero errors.
  - Verification notes (commands or checks):
    - `dart analyze lib/src/planner/` — zero errors.
    - Manual: add 2 tasks, toggle one, edit a title, delete one; navigate to another day and back — state persists.
  - Completed: 2026-08-04
  - Files changed:
    - `lib/src/planner/screens/planner_screen.dart` (new — `PlannerScreen` with day nav, task list, toggle/edit/delete, FAB)
    - `lib/src/planner/screens/planner_item_dialog.dart` (new — `showPlannerItemDialog` with validation)
    - `lib/src/app/tabs/plan_tab.dart` (modified — renders `PlannerScreen` instead of placeholder)
  - Evidence: `dart analyze lib/src/planner/ lib/src/app/tabs/` — "No issues found!". `dart analyze lib/` — "No issues found!". `flutter test` — 1/1 passed. Manual run deferred to T08 validation.

---

- [x] T07: `Reorder tasks + copy from previous day` (status:done)
  - Task ID: T07
  - Goal: Add drag-to-reorder within a day and the "copy from previous day" action to the planner screen.
  - Boundaries (in/out of scope):
    - In: `planner_screen.dart` — convert the list to `ReorderableListView.builder` with `onReorder` persisting the new order via `repository.updateSortOrder` for each affected item; add an AppBar "Copy from yesterday" action that confirms, calls `repository.copyFromPreviousDay(day)`, and shows a SnackBar (`plannerCopyDone(count)` or `plannerCopyNothing`).
    - Out: Auto-copy on day change, recurring templates, changes outside `planner_screen.dart`.
  - Done when:
    - Dragging a task reorders it and the order survives restart.
    - Copy action duplicates yesterday's pending tasks into today and reports the count; with nothing pending it shows "nothing to copy" without creating rows.
    - `dart analyze lib/` — zero errors.
  - Verification notes (commands or checks):
    - `dart analyze lib/src/planner/` — zero errors.
    - Manual: reorder 3 tasks, restart app, order kept; seed yesterday with 2 pending + 1 done, copy, verify only the 2 pending arrive in today.
  - Completed: 2026-08-04
  - Files changed:
    - `lib/src/planner/screens/planner_screen.dart` (modified — `ReorderableListView.builder` + `_reorderItems`, AppBar copy action + `_copyFromPreviousDay`, `_addItem` now appends with `max(sortOrder)+1`)
  - Evidence: `dart analyze lib/src/planner/` — "No issues found!". `dart analyze lib/` — "No issues found!". `flutter test` — 1/1 passed. Manual run deferred to T08 validation. Companion fix (flagged during review): `_addItem` assigns `max(sortOrder)+1` so appended tasks keep deterministic order.

---

- [x] T08: `Final validation, cleanup, and context sync` (status:done)
  - Task ID: T08
  - Goal: Run the full verification suite, confirm success criteria, remove any placeholder/dead code, and sync `context/` so it reflects the new current state.
  - Boundaries (in/out of scope):
    - In: Verification commands, cleanup of leftover placeholder text, context updates.
    - Out: New features, refactors beyond the planner scope.
  - Done when:
    - `dart run build_runner build` — exit 0.
    - `flutter gen-l10n` — exit 0.
    - `dart analyze lib/` — zero errors.
    - `flutter test` — passes.
    - Manual checklist from success criteria passes (day nav, CRUD, reorder, copy, persistence, v1→v2 migration keeps existing data).
    - Context synced:
      - `context/database/schema.md` — add `planner_items` section, change table count to 8, fix the stale migration note (explicit `MigrationStrategy`, `schemaVersion` 2).
      - `context/planner/planner.md` — new domain doc (table, repository API, providers, screens, workflow).
      - `context/context-map.md` — add `plans/daily-planner.md` and `planner/planner.md` rows.
      - `context/architecture.md` — add `/plan` branch to the nav diagram (5 branches) and note 8 tables.
      - `context/glossary.md` — `AppDatabase` entry: "7 tables" → 8.
      - `context/overview.md` — "4 tabs" → 5.
  - Verification notes (commands or checks):
    - Commands above all exit 0; `git status` shows only intended files.
    - Re-read synced context files to confirm accuracy against code.
  - Completed: 2026-08-05
  - Files changed:
    - `context/architecture.md` (modified — `/plan` branch in nav diagram, 8 tables note, key-files table cleanup)
    - `context/context-map.md` (modified — `plans/daily-planner.md` + `planner/planner.md` rows)
    - `context/database/schema.md` (modified — `planner_items` section, 8 tables, fixed migration note)
    - `context/glossary.md` (modified — `AppDatabase` 8 tables, `PlannerItem`/`planner_items` entries)
    - `context/overview.md` (modified — 5 tabs)
    - `context/planner/planner.md` (new — domain doc; cleaned stale "plain ListView" + "Up next" lines)
  - Evidence: `flutter pub run build_runner build` — exit 0 (0 outputs, up to date). `flutter gen-l10n` — exit 0. `dart analyze lib/` — "No issues found!". `flutter test` — 1/1 passed. `git status` — only intended files. Manual runtime checklist (day nav, CRUD, reorder persistence, copy, v1→v2 migration) deferred to the user — headless env, no `flutter run`.

---

## Open Questions

None. All scope decisions were clarified with the user (placement, task model, feature set) and recorded in Assumptions.

## Next Command

```
Plan complete — all 8 tasks (T01–T08) are done. Run sce-validation to produce the final validation report before closing out.
```

---

## Validation Report

### Commands run
- `flutter pub run build_runner build` -> exit 0 (0 outputs — codegen up to date)
- `flutter gen-l10n` -> exit 0 (options from `l10n.yaml`; localizations regenerated)
- `dart analyze lib/` -> exit 0 ("No issues found!")
- `flutter test` -> exit 0 (1/1 passed — `test/placeholder_test.dart`)
- `dart format --output=none --set-exit-if-changed lib/ test/` -> exit 0 (49 files, 0 changed)
- `git status --short` -> only intended files; `context/tmp/` empty (no scaffolding)

### Success-criteria verification
- [x] 5th "Plan" tab, localized en/fr/es, between Diet and Settings -> `lib/src/app/router.dart` inserts the `/plan` branch before `/settings`; `NavigationDestination` uses `Icons.checklist_outlined`/`Icons.checklist` + `l10n.tabPlan`; `tabPlan` present in `app_{en,fr,es}.arb`. `context/overview.md` (5 tabs) + `context/architecture.md` (5-branch nav diagram) updated.
- [x] Each day is independent -> `PlannerRepository.getByDay` normalizes to start-of-day and filters by day; analyzer clean. Runtime check deferred (headless).
- [x] Task CRUD (FAB + dialog create, tap edit, checkbox toggle, swipe-delete with confirmation) -> `planner_screen.dart` + `planner_item_dialog.dart`; analyzer clean.
- [x] Reorder within a day persists -> `ReorderableListView.builder` + `updateSortOrder` per changed index; analyzer clean. Runtime restart check deferred.
- [x] Copy from yesterday -> `copyFromPreviousDay` copies only `done == false` items with fresh UUID v7 ids, preserves relative order, returns count; SnackBar `plannerCopyDone(count)` / `plannerCopyNothing`. Runtime check deferred.
- [x] Data persists across restarts -> Drift `planner_items` table in local SQLite. Runtime check deferred.
- [x] v1 → v2 migration keeps existing data -> `schemaVersion => 2` + explicit `MigrationStrategy` (`onCreate: createAll()`; `onUpgrade: createTable(plannerItems)` for `from < 2`). Runtime migration check deferred.
- [x] `dart run build_runner build` clean -> `flutter pub run build_runner build` exit 0 (Nix env requires `flutter pub run`).
- [x] `flutter gen-l10n` clean -> exit 0.
- [x] `dart analyze lib/` zero errors -> "No issues found!".
- [x] `flutter test` passes -> 1/1 passed.
- [x] All new user-facing strings localized en/fr/es -> `planner*` + `tabPlan` keys in all three ARB files.

### Failed checks and follow-ups
- None. All automated checks pass.

### Residual risks
- Manual runtime validation not executed (headless environment, no `flutter run`). Deferred checklist for the user:
  - Day navigation: arrows and "Today" reload the correct day's tasks.
  - CRUD: add 2 tasks, toggle one, edit a title, delete one; navigate to another day and back — state persists.
  - Reorder 3 tasks, restart the app — order kept.
  - Seed yesterday with 2 pending + 1 done, run copy — only the 2 pending arrive in today with correct SnackBar count; with none pending, "nothing to copy" and no rows created.
  - v1→v2 migration: launch with existing data — the 7 prior tables keep their data and `planner_items` is created.
- Changes are uncommitted (repo policy — commit only when requested).
