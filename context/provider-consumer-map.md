# Provider-Consumer Map

A diagram of which files depend on which Riverpod providers, so we know what breaks when we change a provider's type.

---

## Legend

```
PROVIDER (type)
├── screen/file.dart  (reads via ref.watch)
└── another/file.dart (reads via ref.read)
```

Changing a provider's type (e.g. `Provider` → `FutureProvider`) breaks **all consumers** because they expect a specific return type.

---

## 1. exerciseListProvider

```mermaid
flowchart LR
    P["exerciseListProvider<br/>Provider<List<ExerciseDefinition>>"] --> C1["exercise_screen.dart<br/>ExercisesListTab<br/>ref.watch → List"]
    P --> C2["current_seance_screen.dart<br/>_buildExerciseListView<br/>ref.watch → List"]
    P --> C3["dashboard_screen.dart<br/>StrengthGoalDialog<br/>ref.watch → List"]
    P --> C4["create_seance_screen.dart<br/>build<br/>ref.watch → List"]

    C1 -.- N1["ListView.separated(itemCount: exercises.length)"]
    C2 -.- N2["exercises.where(...).toList()"]
    C3 -.- N3["allExercises.where(...).toList()"]
    C4 -.- N4["allExercises.where(...).toList()"]
```

**4 consumers.** All expect `List<ExerciseDefinition>` directly (no AsyncValue wrapping).

To migrate to DB: keep `Provider<List<ExerciseDefinition>>`, load data via `_loadFromDb()` in `main.dart` after `AppDatabase` is ready, or use a `Notifier` that loads async on build.

---

## 2. activeSeanceProvider

```mermaid
flowchart LR
    P["activeSeanceProvider<br/>NotifierProvider<ActiveSeanceNotifier, Seance?>"] --> C1["SeanceFloatingPill (appbar_seance_indicator.dart)<br/>ref.watch → Seance?"]
    P --> C2["SeancesHistoryTab (exercise_screen.dart)<br/>ref.watch → Seance?"]
    P --> C3["CurrentSeanceScreen (current_seance_screen.dart)<br/>ref.watch → Seance?"]
    P --> C4["_TemplateCard (exercise_screen.dart)<br/>ref.read → cancel + start"]
    P --> C5["seance_library_screen.dart<br/>ref.read → cancel + start"]

    C1 -.- N1["if (seance == null) return SizedBox.shrink()"]
    C2 -.- N2["if (ref.watch(activeSeanceProvider) case final running?) → Running Seance card"]
    C3 -.- N3["if (seance == null) return 'No active seance'"]
```

**5 consumers.** Already uses SharedPreferences JSON for persistence. Keep as-is until Drift migration covers seances.

---

## 3. seanceHistoryProvider

```mermaid
flowchart LR
    P["seanceHistoryProvider<br/>NotifierProvider<SeanceHistoryNotifier, List<Seance>>"] --> C1["SeancesHistoryTab<br/>ref.watch → List"]
    C1 -.- N1["...seances.reversed.map(_SeanceHistoryCard)"]
```

**1 consumer.** Currently in-memory seed. Need DB-backed implementation.

---

## 4. templateListProvider

```mermaid
flowchart LR
    P["templateListProvider<br/>NotifierProvider<TemplateListNotifier, List<SeanceTemplate>>"] --> C1["SeancesHistoryTab<br/>ref.watch → List"]
    P --> C2["_TemplateCard<br/>ref.read → CRUD"]
    P --> C3["seance_library_screen.dart<br/>ref.watch → List"]
    P --> C4["create_seance_screen.dart<br/>ref.read → CRUD"]

    C1 -.- N1["templates.isNotEmpty → horizontal card list"]
    C3 -.- N2["templates.isEmpty → 'No templates'"]
```

**4 consumers.** Uses `SeanceRepository` port already. Just needs a Drift-backed implementation instead of the in-memory one.

---

## 5. ingredientListProvider + mealLogProvider

```mermaid
flowchart LR
    subgraph Food
        I["ingredientListProvider<br/>NotifierProvider<IngredientListNotifier, List<Ingredient>>"]
        M["mealLogProvider<br/>NotifierProvider<MealLogNotifier, List<MealEntry>>"]
    end

    I --> C1["food_providers.dart<br/>MealLogNotifier.build() reads ingredients"]
    I --> C2["dashboard_screen.dart<br/>dailyNutritionProvider reads meals"]
    I --> C3["food_screen (MealsTab)<br/>ref.watch → List<Ingredient>"]

    M --> C2
    M --> C4["food_screen (MealsTab, AddMealScreen)<br/>ref.watch → List<MealEntry>"]
    M --> D["dashboard_providers.dart<br/>dailyNutritionProvider<br/>→ sums macros from today's meals"]
```

**Ingredient:** 3 consumers. **MealLog:** 3 consumers (+ dashboard's daily nutrition). 
These are the most complex because `MealLogNotifier.build()` reads `ingredientListProvider` — they're interdependent.

---

## 6. userProfileProvider + goalsProvider

```mermaid
flowchart LR
    UP["userProfileProvider<br/>NotifierProvider<UserProfileNotifier, UserProfile?>"] --> C1["dashboard_screen.dart<br/>GoalsTab, ProfileSetupDialog<br/>ref.read → setProfile"]
    UP --> C2["dashboard_providers.dart<br/>computedMacrosProvider<br/>ref.watch → profile"]

    GP["goalsProvider<br/>NotifierProvider<GoalsNotifier, GoalsData>"] --> C3["dashboard_screen.dart<br/>GoalsTab, Overview<br/>ref.watch → GoalsData"]
    GP --> C2
    GP --> C4["dashboard_providers.dart<br/>computedMacrosProvider<br/>ref.watch → goalsData"]
```

**Profile:** 2 consumers. **Goals:** 3 consumers. Profile is simple (singleton). Goals has more methods (add/remove/update per type).

---

## Summary — what to touch for each change

| If you change... | Consumers to update |
|---|---|
| `exerciseListProvider` type | 4 files |
| `activeSeanceProvider` type | 5 files |
| `seanceHistoryProvider` type | 1 file |
| `templateListProvider` type | 4 files |
| `ingredientListProvider` type | 3 files |
| `mealLogProvider` type | 3 files |
| `userProfileProvider` type | 2 files |
| `goalsProvider` type | 3 files |

### Safest migration order

1. **exerciseListProvider** — simplest. Swap seed for DB call. Keep `Provider<List<ExerciseDefinition>>` type.
2. **userProfileProvider** + **goalsProvider** — next simplest. Persist via repo, keep type.
3. **ingredientListProvider** + **mealLogProvider** — hardest. Interdependent seed data. Need a plan.
4. **seanceHistoryProvider** + **templateListProvider** — needs full 3-table join (seances → entries → sets). Deferred.

The rule: **never change the provider type** (`Provider` → `FutureProvider`). Instead, keep the same type and load data inside the `build()` method or via `main.dart`.
