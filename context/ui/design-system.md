# FitFat — Design System

The app-wide design system lives in `lib/src/ui/` and is wired through `lib/src/app/theme.dart`.
Established in plan `ui-ux-improvements` T01 (polished Material 3, teal seed kept).

## AppBar action budget (appbar-declutter Phase A)

Rule: **≤1 always-visible action + one `PopupMenuButton` (⋮ More) per screen.**
Create actions live in a `FAB`; search opens a dedicated search route. The appbar
must never become a dumping ground — when a second always-visible action is
needed, it moves into the ⋮ More menu instead.

- Planner: 1 visible icon (view toggle) + ⋮ More (copy previous day).
- Dashboard: single gear; Meals: manage-ingredients; Budget/Notes/Experiments/
  Exercise: title only.
- Follow this budget on new screens and when adding actions to existing ones.

## Layout

```
lib/src/ui/
 ├─ tokens.dart             FitFatTokens — spacing, radii, motion, kContentMaxWidth
 ├─ theme_extensions.dart   FitFatColors — ThemeExtension (success/warning + on*), light + dark
 ├─ date_formats.dart       DateFormats — locale-aware date/time helpers
 ├─ format.dart             formatDecimal — whole-or-one-decimal number formatting
 ├─ haptics.dart            Haptics — selection/mediumImpact/lightImpact feedback helpers
 └─ widgets/
     ├─ status_badge.dart   StatusBadge — animated status pill
     ├─ empty_state.dart    EmptyState — tonal-circle icon + title + description + CTA
     └─ metric_card.dart    MetricCard — stat-card shell (title/value/icon/subtitle/trailing)
```

## FitFatTokens (`lib/src/ui/tokens.dart`)

- **Spacing**: `spaceXs` 4, `spaceS` 8, `spaceM` 12, `spaceL` 16, `spaceXl` 24, `spaceXxl` 32.
- **Radii**: `radiusS` 8, `radiusM` 12, `radiusL` 14, `radiusFull` 999.
- **Rows**: `rowHeight` 50 (ListTile `minTileHeight`).
- **Motion**: `motionFast` 150 ms, `motionNormal` 250 ms, `motionSlow` 350 ms.
- **Layout**: `kContentMaxWidth` 600 (dashboard max-width wrapper, T09).

## Palettes and themes

Color and style are separate. **Color** comes from a `ThemePalette` (`lib/src/ui/palettes.dart`):
13 roles — `bg`, `surface`, `surface2`, `raise`, `fg`, `muted`, `line`, `accent`, `onAccent`,
`success`, `warning`, `danger`, `onDanger`. The user picks one dark and one light palette in
Settings › Appearance (preview tiles, `settings/widgets/palette_picker.dart`); they are stored as
`settings_dark_palette` / `settings_light_palette` by `appearanceProvider`
(`settings/providers/appearance.dart`) and apply instantly. Defaults: **Dracula** (dark) and
**Alucard** (light). Also available: Catppuccin Mocha/Latte, Nord/Nord Light, Gruvbox Dark/Light,
Solarized Dark/Light, Tokyo Night/Day, FitFat Teal. `test/theme_palette_test.dart` checks every
palette for ≥ 4.5:1 text contrast.

**Style** is "Inset", fixed in code (`FitFatTheme.fromPalette`, `lib/src/app/theme.dart`): grouped
sections on the `bg` canvas, flat cards on `surface`, fields on a solid `surface` fill with no
border (accent focus ring), 50dp rows, sheets/dialogs on `raise`. Palette → `ColorScheme`:

| Scheme role | Palette role |
|-------------|--------------|
| `surface`, `surfaceContainerLowest` | `bg` |
| `surfaceContainerLow`, `surfaceContainer` (cards, fields) | `surface` |
| `surfaceContainerHigh` (dialogs, sheets) | `raise` |
| `surfaceContainerHighest` | `surface2` |
| `onSurface` / `onSurfaceVariant` | `fg` / `muted` |
| `outlineVariant` (dividers) | `line` |
| `primary`, `secondary` / `onPrimary` | `accent` / `onAccent` |
| `error` / `onError` | `danger` / `onDanger` |
| `tertiary` | `warning` |

Never hard-code colors in widgets; read the scheme or `FitFatColors`. `FitFatTheme.light` /
`.dark` return the default palettes (used by tests).

## FitFatColors (`lib/src/ui/theme_extensions.dart`)

`success` / `warning` (+ on-colors), built from the active palette with
`FitFatColors.fromPalette`. Danger is `colorScheme.error`. Read with
`Theme.of(context).extension<FitFatColors>()`. "Pending"/neutral statuses use
`colorScheme.outline`.

## Local-first: no loading or error screens

Lists, dashboard, detail and form screens read the local database and must never show a spinner,
skeleton or error screen. The main list providers are loaded in the background at startup
(`_BackgroundStartup` in `app.dart`) and stay cached; `loading:` branches on local data render
`SizedBox.shrink()`. Only sync (push/pull, receipt upload) may show progress or failures.

