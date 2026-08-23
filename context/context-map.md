# FitFat — Context Map

| Area | File | Description |
|------|------|-------------|
| Overview | [overview.md](overview.md) | Project overview and design principles |
| Architecture | [architecture.md](architecture.md) | App shell layout, navigation, routing, database |
| Glossary | [glossary.md](glossary.md) | Domain terminology |
| Plans | [plans/barebone-crud-app.md](plans/barebone-crud-app.md) | Original CRUD implementation plan (completed) |
| Plans | [plans/app-i18n.md](plans/app-i18n.md) | App i18n — localization for all UI strings (completed) |
| Plans | [plans/daily-planner.md](plans/daily-planner.md) | Daily planner — per-day todo list for routine tracking (completed) |
| Plans | [plans/app-improvements.md](plans/app-improvements.md) | App-wide improvements batch: nutriments, search, due dates, body metrics, settings, notifications (completed) |
| Plans | [plans/ui-ux-improvements.md](plans/ui-ux-improvements.md) | App-wide UI/UX overhaul: design system, dashboard, empty states, interactions, delete/undo, locale dates, floating bar, a11y, platform polish (completed) |
| Plans | [plans/active-workout-flow.md](plans/active-workout-flow.md) | Active workout flow redesign: unique active view (`/active-workout`), rest per set (schema v5), summary (completed) |
| Plans | [plans/app-polish-batch.md](plans/app-polish-batch.md) | App polish batch: dashboard settings button, BW goal, quick-action chips, planner notes + day swipe, set decimals, active-workout back button, set completion time (completed) |
| Plans | [plans/remove-dashboard-quick-actions.md](plans/remove-dashboard-quick-actions.md) | Remove dashboard quick-action chips — weight/height entry only via the BodyMetricsCard (completed) |
| Plans | [plans/dashboard-calories-catalog-reminders.md](plans/dashboard-calories-catalog-reminders.md) | Dashboard rework (calorie ring, macros, weight trend, weekly volume), calorie target engine, exercise catalog + history/detail, planner due time + task reminders (completed) |
| Plans | [plans/exercise-filters-metadata.md](plans/exercise-filters-metadata.md) | Exercise search + tag filters, tabbed detail screen (History/Details), curated video subset, catalog metadata normalization + structured FAQs, importer refresh (completed) |
| UI | [ui/design-system.md](ui/design-system.md) | Design system: tokens, tuned light+dark themes, `FitFatColors`, `DateFormats`, shared widgets (incl. `EmptyState`), `lib/src/ui/` layout |
| Database | [database/schema.md](database/schema.md) | Full schema: tables, columns, types, generated code |
| Diet | [diet/ingredient-crud.md](diet/ingredient-crud.md) | Ingredient CRUD: repository, providers, screens, soft-archive semantics (v4) |
| Diet | [diet/meal-crud.md](diet/meal-crud.md) | Meal CRUD: repository, providers, screens |
| Exercise | [exercise/exercise-crud.md](exercise/exercise-crud.md) | Exercise definition CRUD + catalog: repository, providers, screens, search + filters, catalog build/import/refresh, tabbed detail screen (History/Details) |
| Exercise | [exercise/workout-crud.md](exercise/workout-crud.md) | Workout CRUD: repository, providers, screens, workflow |
| Dashboard | [dashboard/dashboard.md](dashboard/dashboard.md) | Dashboard: greeting header, calorie progress ring (consumed vs target), macro-targets progress, weight trend (Add weight/height), weekly workout volume/minutes, upcoming timed tasks, latest workout card, welcome hub |
| Body | [body/body-metrics.md](body/body-metrics.md) | Body metrics: weight/height table, model, repository, providers, dashboard card |
| Settings | [settings/settings.md](settings/settings.md) | App settings: theme mode, language, calorie profile (age/gender/activity/body-fat), body-weight goal, task-reminder toggle; shared_preferences storage |
| Notifications | [notifications/notifications.md](notifications/notifications.md) | Active-workout rest timer + ongoing foreground notification + planner task reminders (due-time + 30-min pre-reminder, Settings toggle, tap → Plan) + experiment check-in reminders (daily, tap → Experiments) |
| Planner | [planner/planner.md](planner/planner.md) | Daily planner: table, model, repository, providers, screens; optional due date + due time with reminders |
| Experiments | [experiments/experiments.md](experiments/experiments.md) | Experiments tab (v18): models, repository, providers, list/form/detail screens, daily check-in reminder, per-category charts vs 14-day baseline |
| Network | [network/network.md](network/network.md) | Decoupled HTTP layer (Phase E): ApiClient (`HttpApiClient`/`MockApiClient`) + `apiClientProvider`; FX endpoint seam `FX_API_BASE_URL` behind `FxRateRemoteService` |
| Performance | [performance.md](performance.md) | Perf guardrails: lazy tab branches (DeferredBranch), memoized workout-form catalog map, bulk history/stats queries, scoped tickers |
| Sync | [sync/sync-contract.md](sync/sync-contract.md) | Data-sync contract (v1 draft + MVP client shipped 2026-08-23): offline-first delta protocol, entity inventory, LWW conflict policy, device/account bootstrap, batch/idempotency guards; §11 records the implemented pull envelope — Bearer API key, `since=` cursor, full-payload exercises/ingredients (with nested pictures/prices + top-level stores), daily FX snapshots, and ingredient push |
