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
- **Radii**: `radiusS` 8, `radiusM` 12, `radiusL` 16, `radiusFull` 999.
- **Motion**: `motionFast` 150 ms, `motionNormal` 250 ms, `motionSlow` 350 ms.
- **Layout**: `kContentMaxWidth` 600 (dashboard max-width wrapper, T09).

## Themes (`lib/src/app/theme.dart`)

`FitFatTheme.light` / `FitFatTheme.dark` are built from `ColorScheme.fromSeed(Colors.teal)`. The
dark scheme layers a **teal-tinted surface family** on top of the standard M3 dark scheme (from
`app-improvements` T07):

| Role | Dark hex |
|------|----------|
| `surface` | `0xFF101415` |
| `surfaceContainerLowest` | `0xFF0B0F10` |
| `surfaceContainerLow` (cards) | `0xFF181D1E` |
| `surfaceContainer` | `0xFF1D2324` |
| `surfaceContainerHigh` | `0xFF282F30` |
| `surfaceContainerHighest` | `0xFF333B3C` |

Component themes registered in both brightnesses: Card (flat, elevation 0, `surfaceContainerLow`),
FilledButton / OutlinedButton / TextButton (radius `radiusM`), InputDecoration (filled + rounded,
primary focus border), NavigationBar, AppBar (flat, transparent surface tint, per-brightness
`systemOverlayStyle` — dark icons in light theme / light icons in dark theme), Dialog,
ExpansionTile (borderless), ListTile (icon color), FloatingActionButton.
App-level feedback uses the shared **`TopBanner`** overlay (`lib/src/ui/widgets/top_banner.dart`,
replacing snackbars app-wide: deletion-undo + error messages only); no SnackBar theme is registered.

## FitFatColors (`lib/src/ui/theme_extensions.dart`)

The only hand-picked colors; everything else is M3-derived from teal. Both themes register the
extension; read it with `Theme.of(context).extension<FitFatColors>()`.

| Token | Light | Dark |
|-------|-------|------|
| `success` | `0xFF2E7D32` | `0xFF81C784` |
| `onSuccess` | `0xFFFFFFFF` | `0xFF10341B` |
| `warning` | `0xFF8A4F00` | `0xFFFFB74D` |
| `onWarning` | `0xFFFFFFFF` | `0xFF3D2500` |

Light values hold ≈5.1:1 (success) / ≈6.6:1 (warning) on white; dark values ≈8.4:1 / ≈9.8:1 on the
tuned dark surfaces — both ≥ 4.5:1. "Pending"/neutral statuses use M3 `colorScheme.outline`
(no extra hand-picked color).

## Shared widgets

- **StatusBadge** — `StatusBadge(label, color)`: pill text on a 15% alpha tint of the status color,
  `AnimatedContainer` color flip over `motionFast`. Used by `workout_list.dart` and
  `workout_detail.dart` (status pills); pending neutral = `colorScheme.outline`.
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

See also: [architecture.md](../architecture.md), [overview.md](../overview.md),
[context-map.md](../context-map.md).
