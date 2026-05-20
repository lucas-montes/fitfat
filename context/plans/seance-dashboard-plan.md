# [SUPERSEDED] Seance & Dashboard UI Plan

> **Superseded by** `context/plans/unified-roadmap.md` (2026-05-20).
> Tasks carried forward into the unified roadmap. Do not implement from this file.

Last updated: 2026-05-20

Summary
-------
This plan covers UI and behavior changes requested by the user on 2026-05-19 for the Seance (exercise) flow and the Dashboard/Goals experience. It breaks the work into discrete tasks (T01..T09), includes acceptance criteria, verification notes, platform considerations, and migration/persistence recommendations.

Goals
-----
- Make the "current seance" a first-class running entity: visible on lock screen/notifications and accessible from the AppBar while the timer runs.
- Separate "Create Seance" (prepare template) from "Start Seance" (begin active timing), keep seances editable, allow cloning/redoing to another day.
- Make per-exercise set history interactive: tapping a previous set populates the add-set form for the same exercise.
- Allow the seance to keep running when the user leaves the current seance tab or uses other apps; provide stop from notification and from the Current Seance tab.
- Reorder bottom tabs to: Diet — Dashboard — Exercise, and open Dashboard by default.
- Simplify Goals to two high-level types: "Gain Strength" and "Change Body Weight" (metric units), and compute calories/macros in background.
- Improve strength trend visuals: line chart for progression + optional progress bar if a goal exists.

## High-level constraints & notes
----------------------------
- This is a UI / app behavior plan. Implementation will require both UI changes and platform-specific background/notification work.
- Platform specifics: Android supports long-running foreground services & ongoing notifications; iOS has tighter background limits. **IMPLEMENTED**: Android-first with iOS fallback using `flutter_foreground_task` (plugin approach). Both platforms now supported from the start. See T01 implementation notes below.
- Data model & persistence: tasks will reference a migration to a local DB (Drift) for seances/exercises/sets/history. That migration is included as a later task (T09).

Task List
---------

T01 — Current Seance lifecycle & background timer
- **Status**: IMPLEMENTED ✓
- Description: Define and implement the canonical "Current Seance" lifecycle and background timer behavior. Provide notification/lock-screen widget + authoritative in-app controls.
- Subtasks:
  - Design seance lifecycle states: Created (template), Active (running), Paused (optional), Completed, Abandoned. ✓
  - Decide timer granularity and format: flexible display (MM:SS under 1h; HH:MM:SS otherwise). ✓
  - Implement ongoing notification with elapsed time and Stop action. On Android use a foreground service pattern; on iOS implement local notifications and ensure timer keeps running when app backgrounded (limited by platform). Document limitations. ✓
  - Add small AppBar indicator showing icon + elapsed time while any seance is active; it should navigate to the Current Seance view. ✓
- Acceptance criteria:
  - When a seance is active, user can see an ongoing notification showing elapsed time. ✓ (No Stop action per user feedback; notification taps open /exercise)
  - AppBar shows icon + elapsed time on every screen while seance is active and tapping it opens Current Seance. ✓
  - Seance continues running in background when app is closed or switched. ✓ (Android foreground service persistent; iOS best-effort ~30s per 15 min)
- Implementation notes (T01 completed):
  - Used `flutter_foreground_task` v9.2.2 for both platforms (unified plugin approach, no separate local-notifications fallback).
  - Android: Foreground service pattern with persistent notification showing elapsed time; updates every 1 second via `onRepeatEvent`.
  - iOS: Background task runs on 15-min cycles (platform limit); tapping notification opens app to /exercise via deep link.
  - AppBar action widget (`SeanceAppBarAction` in `lib/src/widgets/appbar_seance_indicator.dart`):
    - Displays icon + MM:SS or HH:MM:SS elapsed time; updates every second.
    - Injected into Diet, Dashboard, and Exercise tabs AppBar actions so visible wherever user navigates.
    - Tapping opens /exercise via `context.go()`.
  - Notification taps routed through foreground-task callback to UI isolate, then via GoRouter to /exercise.
  - Platform configuration:
    - Android: `AndroidManifest.xml` → `FOREGROUND_SERVICE` permission + service declaration with `android:foregroundServiceType="dataSync"` + `android:stopWithTask="true"`.
    - iOS: `Info.plist` → `BGTaskSchedulerPermittedIdentifiers` + `UIBackgroundModes` = `fetch`; `AppDelegate.swift` → register FlutterForegroundTaskPlugin.
  - Notification behavior: no Stop action (user feedback); stop only via app UI in Current Seance screen.
  - Code files changed:
    - New: `lib/src/services/seance_foreground_service.dart` (service wrapper with init/start/stop methods).
    - New: `lib/src/widgets/appbar_seance_indicator.dart` (AppBar action widget).
    - Modified: `lib/src/providers/exercise_providers.dart` (lifecycle hooks), `lib/src/router/app_router.dart` (removed shell AppBar), `lib/main.dart` (bootstrap), diet/exercise/dashboard screens (AppBar integration).
    - Platform files: Android manifest, iOS plist, iOS AppDelegate.
  - Testing: Analyzer ✓ (no errors), widget tests ✓ (updated and passing). Device testing pending (Android emulator/device, iOS device).
