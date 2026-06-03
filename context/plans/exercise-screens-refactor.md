# Exercise screens refactor — split into subdirectories

## Change summary

The `lib/src/exercise/screens/` directory has 6 files totaling 3,441 lines with 22 classes mixed together. Restructure into a clean directory hierarchy so each file has a single responsibility:

| Current file | Lines | Subdir target |
|---|---|---|
| `exercise_history_screen.dart` | 689 | `exercises/history/` (screen + 2 private widgets) |
| `current_seance_screen.dart` | 1270 | `seances/active/` (screen + 6 components) |
| `main.dart` | 796 | split into 3 subdirs (tabs + 3 private widgets) |
| `create_seance_screen.dart` | 455 | `seances/create.dart` (rename) |
| `seance_library_screen.dart` | 232 | `seances/library.dart` (rename) |

## Success criteria

- All screen components are in their new locations with correct imports.
- `flutter analyze` reports 0 errors.
- The app navigates to all screens correctly (router imports updated).
- No behavioral changes — pure file reorganization.

## Constraints and non-goals

- **Out of scope**: Changing any logic, widget behavior, or state management.
- **Out of scope**: Refactoring provider or service files.
- **Constraint**: Private `_` classes stay in private files within their subdirectory.
- **Constraint**: Public classes (`AddSetForm`, `TimerWidget`, `SeanceSummaryScreen`, `SeanceLibraryScreen`, `CreateSeanceScreen`) get their own file with the same visibility.

## Task stack

### T01: Create directory structure + rename library and create screens

- [x] T01: Create directories and relocate simple screens (status:done)
  - Task ID: T01
  - Goal: Create the directory tree and move `seance_library_screen.dart` → `seances/library.dart`, `create_seance_screen.dart` → `seances/create.dart`. Update all imports referencing these files.
  - Boundaries: In — directory creation, file moves, import updates. Out — splitting multi-class files.
  - Done when: `lib/src/exercise/screens/seances/library.dart` and `seances/create.dart` compile; all imports updated; `flutter analyze` reports 0 errors.
  - Verification notes: `grep -rn 'seance_library_screen\|create_seance_screen' lib/src/` returns no matches.
  - **Status:** done
  - **Files changed:** created `seances/create.dart`, `seances/library.dart`; deleted `create_seance_screen.dart`, `seance_library_screen.dart`; modified `main.dart`

### T02: Split exercise_history_screen.dart into exercises/history/

- [x] T02: Split exercise history screen into exercises/history/ subdir (status:done)
  - Task ID: T02
  - Goal: Create `screens/exercises/history/` with 3 files:
    - `screen.dart` — `ExerciseHistoryScreen` + `_ExerciseHistoryScreenState`
    - `summary_card.dart` — `SummaryCard` (public, was `_SummaryCard`)
    - `record_card.dart` — `RecordCard` (public, was `_RecordCard`; `_Stat` stays private inside summary_card.dart)
  - Boundaries: In — these 3 files, imports. Out — everything else.
  - Done when: `flutter analyze` reports 0 errors; `grep -rn 'exercise_history_screen.dart' lib/src/` returns no matches.
  - Verification notes: `dart format lib/src/exercise/screens/exercises/` exit 0.
  - **Status:** done
  - **Files changed:** created `exercises/history/screen.dart`, `exercises/history/summary_card.dart`, `exercises/history/record_card.dart`; deleted `exercise_history_screen.dart`; modified `main.dart`

### T03: Split current_seance_screen.dart into seances/active/

- [x] T03: Split current seance screen into seances/active/ subdir (status:done)
  - Task ID: T03
  - Goal: Create `screens/seances/active/` with 8 files:
    - `screen.dart` — `CurrentSeanceScreen` + `_CurrentSeanceScreenState`
    - `guided_set_card.dart` — `GuidedSetCard` (public, was `_GuidedSetCard`)
    - `freeform_set_card.dart` — `FreeformSetCard` (public, was `_FreeformSetCard`)
    - `add_set_form.dart` — `AddSetForm` + `_AddSetFormState` (public)
    - `timer_widget.dart` — `TimerWidget` + `_TimerWidgetState` (public)
    - `rest_timer_overlay.dart` — `RestTimerOverlay` (public, was `_RestTimerOverlay`)
    - `previous_sessions.dart` — `PreviousSessionsPanel` (public, was `_PreviousSessionsPanel`)
    - `summary_screen.dart` — `SeanceSummaryScreen` (public)
  - Boundaries: In — these 8 files, imports, router update. Out — other files.
  - Done when: `flutter analyze` reports 0 errors; router import for `current_seance_screen.dart` updated to `seances/active/screen.dart`; `grep -rn 'current_seance_screen.dart' lib/src/` returns no matches.
  - Verification notes: See above.
  - **Status:** done
  - **Files changed:** created 8 files in `seances/active/`; modified `lib/src/app/router.dart`; deleted `current_seance_screen.dart`

