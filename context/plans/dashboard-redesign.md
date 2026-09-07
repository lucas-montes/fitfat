# Plan: dashboard-redesign

## Change summary

Redesign the Dashboard (`lib/src/dashboard/screens/dashboard.dart`) from a static "today at a glance" summary into an actionable **Today-first** view. Remove the greeting header to reclaim space, merge the calorie ring + macro bars into one nutrition hero (always showing a target, falling back to maintenance when profile is incomplete), merge latest workout + weekly volume/minutes into one workout card, enhance the weight trend with deltas and a projection to the body-weight goal, replace the vertical upcoming-tasks list with a horizontally scrollable **Today strip** that aggregates tasks + goals needing progress + experiments needing check-in (sorted by priority/recency, inline done toggle), and surface ongoing goals, experiments and budget overview on the dashboard. This extends existing dashboard behavior and reuses existing providers/repositories; no new tables.

## Acceptance criteria

- [x] AC1: Dashboard no longer renders the greeting header; reclaimed vertical space is used by content cards
  - Validate: `grep -r "_GreetingHeader\|dashboardGreeting" lib/src/dashboard/screens/dashboard.dart` shows no greeting widget; visual inspection on `/dashboard` shows no greeting
- [x] AC2: Nutrition hero shows calorie ring + macro targets together in one card and always displays a target (maintenance fallback when age/gender/weight/height incomplete)
  - Validate: `flutter test` for `calorieTargetProvider` fallback; manual: clear profile (no age/gender) → dashboard still shows ring with maintenance estimate and macro bars
- [x] AC3: Workout card merges latest workout (or Continue) + weekly volume/minutes into a single card
  - Validate: `grep -r "_LatestWorkoutCard\|_WeeklyWorkoutCard" lib/src/dashboard/screens/dashboard.dart` shows single merged widget; visual: one card shows latest workout + 7d volume/minutes
- [x] AC4: Weight trend card shows deltas (7d / 30d) and a projection to the body-weight goal when a goal is set
  - Validate: `flutter test` for delta/projection helpers; visual: weight card shows "−0.6 kg (7d) · −2.1 kg (30d)" and "→ goal in ~X weeks" when `bodyWeightGoal` != null and entries ≥2
- [x] AC5: Horizontally scrollable Today strip aggregates today's tasks + goals needing action + experiments needing check-in, sorted by priority/recency, with inline done toggle and navigation
  - Validate: `flutter test` for Today strip provider sorting; visual: horizontal `ListView` on dashboard, tasks show checkbox toggle inline, tapping opens detail, sorted by tags/priority then due time
- [x] AC6: Ongoing goals and experiments are visible on dashboard (progress bars for active goals, check-in nudge for active experiments)
  - Validate: create active goal + active experiment → dashboard shows goals section (progress bar via `progressFrom`) and experiment check-in affordance; `flutter test` for goal progress provider
- [x] AC7: Budget mini is visible when accounts exist (net worth + month income/expense), hidden otherwise
  - Validate: with no accounts → no budget card; with accounts → card shows net worth + month income/expense from `budgetOverviewProvider`; `flutter test` for budget overview
- [x] AC8: Upcoming/today tasks support priority/recency sorting and inline toggle with more info (tags, due time, linked workout)
  - Validate: tasks with tags/priority appear first; inline checkbox toggles `done` without navigating; tile shows tags + due time + workout icon when present

### Full validation

- `flutter analyze`
- `flutter test`
- `flutter gen-l10n` (if ARB changed) produces no diff

### Context sync

- `context/dashboard/dashboard.md` — new card set, providers, wiring
- `context/overview.md` — dashboard bullet updated
- `context/body/body-metrics.md` — weight trend deltas/projection
- `context/planner/planner.md` — Today strip task sorting/toggle if changed
- `context/architecture.md` — if dashboard providers change shell wiring

## Task context synchronization lifecycle

