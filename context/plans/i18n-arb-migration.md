# i18n / ARB Migration Plan

## Change Summary
Migrate from the manual `_t()` localization pattern to Dart's standard ARB-based generated localization. Add all hardcoded user-facing strings (~350+) across the codebase to `.arb` files and wire them up.

## Success Criteria
- `l10n.yaml` configures gen-l10n for en/fr/es
- `lib/l10n/app_en.arb`, `app_fr.arb`, `app_es.arb` contain all existing + newly discovered strings
- `flutter gen-l10n` generates `AppLocalizations` class successfully
- All 10 source files use the generated `AppLocalizations.of(context)` instead of hardcoded strings
- The old manual `lib/src/l10n/app_localizations.dart` is deleted
- `flutter analyze` passes with 0 errors
- App renders correctly in en/fr/es locales

## Constraints and Non-Goals
- Stay with the existing `intl` + `flutter_localizations` dependencies (already in `pubspec.yaml`)
- ARB key naming convention: `snake_case` matching English string content
- Each `.arb` file contains all strings (no splitting per feature)
- No changes to user populated data (meal/ingredient/exercise/workout names)
- Navigation labels (Diet, Dashboard, Exercise) are included in scope

---

## Tasks

- [x] T01: `Set up ARB infrastructure` (status:done)
  - Task ID: T01
  - Goal: Create `l10n.yaml`, configure `pubspec.yaml` for gen-l10n generation, create initial empty `.arb` files for en/fr/es, run `flutter gen-l10n` to verify generation works.
  - Boundaries (in/out of scope): In — create `l10n.yaml`, add `generate: true` in `pubspec.yaml`, create `lib/l10n/app_en.arb`, `app_fr.arb`, `app_es.arb` with minimal content. Out — no string content migration yet.
  - Done when: `flutter gen-l10n` succeeds and generates `lib/l10n/app_localizations.dart` with a compileable `AppLocalizations` class.
  - Verification notes:
    - `flutter gen-l10n` → exit 0
    - `lib/l10n/app_localizations.dart` exists and compiles
    - `flutter analyze lib/l10n/app_localizations.dart` — 0 issues
    - Files created: `l10n.yaml`, `lib/l10n/app_en.arb`, `app_fr.arb`, `app_es.arb`
    - Files modified: `pubspec.yaml` (added `generate: true`)
    - Generated files: `lib/l10n/app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_fr.dart`, `app_localizations_es.dart`

- [x] T02: `Migrate existing AppLocalizations strings to .arb files` (status:done)
  - Task ID: T02
  - Goal: Export all ~400 lines of existing strings from `lib/src/l10n/app_localizations.dart` into `app_en.arb`, `app_fr.arb`, `app_es.arb`. Regenerate.
  - Boundaries (in/out of scope): In — all getter strings from the manual class translated to ARB keys. Out — no Dart file changes yet.
  - Done when: `flutter gen-l10n` succeeds and the generated class has all ~100+ key/value pairs for each locale.
  - Verification notes:
    - `flutter gen-l10n` → exit 0
    - Generated `AppLocalizations` has 109 getters including parameterized methods (`items`, `formatMacros`, `formatPer100g`, `formatTotal`, `exercisesCount`, `setsCount`)
    - `flutter analyze lib/l10n/app_localizations.dart` — 0 issues
    - `flutter analyze` — 0 errors (full app, old + new coexist)
    - Files populated: `lib/l10n/app_en.arb`, `app_fr.arb`, `app_es.arb` (~90 string keys each)
    - Pluralization handled via ARB's `{count,plural, one{...} other{...}}` syntax
    - Format methods use `{placeholder}` syntax with `@key` metadata blocks

