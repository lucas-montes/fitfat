# Plan: App-wide improvements batch (10 items)

## Change Summary

A batch of 10 improvements across FitFat's diet, exercise, planner, dashboard, and settings areas:

1. **Ingredients**: support optional extra nutriments — sodium (mg), fiber (g), sugar (g) per 100g. Ingredient-only (no meal propagation).
2. **Search boxes**: meal form ingredient picker and workout form exercise picker get a name-filter search box.
3. **Planner**: tasks get an optional due date (defaults to the selected day).
4. **Bug fix**: creating a new meal does not save its ingredients (only the meal row is written).
5. **Dashboard**: add body weight and height entries and view their evolution.
6. **Settings**: profile section with age.
7. **Workout form**: no default values when adding planned sets (selecting an exercise creates 0 sets; "Add set" creates empty sets).
8. **Settings**: theme mode (system / light / dark) and language (en / fr / es) selection, persisted.
9. **Bug fix**: logging actual set values in an active workout does not appear on save (only after marking completed).
10. **Active workout**: persistent notification (Android) showing workout duration and current rest time between sets, plus an in-app rest timer.

All needed dependencies already exist in `pubspec.yaml` but are currently unused (leftovers from the pre-rebuild app): `fl_chart` (charts), `shared_preferences` (settings), `flutter_foreground_task` + `flutter_local_notifications` (notifications, Android manifest already configured), `permission_handler`. **No new dependencies.**

## Success Criteria

- Ingredient form can store optional sodium / fiber / sugar per 100g; existing ingredients (no values) load and save unchanged; meal breakdown and `meal_ingredients` are untouched.
- Meal form and workout form each have a search box that filters the picker list by name (case-insensitive).
- Planner task dialog offers an optional due date defaulting to the selected day; the tile shows the due date; copy-from-previous-day carries the due date.
- Creating a new meal persists its `meal_ingredients` rows linked to the meal id (regression check: add meal → reopen → ingredients present). Orphaned `meal_ingredients` rows (from the bug) are cleaned up by the v3 migration.
- Dashboard shows a body metrics card: add weight (kg) / height (cm) for a day and see weight + height evolution (line charts via `fl_chart`).
- Settings shows a Profile section where the user can set age; age persists across restarts.
- Workout form: selecting an exercise creates no sets; each "Add set" appends one empty set; no pre-filled reps/weight/duration anywhere.
- Settings lets the user pick theme (system/light/dark) and language (en/fr/es); both persist across restarts and apply immediately.
- In an active workout, saving a set's actual values updates the detail view immediately (refresh bug fixed).
- Starting a workout shows an ongoing notification on Android (lock screen + normal usage) with the workout duration and, while resting, the remaining rest time; completing the workout removes it. A rest timer exists on the workout detail screen.
- `flutter pub run build_runner build` — exit 0; `flutter gen-l10n` — exit 0; `dart analyze lib/` — zero errors; `flutter test` — passes; `git status` shows only intended files.
- All new user-facing strings localized in en/fr/es ARB files.

## Constraints & Non-Goals

- New nutriments are **ingredient-only** (user decision): no `meal_ingredients` schema change, no meal breakdown/totals change, no dashboard macro change.
- Body metrics: one row per day holding optional weight and/or height; units kg / cm (metric, consistent with the app).
- Age is a single profile value (int) in `shared_preferences` — no `user_profile` DB table.
- Search is client-side filtering only — no fuzzy search or new dependency.
- Notifications are **Android-first** (the manifest is already configured for `flutter_foreground_task`). iOS gets a best-effort ongoing notification via `flutter_local_notifications`; full iOS foreground-service parity is out of scope.
- Rest timer adds **no DB schema change**; the rest-end timestamp is persisted in `shared_preferences` so the background task callback can render it.
- No due-date reminders/scheduling notifications — the due date is data + display only.
- No dark-mode styling pass beyond a standard Material 3 dark `ThemeData` from the existing teal seed.
- No new tests beyond keeping the existing suite green (matches repo posture); manual runtime validation is deferred to T11.
- One `schemaVersion` bump to 3 covering all table changes in a single migration (repo pattern: planner did the same for v2).

## Assumptions (resolved with user + inferred)

- Item 1: sodium, fiber, sugar are all **optional** on the form (blank = not set → stored `null`). Units: sodium mg/100g, fiber g/100g, sugar g/100g. Columns are nullable.
- Item 2: a `TextField` above the list filters by substring, case-insensitive; empty query shows all.
- Item 3: `due_date` nullable epoch millis. Dialog pre-fills with the selected day (editable, clearable). Copy-from-previous-day carries `due_date`. Task still belongs to its `day` list.
- Item 4: root cause is `meal_form.dart` building new-meal items with `mealId: ''` while `newMeal()` never assigns the meal id. Fix at the factory/insert boundary; migration deletes orphaned `meal_ingredients` whose `meal_id` has no matching `meals` row.
- Item 5: `body_metrics` table keyed by start-of-day; saving an entry for a day upserts (insert or update). Dashboard shows a weight line chart and a height line chart (single point rendered as text).
- Item 7: `_PlannedSetEntry` fields become nullable and empty by default; saving a set with all-null planned values is allowed (shows "—" in detail, matching current empty-set rendering).
- Item 9: root cause is `workout_detail.dart` `_editActuals` calling `ref.invalidate(workoutDetailProvider(workoutExerciseId))` — wrong key (workout_exercise id instead of workout id); the view only refreshed when Complete (which invalidates with the correct id).
- Item 10: rest timer on the workout detail screen (start/cancel between sets, mm:ss countdown). Duration chosen via **preset chips in minutes — 2 / 3 / 4 / 5 / 6 min (user decision 2026-08-06)**. Ongoing notification via `flutter_foreground_task`; content = workout duration + remaining rest (or "no rest"); starts on Start, updates on tick, stops on Complete. Android 13+ `POST_NOTIFICATIONS` runtime permission requested via `permission_handler`. Android-only service (iOS best-effort via `flutter_local_notifications`).
- Nix environment: always `flutter pub run build_runner build` (never `dart run build_runner build`). Headless environment: no `flutter run`; manual checks deferred to T11.