## Shared widgets

- **SectionHeader** (`ui/widgets/section_header.dart`) — `SectionHeader(label, {trailing})`: the
  one group label: small caps, muted, with an optional right-aligned total (day net, week totals).
  Used by `SettingsSection` titles; use it for every grouped list.
- **FormScaffold** (`ui/widgets/form_scaffold.dart`) — the standard form: close (×) on the left,
  small filled **Save** top right (disabled until `canSave`, spinner while `saving`), fields in a
  600dp column, and in edit mode a **DangerRow** at the bottom (`FormDeleteAction(label,
  consequence, onDelete)`) saying what else is removed.
- **confirmDelete** (`ui/widgets/confirm_delete.dart`) — the single delete flow. No other data
  affected → delete at once + Undo banner. Cascade (`cascade: [(label:, count:)]`, zero counts
  ignored) → sheet listing what else goes, delete only on confirm.
- **showAppSheet** (`ui/widgets/app_sheet.dart`) — search-first picker sheet at 92% height:
  search field (+ optional filter chips) pinned on top, results from
  `builder(context, query, scrollController)` below.

- **StatusBadge** — `StatusBadge(label, color)`: pill text on a 15% alpha tint of the status color,
  `AnimatedContainer` color flip over `motionFast`. Used by `workout_list.dart` and
  `workout_detail.dart` (status pills); pending neutral = `colorScheme.outline`. Also used outside
  status semantics for informational tags — the ingredient list marks archived rows with
  `colorScheme.primary` — so a bare icon is not the fallback for "this row is special".
- **EmptyState** — `EmptyState(icon, title, description, {ctaLabel, onCtaPressed})`: tonal-circle
  icon + title + description + optional primary CTA. Since T03 it is the empty state for every list
  screen — ingredients (`soup_kitchen_outlined`), meals (`restaurant_outlined`), exercises
  (`sports_gymnastics`), workouts (`fitness_center`), planner (`event_note`) — each with a CTA that
  opens its create flow, plus the workout-detail no-exercises case (`fitness_center`, **no CTA** —
  no edit-workout flow exists). Strings come from per-screen ARB keys
  (`empty{Ingredients,Meals,Exercises,Workouts,Planner,WorkoutDetail}{Title,Body,Cta}`).
- **MetricCard** — `MetricCard(title, value, {icon, subtitle, trailing, child})`: shared stat-card shell.
  The value renders inside an `AnimatedSwitcher` keyed by the string (hero-number animation); the
  optional `child` slot hosts extra content below the subtitle (e.g. the dashboard hero's P/C/F
  composition bars). Consumed by the dashboard hero card (T09).

## Feedback — top banner (`lib/src/ui/widgets/top_banner.dart`)

`showTopBanner` / `showTopBannerOverlay` render a compact top-anchored banner that replaces the
previous one and auto-dismisses. Policy (feedback-banners T01/T02, 2026-08-17): **only two kinds of
banners may ever appear** — deletion-undo banners (Undo action, generous ~3.5 s duration) and error
banners (`errorWithMessage`, form validations, blocked-action warnings). All success/confirmation
noise was removed; the default duration is 2 s. Do not add new confirmation banners without a
reason.

## Pinned summary rows (`Column` + `Expanded`, not slivers)

When a screen needs a derived readout that stays visible while a long form scrolls, put it in a
`Column` above `Expanded(<scrollable>)` rather than a `SliverPersistentHeader` or
`SliverAppBar.bottom`. Both sliver options take a **fixed extent**, but these readouts vary (an
optional line appears or disappears) and scale with the user's text size — so the extent has to be
hand-computed and can be wrong. A `Column` sibling takes its height from the child, so both cases
just work, `Form`/`validate()` stay untouched, and there is no `NestedScrollView` to fight the
keyboard.

Reference implementation: the recipe nutrition preview in `diet/screens/food_form.dart`, which shows the
resolved per-100g result while the amounts are being typed.

**Cost:** the row permanently occupies vertical space. Keep it to ~2–3 short lines and prefer
compact text over a tall `Card` (which adds 16px of padding on every side).

## Number formatting (`lib/src/ui/format.dart`)

- `formatDecimal(double)` — whole when `value == value.roundToDouble()`, else one decimal ("12" / "12.5"). Single formatting path for set weights/distances and summary metrics (kg / m) across the workout detail, active-workout, and summary screens (app-polish-batch T06). Reps stay integers.

## Locale-aware dates (`lib/src/ui/date_formats.dart`)

- `DateFormats.formatDate` → `MaterialLocalizations.formatMediumDate`
- `DateFormats.formatShortDate` → `MaterialLocalizations.formatShortDate`
- `DateFormats.formatTime(TimeOfDay)` → `MaterialLocalizations.formatTimeOfDay`
- `DateFormats.twoDigit` — context-free zero-pad for locale-independent values

