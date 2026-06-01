# UI: Navigation

This file documents the bottom navigation implementation and localization points.

- File: `lib/src/app/router.dart`
- Component: `AppShell` — responsible for the app shell and bottom navigation bar

Current state:
- The bottom navigation has three destinations: Diet, Dashboard, Exercise.
- Labels are localized via ARB keys: `navDiet`, `navDashboard`, `navExercise`.
- Keys are defined in `lib/l10n/app_en.arb`, `app_fr.arb`, `app_es.arb` and generated into `AppLocalizations`.

Notes:
- `AppShell` constructs the `NavigationDestination` list at build time using `final l10n = AppLocalizations.of(context)!;` so labels are available at runtime and update when locale changes.
- This change was applied as part of the `i18n-arb-migration` plan (T12).

See also:
- `context/context-map.md` (linked to the router file)
- `lib/l10n/` for ARB files and the generated `AppLocalizations` class
