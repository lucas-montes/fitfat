import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../database/database_provider.dart' as db;
import '../network/api_client.dart';
import '../settings/providers/settings.dart';

/// Result of pushing one entity type to the server (push-only sync).
final class PushResult {
  const PushResult({required this.count, this.error});

  final int count;
  final String? error;

  bool get ok => error == null;
}

/// Pushes local data to the configured server (one-way, local -> server).
///
/// The wire format is a JSON object grouping the relevant Drift tables by
/// name, e.g. `{"workouts":[...], "workoutExercises":[...], "exerciseSets":[...]}`
/// POSTed to the operation's endpoint. This captures the full entity graph
/// (parent rows + their child/relation tables) in one request.
final class DataPushService {
  const DataPushService(this.client);

  final ApiClient client;

  Future<PushResult> _pushObject(
    String baseUrl,
    String apiKey,
    String endpoint,
    Map<String, Object?> body,
  ) async {
    try {
      if (baseUrl.isEmpty) {
        return const PushResult(count: 0, error: 'No server URL configured');
      }
      await client.postJson(
        endpoint,
        body: body,
        headers: authHeaders(apiKey),
      );
      return PushResult(count: 1);
    } catch (e) {
      return PushResult(count: 0, error: '$e');
    }
  }

  Future<PushResult> pushWorkouts(WidgetRef ref, String baseUrl, String apiKey, String endpoint) async {
    final database = ref.read(db.databaseProvider);
    final workouts = await database.select(database.workouts).get();
    final exercises = await database.select(database.workoutExercises).get();
    final sets = await database.select(database.exerciseSets).get();
    return _pushObject(baseUrl, apiKey, endpoint, {
      'workouts': workouts.map((e) => e.toJson()).toList(),
      'workoutExercises': exercises.map((e) => e.toJson()).toList(),
      'exerciseSets': sets.map((e) => e.toJson()).toList(),
    });
  }

  Future<PushResult> pushTemplates(WidgetRef ref, String baseUrl, String apiKey, String endpoint) async {
    final database = ref.read(db.databaseProvider);
    final templates = await database.select(database.workoutTemplates).get();
    final exercises = await database.select(database.workoutTemplateExercises).get();
    final sets = await database.select(database.workoutTemplateSets).get();
    return _pushObject(baseUrl, apiKey, endpoint, {
      'workoutTemplates': templates.map((e) => e.toJson()).toList(),
      'workoutTemplateExercises': exercises.map((e) => e.toJson()).toList(),
      'workoutTemplateSets': sets.map((e) => e.toJson()).toList(),
    });
  }

  Future<PushResult> pushNotes(WidgetRef ref, String baseUrl, String apiKey, String endpoint) async {
    final database = ref.read(db.databaseProvider);
    final notes = await database.select(database.notes).get();
    final tags = await database.select(database.noteTags).get();
    final clips = await database.select(database.noteAudio).get();
    return _pushObject(baseUrl, apiKey, endpoint, {
      'notes': notes.map((e) => e.toJson()).toList(),
      'noteTags': tags.map((e) => e.toJson()).toList(),
      'noteAudio': clips.map((e) => e.toJson()).toList(),
    });
  }

  /// Pushes each note voice-clip row as JSON and, when a local audio file
  /// exists, also uploads the bytes via multipart so the server gets the
  /// record + audio together (mirrors [pushReceiptPictures]).
  Future<PushResult> pushNoteAudio(WidgetRef ref, String baseUrl, String apiKey, String endpoint) async {
    try {
      if (baseUrl.isEmpty) {
        return const PushResult(count: 0, error: 'No server URL configured');
      }
      final database = ref.read(db.databaseProvider);
      final rows = await database.select(database.noteAudio).get();
      var pushed = 0;
      for (final r in rows) {
        final data = r.toJson();
        final path = data['audioPath'] as String?;
        Uint8List? bytes;
        if (path != null && path.isNotEmpty) {
          final file = File(path);
          if (await file.exists()) bytes = await file.readAsBytes();
        }
        if (bytes != null) {
          await client.postMultipart(
            endpoint,
            fields: {'noteAudio': jsonEncode(data)},
            files: {'audio': bytes},
            headers: authHeaders(apiKey),
          );
        } else {
          await client.postJson(
            endpoint,
            body: {'noteAudio': [data]},
            headers: authHeaders(apiKey),
          );
        }
        pushed++;
      }
      return PushResult(count: pushed);
    } catch (e) {
      return PushResult(count: 0, error: '$e');
    }
  }

  Future<PushResult> pushTasks(WidgetRef ref, String baseUrl, String apiKey, String endpoint) async {
    final database = ref.read(db.databaseProvider);
    final tasks = await database.select(database.tasks).get();
    final tags = await database.select(database.taskTags).get();
    return _pushObject(baseUrl, apiKey, endpoint, {
      'tasks': tasks.map((e) => e.toJson()).toList(),
      'taskTags': tags.map((e) => e.toJson()).toList(),
    });
  }

