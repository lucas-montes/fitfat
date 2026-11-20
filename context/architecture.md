# FitFat — Architecture

## App Shell (T01)

The app uses a single-activity, multi-tab structure built with GoRouter's `StatefulShellRoute.indexedStack`.

### Navigation

```
MaterialApp.router
 └─ GoRouter
     ├─ StatefulShellRoute.indexedStack
     │    ├─ StatefulShellBranch: /dashboard  → DashboardTab
     │    ├─ StatefulShellBranch: /exercise   → ExerciseTab
     │    ├─ StatefulShellBranch: /diet       → DietTab
     │    ├─ StatefulShellBranch: /plan       → PlanTab → PlannerScreen
     │    ├─ StatefulShellBranch: /notes      → NotesTab → NotesScreen
     │    └─ StatefulShellBranch: /budget     → BudgetTab → BudgetScreen
     └─ GoRoute: /active-workout → ActiveWorkoutScreen   (outside the shell)
     └─ GoRoute: /workout-summary/:id → WorkoutSummaryScreen   (outside the shell)
```

Bottom navigation uses Material 3 `NavigationBar`. Tab state is preserved when switching via `indexedStack`.

**Lazy branches (perf, 2026-08-22):** the shell's `IndexedStack` constructs every branch up front, so each tab's root widget is wrapped in `DeferredBranch` (`lib/src/app/deferred_branch.dart`): a branch builds only when first selected (the shell provides its current index via the `BranchVisibility` InheritedWidget) and stays alive afterwards — cold start fires only the dashboard's providers; visited tabs keep their state. Deep links into a non-dashboard branch build that branch immediately (it is the current one).

### Theme & Settings

- Material 3 with teal seed color; design system in `lib/src/ui/` (tokens, `FitFatColors` theme extension, shared widgets) — see [ui/design-system.md](ui/design-system.md)
- Tuned light + dark themes (`FitFatTheme.light` / `FitFatTheme.dark` in `lib/src/app/theme.dart`) with component themes; dark mode uses a teal-tinted surface family; cards = `surfaceContainerLow`; switched via `ThemeMode` (system/light/dark)
- App-level settings (theme mode, language en/fr/es, calorie profile: age/gender/activity/body-fat, body-weight goal, app-wide task-reminder toggle) live in `lib/src/settings/` and persist via `shared_preferences` — see [settings.md](settings/settings.md)
- `FitFatApp` is a `ConsumerWidget` watching `settingsProvider`; `MaterialApp.router` gets `theme`, `darkTheme`, `themeMode`, `locale` and mounts the one-shot `_StartupReminderSync` via `builder`
- `main.dart` awaits `SharedPreferences.getInstance()`, overrides `sharedPreferencesProvider` + `taskReminderSchedulerProvider` inside `ProviderScope`, and opts into Android edge-to-edge (`SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge)`)

### Key files

| File | Purpose |
|------|---------|
| `lib/main.dart` | App entry point: loads `SharedPreferences`, overrides `sharedPreferencesProvider` + `taskReminderSchedulerProvider`, runs `ProviderScope`; opts into Android edge-to-edge (`SystemUiMode.edgeToEdge`); initializes the foreground-service channel + registers the notification tap-routing `addTaskDataCallback` (T06); initializes `timezone` (`FlutterTimezone.getLocalTimezone`) + the `flutter_local_notifications` plugin for planner reminders with tap→`/plan` routing (T11) |
| `lib/src/app/app.dart` | `ConsumerWidget` — `MaterialApp.router` wired with theme/darkTheme/themeMode/locale; `builder` mounts `_StartupReminderSync` (one-shot task-reminder reschedule, l10n-aware, T11) |
| `lib/src/app/router.dart` | GoRouter config + `_ShellWithNavBar` |
| `lib/src/app/theme.dart` | Tuned light + dark themes, component themes, registers `FitFatColors` |
| `lib/src/ui/` | Design system: `tokens.dart`, `theme_extensions.dart`, `widgets/` (StatusBadge, EmptyState, MetricCard) |
| `lib/src/app/tabs/*.dart` | Tab screens (Dashboard, Exercise, Diet, Plan, Notes, Budget, Experiments) |

### GoRouter shell behavior