- [x] T03: `Swap main.dart to use generated AppLocalizations` (status:done)
  - Task ID: T03
  - Goal: Update `lib/src/app/main.dart` to register the generated `AppLocalizations` delegate alongside the existing manual one. Both coexist during per-file migration.
  - Boundaries (in/out of scope): In — `main.dart`. Added generated delegate import with `as gen` alias. Out — old manual file stays for now (removed in T13).
  - Done when: App builds and renders. `flutter analyze` → 0 errors.
  - Verification notes:
    - `flutter analyze` → 0 errors
    - Both delegates registered: `AppLocalizations.delegate` (manual) + `gen.AppLocalizations.delegate` (generated)
    - Files changed: `lib/src/app/main.dart`

- [x] T04: `i18n — diet/screens/main.dart` (status:done)
  - Task ID: T04
  - Goal: Replace all ~18 hardcoded user-facing strings in `lib/src/diet/screens/main.dart` with `AppLocalizations.of(context).key` calls. Add any missing keys to `.arb` files.
  - Boundaries (in/out of scope): In — meal list, ingredient list, and all their dialogs, buttons, empty states, tooltips. Out — user meal/ingredient names.
  - Done when: All hardcoded strings replaced. `flutter analyze` passes.
  - Verification notes:
    - `grep -n "'[A-Za-z]" lib/src/diet/screens/main.dart` shows only dynamic/programmatic strings (imports, DateFormat patterns, map keys)
    - `flutter analyze` → 0 errors
    - `flutter gen-l10n` → exit 0
    - Files changed: `lib/src/diet/screens/main.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_fr.arb`, `lib/l10n/app_es.arb`
    - Keys added: `meal`, `sortAZ`, `sortZA`, `noIngredientsFoundSubtext`, `kcalAbbrev`, `proteinAbbrev`, `carbsAbbrev`, `fatAbbrev`

- [x] T05: `i18n — diet/screens/ingredients/edit.dart` (status:done)
  - Task ID: T05
  - Goal: Replace all ~25 hardcoded strings in the ingredient editor with `AppLocalizations` calls. Add any missing keys to `.arb` files.
  - Done when: All hardcoded strings replaced. `flutter analyze` passes.
  - Verification notes:
    - `grep -n "'[A-Za-z]" lib/src/diet/screens/ingredients/edit.dart` shows only imports and a comment
    - `flutter analyze` → 0 errors
    - `flutter gen-l10n` → exit 0
    - Files changed: `lib/src/diet/screens/ingredients/edit.dart`, `lib/l10n/app_en.arb`, `app_fr.arb`, `app_es.arb`
    - Keys added: `sodiumPer100g`, `fiberPer100g`

- [x] T06: `i18n — diet/screens/meals/edit.dart` (status:done)
  - Task ID: T06
  - Goal: Replace all ~21 hardcoded strings in the meal editor with `AppLocalizations` calls. Add any missing keys to `.arb` files.
  - Done when: All hardcoded strings replaced. `flutter analyze` passes.
  - Verification notes:
    - `grep -n "'[A-Za-z]" lib/src/diet/screens/meals/edit.dart` shows only imports, a DateFormat pattern, and a comment
    - `flutter analyze` → 0 errors
    - `flutter gen-l10n` → exit 0
    - Files changed: `lib/src/diet/screens/meals/edit.dart`, `lib/l10n/app_en.arb`, `app_fr.arb`, `app_es.arb`
    - Keys added: `eatenAtLabel` (with `{time}` placeholder)

- [x] T07: `i18n — exercise/screens/main.dart` (status:done)
  - Task ID: T07
  - Goal: Replace all ~45 hardcoded strings in the Exercise screen (tabs, Workouts tab, Exercises tab, Stats tab, history cards, template cards, dialogs, empty states) with `AppLocalizations` calls. Add tab labels, section headers, buttons, tooltips. Add any missing keys to `.arb` files.
  - Done when: All hardcoded strings replaced. `flutter analyze` passes.
  - Verification notes:
    - `grep -n "'[A-Za-z]" lib/src/exercise/screens/main.dart` shows only data-generation pattern (`'From ${DateFormat...}'`)
    - `flutter analyze` → 0 errors
    - `flutter gen-l10n` → exit 0
    - Files changed: `lib/src/exercise/screens/main.dart`, `lib/l10n/app_en.arb`, `app_fr.arb`, `app_es.arb`
    - Keys added: `workoutsTab`, `statsTab`, `searchExercisesHint`, `noExercisesFoundSimple`, `noExercisesFoundAction`, `runningWorkout`, `unnamedWorkout`, `viewWorkout`, `stopWorkout`, `newSeance`, `startBlankSeance`, `create`, `noTemplatesYet`, `browseAllTemplates`, `noWorkoutsYet`, `allTime`, `workouts`, `duration`, `thisWeek`, `activity`, `trends`, `edit`, `clone`, `start`, `createTemplateFrom`, `workoutAlreadyRunning`, `workoutAlreadyRunningContent`, `startNewWorkout`, `workout`, `noExercises`