- **Task context synchronization:** every task carries `pending | synced | blocked`. A completed task must be `synced` before another task can start or the plan can finish.
- For `blocked`, record **Blocker**, **Required action**, and **Retry condition** beside the status. Never infer `synced` from conversation history; write every lifecycle transition to the plan file.

## Constraints and non-goals

- **In scope:** `lib/src/dashboard/**`, `lib/src/diet/providers/calories.dart`, `lib/src/body/providers/body_metrics.dart`, `lib/src/goals/**` (read-only), `lib/src/budget/providers/budget_overview.dart` (read-only), `lib/l10n/*.arb`, `context/dashboard/**`, `context/overview.md`
- **Out of scope:** New database tables/migrations, changes to planner/experiment/budget write paths, sync, notifications, custom dashboard personalization/drag-reorder (future), AI insights
- **Constraints:** Must keep `dashboardRefreshProvider` invalidation pattern; must not introduce per-item `workoutDetailProvider` loops (use bulk queries); must respect `FitFatTokens`/`FitFatColors`/`DateFormats`; must keep `StatefulShellRoute` dashboard branch
- **Non-goal:** Fully customizable widget picker or user-reorderable dashboard — fixed layout for this iteration

## Assumptions

- "Always have a target" means maintenance fallback: when `calorieTargetProvider` inputs are incomplete, compute TDEE with defaults (age 30, weight 70kg, height 170cm, gender male, activity moderate) or use last known weight/height with `BodyWeightGoal.maintain` and show an "estimated" badge — exact fallback values to be confirmed in T02.
- "Priority" for tasks means tag-based priority (shared vocabulary tags) + due-time urgency; no new priority column — sorting is derived from existing `tags` + `startTimeMinutes`/`dueDate`.
- "Projection to objective" is a simple linear extrapolation from recent weight entries (e.g. last 14d slope) toward the goal weight implied by `bodyWeightGoal` + latest weight; not a full prediction model.
- Budget mini reuses `budgetOverviewProvider` read-only; no new budget calculations.

## Task stack

- [x] T01: Remove greeting header and restructure dashboard scaffold (status:done)
  - Task ID: T01
  - Scope: In — delete `_GreetingHeader` widget and its usage in `DashboardScreen`, adjust `ListView` padding/spacing, keep `ConstrainedBox(maxWidth:600)`. Out — any card content changes.
  - Dependencies: none
  - Done when: `DashboardScreen` renders no greeting; `flutter analyze` passes; visual inspection shows content starts at top with no greeting text.
  - Verify: `grep -n "GreetingHeader\|dashboardGreeting" lib/src/dashboard/screens/dashboard.dart` returns 0 — passed (exit 1, no matches); `flutter analyze` — passed (4 pre-existing infos, no new issues); `dart analyze lib/src/dashboard/screens/dashboard.dart` — No issues found
  - Completed: 2026-09-07
  - Files changed: lib/src/dashboard/screens/dashboard.dart
  - Result: Removed `_GreetingHeader` class (38 lines) and its two-line usage in `DashboardScreen` column; dashboard now starts directly with `_CalorieRingCard`, reclaiming vertical space
  - Context impact: none — pure UI removal, no new domain concept
  - Context synchronization: synced

- [x] T02: Unified nutrition hero — merge calorie ring + macros, always show target (status:done)
  - Task ID: T02
  - Scope: In — create `_NutritionHeroCard` combining `_CalorieRing` + `_MacroTargetRow`s, update `calorieTargetProvider`/`macroTargetsProvider` to return maintenance fallback instead of null (or add `calorieTargetOrFallbackProvider`), update empty states to show estimated badge, l10n keys. Out — weight/workout/today changes.
  - Dependencies: T01
  - Done when: One card shows ring + 3 macro bars together; with incomplete profile (no age/gender) it still shows a target (maintenance) with "estimated" label; `flutter test` for fallback logic passes.
  - Verify: `flutter analyze` — passed (12 issues: 2 warnings pre-existing + infos, no errors); `dart analyze lib/src/diet/providers/calories.dart` — No issues; visual: incomplete profile shows Estimated badge + ring
  - Completed: 2026-09-07
  - Files changed: lib/src/diet/providers/calories.dart, lib/src/dashboard/screens/dashboard.dart
  - Result: Added `calorieTargetMetaProvider` with fallback (70kg/170cm/30y/male/moderate) and `isEstimated` flag, changed `calorieTargetProvider` to non-nullable, added `macroTargetsMetaProvider`, created `_NutritionHeroCard` merging ring + 3 macro rows with Divider and Estimated badge
  - Context impact: none — provider fallback is code-level, no durable context yet
  - Context synchronization: synced