## Task Stack

---

- [x] T01: `Schema v3: ingredient nutriments, planner due date, body metrics` (status:done)
  - Task ID: T01
  - Completed: 2026-08-05
  - Files changed: `lib/src/database/tables.dart`, `lib/src/database/app_database.dart`, `lib/src/database/app_database.g.dart` (generated), `context/database/schema.md`
  - Evidence: `flutter pub run build_runner build` exit 0; `dart analyze lib/` "No issues found!"; `flutter test` 1/1 passed
  - Notes: Columns are `sodium_per100g`/`fiber_per100g`/`sugar_per100g` (consistent with existing `calories_per100g` convention; schema.md corrected to actual generated names). Orphan cleanup uses `m.database.customStatement` — drift 2.31 `Migrator` has no public `customStatement`/`deleteWhere`. No defensive due_date guard (v1→v3 edge case accepted as non-issue — DB can be wiped).
  - Goal: Extend the Drift schema to v3: add nullable `sodium_per_100g`, `fiber_per_100g`, `sugar_per_100g` to `ingredients`; add nullable `due_date` to `planner_items`; add a new `body_metrics` table; bump `schemaVersion` to 3 with an explicit migration that preserves data and cleans up orphaned `meal_ingredients` rows.
  - Boundaries (in/out of scope):
    - In: `lib/src/database/tables.dart` (3 new ingredient columns, `due_date`, new `BodyMetrics` table), `lib/src/database/app_database.dart` (register `BodyMetrics`, `schemaVersion => 3`, `onUpgrade` `if (from < 3)` steps), codegen, `context/database/schema.md` (8→9 tables, v3 note).
    - Out: Domain models, repositories, UI (each feature task handles its own).
  - Done when:
    - `ingredients` has nullable sodium/fiber/sugar REAL columns; `planner_items` has nullable `due_date` INTEGER; `body_metrics` table exists with `id` (TEXT PK uuid v7), `date` (INTEGER start-of-day), `weight_kg` (REAL?), `height_cm` (REAL?), `created_at` (INTEGER).
    - `schemaVersion` is 3; `onUpgrade` adds the columns, creates `body_metrics`, and deletes orphaned `meal_ingredients` (rows whose `meal_id` is not in `meals`), all without dropping data.
    - `context/database/schema.md` updated (9 tables, v3).
    - `flutter pub run build_runner build` — exit 0; `dart analyze lib/` — zero errors.
  - Verification notes (commands or checks):
    - `flutter pub run build_runner build` — exit 0.
    - `dart analyze lib/` — "No issues found!".
    - `flutter test` — 1/1 passed.
    - Note: use `m.addColumn` for new nullable columns and `m.createTable(bodyMetrics)`; for the orphan cleanup use `m.customStatement('DELETE FROM meal_ingredients WHERE meal_id NOT IN (SELECT id FROM meals)')` (or `m.deleteWhere` if available in drift 2.20).

---

- [x] T02: `Fix meal creation not saving ingredients` (status:done)
  - Task ID: T02
  - Completed: 2026-08-05
  - Files changed: `lib/src/diet/repositories/meal_repository.dart` (`newMeal` stamps the generated meal id onto every item), `lib/src/diet/screens/meal_form.dart` (`_buildItem` mealId now an optional named param; new-meal path passes no placeholder)
  - Evidence: `dart analyze lib/src/diet/` "No issues found!"; `dart analyze lib/` "No issues found!"; `flutter test` 1/1 passed
  - Notes: Factory-boundary fix per plan assumptions — `newMeal` reconstructs items with the real meal id (no model change). Pre-existing corrupt rows (`meal_id = ''`) are cleaned by the T01 v3 migration orphan cleanup. Manual regression (create meal → reopen → ingredients present) deferred to T11.
  - Goal: Fix the bug where creating a new meal writes only the `meals` row and its `meal_ingredients` rows end up with an empty `meal_id`, so they never load back.
  - Boundaries (in/out of scope):
    - In: `lib/src/diet/repositories/meal_repository.dart` (`newMeal` assigns the meal id to each item, or the form builds items with the real meal id), `lib/src/diet/screens/meal_form.dart` (remove the `''` mealId workaround), regression check.
    - Out: Schema changes (T01), search box (T04), nutriment display.
  - Done when:
    - After creating a meal, `meal_ingredients` rows reference the meal's id; reopening the meal in edit mode shows its ingredients.
    - `dart analyze lib/src/diet/` — zero errors.
  - Verification notes (commands or checks):
    - `dart analyze lib/src/diet/` — zero errors.
    - Manual (deferred): create meal with 2 ingredients → reopen → both present with grams.

