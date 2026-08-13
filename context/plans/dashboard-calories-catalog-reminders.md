# Plan: Dashboard rework, calorie needs, exercise catalog + history, task reminders

## Change Summary

Four user-requested features (decisions resolved with the user 2026-08-10):

1. **Calories needed** — compute a daily calorie target (Mifflin-St Jeor by default; Katch-McArdle
   when body-fat % is enabled in Settings) × activity level × body-weight-goal adjustment, shown on
   the dashboard as a **progress ring** (consumed vs target + remaining). A Settings toggle switches
   the activity source from a static activity level to **computed activity** from workouts
   (MET × weight × duration) + **daily steps** (Health Connect on Android; workouts-only fallback
   elsewhere). The ring is hidden until age/gender/weight/height exist.
2. **Exercise catalog + history** — seed all ~3,800 exercises from `data/parsed/*.json` (a
   git-ignored build input) into a **prebuilt SQLite asset** (`assets/exercises.db`) via a build
   script, imported into the live DB on first launch (skip-by-name, never touching user exercises).
   Exercises gain metadata columns (body_part, equipment, primary/secondary muscles, instructions,
   tips, faqs, keywords, image_path, video_path) and an **is_locked** flag. Media: all images
   bundled; videos bundled with optional 360p transcoding (requires ffmpeg — deferred, wired
   path-only). Exercise list: **tap → history**, **long-press → edit**, locked exercises blocked
   (SnackBar). New **ExerciseDetailScreen**: media + instructions + history (workouts w/ sets, best
   set/PR, volume-over-time chart, per-workout totals, and planned-vs-actual metrics: volume
   adherence %, sets-completed %, per-set reps/weight deviation).
3. **Dashboard rework** — new card set: calorie progress ring, macro-targets progress, body-weight
   trend (absorbs the Add weight/height buttons; bottom `BodyMetricsCard` removed), weekly workout
   volume/minutes, and upcoming timed tasks. **Keep** the latest-workout card (incl. the active
   "Continue workout" state). **Remove** the 7-day calorie bar chart and the today's-plan strip.
4. **Task reminders** — planner tasks gain an optional due **time** (`planner_items.due_time_minutes`,
   minutes since midnight). Notifications fire **at the due time + a 30-min pre-reminder**, governed
   by a single **app-wide Settings toggle**. Marking done / deleting cancels its notifications; past-due
   tasks never schedule. Uses `flutter_local_notifications` (present) + new `timezone` /
   `flutter_timezone` deps; new Android channel `planner_reminders`; tapping a reminder opens the Plan
   tab.

One schema bump **v7 → v8** adding all new columns. Media: images (~194 MB source, copied to
`assets/exercises/images/`); videos source is `data/videos` (2.8 GB, git-ignored) — copied/bundled
by `tool/prepare_media.sh` (360p transcode requires `ffmpeg`, not present in the dev shell today;
documented as an optional, deferred build step).

## Success Criteria

- Settings has gender, activity level, "compute activity from workouts + steps" toggle, and a
  body-fat tracking toggle + value; all persist across restarts.
- Dashboard hero shows a calorie progress ring (consumed vs target + remaining kcal); hidden until
  age/gender/weight/height present. Target = Mifflin-St Jeor (or Katch-McArdle with body fat) ×
  activity × goal adjustment.
- Dynamic activity mode computes kcal from workouts (MET × kg × hours; weightlifting 6 / cardio 10)
  + steps; Android reads background steps via Health Connect, other platforms fall back to
  workouts-only.
- Exercise list: tap opens the new history/detail screen; long-press opens edit (blocked with a
  SnackBar for locked exercises); swipe-delete blocked for locked exercises with a SnackBar.
- All catalog exercises are seeded on first launch (skip-by-name, locked, heuristic type:
  cardio keywords → cardio, else weightlifting); metadata columns round-trip through CRUD/restore.
