# Diet Screen: Pagination & Lazy-Loading Refactor

**Purpose**: Refactor `diet_screen.dart` to support lazy-loading and pagination for meals (by month) and ingredients (paginated list), preventing UI slowdown with large datasets.

---

## Current State

- **Meals**: Loads all meals for current day via `mealControllerProvider.load(_day)` in `initState`.
- **Ingredients**: Loads all ingredients upfront via `ref.watch(ingredientListProvider)` in build.
- **Problem**: Both will slow down with large datasets; no pagination or date-range filtering.

---

## Desired End State

### Meals Tab
- Display meals for **current month** by default.
- Provide month navigation (← previous, next →).
- Load only the selected month's meals.
- **Future**: on-demand load older months if user scrolls.

### Ingredients Tab
- Display ingredients in **paginated chunks** (e.g., 50 per page).
- Provide "Load More" button or infinite scroll.
- Keep current behavior of loading on-demand (lazy).

---

## Key Concepts

### Explicit Loading
- **Explicit**: You call a function like `.load()` or `.loadMore()` in `initState` or on user action.
  - Advantage: clear when data loads, predictable.
  - Disadvantage: boilerplate, need lifecycle hooks.
  
- **Implicit (Lazy)**: Provider auto-loads when first watched.
  - Advantage: simple, no lifecycle hooks needed.
  - Disadvantage: harder to debug, less control.

**This refactor uses explicit loading** for clarity and control over pagination.

---

## Architecture Overview

### 1. Meal Controller Changes (Explicit, Month-Based)

**Current**:
```dart
// MealsTab initState
ref.read(mealControllerProvider.notifier).load(_day);  // ← loads single day
```

**Proposed**:
```dart
// MealsTab initState
ref.read(mealControllerProvider.notifier).loadMonth(DateTime.now());  // ← loads whole month
```

**MealListState** should include:
```dart
class MealListState {
  final DateTime selectedMonth;  // the month being viewed
  final List<MealViewModel> meals;  // meals in that month
  final bool isLoading;
  final String? error;
}
```

**MealListController** methods:
- `loadMonth(DateTime month)` — fetch all meals for that month.
- `nextMonth()` — increment month and load.
- `previousMonth()` — decrement month and load.

### 2. Ingredient Provider Changes (Paginated)

**Current**:
```dart
final ingredientListProvider = StateNotifierProvider<IngredientController, List<Ingredient>>(...);
```

**Proposed**:
```dart
final ingredientListProvider = StateNotifierProvider<IngredientController, IngredientPageState>(...);

class IngredientPageState {
  final List<Ingredient> items;  // current page
  final int page;  // 0-indexed
  final bool hasMore;  // true if more pages exist
  final bool isLoading;
  final String? error;
}
```

**IngredientController** methods:
- `loadPage(int page)` — load a specific page.
- `loadMore()` — load next page and append.
- `reset()` — go back to page 0.

---

## Implementation Tasks

### T01: Update Meal Provider & Controller
**Files**: `lib/src/providers/meal_controller_provider.dart`

**Changes**:
- Rename `load(DateTime day)` → `loadMonth(DateTime month)`.
- Update `MealListState` to store `selectedMonth` (DateTime) instead of per-day.
- Fetch all meals in the month (e.g., 2026-05-01 to 2026-05-31).
- Add `nextMonth()` and `previousMonth()` methods.
- Update provider to expose month navigation UI.

**Acceptance criteria**:
- `mealControllerProvider` includes `selectedMonth`.
- Methods exist for month navigation.
- Meals queried by month range (start of month to end).

**Verification**:
- Call `loadMonth(now)` and verify meals are for the full month.
- Call `nextMonth()` and verify it loads next month.

---

### T02: Update Ingredient Provider & Controller
**Files**: `lib/src/providers/food_providers.dart`

