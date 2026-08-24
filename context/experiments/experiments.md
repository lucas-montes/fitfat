# FitFat — Experiments

Experiments are **planner items** (schema v24): `planner_items.kind =
'experiment'` rows with a start→end date range, daily check-ins, and
per-category review charts. There is no standalone experiments table or tab —
they surface as the "Experiments" segment of the Planner tab.

## Domain

- **PlannerItem** (`lib/src/models/planner_item.dart`) carries both shapes via
  `PlannerItemKind { task, experiment }`. Experiment-only fields (null/ignored
  for plain tasks): `endDate` (**required** end date; new forms default to one
  week out), `purpose` (hypothesis), `status`
  (`planned` / `active` / `done` / `aborted`), `categories`
  (`workout` / `diet` / `body` / `steps`, JSON `string[]`), `reminderEnabled`,
  `reminderTimeMinutes` (default 20:00). Child tasks link to an experiment via
  their nullable `experimentId`.
- **Experiment** (`lib/src/models/experiment.dart`) survives as a read
  projection over a planner-item row, built by `PlannerRepository`
  (`name` = title, `startDate` = day, plus the columns above).
- **ExperimentCheckin**: id, experimentId (= planner item id), day
  (start-of-day), rating (1..5), optional note. One per experiment per day
  (unique key `(experiment_id, day)`); the repo upserts in place.

## Storage

- No `experiments` table since v24 (`app_database.dart`). The v24 migration
  adds the experiment columns to `planner_items`, copies old `experiments`
  rows over **preserving ids**, rebuilds `experiment_checkins` without its FK,
  and drops `experiments`. Upgrades from <18 raw-SQL-create an empty legacy
  `experiments` first so the copy has a source.
- Status/category codecs live on `models/experiment.dart` extensions
  (`storage`) and in `PlannerRepository` (`_statusFromStorage` etc.).

## Repository

All experiment data flows through `PlannerRepository`
(`lib/src/planner/repositories/planner_repository.dart`):
- `getExperiments()` (newest first), `getExperimentById`,
  `upsertExperiment(Experiment)`, `deleteExperiment` (one transaction:
  detaches linked child tasks, removes check-ins, deletes the row),
- `getLinkedTasks(id)`, `setTaskExperiment(taskId, experimentId?)`,
  `searchTasks(query)` (link-a-task picker; plain tasks only),
- `getByRange(start, end)` (calendar month markers),
- `upsertCheckin(...)`, `getCheckins(...)`.
Day lists (`getByDay`) and copy-from-yesterday exclude experiments.

## Providers

`lib/src/experiments/providers/experiments.dart`:
- `experimentListProvider`, `experimentByIdProvider`,
  `experimentCheckinsProvider`, `experimentLinkedTasksProvider` — all reading
  through `plannerRepositoryProvider`.
- Chart data: `workoutDailyVolumesProvider(from)` →
  `WorkoutRepository.getDailyVolumes` (per-day completed volume),
  `stepsDailyProvider(from)` → `HealthConnectSteps.getDailySteps` (best-effort,
  empty when unavailable). Diet/body reuse `mealListProvider` /
  `bodyMetricsProvider` directly in the chart widgets.

## Screens

- **Planner tab** (`planner_screen.dart`) is now segmented `[Calendar |
  Experiments]`:
  - *Calendar* — `table_calendar` month grid: plain-task days get a dot,
    experiment ranges tint the whole span, selected day fills, today outlines;
    below it the selected day's task list (tap → edit, long-press → detail).
    FAB adds a task.
  - *Experiments* — `ExperimentsView` list (status badge + category chips +
    start date + days elapsed); tap → detail; FAB opens the form.
- `experiment_form_screen.dart` — name (required), purpose, **required** start
  + end date pickers, status dropdown, category `FilterChip` multi-select,
  reminder switch + time picker (default 20:00). Save → `upsertExperiment` +
  reschedule reminder; delete → cancel reminder + `deleteExperiment`.
- `experiment_detail_screen.dart` — header card (name, purpose, status badge,
  category chips, dates, days elapsed); status actions for active experiments
  (Mark done stamps endDate, Abort); today's check-in (1–5 star rating + note,
  upserts per day); progress; **Linked tasks section** (list with unlink +
  searchable `_TaskPickerSheet` that links/unlinks existing planner tasks);
  tracked-data charts per linked category over the range vs a dashed 14-day
  pre-start baseline mean; check-in timeline.
- Router: no `/experiments` route/tab anymore (6 bottom tabs); the check-in
  notification tap routes to `/plan`.

## Reminder notification

Unchanged mechanics (`lib/src/experiments/notifications/
experiment_reminder.dart`): deterministic id per experiment id, daily
`zonedSchedule` at `reminderTimeMinutes` while active + reminders enabled,
cancelled on done/aborted/delete/disable. Callers now pass projections from
`PlannerRepository`; Settings' master toggle lists experiments via it too.

## Key decisions

- Experiments differ from tasks exactly by being a **required date range**
  with status/categories/check-ins — no due date, no recurrence, no
  time-of-day.
- Keeping `Experiment` as a projection meant detail/chart code barely changed
  while the table was fully removed.
- Success criteria verified: `flutter analyze` clean; `flutter test` +49 -2
  (the -2 are the pre-existing `libsqlite3.so` host env failures).