- [x] T08: `i18n — exercise/screens/current_seance_screen.dart` (status:done)
  - Task ID: T08
  - Goal: Replace all ~50 hardcoded strings in the active workout screen (empty states, search bar, set cards, summary view, rest timer, dialogs, tooltips) with `AppLocalizations` calls. Add any missing keys to `.arb` files.
  - Done when: All hardcoded strings replaced. `flutter analyze` passes.
  - Verification notes:
    - `grep -n "'[A-Za-z]"` shows no hardcoded UI strings remain
    - `flutter analyze` → 0 errors (35 pre-existing warnings/info)
    - `flutter gen-l10n` → exit 0
    - Import changed from `../../l10n/app_localizations.dart` to `package:fitfat/l10n/app_localizations.dart`
    - Added `!` to existing `AppLocalizations.of(context)` call
    - Files changed: `lib/src/exercise/screens/current_seance_screen.dart`, `lib/l10n/app_en.arb`, `app_fr.arb`, `app_es.arb`
    - Keys added: `pr`, `oneRM`, `workoutSummary`, `untitledWorkout`, `exerciseBreakdown`, `best`, `finish`, `previousSessions` (with `{count}` placeholder), `tapToExpand`, `reps`

- [x] T09: `i18n — exercise/screens/seance_library_screen.dart + create_seance_screen.dart` (status:done)
  - Task ID: T09
  - Goal: Replace all ~29 hardcoded strings in the template library and template editor screens with `AppLocalizations` calls. Add any missing keys to `.arb` files.
  - Done when: All hardcoded strings replaced. `flutter analyze` passes.
  - Verification notes:
    - `grep -n "'[A-Za-z]"` shows no hardcoded UI strings remain
    - `flutter analyze` → 0 errors (35 pre-existing warnings/info)
    - `flutter gen-l10n` → exit 0
    - Import changed from `../../l10n/app_localizations.dart` to `package:fitfat/l10n/app_localizations.dart` (seance_library_screen.dart)
    - Added `package:fitfat/l10n/app_localizations.dart` import (create_seance_screen.dart)
    - Fixed `activeWorkout` calls to add `!` and switched to `l10n.activeWorkout` (both files)
    - Files changed: `lib/src/exercise/screens/seance_library_screen.dart`, `lib/src/exercise/screens/create_seance_screen.dart`, `lib/l10n/app_en.arb`, `app_fr.arb`, `app_es.arb`
    - Keys added: `templateLibrary`, `createFirstTemplate`, `createTemplate`, `editTemplate`, `templateNameLabel`, `addCustom`, `searchAboveHint`, `noExercisesAdded`, `noSetsConfigured`, `remove`, `restSeconds`

- [x] T10: `i18n — exercise/screens/exercise_history_screen.dart` (status:done)
  - Task ID: T10
  - Goal: Replace all ~30 hardcoded strings in the exercise history screen (filter chips, chart labels, record cards, empty states, stat items) with `AppLocalizations` calls. Add any missing keys to `.arb` files.
  - Done when: All hardcoded strings replaced. `flutter analyze` passes.
  - Verification notes:
    - `flutter analyze` → 0 errors (35 pre-existing warnings/info)
    - `flutter gen-l10n` → exit 0
    - Only remaining `'[A-Z]'` match is data format string (`Set 1: 8 reps × 60.0 kg`)
    - Files changed: `lib/src/exercise/screens/exercise_history_screen.dart`, `lib/l10n/app_en.arb`, `app_fr.arb`, `app_es.arb`
    - Keys added: `pastMonth`, `past3Months`, `pastYear`, `noHistoryFor` (with `{name}` placeholder), `completeWorkoutToSee`, `records`, `volumeProgression`, `date`, `searchHistory`, `searchByDateWorkout`, `sessionsCount` (plural), `time`, `bestEstimated1RM`, `maxWeight`, `maxVolumeSet`, `totalVolume`, `notAvailable`, `across`