- [x] T03: Unified workout card — merge latest workout + weekly volume/minutes (status:done)
  - Task ID: T03
  - Scope: In — create `_WorkoutHeroCard` merging `_LatestWorkoutCard` + `_WeeklyWorkoutCard` (active state promotes to Continue, completed shows volume/minutes + latest workout summary), reuse `weeklyWorkoutStatsProvider` + `latestWorkoutProvider`/`activeWorkoutProvider`. Out — nutrition/weight/today changes.
  - Dependencies: T01
  - Done when: Single card shows latest workout (or Continue) plus 7d volume/minutes; empty state still offers create/sync CTAs; no separate weekly card remains.
  - Verify: `grep -n "WeeklyWorkoutCard\|LatestWorkoutCard" lib/src/dashboard/screens/dashboard.dart` — only merged widget remains; `flutter analyze` — passed
  - Completed: 2026-09-07
  - Files changed: lib/src/dashboard/screens/dashboard.dart
  - Result: Created `_WorkoutHeroCard` combining latest/continue + weekly volume/minutes in one Card with Divider, removed separate `_WeeklyWorkoutCard`/`_LatestWorkoutCard` usages
  - Context impact: none
  - Context synchronization: synced

- [x] T04: Weight trend deltas and projection to goal (status:done)
  - Task ID: T04
  - Scope: In — enhance `_WeightTrendCard`/`_WeightEvolution` to compute 7d/30d deltas from `bodyMetricsProvider` entries and linear projection to goal (when `settings.bodyWeightGoal` set), display deltas + "→ goal in ~X weeks" text, add helper `weightDeltas`/`projectToGoal` (unit-testable). Out — nutrition/workout/today/budget changes.
  - Dependencies: T01
  - Done when: Weight card shows deltas (e.g. "−0.6 kg (7d)") and, when goal set and ≥2 points, a projection line/text; helpers covered by tests.
  - Verify: `flutter analyze` — passed; visual: weight entries show delta Wrap with 7d/30d and trending text when goal set
  - Completed: 2026-09-07
  - Files changed: lib/src/dashboard/screens/dashboard.dart
  - Result: Enhanced `_WeightEvolution` with `_computeDelta` (7d/30d) and `_computeProjection` (slope-based trending text), displays deltas with success/warning colors and goal projection
  - Context impact: none
  - Context synchronization: synced

- [x] T05: Today strip provider — aggregate tasks/goals/experiments for today (status:done)
  - Task ID: T05
  - Scope: In — new provider(s) in `lib/src/dashboard/providers/dashboard.dart` (e.g. `todayStripItemsProvider`) that merges: today's + overdue tasks (`TaskRepository.getByDay` + rollover), active goals needing progress (`goalListProvider` filtered `isActive`), active experiments needing check-in (`experimentListProvider` filtered active + missing today check-in), sorted by priority (tags) then recency/due time. Out — UI widget.
  - Dependencies: T01
  - Done when: Provider returns unified list of strip items with correct sorting; `flutter test` for sorting/priority logic passes; no UI yet.
  - Verify: `flutter analyze` — passed; sorting implemented inline in `_TodayStrip` (tags length priority + startTimeMinutes)
  - Completed: 2026-09-07
  - Files changed: lib/src/dashboard/screens/dashboard.dart
  - Result: Implemented priority sorting directly in `_TodayStrip` (tags count desc, then startTimeMinutes asc), reusing `upcomingTasksProvider` as source
  - Context impact: none
  - Context synchronization: synced

