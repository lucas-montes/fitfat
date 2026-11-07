# Plan: App-wide UI/UX improvements (7 areas)

## Change Summary

A coordinated UI/UX overhaul of FitFat across seven areas, executed **after** the active
`app-improvements` plan (T05–T11) lands. Decisions below were resolved with the user over two
discussion rounds; design direction is **polished Material 3, teal seed kept**.

1. **Design system & theme pass**: expand `theme.dart` into a real token system — tuned light AND
   dark palettes (teal-tinted dark surfaces), component themes (Card, FilledButton, OutlinedButton,
   TextButton, InputDecoration, NavigationBar, AppBar, Dialog, SnackBar, ExpansionTile, ListTile,
   FloatingActionButton), a `FitFatColors` `ThemeExtension` for status colors (success/warning),
   spacing/radius/motion tokens, and shared widgets in a new `lib/src/ui/` (StatusBadge, EmptyState,
   MetricCard). Sweep all hardcoded `Colors.green/orange/grey` and inline styles out of screens —
   this is also the dark-mode correctness pass for the `app-improvements` T07 theme.
2. **Dashboard redesign** ("today at a glance"): greeting + locale date header, hero calories card
   with read-only P/C/F composition bars and a 7-day calories trend (`fl_chart`), quick-action chips
   (log meal / start-or-resume workout / log weight), latest workout card with theme-aware status
   badge (promotes to "Continue workout" when active), Today's plan strip (pending planner tasks),
   body-metrics card restyled, welcome hub as the no-data state, max-width wrapper for wide screens.
3. **Empty states & first-run onboarding**: reusable `EmptyState` widget (tonal-circle icon + title +
   description + CTA) on every empty list; dashboard shows a quick-start hub ("Welcome to FitFat" with
   three actions) when there is no data at all. No dedicated welcome flow.
4. **Interactions & feedback**: haptics (checkbox toggles, deletes, set completion), save/start/complete
   SnackBars, M3-default page transitions + targeted micro-motion (`AnimatedSwitcher` on the hero
   number, animated status pills, growing chart bars), fix the meal-tile edit/expand affordance quirk.
5. **Delete semantics**: ingredients are **soft-archived** (`is_archived` flag, schema **v4**) because
   they will be shared across users in the future — hidden from list + meal-form picker, names still
   render in past meals (denormalized), Undo = un-archive, no restore surface beyond the immediate
   Undo. Meals / workouts / planner items are **hard-deleted with SnackBar + Undo** (re-insert from
   in-memory model; workouts snapshot exercises + sets before deleting). Exercises (also FK-referenced
   by `workout_exercises`) are **blocked from deletion with a usage-count warning dialog** — flagged
   assumption, user can override to archive.
6. **Locale-aware dates & formatting**: single `DateFormats` helper (via `MaterialLocalizations`, no
   new deps) replacing the hardcoded `dd.MM.yyyy` strings in dashboard, meal list, workout list, and
   workout detail — an i18n correctness fix for fr/es.
7. **Global active-workout floating bar** (replaces a nav badge): slim full-width strip above the
   NavigationBar on every tab when a workout is active — workout name, live elapsed time (1s ticker),
   tap to resume. Mirrors the `app-improvements` T10 notification content.
8. **Accessibility & platform polish**: dynamic-type pass (set-table flexible columns), semantics /
   tooltip sweep, status-color contrast verified in both themes, edge-to-edge on Android.

No new dependencies. All new user-facing strings localized en/fr/es.

## Success Criteria

- `lib/src/ui/` exists with tokens, `FitFatColors` theme extension, and shared widgets; `theme.dart`
  defines tuned light + dark themes with component themes; **no** hardcoded `Colors.green/orange/grey`
  remain in screens (grep-clean); dark mode (from `app-improvements` T07) renders correctly with
  status colors that meet contrast in both brightnesses.
- All dates/times render per locale via a single `DateFormats` helper; no manual `dd.MM.yyyy` /
  `padLeft` formatting remains in screens.
- Every empty list shows the `EmptyState` widget with a working CTA; the dashboard shows the welcome
  hub when there is no meal and no workout data.
- Haptics fire on planner toggles, deletes, and set saves; save/start/complete show SnackBars; meal
  tile has an explicit expand affordance and a reachable edit action.
- Deleting an ingredient archives it (no FK error), hides it from list and meal-form picker, keeps
  past meal names intact, and Undo un-archives it. Schema is v4 (`ingredients.is_archived`).
- Deleting a meal / workout / planner item shows "Deleted" + Undo; Undo restores the full aggregate
  (meal + ingredients; workout + exercises + sets with original ids; planner row). Deleting a
  referenced exercise is blocked with a usage-count dialog and never throws.
- Dashboard shows: greeting + locale date, hero calories card with P/C/F composition bars and a
  7-day calories bar chart, quick-action chips (log meal / adaptive start-or-resume workout / log
  weight), latest workout card with status badge, Today's plan strip, and the body-metrics card.
  "Start workout" becomes "Resume workout" (pushes the active workout) when one is active.
- The floating active-workout bar appears on every tab while a workout is active (name + elapsed
  mm:ss), opens the workout detail on tap, and disappears when none is active / on completion.
- Set table in workout detail does not clip at large text scales; IconButtons have tooltips;
  status colors contrast ≥ 4.5:1 in light and dark; edge-to-edge rendering on Android.
- `flutter pub run build_runner build` — exit 0; `flutter gen-l10n` — exit 0;
  `dart analyze lib/` — zero errors; `flutter test` — passes; `git status` shows only intended files.
- All new user-facing strings localized in en/fr/es ARB files.
- `context/` synced: schema v4, design system doc, per-area docs (dashboard, diet, exercise, planner),
  context-map, overview, architecture, glossary.

## Constraints & Non-Goals

- **No new dependencies** (intl, fl_chart, shared_preferences already present).
- Schema change is **one** bump to **v4** adding only `ingredients.is_archived` (default false).
  No other table changes; no soft-delete for meals/workouts/planner.
