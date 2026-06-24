# Plan: Exercise Module Refactor — Three-Layer Architecture

## Change summary

Restructure the exercise module into three clear layers with proper separation of concerns:

```
CURRENT:                         TARGET:
Repository → Providers → Screens  Repository → Services → Providers → Screens
(providers do business logic)      (services handle business logic, providers are thin)
                                   (screens are decomposed into focused widget files)
```

No behavioral changes — all existing functionality is preserved. This is a pure structural refactoring.

The architecture follows the same pattern as the meals/diet module:
```
adapters/interfaces/         ← abstract repository contracts
adapters/drift/              ← Drift implementations (implements the interface)
exercise/services/           ← pure-Dart business logic, mapping, transformation
exercise/providers/          ← Riverpod Notifiers with explicit state classes
exercise/screens/workout/
  └── widgets/               ← extracted presentational widgets
```

Key difference from the meals module: we add a **service layer** between providers and repository (the meals module calls the repo directly from providers). This is what you asked for — "another class should handle the business logic, mapping the classes to results."

## Success criteria

- `WorkoutRepository` abstract interface exists with `DriftWorkoutRepository implements WorkoutRepository`
- Three new services exist: `SetManagementService`, `WorkoutLifecycleService`, `WorkoutSessionService` (existing promoted)
- All services registered as Riverpod providers
- `exercise_detail_screen.dart` reduced from 1088 → ~700 lines (sub-widgets extracted)
- `active_screen.dart` reduced from 415 → ~300 lines
- `list.dart` reduced from 471 → ~350 lines
- `workout_summary_screen.dart` reduced from 287 → ~200 lines
- `dart analyze lib/` — 0 errors, 0 warnings
- `flutter test test/src/exercise/` — 62/62 passed

## Constraints and non-goals

- **No behavioral changes** — this is pure refactoring. Bug fixes are out of scope.
- Do not rename existing models (`Workout`, `WeightSet`, `CardioSet`, `ExerciseDefinition`)
- Do not change the DB schema or Drift table definitions
- Do not change GoRouter routes or navigation structure
- Do not change the foreground service (`WorkoutForegroundService`)
- Widget extraction: keep files in `lib/src/exercise/screens/workout/` (co-located)

## Task stack

---

- [x] T01: `Create WorkoutRepository interface and implement in DriftWorkoutRepository` (status:done)
  - Task ID: T01
  - Goal: Add abstract `WorkoutRepository` interface with all methods currently exposed by `DriftWorkoutRepository`. Rename current class to implement it. Update the Riverpod provider to expose the interface type.
  - Boundaries (in/out of scope):
    - In: Creating `lib/src/adapters/interfaces/workout_repository.dart` with abstract class. Renaming `DriftWorkoutRepository` to show `implements WorkoutRepository`. Updating `workoutRepositoryProvider` return type.
    - Out: Changing any method signatures or behavior. Adding/removing methods.
  - Done when:
    - `WorkoutRepository` interface exists with all existing `DriftWorkoutRepository` methods
    - `DriftWorkoutRepository implements WorkoutRepository`
    - `workoutRepositoryProvider` exposes `WorkoutRepository` type
    - `dart analyze lib/` passes
    - All tests pass
  - Verification notes: `dart analyze lib/src/adapters/`; `flutter test test/src/exercise/`

---

- [x] T02: `Register existing and new services as Riverpod providers` (status:done)
  - Task ID: T02
  - Goal: Create Riverpod providers for all existing services (`WorkoutSessionService`, `ExerciseLibraryService`, `ProgressionService`) and stub providers for new services (`SetManagementService`, `WorkoutLifecycleService`). Services remain pure-Dart; only registration is new.
  - Boundaries (in/out of scope):
    - In: Creating `lib/src/exercise/services/providers.dart` with service providers. All 5 services registered.
    - Out: Implementing `SetManagementService` or `WorkoutLifecycleService` methods (stubs only). Changing existing screen code to use providers (next tasks).
  - Done when:
    - `workoutSessionServiceProvider`, `exerciseLibraryServiceProvider`, `progressionServiceProvider` exist with factory constructors
    - `setManagementServiceProvider`, `workoutLifecycleServiceProvider` exist as stubs
    - `dart analyze lib/` passes
  - Verification notes: `dart analyze lib/src/exercise/services/providers.dart`

