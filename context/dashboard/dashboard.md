# Dashboard

Read-only summary view showing today's calorie intake and latest completed workout.

## Files

| File | Purpose |
|------|---------|
| `lib/src/dashboard/providers/dashboard.dart` | Riverpod providers for today's calories and latest workout |
| `lib/src/dashboard/screens/dashboard.dart` | Dashboard UI: two `Card` widgets in a `ListView` |

## Providers

- **`todayCaloriesProvider`** (`FutureProvider<double>`): Filters all meals by today's date and sums their `totalCalories`.
- **`latestWorkoutProvider`** (`FutureProvider<Workout?>`): Gets all workouts, filters to completed, returns the first (most recent, ordered by date desc). Returns `null` if no workouts completed.

## Screens

- **`DashboardScreen`** (`ConsumerWidget`): Two cards in a `ListView`:
  - "Today's Calories" — fire icon + calorie total in bold headline style
  - "Latest Workout" — fitness icon + workout name, date, and duration (if > 0)
  - Shows placeholder text ("No completed workouts yet.") when no data

## Repositories used

- `MealRepository.getAll()` (from diet domain)
- `WorkoutRepository.getAll()` (from exercise domain)

Repository providers are local to the dashboard domain (not shared).

## Wiring

`DashboardTab` (`lib/src/app/tabs/dashboard_tab.dart`) renders `DashboardScreen` as the root of the Dashboard route branch.

See also: [overview.md](../overview.md), [architecture.md](../architecture.md), [meal-crud.md](../diet/meal-crud.md), [workout-crud.md](../exercise/workout-crud.md)