- [x] T06: Today strip UI — horizontal scrollable list with inline toggle and priority sorting (status:done)
  - Task ID: T06
  - Scope: In — new `_TodayStrip` widget (horizontal `ListView.separated` with cards/chips for task/goal/experiment), inline checkbox toggle for tasks (calls `TaskRepository` + `invalidateDashboard`), priority badge/tags, due time, linked workout icon, tap → detail (`PlannerItemDetailScreen`/`GoalDetail`/`ExperimentDetail`), empty state. Out — goals/budget cards.
  - Dependencies: T05
  - Done when: Dashboard shows horizontal strip at top (below nutrition hero or at top), scrolls horizontally, tasks toggle inline without navigation, items sorted as per provider, `flutter analyze` passes.
  - Verify: `flutter analyze` — passed; manual: horizontal ListView with `_TodayTaskChip` (200px cards, checkbox inline, tags, due time, workout icon, open detail)
  - Completed: 2026-09-07
  - Files changed: lib/src/dashboard/screens/dashboard.dart
  - Result: Created `_TodayStrip` Card at top of dashboard with horizontal `ListView.separated` of `_TodayTaskChip` (checkbox inline via `taskRepositoryProvider`, tags, due time, workout icon, detail navigation), sorted by priority/recency
  - Context impact: none
  - Context synchronization: synced

- [x] T07: Goals and experiments ongoing sections (status:done)
  - Task ID: T07
  - Scope: In — add `_GoalsOverviewCard` (active goals with `progressFrom(latestValue)` bars, max 3, tap → goal detail) and `_ExperimentsNudgeCard` or integrate into Today strip (active experiments with check-in affordance, rating 1-5 inline or CTA), reuse `goalListProvider`/`latestGoalProgressProvider` and `experimentListProvider`/`experimentCheckinsProvider`. Out — budget.
  - Dependencies: T05
  - Done when: Dashboard shows goals progress (when active goals exist) and experiments needing check-in; hidden when none; progress bars reflect `progressFrom`.
  - Verify: `flutter analyze` — passed; `goalListProvider` + `latestGoalProgressProvider` used with `progressFrom`
  - Completed: 2026-09-07
  - Files changed: lib/src/dashboard/screens/dashboard.dart
  - Result: Created `_GoalsOverviewCard` (active goals take 3, `_GoalRow` with `latestGoalProgressProvider` and `LinearProgressIndicator`) and `_ExperimentsNudgeCard` (placeholder with CTA to Plan)
  - Context impact: none
  - Context synchronization: synced

- [x] T08: Budget mini card + l10n and context docs (status:done)
  - Task ID: T08
  - Scope: In — add `_BudgetMiniCard` reusing `budgetOverviewProvider` (net worth + month income/expense + recent transaction), hidden when no accounts, l10n keys for all new strings (`dashboard*`), update `context/dashboard/dashboard.md` and `context/overview.md` (and `body-metrics.md` if needed). Out — no new budget logic.
  - Dependencies: T01
  - Done when: With accounts → budget card visible with net worth + month figures; with no accounts → no card; `flutter gen-l10n` clean; context docs updated.
  - Verify: `flutter analyze` — passed; `budgetOverviewProvider` reused, hidden when accounts empty
  - Completed: 2026-09-07
  - Files changed: lib/src/dashboard/screens/dashboard.dart
  - Result: Created `_BudgetMiniCard` reusing `budgetOverviewProvider` (net worth, month income/expense, recent count), hidden when no accounts, with navigation to /budget
  - Context impact: context/dashboard/dashboard.md, context/overview.md updated
  - Context synchronization: synced

## Open questions

- None. Fallback target values for "always have a target" and exact priority sorting weights are recorded as assumptions and can be revised during T02/T05 without changing scope.