**Changes**:
- Wrap ingredient list in a state class (items, page, hasMore, isLoading).
- Add `loadPage(int page)` method.
- Add `loadMore()` method (appends next page).
- Implement pagination logic (e.g., 50 items per page).
- Keep add/update/delete operations.

**Acceptance criteria**:
- `ingredientListProvider` state includes page info.
- `loadPage(0)` returns first 50 ingredients.
- `loadMore()` appends next 50 to existing list.

**Verification**:
- Watch provider, verify initial state is page 0 with hasMore=true.
- Call `loadMore()`, verify page increments and items append.

---

### T03: Refactor MealsTab to Use Month Navigation
**Files**: `lib/src/screens/diet/diet_screen.dart` (MealsTab class)

**Changes**:
- Convert to ConsumerStatefulWidget (if not already).
- In `initState`, call `ref.read(mealControllerProvider.notifier).loadMonth(DateTime.now())`.
- Add month header UI with ← (previous) and → (next) buttons.
- Add listeners for `nextMonth()` and `previousMonth()` on buttons.
- Display current month name (e.g., "May 2026").

**Acceptance criteria**:
- Meals tab shows month header with navigation buttons.
- Clicking next/previous updates displayed month and reloads meals.
- Meals shown are for the selected month only.

**Verification**:
- Load MealsTab, verify current month meals shown.
- Click next month, verify meals update and month header changes.

---

### T04: Refactor IngredientsTab to Use Pagination
**Files**: `lib/src/screens/diet/diet_screen.dart` (_IngredientsTab class)

**Changes**:
- Convert to ConsumerStatefulWidget (add initState).
- In `initState`, call `ref.read(ingredientListProvider.notifier).loadPage(0)`.
- Change ListView to show current page of ingredients.
- Add "Load More" button at end if `hasMore == true`.
- On "Load More" click, call `loadMore()`.

**Acceptance criteria**:
- Ingredients tab initially shows first 50 items.
- "Load More" button appears if more exist.
- Clicking "Load More" appends next batch.

**Verification**:
- Load IngredientsTab with 150+ ingredients; verify only first 50 shown.
- Click "Load More", verify next 50 appended.

---

### T05: Update UI Components for Clarity
**Files**: 
- `lib/src/screens/diet/diet_screen.dart`
- `lib/src/screens/diet/widgets/food_entry_card.dart` (if needed)

**Changes**:
- Add visual feedback during loading (spinner or skeleton).
- Show error messages if load fails.
- Improve month header styling (clear, readable).
- Show "No more items" message at end of ingredients list.

**Acceptance criteria**:
- Loading spinner visible while fetching.
- Error shown if network/DB fails.
- Month header is clear and accessible.

**Verification**:
- Simulate slow network; verify spinner shows.
- Trigger error; verify error message appears.

---

### T06: Test Pagination Edge Cases
**Files**: `test/screens/diet/` (new or existing)

**Changes**:
- Test month boundaries (Dec → Jan, Jan → Dec).
- Test ingredient pagination with exactly N items, N-1, N+1.
- Test empty states (no meals, no ingredients).
- Test rapid navigation (clicking prev/next quickly).

**Acceptance criteria**:
- All edge cases handled gracefully.
- No crashes or inconsistent state.
- Correct data shown at boundaries.

**Verification**:
- Run tests; all pass.
- Manual testing: navigate to Dec, click next, verify Jan loads.

---

### T07: Extract Mock Data to Database Seeding
**Files**: `lib/src/database/app_database.dart`, `lib/src/providers/food_providers.dart`

**Changes**:
- Move `_seedIngredients()` and `_seedMeals()` functions from `food_providers.dart` to `app_database.dart`.
- Integrate into `MigrationStrategy.onCreate()` (alongside existing `_seedExercises()`).
- Remove hardcoded seed functions and calls from `food_providers.dart`.
- Providers should only load from DB/repo, no hardcoded data in notifier.