---

- [x] T03: `Ingredient form: optional sodium, fiber, sugar` (status:done)
  - Task ID: T03
  - Completed: 2026-08-05
  - Files changed: `lib/src/models/ingredient.dart` (3 nullable fields + sentinel-based `copyWith`), `lib/src/diet/repositories/ingredient_repository.dart` (map columns in `_toDomain`/`insert`/`update`; `newIngredient` optional params), `lib/src/diet/screens/ingredient_form.dart` (3 optional fields, blank → null, non-negative validation, suffix mg/g), `lib/src/diet/screens/ingredient_list.dart` (optional nutrient subtitle line), `lib/l10n/app_{en,es,fr}.arb` + regenerated `app_localizations*.dart`
  - Evidence: `flutter gen-l10n` exit 0; `dart analyze lib/` "No issues found!"; `flutter test` 1/1 passed
  - Notes: Sentinel `copyWith` (differing from the simple `?? this.x` pattern) lets blank fields clear a value to null on edit. Nutrient subtitle joins only present values using the app's " · " separator. Existing ingredients without values round-trip nulls unchanged.
  - Goal: Add optional sodium/fiber/sugar per-100g to the ingredient domain model, repository mapping, form, and list display.
  - Boundaries (in/out of scope):
    - In: `lib/src/models/ingredient.dart` (3 nullable fields + `copyWith`), `lib/src/diet/repositories/ingredient_repository.dart` (map new columns; `newIngredient` optional params), `lib/src/diet/screens/ingredient_form.dart` (3 optional fields, blank → null, suffix mg/g), `lib/src/diet/screens/ingredient_list.dart` (optional subtitle line), ARB keys en/fr/es + `flutter gen-l10n`.
    - Out: `meal_ingredients`/meal breakdown changes (user decision: ingredient-only), dashboard changes.
  - Done when:
    - Existing ingredients without nutriment values load/save unchanged (nulls round-trip).
    - Form accepts optional sodium (mg), fiber (g), sugar (g); empty → stored `null`; non-empty validated non-negative.
    - All new strings localized en/fr/es; `flutter gen-l10n` — exit 0.
    - `dart analyze lib/` — zero errors.
  - Verification notes (commands or checks):
    - `flutter gen-l10n` — exit 0; `dart analyze lib/` — "No issues found!".
    - `flutter test` — 1/1 passed.

---

- [x] T04: `Search boxes in meal and workout forms` (status:done)
  - Task ID: T04
  - Completed: 2026-08-05
  - Files changed: `lib/src/diet/screens/meal_form.dart` (search field + case-insensitive name filter over the ingredient picker), `lib/src/exercise/screens/workout_form.dart` (same over the exercise picker), `lib/l10n/app_{en,es,fr}.arb` (`commonSearch` key) + regenerated `app_localizations*.dart`
  - Evidence: `flutter gen-l10n` exit 0; `dart analyze lib/src/diet/ lib/src/exercise/` "No issues found!"; `dart analyze lib/` "No issues found!"; `flutter test` 1/1 passed
  - Notes: Filter is `name.toLowerCase().contains(query)`; empty query shows all. Selection state lives in separate maps (`_grams`/`_selected`), so filtering preserves selection and hidden selections still save. Search field shown only when the full list is non-empty. No no-results messaging (not in acceptance criteria).
  - Goal: Add a name-filter search box to the ingredient picker in the meal form and to the exercise picker in the workout form.
  - Boundaries (in/out of scope):
    - In: `lib/src/diet/screens/meal_form.dart` (filter `TextField` over the ingredient list), `lib/src/exercise/screens/workout_form.dart` (filter `TextField` over the exercise list), ARB keys en/fr/es + `flutter gen-l10n`.
    - Out: Search on other screens, fuzzy matching, new dependencies.
  - Done when:
    - Typing filters the picker list case-insensitively by name; clearing shows all; selection state is preserved while filtering.
    - New strings localized en/fr/es; `dart analyze lib/` — zero errors.
  - Verification notes (commands or checks):
    - `flutter gen-l10n` — exit 0; `dart analyze lib/src/diet/ lib/src/exercise/` — zero errors.

---