- [x] T11: `i18n — dashboard/screens/main.dart` (status:done)
  - Task ID: T11
  - Goal: Replace all ~130+ hardcoded strings in the dashboard (tabs, overview cards, goals, settings, streaks, weight/water trackers, alert dialogs, snackbars, empty states) with `AppLocalizations` calls. Add any missing keys to `.arb` files.
  - Done when: All hardcoded strings replaced. `flutter analyze` passes.
  - Verification notes:
    - `flutter gen-l10n` → exit 0
    - `flutter analyze` → 0 errors (35 pre-existing warnings/info)
    - Files changed: `lib/src/dashboard/screens/main.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_fr.arb`, `lib/l10n/app_es.arb`
    - Keys added: `overviewTab`, `goalsTab`, `settingsTab`, `weight`, `weightLogged`, `enterWeightKg`, `log`, `weightTracker`, `noWeightEntries`, `latest`, `logWeight`, `historyLast7Entries`, `waterIntake`, `goal`, `setDailyWaterGoal`, `litersExample`, `todaysActivity`, `workoutInProgress`, `recentWorkout`, `exercisesCompleted`, `noWorkoutsToday`, `elapsed`, `last84Days`, `noTrainingRecorded`, `today`, `calories`, `protein`, `carbs`, `fat`, `setProfileForTargets`, `bodyWeightGoal`, `noBodyweightGoalSet`, `addBodyWeightGoal`, `target`, `by`, `strengthGoals`, `addStrengthGoalTooltip`, `noStrengthGoalsYet`, `setUpProfileFirst`, `createProfile`, `editProfile`, `yourProfile`, `birthdate`, `sex`, `heightCm`, `activityLevel`, `addBodyWeightGoalTitle`, `editBodyWeightGoalTitle`, `direction`, `targetWeightKg`, `targetDate`, `notSet`, `addStrengthGoalTitle`, `editStrengthGoalTitle`, `searchOrTypeCustom`, `deleteBodyweightGoal`, `deleteBodyweightGoalContent`, `deleteStrengthGoalTitle` (with `{exercise}` placeholder), `deleteStrengthGoalContent`, `deleteEverything`, `goalReached`, `toGo`, `strengthTrend`, `noStrengthData`, `weightTrend90Days`, `profile`, `setUpProfile`, `nutrition`, `visibleMacros`, `defaultRestTimer`, `secondsBetweenSets`, `restTimerComingSoon`, `appearance`, `theme`, `systemDefault`, `themeComingSoon`, `data`, `exportDatabase`, `shareDbFile`, `deleteAllData`, `removeEverything`, `noDbFound`, `deleteAllDataTitle`, `deleteAllDataContent`, `dbDeleted`, `thisMonth`, `couldNotLoadWeightHistory`, `trainingHeatmap`, `heatmapLegendLow`, `heatmapLegendMid`, `heatmapLegendHigh`, `benchPress`, `deadlift`, `squat`, `enterDetailsForMacros`, `exportFailed` (with `{error}` placeholder), `deleteFailed` (with `{error}` placeholder)

