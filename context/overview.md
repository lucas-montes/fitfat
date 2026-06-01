# FitFat Overview

FitFat is a Flutter app for fitness and nutrition tracking.

## What the app does now
- Tracks meals and ingredients with macro totals.
- Tracks exercise sessions (`seances`), exercise libraries, and workout templates.
- Shows a dashboard with workout activity summary, training heatmap, water tracking, weight tracking, daily nutrition, goals, and charts.
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
- `Dashboard`: focused daily glance — calories/macros, workout status, active goals, weight (conditional), 7-day streaks. Also has Goals and Settings sub-tabs.
- `Exercise`: workout sessions, templates, exercise history, training stats, heatmap, and trend charts.
- `current-seance`: full-screen active workout session route.

## Current app shape
- `lib/main.dart` boots Flutter, logging, and foreground-task callbacks.
- `lib/src/app/router.dart` defines the bottom-nav shell and the active-session route.
- `lib/src/app/theme.dart` defines Material 3 theme with custom typography, card shapes, input decoration, and button styles.
- `lib/src/database/` defines Drift tables and the database provider.
- `lib/src/models/` holds domain models for food, exercise, dashboard, and seance data.
- `lib/src/adapters/drift/` converts between Drift rows and domain models.
- `lib/src/diet/`, `lib/src/dashboard/`, and `lib/src/exercise/` contain the feature UI and Riverpod controllers.

## Localization
- **ARB-based generated localization** via `flutter gen-l10n`. Files in `lib/l10n/`:
  - `app_en.arb`, `app_fr.arb`, `app_es.arb` — string definitions
  - `app_localizations.dart` — generated `AppLocalizations` class (do not edit manually)
- Configured via `l10n.yaml` at project root.
- `pubspec.yaml` has `generate: true` under `flutter:`.
- Supports en, fr, es.

## Inferred product intent
- The app appears to combine food logging, gym session tracking, and goal-based nutrition guidance.
- The naming suggests an in-progress or refactored personal fitness tracker; terminology should be normalized around a localized workout vocabulary.

## Settings tab (Dashboard sub-tab)
- **Profile section**: edit profile via `ProfileSetupDialog`, shows current profile summary.
- **Nutrition section**: macro visibility toggles via `dietPreferencesProvider` with `SwitchListTile` for each macro (calories, protein, carbs, fat).
- **Workout section**: rest timer default (placeholder).
- **Appearance section**: theme (placeholder).
- **Data section**: export database, delete all data (existing functionality).

## Exercise module specifics
- **Two workout modes**: Guided mode follows predefined templates with auto-complete sets. Free-form mode allows ad-hoc set entry with smart pre-fill from last set.
- **Rest timer**: Countdown between sets with sound/vibration alert, configurable per exercise in templates (uses existing `restBetweenSets` / `restSeconds` fields).
- **Progression tracking**: Estimated 1RM, volume (sets×reps×weight), max weight, and personal records — charted over time.
- **Bundled exercise library**: ~30-40 common exercises seeded on first launch, organized by muscle group. Users can also create custom exercises.
- **Dashboard workout summary**: the dashboard surfaces today's workout status (active or last completed), plus a 7-day workout streak mini-heatmap. Training stats, full heatmap, and trend charts live in the Exercise tab.
- **Dashboard goals overview**: compact card showing all active goals (bodyweight, strength) with progress indicators.
- **Dashboard streaks**: two side-by-side 7-day mini-heatmaps for calorie compliance and workout consistency.
- **Dashboard bodyweight tracker**: bodyweight entry card shown only when a bodyweight goal exists.
- **Service layer needed**: Business logic (session state, rest timer, progression calculations) should be extracted into pure Dart service classes.
- **Provider separation**: The 555-line `seance.dart` provider file should be split into focused files per concern (active session, history, templates, exercise list).
- **Abstract repository interfaces**: Needed for `SeanceRepository` and `ExerciseRepository` to support testability and future alternative backends.

## Open questions
- Which localization system should be used for `en`, `fr`, and `es`.
- Whether any settings deserve their own sub-flows beyond the dashboard tab.
- Which refactor targets should be prioritized first for testability and bug reduction.