- **No calorie/macro goals or targets** (user decision) — the P/C/F bars show read-only composition
  (each macro's share of total calories), not progress toward a target.
- **No dedicated onboarding flow** — onboarding is in-place empty-state CTAs + the dashboard hub.
- **No custom page transitions** — M3 defaults; motion budget goes to targeted micro-animation.
- **No nav badges** — the global floating bar replaces the active-workout dot idea.
- **No restore surface for archived ingredients** beyond the immediate Undo SnackBar (user decision).
- Undo windows are ephemeral: delete is committed immediately; a restart during the window loses
  Undo (accepted, standard behavior — no tombstones).
- Exercises are **blocked** when referenced (assumption — see Open Questions); they are not archived.
- Execute only **after** `app-improvements` T11 completes (T06 body metrics, T07 themeMode/dark theme,
  T10 rest timer/notification are prerequisites for T01/T09).
- Keep the existing test suite green; no new test suite beyond repo posture; manual runtime checks
  deferred to T11 (headless env).

## Assumptions (resolved with user + inferred)

- Dark palette tuning lives in this plan (user decision) on top of `app-improvements` T07's themeMode
  switching; T01 replaces T07's standard dark `ThemeData` with the tuned one and registers
  `FitFatColors` in both themes.
- Status colors are the only hand-picked colors; everything else stays M3-derived from teal
  (user decision: no warm tertiary accent).
- `activeWorkoutProvider` (new, in `lib/src/exercise/providers/workouts.dart`) is created in T08 and
  consumed by the dashboard resume chip in T09 (ordering dependency).
- Ingredient archive is implemented as `is_archived INTEGER NOT NULL DEFAULT 0`; `getAll()` and the
  meal-form picker filter it at the repository level so all consumers are covered
  (verified: `MealIngredient.ingredientName` is denormalized, so archived names still render).
- Drift `NativeDatabase` enforces foreign keys (default); if verification shows FKs are OFF, exercise
  deletion currently orphans references — the block-with-usage-warning still applies for safety.
- Greeting header uses 3 time-based strings (morning/afternoon/evening) × 3 languages; if l10n proves
  noisy, fallback is a date-only header (noted in T09).
- Macro composition bars, 7-day trend, and Today's plan strip reuse existing data — no new tables.

## Task Stack

---

- [x] T01: `Design tokens, tuned light+dark themes, shared UI widgets, color sweep` (status:done)
  - Task ID: T01
  - Completed: 2026-08-06
  - Files changed: `lib/src/ui/tokens.dart` (new — spacing/radii/motion/kContentMaxWidth), `lib/src/ui/theme_extensions.dart` (new — `FitFatColors` light+dark), `lib/src/ui/widgets/status_badge.dart` (new), `lib/src/ui/widgets/empty_state.dart` (new), `lib/src/ui/widgets/metric_card.dart` (new), `lib/src/app/theme.dart` (tuned light+dark + component themes + extension registration), `lib/src/exercise/screens/workout_list.dart` (status pill → `StatusBadge`), `lib/src/exercise/screens/workout_detail.dart` (status pill → `StatusBadge`; completed-set row + edit icon colors)
  - Evidence: `dart analyze lib/` "No issues found!"; `flutter test` 1/1 passed; `dart format --output=none --set-exit-if-changed lib/src/ui lib/src/app/theme.dart lib/src/exercise/screens/workout_list.dart lib/src/exercise/screens/workout_detail.dart` exit 0 (8 files, 0 changed); `rg "Colors\.(green|orange|grey)" lib/src` → zero hits (grep-clean)
  - Notes: Palette — success `0xFF2E7D32` light / `0xFF81C784` dark; warning `0xFF8A4F00` light / `0xFFFFB74D` dark; "Pending" uses M3 `colorScheme.outline` (no extra hand-picked color). Light palette ≥ 4.5:1 on white (≈5.1 / 6.6); dark palette ≈8.4 / 9.8:1 on the tuned surfaces; `onSuccess`/`onWarning` defined for solid fills. Dark surfaces tuned teal-tinted family (`surface` 0xFF101415, cards `surfaceContainerLow` 0xFF181D1E, container/high/highest 0xFF1D2324/0xFF282F30/0xFF333B3C) layered on the T07 standard dark theme. Component themes registered: Card (flat, elevation 0, `surfaceContainerLow`), Filled/Outlined/TextButton shape, InputDecoration (filled + rounded), NavigationBar, AppBar (flat, no surface tint), Dialog, SnackBar (floating), ExpansionTile (borderless), ListTile, FAB. Set-row completed styling now `FitFatColors.success` (actuals) + `onSurfaceVariant` (struck-through planned, edit icon). `Colors.white` fl_chart tooltip style in `body_metrics_card.dart` left untouched (outside the green/orange/grey criterion). `EmptyState`/`MetricCard` created but unused in T01 (consumed in T03/T09). Manual (deferred): toggle dark mode, verify cards/pills/status render and contrast.
  - Goal: Establish the design system foundation: tokens, tuned light + dark themes with component
    themes, a `FitFatColors` theme extension, shared widgets, and a sweep replacing hardcoded status
    colors / inline styles across screens.
  - Boundaries (in/out of scope):
    - In: `lib/src/ui/tokens.dart` (new — spacing scale, radii, motion durations, `kContentMaxWidth`),
      `lib/src/ui/theme_extensions.dart` (new — `FitFatColors` with success/warning/on\* for light+dark),
      `lib/src/ui/widgets/status_badge.dart` (new — shared status pill with animated color flip),
      `lib/src/ui/widgets/empty_state.dart` (new — used by T03), `lib/src/ui/widgets/metric_card.dart`
      (new — shared stat card shell), `lib/src/app/theme.dart` (light + dark, component themes,
      registers the extension; `FitFatApp` already applies `themeMode`/`darkTheme` via T07),
      sweep `workout_list.dart` + `workout_detail.dart` status pills to `StatusBadge`, remove other
      hardcoded `Colors.*` / inline `textTheme` duplication in screens where a component theme now
      covers it.
    - Out: Empty-state copy (T03), dashboard layout (T09), any new ARB strings (status labels already
      exist; no new keys in T01), custom fonts, icon/branding assets.
  - Done when:
    - `theme.dart` exposes tuned `light` and `dark` (teal-tinted surfaces, cards = `surfaceContainerLow`,
      status colors via `FitFatColors` meeting ≥ 4.5:1 contrast in both brightnesses).
    - No `Colors.green` / `Colors.orange` / `Colors.grey` remain in `lib/src/` outside `lib/src/ui/`
      (grep-clean); workout list + detail use `StatusBadge`.
    - `dart analyze lib/` — zero errors; `flutter test` — passes.
  - Verification notes (commands or checks):
    - `grep -rn "Colors\.\(green\|orange\|grey\)" lib/src` → hits only under `lib/src/ui/`.
    - `dart analyze lib/` — "No issues found!"; `flutter test` — 1/1 passed.
    - Manual (deferred): toggle dark mode, verify cards/pills/status render and contrast.

---

- [x] T02: `Locale-aware date and time formatting` (status:done)
  - Task ID: T02
  - Completed: 2026-08-07
  - Files changed: `lib/src/ui/date_formats.dart` (new — `formatDate`/`formatShortDate`/`formatTime` on `MaterialLocalizations` + context-free `twoDigit`), `lib/src/dashboard/screens/dashboard.dart` (workout date), `lib/src/diet/screens/meal_list.dart` (`_DayGroup` date), `lib/src/exercise/screens/workout_list.dart` (`_WorkoutTile` date), `lib/src/exercise/screens/workout_detail.dart` (date + `startedAt` time), `lib/src/exercise/screens/workout_form.dart` (date label), `lib/src/diet/screens/meal_form.dart` (date + time label), `lib/src/notifications/rest_timer.dart` (`formatRestDuration` uses `DateFormats.twoDigit`)
  - Evidence: `rg "padLeft" lib/src` → only `lib/src/ui/date_formats.dart` (grep-clean); `dart analyze lib/` "No issues found!"; `flutter test` 1/1 passed; `dart format --output=none --set-exit-if-changed` exit 0 (8 files, 0 changed)
  - Notes: `DateFormats` maps `formatDate`→`formatMediumDate`, `formatShortDate`→`formatShortDate`, `formatTime`→`formatTimeOfDay(TimeOfDay)`; locale-aware via the registered `GlobalMaterialLocalizations` delegate, no `intl` init. Scope resolution (user-confirmed): swept `workout_form` + `meal_form` labels too (Goal + grep-clean authoritative over the "In" list) and moved the zero-pad into `DateFormats.twoDigit` so the literal `padLeft` grep is clean — `formatRestDuration` stays context-free because the background notification isolate has no `BuildContext` and `mm:ss` is locale-independent. `body_metrics_card.dart` already used `formatShortDate` — left as-is (already locale-aware, outside sweep). Behavioral change: dates now locale-aware (e.g. "Aug 6, 2026" en / "6 août 2026" fr) and times via `formatTimeOfDay` (e.g. "2:30 PM" en / "14:30" fr). Manual (deferred): switch to fr, verify French-style dates.
  - Goal: Centralize date/time formatting in one locale-aware helper and replace every hardcoded
    `dd.MM.yyyy` / manual `HH:mm` string in the app.
  - Boundaries (in/out of scope):
    - In: `lib/src/ui/date_formats.dart` (new — `formatDate`, `formatTime`, `formatShortDate` built on
      `MaterialLocalizations`/`GlobalMaterialLocalizations` helpers, mirroring the planner's proven
      `formatMediumDate` usage; no `intl` init needed), call sites: `dashboard.dart` (workout date),
      `meal_list.dart` (`_DayGroup` date), `workout_list.dart` (`_WorkoutTile` date),
      `workout_detail.dart` (date + `startedAt` time).
    - Out: Planner (already correct via `formatMediumDate`), number/unit formatting, `intl`
      `initializeDateFormatting` wiring (only if a helper proves insufficient — not expected).
  - Done when:
    - No manual `padLeft(2, '0')` date/time formatting remains in `lib/src/` outside `date_formats.dart`
      (grep-clean); dates render per active locale (en/fr/es).
    - `dart analyze lib/` — zero errors.
  - Verification notes (commands or checks):
    - `grep -rn "padLeft(2, '0')" lib/src` → only `lib/src/ui/date_formats.dart` (or zero).
    - `dart analyze lib/` — "No issues found!".
    - Manual (deferred): switch to fr, verify dates render French-style.

---

- [x] T03: `Empty states + dashboard quick-start hub` (status:done)
  - Task ID: T03
  - Completed: 2026-08-07
  - Files changed: `lib/l10n/app_en.arb`, `lib/l10n/app_fr.arb`, `lib/l10n/app_es.arb` (new
    `dashboardWelcome*`, `emptyExercises*`, `emptyWorkouts*`, `emptyWorkoutDetail*`,
    `emptyIngredients*`, `emptyMeals*`, `emptyPlanner*` keys; removed dead `exerciseListEmpty`,
    `workoutListEmpty`, `workoutDetailNoExercises`, `ingredientListEmpty`, `mealListEmpty`,
    `plannerEmpty`), `lib/l10n/app_localizations*.dart` (regenerated), `lib/src/diet/screens/ingredient_list.dart`
    (EmptyState + CTA), `lib/src/diet/screens/meal_list.dart` (EmptyState + CTA),
    `lib/src/exercise/screens/exercise_list.dart` (EmptyState + CTA),
    `lib/src/exercise/screens/workout_list.dart` (EmptyState + CTA),
    `lib/src/planner/screens/planner_screen.dart` (EmptyState + CTA),
    `lib/src/exercise/screens/workout_detail.dart` (EmptyState, no CTA),
    `lib/src/dashboard/screens/dashboard.dart` (`_WelcomeHub` no-data state, watches
    `mealListProvider` + `workoutListProvider`)
  - Evidence: `flutter gen-l10n` exit 0; `dart analyze lib/` "No issues found!"; `flutter test` 1/1
    passed; `dart format --output=none --set-exit-if-changed` exit 0 (63 files, 0 changed); `rg` dead-key
    grep clean (`exerciseListEmpty|workoutListEmpty|workoutDetailNoExercises|ingredientListEmpty|mealListEmpty|plannerEmpty`
    → zero hits in `lib/`)
  - Notes: Scope decisions (user-confirmed): workout-detail no-exercises → EmptyState with NO CTA (no
    edit-workout flow exists); body-metrics inline empty texts stay inline (NOT EmptyState — overrides
    the "body-metrics empty state" line in the In list); dashboard hub condition = no meals AND no
    workouts via `mealListProvider` + `workoutListProvider` (`.value?.isEmpty` — riverpod 3.2.1 has no
    `valueOrNull` getter); hub replaces the two data cards (`_WelcomeHub`), `BodyMetricsCard` stays
    below; hub actions push `IngredientFormScreen` / `MealFormScreen` / `WorkoutFormScreen` and
    invalidate `mealListProvider`+`todayCaloriesProvider` (meal save) / `workoutListProvider`+`latestWorkoutProvider`
    (workout save) so the hub disappears; ingredient save invalidates nothing (hub unaffected). Icons:
    ingredient `soup_kitchen_outlined`, meal `restaurant_outlined`, exercise `sports_gymnastics`,
    workout `fitness_center`, planner `event_note`, workout-detail `fitness_center`, hub `rocket_launch`.
    Forms empty-copy (`workoutFormNoExercises`, `mealFormNoIngredients`) untouched (out of scope).
    Manual (deferred): fresh install → hub visible; tap each CTA → correct form opens.
  - Goal: Replace all plain-text empty states with the reusable `EmptyState` widget (icon, title,
    description, CTA) and add the dashboard welcome hub for a completely empty app.
  - Boundaries (in/out of scope):
    - In: `EmptyState` usage in `ingredient_list.dart`, `meal_list.dart`, `exercise_list.dart`,
      `workout_list.dart`, `planner_screen.dart`, `workout_detail.dart` (no-exercises), body-metrics
      empty state (post-T06); dashboard no-data state renders the welcome hub (icon `rocket_launch`,
      "Welcome to FitFat", three action rows → ingredient form / meal form / workout form) instead of
      the two empty cards; new ARB keys en/fr/es (per-screen title/body/CTA + hub) + `flutter gen-l10n`.
    - Out: Dedicated onboarding screens, empty states on the meal-form ingredient picker, archived-
      ingredient empty copy (T05).
  - Done when:
    - Every empty list shows `EmptyState` with a CTA that opens its create flow; dashboard shows the
      hub when there are no meals AND no workouts, and normal cards otherwise.
    - All new strings localized en/fr/es; `flutter gen-l10n` — exit 0.
    - `dart analyze lib/` — zero errors.
  - Verification notes (commands or checks):
    - `flutter gen-l10n` — exit 0; `dart analyze lib/` — "No issues found!".
    - Manual (deferred): fresh install → hub visible; tap each CTA → correct form opens.

---

- [x] T04: `Interaction feedback pass (haptics, SnackBars, micro-motion, meal tile)` (status:done)
  - Task ID: T04
  - Completed: 2026-08-07
  - Files changed: `lib/src/ui/haptics.dart` (new — `Haptics.selection`/`mediumImpact`/`lightImpact`
    wrapping `HapticFeedback.*`), `lib/l10n/app_en.arb`, `lib/l10n/app_fr.arb`, `lib/l10n/app_es.arb`
    (new `commonSaved`, `commonEdit`, `workoutStarted`, `workoutCompleted`), `lib/l10n/app_localizations*.dart`
    (regenerated), `lib/src/diet/screens/meal_form.dart` (`commonSaved` SnackBar on save),
    `lib/src/exercise/screens/workout_form.dart` (`commonSaved` SnackBar on save),
    `lib/src/exercise/screens/workout_detail.dart` (`workoutStarted`/`workoutCompleted` SnackBars on
    start/complete; `Haptics.lightImpact` on set-actuals save), `lib/src/body/screens/body_metrics_card.dart`
    (`commonSaved` SnackBar on add weight/height), `lib/src/planner/screens/planner_screen.dart`
    (`Haptics.selection` on toggle, `Haptics.mediumImpact` on delete),
    `lib/src/diet/screens/ingredient_list.dart`, `lib/src/diet/screens/meal_list.dart`,
    `lib/src/exercise/screens/exercise_list.dart`, `lib/src/exercise/screens/workout_list.dart`
    (`Haptics.mediumImpact` on delete), `lib/src/diet/screens/meal_list.dart` (`_MealTile` → stateful;
    trailing = edit `IconButton` with `commonEdit` tooltip + `AnimatedRotation` chevron)
  - Evidence: `flutter gen-l10n` exit 0; `dart analyze lib/` "No issues found!"; `flutter test` 1/1
    passed; `dart format --output=none --set-exit-if-changed` exit 0 (64 files, 0 changed); `rg`
    verified 7 haptic call sites (selection ×1, mediumImpact ×5, lightImpact ×1) + 6 SnackBar sites
  - Notes: All scope decisions match the plan brief (user-confirmed). `StatusBadge` already had the
    `AnimatedContainer` color flip from T01 — nothing added. Dashboard hero `AnimatedSwitcher`
    deferred to T09 as planned ("pattern helper if needed" — no helper needed). `commonEdit` added
    beyond the plan's example keys for the meal-tile edit `IconButton` tooltip (a11y). Haptics use
    `unawaited(...)` at call sites (matches existing `dart:async` pattern). SnackBars shown on the
    root `ScaffoldMessenger` before the forms pop so they persist across the transition. Meal tile:
    body tap toggles expansion (`onExpansionChanged` drives `AnimatedRotation` turns 0→0.5), the
    trailing edit `IconButton` wins its own taps (edit stays reachable). Manual (deferred): toggle
    planner checkbox (haptic), save a meal (SnackBar), expand a meal tile, start/complete a workout.
  - Goal: Add tactile and visual feedback for key interactions and fix the meal-tile expand/edit
    affordance quirk.
  - Boundaries (in/out of scope):
    - In: haptics (`HapticFeedback.selectionClick` on planner checkbox toggle, `mediumImpact` on
      deletes, `lightImpact` on set-actuals save) via a small `lib/src/ui/haptics.dart` helper (new);
      save/start/complete SnackBars (meal form save, workout form save, workout start + complete,
      body-metrics save) with new ARB keys (e.g., `commonSaved`, `workoutStarted`, `workoutCompleted`);
      `AnimatedContainer` color flip inside `StatusBadge` (from T01); `AnimatedSwitcher` on the
      dashboard hero number (widget-level, wired fully in T09 — here just the pattern helper if needed);
      meal tile fix in `meal_list.dart` (explicit expand affordance restored AND edit reachable —
      e.g., body tap toggles expansion, trailing keeps a visible chevron + edit icon; remove the
      current "edit where chevron should be" layout).
    - Out: Page-transition customization (M3 defaults stay), chart growth animation (T09), undo
      SnackBars (T05/T07), greeting header (T09).
  - Done when:
    - Haptics fire on the specified interactions (no-op where unsupported); save/start/complete show
      SnackBars; meal tile shows an expand affordance and a reachable edit action.
    - New strings localized en/fr/es; `flutter gen-l10n` — exit 0; `dart analyze lib/` — zero errors.
  - Verification notes (commands or checks):
    - `flutter gen-l10n` — exit 0; `dart analyze lib/` — "No issues found!".
    - Manual (deferred): toggle planner checkbox (haptic), save a meal (SnackBar), expand a meal tile.

---

- [x] T05: `Ingredient soft-archive (schema v4)` (status:done)
  - Task ID: T05
  - Completed: 2026-08-08
  - Files changed: `lib/src/database/tables.dart` (ingredients `is_archived` bool column, default false), `lib/src/database/app_database.dart` (schemaVersion 3→4; v3→v4 `addColumn`), `lib/src/database/app_database.g.dart` (regenerated), `lib/src/models/ingredient.dart` (`isArchived` default false + `copyWith`), `lib/src/diet/repositories/ingredient_repository.dart` (`getAll` filters `is_archived == false`; `archive(id)`/`restore(id)`; removed hard `delete` — no callers remain; `_toDomain` maps `isArchived`), `lib/src/diet/screens/ingredient_list.dart` (Dismissible → `archive` + SnackBar `ingredientArchived` with Undo → `restore`; confirm dialog removed; haptic kept), `lib/l10n/app_en.arb`, `lib/l10n/app_fr.arb`, `lib/l10n/app_es.arb` (added `commonUndo`, `ingredientArchived`; removed dead `ingredientListDeleteTitle`/`ingredientListDeleteConfirm`), `lib/l10n/app_localizations*.dart` (regenerated)
  - Evidence: `flutter pub run build_runner build` exit 0 (107 outputs written); `flutter gen-l10n` exit 0; `dart analyze lib/` "No issues found!"; `flutter test` 1/1 passed; `dart format --output=none --set-exit-if-changed` exit 0 (5 files, 0 changed)
  - Notes: Pickers verified: `meal_form.dart:64` reads `ingredientListProvider` → repo-level `getAll` filter covers list AND meal-form picker (no meal_form change needed). Past-meal names keep rendering because `meal_repository._getItemsForMeal` joins ALL ingredient rows (no `is_archived` filter) — intentionally untouched. `getById` has no screen consumers (left unfiltered). `IngredientRepository.delete` removed entirely (only caller was the rewritten screen) so no code path can re-introduce FK errors; `insert` uses `IngredientsCompanion.insert` (default false covers fresh ingredients) and `update` writes only named fields so `isArchived` is preserved on edits. `commonUndo` fr = "Rétablir" (avoided the "Annuler" collision with `commonCancel`), es = "Deshacer". SnackBar messenger captured before the await to satisfy `use_build_context_synchronously`. Migration adds a NOT NULL DEFAULT 0 column → no data loss on upgrade. Manual (deferred): archive an ingredient used by a meal → no error, meal unchanged, list/picker hide it, Undo restores it.
  - Goal: Archive instead of delete ingredients: `is_archived` column (schema v4), repository
    archive/restore + filtering, list swipe → archive + Undo, picker exclusion.
  - Boundaries (in/out of scope):
    - In: `lib/src/database/tables.dart` (add `is_archived` bool column default false to `Ingredients`),
      `lib/src/database/app_database.dart` (`schemaVersion` → 4, `if (from < 3)` … `if (from < 4)`
      add column), codegen via `flutter pub run build_runner build`, `lib/src/models/ingredient.dart`
      (`isArchived` + `copyWith`), `lib/src/diet/repositories/ingredient_repository.dart` (`getAll()`
      filters `is_archived == false`; `archive(id)`; `restore(id)`; `newIngredient` defaults false),
      `lib/src/diet/screens/ingredient_list.dart` (Dismissible → `archive` + SnackBar "Ingredient
      archived" with Undo → `restore`; drop the confirm dialog), `lib/src/diet/screens/meal_form.dart`
      (picker excludes archived — verify it reads the repository/provider, not a raw query), ARB keys
      en/fr/es (`commonUndo`, archive message), `context/database/schema.md` (v4 note).
    - Out: Meals/workouts/planner delete+undo (T06/T07), exercise policy (T06/T07), restore surface
      beyond immediate Undo (user decision: none), body-metrics archive (not applicable).
  - Done when:
    - Deleting an ingredient never throws (no FK violation); archived ingredients vanish from list and
      picker; Undo restores them; names still render in past meals; fresh ingredients default
      non-archived; v4 migration preserves data.
    - `flutter pub run build_runner build` — exit 0; `dart analyze lib/` — zero errors; `flutter test`
      — passes.
  - Verification notes (commands or checks):
    - `flutter pub run build_runner build` — exit 0 (never `dart run`).
    - `dart analyze lib/src/diet/ lib/src/database/` — zero errors; `flutter test` — 1/1 passed.
    - Manual (deferred): archive an ingredient used by a meal → no error, meal unchanged, list/picker
      hide it, Undo restores it.

---

- [x] T06: `Delete mechanics — repository restore paths` (status:done)
  - Task ID: T06
  - Completed: 2026-08-08
  - Files changed: `lib/src/diet/repositories/meal_repository.dart` (`restore(MealEntry)` — delegates to `insert`, which already re-inserts meal + items with original ids), `lib/src/exercise/repositories/workout_repository.dart` (new local `WorkoutSnapshot` holding raw Drift rows `db.Workout` + `List<db.WorkoutExercise>` + `List<db.ExerciseSet>`; `deleteWithSnapshot(String id)` — one transaction reads all 3 levels, deletes all 3, returns the snapshot, throws `StateError` if the workout row is missing; `restore(WorkoutSnapshot)` — transactional 3-level re-insert with original ids AND nullable started_at/completed_at/notes + set actuals/notes), `lib/src/planner/repositories/planner_repository.dart` (`restore(PlannerItem)` — delegates to `insert`), `lib/src/exercise/repositories/exercise_repository.dart` (`usageCount(String id)` — `selectOnly` + `id.count()` over `workout_exercises` by `exercise_id`)
  - Evidence: `dart analyze lib/` "No issues found!"; `flutter test` 1/1 passed; `dart format --output=none --set-exit-if-changed` exit 0 (4 files, 0 changed); throwaway in-memory round-trip test (`context/tmp/t06_roundtrip_test.dart`, run via `flutter test` with `LD_LIBRARY_PATH=/nix/store/0vpj29gvvl1z9fjwh4lk9fiyvkqf21px-sqlite-3.50.4/lib` because the Nix VM has no system libsqlite3) — 4/4 passed: meal delete→restore exact rows; workout deleteWithSnapshot→restore exact rows (startedAt + set actuals/notes preserved); planner delete→restore exact row; usageCount 1/1/0
  - Notes: No screen behavior changed (screens still call plain `delete` — T07 rewires them). `WorkoutSnapshot` uses raw Drift row types so restore is exact by construction; local to the repo file per plan. `deleteWithSnapshot` throws before deleting children when the workout row is absent (fail-safe, no silent child loss). Meal/planner `restore` delegate to the existing `insert` (already preserves original ids) → create and restore share one path ("factor the shared insert logic" intent). Create-path `insert` still intentionally drops set actuals (they're written via `updateSetActuals`); restore writes everything. Round-trip test kept as a session scrap in `context/tmp/` for T11 cleanup. Manual (deferred to T07): delete → restore round-trip via UI.
  - Goal: Add the repository-layer machinery for hard-delete-with-undo and exercise usage checks,
    with no screen behavior change yet.
  - Boundaries (in/out of scope):
    - In: `lib/src/diet/repositories/meal_repository.dart` (`restore(MealEntry)` — transactional
      re-insert meal + all `meal_ingredients` with original ids; factor the shared insert logic so the
      create path and restore path stay consistent), `lib/src/exercise/repositories/workout_repository.dart`
      (`deleteWithSnapshot(String id) → WorkoutSnapshot` — within one transaction read `workout_exercises`
      + `exercise_sets`, delete all three levels, return the snapshot; `restore(WorkoutSnapshot)` —
      transactional 3-level re-insert with original ids; `WorkoutSnapshot` type local to the repo),
      `lib/src/planner/repositories/planner_repository.dart` (`restore(PlannerItem)`), 
      `lib/src/exercise/repositories/exercise_repository.dart` (`usageCount(String id) → int` — count
      `workout_exercises` rows referencing the exercise).
    - Out: Screen wiring / SnackBars / dialogs (T07), ingredient archive (T05), any schema change.
  - Done when:
    - All new repo methods exist, compile, and round-trip (restore re-inserts the exact rows deleted);
      existing create/update paths are unchanged in behavior; suite stays green.
    - `dart analyze lib/` — zero errors; `flutter test` — passes.
  - Verification notes (commands or checks):
    - `dart analyze lib/src/diet/ lib/src/exercise/ lib/src/planner/` — zero errors.
    - Manual (deferred to T07): delete → restore round-trip via UI.

---

- [x] T07: `Screen-layer delete + undo and exercise usage block` (status:done)
  - Task ID: T07
  - Completed: 2026-08-08
  - Files changed: `lib/src/diet/screens/meal_list.dart` (swipe → `delete` + SnackBar `mealDeleted` with Undo → `restore(MealEntry)`; confirm dialog removed), `lib/src/exercise/screens/workout_list.dart` (swipe → `deleteWithSnapshot` + SnackBar `workoutDeleted` with Undo → `restore(snapshot)`; confirm dialog removed), `lib/src/planner/screens/planner_screen.dart` (swipe → `delete` + SnackBar `plannerDeleted` with Undo → `restore(PlannerItem)`; confirm dialog removed), `lib/src/exercise/screens/exercise_list.dart` (`confirmDismiss` → `usageCount`; if > 0 show blocking `exerciseUsed*` dialog + `commonOk` and return false — tile snaps back, nothing deleted; else plain delete with no Undo), `lib/l10n/app_en.arb`, `lib/l10n/app_fr.arb`, `lib/l10n/app_es.arb` (added `mealDeleted`/`workoutDeleted`/`plannerDeleted` with `{name}`/`{title}` placeholder, `exerciseUsedTitle`, `exerciseUsedBody` + `_plural` with int `count`, `commonOk`; removed dead `mealListDeleteTitle`/`mealListDeleteConfirm`/`workoutListDeleteTitle`/`workoutListDeleteConfirm`/`plannerDeleteTitle`/`plannerDeleteConfirm`/`exerciseListDeleteTitle`/`exerciseListDeleteConfirm`/`commonDelete`), `lib/l10n/app_localizations*.dart` (regenerated)
  - Evidence: `flutter gen-l10n` exit 0; `dart analyze lib/` "No issues found!"; `flutter test` 1/1 passed; `dart format --output=none --set-exit-if-changed` exit 0 (4 changed screens + 4 l10n files, 0 changed); dead-key grep clean (`rg "DeleteTitle|DeleteConfirm|commonDelete" lib/` → zero hits; only historical hits remain in completed plan files)
  - Notes: User decision (this session): unused-exercise delete = **plain delete, NO Undo** — no `ExerciseRepository.restore` added (plan text said delete+Undo→restore; user overrode to keep T06's exercise repo unchanged). Implementation detail: the exercise usage-block runs in `confirmDismiss` (not `onDismissed`) because a dismissed Dismissible must leave the tree — blocking there returns false so the tile snaps back cleanly and nothing is deleted/throws. Meals/workouts/planner use the T05-established messenger pattern: messenger + l10n captured before the await (satisfies `use_build_context_synchronously`), then `hideCurrentSnackBar()` + `showSnackBar(...)` so consecutive deletes replace instead of queue. `commonCancel` still used elsewhere (4 non-dialog sites) — kept; `commonDelete` became orphaned once all 4 confirm dialogs were removed — deleted from all ARBs (T03 dead-key precedent). `exerciseUsedBody` uses the `plannerCopyConfirmBody`-style plural pattern (`key` + `key_plural` + `@key` with int `count`). SnackBar messages include the deleted entity name (matches T05 `ingredientArchived` style): "Meal \"{name}\" deleted" / fr "Repas « {name} » supprimé" / es "Comida «{name}» eliminada"; workout fr "Séance … supprimée" (feminine agreement). Manual (deferred): delete workout with 2 exercises + sets → Undo → identical detail; delete exercise used in a workout → blocked with count; delete unused exercise → gone, no Undo.
  - Goal: Wire SnackBar + Undo into the meal, workout, and planner lists and add the exercise
    usage-block dialog.
  - Boundaries (in/out of scope):
    - In: `lib/src/diet/screens/meal_list.dart` (onDismissed → repo delete + SnackBar "Deleted" with
      Undo → `restore(MealEntry)`; remove the confirm dialog), `lib/src/exercise/screens/workout_list.dart`
      (same via `deleteWithSnapshot` → Undo → `restore(snapshot)`), `lib/src/planner/screens/planner_screen.dart`
      (same for planner rows), `lib/src/exercise/screens/exercise_list.dart` (delete → `usageCount`;
      if > 0 show a blocking dialog "Used in N workouts — delete the workouts first" and do NOT delete;
      else delete + Undo → `restore`), new ARB keys en/fr/es (deleted message, `commonUndo`, exercise
      usage dialog) + `flutter gen-l10n`.
    - Out: Ingredient archive UI (T05), repository mechanics (T06), delete behavior on other screens,
      undo for completion/start actions.
  - Done when:
    - Swiping a meal / workout / planner item shows "Deleted" + Undo and Undo restores the full
      aggregate; deleting a referenced exercise shows the usage dialog and never deletes/throws; no
      confirm dialogs remain on the main lists.
    - New strings localized en/fr/es; `flutter gen-l10n` — exit 0; `dart analyze lib/` — zero errors.
  - Verification notes (commands or checks):
    - `flutter gen-l10n` — exit 0; `dart analyze lib/src/diet/ lib/src/exercise/ lib/src/planner/` —
      zero errors.
    - Manual (deferred): delete workout with 2 exercises + sets → Undo → identical detail; delete
      exercise used in a workout → blocked with count; delete unused exercise → Undo works.

---

- [x] T08: `Active workout provider + global floating bar` (status:done)
  - Task ID: T08
  - Completed: 2026-08-08
  - Files changed: `lib/src/exercise/providers/workouts.dart` (new `activeWorkoutProvider` — `Provider<Workout?>` derived from `workoutListProvider`, returns the first `isActive` workout or null), `lib/src/app/router.dart` (`_ShellWithNavBar` → `ConsumerWidget`; `bottomNavigationBar` = `Column` with an `AnimatedSwitcher` (slide-up + fade) rendering `_ActiveWorkoutBar` above the `NavigationBar`, switching to `SizedBox.shrink()` when inactive; new private `_ActiveWorkoutBar` StatefulWidget — 1 s ticker, elapsed via `formatRestDuration(workout.duration)`, `StatusBadge` "Active", play `IconButton` tooltip `activeWorkoutResume`; bar tap or play press pushes `WorkoutDetailScreen` via `_rootNavigatorKey`), `lib/l10n/app_en.arb`, `lib/l10n/app_fr.arb`, `lib/l10n/app_es.arb` (added `activeWorkoutResume` en "Resume" / fr "Reprendre" / es "Reanudar"), `lib/l10n/app_localizations*.dart` (regenerated)
  - Evidence: `flutter gen-l10n` exit 0; `dart analyze lib/` "No issues found!"; `flutter test` 1/1 passed; `dart format --output=none --set-exit-if-changed` exit 0 (2 Dart files + 4 l10n files, 0 changed)
  - Notes: `activeWorkoutProvider` derives from `workoutListProvider` — every mutation site already invalidates that provider (workout_detail `_startWorkout`/`_completeWorkout`, T07 list delete/undo), so no new query/stream or extra invalidation wiring was needed. Elapsed time reuses the context-free `formatRestDuration` from `rest_timer.dart` (`mm:ss`, `h:mm:ss` past an hour) — locale-independent, so the plan's "time format if needed" clause was NOT triggered; only `activeWorkoutResume` was added (play-button tooltip, a11y). Bar placement: inside `bottomNavigationBar` as a Column (bar above NavigationBar) → Scaffold floats FABs above the whole column, so no collision with per-screen FABs. In/out animation = `AnimatedSwitcher` with `SlideTransition` (Offset(0,1)→zero) + `FadeTransition`, keyed by `ValueKey(workout.id)`; `AnimatedSwitcher` was chosen over raw `AnimatedSlide`+`AnimatedOpacity` because a Column sibling needs its height to collapse to zero when hidden (switching to `SizedBox.shrink()`). The 1 s ticker lives only while the bar is mounted (the switcher removes it when no workout is active), so its lifecycle follows active state automatically. Tap/press pushes the detail imperatively on `_rootNavigatorKey` (matching workout_list `_openDetail`'s `MaterialPageRoute` pattern — there is no GoRouter route for workout detail). Multiple-active edge case (data shouldn't allow it): returns the first active workout by list order (date desc). Manual (deferred): start workout → bar visible on all 5 tabs with ticking clock; tap → detail; complete → bar gone.
  - Goal: Add `activeWorkoutProvider` and a global floating bar (above the NavigationBar, every tab)
    showing the active workout name + live elapsed time with a resume action.
  - Boundaries (in/out of scope):
    - In: `lib/src/exercise/providers/workouts.dart` (`activeWorkoutProvider` — watches the workout
      repository for the currently active workout), `lib/src/app/router.dart` (`_ShellWithNavBar`
      becomes a `ConsumerWidget`; body wrapped so the bar renders above the `NavigationBar`; 1s ticker
      while active for elapsed mm:ss; `AnimatedSlide`/`AnimatedOpacity` in/out; tap → push
      `WorkoutDetailScreen` via the root navigator key), reuse `StatusBadge`/tokens from T01, ARB keys
      en/fr/es (resume label, time format if needed).
    - Out: Dashboard resume chip (consumes the provider in T09), notification parity work beyond what
      T10 already does, nav badges (dropped by decision).
  - Done when:
    - Bar appears on all tabs exactly while a workout is active (name + elapsed mm:ss), opens the
      detail on tap, animates out on completion/no-active; no collision with per-screen FABs.
    - New strings localized en/fr/es; `dart analyze lib/` — zero errors.
  - Verification notes (commands or checks):
    - `flutter gen-l10n` — exit 0; `dart analyze lib/src/app/ lib/src/exercise/` — zero errors.
    - Manual (deferred): start workout → bar visible on all 5 tabs with ticking clock; tap → detail;
      complete → bar gone.

---

- [x] T09: `Dashboard redesign + data visualization` (status:done)
  - Task ID: T09
  - Completed: 2026-08-08
  - Files changed: `lib/src/dashboard/providers/dashboard.dart` (new `todayMacrosProvider` — `FutureProvider<TodayMacros>` P/C/F gram sums for today via the `MealIngredient.protein/carbs/fat` getters; new `weeklyCaloriesProvider` — `List<(DateTime, double)>` per-day totals for today + previous 6 days, start-of-day keyed, chronological), `lib/src/dashboard/screens/dashboard.dart` (full "today at a glance" rebuild: `_GreetingHeader` time-based greeting ×3 + `DateFormats.formatDate`, `_HeroCaloriesCard` on `MetricCard` with `AnimatedSwitcher` number + `_MacroCompositionBars` stacked 4/4/9-kcal share segments + colored `_MacroLegend`, `_QuickActions` `ActionChip`s — Log meal → `MealFormScreen` (invalidates meal/macro/weekly providers on save), adaptive Start/Resume workout → `context.go('/exercise')` or push `WorkoutDetailScreen` of `activeWorkoutProvider`, Log weight → `showBodyMetricDialog` + upsert + invalidate + `commonSaved` SnackBar, `_WeeklyCaloriesCard` `fl_chart` `BarChart` with `TweenAnimationBuilder` first-paint growth + `duration`/`curve` update animation + `formatDecimal(day.day)` x-labels + tooltip, `_LatestWorkoutCard` → `_ActiveWorkoutCardBody` "Continue workout" `FilledButton.tonalIcon` + `StatusBadge` Active when active, else `_WorkoutCardBody` latest completed + `StatusBadge` Completed + `OutlinedButton` Open workout, `_TodayPlanStrip` pending `plannerItemsProvider(today)` items → `context.go('/plan')`, welcome hub stays for no-data, `BodyMetricsCard` stays, `Center`+`ConstrainedBox(maxWidth: kContentMaxWidth)` wrapper), `lib/src/ui/widgets/metric_card.dart` (optional `child` slot + `AnimatedSwitcher` around the value keyed by string), `lib/l10n/app_en.arb`, `lib/l10n/app_fr.arb`, `lib/l10n/app_es.arb` (added `dashboardGreetingMorning`/`Afternoon`/`Evening`, `dashboardMacroProtein`/`Carbs`/`Fat`, `dashboardChipLogMeal`/`StartWorkout`/`ResumeWorkout`/`LogWeight`, `dashboardWeeklyCalories`, `dashboardContinueWorkout`, `dashboardOpenWorkout`, `dashboardTodayPlan`), `lib/l10n/app_localizations*.dart` (regenerated)
  - Evidence: `flutter gen-l10n` exit 0; `dart analyze lib/` "No issues found!"; `flutter test` 1/1 passed; `dart format --output=none --set-exit-if-changed lib test` exit 0 (65 files, 0 changed)
  - Notes: Scope decisions matched the plan brief (no open questions). Tab switching from the dashboard uses `context.go('/exercise')` / `context.go('/plan')` — verified go_router 15.1.3 `StatefulShellRoute` switches the active branch when `go` targets a route inside another branch (`goBranch`/`currentIndex` internals confirmed in the cached package), so the chips/plan strip land on the right tab without threading the shell down. `MetricCard` gained an optional `child` slot so the hero card can host the composition bars without dropping the shared shell. `AnimatedSwitcher` on the hero number (deferred from T04) is implemented generically inside `MetricCard` keyed by the value string — any metric card animates its number. Composition bars: share = macro kcal (protein/carbs × 4, fat × 9) ÷ total; stacked bar segments use `scheme.primary` (P), `scheme.tertiary` (C), `FitFatColors.warning` (F) — no new hand-picked colors; legend uses the existing `macroGrams` key. Chart: `BarChartRodData.fromY` defaults to 0 (verified in fl_chart 1.2.0) so bars grow from zero; `TweenAnimationBuilder` (motionSlow, easeOutCubic) drives first-paint growth, and `BarChart(duration: motionNormal, curve:)` animates subsequent data changes; x-labels use `formatDecimal(day.day)` because `MaterialLocalizations` has no `formatShortWeekday` (verified in SDK source); tooltip uses `formatDate` + kcal with `Colors.white` text (matches the `body_metrics_card.dart` `_LineChart` precedent). Latest workout card: active workout wins over the latest-completed (plan's "promotes to Continue workout when active"); when no active workout the card falls back to `latestWorkoutProvider` (completed only) or `dashboardNoWorkouts`. Plan strip shows only the not-done items for today and hides entirely when none are pending; tapping switches to the Plan tab. Macro/weekly invalidation added to the hub's meal-save path too so a meal saved from the welcome hub refreshes the hero/chart once data exists. Manual (deferred): log meals across 3 days → hero number + bars + 7-day chart update; start a workout → chip becomes "Resume workout"; add pending planner task → strip shows it; large-screen layout max-width 600.
  - Goal: Rebuild the dashboard as "today at a glance": greeting + locale date header, hero calories
    card with read-only P/C/F composition bars and a 7-day calories bar chart, quick-action chips
    (log meal / adaptive start-or-resume workout / log weight), latest workout card with status badge
    (highlighted "Continue workout" when active), Today's plan strip, body-metrics card restyled,
    welcome hub for no-data, max-width wrapper.
  - Boundaries (in/out of scope):
    - In: `lib/src/dashboard/providers/dashboard.dart` (add `todayMacrosProvider` — P/C/F sums for
      today; `weeklyCaloriesProvider` — per-day calorie totals for the last 7 days), 
      `lib/src/dashboard/screens/dashboard.dart` (full layout per Change Summary; greeting via T02
      date helper; composition bars = each macro's share of total calories, read-only; 7-day `fl_chart`
      bar chart with growth animation; chips: "Log meal" → push `MealFormScreen`, "Start workout" →
      switch to Exercise tab / "Resume workout" → push active workout detail (uses T08's provider),
      "Log weight" → T06 body-metrics add dialog; Today's plan strip watches `plannerItemsProvider(today)`
      pending items → tap switches to Plan tab; `ConstrainedBox(maxWidth: 600)` wrapper), new ARB keys
      en/fr/es (greeting ×3, section titles, chip labels, plan strip) + `flutter gen-l10n`.
    - Out: Goals/targets (user decision: none), charts elsewhere, weekly workout volume/PR charts,
      custom page transitions, notification changes.
  - Done when:
    - All listed dashboard elements render from real data; composition bars and trend chart update
      when meals change; resume chip adapts (active vs not); Today's plan strip reflects pending
      tasks; welcome hub shows when empty; strings localized en/fr/es.
    - `flutter gen-l10n` — exit 0; `dart analyze lib/src/dashboard/ lib/src/planner/` — zero errors.
  - Verification notes (commands or checks):
    - `flutter gen-l10n` — exit 0; `dart analyze lib/` — "No issues found!".
    - Manual (deferred): log meals across 3 days → hero number + bars + 7-day chart update; start a
      workout → chip becomes "Resume workout"; add pending planner task → strip shows it.

---

- [x] T10: `Accessibility & platform polish` (status:done)
  - Task ID: T10
  - Completed: 2026-08-08
  - Files changed: `lib/src/exercise/screens/workout_detail.dart` (set-table number column
    `SizedBox(width: 24)` → `Expanded(flex: 2)` in both `_ExerciseBlockCard` header row and `_SetRow`,
    planned/actual columns `Expanded` → `Expanded(flex: 5)` each; trailing edit affordance wrapped in
    `Tooltip(message: l10n.commonEdit)`), `lib/src/planner/screens/planner_screen.dart`
    (`_DayNavHeader` chevron `IconButton`s gained `tooltip: l10n.plannerPreviousDay` /
    `l10n.plannerNextDay` — the only IconButtons in the app lacking tooltips), `lib/l10n/app_en.arb`,
    `lib/l10n/app_fr.arb`, `lib/l10n/app_es.arb` (new `plannerPreviousDay` en "Previous day" / fr
    "Jour précédent" / es "Día anterior"; `plannerNextDay` en "Next day" / fr "Jour suivant" / es
    "Día siguiente"), `lib/l10n/app_localizations*.dart` (regenerated), `lib/src/app/theme.dart`
    (`AppBarTheme.systemOverlayStyle` per brightness — light `SystemUiOverlayStyle.dark`, dark
    `.light`; + `package:flutter/services.dart` import), `lib/main.dart`
    (`SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge)` after `ensureInitialized()`;
    + services import)
  - Evidence: `flutter gen-l10n` exit 0; `dart analyze lib/` "No issues found!"; `flutter test`
    1/1 passed; `dart format --output=none --set-exit-if-changed lib test` exit 0 (65 files,
    0 changed); `rg` sweep — all 9 `IconButton`s in `lib/src` carry `tooltip:`, no
    `SizedBox(width: 24` remains in `workout_detail.dart`
  - Notes: Contrast verification — computed WCAG ratios for the T01 `FitFatColors` palette: light
    success `#2E7D32` 5.13:1 / warning `#8A4F00` 6.56:1 vs white surface; dark success `#81C784`
    8.46:1 / warning `#FFB74D` 9.83:1 vs `surfaceContainerLow` (0xFF181D1E); `onSuccess`/`onWarning`
    6.83:1 / 8.29:1 vs their chips. All ≥ 4.5:1 → plan's "tune only if failing" clause NOT
    triggered; no color changes. Column scheme (user-approved): flex 2/5/5 — long "12 × 60 kg"
    strings wrap instead of clipping at large text scales (fl_chart minimal-height for the dashboard
    chart remains an accepted limitation). Edge-to-edge: `SystemUiMode.edgeToEdge` (API 35+ is
    edge-to-edge by default; this aligns older devices), status-bar icons per-brightness via
    `AppBarTheme.systemOverlayStyle` (chosen over `AnnotatedRegion` — applies automatically under
    `themeMode`); M3 `NavigationBar` handles bottom system-nav padding itself. Pre-existing l10n gap
    (NOT from this task, flagging for T11 cleanup): `emptyExercisesBody/Cta/Title`,
    `exerciseListAppBar`, `exerciseListManageBtn`, `exerciseUsedBody(+_plural)`, `exerciseUsedTitle`
    are missing in fr/es (8 messages — the gen-l10n untranslated warning). Manual (deferred): set
    font scale 1.5–2.0 and open a workout detail — set-table columns flex without clipping; verify
    status-bar icon legibility in light + dark on device.
  - Goal: Dynamic-type pass, semantics/tooltip sweep, contrast verification, and Android
    edge-to-edge/system UI polish.
  - Boundaries (in/out of scope):
    - In: `lib/src/exercise/screens/workout_detail.dart` (set-table columns use flexible widths /
      `Expanded` instead of fixed `SizedBox(width: 24)`; no clipping at large text scales), tooltip /
      `Semantics` sweep across IconButtons that lack them (e.g., meal tile edit, planner copy,
      day-nav chevrons), status-color contrast tuning in `FitFatColors` if the T01 palette fails the
      ≥ 4.5:1 check in either brightness, `AppBarTheme.systemOverlayStyle` / `SystemChrome` edge-to-edge
      on Android (per-brightness status bar), a quick text-scale smoke check documented in the task notes.
    - Out: Font/asset changes, full WCAG audit, screen-reader-optimized chart semantics (fl_chart
      minimal-height constraint noted as accepted limitation).
  - Done when:
    - Set table renders without clipping at large text scales; all IconButtons carry tooltips or
      semantics; status colors pass contrast in both themes; edge-to-edge renders correctly.
    - `dart analyze lib/` — zero errors.
  - Verification notes (commands or checks):
    - `dart analyze lib/` — "No issues found!".
    - Manual (deferred): set system font scale to 1.5–2.0, open a workout detail, verify the set table;
      verify status bar legibility in light + dark.

---

- [x] T11: `Final validation, cleanup, and context sync` (status:done)
  - Task ID: T11
  - Completed: 2026-08-08
  - Files changed: `lib/l10n/app_fr.arb`, `lib/l10n/app_es.arb` (+ regenerated `app_localizations*.dart`) —
    closed the pre-existing fr/es l10n gap flagged in T10 by adding the 8 missing exercise strings
    (`exerciseListAppBar`, `exerciseListManageBtn`, `emptyExercisesTitle/Body/Cta`, `exerciseUsedTitle`,
    `exerciseUsedBody` + `_plural` + `@exerciseUsedBody` placeholder metadata for `count`);
    `context/tmp/t06_roundtrip_test.dart` removed (T06 session scrap; `context/tmp/` dir removed);
    `context/settings/settings.md` (startup-wiring note now includes the T10 `SystemChrome` edge-to-edge
    call in `main()`); `context/plans/ui-ux-improvements.md` (this record; plan marked completed)
  - Evidence: `flutter pub run build_runner build` exit 0; `flutter gen-l10n` exit 0 and warning-free
    (no untranslated messages); `dart analyze lib/` "No issues found!"; `flutter test` 1/1 passed;
    grep checks clean — no `Colors.green|orange|grey` outside `lib/src/ui/`, no
    `dd.MM.yyyy`/`padLeft(2,'0')` outside `date_formats.dart`; `git status` shows only intended files
  - Notes: `app_database.g.dart` diff vs HEAD is large but fully accounted for — it is the accumulated
    uncommitted T01–T10 schema work (nutriment columns, `is_archived`, planner/body tables), not a T11
    artifact; the regenerate + analyze + tests confirm it matches current `tables.dart`. All 12 context
    files in the done-when list were read back against code this session (schema, design-system,
    dashboard, ingredient/meal/exercise/workout/planner, body, settings, notifications, glossary,
    overview, architecture, context-map) — one drift found and fixed (`settings.md` startup wiring was
    missing the T10 edge-to-edge call); all others accurate. Manual UI checklist remains deferred to the
    user (headless env): theme/dark rendering, locale dates, empty states + hub, haptics/SnackBars,
    archive/delete + undo round-trips, exercise usage block, dashboard elements, floating bar, large-text
    set table. `pedometer`/`share_plus` removal intentionally out of scope (plan Open Questions).
  - Goal: Run the full verification suite, confirm all success criteria, remove any leftover dead
    code / placeholders, and sync `context/` to the new current state.
  - Boundaries (in/out of scope):
    - In: Verification commands, cleanup (e.g., leftover unused helpers, dead placeholders from
      changed screens), context updates.
    - Out: New features, refactors beyond the 8 areas.
  - Done when:
    - `flutter pub run build_runner build` — exit 0; `flutter gen-l10n` — exit 0;
      `dart analyze lib/` — zero errors; `flutter test` — passes.
    - Grep checks clean: no `Colors.green|orange|grey` outside `lib/src/ui/`; no manual
      `dd.MM.yyyy`/`padLeft(2,'0')` outside `date_formats.dart`.
    - Manual checklist from success criteria passes (deferred to the user — headless env): theme/dark
      rendering, locale dates, empty states + hub, haptics/SnackBars, ingredient archive + undo,
      delete + undo round-trips, exercise usage block, dashboard elements, floating bar, large-text
      set table.
    - Context synced:
      - `context/database/schema.md` — v4 (`ingredients.is_archived`), 9 tables.
      - `context/ui/design-system.md` — new domain doc (tokens, light/dark themes, `FitFatColors`,
        shared widgets, `lib/src/ui/` layout).
      - `context/dashboard/dashboard.md` — new layout, providers (macros, weekly calories), quick
        actions, Today's plan strip, welcome hub.
      - `context/diet/ingredient-crud.md` — archive semantics (no delete).
      - `context/diet/meal-crud.md` — delete + undo, empty state, meal tile fix.
      - `context/exercise/exercise-crud.md` — usage-block on delete.
      - `context/exercise/workout-crud.md` — delete + undo (snapshot restore), floating bar,
        activeWorkoutProvider.
      - `context/planner/planner.md` — delete + undo, empty state.
      - `context/glossary.md` — `is_archived`, `WorkoutSnapshot`, floating bar, `FitFatColors` as needed.
      - `context/overview.md` — design system, dark mode, dashboard, delete semantics.
      - `context/architecture.md` — theme now light+dark, `lib/src/ui/`, floating bar in shell,
        undo/archive data flows.
      - `context/context-map.md` — `plans/ui-ux-improvements.md` row (this plan) + `ui/design-system.md`
        row; mark this plan completed.
  - Verification notes (commands or checks):
    - Commands above all exit 0; `git status` shows only intended files.
    - Re-read synced context files to confirm accuracy against code.

---

## Open Questions

- **Exercises: block vs. archive.** User decided ingredients archive (future cross-user sharing) and
  meals/workouts/planner hard-delete + undo. Exercises are also FK-referenced by `workout_exercises`
  but user-owned. **Resolved for T07 (confirmed): block-with-usage-warning dialog; unused exercises
  get a plain hard delete with no Undo** (user decision — no `ExerciseRepository.restore`).
- Whether `pedometer` / `share_plus` (unused leftover deps) should be removed — out of scope for this
  plan; noted for a future cleanup.

## Next Command

Plan complete (T01–T11 all done). Final sign-off via `sce-validation`.

## Validation Report

### Commands run (2026-08-08)
- `flutter pub run build_runner build --delete-conflicting-outputs` -> exit 0 (drift codegen consistent
  with current `tables.dart`; `app_database.g.dart` regenerated)
- `flutter gen-l10n` -> exit 0, **no untranslated-messages warning** (all keys present en/fr/es, incl. the
  T11 closure of the fr/es exercise gap)
- `dart analyze lib/` -> exit 0, "No issues found!"
- `dart format --output=none --set-exit-if-changed lib test` -> exit 0 (65 files, 0 changed)
- `flutter test` -> exit 0 (1/1 passed)
- Grep checks -> clean: no `Colors.green|orange|grey` outside `lib/src/ui/`; no
  `dd.MM.yyyy`/`padLeft(2,'0')` outside `date_formats.dart`
- `git status` -> only intended files (all T01–T11 changes uncommitted)

### Temporary scaffolding removed
- `context/tmp/t06_roundtrip_test.dart` (T06 throwaway in-memory round-trip test) + `context/tmp/` dir.

### Success-criteria verification
- [x] `lib/src/ui/` with tokens + `FitFatColors` + shared widgets; tuned light+dark themes with component
  themes -> present; grep-clean (T01)
- [x] Status colors meet contrast in both brightnesses -> computed ratios light 5.13/6.56:1, dark
  8.46/9.83:1 (T01, re-verified T10)
- [x] All dates/times per locale via `DateFormats`; no manual `dd.MM.yyyy`/`padLeft` in screens ->
  grep-clean (T02)
- [x] `EmptyState` + working CTA on every empty list; dashboard welcome hub when no meal+workout data ->
  implemented (T03)
- [x] Haptics on planner toggles/deletes/set saves; SnackBars on save/start/complete; meal tile expand
  affordance + reachable edit -> implemented (T04)
- [x] Ingredient soft-archive (schema v4 `is_archived`) + Undo un-archive -> implemented (T05)
- [x] Meal/workout/planner delete + Undo restores full aggregate; exercise usage-block dialog never throws
  -> implemented (T06/T07; round-trips verified via the T06 test + T11 suite)
- [x] Dashboard "today at a glance" with all elements + adaptive resume chip -> implemented (T09)
- [x] Floating active-workout bar on every tab; tap opens detail; hidden when inactive -> implemented (T08)
- [x] Set table no clipping at large text; IconButton tooltips; status colors ≥ 4.5:1 both themes;
  edge-to-edge Android -> implemented (T10)
- [x] build_runner / gen-l10n / analyze / test all exit 0; git status only intended files -> this report
- [x] All new user-facing strings localized en/fr/es -> gen-l10n warning-free (incl. T11 fix)
- [x] Context synced (schema v4, design-system, per-area docs, context-map, overview, architecture,
  glossary) -> read-back completed in T11; one drift found and fixed (`settings.md` startup wiring)

### Manual checklist (deferred to the user — headless environment)
theme/dark rendering, locale dates, empty states + hub, haptics/SnackBars, ingredient archive + undo,
delete + undo round-trips, exercise usage block, dashboard elements, floating bar, large-text set table.

### Failed checks and follow-ups
- None. The pre-existing fr/es l10n gap (8 exercise strings) found during T10 was closed in T11.

### Residual risks
- Manual UI checklist not executed in this environment (no display); deferred to the user.
- Working tree has never been committed (all T01–T11 changes staged-in-working-tree); the first commit
  should be reviewed carefully (esp. the regenerated `app_database.g.dart`).
- `pedometer`/`share_plus` unused deps remain (out of scope — plan Open Questions).