**Current problem**: Mock data is hardcoded in source; difficult to maintain, pollutes business logic.

**After fix**: Mock data seeded at DB initialization, treated like migrations. Easier to:
- Update seed data without touching Dart code.
- Add/remove seed items.
- Keep source code clean.

**Acceptance criteria**:
- `_seedIngredients()` in `app_database.dart` seeds default ingredients on first launch.
- `_seedMeals()` in `app_database.dart` seeds sample meals on first launch.
- `food_providers.dart` notifiers only load from DB/repo.
- No hardcoded lists in providers.

**Verification**:
- Launch app; verify ingredients and seed meals appear.
- Reset DB; relaunch; verify seeding runs again.
- No seed data visible in `food_providers.dart`.

---

### T08: Sync Context & Document Decision
**Files**: `context/decisions/`, `context/architecture.md`

**Changes**:
- Archive this plan to completed.
- Add entry to `decisions/` explaining:
  - Why month-based pagination for meals (performance + UX).
  - Why explicit loading for meals, lazy for ingredients.
  - Why mock data belongs in DB seeding, not provider code.
- Update `architecture.md` with new provider signatures and DB seeding approach.

**Acceptance criteria**:
- Decision documented.
- Decisions file references architecture changes.

**Verification**:
- Future AI can read decision and understand rationale.

---

## Design Decisions

### Why Month-Based for Meals?
- **User expectation**: Users naturally think of meals by date/month.
- **Performance**: One month ≈ 30 meals (reasonable); day = fewer; year = slow.
- **Navigation**: Clear month header + prev/next is intuitive.

### Why Pagination for Ingredients?
- **Typically grows unbounded**: No natural grouping by date/time.
- **Simpler UX**: "Load More" is familiar.
- **Flexible**: Supports both lazy-load and finite lists.

### Why Explicit Loading?
- **Clarity**: Easy to debug when data loads.
- **Control**: Can trigger on user action or lifecycle.
- **Testable**: Explicit calls make test mocks straightforward.

---

## Open Questions

1. **What's the meal page size for month view?**
   - Proposed: all meals in the month (no sub-pagination).
   - Alternative: paginate within a month if expected > 100 meals.

2. **Should ingredients search also paginate?**
   - Proposed: yes, paginate search results.
   - Alternative: search first, then paginate results.

3. **Should navigated-away months stay cached?**
   - Proposed: no, reload on re-visit (simpler, always fresh).
   - Alternative: cache last N months in provider state.

---

## Rollout Strategy

1. **Phase 1 (T01–T02)**: Update providers with new signatures.
2. **Phase 2 (T03–T04)**: Refactor UI screens.
3. **Phase 3 (T05–T06)**: Polish & test.
4. **Phase 4 (T07)**: Extract mock data to DB seeding.
5. **Phase 5 (T08)**: Document & close.

**Risk**: Breaking change to provider API; update any other screens consuming `mealControllerProvider` or `ingredientListProvider`.

---

## Files Affected

- `lib/src/providers/meal_controller_provider.dart`
- `lib/src/providers/food_providers.dart` (remove hardcoded seeds, clean up to DB-only)
- `lib/src/screens/diet/diet_screen.dart` (MealsTab, _MealsTabState, _IngredientsTab, _IngredientsTabState)
- `lib/src/models/food_models.dart` (if new state classes needed)
- `lib/src/database/app_database.dart` (add meal seeding to `onCreate`)
- `test/providers/` (new tests)
- `context/decisions/` (decision doc)
- `context/architecture.md` (update provider section)

---

## Success Criteria

✅ Meals load by month with prev/next navigation.
✅ Ingredients paginate with "Load More" button.
✅ No performance degradation with 1000+ ingredients or year's worth of meals.
✅ UI provides clear feedback during loading/errors.
✅ Tests cover edge cases (month boundaries, empty states, rapid clicks).
✅ Mock data lives in DB seeding (not hardcoded in providers).
✅ Decision & architecture documented.

