# FitFat — Context Map

| Area | File | Description |
|------|------|-------------|
| Overview | [overview.md](overview.md) | Project overview and design principles |
| Architecture | [architecture.md](architecture.md) | App shell layout, navigation, routing, database, data sync |
| Glossary | [glossary.md](glossary.md) | Domain terminology |
| Patterns | [patterns.md](patterns.md) | Placeholder — reserved for recurring implementation patterns; nothing recorded yet |

## Domain context
| Area | File | Description |
|------|------|-------------|
| Database | [database/schema.md](database/schema.md) | Full schema: tables, columns, types, generated code, and the migration history up to the current version |
| UI | [ui/design-system.md](ui/design-system.md) | Design system: tokens, tuned light+dark themes, `FitFatColors`, `DateFormats`, shared widgets (incl. `EmptyState`), `lib/src/ui/` layout |
| Diet | [diet/ingredient-crud.md](diet/ingredient-crud.md) | Ingredient CRUD: repository, providers, screens, soft-archive semantics |
| Diet | [diet/food-crud.md](diet/food-crud.md) | Food CRUD: the `meal → food → ingredient` layer, per-100g resolution, repository, providers, screens |
| Diet | [diet/meal-crud.md](diet/meal-crud.md) | Meal CRUD: repository, providers, screens |
| Exercise | [exercise/exercise-crud.md](exercise/exercise-crud.md) | Exercise definition CRUD + catalog: repository, providers, screens, search + filters, the server-synced catalogue, tabbed detail screen |
| Exercise | [exercise/workout-crud.md](exercise/workout-crud.md) | Workout CRUD: repository, providers, screens, workflow, active workout, summary |
| Dashboard | [dashboard/dashboard.md](dashboard/dashboard.md) | Dashboard: today strip, nutrition hero, weight trend, workout hero, goals overview, budget mini, welcome hub |
| Body | [body/body-metrics.md](body/body-metrics.md) | Body metrics: weight/height table, model, repository, providers, dashboard card |
| Settings | [settings/settings.md](settings/settings.md) | App settings: theme mode, language, calorie profile (age/gender/activity/body-fat), body-weight goal, task-reminder toggle; shared_preferences storage |
| Notifications | [notifications/notifications.md](notifications/notifications.md) | Active-workout rest timer + ongoing foreground notification + planner task reminders (due-time + 30-min pre-reminder, Settings toggle, tap → Plan) |
| Planner | [planner/planner.md](planner/planner.md) | Daily planner: table, model, repository, providers, screens; optional due date + due time with reminders; recurring series and carry-over |
| Network | [network/network.md](network/network.md) | Decoupled HTTP layer (`ApiClient`/`HttpApiClient`/`MockApiClient` + `apiClientProvider`); no phone-side FX endpoint: rates come from the sync server |
| Performance | [performance.md](performance.md) | Perf guardrails: lazy tab branches (DeferredBranch), memoized workout-form catalog map, bulk history/stats queries, scoped tickers |
| Sync | [sync/sync-contract.md](sync/sync-contract.md) | Data-sync contract (v1 draft + the implemented pull envelope): offline-first delta protocol, entity inventory, LWW conflict policy, device/account bootstrap, batch/idempotency guards |

## Plans

Every plan in `context/plans/` carries a `**Status:**` line directly under its
title. That line — not the checkboxes — is the authoritative statement of
whether the work shipped. A plan can be `completed` with a task still
unchecked when that task was verified only by inspection or is a device-side
manual check.

### In progress
| Plan | Status | Description |
|---|---|---|
| `food-group-redesign` | in progress | Meal history as day cards with the macro bar, the meal editor without names, recipe cards with eaten grams, the recipe table form, ingredient cards and the tabbed ingredient detail |
| `selective-sync-catalog` | code complete, manual QA outstanding | The minimal catalogue tables, the server catalogue endpoints, the background refresh, the bulk-vs-selective menus and the hub de-duplication all shipped. The four acceptance criteria are device-side checks: AC1/AC3/AC4 were verified by inspection only, and AC2's automated test (`test/catalog_selective_sync_test.dart`) compiles but has never executed in this environment |
| `task-carryover-notifications-fix` | code complete, manual device QA outstanding | The rollover ordering, the reminder rescheduling for rolled tasks, the reminder lifecycle on task mutations, the settings-based default time for untimed tasks and the exact-alarm fallback all shipped. All five acceptance criteria are device checks that have not been run |
| `settings-additions` | partially implemented | The units, the backup/export and the body-weight goal shipped; the FX auto-refresh toggle and its interval are absent, and no longer wanted: the server pulls rates itself (2026-11-20) |
| `dashboard-redesign` | partially implemented | The nutrition and workout hero cards, the weight trend, the today strip and the goals overview shipped. The experiments nudge card is impossible (the feature was removed in schema v37) and the projection reads "trending down" rather than "goal in ~X weeks" |
| `dashboard-calories-catalog-reminders` | partially implemented | The calorie target engine, the exercise history/detail tabs and the task reminders shipped. The progress "ring" is now bars, and the bundled `assets/exercises.db` seeding is gone — the catalogue now arrives by server sync |
| `rest-timer-data-reset-catalog-polish` | partially implemented | The count-up rest timer, the rest alarm, the data reset and the Notes tab shipped; "reset re-imports the bundled catalogue" cannot work because there is no bundled catalogue any more |
| `ui-ux-improvements` | largely implemented | The design system, the empty states, the delete/undo flow, the locale dates and the a11y work shipped, but hardcoded `Colors.green` remain in five screens |
| `app-polish-batch` | completed with one deviation | Set values always print one decimal, rather than only when fractional (`formatWeightValue` in `lib/src/ui/units.dart`) |
| `appbar-declutter` | partially implemented | The feature it declutters, "copy previous day", no longer exists anywhere in the app, and the planner appbar now shows a two-segment control rather than a More menu |
| `daily-planner` | partially implemented | The planner tab, per-day CRUD, reordering and persistence shipped; "copy from previous day" is gone, superseded by recurrence and carry-over |

