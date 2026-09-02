import 'dart:io';

import '../models/exercise.dart';
import '../network/api_client.dart';
import '../exercise/repositories/exercise_repository.dart';
import 'exercise_media_sync.dart';
import 'sync_models.dart';

/// Pulls exercises from the sync server: `GET /exercises?since=<cursor>` with
/// a Bearer API key. Each changed row is upserted (server authority); deleted
/// ids are hard-deleted locally.
///
/// Media is never part of the row payload: the server only advertises
/// availability via `hasImage` / `hasVideo`, and [ExerciseMediaDownloader]
/// fetches `<base>/exercises/<id>.jpg|.mp4` into app-local storage. The local
/// file paths live in the exercise's `imagePath` / `videoPath` columns and are
/// preserved across pulls (a re-pull must not clobber a downloaded file), and
/// cleared — with the file removed — when the server stops advertising them.
final class ExerciseSyncClient {
  ExerciseSyncClient(this._api, this._repo, {ExerciseMediaDownloader? media})
    : _media = media ?? ExerciseMediaDownloader(_api);

  final ApiClient _api;
  final ExerciseRepository _repo;
  final ExerciseMediaDownloader _media;

  static const _path = '/exercises';

  Future<SyncResult> sync({
    required int since,
    required String apiKey,
    String endpoint = _path,
  }) async {
    try {
      final payload = await _api.getJson(
        endpoint,
        query: {'since': '$since'},
        headers: ExerciseMediaDownloader.auth(apiKey),
      );
      if (payload is! Map) {
        return const SyncResult(error: 'Unexpected exercises payload');
      }
      final serverTime = (payload['server_time'] as num?)?.toInt() ?? since;

      var updated = 0;
      var deleted = 0;
      var mediaFailed = false;
      final items = payload['items'];
      if (items is List) {
        for (final raw in items) {
          if (raw is! Map) continue;
          final parsed = parseExercise(raw, serverTime);
          if (parsed == null) continue;
          final (incoming, hasImage, hasVideo) = parsed;
          final existing = await _repo.getById(incoming.id);
          final saved = await _reconciled(
            incoming,
            existing,
            hasImage: hasImage,
            hasVideo: hasVideo,
          );
          await _repo.upsert(saved);
          updated++;
          if (!await _applyMedia(
            existing,
            saved,
            hasImage: hasImage,
            hasVideo: hasVideo,
            apiKey: apiKey,
          )) {
            mediaFailed = true;
          }
        }
      }

      final deletedRaw = payload['deleted'];
      if (deletedRaw is List) {
        for (final id in deletedRaw) {
          if (id is! String) continue;
          await _media.remove(id, ExerciseMediaKind.image);
          await _media.remove(id, ExerciseMediaKind.video);
          await _repo.delete(id);
          deleted++;
        }
      }

      // A failed media download keeps the last good cursor (no partial
      // advancement): the next pull re-fetches these rows and retries.
      if (mediaFailed) {
        return SyncResult(
          error: 'Exercise media download failed',
          updated: updated,
          deleted: deleted,
        );
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

  /// Merges server metadata with the locally-downloaded media state: keep a
  /// path only while its file still exists on disk; null it out when the
  /// server no longer advertises that medium. The result is what gets upserted,
  /// so a pull can never wipe an already-downloaded file.
  Future<Exercise> _reconciled(
    Exercise incoming,
    Exercise? existing, {
    required bool hasImage,
    required bool hasVideo,
  }) async {
    return incoming.copyWith(
      imagePath: hasImage ? await _kept(existing?.imagePath) : null,
      videoPath: hasVideo ? await _kept(existing?.videoPath) : null,
    );
  }

  Future<String?> _kept(String? path) async {
    if (path == null) return null;
    return await File(path).exists() ? path : null;
  }

  /// Removes stale files for media the server dropped and downloads advertised
  /// media missing from disk, persisting the resulting local paths. Returns
  /// false when any download failed so the whole pull is retried.
  Future<bool> _applyMedia(
    Exercise? existing,
    Exercise saved, {
    required bool hasImage,
    required bool hasVideo,
    required String apiKey,
  }) async {
    var ok = true;

    Future<void> applyOne(
      ExerciseMediaKind kind,
      bool present,
      String? oldPath,
      String? newPath,
    ) async {
      if (!present) {
        if (oldPath != null) await _media.remove(saved.id, kind);
        return;
      }
      if (newPath != null) return;
      try {
        final downloaded = await _media.download(
          exerciseId: saved.id,
          kind: kind,
          apiKey: apiKey,
        );
        if (kind == ExerciseMediaKind.image) {
          await _repo.updateMedia(saved.id, imagePath: downloaded);
        } else {
          await _repo.updateMedia(saved.id, videoPath: downloaded);
        }
      } catch (_) {
        ok = false;
      }
    }

    await applyOne(
      ExerciseMediaKind.image,
      hasImage,
      existing?.imagePath,
      saved.imagePath,
    );
    await applyOne(
      ExerciseMediaKind.video,
      hasVideo,
      existing?.videoPath,
      saved.videoPath,
    );
    return ok;
  }

  /// Parses one payload row into `(exercise, hasImage, hasVideo)`. The payload
  /// carries no media paths — those are derived from the id and managed
  /// client-side — so any `imagePath`/`videoPath` in the JSON is ignored.
  /// Public for tests; not part of the client's surface.
  static (Exercise, bool, bool)? parseExercise(
    Map<Object?, Object?> raw,
    int serverTime,
  ) {
    final id = raw['id'];
    final name = raw['name'];
    if (id is! String || name is! String) return null;
    final ts = raw['updated_at'] ?? raw['created_at'];
    final exercise = Exercise(
      id: id,
      name: name,
      exerciseType: raw['exerciseType'] as String? ?? 'weightlifting',
      bodyPart: raw['bodyPart'] as String?,
      equipment: raw['equipment'] as String?,
      primaryMuscle: raw['primaryMuscle'] as String?,
      secondaryMuscle: raw['secondaryMuscle'] as String?,
      instructions: _stringList(raw['instructions']),
      tips: _stringList(raw['tips']),
      faqs: raw['faqs'] as String?,
      keywords: _stringList(raw['keywords']),
      similarTo: raw['similarTo'] as String?,
      tags: _stringList(raw['tags']),
      isCanonical: (raw['isCanonical'] as bool?) ?? false,
      createdAt: toSyncDateTime(ts, serverTime),
    );
    return (exercise, raw['hasImage'] == true, raw['hasVideo'] == true);
  }

  static List<String>? _stringList(Object? value) {
    if (value is List) return value.whereType<String>().toList();
    return null;
  }
}
