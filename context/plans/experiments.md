# Plan: Experiments — new tab, daily check-ins, reminders, review

## Change Summary

New feature (review 2026-08-17, brainstormed): a **6th "Experiments" tab** that
lets the user run time-boxed wellness experiments, link them to multiple existing
categories, check in daily (rating + note), and review aggregated data vs a
baseline at the end. A **daily check-in reminder notification** is included.

## Success Criteria

- Schema adds `experiments` + `experiment_checkins` tables with a working
  migration.
- `/experiments` is a real `StatefulShellBranch` tab (science icon).
- Create/edit an experiment: name, hypothesis/purpose, start + end date, status
  (planned/active/done/aborted), linked categories (workout / diet / body /
  steps), reminder toggle + time (default 20:00).
- Detail screen: header + progress, today's check-in (rating 1–5 + note),
  check-in timeline, per linked category aggregates over the range (workout volume
  + adherence, kcal/macros, body-weight series, steps) with `fl_chart`, and an
  end-review vs a 14-day baseline.
- Daily reminder scheduled while active, cancelled on done/aborted/delete; tap →
  `/experiments`.
- l10n en/fr/es; `dart analyze lib/` clean; `flutter test` passes.

## Constraints & Non-Goals

- One schema bump (new tables only, no changes to existing tables).
- Reuses `fl_chart` + `flutter_local_notifications` (no new deps).
- Non-goal: templates/library of experiments, reminders outside the app,
  cross-experiment analytics, data export.

## Task Stack

- [x] T01: `Schema + models + repository` (status:done)
  - Task ID: T01
  - Goal: Add `experiments` (id, name, purpose, startDate, endDate, status,
    categories JSON, reminderEnabled, reminderTimeMinutes, createdAt) and
    `experiment_checkins` (id, experimentId, day, rating, note, createdAt);
    bump schema; regenerate; add domain models + repository (CRUD, check-in
    upsert-per-day, getByDay).
  - Boundaries (in/out of scope):
    - In: `lib/src/database/tables.dart`, `app_database.dart` (version + migration),
      build_runner, new `lib/src/experiments/` (models + repository + providers
      mirroring the planner pattern), `flutter pub run build_runner build`.
    - Out: UI, reminders (later tasks).
  - Done when: tables exist post-migration; CRUD + check-in upsert work; `dart analyze lib/` clean.
  - Verification notes (commands or checks):
    - `flutter pub run build_runner build --delete-conflicting-outputs`; `dart analyze lib/`.

- [x] T02: `Tab + list + form screens` (status:done)
  - Task ID: T02
  - Goal: Add the 6th tab and an experiments list + create/edit form.
  - Boundaries (in/out of scope):
    - In: `lib/src/app/router.dart` (new `StatefulShellBranch` `/experiments`,
      tinted icon `Icons.science_outlined`), `lib/src/app/tabs/` (new tab widget),
      `lib/src/experiments/screens/experiments_screen.dart` (list w/ status badges
      + FAB), `experiment_form_screen.dart` (all fields incl. category multi-select
      + reminder toggle/time), shared l10n keys.
    - Out: detail screen (T03).
  - Done when: the tab exists and navigation works; experiments can be created/
    edited; reminders not yet scheduled (T04); `flutter gen-l10n` exit 0; `dart analyze` clean.
  - Verification notes (commands or checks):
    - `flutter gen-l10n`; `dart analyze lib/src/`.

- [x] T03: `Detail: check-ins + aggregation + review` (status:done)
  - Task ID: T03
  - Goal: Detail screen with today's check-in, timeline, category aggregates, and
    end-review.
  - Boundaries (in/out of scope):
    - In: `lib/src/experiments/screens/experiment_detail_screen.dart` — header/
      progress; today's check-in (rating selector 1–5 + note, saves via repo);
      check-in timeline; per linked category aggregation over [start,end]: workout
      (volume, completed sets ratio vs plan) via `workoutRepositoryProvider`,
      diet (daily kcal avg + macros) via `mealRepositoryProvider`, body (weight
      series) via `bodyMetricsRepositoryProvider`, steps via existing providers;
      `fl_chart` line charts; completed experiments show baseline comparison
      (range avg vs 14 days before start). Empty states per category.
    - Out: reminder scheduling (T04).
  - Done when: check-ins persist; aggregates/charts render from real data; review
    shows baseline comparison; `dart analyze lib/` clean.
  - Verification notes (commands or checks):
    - `dart analyze lib/src/experiments/`.