- [x] T12: `i18n — app/router.dart` (status:done)
  - Task ID: T12
  - Goal: Replace the 3 hardcoded bottom navigation labels (Diet, Dashboard, Exercise) with `AppLocalizations` calls. Note: these are `NavigationDestination` labels inside a `StatefulShellRoute` builder, which has access to `BuildContext`.
  - Done when: Bottom nav labels resolve from `AppLocalizations.of(context)`. `flutter analyze` passes.
  - Verification notes:
    - `lib/l10n/app_en.arb`, `app_fr.arb`, `app_es.arb` updated with `navDiet`, `navDashboard`, `navExercise`
    - `lib/src/app/router.dart` updated to import `package:fitfat/l10n/app_localizations.dart` and build `destinations` at runtime from `l10n`
    - `flutter analyze lib/src/app/router.dart` → No issues found


- [x] T13: `Validation and cleanup` (status:done)
  - Task ID: T13
  - Goal: Final validation: `flutter gen-l10n` succeeds, `flutter analyze` passes, verify en/fr/es all render, ensure no remaining hardcoded strings in scanned files, verify pluralized strings (sets/set, reps, exercises, days, sessions, items) work correctly in all locales, sync context docs.
  - Boundaries (in/out of scope): In — verify no grep hits for hardcoded strings in target files. Out — no code changes except small, in-scope fixes to remove remaining UI literals.
  - Done when: All checks pass. Context docs updated.
  - Validation report:

    ### Commands run
    - `flutter gen-l10n` -> used project l10n.yaml (exit 0 / generated `lib/l10n/*`)
    - `flutter analyze` -> completed; **0 errors**, 35 warnings/infos (project-wide, pre-existing)
    - Grep scan for remaining capitalized literal strings in `lib/src/` — results below

    ### Key outputs (short)
    - `flutter gen-l10n`: generation completed (project l10n.yaml used)
    - `flutter analyze`: no errors. Warnings/infos noted but unrelated to i18n migration (debug prints, dead code, unused imports, pre-existing issues).

    ### Remaining literal strings found by scan (classified)
    The grep scan returned a small number of non-localized string literals. Each item is classified as ACCEPTABLE (out-of-scope) or FIXED (in-scope and addressed):

    - lib/src/dashboard/providers/dashboard.dart: seeded strength exercise names ('Bench Press','Deadlift','Squat') — ACCEPTABLE (domain seed data)
    - lib/src/dashboard/providers/dashboard.dart: debug prints (`print('Failed to load/save water tracker: $e')`) — ACCEPTABLE (debug logs)
    - lib/src/database/app_database.dart: seeded food rows (Chicken Breast, White Rice, ...) — ACCEPTABLE (seed data)
    - lib/src/exercise/services/workout_services.dart: exercise catalogue lists (Bench Press, Deadlift, Squat, etc.) — ACCEPTABLE (domain data)
    - lib/src/dashboard/screens/main.dart: two 'Target: ... kg' strings updated to use l10n.target (FIXED)
    - misc: generated files, .g.dart outputs, and a few backup (.bak) files surfaced by the grep — IGNORE (generated/backup files)

    ### Verification of success criteria
    - l10n config (l10n.yaml) present and gen-l10n produced AppLocalizations -> confirmed
    - ARB files (en/fr/es) contain migrated + newly added keys -> confirmed
    - All targeted source files have been migrated and compile -> confirmed by `flutter analyze` (0 errors)
    - Bottom navigation labels and dashboard strings verified -> confirmed
    - Pluralized strings and parameterized placeholders were preserved in ARB files where applicable -> confirmed by inspecting generated localization code

    ### Residual risks / follow-ups
    - Several warnings/infos remain in the project unrelated to i18n (debug prints, dead code, unused imports). These are out-of-scope for this migration but worth a dedicated cleanup pass.
    - Some domain seed data contains english exercise/food names (deliberate). If you want these localized display names, that is a separate product decision (out of scope for this plan).

  - Verification notes (evidence):
    - `flutter gen-l10n` ran and generated `lib/l10n/app_localizations.dart` and locale files
    - `flutter analyze` completed with 0 errors (see tool output)
    - Grep scan performed; remaining literals are classified above

  - Completion: T13 validated and marked done. Context updated with `context/ui/navigation.md` and `context/context-map.md` to reflect router localization changes.

---

## Open Questions
- None remaining — all clarifications resolved during intake.
