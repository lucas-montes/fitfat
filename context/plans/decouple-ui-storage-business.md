# Plan: Decouple Views/UI from Storage and Business Logic

Purpose
- Decouple UI (views/widgets) from storage (CRUD) and business logic (reactive workflows, validations, use-cases). The result should make screens simple list-driven UIs that call into a small set of controllers/use-cases. Controllers encapsulate event handling, orchestration, and side-effects, and depend only on repository interfaces.

Goals
- Clear separation: UI <-> Controller (business) <-> Repository (storage).
- Keep storage layer simple: CRUD + optional watch streams.
- Business layer exposes stable state models and event methods for the UI to call; the UI mustn't call repositories directly.
- Minimal runtime changes: no DB schema changes; adapters map to the existing Drift `AppDatabase`.
- Incrementally replace screens: start with diet Meals list as a low-risk proof.

Three-layer architecture (concept)
- UI layer (views/widgets)
  - Very thin: renders state and calls controller methods on user actions.
  - Receives UI-specific view models (DTOs) from controllers.

- Business layer (controllers / use-cases)
  - Exposes state (immutable) plus command methods for UI events.
  - Converts repository streams/futures into stable UI state.
  - Handles validation, optimistic updates, background tasks, and cross-feature orchestration (e.g., when a seance completes, update goals).
  - Implemented with Riverpod `StateNotifier`, `AsyncNotifier`, or `Notifier` depending on complexity.

- Storage layer (repositories & adapters)
  - Pure CRUD + optional `watch*` streams.
  - Implemented by `Drift*Repository` adapters inside `lib/src/adapters/drift/` that map tables ↔ domain models.

Design patterns & Riverpod mapping
- Controller pattern: a controller is a `StateNotifier<ControllerState>` or `AsyncNotifier<ControllerState>` exposing methods for UI events.
- Providers:
  - `Provider<MealRepository>` — repository instance (Drift adapter)
  - `Provider<MealController>` or `StateNotifierProvider<MealController, MealState>` — business controller
  - UI uses `ref.watch(mealControllerProvider.select((s) => s.items))` to rebuild minimal parts
- For cross-cutting events, use a `Provider<EventBus>` backed by a `StreamController.broadcast()` so services/controllers can subscribe without tight coupling.

Example: Meals feature

- Repository interface (already present) — `MealRepository` with `getMealsForDay`, `watchMealsForDay`, `saveMeal`, `deleteMeal`.

- Controller (new): `MealListController extends StateNotifier<MealListState>`
  - State shape:
    - `MealListState { status: Idle|Loading|Data|Error, List<MealViewModel> meals, DateTime day, String? errorMessage }`
  - Methods:
    - `Future<void> load(DateTime day)` — loads initial data (sets Loading → Data)
    - `Future<void> refresh()` — reload or re-fetch
    - `Future<void> addMeal(MealInput)` — validates and calls repo.save; on success update state (optimistic option)
    - `Future<void> updateMeal(String id, MealInput)`
    - `Future<void> deleteMeal(String id)` — confirm, call repo.delete, update state
    - `void subscribe()` — subscribes to `repo.watchMealsForDay(day)` and updates state when underlying data changes

- UI Usage (MealsTab):
  - Uses `StateNotifierProvider.family` or `StateNotifierProvider` with `MealListController`.
  - Widgets call controller methods (e.g., `ref.read(mealControllerProvider.notifier).addMeal(input)`).
  - Widgets render `ref.watch(mealControllerProvider)` and show loading / error / list.

Why controllers? (benefits)
- Isolate validation and orchestration code in testable units.
- UI doesn't need to know about streams or repositories — simpler tests and less boilerplate in widgets.
- Controllers can provide view-models optimized for UI (e.g., formatted calories, localized strings) while keeping domain models pure.

Optimistic updates & failures
- Controller can optionally apply optimistic updates (update UI before persistence), and revert on error with an informative message. This is a controller-level decision.

Cross-feature orchestration
- Use the EventBus or a global notifier for app-wide events (seance started, seance stopped, seance complete). Keep bus usage explicit and minimal.

Incremental implementation plan

T1: Define controller API & provider wiring (planning)
  - Pick the first feature (Meals list) and draft `MealListController` API and state model under `context/plans/`.

T2: Implement in-app adapters (Drift) — read-only first
  - Implement `DriftMealRepository.watchMealsForDay` and `getMealsForDay` mapping rows → domain models. Put this in `lib/src/adapters/drift/drift_meal_repository.dart`.

T3: Implement `MealListController` using the repository provider
  - Add `lib/src/providers/repositories.dart` and `lib/src/providers/meal_controller_provider.dart`.

T4: Replace one screen to use the controller
  - Replace `MealsTab` to rely on the controller state. Keep original code as a fallback branch to revert if required.

T5: Add tests
  - Unit tests for `MealListController` using `InMemoryMealRepository`.
  - Adapter tests that map Drift rows into domain models (use in-memory Drift DB).

T6: Repeat for other features
  - Seance library & current seance controllers
  - Goal & profile controllers

Acceptance criteria
- UI widgets call controller methods instead of repository methods directly for the first migrated screen.
- Unit tests exist for the controller that do not touch Drift.
- No on-disk schema changes required.

Questions to refine requirements
1) Scope of controllers: Do you prefer one controller per screen (MealsTab controller) or per domain (MealController + MealEditorController)?
2) Optimistic updates: Do you want optimistic UI updates enabled by default, or prefer waiting for persistence to complete before updating UI?
3) Error surface: How should the UI display errors? Snackbar, inline error states, or modal dialogs? Prefer consistent UX.
4) Cross-feature events: Which app-level events must be broadcasted (seance start/stop, seance complete, goal updated)?
5) Offline behavior: Must the app support offline edits and syncing, or is local-only CRUD sufficient?
6) Concurrency: Are multiple simultaneous writers possible (e.g., background tasks, sync processes) that the business layer must reconcile?
7) Testing priorities: Which controllers should be tested first (Meals, Seances, Goals)?
8) Performance: Are there any lists with very large datasets requiring pagination or lazy loading?

Suggested defaults (if you don't want to answer everything now)
- One controller per screen for simplicity (can evolve to smaller controllers later).
- Start without optimistic updates (safer) and add later if UX demands it.
- Error display: use snackbars for transient errors and inline error states for form validation failures.
- Broadcast minimal events: `SeanceStarted`, `SeanceStopped`, `SeanceCompleted`, `ProfileUpdated`.
- Offline: assume local-only for now; add sync later.
- Testing order: Meals → Seances → Goals.

Next recommended step
- I can draft the `MealListController` API and a provider wiring sketch and save it to `context/plans/meal-controller-api.md`. That will give you the concrete types and a small example UI call-site. If you approve, I'll produce that file next.