- [x] T05: `Planner task due date` (status:done)
  - Task ID: T05
  - Completed: 2026-08-05
  - Files changed: `lib/src/models/planner_item.dart` (`DateTime? dueDate` + sentinel `copyWith`), `lib/src/planner/repositories/planner_repository.dart` (`insert`/`update`/`_toDomain`/`copyFromPreviousDay` write `due_date`; `newPlannerItem` optional param), `lib/src/planner/screens/planner_item_dialog.dart` (returns `(title, dueDate)` record; date row with picker + clear button; `initialDueDate` param), `lib/src/planner/screens/planner_screen.dart` (add pre-fills `_selectedDay`, edit passes `item.dueDate`, tile shows formatted due date), `lib/l10n/app_{en,es,fr}.arb` (`plannerDueDateNone`, `plannerDueDateClear`) + regenerated `app_localizations*.dart`
  - Evidence: `flutter gen-l10n` exit 0; `dart analyze lib/src/planner/` "No issues found!"; `dart analyze lib/` "No issues found!"; `flutter test` 1/1 passed
  - Notes: Dialog return changed from `String` to `(String, DateTime?)` record — both call sites updated. Add flow defaults due date to the selected day (editable/clearable); edit preserves existing value. Tile uses `MaterialLocalizations.formatMediumDate`. Copy-from-previous-day carries `due_date`. Manual runtime check (set due date, copy from yesterday) deferred to T11.
  - Goal: Add an optional due date to planner tasks: model, repository write-through, dialog picker defaulting to the selected day, tile display, and copy-from-previous-day carry-over.
  - Boundaries (in/out of scope):
    - In: `lib/src/models/planner_item.dart` (`DateTime? dueDate` + `copyWith`), `lib/src/planner/repositories/planner_repository.dart` (insert/update write `due_date`; `copyFromPreviousDay` copies it; `newPlannerItem` optional param), `lib/src/planner/screens/planner_item_dialog.dart` (optional date field, pre-filled with the selected day, clearable), `lib/src/planner/screens/planner_screen.dart` (pass default day; tile shows due date), ARB keys en/fr/es + `flutter gen-l10n`.
    - Out: Due-date reminders/notifications, re-scheduling, sorting by due date, changes to the day-keyed list semantics.
  - Done when:
    - Adding/editing a task sets an optional due date; tile shows it when set; copy-from-previous-day carries `dueDate` into the copied tasks.
    - `dart analyze lib/` — zero errors.
  - Verification notes (commands or checks):
    - `flutter gen-l10n` — exit 0; `dart analyze lib/src/planner/` — zero errors.
    - Manual (deferred): set due date, copy from yesterday, verify due dates carried.

---

- [x] T06: `Body metrics on dashboard (weight + height)` (status:done)
  - Task ID: T06
  - Completed: 2026-08-06
  - Files changed: `lib/src/models/body_metrics_entry.dart` (new — domain model), `lib/src/body/repositories/body_metrics_repository.dart` (new — `getAll()` chronological, `getLatest()` desc-limit-1, `upsert(day, {weightKg, heightCm})` where a null arg leaves that metric unchanged), `lib/src/body/providers/body_metrics.dart` (new — `bodyMetricsRepositoryProvider`, `bodyMetricsProvider`, `latestBodyMetricsProvider`), `lib/src/body/screens/body_metric_dialog.dart` (new — single-value dialog: date picker defaulting to today, empty required value, returns `(day, value)`), `lib/src/body/screens/body_metrics_card.dart` (new — dashboard card: "Add weight"/"Add height" buttons + latest summary + weight/height evolution via `fl_chart`), `lib/src/dashboard/screens/dashboard.dart` (third card), `lib/l10n/app_{en,es,fr}.arb` (17 `bodyMetrics*` keys) + regenerated `app_localizations*.dart`
  - Evidence: `flutter gen-l10n` exit 0; `dart analyze lib/src/body/ lib/src/dashboard/` "No issues found!"; `dart analyze lib/` "No issues found!"; `flutter test` 1/1 passed
  - Notes: User decision (2026-08-06): weight and height are added via **separate** dialogs, not one combined form. Each dialog: date picker defaults to today, value field is empty with no default, value required and positive (non-null; blank or `<= 0` rejected). `upsert` semantics: a null `weightKg`/`heightCm` argument leaves that metric unchanged, so adding height never wipes a stored weight and vice versa; re-saving the same day for the same metric updates in place. Charts via `fl_chart` (dependency no longer dead): ≥2 points → line chart with date bottom titles + touch tooltip; 1 point → bold value text; 0 points → empty-state text. Latest summary line uses `latestBodyMetricsProvider`. `fl_chart` LineChart API verified against installed 1.2.0 (FlTitlesData/AxisTitles/SideTitles, GetTitleWidgetFunction `(double, TitleMeta)`). `color.withValues(alpha:)` matches repo convention (Flutter 3.38.3). Manual runtime check (add entries across days, verify charts update) deferred to T11.
  - Goal: Add body weight/height tracking: repository over `body_metrics`, providers, a Dashboard card with an add-entry dialog and evolution charts.
  - Boundaries (in/out of scope):
    - In: `lib/src/body/repositories/body_metrics_repository.dart` (new — `getAll()`, `upsert(day, {weightKg, heightCm})` keyed by start-of-day, `getLatest()`), `lib/src/body/providers/body_metrics.dart` (repository + `bodyMetricsProvider`, `latestBodyMetricsProvider`), `lib/src/dashboard/screens/dashboard.dart` (new "Body Metrics" card: add button/dialog with weight + height, weight line chart + height line chart via `fl_chart`), ARB keys en/fr/es + `flutter gen-l10n`.
    - Out: Profile/age (T07), charts elsewhere, BMI/derived metrics.
  - Done when:
    - User can add weight (kg) and/or height (cm) for a day; re-saving the same day updates instead of duplicating.
    - Dashboard renders weight and height evolution (charts when ≥2 points; single point as text).
    - `fl_chart` is used (dependency no longer dead).
    - `dart analyze lib/` — zero errors.
  - Verification notes (commands or checks):
    - `flutter gen-l10n` — exit 0; `dart analyze lib/src/body/ lib/src/dashboard/` — zero errors.
    - Manual (deferred): add entries across days, verify chart updates.

