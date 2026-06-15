# Stats Tab

Replaces the old dashboard-dependent stats with a self-contained tab that reads directly from `workoutHistoryProvider`. Defined in `lib/src/exercise/screens/stats/stats_tab.dart`.

## Data source

Watches `workoutHistoryProvider` (`history_provider.dart`) which returns `List<domain.Workout>`. All stats are computed locally from this list — no separate provider for dashboard stats.

## Layout (top to bottom)

1. **All-time overview card** — total workouts count, total volume (kg), total duration (minutes), total cardio minutes (shown only when > 0).

2. **This-week stats** — `_WeekStatsCard` with session count, volume, and duration for the current Mon-Sun week. Computed inline by filtering `workouts` where `endTime >= weekStart`.

3. **Heatmap** — `_HeatmapGrid` widget, 84-day activity grid (7 columns × 12 rows). Colors any day with **any** activity (weightlifting or cardio), distinguished from inactive days. Tap opens a bottom sheet (`_showDayDetail`) showing that day's `domain.Workout` entries with type-specific icons, exercise names, and volume/duration.

4. **Cardio by week** — `_CardioByWeekCard` widget. Shows the most recent 8 weeks, each with a `LinearProgressIndicator` (capped at 300 min). Computed from `w.totalCardioMinutes` per workout.

5. **Volume by exercise** — `_VolumeByExerciseCard` widget. Top 10 exercises by all-time volume load, each with a `LinearProgressIndicator` relative to the max. Skips cardio entries.

## Internal helpers

| Widget | Purpose |
|--------|---------|
| `_HeatmapDay` | Data class with `date`, `volume`, `hasWorkout`, `workouts`, `duration` |
| `_HeatmapGrid` | 7-column grid, `_heatmapColor()` blends surfaceContainerHighest → primary based on normalized volume |
| `_WeekStatsCard` | Wrap of three `_StatCard` instances (sessions, volume, duration) |
| `_StatCard` | Compact stat tile with icon, value, label |
| `_LegendDot` | Colored circle + label for heatmap legend |
| `_CardioByWeekCard` | Per-week cardio minutes with progress bars, sorted descending |
| `_VolumeByExerciseCard` | Per-exercise all-time volume, top 10 sorted descending |

## Key behaviors

- **Heatmap colors any day with activity** — `hasWorkout` flag is true whenever `dayWorkouts.isNotEmpty`, regardless of weightlifting vs. cardio.
- **Cardio stats** appear conditionally: if total all-time cardio minutes > 0, the all-time card shows a cardio row; if no cardio data exists, `_CardioByWeekCard` returns `SizedBox.shrink()`.
- **ProgressionService** in `workout_services.dart` has `WeightSet` overloads (`setVolumeFromWeightSet`, `epleyOneRMFromWeightSet`, `findBestSetFromWeightSets`, `findMaxWeightFromWeightSets`, `findMaxVolumeSetFromWeightSets`) accepting `domain.WeightSet` for use by new-model consumers.

## L10n keys consumed

`allTime`, `workouts`, `volume`, `duration`, `cardio`, `thisWeek`, `activity`, `trainingHeatmap`, `last84Days`, `heatmapLegendLow`, `heatmapLegendMid`, `heatmapLegendHigh`, `noTrainingRecorded`, `exercises`, `volumeProgression`, `trends`.

## Related files

- `lib/src/exercise/providers/history_provider.dart` — data source
- `lib/src/exercise/services/workout_services.dart` — `ProgressionService` with `WeightSet` overloads
- `lib/src/exercise/screens/stats/stat_item.dart` — `StatItem` widget used in all-time card

See also: [training-tab.md](training-tab.md), [workout-model.md](workout-model.md), [context-map.md](../context-map.md)