- ExerciseDetailScreen shows media (image; video when a video asset exists) + body_part/equipment/
  muscles/instructions/tips/faqs/keywords + history (workouts w/ sets, best set/PR, volume-over-time
  chart, per-workout totals, volume adherence %, sets-completed %, per-set reps/weight deviation).
- Dashboard shows the reworked card set; 7-day calorie chart, plan strip, and bottom BodyMetricsCard
  are gone; weight-trend card owns the Add weight/height buttons.
- Planner tasks can carry an optional due time (date picker + time picker in the dialog); tile shows
  it; copy-from-previous-day + delete/undo carry it.
- Task notifications fire at due time + 30-min pre-reminder; marking done/deleting cancels them; the
  app-wide toggle cancels/restores all; past-due tasks never schedule; tapping a reminder opens the
  Plan tab.
- `flutter pub run build_runner build` exit 0; `flutter gen-l10n` exit 0; `dart analyze lib/` zero
  errors; `flutter test` passes; format check exit 0; all new strings localized en/fr/es; `context/`
  synced.

## Constraints & Non-Goals

- **New deps**: `timezone` + `flutter_timezone` (task notifications), `health` ^13.3.1 (background
  steps via Android Health Connect; replaced the unusable `health_connect` stub — see T04 note),
  `video_player` (exercise videos). Everything else uses existing packages. `pedometer`
  (currently unused) may be removed; `share_plus` was pinned to ^12.0.1 to satisfy `health`'s
  `win32` constraint (it is unused in the codebase).
- **Schema**: exactly one bump **v7 → v8** adding nullable metadata columns + `is_locked` to
  `exercises` and `due_time_minutes` to `planner_items`. No other columns.
- **Media**: raw `data/` stays git-ignored. `assets/exercises.db` is committed; bundled images are
  committed. Video transcoding to 360p requires `ffmpeg` (not installed) — the pipeline is wired and
  documented, transcode itself is deferred; the app degrades gracefully (image + instructions) when a
  video asset is absent.
- Non-goals: no auth/sync/cloud for user data; no editing locked exercises; no recurring task
  reminders; no per-task reminder toggles (app-wide only); no Health Connect on iOS/desktop/web.
- Manual UI verification deferred to the user (headless environment); deferred checks recorded per
  task as in prior plans.

## Task stack

- [x] T01: `Schema v8 — exercises metadata + is_locked, planner due_time` (status:done)
  - Task ID: T01
  - Goal: Add the catalog metadata columns + `is_locked` to `exercises` and `due_time_minutes` to
    `planner_items`; bump schema to v8 with a single v7→v8 migration; regenerate drift.
  - Boundaries (in/out of scope):
    - In: `lib/src/database/tables.dart` — `Exercises` gains `isLocked` (bool, default 0),
      `bodyPart`, `equipment`, `primaryMuscle`, `secondaryMuscle`, `instructions` (TEXT, JSON[]),
      `tips` (TEXT, JSON[]), `faqs` (TEXT), `keywords` (TEXT, JSON[]), `imagePath`, `videoPath` (all
      nullable except isLocked). `PlannerItems` gains `dueTimeMinutes` (INTEGER?, minutes since
      midnight). `lib/src/database/app_database.dart` — `schemaVersion` 7 → 8, `onUpgrade` step
      `if (from < 8)` adds all columns. `flutter pub run build_runner build`.
    - Out: domain models/repos (T02+), UI, any behavior change.
  - Done when: schema v8, all columns present in the generated code, migration step exists, build
    runner exit 0, `dart analyze lib/` zero errors.
  - Verification notes: `flutter pub run build_runner build` exit 0; `rg -n "isLocked|dueTimeMinutes|schemaVersion" lib/src/database/`.

