# State Management — Riverpod

## What is Riverpod?

Riverpod is a state management library for Flutter. It lets you **declare** state (like a list of exercises or the active seance) and **react** to changes automatically — when the state changes, every widget that reads it rebuilds.

Think of it as:
- A **dependency injection** container (you declare how to create things)
- A **reactivity** system (widgets auto-update when data changes)
- A **testability** tool (you can override any provider in tests)

---

## Provider types used in fitfat

| Type | When to use | Example |
|---|---|---|
| `Provider<T>` | Synchronous, never changes | `databaseProvider` |
| `NotifierProvider<N, T>` | Mutable state with methods | `ingredientListProvider` |
| `FutureProvider<T>` | Async data that loads once | (not used — we use Notifier with async init instead) |
| `StreamProvider<T>` | Reactive stream | (not used — we use Notifier with manual state updates) |

---

## Provider anatomy

```dart
// 1. Declare the provider (global variable)
final exerciseListProvider =
    NotifierProvider<ExerciseListNotifier, List<ExerciseDefinition>>(
  ExerciseListNotifier.new,
);

// 2. Define the notifier class
class ExerciseListNotifier extends Notifier<List<ExerciseDefinition>> {
  @override
  List<ExerciseDefinition> build() {
    _loadFromDb(); // async init
    return [];     // initial value while loading
  }

  Future<void> _loadFromDb() async {
    final db = ref.read(databaseProvider);
    // ...
    state = loadedExercises; // triggers UI rebuild
  }
}
```

### How `build()` works

`build()` is called when the provider is first read. It returns the **initial state**. The `ref` object lets you read other providers.

When you assign `state = newValue`, all widgets watching this provider rebuild.

---

## Reading providers in widgets

```dart
// In a ConsumerWidget:
@override
Widget build(BuildContext context, WidgetRef ref) {
  final exercises = ref.watch(exerciseListProvider);
  // exercises is List<ExerciseDefinition>
  // Widget rebuilds when the list changes
}

// Read once without watching:
ref.read(exerciseListProvider.notifier).addExercise(newExercise);

// Watch a notifier's state:
final count = ref.watch(counterProvider); // int

// Call a method on the notifier:
ref.read(counterProvider.notifier).increment();
```

**Key difference:**
| Method | Behavior |
|---|---|
| `ref.watch(provider)` | Rebuilds widget when provider value changes |
| `ref.read(provider)` | Gets current value once, no rebuild |
| `ref.read(provider.notifier)` | Gets the notifier to call methods |

---

## Provider overrides (testing)

```dart
final container = ProviderContainer(
  overrides: [
    // Replace real provider with a mock
    databaseProvider.overrideWith(
      (ref) => AppDatabase.forTesting(NativeDatabase.memory()),
    ),
    // Or override with a fixed value
    seanceRepositoryProvider.overrideWithValue(InMemorySeanceRepository()),
  ],
);
addTearDown(container.dispose);
```

---

## Common patterns in fitfat

### Pattern 1: Notifier with async init

```dart
class ExerciseListNotifier extends Notifier<List<ExerciseDefinition>> {
  @override
  List<ExerciseDefinition> build() {
    _loadFromDb();
    return []; // empty while loading
  }

  Future<void> _loadFromDb() async {
    try {
      final db = ref.read(databaseProvider);
      final data = await db.getAllExercises();
      state = data.map(...).toList();
    } catch (_) {}
  }
}
```

The `build()` method must return synchronously. The async load happens in the background and updates `state` when ready.

### Pattern 2: Persist on every mutation

```dart
void addSet(int exerciseIndex, int reps, double weight) {
  // Update state immediately
  state = updatedSeance;
  // Persist asynchronously
  unawaited(_persist());
}
```

State is updated first (UI reacts instantly), then persistence happens in the background.

### Pattern 3: Cross-provider communication

```dart
void updateIngredient(Ingredient ingredient) {
  state = [...];
  // Notify another provider of the change
  ref.read(mealLogProvider.notifier).replaceIngredient(ingredient);
}
```

---

## Links

| What | Link |
|---|---|
| Riverpod docs | https://riverpod.dev |
| Getting started | https://riverpod.dev/docs/getting_started |
| NotifierProvider | https://riverpod.dev/docs/providers/notifier_provider |
| Provider overrides | https://riverpod.dev/docs/concepts/modifiers#override |
| ProviderScope | https://riverpod.dev/docs/concepts/scopes |
