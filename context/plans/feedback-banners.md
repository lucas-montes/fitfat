# Plan: Feedback banners — keep only deletion-undo

## Change Summary

The app uses a custom top banner (`showTopBanner` / `showTopBannerOverlay` in
`lib/src/ui/widgets/top_banner.dart`) for almost all feedback. Most of it is
confirmation noise ("saved", "added", "started", "completed", "copied",
"refreshed", "reset done", plain "deleted"). User decision (2026-08-17): keep
**only the banners that allow undoing a deletion**; remove the rest.

Assumption (user to veto if wrong): error banners (`errorWithMessage`) stay —
they are critical feedback, not noise.

## Success Criteria

- Only deletion-undo banners + error banners can ever appear.
- No dead l10n keys / unused helper imports left behind.
- `dart analyze lib/` zero errors; `flutter test` passes; `dart format` clean.

## Constraints & Non-Goals

- **No new dependencies.**
- Undo banners keep their Undo action and a generous display duration (~3.5 s).
- Do not touch the banner widget's mechanics beyond the default duration (3 s → 2 s).
- Non-goal: redesigning any toast/snackbar system beyond removing call sites.

## Task Stack

- [x] T01: `Remove non-undo banner call sites` (status:done)
  - Task ID: T01
  - Goal: Remove every `showTopBanner` / `showTopBannerOverlay` call that is not a
    deletion-undo banner or an error banner.
  - Boundaries (in/out of scope):
    - In: audit all call sites in `lib/src/`; delete confirmation-noise calls
      (commonSaved, workoutStarted, workoutCompleted, workoutDeleted without undo,
      copyDone, fxRefreshed, resetDataDone, exercise "added", etc.); keep undo calls
      (meal/workout/planner delete-undo, ingredient archive-undo) and error calls.
    - Out: changing undo behavior, changing the banner widget itself.
  - Done when: grep shows only undo + error banners remain; imports of
    `top_banner.dart` are only present where still needed; `dart analyze lib/` clean.
  - Verification notes (commands or checks):
    - `rg -n "showTopBanner|showTopBannerOverlay" lib/` — review each remaining call.
    - `dart analyze lib/`; `flutter test`.

- [x] T02: `Trim unused l10n keys + default banner duration` (status:done)
  - Task ID: T02
  - Goal: Delete l10n keys that became unreferenced (confirmed via grep) across
    en/fr/es ARBs + regenerate; lower the banner default duration to 2 s.
  - Boundaries (in/out of scope):
    - In: `lib/l10n/app_{en,fr,es}.arb` (remove dead keys), `flutter gen-l10n`,
      `lib/src/ui/widgets/top_banner.dart` (default `displayDuration` 3 s → 2 s).
    - Out: any remaining banner behavior changes.
  - Done when: no dead keys (grep each removed key returns 0 references in lib/);
    `flutter gen-l10n` exit 0; `dart analyze lib/` clean.
  - Verification notes (commands or checks):
    - `flutter gen-l10n`; `dart analyze lib/`.

- [x] T03: `Validation and context sync` (status:done)
  - Task ID: T03
  - Goal: Full checks + `context/` sync (ui/design-system.md or overview.md mention
    of banner feedback) + validation report.
  - Boundaries (in/out of scope):
    - In: `flutter analyze`, `flutter test`, `dart format --set-exit-if-changed`,
      context files, this plan's validation section.
    - Out: git commit.
  - Done when: suite green; context reads back accurate.
  - Verification notes (commands or checks):
    - `dart analyze lib/`; `flutter test`; `dart format --output=none --set-exit-if-changed lib test`.

## Validation Report (T03)

- `flutter analyze lib` → **No issues found**.
- `dart format --output=none --set-exit-if-changed <edited files>` → **clean** (0 changed).
- `flutter test` → pure-logic suites pass; the only failures are the pre-existing
  DB-backed tests that cannot load `libsqlite3.so` in this environment (missing native
  library, unrelated to this change).
- Context: added the banner-feedback policy to `context/ui/design-system.md`
  ("Feedback — top banner" section).

## Next Command

/next-task feedback-banners T03