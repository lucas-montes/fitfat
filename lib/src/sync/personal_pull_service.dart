import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../database/app_database.dart' as db;
import '../database/database_provider.dart' as db;
import '../network/api_client.dart';
import '../settings/providers/settings.dart';
import 'sync_models.dart';
import 'sync_state_store.dart';

/// Pulls the **personal pool** — the user's own data mirrored by the sync
/// server — and applies it into the local database.
///
/// Rows ride the wire in the same shape the push handlers write them: camelCase
/// fields, epoch-millisecond timestamps. Two roles apply (see [SyncResource]):
///
///  * **Local-first** resources (tasks, notes, goals, workouts, templates,
///    experiments, meals, bodyMetrics, budgetAccounts, transactions) apply a
///    server row only when the id is absent locally, so a local edit always
///    wins. Tombstoned ids delete the local row with its dependents — a
///    deletion anywhere is a deletion everywhere.
///  * **Server-wins** resources (tags, receipts) upsert over local state: the
///    server is their source of truth. Receipt metadata + OCR parse ride
///    along; the image itself stays server-side and is never downloaded.
///
/// The `since` cursor advances only on success, per resource, matching the
/// other sync clients.
final class PersonalPullService {
  final ApiClient _api;
  final db.AppDatabase _database;
  final SyncStateStore _state;

  PersonalPullService(this._api, this._database, this._state);

  static const _error = 'Unexpected payload';

  static Map<String, String> authHeaders(String apiKey) => {
    'Authorization': 'Bearer $apiKey',
  };

  // --------------------------------------------------------------------------
  // Tasks
  // --------------------------------------------------------------------------

  Future<SyncResult> pullTasks({
    required String apiKey,
    required String endpoint,
  }) async {
    final since = _state.getLastSyncedAt(SyncResource.tasks);
    try {
      final (payload, serverTime) = await _fetch(endpoint, apiKey, since);
      final items = _maps(payload['items']);
      var updated = 0;
      for (final raw in items) {
        final id = raw['id'];
        if (id is! String) continue;
        final existing =
            await (_database.select(_database.tasks)
                  ..where((t) => t.id.equals(id)))
                .get();
        if (existing.isNotEmpty) continue;
        await _database.into(_database.tasks).insert(
          db.TasksCompanion.insert(
            id: id,
            date: _int(raw['date']),
            title: _str(raw['title'], ''),
            done: _int(raw['done']),
            taskStatus: Value(_optInt(raw['taskStatus'])),
            carryOver: Value(
              raw['carryOver'] is bool
                  ? raw['carryOver'] as bool
                  : ((raw['carryOver'] as num?)?.toInt() ?? 0) != 0,
            ),
            sortOrder: _int(raw['sortOrder']),
            dueDate: Value(_optInt(raw['dueDate'])),
            dueTimeMinutes: Value(_optInt(raw['dueTimeMinutes'])),
            startTimeMinutes: Value(_optInt(raw['startTimeMinutes'])),
            endTimeMinutes: Value(_optInt(raw['endTimeMinutes'])),
            notes: Value(_optStr(raw['notes'])),
            workoutId: Value(_optStr(raw['workoutId'])),
            workoutTemplateId: Value(_optStr(raw['workoutTemplateId'])),
            recurrence: Value(_optStr(raw['recurrence'])),
            seriesId: Value(_optStr(raw['seriesId'])),
            createdAt: _int(raw['createdAt']),
          ),
          mode: InsertMode.insertOrIgnore,
        );
        updated++;
      }
      final deleted = await _tombstoneTasks(_names(payload['deleted']));
      await _advance(SyncResource.tasks, serverTime, since);
      return _result(updated, deleted, serverTime);
    } on ApiException catch (e) {
      return SyncResult(error: 'Pull failed (HTTP ${e.statusCode})');
    } catch (e) {
      return SyncResult(error: e.toString());
    }
  }

  // --------------------------------------------------------------------------
  // Notes (tag links ride along; audio stays server-side)
  // --------------------------------------------------------------------------

