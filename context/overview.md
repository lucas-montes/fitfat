# FitFat — Project Overview

A Flutter fitness tracking app with diet, exercise, and dashboard features.

## Architecture

- **State management:** Riverpod (StateNotifierProvider with `AsyncValue`)
- **Database:** Drift (SQLite), schema version 13
- **Persistence:** SQLite for all permanent data, no SharedPreferences for exercise module
- **Navigation:** GoRouter with `StatefulShellRoute` (3-tab layout) + top-level `/active-workout` route (full-screen, no bottom nav)

## Domain modules

- **exercise/** — workout tracking, exercise library, stats. Unified Workout model with WeightSet/CardioSet. Completed rewrite. See [architecture.md](architecture.md).
- **diet/** — meal logging, ingredient database, macro tracking
- **dashboard/** — goals, body weight, TDEE, nutrition summaries, step/water tracking

## Completed work

- **Exercise module rewrite** (June 2026) — unified Workout model, DB schema v12, DriftWorkoutRepository, new providers, restructured screens. See [plans/exercise-module-rewrite.md](plans/exercise-module-rewrite.md).