  Future<PushResult> pushGoals(WidgetRef ref, String baseUrl, String apiKey, String endpoint) async {
    final database = ref.read(db.databaseProvider);
    final goals = await database.select(database.goals).get();
    final progress = await database.select(database.goalProgressEntries).get();
    final tags = await database.select(database.goalTags).get();
    return _pushObject(baseUrl, apiKey, endpoint, {
      'goals': goals.map((e) => e.toJson()).toList(),
      'goalProgressEntries': progress.map((e) => e.toJson()).toList(),
      'goalTags': tags.map((e) => e.toJson()).toList(),
    });
  }

  Future<PushResult> pushMeals(WidgetRef ref, String baseUrl, String apiKey, String endpoint) async {
    final database = ref.read(db.databaseProvider);
    final meals = await database.select(database.meals).get();
    final items = await database.select(database.mealIngredients).get();
    return _pushObject(baseUrl, apiKey, endpoint, {
      'meals': meals.map((e) => e.toJson()).toList(),
      'mealIngredients': items.map((e) => e.toJson()).toList(),
    });
  }

  Future<PushResult> pushTransactions(WidgetRef ref, String baseUrl, String apiKey, String endpoint) async {
    final database = ref.read(db.databaseProvider);
    final rows = await database.select(database.transactions).get();
    return _pushObject(baseUrl, apiKey, endpoint, {
      'transactions': rows.map((e) => e.toJson()).toList(),
    });
  }

  Future<PushResult> pushBudgetAccounts(WidgetRef ref, String baseUrl, String apiKey, String endpoint) async {
    final database = ref.read(db.databaseProvider);
    final rows = await database.select(database.accounts).get();
    return _pushObject(baseUrl, apiKey, endpoint, {
      'accounts': rows.map((e) => e.toJson()).toList(),
    });
  }

  /// Pushes each receipt row as JSON and, when a local picture exists, also
  /// uploads the image via multipart so the server gets record + bytes.
  Future<PushResult> pushReceiptPictures(WidgetRef ref, String baseUrl, String apiKey, String endpoint) async {
    try {
      if (baseUrl.isEmpty) {
        return const PushResult(count: 0, error: 'No server URL configured');
      }
      final database = ref.read(db.databaseProvider);
      final rows = await database.select(database.receipts).get();
      var pushed = 0;
      for (final r in rows) {
        final data = r.toJson();
        final path = data['picturePath'] as String?;
        Uint8List? bytes;
        if (path != null && path.isNotEmpty) {
          final file = File(path);
          if (await file.exists()) bytes = await file.readAsBytes();
        }
        if (bytes != null) {
          await client.postMultipart(
            endpoint,
            fields: {'receipt': jsonEncode(data)},
            files: {'picture': bytes},
            headers: authHeaders(apiKey),
          );
        } else {
          await client.postJson(
            endpoint,
            body: {'receipts': [data]},
            headers: authHeaders(apiKey),
          );
        }
        pushed++;
      }
      return PushResult(count: pushed);
    } catch (e) {
      return PushResult(count: 0, error: '$e');
    }
  }
}

/// Convenience: resolves the configured [DataPushService] and pushes [type].
Future<PushResult> pushDataType(WidgetRef ref, String type) async {
  final settings = ref.read(settingsProvider);
  final service = DataPushService(
    HttpApiClient(
      http.Client(),
      baseUrl: settings.remoteSyncBaseUrl,
      timeout: Duration(seconds: settings.apiTimeoutSeconds),
    ),
  );
  final base = settings.remoteSyncBaseUrl;
  final key = settings.remoteSyncApiKey;
  switch (type) {
    case 'workouts':
      return service.pushWorkouts(ref, base, key, settings.endpointWorkouts);
    case 'templates':
      return service.pushTemplates(ref, base, key, settings.endpointTemplates);
    case 'notes':
      return service.pushNotes(ref, base, key, settings.endpointNotes);
    case 'noteAudio':
      return service.pushNoteAudio(ref, base, key, settings.endpointNotes);
    case 'tasks':
      return service.pushTasks(ref, base, key, settings.endpointTasks);
    case 'goals':
      return service.pushGoals(ref, base, key, settings.endpointGoals);
    case 'meals':
      return service.pushMeals(ref, base, key, settings.endpointMeals);
    case 'transactions':
      return service.pushTransactions(
        ref,
        base,
        key,
        settings.endpointTransactions,
      );
    case 'budgetAccounts':
      return service.pushBudgetAccounts(
        ref,
        base,
        key,
        settings.endpointBudgetAccounts,
      );
    case 'receiptPictures':
      return service.pushReceiptPictures(
        ref,
        base,
        key,
        settings.endpointReceiptPictures,
      );
    default:
      return PushResult(count: 0, error: 'Unknown type: $type');
  }
}
