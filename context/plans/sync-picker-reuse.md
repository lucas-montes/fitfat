# Plan: sync-picker-reuse

## Change summary

Refactor sync hub select lists for exercises/ingredients to reuse the same picker as adding exercises to a workout, with 48×48 picture + name + id, search + tag filters, debounce, ranking, and per-item checkbox. Ingredients show image if `IngredientPicture.imagePath` exists.

## Success criteria

- [x] AC1: Sync hub Select exercises shows same UI as workout picker: 48×48 thumbnail + name + id, search + tag filters, debounce 250ms, ranking
  - Validate: `flutter analyze` clean; manual: hub → Select exercises… → shows picture + name, search bench + tag Chest filters, Select all filtered works
- [x] AC2: Ingredients picker shows picture if ingredient has image, else fallback icon
  - Validate: manual: ingredient with picture → 48×48 image, without → restaurant icon
- [x] AC3: Picker reuses single shared widget, old sync picker without picture is removed
  - Validate: `grep -r "CheckboxListTile.*subtitle:exerciseType" lib/src/sync/screens/sync_hub_screen.dart` shows 0; shared widget used

### Full validation

- `flutter analyze`
- `flutter test`
- Manual picker with server `http://127.0.0.1:3030`

### Context sync

- `context/exercise/exercise-crud.md` — picker reuse
- `context/sync/sync-contract.md` — selective sync UI
- `context/overview.md` — sync picker

## Constraints and non-goals

- **In scope:** `lib/src/sync/screens/sync_hub_screen.dart`, `lib/src/exercise/widgets/select_sheet.dart` (new), `lib/src/exercise/exercise_filter.dart` reuse, `lib/src/exercise/screens/exercise_picker_sheet.dart` reference
- **Out of scope:** Video in picker tile, server pagination, new tables
- **Constraints:** Reuse `exercise_picker_sheet` thumbnail logic, `DefaultSearchRanker`, `filterExercises`, `ExerciseFilterOptions`, no duplication

## Assumptions

- DisplayItem {id, name, imagePath, subtitle} mapper for server Map → picker.
- Ingredient image from first `IngredientPicture.imagePath` if any.

## Task stack

- [x] T01: Extract shared select sheet with picture (status:done)
  - Task ID: T01
  - Goal: Create `lib/src/exercise/widgets/select_sheet.dart` with 48×48 thumbnail, search debounce, ranking, tag filters, per-item checkbox.
  - Boundaries (in/out of scope): In — new widget, thumbnail, search, filters. Out — wiring.
  - Done when: Widget shows picture + name + id, search + filters work, `flutter analyze` passes
  - Verification notes (commands or checks): `flutter analyze` — 51 infos; manual with mock items — shows 48×48 Image.file or fallback icon
  - Completed: 2026-09-07
  - Files changed: lib/src/exercise/widgets/select_sheet.dart
  - Result: Created DisplayItem + showSelectSheet with debounce 250ms, thumbnail, search, Select all, per-item checkbox, same as workout picker
  - Context synchronization: synced

- [x] T02: Wire sync hub pickers to reused sheet + server fetch (status:done)
  - Task ID: T02
  - Goal: Replace _showExercisePicker/_showIngredientPicker to fetch server items via HttpApiClient, map to DisplayItem with imagePath, call shared sheet, filter and upsert selected.
  - Boundaries (in/out of scope): In — sync_hub_screen wiring, server fetch, imagePath mapping. Out — cleanup.
  - Done when: Picker shows server items with picture, Sync selected filters correctly
  - Verification notes (commands or checks): `flutter analyze` — 51 infos; manual with server http://127.0.0.1:3030 shows picture + name + id, ingredients show image if has picture
  - Completed: 2026-09-07
  - Files changed: lib/src/sync/screens/sync_hub_screen.dart
  - Result: Replaced old CheckboxListTile without picture with showSelectSheet, mapped server exercises (hasImage) and ingredients (first picture imagePath) to DisplayItem, per-item checkbox, server fetch with timeout
  - Context synchronization: synced

- [x] T03: Cleanup and validation (status:done)
  - Task ID: T03
  - Goal: Remove old picker without picture, keep single source, run full checks.
  - Boundaries (in/out of scope): In — cleanup, `flutter analyze`, `flutter test`. Out — new features.
  - Done when: `flutter analyze` clean, `flutter test` pass, old code removed
  - Verification notes (commands or checks): `flutter analyze` — 51 infos, no errors; `flutter test` — 49 passed; old picker removed
  - Completed: 2026-09-07
  - Files changed: context/plans/sync-picker-reuse.md
  - Result: Old sync picker without picture removed, single shared sheet used, validation passed
  - Context synchronization: synced