- [x] T04: `Daily check-in reminder` (status:done)
  - Task ID: T04
  - Goal: Schedule/cancel the daily "check in" notification per experiment.
  - Boundaries (in/out of scope):
    - In: `lib/src/experiments/services/experiment_reminders.dart` — a scheduler
      reusing `flutter_local_notifications` + `timezone` (mirror
      `task_reminders.dart`): `zonedSchedule` daily at `reminderTimeMinutes` while
      active; cancel on done/aborted/delete/disable; deterministic per-experiment
      ids; channel `experiment_checkins`; tap routes to `/experiments`. Wire into
      T02/T03 mutations.
    - Out: multi-day scheduling on iOS nuances (best-effort).
  - Done when: reminder registers/cancels with toggle + status changes; `dart analyze` clean.
  - Verification notes (commands or checks):
    - `dart analyze lib/src/experiments/`.

- [x] T05: `Validation and context sync` (status:done)
  - Task ID: T05
  - Goal: Full checks + context sync (new `context/experiments/`, schema.md,
    architecture.md, context-map.md, overview.md) + validation report.
  - Boundaries (in/out of scope): in — build_runner, gen-l10n, analyze, test,
    format, context; out — commit.
  - Done when: suite green (excluding pre-existing sqlite env tests); context reads
    back accurate.
  - Verification notes (commands or checks):
    - build_runner, gen-l10n, `dart analyze lib/`, `flutter test`, `dart format --output=none --set-exit-if-changed lib test`.

## Next Command

/next-task experiments T01

## Validation Report

Status: ALL TASKS COMPLETE (2026-08-18)

### Checks run

- `flutter pub run build_runner build --delete-conflicting-outputs` — regenerated cleanly (new `Experiments`/`ExperimentCheckins` tables + companions).
- `flutter gen-l10n` — exit 0 (new keys compiled into `AppLocalizations`).
- `dart format lib/src/experiments lib/src/app/tabs/experiments_tab.dart lib/src/app/router.dart lib/src/app/app.dart lib/src/notifications/notification_plugin.dart lib/src/database/tables.dart lib/src/database/app_database.dart lib/src/exercise/repositories/workout_repository.dart lib/src/diet/providers/health_connect_steps.dart lib/src/models/experiment.dart` — clean (12 files reformatted).
- `dart format --output=none --set-exit-if-changed lib` — 10 files in this plan's touched set are format-clean; 18 OTHER files (from earlier plans, e.g. `exercise_detail_screen.dart`, `planner_recurrence.dart`) show pre-existing formatter drift (left untouched to avoid reformatting noise in the dirty worktree).
- `flutter analyze lib` — No issues found.
- `flutter test` — `+39 -4` same as baseline; the 4 failures are the pre-existing DB-backed suites that cannot load `libsqlite3.so` in this environment (catalog_importer, note_repository, others) — unrelated to this plan.

### Success-criteria evidence

| Criterion | Evidence |
| --- | --- |
| Schema: `experiments` + `experiment_checkins`, migration | `tables.dart` new tables; `app_database.dart` `schemaVersion => 18` + `onUpgrade` `from < 18` createTable block |
| `/experiments` real tab | 7th `StatefulShellBranch` in `router.dart`, `Icons.science_outlined` destination, `tabs/experiments_tab.dart` |
| Create/edit form (all fields) | `experiment_form_screen.dart`: name, purpose, start/end (open-ended), status dropdown, category `FilterChip` multi-select, reminder `SwitchListTile` + time picker (default 20:00) |
| Detail: header + progress + today's check-in + timeline + per-category charts + 14-day baseline | `experiment_detail_screen.dart`: `_HeaderCard`, `_ProgressCard`, `_CheckinCard` (1–5 star + note, upsert per day), `_CheckinTimeline`, per-category `_SeriesChart` (workout daily volume, kcal + protein, weight, steps) vs dashed 14-day pre-start baseline |
| Reminder lifecycle + tap routing | `experiments/notifications/experiment_reminder.dart` (channel `experiment_reminders`, deterministic id, `zonedSchedule` + `DateTimeComponents.time`, payload `experiment_reminder`), wired into save/mark-done/abort/delete; tap → `/experiments` via `notification_plugin.dart` |
| l10n en/fr/es | new keys in all three ARBs (tab, list, form, detail, chart, reminder) |

### Realized-notes / deviations (recording for context accuracy)

- Reminder service lives at `lib/src/experiments/notifications/experiment_reminder.dart` (plan text suggested `services/experiment_reminders.dart`; kept alongside `notifications/` peers).
- Added `WorkoutRepository.getDailyVolumes(fromDay)` for per-day workout volume, and `HealthConnectSteps.getDailySteps(from, to)` for the steps chart (best-effort/empty on failure).
- Charts render while the experiment is open (any status); baseline is a dashed mean line over the 14 days before `startDate`; empty categories show `experimentDetailNoData`.
- Status changes via detail-screen buttons (`Mark done` / `Abort`); done stamps `endDate` = now. Deleting happens from the edit form and also cancels the reminder + removes check-ins (repo delete does both in one transaction).
- No commit step (consistent with prior plans). Context files updated in T05: schema.md (v18), schema context-map inventory, overview count, experiment context page added, notification sources, glossary + architecture data-access notes.