import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Directory under the app docs folder that holds all note voice-clip files.
Future<Directory> noteAudioDirectory() async {
  final docs = await getApplicationDocumentsDirectory();
  final dir = Directory(p.join(docs.path, 'note_audio'));
  if (!await dir.exists()) await dir.create(recursive: true);
  return dir;
}

/// Builds the on-disk path for a clip id (`.m4a`).
Future<String> noteAudioPathFor(String clipId) async {
  final dir = await noteAudioDirectory();
  return p.join(dir.path, '$clipId.m4a');
}

/// Generates a fresh clip id + its final on-disk path in one call.
Future<(String id, String path)> newClipLocation() async {
  final id = const Uuid().v7();
  final path = await noteAudioPathFor(id);
  return (id, path);
}

/// Deletes the file backing a clip, ignoring a missing file.
Future<void> deleteClipFile(String path) async {
  final file = File(path);
  if (await file.exists()) {
    try {
      await file.delete();
    } catch (_) {
      // Best-effort: an undeletable orphan is non-fatal.
    }
  }
}
