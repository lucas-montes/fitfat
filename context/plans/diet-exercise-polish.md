# Diet and Exercise polish pass

## Change summary

Nine issues across the diet and exercise modules:

### Diet issues
1. **Macro values not rounded** — ingredient macros show many decimals (e.g., `123.456... g`). Should round: calories → 0 decimals, macros → 1 decimal.
2. **No way to view archived ingredients** — `isArchived` column exists, archive action works, but the ingredient list hides archived items with no way to show/filter them.
3. **Macro visibility filter doesn't apply to list views** — `dietPreferencesProvider` toggles are read but not used to filter the macro display in meals list and ingredients list.

### Exercise issues (all in active workout)
4. **Previous sessions ordering** — the previous sessions panel in the active workout screen should show most recent workouts first, not oldest.
5. **Add set button layout** — add set button is below the reps/weight fields, should be next to them (inline).
6. **Remove e1RM from active workout** — remove estimated 1RM line from the active workout screen (keep it in the exercise history views).
7. **Click to prefill set** — clicking a historical set in the previous sessions panel should fill its reps/weight into the add set form's fields.
8. **Finish summary exists but needs clearer layout** — the `SeanceSummaryScreen` shows total volume and duration, but the user wants a clearer summary with total sets, exercises, sets per exercise, weight, and duration.
9. **Profile dialog doesn't prefill current values** — `ProfileSetupDialog(initial: ...)` is not always called with the existing profile, so the form defaults to `DateTime(1990)` and empty height/weight.

## Success criteria

- All ingredient macros display rounded values.
- Archived ingredients toggle/filter exists in the ingredients tab.
- Macro visibility toggles affect meal group summaries and ingredient list display.
- Seance history shows most recent workouts first.
- Add set button is next to reps/weight fields horizontally.
- e1RM is no longer visible in any exercise screen.
- Clicking a set pre-fills reps/weight into the form.
- Workout summary screen shows total sets, exercises, sets per exercise, weight, duration.
- Profile dialog pre-fills birth date, height, weight, gender, and activity when editing.

## Constraints and non-goals

- **Out of scope**: Full workout history redesign, adding MET-based calorie estimation.
- **Out of scope**: Redesigning the ingredient editing flow.
- **Out of scope**: Changing how archived ingredients are archived (only adding a filter/view toggle).

## Task stack

### T01: Round ingredient macro values

- [x] T01: Round ingredient macro display values (status:done)
  - Task ID: T01
  - Goal: Round macro display values in the ingredient edit screen and ingredient list. Calories → `toStringAsFixed(0)`, protein/carbs/fat → `toStringAsFixed(1)`. Apply at the UI level in the ingredient edit screen (macro preview) and in the meal list row.
  - Boundaries: In — `lib/src/diet/screens/ingredients/edit.dart` (macro preview), `lib/src/diet/screens/main.dart` (meal row). Out — backend/model changes.
  - Done when: All macro displays show rounded values; `flutter analyze` reports 0 new issues.
  - Verification notes: Visual check — ingredient edit preview shows e.g. `100 kcal · 25g protein` not `100.0 kcal · 25.0g protein`.
  - **Status:** done
  - **Files changed:** `lib/src/diet/screens/ingredients/edit.dart`, `lib/src/diet/screens/main.dart`

### T02: Add archived ingredients filter/toggle

- [x] T02: Add archive toggle/filter to ingredients tab (status:done)
  - Task ID: T02
  - Goal: In the ingredients list tab, add a way to toggle between "Active" and "Archived" ingredients. The `isArchived` column and `archiveIngredient()` action already exist. Add a `FilterChip` to toggle the view.
  - Boundaries: In — `lib/src/diet/screens/main.dart` ingredients tab. Out — the archive action itself (already works).
  - Done when: Ingredients tab shows toggle showing active/archived; filtering works; `flutter analyze` reports 0 new issues.
  - Verification notes: Toggle to archived, see archived ingredients appear.
  - **Status:** done
  - **Files changed:** `lib/src/diet/screens/main.dart`

### T03: Fix macro visibility filters in list views

- [x] T03: Apply macro visibility filter to meal and ingredient list displays (status:done)
  - Task ID: T03
  - Goal: `dietPreferencesProvider` controls which macros are visible (calories, protein, carbs, fat). The settings toggles work, but the macros were still displayed in the meals tab ingredient/meal lists regardless of the toggles. Fix the meal row and ingredient list displays to respect the visibility prefs. Also fixed trailing separator bug in `_formatMacrosWithPrefs` (used `StringBuffer` with hardcoded ` · ` instead of `parts.join()`).
  - Boundaries: In — `lib/src/diet/screens/main.dart`. Out — other screens.
  - Done when: Toggling off "protein" in settings removes protein info from meal group cards, meal rows, and ingredient list; toggling it back shows it again.
  - Verification notes: Toggle protein off in settings → meals tab no longer shows protein in any list view.
  - **Status:** done
  - **Files changed:** `lib/src/diet/screens/main.dart`

