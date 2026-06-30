# Glossary

## Core workout domain

| Term | Definition |
|------|-----------|
| **Workout** | A planned workout session with a `scheduledDate`. `startedAt = null` = pending; `startedAt != null` = in progress. No free-form mode. |
| **WeightSet** | One weightlifting set within a workout. Carries planned and actual values for adherence tracking. |
| **CardioSet** | One cardio/duration set within a workout. Carries planned and actual values. |
| **Effective values** | `actual ?? planned` — falls back to planned when actual is not yet recorded. |
| **Failed set** | A completed set marked as a failed PR attempt (`isFailed = true`). Rendered with a red cross icon and strikethrough text. |

## Enums

| Enum | Values |
|------|--------|
| **ExerciseType** | `weightlifting`, `cardio` |
| **BodyPart** | `chest`, `back`, `shoulders`, `biceps`, `triceps`, `forearms`, `quadriceps`, `hamstrings`, `glutes`, `calves`, `abdominals`, `obliques`, `traps`, `lats`, `neck`, `fullBody` |
| **WorkoutSource** | `manual`, `coach`, `quickLog` |

## Old terms (being removed)

| Old term | Replacement |
|----------|-------------|
| Free-form workout | Removed — all workouts now have a scheduledDate |
| Plan | Workout with scheduledDate set |
| Session | Workout with startedAt set |
| Template | Workout with scheduledDate in the future, not started |
| PlannedWorkout | Workout (same concept) |
| PlannedEntry / PlannedSet | WeightSet / CardioSet with planned fields set |
| WorkoutEntry | Replaced by direct WeightSet/CardioSet storage |
| Seance | Entirely removed |
| ExerciseEntry / ExerciseSet | Entirely removed |
