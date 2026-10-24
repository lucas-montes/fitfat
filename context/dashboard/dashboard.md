# Dashboard

Redesigned Today-first actionable view (dashboard-redesign): horizontal Today strip (tasks, priority-sorted, inline toggle), nutrition hero (five uniform calorie/macro/fiber rows with an Estimated badge), weight trend with deltas (7d/30d) and goal projection, unified workout hero (latest/Continue + weekly volume/minutes), goals overview (active goals with progressFrom bars), and budget mini (net worth + month income/expense when accounts exist). Greeting header removed.

## Files

| File | Purpose |
|------|---------|
| `lib/src/dashboard/providers/dashboard.dart` | Riverpod providers: today's consumed calories/macros, latest workout, weekly volume/minutes, upcoming tasks (used by Today strip priority sorting) |
| `lib/src/dashboard/screens/dashboard.dart` | Dashboard UI: Today strip, nutrition hero, weight trend, workout hero, goals, budget mini, welcome hub |
| `lib/src/diet/providers/calories.dart` | Riverpod wiring only: `calorieCalculatorProvider`, the two input-source providers, `calorieTargetMetaProvider`, `calorieTargetProvider`, `macroTargetsProvider` |
| `lib/src/diet/services/calorie_calculator.dart` | `CalorieCalculator` — the BMR → TDEE → target → macro derivation, plus `CalorieTargetMeta` / `MacroTargets` |
| `lib/src/diet/services/bmr_equation.dart` | `BmrEquation` strategy + `MifflinStJeorEquation`, `KatchMcArdleEquation` |
| `lib/src/diet/services/activity_factor_source.dart` | `ActivityFactorSource` strategy + `PalActivityFactor` (reads `ActivityLevel.multiplier`) |
| `lib/src/diet/services/calorie_inputs.dart` | `BodyProfile` / `CalorieInputs` records, the `BodyProfileSource` and `UserProfileSource` seams, and the shared fallback body (70 kg / 170 cm / 30 y / male) |

## Calorie derivation

`CalorieCalculator` takes two swappable strategies — a `BmrEquation` and an
`ActivityFactorSource` — and nothing else. The maths is sync and pure; the one
`await` is the activity source, which is async so a measured (workouts + steps)
source can replace `PalActivityFactor` later without changing the interface.

- TDEE = **BMR × activity factor**. Katch-McArdle is preferred when body fat is
  tracked and set, otherwise the injected equation (Mifflin-St Jeor in the app).
- Target = TDEE + the active phase's signed `adjustment`.
- Macros: protein = `proteinPerKg × bodyweightKg`, fat = 30%-style share of the
  target, carbs = the remaining calories (clamped at 0), fiber = configured.

Because protein is the only bodyweight-driven target, it does not scale with an
inflated TDEE while carbs and fat do — the invariants that P/C/F sum to exactly
the calorie target, and that BMR and the macro targets assume the same fallback
body, are both pinned in `test/calorie_calculator_test.dart`.

## Providers

- **`todayCaloriesProvider`** (`FutureProvider<double>`): `meal_foods` snapshot
  calories summed over today's window, via `MealRepository.totalsBetween`.
- **`todayMacrosProvider`** (`FutureProvider<TodayMacros>`; typedef `({double protein, double carbs, double fat, double fiber})`): the same aggregate query.
- **`calorieTargetMetaProvider`** (`FutureProvider<CalorieTargetMeta>`): delegates to `CalorieCalculator.target`; `isEstimated` true when weight, height, age or gender was a fallback.
- **`calorieTargetProvider`** (`FutureProvider<double>`): `meta.target`.
- **`macroTargetsProvider`** (`FutureProvider<MacroTargets>`): `CalorieCalculator.macros`.
- **`latestWorkoutProvider`** (`FutureProvider<Workout?>`): completed workouts only, most recent.
- **`weeklyWorkoutStatsProvider`** (`FutureProvider<WeeklyWorkoutStats>`; `({double totalVolumeKg, int totalMinutes})`): last 7 days completed workouts bulk via `getVolumeAndMinutesSince`.
- **`upcomingTasksProvider`** (`FutureProvider<List<Task>>`): pending tasks on/after today, sorted by day then time; Today strip re-sorts by `tags.length` priority then startTimeMinutes.
- `DashboardScreen` also watches `mealListProvider`/`workoutListProvider` for first-run, `activeWorkoutProvider` for workout hero, `goalListProvider`/`latestGoalProgressProvider` for goals card, `budgetOverviewProvider` for budget mini.

## Screens

`DashboardScreen` (`ConsumerWidget`): AppBar with settings → `context.go('/settings')`. Body: `ListView` → `Center` → `ConstrainedBox(maxWidth:600)`. Column:

- **Welcome hub** (`_WelcomeHub`) when no meals AND no workouts (unchanged).
- Otherwise:
  - **`_TodayStrip`** — `upcomingTasksProvider` sorted by `tags.length` desc then `startTimeMinutes` asc; horizontal `ListView.separated` of `_TodayTaskChip` (200px card: checkbox inline via `taskRepositoryProvider.update` + `invalidate(upcomingTasksProvider)`, tags, due time, workout icon, tap → `PlannerItemDetailScreen`).
  - **`_NutritionHeroCard`** — `calorieTargetMetaProvider` + `todayCaloriesProvider` + `todayMacrosProvider` + `macroTargetsProvider`; five identical `_MacroTargetRow`s (calories, protein, carbs, fat, fiber) so a glance down the list compares like with like. Only the calorie row carries an `overflowColor`, since calories are the one row you can meaningfully overshoot. BMR · TDEE · equation name · Estimated badge in the `_BmrTdeeFooter` below the divider.
  - **`_WeightTrendCard`** — `bodyMetricsProvider` + `latestBodyMetricsProvider` + `settingsProvider`; Add weight/height buttons, latest values, `_WeightEvolution` (chart + deltas 7d/30d via `_computeDelta` + projection via `_computeProjection` when goal set).
  - **`_WorkoutHeroCard`** — `activeWorkoutProvider` (Continue) or `latestWorkoutProvider` + `weeklyWorkoutStatsProvider` (volume/minutes) in one Card with Divider.
  - **`_GoalsOverviewCard`** — `goalListProvider` filtered `isActive` take 3 + `latestGoalProgressProvider` per goal, `progressFrom` bar.
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
