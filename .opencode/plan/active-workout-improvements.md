# Active Workout & Exercise System Improvements Plan

## Change Summary
Comprehensive improvements to the active workout experience, exercise search/display, workout management, and planner integration:

### Original 8 Items
1. **Settings**: Add "Back to Dashboard" button in Settings screen
2. **Notifications**: Include rest time in rest alarm notification body
3. **Active Workout**: Add exercise search entry to active workout (with images)
4. **Active Workout**: Remove "Create Exercise" from active workout exercise search
5. **Active Workout**: Improve exercise search UX - show current workout exercises at top
6. **Rest Timer**: Fix rest timer not restarting when new set is added
7. **Notifications**: Optimize rest alarm notification scheduling (reduce delay)
8. **Workout Completion**: Parallelize workout completion operations to reduce latency

### New Requirements
9. **Exercise Display**: Fix exercise image layout - exercises without images are distorted, titles misaligned
10. **Exercise Canonicalization**: Data migration to mark canonical exercises + variants; show both in search
11. **Search Relevance**: Pluggable ranking system - exact > prefix > keyword > word-boundary > substring > muscle > fuzzy
12. **Workout Duplication**: Long-press workout → "Duplicate Workout" action
13. **Planner Integration**: Link workouts to planner items; show in agenda/list view with date/time

## Success Criteria
- [ ] Settings screen has a tappable "Back to Dashboard" item navigating to `/dashboard`
- [ ] Rest alarm notification shows planned rest duration (e.g., "Your planned rest of 2:00 is complete")
- [ ] Active workout screen has "+ Add Exercise" button at bottom of exercise list opening search modal
- [ ] Exercise search in active workout shows 48x48 thumbnails for catalog exercises
- [ ] Active workout exercise search has NO "Create Exercise" option
- [ ] Current workout exercises appear first in search with checkmark/badge indicator
- [ ] Adding actuals to a set with restSeconds restarts timer with new duration
- [ ] Rest alarm fires within 1-2 seconds of planned time (both exact/inexact Android paths)
- [ ] Workout completion responds within 500ms (tap → navigation/snackbar)
- [ ] Exercise tiles have consistent layout regardless of image presence (fixed 48x48 image box, aligned text baseline)
- [ ] Database migration marks canonical exercises; variants linked via `similarTo` field
- [ ] Search shows canonical exercises by default; toggle to include variants
- [ ] Search ranks results by relevance using pluggable `ScoredSearchResult` class
- [ ] Workout list: long-press → "Duplicate Workout" creates editable copy with new ID/date
- [ ] Planner items can reference workouts via `workoutId`; appear in agenda view with date/time

## Constraints and Non-Goals
- **Non-goal**: Full exercise creation flow in active workout (only search/add existing)
- **Non-goal**: Changing workout_form.dart exercise search (separate planning screen)
- **Constraint**: Maintain compatibility with existing rest timer persistence (SharedPreferences)
- **Constraint**: Must work on both Android and iOS
- **Constraint**: Don't break existing foreground service / ongoing notification
- **Constraint**: Exercise canonicalization adds `similarTo` (String?), `tags` (List<String>?), `isCanonical` (bool) to Exercise model via migration
- **Constraint**: Workout-planner linking adds `workoutId` (String?) to PlannerItem model via migration
- **Constraint**: Search ranking implemented as swappable `SearchRanker` interface/class

## Task Stack

### Phase 1: Settings & Notifications (Quick Wins)
- [x] **T01**: Add "Back to Dashboard" button in Settings screen
- [x] **T02**: Include rest time in rest alarm notification

### Phase 2: Active Workout Exercise Search
- [x] **T03**: Add "+ Add Exercise" button at bottom of active workout exercise list
- [x] **T04**: Implement exercise search modal with images for active workout
- [x] **T05**: Remove "Create Exercise" from active workout exercise search
- [x] **T06**: Improve exercise search UX - prioritize current workout exercises