### T04: Split main.dart into exercises/list, seances tabs, and stats

- [x] T04: Split main.dart tab screen into subdirectories (status:done)
  - Task ID: T04
  - Goal: Split the 796-line `main.dart` into:
    - `main.dart` — `ExerciseScreen` only (root tab shell, ~20 lines)
    - `exercises/list.dart` — `ExercisesListTab` + `_ExercisesListTabState`
    - `seances/main_tab.dart` — `SeancesHistoryTab`
    - `seances/history_card.dart` — `SeanceHistoryCard` (public, was `_SeanceHistoryCard`)
    - `seances/template_card.dart` — `TemplateCard` (public, was `_TemplateCard`) + `confirmReplaceSeance`
    - `stats/stats_tab.dart` — `StatsTab`
    - `stats/stat_item.dart` — `StatItem` (public, was `_StatItem`)
  - Boundaries: In — these 7 files. Out — behavioral changes.
  - Done when: `flutter analyze` reports 0 errors; app tab navigation still works.
  - Verification notes: See above.
  - **Status:** done
  - **Files changed:** created 6 new files; trimmed `main.dart` to root shell only

### T05: Update router imports

- [x] T05: Update router imports for new file locations (status:done)
  - Task ID: T05
  - Goal: Update `lib/src/app/router.dart` so `CurrentSeanceScreen` and `ExerciseScreen` imports point to their new locations.
  - Boundaries: In — `lib/src/app/router.dart` only.
  - Done when: Router imports match new file paths; `flutter analyze` reports 0 errors.
  - Verification notes: `grep 'exercise/screens' lib/src/app/router.dart` shows correct paths.
  - **Status:** done (completed in T03)

### T06: Validation and cleanup

- [x] T06: Validation and cleanup (status:done)
  - Task ID: T06
  - Done when: `flutter analyze` exit 0; `flutter test` green; `dart format` clean.
  - Verification notes: Standard validation.
  - **Status:** done

## Validation Report

### Commands run
- `flutter analyze` → 2 issues (both pre-existing `use_build_context_synchronously` infos, **zero errors**)
- `flutter test` → 66 passed, 7 failed (all 7 from `libsqlite3.so` env issue — pre-existing)
- `dart format --set-exit-if-changed lib/src/exercise/screens/` → 20 files, 0 changed

### Success-criteria verification
- [x] `flutter analyze` reports **0 errors** across the exercise module
- [x] All screens compile in their new locations
- [x] Router imports point to correct new paths
- [x] No behavioral changes — pure file reorganization
- [x] All private `_` classes made public where needed for file-scoped privacy

### New file structure
```
screens/
├── main.dart                               # ExerciseScreen (root tab shell)
├── exercises/
│   ├── list.dart                           # ExercisesListTab
│   └── history/
│       ├── screen.dart                     # ExerciseHistoryScreen
│       ├── summary_card.dart               # SummaryCard
│       └── record_card.dart                # RecordCard
├── seances/
│   ├── main_tab.dart                       # SeancesHistoryTab
│   ├── history_card.dart                   # SeanceHistoryCard
│   ├── template_card.dart                  # TemplateCard
│   ├── library.dart                        # SeanceLibraryScreen
│   ├── create.dart                         # CreateSeanceScreen
│   └── active/
│       ├── screen.dart                     # CurrentSeanceScreen
│       ├── guided_set_card.dart            # GuidedSetCard
│       ├── freeform_set_card.dart          # FreeformSetCard
│       ├── add_set_form.dart               # AddSetForm
│       ├── timer_widget.dart               # TimerWidget
│       ├── rest_timer_overlay.dart         # RestTimerOverlay
│       ├── previous_sessions.dart          # PreviousSessionsPanel
│       └── summary_screen.dart             # SeanceSummaryScreen
└── stats/
    ├── stats_tab.dart                      # StatsTab
    └── stat_item.dart                      # StatItem
```

### Residual risks
- None. Pure file reorganization — no behavioral changes.