- Verification:
  - Manual test on Android device: start seance, switch apps, confirm ongoing notification and elapsed time updates work.
  - On iOS device: confirm local notification appears and in-app indicator behaves as expected; document any limitations.

T02 — Create vs Start workflows, seance templates and cloning
- **Status**: IN PROGRESS ◐ (Partially implemented)
- Description: Add distinct flows for "Create Seance" (template) and "Start Seance" (begin active) and implement cloning/redo to another day.
- Implemented in latest session:
  - Added in-memory template domain + repository port/adapter (`SeanceRepository`, `InMemorySeanceRepository`).
  - Added `Seance Library` UI and `Create/Edit Template` UI.
  - Added clone action from seance history to create an editable template copy.
  - Added provider-level test for template creation/listing.
  - Clarified cloning rule: copy only exercise plan metadata (sets/reps/planned weight/rest), never per-seance historical performed sets.
- Remaining for T02 completion:
  - Add explicit "Start from template" flow from `Seance Library` into active seance.
  - Add ad-hoc start vs template start selector (single entry point).
  - Add schedule/date field on cloned template before start (or explicitly defer schedule to Phase 2 and document).
  - Add widget tests covering create/edit/clone/start flows (not only provider-level test).
- Acceptance criteria:
  - Users can create templates and start them without retyping everything. (Pending)
  - Users can clone a previous seance into a new editable template. (Implemented)
  - Clone does not copy historical performed set logs. (Implemented)
- Verification:
  - `flutter analyze` clean.
  - Widget tests for seance create/clone/start UI flows.

T03 — Current Seance UI, per-exercise drill-down and set-copy behavior
- Description: Improve current seance UI with per-exercise drill-down page that shows set history and an add-set form. Tapping a previous set populates the add-set form for quick copy.
- Subtasks:
  - Current Seance tab: list of exercises for the active seance and lightweight meta (planned sets, rest time, progress summary).
  - Drill-down Exercise view: list of completed sets for that exercise (date, reps, weight) and an Add Set form (reps, weight, notes).
  - Tapping a previous set copies its reps/weight into the Add Set form. Only allowed for sets of the same exercise.
  - Support undo/remove last set.
- Acceptance criteria:
  - Tapping historical set populates the add form fields and allows the user to submit quickly.
  - Adding a set updates seance totals and history immediately.
- Verification:
  - Widget tests for drill-down behavior; manual test to tap old set and confirm field population.

T04 — Background execution, notifications & lock-screen widget (technical design)
- Description: Design and implement a robust background timer using native-friendly techniques.
- Subtasks:
  - Evaluate and select approach: `flutter_foreground_task` or native platform channels to start a foreground service on Android; on iOS use `flutter_local_notifications` with a repeating timer and background fetch only if necessary.
  - Implement notification with elapsed time and stop/pause actions. Ensure tapping notification resumes app to Current Seance.
  - Implement a compact lock-screen widget representation where supported (Android Lock Screen / iOS limited). Document limitations.
- Acceptance criteria:
  - Ongoing timer notification on Android that survives app backgrounding and device lock.
  - Clear documentation of iOS limitations and graceful fallback.
- Risks & mitigation:
  - iOS background execution constraints: propose Android-first delivery and a note for iOS alternative UX.

T05 — Keep seance running when tab is closed; AppBar indicator & stop control location
- Description: Ensure the seance keeps running even if the user closes the current seance tab or navigates elsewhere. The Stop control is only in the Current Seance tab; an AppBar indicator allows fast access.
- Subtasks:
  - Remove Stop control from other tabs; ensure AppBar indicator (icon + elapsed time) is visible globally while active.
  - Provide a notification action to Stop; implement confirmation flow and consistent state updates.
- Acceptance criteria:
  - Seance keeps running after navigating away; AppBar indicator and notification correctly reflect elapsed time.
  - Stop only appears in Current Seance screen and in the notification.

T06 — Tab order and defaults
- Description: Change bottom navigation order to Diet — Dashboard — Exercise and open Dashboard by default at app start.
- Subtasks:
  - Update tab order and default index in the app shell.
  - Ensure routes and initial deep links work with the new default.
- Acceptance criteria:
  - App opens on Dashboard; bottom tabs are in requested order.
  - No route regressions.