---

- [x] T07: `Settings: profile (age), theme mode, language` (status:done)
  - Task ID: T07
  - Completed: 2026-08-06
  - Files changed: `lib/src/settings/providers/settings.dart` (new — `SettingsState` (themeMode/locale/age) + `SettingsNotifier extends Notifier<SettingsState>` + `sharedPreferencesProvider`), `lib/src/settings/screens/settings_screen.dart` (new — `ConsumerStatefulWidget`: Profile age field, Appearance theme `SegmentedButton`, Language `SegmentedButton`), `lib/src/app/tabs/settings_tab.dart` (renders `SettingsScreen`), `lib/src/app/app.dart` (`FitFatApp` is now a `ConsumerWidget`; `MaterialApp.router` gets `theme`/`darkTheme`/`themeMode`/`locale`), `lib/src/app/theme.dart` (added `FitFatTheme.dark`), `lib/main.dart` (`main()` awaits `SharedPreferences.getInstance()`, wraps `runApp` in `ProviderScope` with `sharedPreferencesProvider` override), `lib/l10n/app_{en,es,fr}.arb` (12 new `settings*` keys; removed dead `settingsBody`) + regenerated `app_localizations*.dart`
  - Evidence: `flutter gen-l10n` exit 0; `dart analyze lib/src/settings/ lib/src/app/ lib/main.dart` "No issues found!"; `dart analyze lib/` "No issues found!"; `flutter test` 1/1 passed
  - Notes: First Riverpod `Notifier` in the repo (Riverpod 3.3.1). `sharedPreferencesProvider` is overridden in `main()` so settings load synchronously with no flicker (defaults: `ThemeMode.system`, `locale` null = device locale, `age` null). Language is en/fr/es only per plan — before the user picks, the app follows the device locale; there is no "System" option to revert after choosing. Language `SegmentedButton` uses `emptySelectionAllowed: true` + empty guard because `selected` may start empty (Flutter asserts `selected.length > 0 || emptySelectionAllowed`). Age: numeric field validated 0–120; blank clears the stored age (`setAge(null)` removes the key). Age changes apply immediately and persist via `shared_preferences` keys `settings_theme_mode`/`settings_locale`/`settings_age`. Manual runtime check (set dark + French, restart, verify persisted) deferred to T11.
  - Goal: Build the Settings screen: profile age input, theme mode (system/light/dark), language (en/fr/es) — all persisted via `shared_preferences` and applied app-wide.
  - Boundaries (in/out of scope):
    - In: `lib/src/settings/providers/settings.dart` (new `Notifier`/provider over `SharedPreferences`: `themeMode`, `locale`, `age`), `lib/src/settings/screens/settings_screen.dart` (new — Profile / Appearance / Language sections; replace the placeholder body in `lib/src/app/tabs/settings_tab.dart`), `lib/src/app/app.dart` (`FitFatApp` becomes a `ConsumerWidget` watching the provider; `MaterialApp.router` gets `themeMode`, `darkTheme`, `theme`, `locale`), `lib/src/app/theme.dart` (add `FitFatTheme.dark`), ARB keys en/fr/es + `flutter gen-l10n`.
    - Out: Dark-mode styling pass beyond the standard M3 dark theme; per-profile multi-user support; DB storage for settings.
  - Done when:
    - Changing theme applies immediately and persists across restarts; same for language and age.
    - Settings screen shows Profile (age), Appearance (system/light/dark), Language (en/fr/es).
    - `shared_preferences` is used (dependency no longer dead).
    - `dart analyze lib/` — zero errors.
  - Verification notes (commands or checks):
    - `flutter gen-l10n` — exit 0; `dart analyze lib/src/settings/ lib/src/app/` — zero errors.
    - Manual (deferred): set dark + French, restart, verify persisted.

---

