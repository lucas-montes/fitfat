# Plan: Migrate AddMealScreen and Add Tests

## Summary

Objective: finish the Meals feature migration by (1) migrating `AddMealScreen` to use the new `mealControllerProvider` (controller), and (2) add unit tests for the `MealListController` using a real, file-backed development database (not the production DB). This plan focuses only on the concrete implementation steps required in the application codebase. It assumes the new repository adapters and `mealControllerProvider` already exist in the codebase.

Path: `context/plans/migrate-addmeal-and-tests.md`

## Tasks

T01: Migrate `AddMealScreen` to `mealControllerProvider`
- Description: Replace direct writes to the legacy `mealLogProvider.notifier` with calls to the new controller API (`mealControllerProvider.notifier`). Ensure the screen uses domain `MealEntry` and calls `addMeal` or `updateMeal` as appropriate. Keep UI behavior identical.
- Boundaries:
  - Only update `lib/src/screens/food/add_meal_screen.dart` and any helper widgets it imports locally.
  - Do not change repository implementations.
- Done checks:
  - `AddMealScreen` no longer imports or writes to `mealLogProvider.notifier`.
  - `AddMealScreen` calls `ref.read(mealControllerProvider.notifier).addMeal(...)` when creating a new meal.
  - `AddMealScreen` calls `ref.read(mealControllerProvider.notifier).updateMeal(...)` when editing an existing meal.
  - App compiles without new errors related to AddMealScreen.
- Verification:
  - Manual smoke: open Add Meal, save, verify item appears in Meals tab.
  - Unit/Widget test added in T02 can exercise the saving path.

T02: Add tests for `MealListController` using a dev file-backed DB
- Description: Add unit tests to validate controller interactions using a real, file-backed development database (via the `devMealRepositoryProvider` / `devDatabaseProvider`) so tests exercise the same SQL/storage codepath as production without touching the production DB file.
- Files to add:
  - `test/repositories/dev_meal_repository_test.dart` (optional; can be skipped if coverage focuses on controller)
  - `test/providers/meal_list_controller_test.dart`
- Boundaries:
  - Tests should not modify app source files; they can create test-only helpers.
  - Use `package:flutter_test/flutter_test.dart` and `package:riverpod/riverpod.dart` or `flutter_riverpod` for provider container usage. Use provider overrides to inject `devMealRepositoryProvider` where useful.
- Done checks:
  - Dev DB tests cover create, read, update, delete and stream behavior (exercise Drift SQL mapping).
  - `MealListController` tests cover load(day), addMeal, updateMeal, deleteMeal, and that state updates correctly.
  - Tests run locally with `flutter test` and pass.
- Verification:
  - All new tests pass in CI or local `flutter test` run.

T03: Sweep for remaining `mealLogProvider` direct writes
- Description: Find usages of `mealLogProvider.notifier` and `mealLogProvider` that perform writes and update them to use the controller where appropriate. Leave read-only usages (if any) as-is until planned refactor.
- Boundaries:
  - Limit changes to call-sites that are clearly performing mutations (add/update/delete meals).
  - If a call-site is ambiguous, add a TODO comment instead of changing behavior.
- Done checks:
  - No direct calls to `mealLogProvider.notifier` performing mutations remain, except tests or legacy compatibility layers.
  - App compiles.
- Verification:
  - Run a workspace text search for `mealLogProvider.notifier` and review remaining hits.

T04: Add simple widget test (optional) for `AddMealScreen`
- Description: Add a shallow widget test that pumps `AddMealScreen`, fills its fields, and asserts the controller received an `addMeal` call (using `devMealRepositoryProvider` via a provider override to use the file-backed dev DB).
- Boundaries:
  - Keep this test lightweight; it should not require platform channels or heavy integration.
- Done checks:
  - Widget test executes and verifies controller interaction.
- Verification:
  - `flutter test` passes for widget test.

T05: Run static analysis and fix remaining diagnostics
- Description: Run `flutter analyze` and `flutter test` (locally) after code changes and address any errors reported. Focus fixes only on issues introduced by the migration.
- Boundaries:
  - Do not refactor unrelated code or fix unrelated lints unless they block the migration.
- Done checks:
  - `flutter analyze` reports no new errors related to migrated files.
  - `flutter test` passes.

## Order and Rationale
- Primary order: T01 → T02 → T03 → T04 → T05.
- Rationale: Migrate the UI first (T01) to ensure runtime behavior aligns with the new controller API, then add unit tests (T02) to protect behavior and prevent regressions. T03 is a cleanup sweep to catch remaining mutation sites. T04 is optional but valuable for CI-based verification. T05 ensures code quality and fixes remaining issues.

## Estimates
- T01: 1–2 hours (code change + compile & manual smoke).
- T02: 2–3 hours (tests + minor fixes for testability).
- T03: 30–60 minutes (search & replace + review).
- T04: 1 hour (optional).
- T05: 30–90 minutes depending on diagnostics.

## Preconditions & Notes
- Assumes `mealControllerProvider` and `InMemoryMealRepository` are present and functioning as per the earlier migration.
- If `AddMealScreen` depends on intermediate view-models, adapt to domain `MealEntry` mapping carefully.
- Keep migrations small and test after each task.

## Next Step Recommendation
- If you approve, I will start T01: implement the `AddMealScreen` migration. I will produce a patch that updates `lib/src/screens/food/add_meal_screen.dart`, run a focused code-check, and report back with changes and any diagnostics.
