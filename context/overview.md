# FitFat — Project Overview

A Flutter fitness tracking app with diet, exercise, and dashboard features.

## Architecture

- **State management:** Riverpod (StateNotifierProvider with `AsyncValue`)
- **Database:** Drift (SQLite), schema version 1 (reset — no migration chain)
- **Persistence:** SQLite for all permanent data, no SharedPreferences for exercise module
- **Navigation:** GoRouter with `StatefulShellRoute` (3-tab layout) + top-level routes `/active-workout`, `/create-workout`, `/workout-summary/:id`, `/workout-history/:id` (full-screen, no bottom nav)

## Domain modules

- **exercise/** — workout tracking, exercise library, stats. Unified Workout model with WeightSet/CardioSet. Completed rewrite. See [architecture.md](architecture.md).
- **diet/** — meal logging, ingredient database, macro tracking
- **dashboard/** — goals, body weight, TDEE, nutrition summaries, step/water tracking

## Completed work

| Date | Plan | Summary |
|------|------|---------|
| Jun 18 | Exercise module rewrite | Unified Workout model, DB schema, DriftWorkoutRepository, new providers, restructured screens |
| Jun 19 | Active workout exercise management | Exercise/set management in active workout, add-exercise sheet, exercise detail screen |
| Jun 19 | Active workout UX fixes | Notification tap race condition, top card resume button, inline add-set form, history ordering |
| Jun 20 | Workout UX enhancements | Auto-complete sets, live timer, summary screen, history detail view, swipe between exercises, elapsed rest timer |
| Jun 22-23 | Exercise module refactor | Three-layer architecture: WorkoutRepository interface, service layer, ExerciseDetailNotifier, widget extraction |
| Jun 24 | Active workout polish | Rest timer persistence, compact chips/notes/tiles, back nav, stat cards, independent history scroll, smaller heatmap, history snippet, duplicate timer removal |
| Jun 25 | Provider init bugfix | Fix crash when adding exercise during active workout (uninitialized provider state) |
| Jun 25 | Training tab blank fix | Remove full-screen empty state, always render three-section layout with per-section placeholders |
| Jun 26-27 | Workout UX round 2 | History mini-tiles, compact form, free-form/planned separate forms, add-exercise pill, PageView performance, equal-height stat cards, exercise_translations DB table |
| Jun 30 | Workout comparison & stats | Edit-set crash fix, per-exercise stats, planned-vs-accomplished display, PR attempt tracking (isFailed) |
| Jun 30 | Remove free-form workouts | Removed free-form mode, reset DB to schema v1 with onUpgrade handler, simplified model (scheduledDate required), created planned-only creation UI |