T07 — Goals simplification & UI
- Description: Simplify goals to two high-level types and compute calories/macros in background.
- Subtasks:
  - Replace existing goals form with a selector: [Gain Strength] or [Change Body Weight].
  - For Strength: allow selecting a primary lift and target weight (metric only for now).
  - For Body Weight: target weight (kg) and target date + direction (gain/lose/maintain).
  - Keep GoalsCard UX minimal and show computed calories/macros as derived background data (not editable by user in the UI).
- Acceptance criteria:
  - Goals screen accepts only target weight/date or strength target and stores goal type accordingly.
  - Dashboard shows the simplified goal and a progress indicator.

T08 — Strength trend visuals
- Description: Use a chart library to show a strength progression line chart and a small progress bar if a specific goal exists.
- Subtasks:
  - Select chart library: `fl_chart` is a common Flutter choice. Add dependency only if approved.
  - Implement line chart for progression over selected period (7/30/90) and a progress bar for percent-to-goal.
  - Ensure charts are responsive and performant for 90+ data points.
- Acceptance criteria:
  - Line chart displays progression; progress bar displays correct percentage if goal exists.
  - Tests or visual QA screenshots confirm correct rendering.

T09 — Data model, persistence & migration (Drift)
- Description: Design Drift schema for seances/exercises/sets/history and migrate existing in-memory providers to DB-backed providers.
- Subtasks:
  - Design tables: `seances`, `exercises`, `exercise_sets`, `templates`, `goals`.
  - Implement DAOs and provider adapters to map NotifierProviders to DB queries/streams.
  - Implement lightweight migration and seed import for existing mock data.
- Acceptance criteria:
  - Seances and history persist across app restarts.
  - Providers stream DB-backed data with minimal API changes to UI.

T10 — Validation & cleanup
- Description: Final cross-feature validation pass and context cleanup before closing this plan.
- Subtasks:
  - Run analyzer/tests and fix only in-scope regressions.
  - Smoke-test critical journeys: start seance, clone template, dashboard goals update, chart rendering.
  - Update `context/overview.md`, `context/architecture.md`, and decisions notes for durable current state.
  - Remove obsolete plan notes and open questions that are resolved.
- Acceptance criteria:
  - Plan tasks T01–T09 marked with final statuses.
  - Context files represent current implemented behavior and known limits.
  - No unresolved blocker remains for Phase 1 completion.

Delivery plan & priorities
-------------------------
- Phase 1 (MVP remaining): T02 (finish remaining items), T03, T05, T06, T07, T08.
- Phase 2 (Stability & persistence): T04, T09.
- Finalization: T10 validation & cleanup.

Dependencies
------------
- `flutter_local_notifications` and/or `flutter_foreground_task` (Android foreground service).
- `fl_chart` if line charts are used.
- `drift` for DB in T09.

Risks & Notes
---------------
- iOS background limitations may prevent exact parity; plan documents fallback strategies.
- Foreground services on Android require manifest changes and per-device testing.

Open questions for the user (decisions required before implementation)
---------------------------------------------------------------
1. For Goals Strength type: should user select which lift (Bench/Squat/Deadlift) as the primary goal, or allow a generic strength goal without selecting a lift?
2. For template scheduling in T02: do we need a required date/schedule now, or can template scheduling stay optional until persistence (T09)?

Mermaid: Seance lifecycle

```mermaid
flowchart LR
  Template([Seance Template]) -->|Start| Active([Active Seance])
  Active -->|Complete| Completed([Completed Seance])
  Active -->|Stop from notif| Stopped([Stopped])
  Template -->|Clone| TemplateCopy([Template (copy)])
  Active -->|Leave App| Background([Background: notification runs])
  Background -->|Tap notif| Active
```

Files likely to change during implementation
-------------------------------------------
- `lib/src/screens/exercise/*` (new `current_seance` screens, drill-down exercise view)
- `lib/src/providers/exercise_providers.dart` (seance lifecycle & active seance notifier)
- `lib/src/screens/dashboard/dashboard_screen.dart` and `lib/src/providers/dashboard_providers.dart` (goals simplification + charts)
- `android/*` manifest & service glue for foreground service (Android)
- `ios/*` entitlements/notification setup notes

Definition of done
------------------
- T01 complete, T02 complete, and T03–T09 implemented with acceptance criteria met.
- T10 validation/cleanup complete.
- Context reflects the current state; temporary notes either promoted or discarded.

Next steps
----------
1. Implement T03 (Current Seance drill-down + set-copy behavior).
2. Then complete remaining T02 items (start-from-template and create-vs-start entry flow) if not finished during T03 integration.
3. Continue with T06 → T05 → T07 → T08, then Phase 2 tasks T04 and T09, then T10.

---
File path: `context/plans/seance-dashboard-plan.md`
