# FitFat Overview

FitFat is a Flutter app for fitness and nutrition tracking.

## What the app does now
- Tracks meals and ingredients with macro totals.
- Tracks exercise sessions (`seances`), exercise libraries, and workout templates.
- Shows a dashboard with daily nutrition, goals, and charts.
- Persists data locally with Drift/SQLite and a small amount of `SharedPreferences` state for the active session.

## Product direction
- Training and nutrition are equally important.
- The app should be offline-first and usable without internet.
- The workout domain should be named `workout` in user-facing language, while allowing localization for French, English, and Spanish.
- The dashboard is the preferred place for settings as a tab.
- The app is for a single person rather than multi-account use.
- The current priority is polishing the app, simplifying the codebase, improving testability, and removing bugs.

## Top-level navigation
- `Diet`: meal log and ingredient list.
- `Dashboard`: nutrition overview, goals, profile/settings, and trend charts.
- `Exercise`: workout sessions, templates, and exercise history.
- `current-seance`: full-screen active workout session route.

## Current app shape
- `lib/main.dart` boots Flutter, logging, and foreground-task callbacks.
- `lib/src/app/router.dart` defines the bottom-nav shell and the active-session route.
- `lib/src/database/` defines Drift tables and the database provider.
- `lib/src/models/` holds domain models for food, exercise, dashboard, and seance data.
- `lib/src/adapters/drift/` converts between Drift rows and domain models.
- `lib/src/diet/`, `lib/src/dashboard/`, and `lib/src/exercise/` contain the feature UI and Riverpod controllers.

## Inferred product intent
- The app appears to combine food logging, gym session tracking, and goal-based nutrition guidance.
- The naming suggests an in-progress or refactored personal fitness tracker; terminology should be normalized around a localized workout vocabulary.

## Open questions
- Which localization system should be used for `en`, `fr`, and `es`.
- Whether any settings deserve their own sub-flows beyond the dashboard tab.
- Which refactor targets should be prioritized first for testability and bug reduction.
