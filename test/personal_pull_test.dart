import 'dart:typed_data';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:fitfat/src/database/app_database.dart' as db;import 'package:fitfat/src/network/api_client.dart';
import 'package:fitfat/src/sync/personal_pull_service.dart';
import 'package:fitfat/src/sync/sync_models.dart';
import 'package:fitfat/src/sync/sync_state_store.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake server responses keyed by request path.
final class _FakeApi implements ApiClient {
  _FakeApi(this._byPath, {this.failPaths = const {}});

  final Map<String, Object?> _byPath;
  final Set<String> failPaths;

  @override
  Future<Object?> getJson(
    String path, {
    Map<String, String>? query,
    Map<String, String>? headers,
  }) async {
    if (failPaths.contains(path)) {
      throw ApiException(statusCode: 404, body: 'not found');
    }
    final body = _byPath[path];
    if (body == null) throw ApiException(statusCode: 404, body: 'not found');
    return body;
  }

  @override
  Future<Object?> postJson(
    String path, {
    Object? body,
    Map<String, String>? query,
    Map<String, String>? headers,
  }) async => <String, Object?>{'server_time': 1000};

  @override
  Future<Uint8List> getBytes(String path, {Map<String, String>? headers}) async =>
      Uint8List(0);

  @override
  Future<Object?> postBytes(
    String path, {
    required Uint8List body,
    Map<String, String>? headers,
  }) async => null;

  @override
  Future<Object?> postMultipart(
    String path, {
    required Map<String, String> fields,
    required Map<String, MultipartFilePart> files,
    Map<String, String>? headers,
  }) async => null;

  @override
  Future<Object?> putJson(
    String path, {
    Object? body,
    Map<String, String>? query,
    Map<String, String>? headers,
  }) async => null;

  @override
  Future<Object?> deleteJson(String path, {Map<String, String>? query}) async =>
      null;
}

