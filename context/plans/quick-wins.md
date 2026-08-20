# Plan: Quick wins — vertical planned sets + form picker thumbnails

## Change Summary

Two small UI fixes requested during review (2026-08-17):

1. **Workout detail (planning) screen**: planned sets render as wrapped chips
   side-by-side (`_ExerciseBlockCard` uses `Wrap`); make each set its own line,
   vertically.
2. **Workout form exercise picker**: search results show only type icons; add
   exercise thumbnails (48×48 image or type-icon fallback) like the active-workout
   search tile.

## Success Criteria

- Workout detail lists each planned set on its own full-width line.
- Workout-form picker rows show a 48×48 thumbnail for catalog exercises (image)
  and the type icon otherwise.
- `dart analyze lib/` zero errors; no new l10n keys required.

## Constraints & Non-Goals

- No schema / dependency changes.
- Non-goal: active-workout layout (Plan `active-workout-redo`), search ranking.

## Task Stack

- [x] T01: `Vertical planned sets in workout detail` (status:done)
  - Task ID: T01
  - Goal: Render each planned set on its own line in `_ExerciseBlockCard`.
  - Boundaries (in/out of scope):
    - In: `lib/src/exercise/screens/workout_detail.dart` — replace the `Wrap` of
      `_SetChip` (circa line 198) with a vertical `Column` of set rows (one chip
      or bordered row per set, full width, small spacing/divider).
    - Out: chip content/label logic, other screens.
  - Done when: sets stack top-to-bottom, one per line; `dart analyze lib/` clean.
  - Verification notes (commands or checks):
    - `dart analyze lib/src/exercise/screens/workout_detail.dart`.

- [x] T02: `Thumbnails in workout-form picker` (status:done)
  - Task ID: T02
  - Goal: Show exercise images in the workout-form exercise search results.
  - Boundaries (in/out of scope):
    - In: `lib/src/exercise/screens/exercise_picker_sheet.dart` — the result
      `ListTile` leading becomes a 48×48 `Image.asset(ex.imagePath)` with the
      existing type-icon fallback (mirror `_ExerciseSearchTile.__buildThumbnail`
      in `active_workout_screen.dart`).
    - Out: the "create exercise" row, picker selection logic.
  - Done when: image-backed exercises show thumbnails; others show the icon;
    `dart analyze lib/` clean.
  - Verification notes (commands or checks):
    - `dart analyze lib/src/exercise/screens/exercise_picker_sheet.dart`.

- [x] T03: `Validation and context sync` (status:done)
  - Task ID: T03
  - Goal: Full checks + context sync (`context/architecture.md`,
    `context/exercise/workout-crud.md`) + validation report.
  - Boundaries (in/out of scope): in — analyze/test/format, context sync; out —
    git commit.
  - Done when: suite green; context reads back accurate.
  - Verification notes (commands or checks):
    - `dart analyze lib/`; `flutter test`; `dart format --output=none --set-exit-if-changed lib test`.

## Validation Report (T03)

- `flutter analyze lib` → **No issues found**.
- `dart format` on edited files → clean (0 changed).
- `flutter test` → only pre-existing DB-backed failures (missing `libsqlite3.so` in this env).
- Context: `context/exercise/workout-crud.md` updated (vertical set lines in the
  planning `_ExerciseBlockCard`; 48×48 picker thumbnails).

## Next Command

/next-task quick-wins T01