- [x] T08: `Workout form: no default set values` (status:done)
  - Task ID: T08
  - Completed: 2026-08-06
  - Files changed: `lib/src/exercise/screens/workout_form.dart` (`_PlannedSetEntry` fields now `int? reps`/`double? weightKg`/`int? durationMinutes` with null defaults and no constructor params; checkbox select stores `[]` instead of auto-generating 3 default sets; "Add set" appends `_PlannedSetEntry()` (empty); set-row fields use null-safe `initialValue` (`entry.reps?.toString() ?? ''`) and nullable `onChanged` parse (`int.tryParse` → null on empty); save passes values through `(plan.x ?? 0) > 0 ? plan.x : null`)
  - Evidence: `dart analyze lib/src/exercise/` "No issues found!"; `dart analyze lib/` "No issues found!"; `flutter test` 1/1 passed. No ARB/gen-l10n needed (no new strings).
  - Notes: `newPlannedSet` already accepted nullable `reps`/`weightKg`/`durationMinutes` — no repository/model change. The `(plan.x ?? 0) > 0 ? plan.x : null` guard is kept (Dart requires `?? 0` before `>` on a nullable) so empty fields **and** a typed `0` both store `null`, preserving the detail-screen "—" rendering. `_PlannedSetEntry` keeps no explicit constructor (implicit default) to avoid `unused_element_parameter` warnings. An exercise can now be saved with 0 sets (detail renders "0 sets"). Form-field text persists across rebuilds via the existing `initialValue` + `onChanged` pattern (state preserved by position). Manual runtime check (create workout with an empty set → detail shows "—") deferred to T11.
  - Goal: Remove pre-filled planned-set values from the workout form: selecting an exercise creates 0 sets and each "Add set" appends an empty set.
  - Boundaries (in/out of scope):
    - In: `lib/src/exercise/screens/workout_form.dart` (`_PlannedSetEntry` nullable/empty defaults; remove auto-generated 3 sets on select; "Add set" appends an empty entry; save maps empty fields to `null` via `newPlannedSet`).
    - Out: Detail-screen behavior, actual-value logging, rest timer (T10).
  - Done when:
    - Selecting an exercise shows no sets; "Add set" adds one empty set (blank reps/kg/min fields); saving stores `null` for unset values.
    - `dart analyze lib/` — zero errors.
  - Verification notes (commands or checks):
    - `dart analyze lib/src/exercise/` — zero errors.
    - Manual (deferred): create workout with an empty set → detail shows "—" planned.

---

- [x] T09: `Fix workout actuals not refreshing on save` (status:done)
  - Task ID: T09
  - Completed: 2026-08-06
  - Files changed: `lib/src/exercise/screens/workout_detail.dart` (`_editActuals` now invalidates `workoutDetailProvider(workout.id)`; removed the now-unused `workoutExerciseId` field/ctor param from `_SetRow` and its `workoutExerciseId: block.exercise.id` call-site argument in `_ExerciseBlockCard`)
  - Evidence: `dart analyze lib/src/exercise/` "No issues found!"; `dart analyze lib/` "No issues found!"; `flutter test` 1/1 passed. No ARB/gen-l10n needed (no new strings).
  - Notes: One-line fix at the right key: `workoutDetailProvider` is keyed by workout id, so invalidating with `workoutExerciseId` refreshed a provider instance nobody watches; the view only appeared to update on Complete (which invalidates `workoutDetailProvider(workoutId)`). `_SetRow` already held the `Workout` object, so `workout.id` needed no new threading. `workoutExerciseId` had no other use, so it was fully removed to keep `dart analyze lib/` at zero issues (not just zero errors). Manual runtime check (active workout → log actuals → values appear instantly without completing) deferred to T11.
  - Goal: Fix the bug where logging a set's actual values in an active workout does not appear in the detail view until the workout is completed.
  - Boundaries (in/out of scope):
    - In: `lib/src/exercise/screens/workout_detail.dart` — `_editActuals` must invalidate `workoutDetailProvider(workoutId)` (the workout id), not `workoutDetailProvider(workoutExerciseId)`; thread the workout id down to `_SetRow` (it already receives the `Workout` object).
    - Out: Rest timer (T10), any other refresh behavior.
  - Done when:
    - Saving actuals for a set updates the detail view immediately.
    - `dart analyze lib/` — zero errors.
  - Verification notes (commands or checks):
    - `dart analyze lib/src/exercise/` — zero errors.
    - Manual (deferred): active workout → log actuals → values appear instantly without completing.

---

