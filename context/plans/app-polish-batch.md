# Plan: App polish batch — dashboard, settings, planner, workout sets

## Change Summary

Eight user-requested UX/data changes across the dashboard, settings, planner, and workout screens
(decisions resolved with the user 2026-08-09):

1. **Dashboard settings button**: the dashboard AppBar (today: title only) gains a settings icon in
   the top-right corner that opens the Settings tab.
2. **Body-weight goal**: a new Settings option — goal = **lose weight / maintenance / gain weight**
   — persisted in `shared_preferences`; the dashboard `BodyMetricsCard` shows the active goal as a
   small badge.
3. **Quick-action chips aligned**: the dashboard's 3 uneven `ActionChip`s in a `Wrap` become an
   **equal-width row** (`Row` + `Expanded`). Per user: **remove the start-or-resume-workout chip**
   (the latest-workout card + global active bar already cover workout entry) and **remove the
   log-meal chip** (user confirmed). The quick actions become **log body weight + log height** (the
   height chip is new — opens the existing height dialog).
4. **Planner free-text notes**: planner tasks gain an optional free-text notes field (schema v5 → v6,
   `planner_items.notes`), editable in the existing add/edit dialog and shown under the task title.
5. **Planner day swipe**: the day body becomes a horizontal `PageView` so swiping left/right changes
   the selected day; the existing chevrons + Today button stay. A swipe starting on a task tile still
   deletes it (existing `Dismissible` behavior wins on tiles).
6. **Set value decimals**: set values (kg / m) are no longer rounded to 0 decimals — display **one
   decimal only when fractional** ("12 kg" / "12.5 kg") in the workout detail, active-workout screen,
   and summary.
7. **Active-workout back button**: `ActiveWorkoutScreen` gains a leading back affordance — pop when a
   back stack exists, else return to the exercise tab (`go('/exercise')`).
8. **Set completion timestamp**: when a set's actuals are recorded (set done), the **completion
   time** is saved (`exercise_sets.completed_at`, schema v6 → v7) and shown as HH:mm on the set row
   in the active-workout screen. This raw data enables future rest-between-sets math (out of scope
   here — `actualRestSeconds` already covers rest today).

Two sequential schema bumps: **v5 → v6** (`planner_items.notes`, T04) and **v6 → v7**
(`exercise_sets.completed_at`, T08), each with `build_runner` regeneration.

## Success Criteria

- Dashboard AppBar shows a settings icon top-right; tapping it opens the Settings tab.
- Settings has a body-weight goal selector (lose / maintenance / gain); the choice persists across
  restarts and is reflected on the dashboard `BodyMetricsCard`.
- Dashboard quick actions render as an equal-width row with exactly **log weight + log height**;
  neither the meal chip nor the workout chip is present.
- Planner tasks can hold an optional free-text note: entered/edited in the dialog, displayed in the
  tile, carried by copy-from-previous-day, and round-tripped through insert/update/delete+undo.
- Planner day body swipes left/right to change the day (chevrons + Today still work; swiping on a
  tile still deletes).
- Set weights/distances display one decimal only when fractional in detail, active, and summary
  screens.
- `ActiveWorkoutScreen` has a leading back button: pops when possible, else returns to `/exercise`.
- Recording a set's actuals stamps `completed_at`; the active screen shows the completion time
  HH:mm on that set row; the column round-trips through restore.
- `flutter pub run build_runner build` — exit 0 (both schema tasks); `flutter gen-l10n` — exit 0;
  `dart analyze lib/` — zero errors; `flutter test` — passes; all new strings localized en/fr/es;
  `context/` synced.

## Constraints & Non-Goals

- **No new dependencies.** All changes use existing packages (`shared_preferences`, `drift`, etc.).
- Schema changes are exactly two bumps: **v5 → v6** (only `planner_items.notes`, nullable) and
  **v6 → v7** (only `exercise_sets.completed_at`, nullable). No other columns.
- No rest-between-sets calculation in this plan (raw `completed_at` is recorded for future use;
  `actualRestSeconds` remains the rest source today).
- Removing chips does NOT remove their ARB keys (unused keys are harmless); optional key cleanup is
  left to T09 only if trivial.
- No changes to notification content, no new tabs, no auth/sync, no dependency changes.
- Manual UI verification deferred to the user (headless environment); deferred checks recorded per
  task as in prior plans.
- Not in scope: exercise definitions, meal/ingredient changes, chart changes, git commit.

## Task stack

- [x] T01: `Dashboard settings button — top-right → /settings` (status:done)
  - Task ID: T01
  - Completed: 2026-08-09
  - Files changed: `lib/src/dashboard/screens/dashboard.dart` (`DashboardScreen` AppBar gains
    `actions: [IconButton(Icons.settings, tooltip: l10n.settingsAppBar, onPressed: () =>
    context.go('/settings'))]` — no ARB changes, tooltip reuses the existing `settingsAppBar` key;
    `go_router` import already present)
  - Evidence: `dart analyze lib/` "No issues found!" exit 0; `flutter test` 1/1 passed exit 0;
    `dart format --output=none --set-exit-if-changed lib test` exit 0 ("Formatted 67 files (0
    changed)"); grep — `Icons.settings` at dashboard.dart:46, `go('/settings')` at :48
  - Goal: Add a settings icon button to the top-right of the dashboard AppBar that opens the Settings
    tab.
  - Boundaries (in/out of scope):
    - In: `lib/src/dashboard/screens/dashboard.dart` — `DashboardScreen` Scaffold AppBar gains
      `actions: [IconButton(Icons.settings, tooltip: l10n.settingsAppBar, onPressed: context.go('/settings'))]`.
      `go_router` is already imported; `/settings` is an existing shell branch (branch switching via
      `context.go` is the established pattern, see architecture.md).
    - Out: settings screen content, other tabs, ARB changes (tooltip reuses `settingsAppBar`).
  - Done when: dashboard AppBar shows the settings icon top-right; tapping it lands on the Settings
    tab; `dart analyze lib/` zero errors.
  - Verification notes (commands or checks):
    - `rg -n "Icons.settings|go('/settings')" lib/src/dashboard/screens/dashboard.dart` — present.
    - Manual (deferred): tap gear on dashboard → Settings tab.