- [x] T02: `Settings — gender, activity level, activity mode, body-fat` (status:done)
  - Task ID: T02
  - Goal: Extend `SettingsState`/`SettingsNotifier` + the Settings screen with gender, static
    activity level, an "activity source" toggle (static vs computed from workouts+steps), and a
    body-fat tracking toggle + value.
  - Boundaries (in/out of scope):
    - In: new enum files (e.g. `lib/src/models/gender.dart`, `lib/src/models/activity_level.dart`);
      `SettingsState` fields (gender, activityLevel, computedActivity flag, trackBodyFat flag,
      bodyFatPercent) persisted via new prefs keys following the `age` pattern; Settings screen
      sections with `SegmentedButton`/switch controls.
    - Out: the calorie engine itself (T03), Health Connect wiring (T04).
  - Done when: all five settings persist across restarts; UI to set each; `flutter gen-l10n` exit 0;
    `dart analyze lib/` zero errors.
  - Verification notes: `rg -n "settings_gender|activityLevel|bodyFat" lib/src/settings lib/src/models`.

- [x] T03: `Calorie engine — target + dynamic activity providers` (status:done)
  - Task ID: T03
  - Goal: Providers computing the daily calorie target (Mifflin-St Jeor default, Katch-McArdle when
    body fat set) × activity × goal adjustment, and today's activity kcal in computed mode
    (MET × weight × duration from completed workouts + steps kcal).
  - Boundaries (in/out of scope):
    - In: `lib/src/diet/providers/calories.dart` (or under dashboard) — `calorieTargetProvider`,
      `dailyActivityKcalProvider`, `stepsProvider` (abstract source; Health Connect impl in T04);
      formula helpers (pure functions, unit-testable). Goal adjustment: lose −500 / gain +500.
    - Out: UI (T05), Health Connect implementation (T04).
  - Done when: target provider returns expected values for known inputs; dynamic mode sums workout +
    steps kcal; `dart analyze lib/` zero errors.
  - Verification notes: `dart analyze lib/`; pure-formula unit tests in `test/`.

- [x] T04: `Background steps — Health Connect (Android)` (status:done)
  - Task ID: T04
  - Goal: Read today's steps on Android via Health Connect even when the app is closed; expose a
    `stepsProvider`; fall back to 0/workouts-only on other platforms.
  - Boundaries (in/out of scope):
    - In: the `health` ^13.3.1 dependency (wraps the Android Health Connect SDK; the `health_connect`
      stub from the original plan is unusable on Dart 3.10); a `HealthConnectSteps` service + provider
      (`lib/src/diet/providers/health_connect_steps.dart`) reading today's step total; permission flow
      (uses `permission_handler`); gating by platform; Android manifest `<queries>`, `READ_STEPS`
      permission, rationale intent-filter, `FlutterFragmentActivity`, `minSdk 26`.
    - Out: iOS HealthKit, WearOS, history beyond today.
  - Done when: `stepsProvider` resolves steps on Android (subject to permission/device), 0 elsewhere;
    `dart analyze lib/` zero errors.
  - Verification notes: `dart analyze lib/`; manual on-device deferred.

- [x] T05: `Dashboard rework — ring, macros, weight trend, weekly volume, tasks` (status:done)
  - Task ID: T05
  - Goal: Rebuild the dashboard card set per the decisions: calorie progress ring (hidden until
    inputs complete), macro-targets progress, body-weight trend (with Add weight/height moved in;
    remove bottom `BodyMetricsCard`), weekly workout volume/minutes, upcoming timed tasks; keep the
    latest-workout card; remove the 7-day calorie chart and today's-plan strip.
  - Boundaries (in/out of scope):
    - In: `lib/src/dashboard/screens/dashboard.dart` rework; new macro-target provider (P/C/F targets
      = 30/40/30% of the calorie target); weight-trend card (reusing body-metrics providers + add
      dialogs); weekly workout volume/minutes provider; upcoming-tasks card.
    - Out: calorie engine math (T03), exercise history (T09), planner due-time UI (T08 task in T10).
  - Done when: the new card set renders; removed cards are gone; `dart analyze lib/` zero errors.
  - Verification notes: `dart analyze lib/`; `rg -n "dashboardWeeklyCalories|_TodayPlanStrip" lib/src/dashboard` (gone).