  Future<SyncResult> pullNotes({
    required String apiKey,
    required String endpoint,
  }) async {
    final since = _state.getLastSyncedAt(SyncResource.notes);
    try {
      final (payload, serverTime) = await _fetch(endpoint, apiKey, since);
      final items = _maps(payload['items']);
      var updated = 0;
      for (final raw in items) {
        final id = raw['id'];
        if (id is! String) continue;
        final existing =
            await (_database.select(_database.notes)
                  ..where((t) => t.id.equals(id)))
                .get();
        if (existing.isNotEmpty) continue;
        await _database.into(_database.notes).insert(
          db.NotesCompanion.insert(
            id: id,
            title: _str(raw['title'], ''),
            body: Value(_str(raw['body'], '')),
            updatedAt: _int(raw['updatedAt']),
            createdAt: _int(raw['createdAt']),
          ),
          mode: InsertMode.insertOrIgnore,
        );
        updated++;
      }
      for (final raw in _maps(payload['noteTags'])) {
        final tagId = raw['tagId'];
        final noteId = raw['noteId'];
        if (tagId is! String || noteId is! String) continue;
        await _database.into(_database.noteTags).insert(
          db.NoteTagsCompanion.insert(tagId: tagId, noteId: noteId),
          mode: InsertMode.insertOrIgnore,
        );
      }
      final deleted = await _tombstoneNotes(_names(payload['deleted']));
      await _advance(SyncResource.notes, serverTime, since);
      return _result(updated, deleted, serverTime);
    } on ApiException catch (e) {
      return SyncResult(error: 'Pull failed (HTTP ${e.statusCode})');
    } catch (e) {
      return SyncResult(error: e.toString());
    }
  }

  // --------------------------------------------------------------------------
  // Goals (progress history rides along)
  // --------------------------------------------------------------------------

