# Patterns

## UI-first development

All screens are built with mock data via Riverpod providers. No database is required during UI iteration. This allows rapid visual refinement before committing to a data model.

## State management pattern

Manual Riverpod providers (no codegen). Each feature domain has a corresponding provider file:

```dart
// lib/src/providers/food_providers.dart
final mockFoodsProvider = Provider<List<MockFood>>((ref) {
  return MockData.foods;
});
```

### Provider types

- `Provider<T>` — synchronous mock data
- `StateNotifierProvider` — mutable state (timers, active sessions)
- `FutureProvider` — async DB queries (Phase 2)

## Navigation pattern

GoRouter with named routes. Screens are organized by feature domain under `lib/src/screens/{feature}/`. Each screen file exports a single widget.

## Feature-first folder convention

Each major feature gets its own directory under `lib/src/screens/`:
```
screens/
├── food/          # Meal logging, food search
├── exercise/      # Cardio timer, weightlifting
├── dashboard/     # Charts, trends
└── settings/      # Goals, preferences
```

Shared providers and models live in `lib/src/providers/` and `lib/src/models/`.

## Theme pattern

Material 3 with `ColorScheme.fromSeed()`. A single `AppTheme` class exposes `light` and `dark` static getters. Seed color is Indigo-600 (`#4F46E5`). System font (Roboto on Android, SF Pro on iOS) used to avoid network calls.
