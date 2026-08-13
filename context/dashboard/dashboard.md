# Dashboard

"Today at a glance" read-only summary view (reworked in T05): greeting + locale date, calorie progress ring (consumed vs target), macro-targets progress, body-weight trend (owns Add weight/height entry), weekly workout volume/minutes, upcoming timed tasks, and the latest workout card. The 7-day calorie chart, today's-plan strip, and the bottom `BodyMetricsCard` were removed.

## Files

| File | Purpose |
|------|---------|
| `lib/src/dashboard/providers/dashboard.dart` | Riverpod providers: today's calories/macros, latest workout, weekly volume/minutes, upcoming timed tasks |
| `lib/src/dashboard/screens/dashboard.dart` | Dashboard UI: greeting header, the card set below, welcome hub (no-data) |

## Providers

- **`todayCaloriesProvider`** (`FutureProvider<double>`): filters all meals by today's start-of-day window, sums their `totalCalories`.
- **`todayMacrosProvider`** (`FutureProvider<TodayMacros>`; typedef `({double protein, double carbs, double fat})`): same today-window filter, sums per-item `MealIngredient` P/C/F grams.
- **`latestWorkoutProvider`** (`FutureProvider<Workout?>`): completed workouts only, most recent (date desc); `null` when none.
- **`weeklyWorkoutStatsProvider`** (`FutureProvider<WeeklyWorkoutStats>`; typedef `({double totalVolumeKg, int totalMinutes})`): for completed workouts whose `completedAt` is within the last 7 days, sums Σ set `totalVolume` (kg) and the workout durations (minutes).
- **`upcomingTimedTasksProvider`** (`FutureProvider<List<PlannerItem>>`): pending planner tasks with a due time, due today or later, via `PlannerRepository.getUpcomingWithDueTime(today)`.
- `DashboardScreen` also watches the cross-domain `mealListProvider` (diet) and `workoutListProvider` (exercise) to detect the first-run state, and `activeWorkoutProvider` (exercise) for the latest-card active state.

## Screens

`DashboardScreen` (`ConsumerWidget`): AppBar shows the app title with a settings `IconButton` (tooltip `settingsAppBar`) → `context.go('/settings')`. Body: `ListView` → `Center` → `ConstrainedBox(maxWidth: 600)`. Column:

- **`_GreetingHeader`** — time-based greeting (morning < 12 / afternoon < 18 / evening) + locale date via `DateFormats.formatDate`.
- **Welcome hub** (`_WelcomeHub`) when there are no meals AND no workouts: rocket tonal circle + three action rows (ingredient / meal / workout forms).
- Otherwise the data cards:
  - **`_CalorieRingCard`** — watches `todayCaloriesProvider` (consumed) + `calorieTargetProvider` (from `lib/src/diet/providers/calories.dart`); renders `_CalorieRing` (progress ring of consumed/target) + remaining kcal (`dashboardRemaining` / `dashboardConsumedOfTarget` / `dashboardOverTarget`). **Hidden until the calorie-profile inputs exist** (age/gender/weight/height), i.e. when the target is unavailable.
  - **`_MacroTargetsCard`** — `todayMacrosProvider` vs `macroTargetsProvider` (P/C/F = 30/40/30% of the calorie target); three `_MacroTargetRow`s with label, grams progress (`dashboardMacroProgress`), percent.
  - **`_WeightTrendCard`** — watches `bodyMetricsProvider` + `latestBodyMetricsProvider` + `settingsProvider`; renders the weight-over-time `_WeightLineChart` (custom painter) with Add weight / Add height buttons (moved here from the removed `BodyMetricsCard`; see [body-metrics.md](../body/body-metrics.md)). Goal badge when `bodyWeightGoal` set.
  - **`_WeeklyWorkoutCard`** — `weeklyWorkoutStatsProvider`; shows total volume (`dashboardVolumeKg`) and total minutes (`dashboardMinutes`).
  - **`_UpcomingTasksCard`** — `upcomingTimedTasksProvider`; lists pending timed tasks (title + due date/time), "See all" → `context.go('/plan')`. Empty state `dashboardNoUpcomingTasks`.
  - **`_LatestWorkoutCard`** — when `activeWorkoutProvider` is non-null renders the "Continue workout" active body (→ `context.go('/active-workout')`); otherwise the latest completed workout (name + `StatusBadge` + date + duration, "Open workout" → workout detail/summary) or `dashboardNoWorkouts`.

## Repositories used

- `MealRepository.getAll()` — today calories, today macros.
- `WorkoutRepository.getAll()` + `workoutDetailProvider` — latest + weekly stats.
- `PlannerRepository.getUpcomingWithDueTime(today)` — upcoming timed tasks.
- `BodyMetricsRepository` — weight trend card.

## Wiring

`DashboardTab` (`lib/src/app/tabs/dashboard_tab.dart`) renders `DashboardScreen` as the root of the Dashboard route branch. Cross-tab navigation uses `context.go('/plan')` / `context.go('/settings')` — go_router 15 `StatefulShellRoute` switches the active branch when `go` targets a route inside another branch.

See also: [overview.md](../overview.md), [architecture.md](../architecture.md), [meal-crud.md](../diet/meal-crud.md), [workout-crud.md](../exercise/workout-crud.md), [planner.md](../planner/planner.md), [body-metrics.md](../body/body-metrics.md), [settings.md](../settings/settings.md)