---

- [x] T02: `Body-weight goal — settings selector + dashboard badge` (status:done)
  - Task ID: T02
  - Goal: Add a persisted body-weight goal setting (lose / maintenance / gain) in Settings and show
    the active goal on the dashboard `BodyMetricsCard`.
  - Boundaries (in/out of scope):
    - In: `lib/src/settings/providers/settings.dart` — new enum `BodyWeightGoal { lose, maintain,
      gain }` (domain file `lib/src/models/` or local to settings — follow existing style);
      `SettingsState` gains `BodyWeightGoal? bodyWeightGoal` (null = unset) with `copyWith` support;
      `SettingsNotifier` persists it under a new prefs key (`settings_body_weight_goal`) in
      `build()`/`setBodyWeightGoal(...)` following the `age` pattern (remove on null).
      `lib/src/settings/screens/settings_screen.dart` — new "Body weight goal" section (under
      Profile) with a `SegmentedButton<BodyWeightGoal>` (lose / maintenance / gain) following the
      existing theme/language SegmentedButton pattern.
      `lib/src/body/screens/body_metrics_card.dart` — show the active goal as a small badge/label in
      the card header row (trailing side of the title Row) when set; hidden when unset.
      `lib/l10n/app_en.arb` / `app_fr.arb` / `app_es.arb` — new keys: section label
      (`settingsBodyWeightGoal`), the three option labels (`settingsGoalLose` / `settingsGoalMaintain`
      / `settingsGoalGain`), and a dashboard badge label with the goal interpolated (e.g.
      `bodyMetricsGoal` = "Goal: {goal}" — en/fr/es) + `flutter gen-l10n`.
    - Out: changing any body-metrics logic, trend hints, calorie targets.
  - Done when: selecting a goal persists across restart (prefs key), re-renders the SegmentedButton,
    and shows on the dashboard card; unsetting (no such UI — goal is always one of three once set;
    default null = no badge); `flutter gen-l10n` exit 0; `dart analyze lib/` zero errors.
  - Verification notes (commands or checks):
    - `flutter gen-l10n` — exit 0; grep new keys in all 3 ARBs.
    - `rg -n "bodyWeightGoal|settings_body_weight_goal" lib/src/settings lib/src/body` — wired.
    - Manual (deferred): pick a goal → badge appears on dashboard; restart → still selected.
  - Task ID: T02
  - Completed: 2026-08-10
  - Files changed: `lib/src/models/body_weight_goal.dart` (new — `enum BodyWeightGoal { lose,
    maintain, gain }`); `lib/src/settings/providers/settings.dart` (`SettingsState.bodyWeightGoal`
    + `copyWith` `clearBodyWeightGoal` sentinel, `_bodyWeightGoalKey`, `build()` restore,
    `setBodyWeightGoal`, `_bodyWeightGoalFromName`); `lib/src/settings/screens/settings_screen.dart`
    ("Body weight goal" section with `SegmentedButton<BodyWeightGoal>` after the age form);
    `lib/src/body/screens/body_metrics_card.dart` (goal badge in header row, right-aligned via
    `Expanded` title + trailing `Text`); `lib/l10n/app_en.arb` / `app_fr.arb` / `app_es.arb`
    (5 new keys each + `@bodyMetricsGoal` placeholder metadata) + regenerated `app_localizations*.dart`
  - Evidence: `flutter gen-l10n` exit 0; `dart analyze lib/` "No issues found!" exit 0; `flutter test`
    1/1 passed exit 0; `dart format --output=none --set-exit-if-changed lib test` exit 0 ("Formatted
    68 files (0 changed)"); grep — `bodyWeightGoal|settings_body_weight_goal` wired in settings
    provider/screen + body card; enum at `lib/src/models/body_weight_goal.dart:2`; 5 keys present in
    all 3 ARBs
  - Notes: goal persists via `settings_body_weight_goal`; unset only via null default (no UI to
    clear once set); body → settings provider import added in `body_metrics_card.dart`.

---

- [x] T03: `Dashboard quick actions — equal-width row, weight + height chips` (status:done)
  - Task ID: T03
  - Goal: Replace the dashboard quick-action `Wrap` with an equal-width row of exactly two chips
    (log body weight + log height), removing the meal and start/resume-workout chips.
  - Boundaries (in/out of scope):
    - In: `lib/src/dashboard/screens/dashboard.dart` — `_QuickActions.build` replaces the `Wrap` with
      a `Row` of two `Expanded` `ActionChip`s: keep `_logWeight` (existing) and add `_logHeight`
      mirroring `BodyMetricsCard._addHeight` (`showBodyMetricDialog` with `bodyMetricsDialogHeightTitle`
      / `bodyMetricsHeightLabel` / suffix `'cm'` → `bodyMetricsRepositoryProvider.upsert(day,
      heightCm: value)` + invalidate `bodyMetricsProvider`/`latestBodyMetricsProvider` + saved
      SnackBar). Remove the meal chip (`_logMeal` — delete the now-unused method + its
      `mealListProvider`/`todayCaloriesProvider`/`todayMacrosProvider`/`weeklyCaloriesProvider`
      invalidations if unreferenced) and the start/resume-workout chip (its
      `activeWorkoutProvider` watch moves out — verify no other use in the file before dropping the
      import).
      `lib/l10n/app_en.arb` / `app_fr.arb` / `app_es.arb` — new `dashboardChipLogHeight`
      (en "Log height" / fr "Ajouter la taille" / es "Registrar altura") + `flutter gen-l10n`.
      Existing ARB keys (`dashboardChipLogMeal`, `dashboardChipStartWorkout`,
      `dashboardChipResumeWorkout`) stay in the ARBs (removal optional in T09 if trivial).
    - Out: chip styling beyond equal-width layout (no style change to ActionChip), removing ARB keys,
      the workout-related dashboard widgets (latest-workout card, active bar stay untouched).
  - Done when: exactly two equal-width chips render (log weight + log height); the height chip opens
    the height dialog and saves a height entry; no meal/workout chips; `flutter gen-l10n` exit 0;
    `dart analyze lib/` zero errors.
  - Verification notes (commands or checks):
    - `rg -n "dashboardChipLogMeal|dashboardChipStartWorkout|dashboardChipResumeWorkout" lib/src`
      — absent from code (keys may remain in ARBs).
    - `rg -n "_logHeight|Expanded|ActionChip" lib/src/dashboard/screens/dashboard.dart` — row layout.
    - Manual (deferred): dashboard shows 2 aligned chips; height chip saves to the body-metrics card.
  - Task ID: T03
  - Completed: 2026-08-10
  - Files changed: `lib/src/dashboard/screens/dashboard.dart` (`_QuickActions` — `Wrap` of 3 chips →
    equal-width `Row` of two `Expanded` `ActionChip`s: log weight + log height; `_logMeal` removed,
    `_logHeight` added mirroring `BodyMetricsCard._addHeight`); `lib/l10n/app_en.arb` /
    `app_fr.arb` / `app_es.arb` (new `dashboardChipLogHeight` each) + regenerated
    `lib/l10n/app_localizations*.dart`
  - Evidence: `flutter gen-l10n` exit 0; `dart analyze lib/` "No issues found!" exit 0; `flutter test`
    1/1 passed exit 0; `dart format --output=none --set-exit-if-changed lib test` exit 0 ("Formatted
    68 files (0 changed)"); grep — `dashboardChipLogMeal|dashboardChipStartWorkout|dashboardChipResumeWorkout`
    absent from `lib/src` (rg exit 1); `_logHeight`/`_logWeight`/two `Expanded` `ActionChip`s at
    dashboard.dart:286-344; `dashboardChipLogHeight` in all 3 ARBs (en:50, fr:40, es:40) + generated
    localizations
  - Notes: meal + workout chips removed (their provider invalidations were still used elsewhere —
    Welcome hub + hero/weekly cards — so no imports dropped; `activeWorkoutProvider` watch kept by
    `_LatestWorkoutCard`); height chip mirrors `BodyMetricsCard._addHeight` (suffix 'cm' →
    `upsert(day, heightCm: value)` + body-metrics invalidations + `commonSaved` SnackBar); old
    `dashboardChip*` keys left in ARBs per plan.

---

- [x] T04: `Planner free-text notes (schema v6)` (status:done)
  - Task ID: T04
  - Goal: Add an optional free-text notes field to planner tasks — schema, model, repository,
    dialog, tile, and copy-from-previous-day all carry it.
  - Boundaries (in/out of scope):
    - In: `lib/src/database/tables.dart` — `PlannerItems` gains `TextColumn? get notes =>
      text().nullable()()`; `lib/src/database/app_database.dart` — `schemaVersion` 5 → 6, `onUpgrade`
      step `if (from < 6)` adds the column; `flutter pub run build_runner build` (regenerate
      `app_database.g.dart`).
      `lib/src/models/planner_item.dart` — `PlannerItem` gains `String? notes` (+ constructor/copyWith).
      `lib/src/planner/repositories/planner_repository.dart` — `insert`/`update` write `notes`;
      row→model mapping reads it; `newPlannerItem(...)` gains `notes`; verify `copyFromPreviousDay`
      copies `notes` (carry it when re-creating items) and `restore` round-trips it.
      `lib/src/planner/screens/planner_item_dialog.dart` — `showPlannerItemDialog` returns
      `(String title, DateTime? dueDate, String? notes)`; add a multiline `TextField` (label
      `plannerNotesLabel`, e.g. `maxLines: 3`) initialized from `initialNotes`; `_submit` includes the
      trimmed notes (empty → null).
      `lib/src/planner/screens/planner_screen.dart` — `_addItem`/`_editItem` destructure the new
      record and pass notes to `newPlannerItem` / `copyWith`; `_PlannerItemTile` shows `item.notes`
      as a small subtitle line under the title/due-date (maxLines 2, ellipsis, `onSurfaceVariant`).
      `lib/l10n/app_en.arb` / `app_fr.arb` / `app_es.arb` — new `plannerNotesLabel` (en "Notes" /
      fr "Notes" / es "Notas") + `flutter gen-l10n`.
    - Out: task colors/priorities, checklist items inside tasks, anything beyond a free-text note.
  - Done when: a task can be created/edited with a note; the note shows in the tile; copy-from-
    previous-day carries notes; delete+undo restores notes; schema is v6 with a v5→v6 migration;
    `flutter pub run build_runner build` exit 0; `flutter gen-l10n` exit 0; `dart analyze lib/` zero
    errors.
  - Verification notes (commands or checks):
    - `flutter pub run build_runner build` — exit 0; `flutter gen-l10n` — exit 0.
    - Grep: `notes` present in tables.dart / model / repository / dialog / tile.
    - Manual (deferred): add task with note → note visible; edit; copy day; delete+undo.
  - Task ID: T04
  - Completed: 2026-08-10
  - Files changed: `lib/src/database/tables.dart` (`PlannerItems.notes` nullable text column);
    `lib/src/database/app_database.dart` (schemaVersion 5 → 6, v5→v6 `onUpgrade` step) + regenerated
    `lib/src/database/app_database.g.dart`; `lib/src/models/planner_item.dart` (`String? notes` +
    constructor/copyWith); `lib/src/planner/repositories/planner_repository.dart` (insert/update write
    `notes`, `_toDomain` reads it, `copyFromPreviousDay` carries it, `restore` round-trips via insert,
    `newPlannerItem` gains `notes`); `lib/src/planner/screens/planner_item_dialog.dart` (returns
    `(String title, DateTime? dueDate, String? notes)`; multiline notes `TextField` initialized from
    `initialNotes`; empty → null); `lib/src/planner/screens/planner_screen.dart` (`_addItem`/`_editItem`
    destructure + pass notes; `_PlannerItemTile` shows notes subtitle — maxLines 2, ellipsis,
    `onSurfaceVariant`); `lib/l10n/app_en.arb` / `app_fr.arb` / `app_es.arb` (new `plannerNotesLabel`)
    + regenerated `lib/l10n/app_localizations*.dart`
  - Evidence: `flutter pub run build_runner build` exit 0 (wrote 100 outputs); `flutter gen-l10n` exit
    0; `dart analyze lib/` "No issues found!" exit 0; `flutter test` 1/1 passed exit 0; `dart format
    --output=none --set-exit-if-changed lib test` exit 0 ("Formatted 68 files (0 changed)"); grep —
    `notes` wired through tables.dart:120 (`PlannerItems.notes`), planner_item.dart:10/20/34/43,
    planner_repository.dart:32/46/96/114/130/138, planner_item_dialog.dart:9/46/54/72/73/108,
    planner_screen.dart:116/131/146/149/313-340; `schemaVersion` 6 at app_database.dart:31;
    `plannerNotesLabel` in all 3 ARBs (en:253, fr:189, es:189) + generated localizations
  - Notes: schema now v6 with v5→v6 migration (`addColumn(plannerItems, plannerItems.notes)`); notes
    nullable, trimmed on submit (empty → null); copy-from-previous-day and delete+undo (restore =
    insert) both carry notes

---

- [x] T05: `Planner day swipe — PageView prev/next day` (status:done)
  - Task ID: T05
  - Goal: Make the planner day body swipe left/right to change the selected day, keeping the chevron
    header + Today button and the tile swipe-to-delete.
  - Boundaries (in/out of scope):
    - In: `lib/src/planner/screens/planner_screen.dart` — the `Expanded` day-body area becomes a
      horizontal `PageView` whose pages render the day list for consecutive days around `_selectedDay`
      (infinite: index = whole-day offset from a fixed anchor, e.g. days since `DateTime(2000)`;
      `onPageChanged` updates `_selectedDay`). `_previousDay`/`_nextDay`/`_goToday` additionally
      animate the `PageController` (`animateToPage`) so chevrons and swipe stay in sync. Each page
      keeps the existing `ReorderableListView` of `_PlannerItemTile` (drag-reorder + endToStart
      `Dismissible` delete unchanged — the tile's dismiss wins drags that start on a tile; swipes
      elsewhere change the day; document this in a comment). Header `_DayNavHeader` unchanged.
    - Out: day-scroll animations beyond PageView default, date picker, changing delete behavior.
  - Done when: swiping left/right on non-tile areas changes the day (list + header update);
    chevrons and Today still work and animate the same page; tile swipe-to-delete still works;
    `dart analyze lib/` zero errors.
  - Verification notes (commands or checks):
    - `rg -n "PageView|PageController|animateToPage" lib/src/planner/screens/planner_screen.dart`.
    - Manual (deferred): swipe on empty area changes day; swipe on a tile deletes; chevrons animate.
  - Task ID: T05
  - Completed: 2026-08-10
  - Files changed: `lib/src/planner/screens/planner_screen.dart` — `Expanded` day body → infinite
    `PageView.builder` (anchor `DateTime(2000)`; `PageController(initialPage: today-index)` field,
    disposed); new `_DayPage` `ConsumerWidget` watches `plannerItemsProvider(day)` per page
    (loading/error/empty/`ReorderableListView.builder` of `_PlannerItemTile` moved verbatim);
    `onPageChanged` sets `_selectedDay = _dayFromIndex(index)` (start-of-day);
    `_previousDay`/`_nextDay`/`_goToday` animate via `_pageController.animateToPage`
    (`FitFatTokens.motionNormal` 250ms + `Curves.easeOutCubic`); `_DayNavHeader` + FAB + copy +
    add/edit/toggle/delete/reorder unchanged (all operate on `_selectedDay`; invalidations target
    `plannerItemsProvider(_selectedDay)`); `../../ui/tokens.dart` import added
  - Evidence: `dart analyze lib/` "No issues found!" exit 0; `flutter test` 1/1 passed exit 0;
    `dart format --output=none --set-exit-if-changed lib test` exit 0 ("Formatted 68 files (0
    changed)"); grep — `PageView|PageController|animateToPage|onPageChanged` present
    (planner_screen.dart:27/33/72/75/111/113/273/279); `_DayNavHeader` at :99 (usage) + :331/:338
    (definition) — untouched
  - Notes: infinite PageView anchored to `DateTime(2000)`; per-page day watches via `_DayPage`;
    chevrons/Today animate the controller and `onPageChanged` keeps `_selectedDay` in sync;
    tile `Dismissible` wins drags that start on a tile (documented in `_DayPage` doc comment);
    index math done in UTC (`DateTime.utc` day arithmetic) so DST transitions can't skew the page
    index or today's initial page

---

- [x] T06: `Set value decimals — one decimal only when fractional` (status:done)
  - Task ID: T06
  - Goal: Stop rounding set weights/distances to integers — display one decimal only when the value
    is fractional, consistently across the workout detail, active-workout screen, and summary.
  - Boundaries (in/out of scope):
    - In: a shared formatting helper (e.g. `String formatDecimal(double v)` → whole when
      `v == v.roundToDouble()` else `toStringAsFixed(1)`) — place in `lib/src/ui/` (e.g.
      `lib/src/ui/format.dart` or alongside `date_formats.dart`; keep it minimal and exported for
      reuse). Apply it at every set-value display site:
      - `lib/src/exercise/screens/workout_detail.dart` — planned/actual weight strings: lines ~251
        (`set.weightKg?.toStringAsFixed(0)`), ~260 (`set.actualWeightKg?.toStringAsFixed(0)`), ~264
        (`set.actualWeightKg!.toStringAsFixed(0)`); distance prefill ~392 may stay as-is (input
        field) — only rendered strings change. Dialog prefill `toStringAsFixed(1)` (~384) is an input
        value — leave it.
      - `lib/src/exercise/screens/active_workout_screen.dart` — actuals display lines ~404-411
        (`toStringAsFixed(0)` for reps-weight / weight-only).
      - `lib/src/exercise/screens/workout_summary_screen.dart` — replace the local `_formatNumber`
        with the shared helper (same behavior — dedupe).
      - Reps stay integers (no decimal); duration/distance in the summary already uses
        whole-or-fractional — unify via the helper.
    - Out: input parsing/validation, ARB string changes, stored values, the summary metric
      computation logic.
  - Done when: weight/distance displays show "12 kg" and "12.5 kg" (never "13" for 12.5) in detail,
    active, and summary; no remaining `toStringAsFixed(0)` for set weight/distance display;
    `dart analyze lib/` zero errors.
  - Verification notes (commands or checks):
    - `rg -n "toStringAsFixed\(0\)" lib/src/exercise/screens/` — only non-weight/distance cases remain
      (none expected for weight/distance display).
    - `rg -n "formatDecimal|_formatNumber" lib/src/exercise/screens/ lib/src/ui/` — shared helper used.
    - Manual (deferred): log 12.5 kg actual → shows "12.5 kg".
  - Task ID: T06
  - Completed: 2026-08-10
  - Files changed: `lib/src/ui/format.dart` (new — shared `String formatDecimal(double value)`:
    whole when `value == value.roundToDouble()` else one decimal);
    `lib/src/exercise/screens/workout_detail.dart` (planned + actual weight display strings →
    `formatDecimal`, incl. the weight-only actual); `lib/src/exercise/screens/active_workout_screen.dart`
    (planned + actual weight display strings → `formatDecimal`, incl. the weight-only actual);
    `lib/src/exercise/screens/workout_summary_screen.dart` (local `_formatNumber` removed — total
    distance / volume / max weight now use the shared `formatDecimal`)
  - Evidence: `dart analyze lib/` "No issues found!" exit 0; `flutter test` 1/1 passed exit 0;
    `dart format --output=none --set-exit-if-changed lib test` exit 0 ("Formatted 69 files (0
    changed)"); grep — helper at `lib/src/ui/format.dart:4`; `formatDecimal` used at
    workout_detail.dart:252/263/266, active_workout_screen.dart:391/409/412,
    workout_summary_screen.dart:197/204/210; `_formatNumber` absent from lib; remaining
    `toStringAsFixed(0)` hits are input prefills only — workout_detail.dart:393 +
    active_workout_screen.dart:558 (distance dialog prefill) and workout_form.dart:273 (form
    `initialValue`), none is a set weight/distance display
  - Notes: one decimal only when fractional ("12 kg" / "12.5 kg", never "13" for 12.5); reps remain
    integers (no reps formatting changed); summary deduped onto the shared helper; dialog prefills
    (weight `toStringAsFixed(1)`, distance `toStringAsFixed(0)`) left as input values; the
    active-screen **planned** weight display was also switched to `formatDecimal` — same rendered
    string as workout_detail's planned weight, required by the "no remaining `toStringAsFixed(0)` for
    set weight/distance display" acceptance criterion

---

- [x] T07: `Active-workout back button — pop or /exercise` (status:done)
  - Task ID: T07
  - Goal: Add a leading back affordance to `ActiveWorkoutScreen` that pops when a back stack exists,
    else returns to the exercise tab.
  - Boundaries (in/out of scope):
    - In: `lib/src/exercise/screens/active_workout_screen.dart` — all `AppBar` variants (not-found,
      loading, error, data) gain a leading back `IconButton` (tooltip via
      `MaterialLocalizations.of(context).backButtonTooltip` — no new ARB key) that does:
      `if (Navigator.of(context).canPop()) Navigator.of(context).pop(); else context.go('/exercise');`
      Add a small shared helper or inline per variant (prefer inline consistency with the summary
      screen's `_statusScaffold` back pattern from T07 of active-workout-flow).
    - Out: changes to the Complete flow, the notification tap, or the summary screen.
  - Done when: every `ActiveWorkoutScreen` state has a visible leading back button; back pops when
    possible else lands on `/exercise`; `dart analyze lib/` zero errors.
  - Verification notes (commands or checks):
    - `rg -n "canPop|backButtonTooltip|Icons.arrow_back" lib/src/exercise/screens/active_workout_screen.dart`.
    - Manual (deferred): from active workout (opened via list/dashboard/bar) → back returns to the app.
  - Task ID: T07
  - Completed: 2026-08-10
  - Files changed: `lib/src/exercise/screens/active_workout_screen.dart` — one shared private helper
    `_activeWorkoutBackButton(BuildContext context)` (`IconButton` with `Icons.arrow_back`, tooltip
    `MaterialLocalizations.of(context).backButtonTooltip`) referenced as `leading:` on all 5 AppBar
    variants (not-found ×2 — null active workout + null detail — loading, error, data; the data
    AppBar keeps its Complete action)
  - Evidence: `dart analyze lib/` "No issues found!" exit 0; `flutter test` 1/1 passed exit 0;
    `dart format --output=none --set-exit-if-changed lib test` exit 0 ("Formatted 69 files (0
    changed)"); grep — `canPop`/`backButtonTooltip`/`Icons.arrow_back` at
    active_workout_screen.dart:115/116/119; `leading: _activeWorkoutBackButton` ×5 == `appBar:
    AppBar` ×5 — every AppBar variant covered
  - Notes: leading back on all AppBar variants — pops when canPop else `context.go('/exercise')`;
    pattern mirrored from WorkoutSummaryScreen (one shared helper instead of 5 inline copies, per
    the task's "small shared helper or inline per variant")

---

- [x] T08: `Set completion timestamp — completed_at (schema v7)` (status:done)
  - Task ID: T08
  - Goal: Record the time a set is completed (`exercise_sets.completed_at`) when its actuals are
    saved, and show it as HH:mm on the set row in the active-workout screen.
  - Boundaries (in/out of scope):
    - In: `lib/src/database/tables.dart` — `ExerciseSets` gains `IntColumn? get completedAt =>
      integer().nullable()()` (epoch millis); `lib/src/database/app_database.dart` — `schemaVersion`
      6 → 7, `onUpgrade` step `if (from < 7)` adds the column; `flutter pub run build_runner build`.
      `lib/src/models/exercise_set.dart` — `ExerciseSet` gains `DateTime? completedAt`
      (+ constructor param).
      `lib/src/exercise/repositories/workout_repository.dart` — `updateSetActuals` stamps
      `completedAt: DateTime.now()` whenever actuals are saved (any actual value non-null; overwritten
      on re-edit — acceptable); `insert` (planned sets) leaves it null; `restore` and
      `_getExerciseBlocks` round-trip it.
      `lib/src/exercise/screens/active_workout_screen.dart` — set rows show the completion time
      `DateFormats.formatTime(context, TimeOfDay.fromDateTime(set.completedAt!))` (HH:mm, locale-
      aware) when `set.completedAt != null` (e.g. small label under the actual value / in the set
      row). No new ARB keys required (time formats via `DateFormats`).
    - Out: rest-between-sets calculation, showing time in the pending detail (sets there are never
      completed), summary changes, editing timestamps.
  - Done when: saving actuals writes `completed_at`; the active screen shows HH:mm on completed set
    rows; delete+undo (snapshot restore) preserves it; schema is v7 with a v6→v7 migration;
    `flutter pub run build_runner build` exit 0; `dart analyze lib/` zero errors.
  - Verification notes (commands or checks):
    - `flutter pub run build_runner build` — exit 0.
    - Grep: `completedAt` in tables.dart / model / repository / active_workout_screen.dart;
      `completedAt: DateTime.now()` inside `updateSetActuals`.
    - Manual (deferred): complete a set → time appears next to it; undo-delete preserves it.
  - Task ID: T08
  - Completed: 2026-08-10
  - Files changed: `lib/src/database/tables.dart` (`ExerciseSets.completedAt` nullable int column,
    epoch millis); `lib/src/database/app_database.dart` (schemaVersion 6 → 7, v6→v7 `onUpgrade`
    step `addColumn(exerciseSets, exerciseSets.completedAt)`) + regenerated
    `lib/src/database/app_database.g.dart`; `lib/src/models/exercise_set.dart` (`DateTime? completedAt`
    + constructor param, default null); `lib/src/exercise/repositories/workout_repository.dart`
    (`updateSetActuals` gates on any actual non-null and stamps
    `completedAt: Value(DateTime.now().millisecondsSinceEpoch)` — overwritten on re-edit;
    `restore` round-trips `completedAt: Value(s.completedAt)`; `_getExerciseBlocks` maps
    `completedAt` → `DateTime.fromMillisecondsSinceEpoch` when non-null);
    `lib/src/exercise/screens/active_workout_screen.dart` (`_SetRow` actual column → `Column` with a
    small `bodySmall`/`onSurfaceVariant` HH:mm label via
    `DateFormats.formatTime(context, TimeOfDay.fromDateTime(set.completedAt!))` when
    `set.completedAt != null` — no new ARB keys)
  - Evidence: `flutter pub run build_runner build` exit 0 ("Built with build_runner/aot in 5s; wrote
    33 outputs"); `dart analyze lib/` "No issues found!" exit 0; `flutter test` 1/1 passed exit 0;
    `dart format --output=none --set-exit-if-changed lib test` exit 0 ("Formatted 69 files (0
    changed)"); grep — `completedAt` wired: tables.dart:101 (`ExerciseSets.completedAt`),
    exercise_set.dart:21/36, workout_repository.dart:229 (restore round-trip) / 296 (stamp inside
    `updateSetActuals`) / 362-363 (row→model mapping), active_workout_screen.dart:494/498 (HH:mm
    label); `schemaVersion` 7 at app_database.dart:31. Note: the required grep literal
    `completedAt: DateTime.now()` cannot appear verbatim — drift companion writes require
    `Value(...)` + `.millisecondsSinceEpoch` — the stamp is
    `completedAt: Value(DateTime.now().millisecondsSinceEpoch)` at workout_repository.dart:296,
    inside `updateSetActuals` (same shape as the pre-existing `complete()` at :256)
  - Notes: schema now v7 with v6→v7 migration (`addColumn(exerciseSets, exerciseSets.completedAt)`);
    `updateSetActuals` stamps `completedAt` whenever any actual value is non-null (early-returns
    otherwise — also avoids writing an all-absent companion), overwritten on re-edit (last save
    wins); `insert` of planned sets leaves `completed_at` null; snapshot delete+undo round-trips the
    column (`restore` builds the companion manually, `completedAt: Value(s.completedAt)` added);
    HH:mm shown only on completed set rows of the active-workout screen via `DateFormats.formatTime`
    (locale-aware, no ARB keys); pending detail screen (workout_detail.dart) and summary untouched
    per scope — sets there may carry `completed_at` data but no time is rendered

---

- [x] T09: `Final validation, cleanup, and context sync` (status:done)
  - Task ID: T09
  - Completed: 2026-08-10
  - Files changed: `lib/l10n/app_en.arb` / `app_fr.arb` / `app_es.arb` (optional cleanup — removed
    the now-unused `dashboardChipLogMeal` / `dashboardChipStartWorkout` / `dashboardChipResumeWorkout`
    keys) + regenerated `lib/l10n/app_localizations*.dart`;
    `context/dashboard/dashboard.md` (ARB-key status patched after cleanup);
    `context/context-map.md` (plan row → completed)
  - Evidence: full suite all exit 0 — `flutter pub run build_runner build` ("Built with
    build_runner/aot in 5s; wrote 32 outputs"), `flutter gen-l10n` (×2 — pre- and post-cleanup),
    `dart analyze lib/` "No issues found!" (×2), `flutter test` 1/1 passed, `dart format
    --output=none --set-exit-if-changed lib test` ("Formatted 69 files (0 changed)"); grep — the
    three removed chip keys absent from `lib/` + `test/` post-cleanup (rg exit 1); context readback
    vs code clean except 2 patched spots (dashboard.md, context-map.md); full Validation Report
    appended below
  - Notes: plan complete — all 8 change requests implemented and validated. ARB cleanup performed
    (zero app/test usages remained → keys removed from all 3 ARBs, gen-l10n + analyze re-run clean).
    Manual UI verification deferred to the user (headless environment) — see Validation Report.
  - Goal: Full verification suite, optional trivial cleanup, sync `context/`, and run
    `sce-validation`.
  - Boundaries (in/out of scope):
    - In: verification commands; optional trivial ARB cleanup (removing now-unused
      `dashboardChipLogMeal` / `dashboardChipStartWorkout` / `dashboardChipResumeWorkout` keys ONLY
      if confirmed unused app-wide and removal is trivial — otherwise leave); context updates —
      `context/database/schema.md` (v7: `planner_items.notes` v6, `exercise_sets.completed_at` v7),
      `context/settings/settings.md` (body-weight goal), `context/dashboard/dashboard.md`
      (settings button, quick actions = weight + height, goal badge), `context/planner/planner.md`
      (notes field, day swipe), `context/exercise/workout-crud.md` (set decimals, active-screen back
      button, `completed_at`), `context/glossary.md` (`BodyWeightGoal`, `completed_at`, notes),
      `context/overview.md` and `context/architecture.md` if any root-level behavior changed,
      `context/context-map.md` (this plan); `sce-validation` report appended to the plan.
    - Out: new features, refactors beyond this plan, dependency changes, git commit.
  - Done when: `flutter pub run build_runner build` exit 0; `flutter gen-l10n` exit 0; `dart analyze
    lib/` zero errors; `flutter test` passes; format check exit 0; context files read back accurate
    and ≤ 250 lines; validation report written.
  - Verification notes (commands or checks):
    - Full suite commands all exit 0.
    - Re-read synced context files against code; confirm schema.md documents v7 with both new
      columns and both migrations.

---

## Open Questions

- None — all decisions resolved with the user (2026-08-09):
  - Quick actions: equal-width row; **remove** start/workout chip and meal chip; keep **log weight +
    log height** (height chip is new).
  - BW goal: Settings selector + dashboard `BodyMetricsCard` badge.
  - Decimals: one decimal **only when fractional**.
  - Active-workout back: pop if possible, else `/exercise`.
  - Set time: `completed_at` stamped when actuals are saved, shown HH:mm in the active screen;
    rest-between-sets math out of scope (raw data recorded for future use).
  - Planner swipe: `PageView`; tiles keep swipe-to-delete; chevrons + Today stay.
- Assumption: the dashboard "settings button" means adding one (the dashboard AppBar has no actions
  today) — there is nothing to "move".

## Next Command

```
PLAN COMPLETE — all 9 tasks done (2026-08-10). Validation Report below. Deferred manual UI checks
listed under "Residual risks" are owed by the user; no further tasks remain in this plan.
```

## Validation Report

### Commands run

- `flutter pub run build_runner build` -> exit 0 ("Built with build_runner/aot in 5s; wrote 32
  outputs") — schema v7 codegen with both migrations present.
- `flutter gen-l10n` -> exit 0 (l10n.yaml note only; no errors) — run twice (pre- and post-ARB
  cleanup).
- `dart analyze lib/` -> exit 0 ("No issues found!") — run twice (pre- and post-ARB cleanup).
- `flutter test` -> exit 0 (1/1 passed, "All tests passed!").
- `dart format --output=none --set-exit-if-changed lib test` -> exit 0 ("Formatted 69 files (0
  changed)").

### ARB cleanup (optional, T09)

- **Decision: done.** `rg -n "dashboardChipLogMeal|dashboardChipStartWorkout|dashboardChipResumeWorkout"
  lib test` initially matched only the ARB source files + generated `app_localizations*.dart`;
  `rg ... lib/src test` returned **zero matches** (exit 1). The three keys had no `@` metadata
  annotations, so removal was trivial: deleted them from `lib/l10n/app_en.arb`, `app_fr.arb`,
  `app_es.arb`, re-ran `flutter gen-l10n` (exit 0) + `dart analyze lib/` (exit 0, "No issues
  found!"), and confirmed the keys are absent from the whole `lib/` + `test/` tree (rg exit 1).
  If any usage had remained the keys would have been left untouched — not applicable.

### Scaffolding removal

- `context/tmp/` does not exist; a repo-wide scan for tmp/scratch dirs and backup artifacts
  (`.tmp`, `.bak`, `.orig`, `*~`, `.swp`) found none. No debug code was introduced by T01–T08
  (all checks were clean). Nothing to remove.

### Context verification (readback against code)

- **Verified accurate (no patch needed):** `context/database/schema.md` (version 7;
  `planner_items.notes` v6 + `exercise_sets.completed_at` v7 columns; v5→v6 and v6→v7 migrations —
  confirmed at `app_database.dart:31` (schemaVersion 7), `:62-69` (both `if (from < N)` steps),
  `tables.dart:123` (planner notes), `tables.dart:101` (exercise_sets completed_at));
  `context/settings/settings.md` (BodyWeightGoal enum `body_weight_goal.dart:2`,
  `settings_body_weight_goal` key `settings.dart:53`, `setBodyWeightGoal` `:92`);
  `context/planner/planner.md` (notes dialog/tile/copy + PageView day swipe — `planner_screen.dart:111`,
  `planner_item_dialog.dart:54/72`); `context/exercise/workout-crud.md` (formatDecimal decimals,
  5× back button AppBars, `completed_at` + HH:mm label — `active_workout_screen.dart:66/77/84/93/154/494-498`);
  `context/glossary.md` (BodyWeightGoal, formatDecimal, completed_at, planner notes, schema v7);
  `context/overview.md` (settings incl. body-weight goal; dashboard quick-action chips = weight +
  height); `context/architecture.md` (settings incl. body-weight goal).
- **Patched (2 files, minimal drift):** `context/dashboard/dashboard.md` (line 28 — the removed-chip
  ARB keys no longer "stay in the ARBs"; updated to record the T09 removal);
  `context/context-map.md` (plan row for `app-polish-batch` → "(completed)").
- All read-back context files ≤ 250 lines.

### Failed checks and follow-ups

- none.

### Success-criteria verification

- [x] **Dashboard AppBar shows a settings icon top-right; tapping it opens the Settings tab** —
  `Icons.settings` at `dashboard.dart:46`, `context.go('/settings')` at `:48` (T01 evidence; suite
  green). Manual tap deferred.
- [x] **Settings body-weight goal selector (lose / maintenance / gain); persists across restarts;
  reflected on `BodyMetricsCard`** — `BodyWeightGoal` enum `body_weight_goal.dart:2`;
  `settings_body_weight_goal` prefs key `settings.dart:53`; `setBodyWeightGoal` persists/removes it
  (`:92-101`); goal badge on card `body_metrics_card.dart:89-94` (T02 evidence). Manual restart
  deferred.
- [x] **Quick actions render as an equal-width row with exactly log weight + log height; neither
  meal nor workout chip present** — two `Expanded` `ActionChip`s at `dashboard.dart:332-344`,
  `_logWeight` `:286`, `_logHeight` `:306`; `dashboardChipLogMeal`/`StartWorkout`/`ResumeWorkout`
  absent from `lib/src` + `test` (rg exit 1; ARB keys removed in T09) (T03 evidence).
- [x] **Planner tasks hold an optional free-text note: entered/edited in the dialog, displayed in
  the tile, carried by copy-from-previous-day, round-tripped through insert/update/delete+undo** —
  dialog returns `(title, dueDate, notes)` `planner_item_dialog.dart:9`, TextField `:54`, trimmed
  `:72`; screen destructures + passes notes `planner_screen.dart:144/159/174/177`; tile notes
  subtitle `:399-426`; repository insert/update/restore/mapping carry notes
  `planner_repository.dart:32/46/96/114`; `copyFromPreviousDay` copies notes `:67`+ (T04 evidence).
  Manual UI checks deferred.
- [x] **Planner day body swipes left/right to change the day (chevrons + Today still work; swiping
  on a tile still deletes)** — infinite `PageView.builder` `planner_screen.dart:111`,
  `PageController` `:27/:33`, `animateToPage` `:75`, `onPageChanged` `:113` (T05 evidence). Manual
  swipe deferred.
- [x] **Set weights/distances display one decimal only when fractional in detail, active, and
  summary** — shared `formatDecimal` `ui/format.dart:4`; used at `workout_detail.dart:252/263/266`,
  `active_workout_screen.dart:422/440/443`, `workout_summary_screen.dart:197/204/210` (T06 evidence).
- [x] **`ActiveWorkoutScreen` has a leading back button: pops when possible, else returns to
  `/exercise`** — `_activeWorkoutBackButton` `active_workout_screen.dart:113` with `canPop()` `:119`;
  `leading:` on all 5 AppBar variants (`:66/:77/:84/:93/:154`) (T07 evidence). Manual back-stack
  check deferred.
- [x] **Recording a set's actuals stamps `completed_at`; active screen shows HH:mm on that set row;
  the column round-trips through restore** — `ExerciseSets.completedAt` `tables.dart:101`; schema v7
  + v6→v7 migration `app_database.dart:31/66-69`; stamp `completedAt:
  Value(DateTime.now().millisecondsSinceEpoch)` inside `updateSetActuals`
  `workout_repository.dart:296`; snapshot restore round-trips `:229`; HH:mm label via
  `DateFormats.formatTime` when `set.completedAt != null` `active_workout_screen.dart:494-498`
  (T08 evidence). Manual set-completion check deferred.
- [x] **`flutter pub run build_runner build` exit 0 (both schema tasks); `flutter gen-l10n` exit 0;
  `dart analyze lib/` zero errors; `flutter test` passes; all new strings localized en/fr/es;
  `context/` synced** — all suite commands exit 0 (see Commands run); new keys
  (`dashboardChipLogHeight` en:47/fr:37/es:37, `settingsBodyWeightGoal`/`settingsGoal*`/
  `bodyMetricsGoal`, `plannerNotesLabel`) present in all 3 ARBs + generated localizations; context
  readback clean with 2 minimal patches (see above).

### Residual risks

- Manual UI verification deferred (headless environment). Still owed by the user:
  - Tap the dashboard gear icon → Settings tab opens.
  - Pick a body-weight goal → badge appears on the dashboard `BodyMetricsCard`; app restart → the
    goal is still selected.
  - Dashboard shows exactly 2 aligned chips (log weight + log height); the height chip saves a
    height entry visible on the body-metrics card.
  - Planner: create a task with a note → note visible in the tile; edit the note; copy from
    previous day carries the note; delete + Undo restores the note.
  - Planner: swipe on an empty area changes the day; swipe starting on a task tile deletes the
    tile; chevrons + Today animate to the matching page.
  - Log a 12.5 kg actual → shows "12.5 kg" (never "13") in detail, active, and summary.
  - Active-workout back button: pops when a back stack exists, else lands on `/exercise`.
  - Complete a set → HH:mm completion time appears on its row; delete + Undo preserves it.