void main() {
  late db.AppDatabase database;
  late MemorySyncStateStore state;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    state = MemorySyncStateStore();
  });

  tearDown(() => database.close());

  Future<int> taskCount() async =>
      (await database.select(database.tasks).get()).length;

  test('pullTasks applies new rows and advances the cursor on success', () async {
    database;
    final api = _FakeApi({
      '/tasks': <String, Object?>{
        'server_time': 500,
        'items': [
          {
            'id': 't1',
            'date': 100,
            'title': 'Buy milk',
            'done': 0,
            'taskStatus': 1,
            'carryOver': false,
            'sortOrder': 0,
            'dueDate': null,
            'dueTimeMinutes': null,
            'startTimeMinutes': null,
            'endTimeMinutes': null,
            'notes': 'spam',
            'workoutId': null,
            'workoutTemplateId': null,
            'recurrence': null,
            'seriesId': null,
            'createdAt': 90,
            'updatedAt': 90,
          },
        ],
        'deleted': <String>[],
      },
    });
    final service = PersonalPullService(api, database, state);
    final result = await service.pullTasks(apiKey: 'k', endpoint: '/tasks');
    expect(result.ok, isTrue, reason: result.error);
    expect(result.updated, 1);
    expect(await taskCount(), 1);
    expect(state.getLastSyncedAt(SyncResource.tasks), 500);
    final task = await (database.select(
      database.tasks,
    )..where((t) => t.id.equals('t1'))).getSingle();
    expect(task.title, 'Buy milk');
    expect(task.deletedAt, isNull);
  });

  test('pullTasks never overwrites an existing local row', () async {
    await database.into(database.tasks).insert(
      db.TasksCompanion.insert(
        id: 't1',
        date: 100,
        title: 'Local edit',
        done: 1,
        taskStatus: const Value(0),
        carryOver: const Value(false),
        sortOrder: 0,
        createdAt: 50,
      ),
    );
    final api = _FakeApi({
      '/tasks': <String, Object?>{
        'server_time': 600,
        'items': [
          {
            'id': 't1',
            'date': 100,
            'title': 'Server edit',
            'done': 0,
            'carryOver': false,
            'sortOrder': 0,
            'createdAt': 50,
            'updatedAt': 90,
          },
        ],
        'deleted': <String>[],
      },
    });
    final service = PersonalPullService(api, database, state);
    final result = await service.pullTasks(apiKey: 'k', endpoint: '/tasks');
    expect(result.updated, 0);
    final task = await (database.select(
      database.tasks,
    )..where((t) => t.id.equals('t1'))).getSingle();
    expect(task.title, 'Local edit');
    expect(state.getLastSyncedAt(SyncResource.tasks), 600);
  });

  test('pullTasks deletes tombstoned rows and their links', () async {
    await database.into(database.tasks).insert(
      db.TasksCompanion.insert(
        id: 't1',
        date: 100,
        title: 'Doomed',
        done: 0,
        taskStatus: const Value(0),
        carryOver: const Value(false),
        sortOrder: 0,
        createdAt: 50,
      ),
    );
    await database.into(database.taskGoals).insert(
      db.TaskGoalsCompanion.insert(taskId: 't1', goalId: 'g1'),
    );
    final api = _FakeApi({
      '/tasks': <String, Object?>{
        'server_time': 700,
        'items': <Object?>[],
        'deleted': ['t1'],
      },
    });
    final service = PersonalPullService(api, database, state);
    final result = await service.pullTasks(apiKey: 'k', endpoint: '/tasks');
    expect(result.deleted, 1);
    expect(await taskCount(), 0);
    expect(
      (await database.select(database.taskGoals).get()).length,
      0,
    );
    expect(state.getLastSyncedAt(SyncResource.tasks), 700);
  });

  test('pullTasks leaves the cursor untouched when the request fails', () async {
    final api = _FakeApi({}, failPaths: {'/tasks'});
    final service = PersonalPullService(api, database, state);
    final result = await service.pullTasks(apiKey: 'k', endpoint: '/tasks');
    expect(result.ok, isFalse);
    expect(state.getLastSyncedAt(SyncResource.tasks), 0);
  });

  test('pullWorkouts applies the nested exercise/set graph', () async {
    final api = _FakeApi({
      '/workouts': <String, Object?>{
        'server_time': 800,
        'items': [
          {
            'id': 'w1',
            'name': 'Leg day',
            'date': 100,
            'createdAt': 90,
            'exercises': [
              {
                'id': 'we1',
                'workoutId': 'w1',
                // No local exercises row: mobile FKs are off, and dropping the
                // exercise used to swallow the whole workout graph.
                'exerciseId': 'missing',
                'sortOrder': 0,
                'notes': null,
                'sets': [
                  {
                    'id': 's1',
                    'workoutExerciseId': 'we1',
                    'setNumber': 1,
                    'reps': 8,
                  },
                ],
              },
            ],
          },
        ],
        'deleted': <String>[],
        'deletedExercises': <String>[],
        'deletedSets': <String>[],
      },
    });
    final service = PersonalPullService(api, database, state);
    final result = await service.pullWorkouts(
      apiKey: 'k',
      endpoint: '/workouts',
    );
    expect(result.updated, 3);
    final exercises = await database.select(database.workoutExercises).get();
    expect(exercises.map((e) => e.id), ['we1']);
    final sets = await database.select(database.exerciseSets).get();
    expect(sets.map((s) => s.id), ['s1']);
  });

  test('pullWorkouts still applies children when the workout exists', () async {
    await database.into(database.workouts).insert(
      db.WorkoutsCompanion.insert(
        id: 'w1',
        name: 'Leg day',
        date: 100,
        createdAt: 90,
      ),
    );
    final api = _FakeApi({
      '/workouts': <String, Object?>{
        'server_time': 801,
        'items': [
          {
            'id': 'w1',
            'name': 'Leg day',
            'date': 100,
            'createdAt': 90,
            'exercises': [
              {
                'id': 'we1',
                'workoutId': 'w1',
                'exerciseId': 'e1',
                'sortOrder': 0,
                'notes': null,
                'sets': [
                  {'id': 's1', 'workoutExerciseId': 'we1', 'setNumber': 1},
                ],
              },
            ],
          },
        ],
        'deleted': <String>[],
        'deletedExercises': <String>[],
        'deletedSets': <String>[],
      },
    });
    final service = PersonalPullService(api, database, state);
    final result = await service.pullWorkouts(
      apiKey: 'k',
      endpoint: '/workouts',
    );
    expect(result.updated, 2);
    expect(await database.select(database.workoutExercises).get(), hasLength(1));
    expect(await database.select(database.exerciseSets).get(), hasLength(1));
  });

  test('pullWorkouts applies child tombstones', () async {
    await database.into(database.workouts).insert(
      db.WorkoutsCompanion.insert(
        id: 'w1',
        name: 'Leg day',
        date: 100,
        createdAt: 90,
      ),
    );
    await database.into(database.workoutExercises).insert(
      db.WorkoutExercisesCompanion.insert(
        id: 'we1',
        workoutId: 'w1',
        exerciseId: 'e1',
        sortOrder: 0,
      ),
    );
    await database.into(database.exerciseSets).insert(
      db.ExerciseSetsCompanion.insert(
        id: 's1',
        workoutExerciseId: 'we1',
        setNumber: 1,
      ),
    );
    final api = _FakeApi({
      '/workouts': <String, Object?>{
        'server_time': 802,
        'items': <Object?>[],
        'deleted': <String>[],
        'deletedExercises': ['we1'],
        'deletedSets': <String>[],
      },
    });
    final service = PersonalPullService(api, database, state);
    await service.pullWorkouts(apiKey: 'k', endpoint: '/workouts');
    expect(await database.select(database.workoutExercises).get(), isEmpty);
    expect(await database.select(database.exerciseSets).get(), isEmpty);
  });

  test('pullWorkouts never resurrects a child pending local deletion', () async {
    await database.into(database.workouts).insert(
      db.WorkoutsCompanion.insert(
        id: 'w1',
        name: 'Leg day',
        date: 100,
        createdAt: 90,
      ),
    );
    await database.recordSyncDelete('workoutExercises', 'we1');
    final api = _FakeApi({
      '/workouts': <String, Object?>{
        'server_time': 803,
        'items': [
          {
            'id': 'w1',
            'name': 'Leg day',
            'date': 100,
            'createdAt': 90,
            'exercises': [
              {
                'id': 'we1',
                'workoutId': 'w1',
                'exerciseId': 'e1',
                'sortOrder': 0,
                'notes': null,
                'sets': <Object?>[],
              },
            ],
          },
        ],
        'deleted': <String>[],
        'deletedExercises': <String>[],
        'deletedSets': <String>[],
      },
    });
    final service = PersonalPullService(api, database, state);
    await service.pullWorkouts(apiKey: 'k', endpoint: '/workouts');
    expect(await database.select(database.workoutExercises).get(), isEmpty);
  });

  test('pullTransactions skips rows whose accounts never landed', () async {
    await database.into(database.accounts).insert(
      db.AccountsCompanion.insert(
        id: 'a1',
        name: 'Checking',
        type: 'checking',
        createdAt: 50,
      ),
    );
    final api = _FakeApi({
      '/transactions': <String, Object?>{
        'server_time': 900,
        'items': [
          {
            'id': 'tx1',
            'type': 'expense',
            'amount': 5.0,
            'currencyCode': 'EUR',
            'amountBase': 5.0,
            'rateUsed': 1.0,
            'accountId': 'a1',
            'toAccountId': null,
            'category': null,
            'date': 200,
            'note': null,
            'receiptId': null,
            'isDraft': false,
            'createdAt': 90,
            'updatedAt': 90,
          },
          {
            'id': 'tx2',
            'type': 'expense',
            'amount': 7.0,
            'currencyCode': 'EUR',
            'amountBase': 7.0,
            'rateUsed': 1.0,
            'accountId': 'ghost',
            'toAccountId': null,
            'category': null,
            'date': 200,
            'note': null,
            'receiptId': null,
            'isDraft': false,
            'createdAt': 90,
            'updatedAt': 90,
          },
        ],
        'deleted': <String>[],
      },
    });
    final service = PersonalPullService(api, database, state);
    final result = await service.pullTransactions(
      apiKey: 'k',
      endpoint: '/transactions',
    );
    expect(result.updated, 1);
    final ids = await database
        .select(database.transactions)
        .get()
        .then((rows) => rows.map((r) => r.id).toSet());
    expect(ids, {'tx1'});
  });

  test('pullReceipts mirrors metadata including the OCR parse, never images', () async {
    final api = _FakeApi({
      '/receipt-pictures': <String, Object?>{
        'server_time': 950,
        'items': [
          {
            'id': 'r1',
            'localPath': '',
            'remotePath': 'receipts/r1.jpg',
            'uploadStatus': 2,
            'parsed': true,
            'parsedJson': '{"total":42.75}',
            'transactionId': 'tx1',
            'createdAt': 90,
            'updatedAt': 90,
          },
        ],
        'deleted': <String>[],
      },
    });
    final service = PersonalPullService(api, database, state);
    final result = await service.pullReceipts(
      apiKey: 'k',
      endpoint: '/receipt-pictures',
    );
    expect(result.updated, 1);
    final receipt = await database
        .select(database.receipts)
        .getSingle();
    expect(receipt.parsedJson, '{"total":42.75}');
    expect(receipt.uploadStatus, 2);
    expect(receipt.parsed, isTrue);
  });

  test('pullStores inserts unknown stores and applies tombstones', () async {
    await database.into(database.stores).insert(
      db.StoresCompanion.insert(id: 's0', name: 'Local', createdAt: 1),
    );
    await database.into(database.stores).insert(
      db.StoresCompanion.insert(id: 's2', name: 'Gone', createdAt: 2),
    );
    final api = _FakeApi({
      '/stores': <String, Object?>{
        'server_time': 960,
        'items': [
          {'id': 's1', 'name': 'Carrefour', 'createdAt': 90, 'updatedAt': 90},
          // A local row keeps its local name.
          {'id': 's0', 'name': 'Renamed', 'createdAt': 1, 'updatedAt': 90},
        ],
        'deleted': ['s2'],
      },
    });
    final service = PersonalPullService(api, database, state);
    final result = await service.pullStores(apiKey: 'k', endpoint: '/stores');
    expect(result.ok, isTrue, reason: result.error);
    expect(result.updated, 1);
    expect(result.deleted, 1);
    final rows = await database.select(database.stores).get();
    expect({for (final r in rows) r.id: r.name}, {
      's0': 'Local',
      's1': 'Carrefour',
    });
    expect(state.getLastSyncedAt(SyncResource.stores), 960);
  });
}
