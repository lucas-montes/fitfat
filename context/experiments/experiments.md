# FitFat — Experiments

Experiments tab (schema v18): time-boxed self-tracking experiments with daily
check-ins and per-category review charts.

## Domain

- **Experiment** (`lib/src/models/experiment.dart`): id, name, optional purpose
  (hypothesis), startDate (start-of-day, inclusive), optional endDate (null =
  open-ended), status (`planned` / `active` / `done` / `aborted`), linked
  categories (`workout` / `diet` / `body` / `steps`), `reminderEnabled`,
  `reminderTimeMinutes` (default 20:00), createdAt.
- **ExperimentCheckin**: id, experimentId, day (start-of-day), rating (1..5),
  optional note, createdAt. One per experiment per day (unique key
  `(experiment_id, day)`); the repo upserts in place.

## Storage

- `experiments` + `experiment_checkins` tables in `lib/src/database/tables.dart`;
  schema v18 (`app_database.dart`), migration `from < 18` creates both tables
  (new tables only — no existing-table changes).
- Status and categories are stored as plain text / JSON `string[]`; the
  repository maps them to enums (`_statusFromStorage` / `_decodeCategories`).
- `ExperimentRepository` (`lib/src/experiments/repositories/experiment_repository.dart`):
  `getAll` (newest first), `getById`, `insert`, `update`, `delete` (removes
  check-ins + experiment in one transaction), `upsertCheckin`, `getCheckins`
  (chronological).

## Providers

`lib/src/experiments/providers/experiments.dart`:
- `experimentRepositoryProvider`, `experimentListProvider`,
  `experimentByIdProvider`, `experimentCheckinsProvider`.
- Chart data: `workoutDailyVolumesProvider(from)` →
  `WorkoutRepository.getDailyVolumes` (per-day completed volume),
  `stepsDailyProvider(from)` → `HealthConnectSteps.getDailySteps` (best-effort,
  empty when unavailable). Diet/body reuse `mealListProvider` /
  `bodyMetricsProvider` directly in the chart widgets.

## Screens

- `experiments_screen.dart` — list, newest first; status badge + category chips
  + start date + days elapsed; FAB → form.
- `experiment_form_screen.dart` — name (required), purpose, start/end date
  (open-ended allowed), status dropdown, category `FilterChip` multi-select,
  reminder switch + time picker (default 20:00). Save → `insert`/`update` +
  reschedule reminder; delete (edit mode only, confirm dialog) → cancel reminder
  + `delete` (removes check-ins too).
- `experiment_detail_screen.dart` — header card (name, purpose, status badge,
  category chips, dates, days elapsed); status actions for active experiments
  (Mark done stamps `endDate = now`, Abort); today's check-in (1–5 star rating +
  note, upserts per day, updates existing); progress (linear % when dated,
  check-in count); tracked-data section with one `_SeriesChart` per linked
  category over the experiment period vs a dashed 14-day pre-start baseline mean;
  check-in timeline (newest first, rating pill). Empty categories show
  `experimentDetailNoData`.

## Reminder notification

`lib/src/experiments/notifications/experiment_reminder.dart` — daily check-in
reminder via the shared `flutterLocalNotificationsPlugin`:
- Android channel `experiment_reminders`; payload `experiment_reminder` (tap →
  `/experiments`, wired in `notification_plugin.dart`).
- `ExperimentReminderScheduler.scheduleForExperiment` uses `zonedSchedule` +
  `DateTimeComponents.time` at `reminderTimeMinutes`, only while the experiment
  is **active** with reminders enabled (otherwise it cancels). Deterministic id
  (stable FNV-1a hash of the experiment id) so edits reschedule in place.
- `cancelForExperiment` on done/aborted/delete/disable.

## Key decisions

- One schema bump; charts reuse existing queries (no per-day loops) — workouts
  via `getDailyVolumes`, diet/body via existing list providers.
- Reminders fire only for active experiments; a planned experiment with the
  toggle on schedules once it is started.
- Success criteria verified: `flutter analyze lib` clean; `flutter test`
  `+39 -4` (the 4 failures are the pre-existing `libsqlite3.so` env failures).
