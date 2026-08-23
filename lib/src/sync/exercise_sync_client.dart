import '../models/exercise.dart';
import '../network/api_client.dart';
import '../exercise/repositories/exercise_repository.dart';
import 'sync_models.dart';

/// Pulls exercises from the sync server: `GET /exercises?since=<cursor>` with
/// a Bearer API key. Each changed row is upserted (server authority); deleted
/// ids are hard-deleted locally.
final class ExerciseSyncClient {
  final ApiClient _api;
  final ExerciseRepository _repo;

  const ExerciseSyncClient(this._api, this._repo);

  static const _path = '/exercises';

  Future<SyncResult> sync({required int since, required String apiKey}) async {
    try {
      final payload = await _api.getJson(
        _path,
        query: {'since': '$since'},
        headers: _auth(apiKey),
      );
      if (payload is! Map) {
        return const SyncResult(error: 'Unexpected exercises payload');
      }
      final serverTime = (payload['server_time'] as num?)?.toInt() ?? since;

      var updated = 0;
      final items = payload['items'];
      if (items is List) {
        for (final raw in items) {
          if (raw is! Map) continue;
          final exercise = _parseExercise(raw, serverTime);
          if (exercise == null) continue;
          await _repo.upsert(exercise);
          updated++;
        }
      }

      var deleted = 0;
      final deletedRaw = payload['deleted'];
      if (deletedRaw is List) {
        for (final id in deletedRaw) {
          if (id is String) {
            await _repo.delete(id);
            deleted++;
          }
        }
      }

      return SyncResult(
        updated: updated,
        deleted: deleted,
        serverTime: serverTime,
      );
    } on ApiException catch (e) {
      return SyncResult(error: 'Sync failed (HTTP ${e.statusCode})');
    } catch (e) {
      return SyncResult(error: e.toString());
    }
  }

  static Map<String, String> _auth(String apiKey) => {
    'Authorization': 'Bearer $apiKey',
  };

  static List<String>? _stringList(Object? value) {
    if (value is List) return value.whereType<String>().toList();
    return null;
  }

  static Exercise? _parseExercise(Map<Object?, Object?> raw, int serverTime) {
    final id = raw['id'];
    final name = raw['name'];
    if (id is! String || name is! String) return null;
    final ts = raw['updated_at'] ?? raw['created_at'];
    return Exercise(
      id: id,
      name: name,
      exerciseType: raw['exerciseType'] as String? ?? 'weightlifting',
      isLocked: (raw['isLocked'] as bool?) ?? false,
      bodyPart: raw['bodyPart'] as String?,
      equipment: raw['equipment'] as String?,
      primaryMuscle: raw['primaryMuscle'] as String?,
      secondaryMuscle: raw['secondaryMuscle'] as String?,
      instructions: _stringList(raw['instructions']),
      tips: _stringList(raw['tips']),
      faqs: raw['faqs'] as String?,
      keywords: _stringList(raw['keywords']),
      imagePath: raw['imagePath'] as String?,
      videoPath: raw['videoPath'] as String?,
      similarTo: raw['similarTo'] as String?,
      tags: _stringList(raw['tags']),
      isCanonical: (raw['isCanonical'] as bool?) ?? false,
      createdAt: toSyncDateTime(ts, serverTime),
    );
  }
}