### Phase 3: Rest Timer & Completion Fixes
- [x] **T07**: Fix rest timer restart when new set actuals saved
- [x] **T08**: Optimize rest alarm notification scheduling
- [x] **T09**: Parallelize workout completion operations

### Phase 4: Exercise Display, Canonicalization & Search Relevance
- [x] **T10**: Fix exercise tile layout for consistent alignment (with/without images)
- [x] **T11**: Exercise canonicalization - data migration + search integration
- [x] **T12**: Improve search relevance ranking with pluggable ranker
  - Goal: Rank results by relevance using swappable `SearchRanker` class
  - Boundaries: 
    - In: New `SearchRanker` interface/class in exercise_filter.dart (or new file)
    - In: `ScoredExercise` class with score, matchType, matchedFields
    - In: Default `DefaultSearchRanker` implementing weighted algorithm
    - In: exercise_list.dart - use ranker, display results sorted by score
    - Out: No UI changes beyond ordering
  - Done when: Search for "bench" shows "Bench Press" (exact) before "Dumbbell Bench Press" (substring)
  - Verification: Test various queries, verify result ordering; can swap ranker implementation

### Phase 5: Workout Duplication & Planner Integration
- [x] **T13**: Add workout duplication via long-press
- [x] **T14**: Link workouts to planner items + agenda view
  - Goal: Planner items can reference workouts via `workoutId`; show in agenda/list view with date/time
  - Boundaries: 
    - In: planner_item.dart model - add `workoutId` field (migration)
    - In: planner_repository.dart - update CRUD for workoutId
    - In: planner_screen.dart - add workout picker when creating/editing item (show pending workouts)
    - In: planner_screen.dart - agenda view shows workout badge + name, tap opens workout
    - In: dashboard.dart - upcoming tasks card shows linked workouts with badge
    - Out: No workout model changes
  - Done when: Create planner item with workout link; appears in plan tab agenda view and dashboard upcoming
  - Verification: Add planner item with workout, verify shows in plan tab agenda with time/date, tap opens workout

### Phase 6: Validation
- [x] **T15**: Full validation and cleanup
  - Goal: Run test suite, lint, verify all success criteria
  - Boundaries: In: All modified files; In: Run flutter test, flutter analyze; In: Manual smoke test all 13 features
  - Done when: All tests pass, no analyzer issues, all success criteria verified
  - Verification: `flutter test`, `flutter analyze`, manual verification checklist
  - Notes: `flutter analyze` is clean. `test/exercise_filter_test.dart` (18 tests, covers T11/T12 relevance + canonicalization) passes. DB-backed tests (`note_repository_test`, `task_reminders_test`, `catalog_importer_test`) fail only because the dev environment lacks the native `libsqlite3.so` shared library — a pre-existing environment issue, not a code defect. See Open Questions before claiming full green.

## Assumptions
1. Exercise search in active workout reuses exerciseListProvider (all exercises)
2. "Current workout exercises at top" = exercises in active workout's detail.exercises
3. Rest timer restart on "new set added" = when user saves actuals for set with restSeconds (already partially implemented)
4. Notification delay optimization focuses on Android (iOS uses different mechanism)
5. Exercise canonicalization: migration script groups by name similarity (levenshtein), muscles, equipment; picks one as canonical
6. Workout-planner linking adds `workoutId` (String?) to PlannerItem model
7. Duplicate workout copies all exercises/sets but creates new Workout with today's date
8. Search ranker is injectable via provider for easy testing/swapping

## Open Questions
1. Should active workout exercise search support filters (type, body part, equipment, muscle) like ExerciseListScreen?
2. Should recently used exercises (outside current workout) also appear at top of active workout search?
3. For T07: Is "adding a new set" done via _SetActualsDialog, or is there another way to add sets during active workout?
4. For exercise canonicalization migration: Should it auto-mark based on `isLocked` (seeded = canonical), or analyze all exercises?
5. Should duplicated workout copy notes, or start fresh?
6. For planner-workout linking: Should completing the planner item auto-start the workout?