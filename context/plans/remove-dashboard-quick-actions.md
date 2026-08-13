# Plan: Remove dashboard quick-action chips (weight/height)

## Change Summary

After app-polish-batch, the dashboard had two duplicated weight/height entry points: the
quick-action chip row (`_QuickActions` — "Log weight" + "Log height") and the `BodyMetricsCard`
buttons ("Add weight" + "Add height"). This plan removes the quick-action chips entirely so
weight/height entry lives only in the `BodyMetricsCard`. The user approved full removal including
ARB-key cleanup (2026-08-10).

## Success Criteria

- The dashboard data-cards column no longer contains `_QuickActions` (no chip row between the hero
  card and the weekly-chart card).
- Weight/height entry exists only via the `BodyMetricsCard` "Add weight" / "Add height" buttons.
- `dashboardChipLogWeight` / `dashboardChipLogHeight` keys removed from all 3 ARBs; regenerated
  localizations compile.
- `dart analyze lib/` — zero errors; `flutter test` — passes; format check — exit 0.
- `context/` synced (dashboard.md, overview.md, context-map.md).

## Constraints & Non-Goals

- No schema/dependency changes, no new features, no git commit.
- `BodyMetricsCard` is untouched — its buttons, SnackBar, and provider invalidations already cover
  the removed chips' behavior.
- Manual UI verification deferred to the user (headless environment).

## Task stack

- [x] T01: `Remove _QuickActions + ARB cleanup` (status:done)
  - Task ID: T01
  - Goal: Delete the dashboard quick-action chip row; remove now-unused imports and ARB keys.
  - Boundaries (in/out of scope):
    - In: `lib/src/dashboard/screens/dashboard.dart` — remove `const _QuickActions(),` + its
      adjacent `SizedBox` from the data-cards column (~lines 70-71); delete the `_QuickActions`
      class (~lines 81-350: `_logWeight`, `_logHeight`, chip `build`); drop the now-orphaned
      imports `../../body/providers/body_metrics.dart` and
      `../../body/screens/body_metric_dialog.dart` (grep-confirmed used only by `_QuickActions`);
      keep `../../body/screens/body_metrics_card.dart` (`BodyMetricsCard()` stays last).
      `lib/l10n/app_en.arb` / `app_fr.arb` / `app_es.arb` — remove `dashboardChipLogWeight` and
      `dashboardChipLogHeight` (grep-confirmed unused app-wide outside generated l10n) +
      `flutter gen-l10n`.
    - Out: `BodyMetricsCard` (buttons/SnackBar/invalidations stay), other dashboard widgets,
      other ARB keys, schema/database, dependencies.
  - Done when: no `_QuickActions` in dashboard.dart; the two chip ARB keys absent from lib/ +
    test/; `flutter gen-l10n` exit 0; `dart analyze lib/` zero errors; `flutter test` passes;
    format check exit 0.
  - Verification notes (commands or checks):
    - `rg -n "dashboardChipLogWeight|dashboardChipLogHeight|_QuickActions" lib test` — no matches.
    - `rg -n "showBodyMetricDialog|bodyMetricsRepositoryProvider" lib/src/dashboard` — no matches
      (dashboard no longer touches body-metrics dialogs directly).
    - Manual (deferred): dashboard shows hero → weekly → latest-workout → plan → body-metrics; Add
      weight/height still works from the card.
  - Task ID: T01; Completed: 2026-08-10; Files changed: `lib/src/dashboard/screens/dashboard.dart`,
    `lib/l10n/app_en.arb`, `lib/l10n/app_fr.arb`, `lib/l10n/app_es.arb`, regenerated
    `lib/l10n/app_localizations*.dart`; Evidence: `flutter gen-l10n` exit 0; `dart analyze lib/`
    "No issues found!" exit 0; `flutter test` 1/1 "All tests passed!" exit 0;
    `dart format --output=none --set-exit-if-changed lib test` "0 changed" exit 0;
    `rg -n "dashboardChipLogWeight|dashboardChipLogHeight|_QuickActions" lib test` — no matches
    (exit 1); `rg -n "showBodyMetricDialog|bodyMetricsRepositoryProvider|bodyMetricsProvider|
    latestBodyMetricsProvider" lib/src/dashboard` — no matches (exit 1);
    `rg -n "BodyMetricsCard" lib/src/dashboard/screens/dashboard.dart` — still present (line 75);
    Notes: quick-action chip row removed — weight/height entry only via `BodyMetricsCard`; orphaned
    body-metrics imports dropped; `dashboardChipLogWeight` / `dashboardChipLogHeight` keys removed
    from all 3 ARBs and regenerated localizations.

---

## Next Command

```
PLAN COMPLETE — T01 done (2026-08-10). Deferred manual UI check: dashboard shows
hero → weekly → latest-workout → plan → body-metrics; Add weight/height still work from the card.
```
