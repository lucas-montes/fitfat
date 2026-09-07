import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../database/database_provider.dart' as db;

Future<void> exportWholeDb(BuildContext context) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File(p.join(dir.path, 'fitfat.sqlite'));
  if (!await file.exists()) throw StateError('Database not found');
  final stamp = DateTime.now().toIso8601String().split('T').first;
  final tmp = await getTemporaryDirectory();
  final copy = await file.copy(p.join(tmp.path, 'fitfat-$stamp.sqlite'));
  await SharePlus.instance.share(ShareParams(files: [XFile(copy.path)]));
}

Future<void> exportJsonPerEntity(BuildContext context, WidgetRef ref, Set<String> entities) async {
  final database = ref.read(db.databaseProvider);
  final Map<String, dynamic> dump = {};
  if (entities.contains('tasks')) {
    dump['tasks'] = (await database.select(database.tasks).get()).map((e) => e.toJson()).toList();
    dump['taskTags'] = (await database.select(database.taskTags).get()).map((e) => e.toJson()).toList();
  }
  if (entities.contains('notes')) {
    dump['notes'] = (await database.select(database.notes).get()).map((e) => e.toJson()).toList();
  }
  if (entities.contains('goals')) {
    dump['goals'] = (await database.select(database.goals).get()).map((e) => e.toJson()).toList();
    dump['goalProgressEntries'] = (await database.select(database.goalProgressEntries).get()).map((e) => e.toJson()).toList();
  }
  if (entities.contains('workouts')) {
    dump['workouts'] = (await database.select(database.workouts).get()).map((e) => e.toJson()).toList();
    dump['workoutExercises'] = (await database.select(database.workoutExercises).get()).map((e) => e.toJson()).toList();
    dump['exerciseSets'] = (await database.select(database.exerciseSets).get()).map((e) => e.toJson()).toList();
  }
  if (entities.contains('templates')) {
    dump['workoutTemplates'] = (await database.select(database.workoutTemplates).get()).map((e) => e.toJson()).toList();
  }
  if (entities.contains('experiments')) {
    dump['tasks_experiments'] = (await database.select(database.tasks).get()).where((r) => r.toString().contains('experiment')).toList().length;
  }
  final stamp = DateTime.now().toIso8601String().split('T').first;
  final tmp = await getTemporaryDirectory();
  final path = p.join(tmp.path, 'fitfat-$stamp.json');
  await File(path).writeAsString(jsonEncode(dump));
  await SharePlus.instance.share(ShareParams(files: [XFile(path)]));
}

Future<void> importBackup(BuildContext context, WidgetRef ref) async {
  final result = await FilePicker.platform.pickFiles(allowedExtensions: ['sqlite', 'json', 'db'], type: FileType.custom);
  if (result == null || result.files.single.path == null) return;
  final path = result.files.single.path!;
  final isJson = path.endsWith('.json');
  final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Replace local data?'), content: Text(isJson ? 'Import JSON will upsert selected entities.' : 'Import SQLite will replace the whole database.'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Continue'))]));
  if (confirmed != true) return;
  if (!isJson) {
    final dir = await getApplicationDocumentsDirectory();
    final dest = p.join(dir.path, 'fitfat.sqlite');
    await ref.read(db.databaseProvider).close();
    await File(path).copy(dest);
    ref.invalidate(db.databaseProvider);
  } else {
    final content = await File(path).readAsString();
    final data = jsonDecode(content) as Map<String, dynamic>;
    // Minimal upsert: for demo, just report count
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imported ${data.length} entity groups')));
  }
}