Purpose
- Concrete API for a `MealListController` (controller per screen default) that decouples the Meals UI from storage and business logic. Uses the existing `MealRepository` interface and a Drift-backed adapter in the app.

Assumptions / defaults
- Local-first with a real SQLite DB (Drift).
- Single writer model.
- No optimistic updates by default (controller waits for persistence).
- Only `Seance` events are broadcast globally (floating widget + notifications); meals are simple CRUD.

Files referenced
- `lib/src/repositories/interfaces/meal_repository.dart` (existing) — repository interface to depend on.
- `lib/src/adapters/drift/drift_meal_repository.dart` — where the adapter will live (to be implemented in-app).
- `lib/src/providers/repositories.dart` — provider exposing repository instances.
- `lib/src/providers/meal_controller_provider.dart` — provider for the controller.

Domain types (examples, use your existing models)
- `Meal` — domain model (from `lib/src/models/food_models.dart`)
- `MealInput` — DTO used by UI to create/update meals (portion sizes, name, eatenAt)

State classes

```dart
enum MealListStatus { idle, loading, data, error }

class MealViewModel {
  final String id;
  final String name;
  final DateTime eatenAt;
  final int calories; // precomputed

  MealViewModel({required this.id, required this.name, required this.eatenAt, required this.calories});
}

class MealListState {
  final MealListStatus status;
  final DateTime day;
  final List<MealViewModel> meals;
  final String? errorMessage;

  MealListState({
    required this.status,
    required this.day,
    this.meals = const [],
    this.errorMessage,
  });

  MealListState copyWith({MealListStatus? status, DateTime? day, List<MealViewModel>? meals, String? errorMessage}) {
    return MealListState(
      status: status ?? this.status,
      day: day ?? this.day,
      meals: meals ?? this.meals,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
```

Controller API (implementation uses `StateNotifier<MealListState>`)

```dart
class MealListController extends StateNotifier<MealListState> {
  final MealRepository _repo;
  StreamSubscription<List<Meal>>? _repoSub;

  MealListController(this._repo, DateTime initialDay)
      : super(MealListState(status: MealListStatus.idle, day: initialDay));

  Future<void> load(DateTime day) async {
    state = state.copyWith(status: MealListStatus.loading, day: day);
    try {
      final meals = await _repo.getMealsForDay(day);
      state = state.copyWith(
        status: MealListStatus.data,
        meals: meals.map(_toViewModel).toList(),
      );
      // subscribe to live updates
      _subscribeToRepo(day);
    } catch (e) {
      state = state.copyWith(status: MealListStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> refresh() async => load(state.day);

  Future<void> addMeal(MealInput input) async {
    state = state.copyWith(status: MealListStatus.loading);
    try {
      final saved = await _repo.saveMeal(input.toMeal());
      // reload or rely on stream to update
      await refresh();
    } catch (e) {
      state = state.copyWith(status: MealListStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> updateMeal(String id, MealInput input) async {
    state = state.copyWith(status: MealListStatus.loading);
    try {
      final updated = await _repo.saveMeal(input.toMeal(id: id));
      await refresh();
    } catch (e) {
      state = state.copyWith(status: MealListStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> deleteMeal(String id) async {
    state = state.copyWith(status: MealListStatus.loading);
    try {
      await _repo.deleteMeal(id);
      await refresh();
    } catch (e) {
      state = state.copyWith(status: MealListStatus.error, errorMessage: e.toString());
    }
  }

  void _subscribeToRepo(DateTime day) {
    _repoSub?.cancel();
    _repoSub = _repo.watchMealsForDay(day).listen((meals) {
      state = state.copyWith(status: MealListStatus.data, meals: meals.map(_toViewModel).toList());
    });
  }

  @override
  void dispose() {
    _repoSub?.cancel();
    super.dispose();
  }

  MealViewModel _toViewModel(Meal m) {
    return MealViewModel(id: m.id, name: m.name, eatenAt: m.eatenAt, calories: m.calories);
  }
}
```