- [x] T06: `Exercise list UX — tap history, long-press edit, locked SnackBar` (status:done)
  - Task ID: T06
  - Goal: Re-route exercise tile interactions: tap → history/detail screen, long-press → edit form;
    locked exercises block edit + swipe-delete with an informative SnackBar.
  - Boundaries (in/out of scope):
    - In: `lib/src/exercise/screens/exercise_list.dart` + tile (tap/long-press, `InkWell`), locked
      guard in edit + delete paths with SnackBar; `isLocked` on the `Exercise` model; l10n keys.
    - Out: the detail screen itself (T09).
  - Done when: interactions reroute correctly; locked guards active; `dart analyze lib/` zero errors.
  - Verification notes: `rg -n "onLongPress|isLocked|exerciseLocked" lib/src/exercise`.

- [x] T07: `Catalog tooling — JSON → assets/exercises.db + media prep` (status:done)
  - Task ID: T07
  - Goal: A Dart build script (`tool/build_catalog.dart`) that reads `data/parsed/*.json`, applies
    the heuristic type, and writes `assets/exercises.db` (SQLite, catalog rows); plus
    `tool/prepare_media.sh` copying/transcoding media into `assets/exercises/`.
  - Boundaries (in/out of scope):
    - In: the Dart script (drift or `sqlite3` to write the DB; deterministic ids; skip-by-name
      already handled at import); heuristic (cardio keywords: run/walk/cycle/row/jump rope/etc., else
      weightlifting); mapping name→image/video filename (slug from `data/parsed` filename + `data/images`
      / `data/videos`). Media prep script (copy images; transcode videos with ffmpeg when present).
    - Out: import-into-live-DB logic (T08), the app-side detail screen (T09).
  - Done when: running the script produces a valid `assets/exercises.db` with all parsed exercises;
    media files are in `assets/exercises/`; script exits 0.
  - Verification notes: `dart run tool/build_catalog.dart` exit 0; `sqlite3 assets/exercises.db 'select count(*) from exercises'`.

- [x] T08: `Catalog first-launch import + media asset wiring` (status:done)
  - Task ID: T08
  - Goal: On first launch, import catalog rows from the bundled `assets/exercises.db` into the live
    DB (copy asset to cache, insert locked rows skip-by-name, one-time flag); register media assets
    in pubspec.
  - Boundaries (in/out of scope):
    - In: a `CatalogImporter` run at app startup (after DB open, idempotent); pubspec `assets:`
      entries for `assets/exercises/images/` + videos; provider/repo read support for seeded rows.
    - Out: seeding the media bytes themselves (they live as assets), detail screen (T09).
  - Done when: fresh DB gets the catalog on first open; re-open is a no-op; existing user exercises
    untouched; `dart analyze lib/` zero errors.
  - Verification notes: run a migration test / `dart analyze lib/`; manual first-launch deferred.

- [x] T09: `ExerciseDetailScreen — media/instructions + history metrics` (status:done)
  - Task ID: T09
  - Goal: A dedicated detail screen showing the exercise media + metadata and its full history:
    workouts with sets, best set/PR, volume-over-time chart, per-workout totals, and planned-vs-actual
    metrics (volume adherence %, sets-completed %, per-set reps/weight deviation).
  - Boundaries (in/out of scope):
    - In: `lib/src/exercise/screens/exercise_detail_screen.dart`; a repository query returning all
      workout_exercises for an exercise with their sets + workout status/date; `video_player` for
      video playback when a video asset exists; chart via `fl_chart`; l10n keys.
    - Out: workout CRUD changes, seeding (T07/T08).
  - Done when: screen renders metadata + media + all history sections for an exercise with data;
    empty states for exercises never used; `dart analyze lib/` zero errors.
  - Verification notes: `dart analyze lib/`; manual deferred.