Each tab branch is a `StatefulShellBranch`. Tapping the same tab again resets it to its initial location. The `_ShellWithNavBar` widget renders the `NavigationBar` and delegates body rendering to `StatefulNavigationShell`. Branch switching from *inside* a tab (e.g. the dashboard quick chips / plan strip) uses `context.go('/other-branch-path')` — go_router 15's `StatefulShellRoute` switches the active branch when `go` targets a route inside another branch, so no shell reference needs to be threaded down.

- **Global active-workout bar (T08)**: `_ShellWithNavBar` is a `ConsumerWidget` that watches `activeWorkoutProvider` (in `lib/src/exercise/providers/workouts.dart`) and renders the floating bar (private `_ActiveWorkoutBar`) above the `NavigationBar` whenever a workout is active — workout name, live elapsed `mm:ss` (1 s ticker, `formatRestDuration`), `StatusBadge` "Active" and a play affordance (`activeWorkoutResume`). Tapping the bar or the play button opens the dedicated active-workout view via `GoRouter.of(context).go('/active-workout')` (active-workout-flow T04) — no stacked copies. The bar sits inside the `bottomNavigationBar` column (bar above the `NavigationBar`) so per-screen FABs float clear of it; it animates in/out via `AnimatedSwitcher` (slide + fade) and collapses to zero height when no workout is active.
- **`/active-workout` top-level route (active-workout-flow T04)**: `ActiveWorkoutScreen` (`lib/src/exercise/screens/active_workout_screen.dart`) is registered as a **sibling** `GoRoute` of the shell route, outside every branch, so the shell chrome (floating bar + `NavigationBar`) is not rendered while it is open. All active-workout entry points land here via `context.go(...)`: the floating bar, the workout-list active tap, the dashboard resume chip + continue card, and the workout-detail Start button (which pops the planning detail first — go_router 15 cannot remove imperatively-pushed routes, so pop-then-go replaces it). `WorkoutDetailScreen` is the **pending (planning) screen only**.
- **`/workout-summary/:id` top-level route (active-workout-flow T07)**: `WorkoutSummaryScreen` (`lib/src/exercise/screens/workout_summary_screen.dart`) is a second top-level sibling route outside the shell. Completed workouts open it via `context.go('/workout-summary/:id')` from the completion flow (`_completeWorkout` on `ActiveWorkoutScreen`), the workout-list completed tap, and the dashboard latest-workout card completed tap (T08); it renders read-only per-exercise metrics (avg rest, volume, max weight, total reps — duration/distance for cardio) from `workoutDetailProvider(id)`. `WorkoutDetailScreen` is now exclusively the **pending (planning) screen**, reached only from the workout-list pending tap.

---

## Accessibility & platform polish (T10)

- **Edge-to-edge**: `main()` calls `SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge)` (API 35+ is edge-to-edge by default; this aligns older devices). Status-bar icon brightness follows the active theme via `AppBarTheme.systemOverlayStyle` (dark icons on the light surface, light icons on the teal-tinted dark surface); the M3 `NavigationBar` handles bottom system-nav padding itself.
- **Dynamic type**: the workout-detail set table uses flex columns (`Expanded(flex: 2)` `#` / `flex: 5` planned / `flex: 5` actual) so long "12 × 60 kg" strings wrap instead of clipping at large text scales.
- **Tooltip/semantics sweep**: every `IconButton` in `lib/src` carries a tooltip; the `_SetRow` edit affordance is a `Tooltip` (`commonEdit`).
- **Contrast**: `FitFatColors` light/dark palettes verified ≥ 4.5:1 against their surfaces (light success 5.13:1 / warning 6.56:1; dark success 8.46:1 / warning 9.83:1) — no tuning was needed. See [ui/design-system.md](ui/design-system.md).

---

## Database (T02)