### Completed
| Plan | Description |
|---|---|
| `exercise-group-redesign` | The training home (Recent + Templates rows), weekly history, template cards, workout detail with rest and calories, exercise search with facet dropdowns and the restyled exercise detail (2026-11-27) |
| `barebone-crud-app` | The original CRUD implementation, since heavily superseded (six tabs, 40 tables) |
| `app-improvements` | The app-wide batch: nutriments, meal-form search, due dates, body metrics, the profile, theme and language, the foreground notification, the rest timer |
| `active-workout-flow` | The active workout redesign: the unique `/active-workout` route, per-set rest (schema v5), the workout summary |
| `active-workout-redo` | The exercise cards (notes, media, fact chips, history) and the set rows (no number, stacked plan/actual, progress colouring) |
| `active-workout-declutter` | The merged top card, the rest-to-current-exercise jump, the set markings |
| `workout-replay` | The routine id, the replay action and the prefill preference |
| `exercise-detail-rework` | The exercise detail summary row, the trend chart and the History/Details tabs |
| `exercise-filters-metadata` | The type/body-part/equipment/muscle filters, the tabbed detail screen, the metadata normalisation. The curated-video allowlist and its asset pipeline live outside `lib/` |
| `foods-meal-food-ingredient` | Normalising the diet to `meal → food → ingredient`, with the per-100g resolution and the food form |
| `ingredient-metadata` | Barcode, brand, stores, prices and pictures on an ingredient; the planned mock scanner was replaced by a real scanner plus a server-side Open Food Facts lookup |
| `calorie-macro-phases` | The named-step calorie derivation, the configurable cutting/bulking/maintenance phases and the uniform dashboard row |
| `planner-task-detail` | The planner task detail view and the route-based editor |
| `recurring-task-scope` | "This one" / "This and all following" for editing and deleting a recurring series |
| `remove-dashboard-quick-actions` | Removing the dashboard quick-action chips — weight and height are entered only through the body-metrics card |
| `quick-wins` | The vertical planned-set column and the 48x48 picker thumbnails |
| `notification-timers` | The event-driven notification refresh and the resume resync |
| `notification-lock-screen` | The rest-timer notification on the lock screen (public visibility + alarm category) |
| `settings-rework` | Settings as a hub of five sub-screens, with the System language segment that clears the stored locale |
| `network-client` | The decoupled, mockable HTTP layer (`ApiClient` / `HttpApiClient` / `MockApiClient`) |
| `picker-server-fetch-fix` | The API timeout, the loading spinners and the friendly failure banner |
| `qr-server-config` | Scanning a pairing QR, validating the URL/key/duplicates and auto-testing the server |
| `sync-picker-reuse` | The shared picker reused across the sync flows |
| `multi-server-secure-link` | Several server profiles with one active, the QR scan and the `/health` test; API keys in `flutter_secure_storage`, moved out of plain prefs on first start (2026-11-22) |
| `app-i18n` | Every user-facing string reads from `AppLocalizations` in en/fr/es (finished 2026-11-22); notification channel names and data-layer exception text stay English |
| `feedback-banners` | Only deletion-undo, error, validation and "nothing to pick" banners remain (finished 2026-11-22) |
| `sync-import-export` | The sync hub, personal-pool push/pull and JSON backup export/import; the whole-SQLite export was dropped and the dead `user_data_sync_client.dart` deleted (2026-11-22) |
| `sync-contract` | The offline-first delta contract, the entity inventory, the LWW policy and the implemented pull envelope |
| `performance` | The isolated elapsed ticker, the debounced picker, the bulk set query and the bulk weekly stats |
| `performance-startup-edit` | The deferred tab branches and the cached workout-form exercise map |
| `fx-display` | The rate display. The manual-override marker and edit dialog were removed 2026-11-20, because rates come only from the server |

## Dropped plans
| Plan | Why it was dropped |
|---|---|
| `composite-ingredients` | The `ingredient_components` schema (v33) was dropped in v34 and the capability re-architected as `meal → food → ingredient`; see `foods-meal-food-ingredient` |
| `experiments` | The feature was removed from the app entirely — schema v37 drops `experiments`, `experiment_checkins` and their junction tables. The server still carries the tables, so the desktop's Experiments tab is the one loose end (see `ui-unified-tabs` in the server repo) |