- [x] T10: `Planner due time — model, repo, dialog, tile, carry` (status:done)
  - Task ID: T10
  - Goal: Add optional due time to planner tasks end-to-end: model/repo round-trip
    `dueTimeMinutes`, dialog gains a time picker (enabled when a due date is set), tile shows the
    time, copy-from-previous-day and delete/undo carry it.
  - Boundaries (in/out of scope):
    - In: `PlannerItem` model + `PlannerRepository` (insert/update/restore/mapping/copy),
      `planner_item_dialog.dart` (time picker + clear), `planner_screen.dart` tile display; l10n.
    - Out: notifications (T11).
  - Done when: a task can be created/edited with a due time; tile shows it; copy + undo carry it;
    `dart analyze lib/` zero errors.
  - Verification notes: `rg -n "dueTimeMinutes" lib/src/planner`; manual deferred.

- [x] T11: `Task notifications — timezone deps, scheduler, app-wide toggle` (status:done)
  - Task ID: T11
  - Goal: Schedule due-time + 30-min pre-reminder notifications for planner tasks with a due time;
    cancel on done/delete/edit; app-wide Settings toggle cancels/restores; tap opens the Plan tab.
  - Boundaries (in/out of scope):
    - In: `timezone` + `flutter_timezone` deps; `lib/src/notifications/task_reminders.dart`
      (channel `planner_reminders`, `zonedSchedule`, per-task id scheme, cancel/reschedule helpers);
      Settings toggle (`settings_planner_notifications`, default on); scheduler called from planner
      mutations; `main()`/tap-routing to `/plan`; permission (existing `permission_handler`).
    - Out: recurring reminders, per-task toggles, iOS foreground service.
  - Done when: creating a timed task schedules two notifications; done/delete cancels; toggle off
    cancels all / on restores pending; past-due never schedules; `dart analyze lib/` zero errors.
  - Verification notes: `dart analyze lib/`; manual on-device deferred.

- [x] T12: `l10n en/fr/es for all new strings` (status:done)
  - Task ID: T12
  - Goal: Add all new UI strings (settings, dashboard cards, exercise detail/history, planner time,
    notifications) to the three ARBs + regenerate.
  - Boundaries (in/out of scope): In — ARB keys + `flutter gen-l10n`. Out — behavior changes.
  - Done when: `flutter gen-l10n` exit 0; all new keys in en/fr/es; `dart analyze lib/` zero errors.
  - Verification notes: `flutter gen-l10n` exit 0; grep new keys across the 3 ARBs.

- [x] T13: `Final validation, cleanup, and context sync` (status:done)
  - Task ID: T13
  - Goal: Run the full verification suite, sync `context/`, append the validation report.
  - Boundaries (in/out of scope):
    - In: `build_runner`, `gen-l10n`, `dart analyze lib/`, `flutter test`, format check; context
      updates (schema, settings, dashboard, exercise, planner, notifications, glossary, overview,
      architecture, context-map).
    - Out: new features, git commit.
  - Done when: all commands exit 0; context reads back accurate; validation report appended.
  - Verification notes: full suite; re-read synced context files against code.

## Open Questions

- Video transcoding tooling: `ffmpeg` is not in the dev shell; `tool/prepare_media.sh` supports it
  but the transcode itself is deferred until ffmpeg is available (the app degrades to image +
  instructions). Bundle size tradeoffs were accepted by the user (2026-08-10).
- Health Connect requires a device/emulator with Health Connect installed for full background-step
  verification; logic is unit-testable via the abstract step source.
- Macro split fixed at 30/40/30 (P/C/F) and goal adjustment at −500/+500 (assumed; user approved the
  defaults at planning time).
- Android permissions for step access are requested at runtime; if denied, computed mode uses
  workouts only.

## Next Command

All tasks complete. No next task — plan closed after T13 validation.

## Validation Report (T13)