All date/time display goes through `DateFormats` so it renders per the active locale (en/fr/es) via
the registered `GlobalMaterialLocalizations` delegate (no `intl` init). Call sites: dashboard (workout
date), meal list (`_DayGroup`), meal form (eaten date + time), workout list (`_WorkoutTile`), workout
detail (date + `startedAt` time), workout form (date label). The planner and `body_metrics_card` use
`formatMediumDate`/`formatShortDate` directly (equivalent, pre-existing). `formatRestDuration` in
`lib/src/notifications/rest_timer.dart` stays context-free (background isolate, no `BuildContext`) and
uses `DateFormats.twoDigit` — `mm:ss` is locale-independent notation.

## Haptics (`lib/src/ui/haptics.dart`)

`Haptics.selection()` → `HapticFeedback.selectionClick` (planner checkbox toggles),
`Haptics.mediumImpact()` → `HapticFeedback.mediumImpact` (list deletes), `Haptics.lightImpact()` →
`HapticFeedback.lightImpact` (set-actuals save). Call sites use `unawaited(...)`; no-op where the
platform does not support haptics (T04).

## Accessibility (T10)

- **Tooltips**: every `IconButton` in `lib/src` carries a tooltip; the workout-detail set-row edit
  affordance is a `Tooltip` (`commonEdit`).
- **Dynamic type**: the set table in `workout_detail.dart` uses flex columns (`Expanded(flex: 2)` `#` /
  `flex: 5` planned / `flex: 5` actual) — rows wrap instead of clipping at large text scales.
- **Contrast**: `FitFatColors` verified ≥ 4.5:1 in both brightnesses (light success 5.13:1 / warning
  6.56:1 vs white; dark success 8.46:1 / warning 9.83:1 vs `surfaceContainerLow`) — no palette changes
  were needed.
- **Edge-to-edge**: Android renders edge-to-edge (`SystemUiMode.edgeToEdge` in `main()`); status-bar
  icons follow brightness via `AppBarTheme.systemOverlayStyle`.

## Contract

- No `Colors.green` / `Colors.orange` / `Colors.grey` outside `lib/src/ui/` (grep-clean, verified in
  T01); status colors come from `FitFatColors`, neutrals from `colorScheme`.
- No manual `padLeft(2, '0')` date/time formatting outside `date_formats.dart` (grep-clean, verified
  in T02); calendar dates and clock times render per locale via `DateFormats`.
- **No hardcoded user-facing strings.** Every label goes through an ARB key in all three locales,
  and every number through `formatDecimal` / `formatFxRate` rather than `toStringAsFixed`. Composite
  work regressed both (bare `'P '`/`'F '`/`'Na '` prefixes and a `'—'` placeholder) and had to be
  corrected — `ingredientNutrientSodium/Fiber/Sugar` already covered the nutriments in fr/es.
- **No dead ARB keys.** A key created but never rendered is a defect, not a harmless extra (the
  ingredient-metadata plan recorded "dead keys avoided" as a convention). Sweep after any l10n
  change — `commonDelete` was literally rendering as the tooltip "Common Delete", and four composite
  keys had zero call sites:
  ```bash
  for k in $(grep -o '"\(ingredient\|common\)[A-Za-z]*"' lib/l10n/app_en.arb | tr -d '"' | sort -u); do
    grep -rq "\.$k\b" lib/src --include=*.dart || echo "DEAD: $k"
  done
  ```

See also: [architecture.md](../architecture.md), [overview.md](../overview.md),
[context-map.md](../context-map.md).

## Screen standards: dashboard, settings, sync

- **Dashboard** (`dashboard/screens/dashboard.dart`): a "today stack" — large title, one column of
  `_DashCard`s (small-caps label + value, tap opens the full screen). Order and visibility come from
  `dashboardLayoutProvider` (`settings_dashboard_order` / `settings_dashboard_hidden`), edited in
  Settings › Dashboard; default order is nutrition, tasks, training, weight, goals, money. An empty
  card shows one line plus a start action (`_EmptyStart`), never a blank card. No spinners: cards
  render from cached provider values.
- **Sync status**: `SyncChip` in the dashboard top bar (last sync age / spinner / red on failure)
  opens a sheet with `SyncStatusPanel` (server, last sync, Sync now, live progress, failure with
  Retry and Rescan). The Sync screen opens with the same panel. Progress and failures are shared
  through `syncRunProvider`; start a full sync with `runFullSync(context, ref)`.
- **Settings hub**: search field on top (filters every entry), simple settings inline (theme,
  language sheet, units, notification switches), bigger pages as `SettingsRow`s in
  `SettingsGroup`s showing their current value. Settings save instantly; no Save buttons.
  Settings pages use `SettingsGroup` + `SettingsRow` + `showSettingsChoiceSheet` ("grouped rows
  + sheets").