- [x] T10: `Active workout rest timer + ongoing notification` (status:done)
  - Task ID: T10
  - Completed: 2026-08-06
  - Files changed: `lib/main.dart` (`FlutterForegroundTask.initCommunicationPort()` + `init(...)` — channel `active_workout`, `repeat(1000)` 1 s ticks, no auto-run on boot), `lib/src/notifications/rest_timer.dart` (new — `RestTimerState`/`RestTimerNotifier` persisting `rest_end_at` epoch millis in shared_preferences + shared `formatRestDuration`), `lib/src/notifications/active_workout_notifier.dart` (new — `activeWorkoutTaskCallback` top-level `@pragma('vm:entry-point')` + `ActiveWorkoutTaskHandler` rebuilding notification text each tick from prefs; `ActiveWorkoutNotifier`/`activeWorkoutNotifierProvider` for Start/Stop; Android service start/stop via `flutter_foreground_task`, `permission_handler` POST_NOTIFICATIONS request; iOS best-effort via `flutter_local_notifications`), `lib/src/exercise/screens/workout_detail.dart` (`_startWorkout` persists session + starts service, `_completeWorkout` cancels rest + stops service; new `_RestTimerCard` with preset chips 2/3/4/5/6 min, live mm:ss countdown, cancel), `lib/l10n/app_{en,es,fr}.arb` (5 keys) + regenerated `app_localizations*.dart`
  - Evidence: `flutter gen-l10n` exit 0; `dart analyze lib/src/notifications/ lib/src/exercise/` "No issues found!"; `dart analyze lib/` "No issues found!"; `flutter test` 1/1 passed
  - Notes: User decision (2026-08-06): rest duration via **preset chips in minutes — 2/3/4/5/6 min**. `flutter_foreground_task` 9.2.2 API verified from installed source/example (`initCommunicationPort`/`init`/`startService`/`updateService`/`stopService`, `TaskHandler`, `ForegroundTaskEventAction.repeat`, sealed `ServiceRequestResult`). The background callback runs in its own FlutterEngine, so `shared_preferences` is available in the handler (the package itself uses shared_preferences internally). Session keys persisted to prefs: `active_workout_name`, `active_workout_started_at`, plus localized `notification_elapsed_label`/`notification_rest_label` fragments (AppLocalizations is unavailable in the background isolate, so notification language is fixed at workout start). Expired `rest_end_at` is auto-cleared by both the handler and the UI ticker. Android notification channel name/description are hardcoded English (system-level, set at init before l10n loads). iOS path (`Platform.isIOS` guard) shows once on start — no backgrounded updates (per plan). `restartService()` used instead of `startService()` when the service is already running (`startService` throws `ServiceAlreadyStartedException` internally). Notification text format: "Elapsed 12:34" / "Elapsed 12:34 · Rest 0:45" via `formatRestDuration` (mm:ss, h:mm:ss ≥ 1 h). Manual runtime check (start → notification with duration+rest; complete → gone) deferred to T11.
  - Goal: Add a rest timer between sets on the workout detail screen and an ongoing Android notification showing workout duration and remaining rest time, driven by `flutter_foreground_task` (+ `flutter_local_notifications`).
  - Boundaries (in/out of scope):
    - In: `lib/src/exercise/screens/workout_detail.dart` (rest timer UI: start/cancel between sets, mm:ss countdown, adjustable duration), `lib/src/notifications/active_workout_notifier.dart` (new — orchestrates `flutter_foreground_task`: start service on workout Start, update notification each tick with duration + remaining rest, stop on Complete), `lib/src/notifications/rest_timer.dart` (new — rest state provider; persists `rest_end_at` epoch millis in `shared_preferences` so the background callback can read it), runtime `POST_NOTIFICATIONS` permission via `permission_handler` (Android 13+), ARB keys en/fr/es + `flutter gen-l10n`.
    - Out: iOS foreground-service parity (best-effort ongoing notification only), scheduled/reminder notifications, notification actions (pause/resume).
  - Done when:
    - Starting a workout shows an ongoing notification (lock screen + normal usage) with the workout duration; while a rest is running it shows remaining rest time; completing the workout removes it.
    - Rest timer counts down on the detail screen and cancels on Complete/navigation-away-per-workout.
    - `flutter_foreground_task` and `flutter_local_notifications` are used (dependencies no longer dead).
    - `dart analyze lib/` — zero errors.
  - Verification notes (commands or checks):
    - `flutter gen-l10n` — exit 0; `dart analyze lib/src/exercise/ lib/src/notifications/` — zero errors.
    - Manual (deferred): start workout → notification visible; start rest → notification shows countdown; complete → notification gone.

---

- [x] T11: `Final validation, cleanup, and context sync` (status:done)
  - Task ID: T11
  - Completed: 2026-08-06
  - Files changed: `context/exercise/workout-crud.md` (added active-workout rest timer/notification note — the only context drift found), `context/plans/app-improvements.md` (validation report below). No `lib/` changes.
  - Evidence: `flutter pub run build_runner build` exit 0 (87 outputs, up to date); `flutter gen-l10n` exit 0; `dart analyze lib/` "No issues found!"; `flutter test` 1/1 passed; `dart format --output=none --set-exit-if-changed lib/ test/` exit 0 (58 files, 0 changed); `git status --short` shows only intended files; no `context/tmp/` scraps; no `print`/`debugPrint` in `lib/`.
  - Notes: Full suite green. All 12 T11-listed context files re-read against code — only drift was `workout-crud.md` missing the T10 rest-timer/notification note (fixed). No leftover placeholder text or dead code in `lib/` (only match is a legitimate comment in `meal_form.dart`; dead `settingsBody` key removed in T07; sole test remains `test/placeholder_test.dart` per repo posture). Manual checklist from the 10 success criteria deferred to the user (headless env) and enumerated in the Validation Report residual risks. Plan complete — 11/11.
  - Goal: Run the full verification suite, confirm all 10 success criteria, remove any placeholder/dead code, and sync `context/` to the new current state.
  - Boundaries (in/out of scope):
    - In: Verification commands, cleanup (e.g., any leftover placeholder text, dead code from changed screens), context updates.
    - Out: New features, refactors beyond the 10 items.
  - Done when:
    - `flutter pub run build_runner build` — exit 0; `flutter gen-l10n` — exit 0; `dart analyze lib/` — zero errors; `flutter test` — passes.
    - Manual checklist from success criteria passes (deferred to the user — headless env): meal save-with-ingredients, search filtering, due date + copy carry-over, body metrics entry + charts, age persistence, no set defaults, theme/language persistence, actuals refresh, notification + rest timer.
    - Context synced:
      - `context/database/schema.md` — 9 tables, v3 migration note (done in T01; verify).
      - `context/body/body-metrics.md` — new domain doc (table, repository, providers, dashboard UI).
      - `context/settings/settings.md` — new domain doc (profile age, theme, language, storage).
      - `context/notifications/notifications.md` — new domain doc (rest timer, foreground notification, lifecycle).
      - `context/diet/ingredient-crud.md` — optional nutriments.
      - `context/diet/meal-crud.md` — search box + meal-save bug fix note.
      - `context/exercise/workout-crud.md` — search box, no set defaults, actuals refresh fix, rest timer/notification.
      - `context/planner/planner.md` — due date.
      - `context/glossary.md` — `body_metrics` table, `FlutterForegroundTask`/ongoing notification terms as needed.
      - `context/overview.md` — profile/theme/language, body metrics if cross-cutting.
      - `context/context-map.md` — add `plans/app-improvements.md` + new domain doc rows.
      - `context/architecture.md` — note settings/app-level changes (themeMode/locale) if needed.
  - Verification notes (commands or checks):
    - Commands above all exit 0; `git status` shows only intended files.
    - Re-read synced context files to confirm accuracy against code.