Local SQLite database managed by [Drift](https://drift.simonbinder.eu/).

### Schema overview

```
ingredients ──┐
               ├── food_ingredients ── foods ──┐
               │                                  ├── meal_foods ── meals
               └── (each also owns a 1:1 derived food)
exercises  ──┐
              ├── workout_exercises ── workouts
              │         └── exercise_sets
tasks         (standalone — daily planner tasks, no FKs)
notes         (standalone — free-form Notes tab, no FKs)
accounts ── transactions ── receipts, fx_rates (budget section)
body_metrics  (standalone — one row per day: weight/height, no FKs)
```

37 tables total. See [database/schema.md](database/schema.md) for full column definitions.

### Data access

Hot read paths avoid per-item query loops (perf 2026-08-17):
`WorkoutRepository._getExerciseBlocks` / `getExerciseHistory` load all sets with a
single `workoutExerciseId.isIn(...)` bulk query and group in memory, and the
dashboard's `weeklyWorkoutStatsProvider` calls `getVolumeAndMinutesSince(weekStart)`
(exactly two queries: a workouts→workout_exercises→exercise_sets join for volume,
plus a workouts scan for duration) instead of resolving `workoutDetailProvider` per
completed workout. Workout history charts reuse `WorkoutRepository.getDailyVolumes(from)`.

### Delete semantics (T05+)

- **Ingredients are soft-archived** (`ingredients.is_archived`, schema v4): `IngredientRepository` has `archive`/`restore` and no hard `delete`; `getAll()` filters archived rows so the list and meal-form picker (both read `ingredientListProvider`) hide them. Past meals keep names because `MealRepository` joins all ingredient rows regardless of the flag. See [diet/ingredient-crud.md](diet/ingredient-crud.md).
- **Meals / workouts / planner items**: hard delete + "Deleted" top banner with Undo, wired in T07 (banners replaced the original snackbars app-wide). Repository machinery (T06): `MealRepository.restore` (re-insert with original ids), `WorkoutRepository.deleteWithSnapshot`/`restore` via the repo-local `WorkoutSnapshot` (raw rows → exact restore of all 3 levels), `PlannerRepository.restore`, `ExerciseRepository.usageCount`. Screens: meal/workout/planner `onDismissed` → repo delete (workout via `deleteWithSnapshot`) → `ref.invalidate` → top banner (message + `commonUndo` action → restore + invalidate). No confirm dialogs remain on the main lists.
- **Exercises**: deletion is **blocked** when still referenced. The list screen checks `usageCount` inside `Dismissible.confirmDismiss` (before the tile leaves the tree) and shows a blocking `exerciseUsed*` dialog when count > 0 (returns false → tile snaps back, nothing deleted/throws). Unused exercises are hard-deleted with **no Undo** (user decision, T07).

### Key file locations

| File | Purpose |
|------|---------|
| `lib/src/database/app_database.dart` | `AppDatabase` class, connection setup, `MigrationStrategy` |
| `lib/src/database/tables.dart` | Drift table definitions |
| `lib/src/database/app_database.g.dart` | Generated row classes, companions, table infos, `$AppDatabase` base (all drift output combined here) |

### Domain models

Separate plain Dart classes in `lib/src/models/` mirror the database rows. Repositories convert between Drift-generated rows and domain models.

---

## Network (Phase E)

Small decoupled HTTP layer in `lib/src/network/`: `ApiClient` (abstract,
`getJson`/`postJson`/`putJson`/`deleteJson`), `HttpApiClient` (production,
`package:http`, 15 s timeout, User-Agent, base URL), `MockApiClient` (scripted,
for tests), and an overridable `apiClientProvider`. FX rates are
not fetched by the phone: they arrive with the sync pull (`GET /fx-rates`), and
the server is their only source. See [network/network.md](network/network.md).

## Data sync

The phone talks to a self-hosted Maia server over HTTP with a Bearer API key.
The full target protocol (push batches, device/account bootstrap, idempotency)
is the `/v1/sync/{entity}` envelope in
[sync/sync-contract.md](sync/sync-contract.md); the implementation diverges
(§11 records the implemented pull envelope).

**Server configuration** lives in Settings → Sync and in the sync hub
(`/sync`). It holds **one or more server profiles** (URL + API key) with one
marked active, reachable through the dashboard's sync card. The pairing QR is
scanned by the app (`mobile_scanner`); the server's API key is currently stored
in plain SharedPreferences, not in secure storage. See
[plans/multi-server-secure-link.md](plans/multi-server-secure-link.md).

**Catalogue (global pool).** Exercises, foods and stores come from the server.
A *lightweight catalogue* pair of endpoints
(`GET /exercises/catalog`, `GET /ingredients/catalog`) backs a **selective**
import flow: the list screens offer bulk or selective sync, and a selective
import pulls only the checked rows and never advances the bulk cursor. The
catalogue is refreshed in the background on a 15-minute throttle
(`CatalogSyncClient`, `app/app.dart`), so the pickers work offline once
synced. A minimal local catalogue table holds the synced rows, and
"hide imported" filters against them.

**Personal pool.** The phone pushes and pulls its own data — tasks, notes,
goals, workouts, workout templates, meals, body metrics, and (historically)
experiments. `PersonalPullService` is the pull side: per-resource cursors,
soft-delete tombstones and the `noteAudio` metadata carry-over. Tags and
stores are pushed alongside. Ingredients go the other way as well: a push
sends the stores, then every live ingredient with its pictures and prices, so
the server holds the phone's catalogue too. Finance is **read-only** on the
phone: accounts and transactions are pulled and never pushed; receipts go the
other way — the phone sends each one through the capture upload and then
forgets it, dropping its own row and image once the server has accepted it.
The parse poll is gone from the client: the server reads and matches a
receipt on its own.

**Other client services.** `ExerciseMediaSync` downloads the exercise images
and videos that belong to synced exercises; `IngredientLookupClient` resolves a
scanned barcode against the server, which proxies Open Food Facts;
`LocalBackup` exports the local data as JSON (share sheet) and imports it back
(file picker).

UI entry points: the dashboard's sync card, the `SyncButton` in the exercise
and ingredient list app bars, the ingredient detail screen's push action, and
the currency sync button in the sync-server card. Cursors live in
`SyncStateStore` (SharedPreferences); `fx_rates` is pull-only and read-only on
the phone: a pulled rate replaces the local row for its day.

---

## Notifications (T10 + T11)

Notifications subsystem (`lib/src/notifications/`):

### Active-workout (T10)

- `_BackgroundStartup` (`app.dart`) calls `FlutterForegroundTask.init(...)` (Android channel `active_workout` with HIGH importance/priority + public visibility, 1 s `repeat` event, no auto-run on boot); `main()` only opens the communication port and registers the tap callback.
- **Android**: ongoing foreground notification via `flutter_foreground_task`. The task callback (`@pragma('vm:entry-point') activeWorkoutTaskCallback`) runs in a background isolate with its own FlutterEngine, so `shared_preferences` is readable there; `ActiveWorkoutTaskHandler.onRepeatEvent` rebuilds the notification text each tick from persisted keys.
- Session + rest state is persisted in `shared_preferences` (`active_workout_name`, `active_workout_started_at`, `rest_started_at`, `rest_set_id`, `rest_planned_seconds`, localized label fragments) so the background callback and the UI stay in sync.
- Start is wired to the workout Start button in `workout_detail.dart` (pending screen); Complete and the rest UI (info-strip rest line with count-up; rests auto-start from set saves) live on `ActiveWorkoutScreen` (`/active-workout`).
- **Tap routing (active-workout-flow T06)**: tapping the ongoing notification opens `/active-workout` — `ActiveWorkoutTaskHandler.onNotificationPressed()` → `sendDataToMain('active-workout')` → `addTaskDataCallback` in `main()` (gated on the active session, deferred to first frame on cold start). `startService` sets `notificationInitialRoute: '/active-workout'` for Android cold starts.
- **iOS**: best-effort only via `flutter_local_notifications` (no foreground-service parity).

### Planner task reminders (T11)

- `main()` initializes the `timezone` database (`FlutterTimezone.getLocalTimezone` → `tz.setLocalLocation`) and a single `flutter_local_notifications` plugin (`TaskReminderScheduler.initialize`): Android channel `planner_reminders`, tap handler + cold-start launch replay route to `/plan` via `_openPlanTab`.
- `TaskReminderScheduler` (`lib/src/notifications/task_reminders.dart`) schedules a pre-reminder (configurable lead) + a due-time reminder per planner task — timed tasks anchor to their start time, untimed to the `untimedReminderMinutes` setting (default 09:00) — via `zonedSchedule` (`exactAllowWhileIdle` when granted, silent inexact fallback otherwise), with deterministic per-task ids and a prefs registry for the app-wide `plannerNotifications` toggle (`cancelAll` / `reschedulePending`). Startup runs day rollover before the reminder reschedule; `_rollover` invalidates all Day/Week/Month families + dashboard so carried tasks appear without manual edits, and resume chains rollover then a silent reminder resync.
- Planner mutations keep reminders in sync (add/edit/done/delete/undo/copy); the Android manifest adds `RECEIVE_BOOT_COMPLETED` + `ScheduledNotificationBootReceiver` for reboot persistence.
- See [notifications/notifications.md](notifications/notifications.md) and [planner/planner.md](planner/planner.md).
