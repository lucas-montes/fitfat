# Glossary

## Core workout domain

| Term | Definition |
|------|-----------|
| **Workout** | A single workout session. Can be free-form (no date) or scheduled. Unified model — replaces old Plan + Session split. |
| **WeightSet** | One weightlifting set within a workout. Carries planned and actual values for adherence tracking. |
| **CardioSet** | One cardio/duration set within a workout. Carries planned and actual values. |
| **Scheduled workout** | A workout with a `scheduledDate`. `startedAt = null` = pending; `startedAt != null` = in progress. |
| **Free-form workout** | A workout with `scheduledDate = null`, started immediately. |
| **Effective values** | `actual ?? planned` — falls back to planned when actual is not yet recorded. |

## Enums

| Enum | Values |
|------|--------|
| **ExerciseType** | `weightlifting`, `cardio` |
| **BodyPart** | `chest`, `back`, `shoulders`, `biceps`, `triceps`, `forearms`, `quadriceps`, `hamstrings`, `glutes`, `calves`, `abdominals`, `obliques`, `traps`, `lats`, `neck`, `fullBody` |
| **WorkoutSource** | `manual`, `coach`, `quickLog` |

## Old terms (being removed)

| Old term | Replacement |
|----------|-------------|
| Plan | Workout with scheduledDate set |
| Session | Workout with startedAt set |
| Template | Workout with scheduledDate in the future, not started |
| PlannedWorkout | Workout (same concept) |
| PlannedEntry / PlannedSet | WeightSet / CardioSet with planned fields set |
| WorkoutEntry | Replaced by direct WeightSet/CardioSet storage |
| Seance | Entirely removed |
| ExerciseEntry / ExerciseSet | Entirely removed |