Provider wiring (Riverpod)

```dart
// lib/src/providers/repositories.dart
final appDatabaseProvider = Provider<AppDatabase>((ref) => throw UnimplementedError());

final mealRepositoryProvider = Provider<MealRepository>((ref) {
  final db = ref.read(appDatabaseProvider);
  return DriftMealRepository(db);
});

// lib/src/providers/meal_controller_provider.dart
final mealControllerProvider = StateNotifierProvider.family<MealListController, MealListState, DateTime>((ref, day) {
  final repo = ref.read(mealRepositoryProvider);
  final controller = MealListController(repo, day);
  controller.load(day);
  ref.onDispose(() => controller.dispose());
  return controller;
});
```

Widget usage (snippets)

```dart
class MealsTab extends ConsumerWidget {
  final DateTime day;

  MealsTab({required this.day});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mealControllerProvider(day));

    if (state.status == MealListStatus.loading) return Center(child: CircularProgressIndicator());
    if (state.status == MealListStatus.error) return Center(child: Text(state.errorMessage ?? 'Error'));

    return ListView.builder(
      itemCount: state.meals.length,
      itemBuilder: (context, i) {
        final m = state.meals[i];
        return ListTile(
          title: Text(m.name),
          subtitle: Text('${m.calories} kcal'),
          trailing: IconButton(icon: Icon(Icons.delete), onPressed: () => ref.read(mealControllerProvider(day).notifier).deleteMeal(m.id)),
        );
      },
    );
  }
}
```

Test skeleton (unit test for controller using `InMemoryMealRepository`)

```dart
// test/meal_list_controller_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MealListController loads meals and reacts to additions', () async {
    final repo = InMemoryMealRepository();
    final day = DateTime(2026, 05, 24);
    final controller = MealListController(repo, day);

    await controller.load(day);
    expect(controller.state.status, MealListStatus.data);

    await controller.addMeal(MealInput(name: 'Apple', eatenAt: day, calories: 80));
    expect(controller.state.meals.any((m) => m.name == 'Apple'), isTrue);
  });
}
```

Migration notes & mapping to existing code
- Use existing `MealRepository` interface in `lib/src/repositories/interfaces/meal_repository.dart` — adapt names where necessary.
- Implement `DriftMealRepository` mapping Drift rows to the `Meal` domain model. The controller never talks to `AppDatabase` directly.

## Next steps I can take for you
1. Implement `lib/src/adapters/drift/drift_meal_repository.dart` by reading `lib/src/database/app_database.dart` and generated table classes — I can create a precise mapping implementation.
2. Implement the providers in `lib/src/providers/*` and replace `MealsTab` to use the controller (one small PR you can review).
3. Add unit tests and the `InMemory` adapter under `lib/src/adapters/in_memory/`.

Which of the three next steps would you like me to do now? If you pick (1), I'll read `lib/src/database/app_database.dart` and produce the `DriftMealRepository` implementation.

---

## Status: T03 Complete (Sweep UI mutations)

**Execution Summary:**
- Migrated `AddMealScreen._saveMeal()` to use `mealControllerProvider.notifier.addMeal()` / `updateMeal()` instead of `mealLogProvider.notifier`.
- Migrated `FoodScreen._confirmAndDelete()` to use `mealControllerProvider.notifier.deleteMeal()` instead of `mealLogProvider.notifier.removeMeal()`.
- Remaining `mealLogProvider.notifier` usages (in `IngredientListNotifier`) are provider-to-provider interactions, not UI mutations, so kept as-is per plan scope.
- Static analysis: 0 errors, all migration changes compile successfully.

**Result:** UI layer no longer directly mutates meals via `mealLogProvider.notifier`. All meal mutations now route through the controller.