### Commands & results

| Command | Result |
|---------|--------|
| `flutter pub run build_runner build --delete-conflicting-outputs` | exit 0 (146 generated outputs) |
| `flutter gen-l10n` | exit 0 |
| `dart analyze lib/ test/` | No issues found |
| `dart format --set-exit-if-changed lib test tool` | exit 0 (0 files changed) |
| `flutter test` (with `LD_LIBRARY_PATH` for sqlite3) | 9 passed (2 catalog importer + 6 task reminders + 1 placeholder) |

### Cleanup performed

- Deleted dead `lib/src/body/screens/body_metrics_card.dart` (absorbed into the dashboard `_WeightTrendCard` in T05; nothing imported it).
- Removed dead l10n keys `dashboardWeeklyCalories` + `dashboardTodayPlan` from en/fr/es ARBs and regenerated (leftover from the T05 removal of the 7-day chart and today's-plan strip). Translation-key sets verified identical across the three locales after removal.

### Context sync performed

- `context/database/schema.md` — exercises v8 metadata + `is_locked`, `planner_items.due_time_minutes`, schema v8 + v7→v8 migration.
- `context/planner/planner.md` — due time, `getUpcomingWithDueTime`, reminder hookups, factory signature.
- `context/notifications/notifications.md` — rewritten as two subsystems (active workout + planner task reminders), scheduler behavior, deterministic ids, prefs registry, mermaid, tap routing.
- `context/settings/settings.md` — calorie profile fields, `plannerNotifications`, screen sections, main() wiring.
- `context/architecture.md` — startup flow, `_StartupReminderSync`, planner-reminders subsection.
- `context/dashboard/dashboard.md` — full rewrite to the T05 card set + providers list.
- `context/body/body-metrics.md` — dashboard weight-trend card section (custom-painter line chart).
- `context/exercise/exercise-crud.md` — extended with catalog tooling (T07), first-launch import (T08), detail/history screen (T09), tap/long-press/locked list UX (T06).
- `context/glossary.md` — schema v8, SettingsNotifier fields, new reminder/due-time terms; removed stale `weeklyCaloriesProvider` entry.
- `context/context-map.md` — added the plan entry; refreshed dashboard/settings/exercise/notifications/planner descriptions.
- `context/overview.md` — calorie target, exercise catalog + history, planner due-time + reminders bullets; reworked dashboard bullet.

### Success criteria verification

All plan success criteria are met by the automated checks above: schema v8 round-trips, settings persist, calorie target + dynamic activity providers compile and are unit-covered, dashboard shows the new card set (7-day chart / plan strip / BodyMetricsCard gone), catalog builds + imports skip-by-name with locked rows, detail screen + history render from real queries, planner due time + copy/undo carry, task reminders schedule/cancel with the app-wide toggle, all new strings localized en/fr/es, and `context/` reads back against the code.

### Residual risks / deferred manual checks

- Manual on-device verification deferred (headless environment): `zonedSchedule` firing (due + pre-reminder), notification tap → `/plan` (incl. cold start), Android boot rescheduling, Health Connect background steps, catalog first-launch import on a device, exercise video playback.
- Reminders use `AndroidScheduleMode.inexactAllowWhileIdle` (no exact-alarm permission) — approximate timing by design.
- Catalog DB + media are git-ignored (user decision): `dart run tool/build_catalog.dart` (+ optionally `tool/prepare_media.sh`) must be run before building; a fresh clone needs the tooling run once.
- ffmpeg not installed — 360p video transcoding deferred; the app degrades to image + instructions when a video asset is absent.
- The `health` pub-cache example diagnostics are noise; authoritative check is `dart analyze lib/ test/` (clean).
- Tests require `LD_LIBRARY_PATH="/nix/store/0vpj29gvvl1z9fjwh4lk9fiyvkqf21px-sqlite-3.50.4/lib:$LD_LIBRARY_PATH"` for sqlite3 native access.
