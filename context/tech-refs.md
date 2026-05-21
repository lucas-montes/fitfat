# Flutter Tech Stack — Docs & References

## State Management

### Riverpod (v3)
The app uses `flutter_riverpod` with manual (codegen-free) providers.

| What | Link |
|------|------|
| Official docs | https://riverpod.dev/docs |
| Getting started | https://riverpod.dev/docs/getting_started |
| NotifierProvider | https://riverpod.dev/docs/providers/notifier_provider |
| Provider (read-only) | https://riverpod.dev/docs/providers/provider |
| StreamProvider | https://riverpod.dev/docs/providers/stream_provider |
| FutureProvider | https://riverpod.dev/docs/providers/future_provider |
| ProviderObserver | https://riverpod.dev/docs/concepts/provider_observer |
| ProviderScope + overrides (testing) | https://riverpod.dev/docs/concepts/modifiers#override |
| Migrating from v2 to v3 | https://riverpod.dev/docs/migration/v2_to_v3 |
| Riverpod vs Bloc vs Provider (comparison) | https://riverpod.dev/docs/comparisons |

---

## Local Database

### Drift (SQLite ORM)
Drift is the recommended replacement for raw SQLite in Flutter.

| What | Link |
|------|------|
| Official docs | https://drift.simonbinder.eu/docs/ |
| Getting started | https://drift.simonbinder.eu/docs/getting-started/ |
| Table definitions | https://drift.simonbinder.eu/docs/tables/ |
| DAOs (Data Access Objects) | https://drift.simonbinder.eu/docs/daos/ |
| Queries (select, join, update, delete) | https://drift.simonbinder.eu/docs/queries/ |
| Migrations | https://drift.simonbinder.eu/docs/migrations/ |
| Using with Riverpod (drift_riverpod) | https://drift.simonbinder.eu/docs/other-engines/riverpod/ |
| Using with Riverpod (guide) | https://drift.simonbinder.eu/docs/examples/riverpod |
| In-memory database for testing | https://drift.simonbinder.eu/docs/testing/ |
| Codegen setup (build.yaml) | https://drift.simonbinder.eu/docs/getting-started/#setup |
| Dart-only (no native builds) | https://drift.simonbinder.eu/docs/platforms/web/ |
| SQL helpers (group by, order, limit) | https://drift.simonbinder.eu/docs/queries/sql_helpers/ |

### Example: Drift + Riverpod
```dart
// 1. Define table
class Exercises extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get category => text()();
  @override Set<Column> get primaryKey => {id};
}

// 2. Define DAO
@DriftAccessor(tables: [Exercises])
class ExerciseDao extends DatabaseAccessor<AppDatabase> with _$ExerciseDaoMixin {
  ExerciseDao(AppDatabase db) : super(db);
  Stream<List<Exercise>> watchAll() => select(exercises).watch();
}

// 3. Riverpod provider
final exerciseDaoProvider = Provider<ExerciseDao>((ref) {
  return ref.watch(databaseProvider).exerciseDao;
});

final exerciseListProvider = StreamProvider<List<Exercise>>((ref) {
  return ref.watch(exerciseDaoProvider).watchAll();
});

// 4. UI
final exercises = ref.watch(exerciseListProvider);
exercises.when(data: (list) => ..., loading: ..., error: ...);
```

---

## Simple Key-Value Persistence

### SharedPreferences
Currently used for active seance persistence (temporary until Drift).

| What | Link |
|------|------|
| Pub page | https://pub.dev/packages/shared_preferences |
| Basic usage | https://pub.dev/packages/shared_preferences#usage |
| Async caveat | https://docs.flutter.dev/packages-and-plugins/shared-preferences |

---

## Background Services

### flutter_foreground_task
Used for the active seance timer notification.

| What | Link |
|------|------|
| Pub page | https://pub.dev/packages/flutter_foreground_task |
| Example | https://pub.dev/packages/flutter_foreground_task/example |
| Service lifecycle (start/stop/update) | https://pub.dev/packages/flutter_foreground_task#migrate-from-4x |
| TaskHandler & data communication | https://pub.dev/packages/flutter_foreground_task#how-to-send-data-to-the-main-isolate |

---

## Routing

### go_router

| What | Link |
|------|------|
| Pub page | https://pub.dev/packages/go_router |
| Setup | https://pub.dev/packages/go_router#basic-setup |
| StatefulShellRoute (persistent bottom nav) | https://pub.dev/documentation/go_router/latest/go_router/StatefulShellRoute-class.html |
| Nested navigation | https://pub.dev/packages/go_router#nested-navigation |
| NavigationShell example | https://pub.dev/packages/go_router#bottom-navigation |
| Initial location / deep linking | https://pub.dev/packages/go_router#initial-location |
| GlobalKey<NavigatorState> (root navigator) | https://pub.dev/documentation/go_router/latest/go_router/GoRouter-class.html |

---

## Charts

### fl_chart

| What | Link |
|------|------|
| Pub page | https://pub.dev/packages/fl_chart |
| LineChart | https://pub.dev/packages/fl_chart#line-chart |
| BarChart | https://pub.dev/packages/fl_chart#bar-chart |
| PieChart | https://pub.dev/packages/fl_chart#pie-chart |
| Samples gallery | https://github.com/imaNNeo/fl_chart/tree/master/repo_files/documentations |

---

## Architecture & Patterns

| Concept | Link |
|---------|------|
| Flutter architecture (official) | https://docs.flutter.dev/app-architecture |
| Riverpod + Drift architecture (guide) | https://codewithandrea.com/articles/flutter-app-architecture-riverpod-service-layer/ |
| Repository pattern in Flutter | https://medium.com/flutter-community/the-repository-pattern-in-flutter-217f0a6dc6f6 |
| Offline-first (database + API sync) | https://docs.flutter.dev/data-and-backend/state-mgmt/options#offline-first |
| Options for state management | https://docs.flutter.dev/data-and-backend/state-mgmt/options |
| Key Flutter packages | https://docs.flutter.dev/packages |
