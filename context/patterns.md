# Patterns

## UI-first development

All screens are built with mock data via Riverpod providers. No database is required during UI iteration. Phase 2 (Drift) replaces in-memory providers with DB-backed streaming providers.

## State management pattern

Manual Riverpod providers (no codegen). Each feature domain has a corresponding provider file under `lib/src/providers/`.

### Provider types

- `Provider<T>` — synchronous mock data (e.g., `exerciseListProvider`)
- `NotifierProvider<Notifier<T>, T>` — mutable state with methods (e.g., `ActiveSeanceNotifier`, `MealLogNotifier`, `TemplateListNotifier`)
- Notifier classes encapsulate all mutation logic (add/update/delete/start/stop)
- Async/I/O operations use `Future<void>` methods within Notifiers (e.g., `createTemplate`, `loadTemplates`)
- Cross-provider reads use `ref.read(otherProvider.notifier)` within Notifier methods

### Example pattern

```dart
// Provider definition
final templateListProvider = NotifierProvider<TemplateListNotifier, List<SeanceTemplate>>(
  TemplateListNotifier.new,
);

// Notifier class
class TemplateListNotifier extends Notifier<List<SeanceTemplate>> {
  @override
  List<SeanceTemplate> build() => [];

  Future<void> createTemplate(SeanceTemplate template) async {
    final created = await _repo.createTemplate(template);
    state = [...state, created];
  }
}
```

## Repository pattern (seance templates)

Seance templates use a repository port/adapter pattern:
- `SeanceRepository` — abstract interface (port)
- `InMemorySeanceRepository` — in-memory implementation
- Registered via `Provider<SeanceRepository>`
- Will be replaced by Drift-backed implementation in T09

## Navigation pattern

GoRouter with `StatefulShellRoute.indexedStack` for persistent tab state. Three bottom tabs: Diet, Exercise, Dashboard. Each tab retains its navigation state when switching.

## Feature-first folder convention

Each major feature gets its own directory:
```
screens/
├── food/          # Meal logging, ingredient CRUD
├── exercise/      # Seance flow, template library
└── dashboard/     # Nutrition summary, charts, goals
```

Shared providers, models, services, repositories, and widgets live under `lib/src/{providers,models,services,repositories,widgets}/`.

## Theme pattern

Material 3 with `ColorScheme.fromSeed()`. A single `AppTheme` class exposes `light` and `dark` static getters. Seed color is Indigo-600 (`#4F46E5`). System font used (no network calls).

## Background service pattern

- Active seance timer uses `flutter_foreground_task` for cross-platform background execution
- `SeanceForegroundService` singleton wraps plugin lifecycle (init, start, stop)
- Service started when seance begins, stopped when seance completes
- `SeanceAppBarAction` widget shows elapsed time on all tabs via Provider subscription
- Android: foreground service with persistent notification
- iOS: best-effort background task (15-min cycle limit documented)