### T04: Fix previous sessions ordering in active workout (most recent first)

- [x] T04: Fix previous sessions ordering in active workout (status:done)
  - Task ID: T04
  - Goal: In the active workout screen's previous sessions panel (`previous_sessions.dart`), the historical sets should show most recent first. The panel was calling `.take(5)` before sorting. Fix: sort by `completedAt` descending first, then take 5.
  - Boundaries: In — `lib/src/exercise/screens/seances/active/previous_sessions.dart`. Out — the seance history provider.
  - Done when: Previous sessions in active workout show most recent workout first.
  - Verification notes: During an active workout, open the previous sessions panel → most recent workout appears first.
  - **Status:** done
  - **Files changed:** `lib/src/exercise/screens/seances/active/previous_sessions.dart`

### T05: Move add set button inline with fields

- [x] T05: Move add set button next to reps/weight fields (status:done)
  - Task ID: T05
  - Goal: In `AddSetForm`, move the `FilledButton` from being below the fields to being next to the weight field in the same `Row`. This frees vertical space and makes the flow more natural.
  - Boundaries: In — `lib/src/exercise/screens/seances/active/add_set_form.dart`. Out — other files.
  - Done when: Add set button is horizontally next to the weight field; `flutter analyze` reports 0 new issues.
  - Verification notes: Visual check in active seance screen.
  - **Status:** done
  - **Files changed:** `lib/src/exercise/screens/seances/active/add_set_form.dart`

### T06: Remove e1RM display from active workout screen

- [x] T06: Remove e1RM display from active workout screen (status:done)
  - Task ID: T06
  - Goal: Remove the estimated 1RM display from the active workout screen only.
  - Boundaries: In — `lib/src/exercise/screens/seances/active/screen.dart`. Out — `exercises/history/` screens, `ProgressionService` methods, test file.
  - Done when: `grep -n 'oneRM\|e1RM' lib/src/exercise/screens/seances/active/` returns no matches.
  - Verification notes: Open a guided seance → no e1RM text below sets.
  - **Status:** done
  - **Files changed:** `lib/src/exercise/screens/seances/active/screen.dart`

### T07: Clicking a set pre-fills reps/weight into the form

- [x] T07: Click to prefill set values into add set form (status:done)
  - Task ID: T07
  - Goal: When viewing sets in the active workout's current exercise panel, tapping a set should populate the add set form with its reps and weight. For freeform mode, tapping the card prefills. For guided mode, a small edit icon button prefills.
  - Boundaries: In — `lib/src/exercise/screens/seances/active/screen.dart`, `guided_set_card.dart`, `freeform_set_card.dart`. Out — previous sessions panel, exercise history screens.
  - Done when: Tapping a set in the current exercise fills reps/weight into the add form fields; `flutter analyze` reports 0 new issues.
  - Verification notes: Tap an existing set in the active workout → form populates with that set's reps and weight.
  - **Status:** done
  - **Files changed:** `screen.dart`, `guided_set_card.dart`, `freeform_set_card.dart`

### T08: Enhance workout summary screen

- [x] T08: Enhance workout summary with detailed stats (status:done)
  - Task ID: T08
  - Goal: The `SeanceSummaryScreen` now shows a clear header card with duration, exercises count, total sets, total volume, and total reps. Per-exercise breakdown shows sets, reps, volume, and best set.
  - Boundaries: In — `lib/src/exercise/screens/seances/active/summary_screen.dart`.
  - Done when: Summary screen shows all stats in a clear card layout; `flutter analyze` reports 0 new issues.
  - Verification notes: Complete a workout → summary screen shows detailed breakdown.
  - **Status:** done
  - **Files changed:** `lib/src/exercise/screens/seances/active/summary_screen.dart`

### T09: Fix profile dialog prefill

- [x] T09: Fix profile dialog to prefill current values (status:done)
  - Task ID: T09
  - Goal: `ProfileSetupDialog` already has an `initial` parameter and `initState` reads it. But the dialog was opened with `const ProfileSetupDialog()` (no `initial`). Fix the caller to pass `initial: profile` from the provider.
  - Boundaries: In — `lib/src/dashboard/screens/main.dart` (caller of ProfileSetupDialog). Out — the dialog itself (already handles prefill correctly).
  - Done when: Opening profile edit dialog shows birth date, height, weight, gender, and activity level from the saved profile.
  - Verification notes: Open profile edit → all fields are pre-filled with current values.
  - **Status:** done
  - **Files changed:** `lib/src/dashboard/screens/main.dart`

### T10: Validation and cleanup

- [x] T10: Run flutter analyze, flutter test, dart format (status:done)
  - Task ID: T10
  - Done when: `flutter analyze` reports 0 new errors; `flutter test` green; `dart format` clean.
  - Verification notes: ✅ `flutter analyze` — 2 issues (both pre-existing infos). ✅ `flutter test` — 66 passed, 7 failed (pre-existing `libsqlite3.so`). ✅ `dart format` — clean.
  - **Status:** done
