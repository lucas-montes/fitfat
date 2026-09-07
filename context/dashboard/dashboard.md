# Dashboard

Redesigned Today-first actionable view (dashboard-redesign): horizontal Today strip (tasks + goals + experiments, priority-sorted, inline toggle), nutrition hero (calorie ring + macros with maintenance fallback when profile incomplete, Estimated badge), weight trend with deltas (7d/30d) and goal projection, unified workout hero (latest/Continue + weekly volume/minutes), goals overview (active goals with progressFrom bars), experiments nudge, and budget mini (net worth + month income/expense when accounts exist). Greeting header removed.

## Files

| File | Purpose |
|------|---------|
| `lib/src/dashboard/providers/dashboard.dart` | Riverpod providers: today's calories/macros, latest workout, weekly volume/minutes, upcoming tasks (used by Today strip priority sorting) |
| `lib/src/dashboard/screens/dashboard.dart` | Dashboard UI: Today strip, nutrition hero, weight trend, workout hero, goals, experiments, budget mini, welcome hub |
| `lib/src/diet/providers/calories.dart` | `calorieTargetMetaProvider` (fallback 70kg/170cm/30y/male/moderate, `isEstimated`), `calorieTargetProvider` (non-nullable), `macroTargetsProvider`/`macroTargetsMetaProvider` |

## Providers

- **`todayCaloriesProvider`** (`FutureProvider<double>`): filters all meals by today's start-of-day window, sums their `totalCalories`.
- **`todayMacrosProvider`** (`FutureProvider<TodayMacros>`; typedef `({double protein, double carbs, double fat})`): same today-window filter, sums per-item `MealIngredient` P/C/F grams.
- **`calorieTargetMetaProvider`** (`FutureProvider<CalorieTargetMeta>`; `({double target, bool isEstimated})`): computes TDEE with fallback defaults when age/gender/weight/height missing; `isEstimated` true when any input was fallback.
- **`calorieTargetProvider`** (`FutureProvider<double>`): `meta.target` (always present, maintenance fallback).
- **`macroTargetsProvider`** (`FutureProvider<MacroTargets>`): `macroTargetsFor(target)` always present.
- **`latestWorkoutProvider`** (`FutureProvider<Workout?>`): completed workouts only, most recent.
- **`weeklyWorkoutStatsProvider`** (`FutureProvider<WeeklyWorkoutStats>`; `({double totalVolumeKg, int totalMinutes})`): last 7 days completed workouts bulk via `getVolumeAndMinutesSince`.
- **`upcomingTasksProvider`** (`FutureProvider<List<Task>>`): pending tasks on/after today, sorted by day then time; Today strip re-sorts by `tags.length` priority then startTimeMinutes.
- `DashboardScreen` also watches `mealListProvider`/`workoutListProvider` for first-run, `activeWorkoutProvider` for workout hero, `goalListProvider`/`latestGoalProgressProvider` for goals card, `budgetOverviewProvider` for budget mini.

## Screens

`DashboardScreen` (`ConsumerWidget`): AppBar with settings → `context.go('/settings')`. Body: `ListView` → `Center` → `ConstrainedBox(maxWidth:600)`. Column:

- **Welcome hub** (`_WelcomeHub`) when no meals AND no workouts (unchanged).
- Otherwise:
  - **`_TodayStrip`** — `upcomingTasksProvider` sorted by `tags.length` desc then `startTimeMinutes` asc; horizontal `ListView.separated` of `_TodayTaskChip` (200px card: checkbox inline via `taskRepositoryProvider.update` + `invalidate(upcomingTasksProvider)`, tags, due time, workout icon, tap → `PlannerItemDetailScreen`).
  - **`_NutritionHeroCard`** — `calorieTargetMetaProvider` + `todayCaloriesProvider` + `todayMacrosProvider` + `macroTargetsProvider`; `_CalorieRing` + divider + 3× `_MacroTargetRow`; Estimated badge + Complete profile CTA when `isEstimated`.
  - **`_WeightTrendCard`** — `bodyMetricsProvider` + `latestBodyMetricsProvider` + `settingsProvider`; Add weight/height buttons, latest values, `_WeightEvolution` (chart + deltas 7d/30d via `_computeDelta` + projection via `_computeProjection` when goal set).
  - **`_WorkoutHeroCard`** — `activeWorkoutProvider` (Continue) or `latestWorkoutProvider` + `weeklyWorkoutStatsProvider` (volume/minutes) in one Card with Divider.
  - **`_GoalsOverviewCard`** — `goalListProvider` filtered `isActive` take 3 + `latestGoalProgressProvider` per goal, `progressFrom` bar.
  - **`_ExperimentsNudgeCard`** — placeholder CTA to `/plan` (active experiments surface via Plan tab).
  - **`_BudgetMiniCard`** — `budgetOverviewProvider`; hidden when `accounts.isEmpty`; shows net worth + month income/expense + recent count.

## Repositories used

- `MealRepository.getAll()` — today calories/macros.
- `WorkoutRepository.getAll()` + `getVolumeAndMinutesSince` — workout hero.
- `TaskRepository.getUpcoming` / `getByDay` — Today strip.
- `GoalRepository.getGoals` + `getLatestProgressValue` — goals overview.
- `BodyMetricsRepository` — weight trend.
- `AccountRepository`/`TransactionRepository` via `budgetOverviewProvider` — budget mini.

## Wiring

`DashboardTab` renders `DashboardScreen`. Cross-tab navigation via `context.go('/plan')` / `/exercise` / `/budget` / `/settings` (StatefulShellRoute).

See also: [overview.md](../overview.md), [architecture.md](../architecture.md), [meal-crud.md](../diet/meal-crud.md), [workout-crud.md](../exercise/workout-crud.md), [planner.md](../planner/planner.md), [body-metrics.md](../body/body-metrics.md), [settings.md](../settings/settings.md)