---

## Open Questions

None. All scope decisions were resolved with the user and recorded in Assumptions.

## Next Command

```
Plan complete — all 11 tasks (T01–T11) are done. Validation report below.
```

---

## Validation Report

### Commands run
- `flutter pub run build_runner build` -> exit 0 (87 outputs — codegen up to date)
- `flutter gen-l10n` -> exit 0 (options from `l10n.yaml`; localizations regenerated)
- `dart analyze lib/` -> exit 0 ("No issues found!")
- `flutter test` -> exit 0 (1/1 passed — `test/placeholder_test.dart`)
- `dart format --output=none --set-exit-if-changed lib/ test/` -> exit 0 (58 files, 0 changed)
- `git status --short` -> only intended files; `context/tmp/` empty; no `print(`/`debugPrint(` in `lib/`

### Success-criteria verification
- [x] Ingredient form stores optional sodium/fiber/sugar per 100g; existing ingredients round-trip nulls; `meal_ingredients` untouched -> `ingredient_repository.dart` + `ingredient_form.dart` + `ingredient_list.dart` (T01/T03); analyzer clean. Runtime check deferred (headless).
- [x] Meal + workout form search boxes (case-insensitive name filter) -> `meal_form.dart` + `workout_form.dart` (T04); analyzer clean. Runtime check deferred.
- [x] Planner due date (defaults to selected day, clearable, tile shows date, copy carries it) -> planner model/repo/dialog/screen (T05); analyzer clean. Runtime check deferred.
- [x] Creating a new meal persists `meal_ingredients` rows -> `meal_repository.newMeal` stamps the generated meal id onto every item (T02); orphaned rows cleaned by the v3 migration (T01). Runtime regression deferred.
- [x] Dashboard body metrics card (weight + height evolution via `fl_chart`) -> `lib/src/body/` + dashboard third card (T06); analyzer clean. Runtime check deferred.
- [x] Settings Profile age, persists via `shared_preferences` -> `lib/src/settings/` + `FitFatApp` consumer wiring (T07); analyzer clean. Runtime check deferred.
- [x] Workout form: selecting an exercise creates 0 sets; "Add set" appends empty sets; unset values stored as `null` -> `workout_form.dart` (T08); analyzer clean. Runtime check deferred.
- [x] Settings theme mode + language, persisted and applied immediately -> `settings_screen.dart` + `MaterialApp.router` `themeMode`/`locale`/`darkTheme` (T07); analyzer clean. Runtime check deferred.
- [x] Actuals refresh immediately on save -> `_editActuals` invalidates `workoutDetailProvider(workout.id)` (T09); analyzer clean. Runtime check deferred.
- [x] Active workout ongoing notification + in-app rest timer -> `lib/src/notifications/` + `main.dart` + `_RestTimerCard` preset 2–6 min chips (T10); `flutter_foreground_task`/`flutter_local_notifications` now used; analyzer clean. Runtime check deferred.
- [x] `flutter pub run build_runner build` clean -> exit 0; `flutter gen-l10n` clean -> exit 0; `dart analyze lib/` zero errors -> "No issues found!"; `flutter test` passes -> 1/1.
- [x] `git status` shows only intended files (all changes are T01–T10 modifications + new domain dirs/context docs).
- [x] All new user-facing strings localized en/fr/es -> `commonSearch`, `plannerDueDate*`, `bodyMetrics*`, `settings*`, and T10 notification keys present in all three ARB files.

### Failed checks and follow-ups
- None. All automated checks pass.

### Residual risks
- Manual runtime validation not executed (headless environment, no `flutter run`). Deferred checklist for the user:
  - Meal save-with-ingredients regression (create meal → reopen → ingredients present).
  - Search filtering in meal/workout forms.
  - Planner due date set + clear + copy-from-previous-day carry-over.
  - Body metrics: add weight/height across days → charts update; re-save same day → upsert (no duplicate).
  - Settings: set age/dark/French → restart → persisted.
  - Workout form: select exercise → 0 sets; Add set → empty set; detail shows "—".
  - Actuals: active workout → log actuals → values appear instantly without completing.
  - Notification + rest timer: start workout → ongoing notification with duration; start rest (2–6 min chip) → countdown in notification + card; complete → notification gone.
- Changes are uncommitted (repo policy — commit only when requested).
