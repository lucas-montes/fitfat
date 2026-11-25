import 'dart:io';

import '../models/exercise.dart';
import '../network/api_client.dart';
import '../exercise/repositories/exercise_repository.dart';
import 'exercise_media_sync.dart';
import 'sync_models.dart';

/// Imports individual exercises from the server library. There is no bulk
/// pull: the phone cherry-picks ids (`CatalogSyncClient.importExercises`) and
/// each chosen row is upserted here (server authority).
///
/// Media is never part of the row payload: the server only advertises
/// availability via `hasImage` / `hasVideo`, and [ExerciseMediaDownloader]
/// fetches `<base>/exercises/<id>.jpg|.mp4` into app-local storage. The local
/// file paths live in the exercise's `imagePath` / `videoPath` columns and are
/// preserved across pulls (a re-pull must not clobber a downloaded file), and
/// cleared — with the file removed — when the server stops advertising them.
final class ExerciseSyncClient {
  ExerciseSyncClient(
    ApiClient api,
    this._repo, {
    ExerciseMediaDownloader? media,
  }) : _media = media ?? ExerciseMediaDownloader(api);

  final ExerciseRepository _repo;
  final ExerciseMediaDownloader _media;

  /// Imports one server row: parses, reconciles
  /// client-local media state, upserts, and downloads advertised media missing
  /// from disk. Returns `(imported, mediaOk)` — `imported` is false when the
  /// row is unparseable; `mediaOk` is false when any download failed.
  Future<(bool, bool)> importItem(
    Map<Object?, Object?> raw,
    int serverTime,
    String apiKey,
  ) async {
    final parsed = parseExercise(raw, serverTime);
    if (parsed == null) return (false, true);
    final (incoming, hasImage, hasVideo) = parsed;
    final existing = await _repo.getById(incoming.id);
    final saved = await _reconciled(
      incoming,
      existing,
      hasImage: hasImage,
      hasVideo: hasVideo,
    );
    await _repo.upsert(saved);
    final mediaOk = await _applyMedia(
      existing,
      saved,
      hasImage: hasImage,
      hasVideo: hasVideo,
      apiKey: apiKey,
    );
    return (true, mediaOk);
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
    final bodyPart = raw['bodyPart'] as String?;
    final exercise = Exercise(
      id: id,
      name: name,
      exerciseType: normalizeExerciseType(
        type: raw['exerciseType'] as String?,
        bodyPart: bodyPart,
      ),
      bodyPart: bodyPart,
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
      met: (raw['met'] as num?)?.toDouble(),
      createdAt: toSyncDateTime(ts, serverTime),
    );
    return (exercise, raw['hasImage'] == true, raw['hasVideo'] == true);
  }

  static List<String>? _stringList(Object? value) {
    if (value is List) return value.whereType<String>().toList();
    return null;
  }
}