  Future<SyncResult> pullGoals({
    required String apiKey,
    required String endpoint,
  }) async {
    final since = _state.getLastSyncedAt(SyncResource.goals);
    try {
      final (payload, serverTime) = await _fetch(endpoint, apiKey, since);
      final goals = await _idSet(_database.goals);
      var updated = 0;
      for (final raw in _maps(payload['items'])) {
        final id = raw['id'];
        if (id is! String) continue;
        final existing =
            await (_database.select(_database.goals)
                  ..where((t) => t.id.equals(id)))
                .get();
        if (existing.isNotEmpty) continue;
        await _database.into(_database.goals).insert(
          db.GoalsCompanion.insert(
            id: id,
            title: _str(raw['title'], ''),
            startDate: _int(raw['startDate']),
            status: Value(_str(raw['status'], 'planned')),
            targetType: Value(_str(raw['targetType'], 'none')),
            reminderTimeMinutes: Value(_int(raw['reminderTimeMinutes'])),
            description: Value(_optStr(raw['description'])),
            endDate: Value(_optInt(raw['endDate'])),
            targetValue: Value(_optDouble(raw['targetValue'])),
            baselineValue: Value(_optDouble(raw['baselineValue'])),
            unit: Value(_optStr(raw['unit'])),
            reminderEnabled: Value(raw['reminderEnabled'] == true),
            createdAt: _int(raw['createdAt']),
            updatedAt: _int(raw['updatedAt']),
          ),
          mode: InsertMode.insertOrIgnore,
        );
        updated++;
      }
      for (final raw in _maps(payload['progressEntries'])) {
        final id = raw['id'];
        final goalId = raw['goalId'];
        if (id is! String || goalId is! String) continue;
        if (!goals.contains(goalId)) continue;
        await _database.into(_database.goalProgressEntries).insert(
          db.GoalProgressEntriesCompanion.insert(
            id: id,
            goalId: goalId,
            recordedAt: _int(raw['recordedAt']),
            value: _double(raw['value']),
            note: Value(_optStr(raw['note'])),
            createdAt: _int(raw['createdAt']),
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
      final deleted = await _tombstoneGoals(_names(payload['deleted']));
      await _advance(SyncResource.goals, serverTime, since);
      return _result(updated, deleted, serverTime);
    } on ApiException catch (e) {
      return SyncResult(error: 'Pull failed (HTTP ${e.statusCode})');
    } catch (e) {
      return SyncResult(error: e.toString());
    }
  }

  // --------------------------------------------------------------------------
  // Workouts (exercise rows skip exercises the device has not imported; their
  // sets land only when the parent exercise row landed)
  // --------------------------------------------------------------------------

  Future<SyncResult> pullWorkouts({
    required String apiKey,
    required String endpoint,
  }) async {
    final since = _state.getLastSyncedAt(SyncResource.workouts);
    try {
      final (payload, serverTime) = await _fetch(endpoint, apiKey, since);
      var updated = 0;
      for (final raw in _maps(payload['workouts'])) {
        final id = raw['id'];
        if (id is! String) continue;
        final existing =
            await (_database.select(_database.workouts)
                  ..where((t) => t.id.equals(id)))
                .get();
        if (existing.isNotEmpty) {
          continue;
        }
        await _database.into(_database.workouts).insert(
          db.WorkoutsCompanion.insert(
            id: id,
            name: _str(raw['name'], ''),
            date: _int(raw['date']),
            startedAt: Value(_optInt(raw['startedAt'])),
            completedAt: Value(_optInt(raw['completedAt'])),
            notes: Value(_optStr(raw['notes'])),
            routineId: Value(_optStr(raw['routineId'])),
            templateId: Value(_optStr(raw['templateId'])),
            createdAt: _int(raw['createdAt']),
          ),
          mode: InsertMode.insertOrIgnore,
        );
        updated++;
      }
      final exercises = await _idSet(_database.exercises);
      for (final raw in _maps(payload['workoutExercises'])) {
        final id = raw['id'];
        final workoutId = raw['workoutId'];
        final exerciseId = raw['exerciseId'];
        if (id is! String || workoutId is! String) continue;
        // `workoutExercises.exerciseId` carries a real foreign key to the local
        // exercises table; a pulled session referencing an exercise this
        // device has not imported is skipped, like the foods client skips
        // unknown ingredients.
        if (exerciseId is! String || !exercises.contains(exerciseId)) continue;
        await _database.into(_database.workoutExercises).insert(
          db.WorkoutExercisesCompanion.insert(
            id: id,
            workoutId: workoutId,
            exerciseId: exerciseId,
            sortOrder: _int(raw['sortOrder']),
            notes: Value(_optStr(raw['notes'])),
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
      for (final raw in _maps(payload['exerciseSets'])) {
        final id = raw['id'];
        if (id is! String) continue;
        await _database.into(_database.exerciseSets).insert(
          db.ExerciseSetsCompanion.insert(
            id: id,
            workoutExerciseId: _str(raw['workoutExerciseId'], ''),
            setNumber: _int(raw['setNumber']),
            reps: Value(_optInt(raw['reps'])),
            weightKg: Value(_optDouble(raw['weightKg'])),
            restSeconds: Value(_optInt(raw['restSeconds'])),
            actualReps: Value(_optInt(raw['actualReps'])),
            actualWeightKg: Value(_optDouble(raw['actualWeightKg'])),
            actualRestSeconds: Value(_optInt(raw['actualRestSeconds'])),
            completedAt: Value(_optInt(raw['completedAt'])),
            durationMinutes: Value(_optInt(raw['durationMinutes'])),
            distanceMeters: Value(_optDouble(raw['distanceMeters'])),
            actualDurationMinutes: Value(_optInt(raw['actualDurationMinutes'])),
            actualDistanceMeters: Value(_optDouble(raw['actualDistanceMeters'])),
            notes: Value(_optStr(raw['notes'])),
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
      final deleted = await _tombstoneWorkouts(_names(payload['deleted']));
      await _advance(SyncResource.workouts, serverTime, since);
      return _result(updated, deleted, serverTime);
    } on ApiException catch (e) {
      return SyncResult(error: 'Pull failed (HTTP ${e.statusCode})');
    } catch (e) {
      return SyncResult(error: e.toString());
    }
  }

  // --------------------------------------------------------------------------
  // Templates (nested exercises with their planned sets, one payload)
  // --------------------------------------------------------------------------

  Future<SyncResult> pullTemplates({
    required String apiKey,
    required String endpoint,
  }) async {
    final since = _state.getLastSyncedAt(SyncResource.templates);
    try {
      final (payload, serverTime) = await _fetch(endpoint, apiKey, since);
      final exercises = await _idSet(_database.exercises);
      var updated = 0;
      for (final raw in _maps(payload['items'])) {
        final id = raw['id'];
        if (id is! String) continue;
        final existing =
            await (_database.select(_database.workoutTemplates)
                  ..where((t) => t.id.equals(id)))
                .get();
        if (existing.isNotEmpty) continue;
        await _database.into(_database.workoutTemplates).insert(
          db.WorkoutTemplatesCompanion.insert(
            id: id,
            name: _str(raw['name'], ''),
            startDate: _int(raw['startDate']),
            notes: Value(_optStr(raw['notes'])),
            recurrence: Value(_optStr(raw['recurrence'])),
            excludedDates: Value(_optStr(raw['excludedDates'])),
            sourceRoutineId: Value(_optStr(raw['sourceRoutineId'])),
            createdAt: _int(raw['createdAt']),
            updatedAt: _int(raw['updatedAt']),
          ),
          mode: InsertMode.insertOrIgnore,
        );
        updated++;
        for (final exRaw in _maps(raw['exercises'])) {
          final exerciseId = exRaw['exerciseId'];
          if (exerciseId is! String || !exercises.contains(exerciseId)) continue;
          final weId = exRaw['id'];
          if (weId is! String) continue;
          await _database.into(_database.workoutTemplateExercises).insert(
            db.WorkoutTemplateExercisesCompanion.insert(
              id: weId,
              templateId: id,
              exerciseId: exerciseId,
              sortOrder: _int(exRaw['sortOrder']),
              notes: Value(_optStr(exRaw['notes'])),
            ),
            mode: InsertMode.insertOrIgnore,
          );
          // The wire nests each exercise's planned sets inside the exercise
          // object, mirroring how the push handlers read them.
          for (final setRaw in _maps(exRaw['sets'])) {
            final setId = setRaw['id'];
            if (setId is! String) continue;
            await _database.into(_database.workoutTemplateSets).insert(
              db.WorkoutTemplateSetsCompanion.insert(
                id: setId,
                templateExerciseId: weId,
                setNumber: _int(setRaw['setNumber']),
                reps: Value(_optInt(setRaw['reps'])),
                weightKg: Value(_optDouble(setRaw['weightKg'])),
                restSeconds: Value(_optInt(setRaw['restSeconds'])),
                durationMinutes: Value(_optInt(setRaw['durationMinutes'])),
                distanceMeters: Value(_optDouble(setRaw['distanceMeters'])),
              ),
              mode: InsertMode.insertOrIgnore,
            );
          }
        }
      }
      final deleted = await _tombstoneTemplates(_names(payload['deleted']));
      await _advance(SyncResource.templates, serverTime, since);
      return _result(updated, deleted, serverTime);
    } on ApiException catch (e) {
      return SyncResult(error: 'Pull failed (HTTP ${e.statusCode})');
    } catch (e) {
      return SyncResult(error: e.toString());
    }
  }

  // --------------------------------------------------------------------------
  // Experiments (daily check-ins ride along)
  // --------------------------------------------------------------------------

  Future<SyncResult> pullExperiments({
    required String apiKey,
    required String endpoint,
  }) async {
    final since = _state.getLastSyncedAt(SyncResource.experiments);
    try {
      final (payload, serverTime) = await _fetch(endpoint, apiKey, since);
      final landed = <String>{};
      var updated = 0;
      for (final raw in _maps(payload['items'])) {
        final id = raw['id'];
        if (id is! String) continue;
        final existing =
            await (_database.select(_database.experiments)
                  ..where((t) => t.id.equals(id)))
                .get();
        if (existing.isNotEmpty) continue;
        await _database.into(_database.experiments).insert(
          db.ExperimentsCompanion.insert(
            id: id,
            name: _str(raw['name'], ''),
            startDate: _int(raw['startDate']),
            purpose: Value(_optStr(raw['purpose'])),
            endDate: Value(_optInt(raw['endDate'])),
            status: Value(_str(raw['status'], 'planned')),
            categories: Value(_optStr(raw['categories'])),
            reminderEnabled: Value(raw['reminderEnabled'] == true),
            reminderTimeMinutes: Value(_int(raw['reminderTimeMinutes'])),
            createdAt: _int(raw['createdAt']),
          ),
          mode: InsertMode.insertOrIgnore,
        );
        landed.add(id);
        updated++;
      }
      for (final raw in _maps(payload['checkins'])) {
        final id = raw['id'];
        final experimentId = raw['experimentId'];
        if (id is! String || experimentId is! String) continue;
        if (!landed.contains(experimentId)) continue;
        await _database.into(_database.experimentCheckins).insert(
          db.ExperimentCheckinsCompanion.insert(
            id: id,
            experimentId: experimentId,
            day: _int(raw['day']),
            rating: _int(raw['rating']),
            note: Value(_optStr(raw['note'])),
            createdAt: _int(raw['createdAt']),
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
      var deleted = 0;
      for (final id in _names(payload['deleted'])) {
        // The shared tombstone list covers experiments and their check-ins;
        // deleting whichever table holds the id keeps it honest.
        var hit = await (_database.delete(
          _database.experiments,
        )..where((t) => t.id.equals(id))).go();
        if (hit == 0) {
          hit = await (_database.delete(
            _database.experimentCheckins,
          )..where((t) => t.id.equals(id))).go();
        }
        deleted += hit > 0 ? 1 : 0;
      }
      await _advance(SyncResource.experiments, serverTime, since);
      return _result(updated, deleted, serverTime);
    } on ApiException catch (e) {
      return SyncResult(error: 'Pull failed (HTTP ${e.statusCode})');
    } catch (e) {
      return SyncResult(error: e.toString());
    }
  }

  // --------------------------------------------------------------------------
  // Meals (logged foods ride along)
  // --------------------------------------------------------------------------

  Future<SyncResult> pullMeals({
    required String apiKey,
    required String endpoint,
  }) async {
    final since = _state.getLastSyncedAt(SyncResource.meals);
    try {
      final (payload, serverTime) = await _fetch(endpoint, apiKey, since);
      final landed = <String>{};
      var updated = 0;
      for (final raw in _maps(payload['meals'])) {
        final id = raw['id'];
        if (id is! String) continue;
        final existing =
            await (_database.select(_database.meals)
                  ..where((t) => t.id.equals(id)))
                .get();
        if (existing.isNotEmpty) continue;
        await _database.into(_database.meals).insert(
          db.MealsCompanion.insert(
            id: id,
            name: _str(raw['name'], ''),
            eatenAt: _int(raw['eatenAt']),
            createdAt: _int(raw['createdAt']),
          ),
          mode: InsertMode.insertOrIgnore,
        );
        landed.add(id);
        updated++;
      }
      for (final raw in _maps(payload['mealFoods'])) {
        final id = raw['id'];
        final mealId = raw['mealId'];
        if (id is! String || mealId is! String) continue;
        if (!landed.contains(mealId)) continue;
        await _database.into(_database.mealFoods).insert(
          db.MealFoodsCompanion.insert(
            id: id,
            mealId: mealId,
            foodId: _str(raw['foodId'], ''),
            amount: _double(raw['amount']),
            calories: _double(raw['calories']),
            protein: _double(raw['protein']),
            carbs: _double(raw['carbs']),
            fat: _double(raw['fat']),
            sodium: Value(_double(raw['sodium'])),
            fiber: Value(_double(raw['fiber'])),
            sugar: Value(_double(raw['sugar'])),
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
      var deleted = 0;
      for (final id in _names(payload['deleted'])) {
        var hit = await (_database.delete(
          _database.meals,
        )..where((t) => t.id.equals(id))).go();
        if (hit == 0) {
          hit = await (_database.delete(
            _database.mealFoods,
          )..where((t) => t.id.equals(id))).go();
        }
        deleted += hit > 0 ? 1 : 0;
      }
      await _advance(SyncResource.meals, serverTime, since);
      return _result(updated, deleted, serverTime);
    } on ApiException catch (e) {
      return SyncResult(error: 'Pull failed (HTTP ${e.statusCode})');
    } catch (e) {
      return SyncResult(error: e.toString());
    }
  }

  // --------------------------------------------------------------------------
  // Single-table resources
  // --------------------------------------------------------------------------

  Future<SyncResult> pullBodyMetrics({
    required String apiKey,
    required String endpoint,
  }) async {
    final since = _state.getLastSyncedAt(SyncResource.bodyMetrics);
    try {
      final (payload, serverTime) = await _fetch(endpoint, apiKey, since);
      var updated = 0;
      for (final raw in _maps(payload['items'])) {
        final id = raw['id'];
        if (id is! String) continue;
        final existing =
            await (_database.select(_database.bodyMetrics)
                  ..where((t) => t.id.equals(id)))
                .get();
        if (existing.isNotEmpty) continue;
        await _database.into(_database.bodyMetrics).insert(
          db.BodyMetricsCompanion.insert(
            id: id,
            date: _int(raw['date']),
            weightKg: Value(_optDouble(raw['weightKg'])),
            heightCm: Value(_optDouble(raw['heightCm'])),
            createdAt: _int(raw['createdAt']),
          ),
          mode: InsertMode.insertOrIgnore,
        );
        updated++;
      }
      var deleted = 0;
      for (final id in _names(payload['deleted'])) {
        deleted += await (_database.delete(
          _database.bodyMetrics,
        )..where((t) => t.id.equals(id))).go();
      }
      await _advance(SyncResource.bodyMetrics, serverTime, since);
      return _result(updated, deleted, serverTime);
    } on ApiException catch (e) {
      return SyncResult(error: 'Pull failed (HTTP ${e.statusCode})');
    } catch (e) {
      return SyncResult(error: e.toString());
    }
  }

  Future<SyncResult> pullBudgetAccounts({
    required String apiKey,
    required String endpoint,
  }) async {
    final since = _state.getLastSyncedAt(SyncResource.budgetAccounts);
    try {
      final (payload, serverTime) = await _fetch(endpoint, apiKey, since);
      var updated = 0;
      for (final raw in _maps(payload['items'])) {
        final id = raw['id'];
        if (id is! String) continue;
        final existing =
            await (_database.select(_database.accounts)
                  ..where((t) => t.id.equals(id)))
                .get();
        if (existing.isNotEmpty) continue;
        await _database.into(_database.accounts).insert(
          db.AccountsCompanion.insert(
            id: id,
            name: _str(raw['name'], ''),
            type: _str(raw['type'], 'other'),
            openingBalance: Value(_double(raw['openingBalance'])),
            note: Value(_optStr(raw['note'])),
            createdAt: _int(raw['createdAt']),
          ),
          mode: InsertMode.insertOrIgnore,
        );
        updated++;
      }
      var deleted = 0;
      for (final id in _names(payload['deleted'])) {
        deleted += await (_database.delete(
          _database.accounts,
        )..where((t) => t.id.equals(id))).go();
      }
      await _advance(SyncResource.budgetAccounts, serverTime, since);
      return _result(updated, deleted, serverTime);
    } on ApiException catch (e) {
      return SyncResult(error: 'Pull failed (HTTP ${e.statusCode})');
    } catch (e) {
      return SyncResult(error: e.toString());
    }
  }

  Future<SyncResult> pullTransactions({
    required String apiKey,
    required String endpoint,
  }) async {
    final since = _state.getLastSyncedAt(SyncResource.transactions);
    try {
      final (payload, serverTime) = await _fetch(endpoint, apiKey, since);
      final accounts = await _idSet(_database.accounts);
      var updated = 0;
      for (final raw in _maps(payload['items'])) {
        final id = raw['id'];
        if (id is! String) continue;
        final existing =
            await (_database.select(_database.transactions)
                  ..where((t) => t.id.equals(id)))
                .get();
        if (existing.isNotEmpty) continue;
        final accountId = _optStr(raw['accountId']);
        final toAccountId = _optStr(raw['toAccountId']);
        // The local transactions table carries real foreign keys to accounts;
        // a row whose accounts never landed is skipped rather than aborting.
        if ((accountId != null && !accounts.contains(accountId)) ||
            (toAccountId != null && !accounts.contains(toAccountId))) {
          continue;
        }
        await _database.into(_database.transactions).insert(
          db.TransactionsCompanion.insert(
            id: id,
            type: _str(raw['type'], 'expense'),
            amount: _double(raw['amount']),
            currencyCode: _str(raw['currencyCode'], ''),
            amountBase: _double(raw['amountBase']),
            rateUsed: _double(raw['rateUsed']),
            date: _int(raw['date']),
            accountId: accountId == null ? const Value.absent() : Value(accountId),
            toAccountId: toAccountId == null
                ? const Value.absent()
                : Value(toAccountId),
            category: Value(_optStr(raw['category'])),
            note: Value(_optStr(raw['note'])),
            receiptId: Value(_optStr(raw['receiptId'])),
            isDraft: Value(raw['isDraft'] == true),
            createdAt: _int(raw['createdAt']),
          ),
          mode: InsertMode.insertOrIgnore,
        );
        updated++;
      }
      var deleted = 0;
      for (final id in _names(payload['deleted'])) {
        deleted += await (_database.delete(
          _database.transactions,
        )..where((t) => t.id.equals(id))).go();
      }
      await _advance(SyncResource.transactions, serverTime, since);
      return _result(updated, deleted, serverTime);
    } on ApiException catch (e) {
      return SyncResult(error: 'Pull failed (HTTP ${e.statusCode})');
    } catch (e) {
      return SyncResult(error: e.toString());
    }
  }

  // --------------------------------------------------------------------------
  // Server-wins resources
  // --------------------------------------------------------------------------

  /// Tags: the shared vocabulary. `tags.name` is unique locally, so a server
  /// rename that collides with another local id is skipped rather than
  /// corrupting the vocabulary.
  Future<SyncResult> pullTags({
    required String apiKey,
    required String endpoint,
  }) async {
    final since = _state.getLastSyncedAt(SyncResource.tags);
    try {
      final (payload, serverTime) = await _fetch(endpoint, apiKey, since);
      var updated = 0;
      for (final raw in _maps(payload['items'])) {
        final id = raw['id'];
        final name = raw['name'];
        if (id is! String || name is! String) continue;
        final rows =
            await (_database.select(
              _database.tags,
            )..where((t) => t.name.equals(name))).get();
        if (rows.any((t) => t.id != id)) continue;
        await _database.into(_database.tags).insert(
          db.TagsCompanion.insert(
            id: id,
            name: name,
            color: Value(_optInt(raw['color'])),
            sortOrder: Value(_int(raw['sortOrder'])),
            createdAt: _int(raw['createdAt']),
            updatedAt: _int(raw['updatedAt']),
          ),
          mode: InsertMode.insertOrReplace,
        );
        updated++;
      }
      var deleted = 0;
      for (final id in _names(payload['deleted'])) {
        deleted += await (_database.delete(
          _database.tags,
        )..where((t) => t.id.equals(id))).go();
      }
      await _advance(SyncResource.tags, serverTime, since);
      return _result(updated, deleted, serverTime);
    } on ApiException catch (e) {
      return SyncResult(error: 'Pull failed (HTTP ${e.statusCode})');
    } catch (e) {
      return SyncResult(error: e.toString());
    }
  }

  /// Receipts mirror the server rows, including the OCR parse — the images
  /// themselves stay server-side and are never downloaded here.
  Future<SyncResult> pullReceipts({
    required String apiKey,
    required String endpoint,
  }) async {
    final since = _state.getLastSyncedAt(SyncResource.receipts);
    try {
      final (payload, serverTime) = await _fetch(endpoint, apiKey, since);
      var updated = 0;
      for (final raw in _maps(payload['items'])) {
        final id = raw['id'];
        if (id is! String) continue;
        await _database.into(_database.receipts).insert(
          db.ReceiptsCompanion.insert(
            id: id,
            localPath: _str(raw['localPath'], ''),
            remotePath: Value(_optStr(raw['remotePath'])),
            uploadStatus: Value(_int(raw['uploadStatus'])),
            parsed: Value(raw['parsed'] == true),
            parsedJson: Value(_optStr(raw['parsedJson'])),
            transactionId: Value(_optStr(raw['transactionId'])),
            createdAt: _int(raw['createdAt']),
          ),
          mode: InsertMode.insertOrReplace,
        );
        updated++;
      }
      var deleted = 0;
      for (final id in _names(payload['deleted'])) {
        deleted += await (_database.delete(
          _database.receipts,
        )..where((t) => t.id.equals(id))).go();
      }
      await _advance(SyncResource.receipts, serverTime, since);
      return _result(updated, deleted, serverTime);
    } on ApiException catch (e) {
      return SyncResult(error: 'Pull failed (HTTP ${e.statusCode})');
    } catch (e) {
      return SyncResult(error: e.toString());
    }
  }

  // --------------------------------------------------------------------------
  // Scaffolding
  // --------------------------------------------------------------------------

  /// Decodes the pull response for [endpoint] (or fails with a message the
  /// caller turns into a [SyncResult.error]).
  Future<(Map<String, Object?>, int)> _fetch(
    String endpoint,
    String apiKey,
    int since,
  ) async {
    final response = await _api.getJson(
      endpoint,
      query: {'since': '$since'},
      headers: authHeaders(apiKey),
    );
    if (response is! Map) throw StateError(_error);
    final payload = Map<String, Object?>.from(response);
    final serverTime = (payload['server_time'] as num?)?.toInt() ?? since;
    return (payload, serverTime);
  }

  Future<void> _advance(SyncResource resource, int serverTime, int since) async {
    if (serverTime > since) {
      await _state.setLastSyncedAt(resource, serverTime);
    }
  }

  SyncResult _result(int updated, int deleted, int serverTime) =>
      SyncResult(updated: updated, deleted: deleted, serverTime: serverTime);

  List<Map> _maps(Object? raw) => [
    for (final item in (raw is List ? raw : const <Object>[]))
      if (item is Map) item,
  ];

  Set<String> _names(Object? raw) => {
    for (final id in (raw is List ? raw : const <Object>[]))
      if (id is String) id,
  };

  /// The ids a pulled child row may reference. A missing referenced id means
  /// the child cannot be linked locally, so callers skip it instead of
  /// tripping the child table's foreign key.
  Future<Set<String>> _idSet(dynamic table) async {
    final rows = await _database.select(table).get();
    return {for (final row in rows) row.id as String};
  }

  int _int(Object? raw) => raw is num ? raw.toInt() : 0;
  int? _optInt(Object? raw) => raw is num ? raw.toInt() : null;
  double _double(Object? raw) => raw is num ? raw.toDouble() : 0.0;
  double? _optDouble(Object? raw) => raw is num ? raw.toDouble() : null;
  String _str(Object? raw, String fallback) => raw is String ? raw : fallback;
  String? _optStr(Object? raw) => raw is String ? raw : null;

  // --------------------------------------------------------------------------
  // Tombstones — apply-if-absent means a tombstoned id must delete the local
  // row with its dependents, or the deletion is invisible.
  // --------------------------------------------------------------------------

  Future<int> _tombstoneTasks(Set<String> ids) async {
    var deleted = 0;
    for (final id in ids) {
      final hit = await (_database.delete(
        _database.tasks,
      )..where((t) => t.id.equals(id))).go();
      if (hit > 0) {
        for (final statement in [
          'DELETE FROM task_tags WHERE task_id = ?1',
          'DELETE FROM task_goals WHERE task_id = ?1',
          'DELETE FROM task_experiments WHERE task_id = ?1',
          'DELETE FROM task_notes WHERE task_id = ?1',
        ]) {
          await _database.customStatement(statement, [id]);
        }
        deleted++;
      }
    }
    return deleted;
  }

  Future<int> _tombstoneNotes(Set<String> ids) async {
    var deleted = 0;
    for (final id in ids) {
      final hit = await (_database.delete(
        _database.notes,
      )..where((t) => t.id.equals(id))).go();
      if (hit > 0) {
        for (final statement in [
          'DELETE FROM note_tags WHERE note_id = ?1',
          'DELETE FROM note_audio WHERE note_id = ?1',
          'DELETE FROM task_notes WHERE note_id = ?1',
          'DELETE FROM experiment_notes WHERE note_id = ?1',
          'DELETE FROM goal_notes WHERE note_id = ?1',
          'DELETE FROM note_workouts WHERE note_id = ?1',
        ]) {
          await _database.customStatement(statement, [id]);
        }
        deleted++;
      }
    }
    return deleted;
  }

  Future<int> _tombstoneGoals(Set<String> ids) async {
    var deleted = 0;
    for (final id in ids) {
      var hit = await (_database.delete(
        _database.goals,
      )..where((t) => t.id.equals(id))).go();
      if (hit > 0) {
        // Progress entries carry no foreign key, so a row under a tombstoned
        // goal must go explicitly or a later pull resurrects it as an orphan.
        await _database.customStatement(
          'DELETE FROM goal_progress_entries WHERE goal_id = ?1',
          [id],
        );
        for (final statement in [
          'DELETE FROM goal_tags WHERE goal_id = ?1',
          'DELETE FROM task_goals WHERE goal_id = ?1',
          'DELETE FROM experiment_goals WHERE goal_id = ?1',
          'DELETE FROM goal_notes WHERE goal_id = ?1',
          'DELETE FROM goal_workouts WHERE goal_id = ?1',
        ]) {
          await _database.customStatement(statement, [id]);
        }
      } else {
        hit = await (_database.delete(
          _database.goalProgressEntries,
        )..where((t) => t.id.equals(id))).go();
      }
      deleted += hit > 0 ? 1 : 0;
    }
    return deleted;
  }

  Future<int> _tombstoneWorkouts(Set<String> ids) async {
    var deleted = 0;
    for (final id in ids) {
      final hit = await (_database.delete(
        _database.workouts,
      )..where((t) => t.id.equals(id))).go();
      if (hit > 0) {
        final ses =
            await (_database.select(
              _database.workoutExercises,
            )..where((t) => t.workoutId.equals(id))).get();
        for (final se in ses) {
          await (_database.delete(
            _database.exerciseSets,
          )..where((t) => t.workoutExerciseId.equals(se.id))).go();
        }
        await (_database.delete(
          _database.workoutExercises,
        )..where((t) => t.workoutId.equals(id))).go();
        deleted++;
      }
    }
    return deleted;
  }

  Future<int> _tombstoneTemplates(Set<String> ids) async {
    var deleted = 0;
    for (final id in ids) {
      final hit = await (_database.delete(
        _database.workoutTemplates,
      )..where((t) => t.id.equals(id))).go();
      if (hit > 0) {
        final tes =
            await (_database.select(
              _database.workoutTemplateExercises,
            )..where((t) => t.templateId.equals(id))).get();
        for (final te in tes) {
          await (_database.delete(
            _database.workoutTemplateSets,
          )..where((t) => t.templateExerciseId.equals(te.id))).go();
        }
        await (_database.delete(
          _database.workoutTemplateExercises,
        )..where((t) => t.templateId.equals(id))).go();
        deleted++;
      }
    }
    return deleted;
  }
}

/// Pulls one personal resource into the local database using the configured
/// server + endpoints — the receiving counterpart of [pushDataType].
Future<SyncResult> pullDataType(WidgetRef ref, String type) async {
  final settings = ref.read(settingsProvider);
  final service = PersonalPullService(
    HttpApiClient(
      http.Client(),
      baseUrl: settings.remoteSyncBaseUrl,
      timeout: Duration(seconds: settings.apiTimeoutSeconds),
    ),
    ref.read(db.databaseProvider),
    PrefsSyncStateStore(ref.read(sharedPreferencesProvider)),
  );
  final key = settings.remoteSyncApiKey;
  switch (type) {
    case 'tasks':
      return service.pullTasks(apiKey: key, endpoint: settings.endpointTasks);
    case 'notes':
      return service.pullNotes(apiKey: key, endpoint: settings.endpointNotes);
    case 'goals':
      return service.pullGoals(apiKey: key, endpoint: settings.endpointGoals);
    case 'workouts':
      return service.pullWorkouts(
        apiKey: key,
        endpoint: settings.endpointWorkouts,
      );
    case 'templates':
      return service.pullTemplates(
        apiKey: key,
        endpoint: settings.endpointTemplates,
      );
    case 'experiments':
      return service.pullExperiments(
        apiKey: key,
        endpoint: settings.endpointExperiments,
      );
    case 'meals':
      return service.pullMeals(apiKey: key, endpoint: settings.endpointMeals);
    case 'bodyMetrics':
      return service.pullBodyMetrics(
        apiKey: key,
        endpoint: settings.endpointBodyMetrics,
      );
    case 'budgetAccounts':
      return service.pullBudgetAccounts(
        apiKey: key,
        endpoint: settings.endpointBudgetAccounts,
      );
    case 'transactions':
      return service.pullTransactions(
        apiKey: key,
        endpoint: settings.endpointTransactions,
      );
    case 'receiptPictures':
      return service.pullReceipts(
        apiKey: key,
        endpoint: settings.endpointReceiptPictures,
      );
    case 'tags':
      return service.pullTags(apiKey: key, endpoint: settings.endpointTags);
    default:
      return SyncResult(error: 'Unknown pull type: $type');
  }
}