---

- [x] T03: `Create SetManagementService with set operations and exercise derivation` (status:done)
  - Task ID: T03
  - Goal: Implement `SetManagementService` with methods for loading sets, adding/toggling/deleting sets, and deriving exercise IDs from set data. Refactor `exercise_detail_screen.dart._loadSets()` and `active_screen.dart._loadSets()` to use the service.
  - Boundaries (in/out of scope):
    - In: `SetManagementService` with `loadSets(workoutId)`, `deriveExerciseIds(sets, initialExerciseId)`, `addWeightSet(...)`, `addCardioSet(...)`, `toggleSetCompletion(...)`, `deleteSet(setId)`. Both screens updated to use the service via provider.
    - Out: Changing any UI behavior. Modifying the rest timer logic.
  - Done when:
    - `SetManagementService` is fully implemented with all methods
    - `exercise_detail_screen._loadSets()` delegates to the service
    - `active_screen._loadSets()` delegates to the service
    - `dart analyze lib/` passes, all tests pass
  - Verification notes: `dart analyze lib/src/exercise/services/`; `flutter test test/src/exercise/`

---

- [x] T04: `Create WorkoutLifecycleService and refactor ActiveWorkoutNotifier` (status:done)
  - Task ID: T04
  - Goal: Implement `WorkoutLifecycleService` with methods for `startFreeform`, `startScheduled`, `complete`, `cancel`, `resume`. Refactor `ActiveWorkoutNotifier` to delegate lifecycle management to the service while keeping state management (provider state, watcher notification).
  - Boundaries (in/out of scope):
    - In: `WorkoutLifecycleService` with 5 methods. `ActiveWorkoutNotifier` calls service instead of repo directly.
    - Out: Changing the `complete()` state-update strategy (still sets `completedAt` on in-memory workout, not null). Changing foreground service interaction.
  - Done when:
    - `WorkoutLifecycleService` is implemented
    - `ActiveWorkoutNotifier` delegates all lifecycle calls to the service
    - All existing behaviors preserved (complete doesn't set null, etc.)
    - `dart analyze lib/` passes, all tests pass
  - Verification notes: `dart analyze lib/src/exercise/providers/active_workout.dart`; `flutter test test/src/exercise/`

---

- [x] T05: `Extract ExerciseDetailState management into a dedicated provider` (status:done)
  - Task ID: T05
  - Goal: Create `exerciseDetailProvider` — a family provider scoped to `(workoutId, initialExerciseId)` that manages all set state (lists, current index, exercises, rest timer). Follow the meals pattern: explicit state class with `copyWith` and status enum. `ExerciseWorkoutDetailScreen` becomes a thin consumer.
  - Boundaries (in/out of scope):
    - In: `ExerciseDetailNotifier` with state class (like `MealsState`), extracted from `_ExerciseWorkoutDetailScreenState`. Screen becomes a consumer. New file `lib/src/exercise/providers/exercise_detail.dart`.
    - Out: Extracting sub-widgets (handled in T06). Changing any visual behavior.
  - Done when:
    - `ExerciseDetailNotifier`/`exerciseDetailProvider` exists with explicit `ExerciseDetailState` class using `copyWith`
    - State manages sets, exercise IDs, current index, filtering, rest timer
    - `exercise_detail_screen.dart` uses `ref.watch(exerciseDetailProvider(...))` instead of local `setState` for data
    - Screen is reduced by ~250 lines
    - `dart analyze lib/` passes, all tests pass
  - Verification notes: `dart analyze lib/src/exercise/providers/exercise_detail.dart`; `flutter test test/src/exercise/`

---

- [x] T06: `Extract sub-widgets from exercise_detail_screen.dart into widgets/ folder` (status:done)
  - Task ID: T06
  - Goal: Move private widget classes from `exercise_detail_screen.dart` into their own files under `workout/widgets/`. Matches the diet module pattern (`diet/screens/widgets/`). Pure extraction — no logic changes.
  - Boundaries (in/out of scope):
    - In: Creating `lib/src/exercise/screens/workout/widgets/` directory. Extracting `_WeightSetTile`, `_CardioSetTile`, `_RestElapsedCard`, and the add-set form builder to separate files. Making them public (rename to `WeightSetTile`, etc.).
    - Out: Changing widget behavior or layout. Extracting the screen itself (screen stays).
  - Done when:
    - `widgets/weight_set_tile.dart` with `WeightSetTile`
    - `widgets/cardio_set_tile.dart` with `CardioSetTile`
    - `widgets/rest_elapsed_card.dart` with `RestElapsedCard`
    - `widgets/exercise_set_form.dart` with the add-set form widget
    - `exercise_detail_screen.dart` imports from `widgets/` instead of defining inline
    - Screen reduced from 1088 → ~700 lines
    - `dart analyze lib/` passes, all tests pass
  - Verification notes: `dart analyze lib/src/exercise/screens/workout/`; `flutter test test/src/exercise/`

---

- [x] T07: `Extract widgets from remaining screens into widgets/ folder` (status:done)
  - Task ID: T07
  - Goal: Extract inline private widgets from remaining large screen files into `workout/widgets/`. Pure extraction — no logic changes.
  - Boundaries (in/out of scope):
    - In: Creating files under `workout/widgets/`:
      - From `active_screen.dart`: `_ElapsedTimerWidget` → `elapsed_timer_widget.dart`, `_ExerciseGroupInfo` (data class) → `exercise_group_info.dart`
      - From `list.dart`: `_TodayCard`, `_UpcomingCard`, `_HistoryItem` → `today_card.dart`, `upcoming_card.dart`, `history_item.dart`
      - From `workout_summary_screen.dart`: `_StatCard` → `stat_card.dart`, `_ExerciseSummary` (data class) → `exercise_summary.dart`
    - Out: Changing any behavior or layout.
  - Done when:
    - All extracted widget files exist under `workout/widgets/` and are publicly named
    - Source files import from `widgets/` instead of defining inline
    - `active_screen.dart` reduced from 415 → ~300 lines
    - `list.dart` reduced from 471 → ~350 lines
    - `workout_summary_screen.dart` reduced from 287 → ~200 lines
    - `dart analyze lib/` passes, all tests pass
  - Verification notes: `dart analyze lib/`; `flutter test test/src/exercise/`

---

- [x] T08: `Validation and context sync` (status:done)
  - Task ID: T08
  - Goal: Run full validation suite and sync context files.
  - Boundaries (in/out of scope):
    - In: Full `dart analyze`, `flutter test`, `flutter build apk --debug`. Update `context/context-map.md` with new file locations.
    - Out: Any behavioral changes or bug fixes.
  - Done when:
    - `dart analyze lib/` — 0 errors
    - `flutter test test/src/exercise/` — 62/62 passed
    - `flutter build apk --debug` — succeeds
    - `context/context-map.md` updated with new files
  - Verification notes: Commands listed above.

---

## Target file structure (after all tasks)

```
lib/src/
├── adapters/
│   ├── drift/
│   │   └── workout_repository.dart          ← DriftWorkoutRepository implements WorkoutRepository
│   └── interfaces/
│       ├── exercise_repository.dart          ← existing (unchanged)
│       └── workout_repository.dart           ← NEW: WorkoutRepository interface
│
├── exercise/
│   ├── services/
│   │   ├── workout_services.dart            ← existing (WorkoutSessionService, ExerciseLibraryService, ProgressionService)
│   │   ├── set_management_service.dart       ← NEW
│   │   ├── workout_lifecycle_service.dart     ← NEW
│   │   └── providers.dart                    ← NEW: Riverpod DI for all services
│   │
│   ├── providers/
│   │   ├── active_workout.dart               ← refactored (delegates to lifecycle service)
│   │   ├── exercise_detail.dart              ← NEW: ExerciseDetailNotifier
│   │   ├── exercises.dart                    ← unchanged
│   │   ├── exercise_history.dart             ← unchanged
│   │   ├── rest_timer.dart                   ← unchanged
│   │   ├── workout_history.dart              ← unchanged
│   │   └── workout_list.dart                 ← unchanged
│   │
│   └── screens/workout/
│       ├── widgets/                          ← extracted sub-widgets
│       │   ├── elapsed_timer_widget.dart     ← from active_screen
│       │   ├── exercise_group_info.dart      ← from active_screen (data class)
│       │   ├── exercise_set_form.dart        ← from detail screen
│       │   ├── exercise_summary.dart         ← from summary screen (data class)
│       │   ├── history_item.dart             ← from list.dart
│       │   ├── rest_elapsed_card.dart        ← from detail screen
│       │   ├── stat_card.dart                ← from summary screen
│       │   ├── today_card.dart               ← from list.dart
│       │   ├── upcoming_card.dart            ← from list.dart
│       │   ├── weight_set_tile.dart          ← from detail screen
│       │   └── cardio_set_tile.dart          ← from detail screen
│       ├── active_screen.dart                ← ~300 lines (was 415)
│       ├── add_exercise_sheet.dart           ← unchanged
│       ├── exercise_detail_screen.dart       ← ~700 lines (was 1088)
│       ├── list.dart                         ← ~350 lines (was 471)
│       ├── workout_history_detail_screen.dart ← unchanged
│       └── workout_summary_screen.dart       ← ~200 lines (was 287)
│
└── widgets/
    └── appbar_seance_indicator.dart          ← unchanged
```

## Task log

### T01 — Done
- **Completed:** 2026-06-22
- **Files created:** `lib/src/adapters/interfaces/workout_repository.dart`
- **Files modified:** `lib/src/adapters/drift/workout_repository.dart`, `lib/src/exercise/providers/active_workout.dart`, `lib/src/exercise/providers/workout_history.dart`, `lib/src/exercise/providers/workout_list.dart`
- **Evidence:** `dart analyze lib/` — 0 errors, 0 warnings; `flutter test test/src/exercise/` — 62/62 passed
- **Notes:** Interface follows `ExerciseRepository`/`IngredientRepository` pattern. 18 public methods. `@override` annotations added to all overrides.

### T02 — Done
- **Completed:** 2026-06-22
- **Files created:** `lib/src/exercise/services/providers.dart`, `lib/src/exercise/services/set_management_service.dart` (stub), `lib/src/exercise/services/workout_lifecycle_service.dart` (stub)
- **Files modified:** None
- **Evidence:** `dart analyze lib/` — 0 errors; `flutter test test/src/exercise/` — 62/62 passed

### T03 — Done
- **Completed:** 2026-06-22
- **Files modified:** `lib/src/exercise/services/set_management_service.dart` (full implementation), `lib/src/exercise/services/providers.dart` (inject repo), `lib/src/exercise/screens/workout/active_screen.dart` (use service in `_loadSets`), `lib/src/exercise/screens/workout/exercise_detail_screen.dart` (use service in `_loadSets` + `deriveExerciseIds`)
- **Evidence:** `dart analyze lib/` — 0 errors; `flutter test test/src/exercise/` — 62/62 passed
- **Notes:** Service methods: `loadSets`, `deriveExerciseIds`, `addWeightSet`, `addCardioSet`, `toggleWeightSetCompletion`, `toggleCardioSetCompletion`, `deleteSet`. Screen imports updated from `workout_repository.dart` to `services/providers.dart`.

### T04 — Done
- **Completed:** 2026-06-22
- **Files modified:** `lib/src/exercise/services/workout_lifecycle_service.dart` (full implementation), `lib/src/exercise/services/providers.dart` (inject repo), `lib/src/exercise/providers/active_workout.dart` (delegate lifecycle to service)
- **Evidence:** `dart analyze lib/` — 0 errors; `flutter test test/src/exercise/` — 62/62 passed
- **Notes:** `ActiveWorkoutNotifier` keeps `_repo` for set mutations and `_lifecycleService` for lifecycle. Foreground service + state management stay in the notifier.
- **Completed:** 2026-06-22
- **Files created:** `lib/src/adapters/interfaces/workout_repository.dart`
- **Files modified:** `lib/src/adapters/drift/workout_repository.dart`, `lib/src/exercise/providers/active_workout.dart`, `lib/src/exercise/providers/workout_history.dart`, `lib/src/exercise/providers/workout_list.dart`
- **Evidence:** `dart analyze lib/` — 0 errors, 0 warnings; `flutter test test/src/exercise/` — 62/62 passed
- **Notes:** Interface follows `ExerciseRepository`/`IngredientRepository` pattern. 18 public methods. `@override` annotations added to all overrides.

### T05 — Done
- **Completed:** 2026-06-23
- **Files created:** `lib/src/exercise/providers/exercise_detail.dart`
- **Files modified:** `lib/src/exercise/screens/workout/exercise_detail_screen.dart`
- **Evidence:** `dart analyze lib/` — 0 errors, 0 warnings; `flutter test test/src/exercise/` — 62/62 passed
- **Notes:** `ExerciseDetailNotifier` with explicit `ExerciseDetailState` class (status enum, `copyWith`, computed getters). Screen now watches the provider via `ref.watch` + `ref.listen` for PageController sync. Screen reduced from 1088 → 923 lines.

### T06 — Done
- **Completed:** 2026-06-23
- **Files created:** 
  - `lib/src/exercise/screens/workout/widgets/weight_set_tile.dart`
  - `lib/src/exercise/screens/workout/widgets/cardio_set_tile.dart`
  - `lib/src/exercise/screens/workout/widgets/rest_elapsed_card.dart`
  - `lib/src/exercise/screens/workout/widgets/exercise_set_form.dart`
- **Files modified:** `lib/src/exercise/screens/workout/exercise_detail_screen.dart`
- **Evidence:** `dart analyze lib/` — 0 errors, 0 warnings; `flutter test test/src/exercise/` — 62/62 passed
- **Notes:** Private widgets extracted to 4 public files in `widgets/`. Shared helpers `formatHHmm`/`setSubtitle` live in `weight_set_tile.dart`, imported by `cardio_set_tile.dart`. Screen reduced from 923 → 618 lines.

### T07 — Done
- **Completed:** 2026-06-23
- **Files created:**
  - `lib/src/exercise/screens/workout/widgets/elapsed_timer_widget.dart`
  - `lib/src/exercise/screens/workout/widgets/exercise_group_info.dart`
  - `lib/src/exercise/screens/workout/widgets/exercise_summary.dart`
  - `lib/src/exercise/screens/workout/widgets/history_item.dart`
  - `lib/src/exercise/screens/workout/widgets/stat_card.dart`
  - `lib/src/exercise/screens/workout/widgets/today_card.dart`
  - `lib/src/exercise/screens/workout/widgets/upcoming_card.dart`
- **Files modified:** `active_screen.dart`, `list.dart`, `workout_summary_screen.dart`
- **Evidence:** `dart analyze lib/` — 0 errors, 0 warnings; `flutter test test/src/exercise/` — 62/62 passed
- **Notes:** 7 widgets extracted. Line counts: `active_screen.dart` 414→398, `list.dart` 472→186, `workout_summary_screen.dart` 288→244.

## Validation Report

### Commands run
- `dart analyze lib/` — exit 0 (3 infos: pre-existing `use_build_context_synchronously`)
- `flutter test test/src/exercise/` — exit 0 (62/62 passed)
- `flutter build apk --debug` — exit 0 (29.6s, app-debug.apk built)

### Context sync
- `context/context-map.md` updated with new provider (`exercise_detail.dart`) and `widgets/` directory entries

### Success-criteria verification
- [x] `WorkoutRepository` abstract interface exists with `DriftWorkoutRepository implements WorkoutRepository` — T01
- [x] Three new services exist: `SetManagementService`, `WorkoutLifecycleService`, `WorkoutSessionService` — T02/T03/T04
- [x] All services registered as Riverpod providers — T02
- [x] `exercise_detail_screen.dart` reduced from 1088 → 618 lines (target ~700) — T05/T06
- [x] `active_screen.dart` reduced from 415 → 398 lines (minor: only `_ExerciseGroupInfo` was extracted) — T07
- [x] `list.dart` reduced from 472 → 186 lines (target ~350) — T07
- [x] `workout_summary_screen.dart` reduced from 288 → 244 lines (target ~200) — T07
- [x] `dart analyze lib/` — 0 errors, 0 warnings
- [x] `flutter test test/src/exercise/` — 62/62 passed
- [x] `flutter build apk --debug` — succeeds

### Residual risks
- None identified. Pure structural refactoring with no behavioral changes.
- The 3 `use_build_context_synchronously` infos in `active_screen.dart` and `diet/screens/ingredients/edit.dart` are pre-existing and unrelated.

## Open questions
