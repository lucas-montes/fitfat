import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../network/api_client.dart';

/// Which binary asset of an exercise a download refers to. Media lives on the
/// sync server at URLs derived from the exercise id — `baseUrl/exercises/id.jpg`
/// for images and `.mp4` for videos — so no URL is ever stored.
enum ExerciseMediaKind { image, video }

String _extension(ExerciseMediaKind kind) =>
    kind == ExerciseMediaKind.image ? '.jpg' : '.mp4';

/// Downloads and stores exercise media under
/// `<application documents>/exercise_media/`, keyed by exercise id, using the
/// same Bearer API key as every other sync request. Files persist across
/// restarts (offline-first); a missing file simply re-downloads on next sync.
final class ExerciseMediaDownloader {
  ExerciseMediaDownloader(this._api, {Future<Directory> Function()? mediaDir})
    : _mediaDir = mediaDir ?? defaultMediaDir;

  final ApiClient _api;
  final Future<Directory> Function() _mediaDir;

  /// Auth header shared with the exercise pull so both requests authenticate
  /// identically.
  static Map<String, String> auth(String apiKey) => {
    'Authorization': 'Bearer $apiKey',
  };

  /// `<documents>/exercise_media`, created on first use. Injectable for tests.
  static Future<Directory> defaultMediaDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'exercise_media'));
    await dir.create(recursive: true);
    return dir;
  }

  /// Absolute local path for [exerciseId]'s [kind] file (the file itself may
  /// not exist yet).
  Future<String> localPath(String exerciseId, ExerciseMediaKind kind) async {
    final dir = await _mediaDir();
    return p.join(dir.path, '$exerciseId${_extension(kind)}');
  }

  /// True when the stored file exists on disk.
  Future<bool> exists(String exerciseId, ExerciseMediaKind kind) async =>
      File(await localPath(exerciseId, kind)).exists();

  /// Fetches `<base>/exercises/<id>.<ext>` and writes it to the media
  /// directory. Returns the local path, or null when the server has no such
  /// file (404). Any other failure rethrows — callers treat it as a failed
  /// sync round so it retries after backoff.
  Future<String?> download({
    required String exerciseId,
    required ExerciseMediaKind kind,
    required String apiKey,
  }) async {
    final Uint8List bytes;
    try {
      bytes = await _api.getBytes(
        '/exercises/$exerciseId${_extension(kind)}',
        headers: auth(apiKey),
      );
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
    final path = await localPath(exerciseId, kind);
    await File(path).writeAsBytes(bytes, flush: true);
    return path;
  }

  /// Deletes the stored file for [exerciseId]/[kind] if present; best-effort.
  Future<void> remove(String exerciseId, ExerciseMediaKind kind) async {
    final file = File(await localPath(exerciseId, kind));
    if (await file.exists()) {
      try {
        await file.delete();
      } catch (_) {}
    }
  }
}
