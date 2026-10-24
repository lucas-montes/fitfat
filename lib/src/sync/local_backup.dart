import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../database/app_database.dart';
import '../database/database_provider.dart' as db;

/// Which tables belong to which backup entity, parents always before their
/// children — the backup hub hands the same entity labels to export and
/// import, so both sides stay in lock-step through this map.
const _ownership = <String, List<String>>{
  'Tasks': ['tasks', 'task_tags', 'task_goals', 'task_notes'],
  'Notes': ['notes', 'note_tags'],
  'Goals': ['goals', 'goal_tags', 'goal_progress_entries', 'goal_workouts'],
  'Workouts': [
    'workouts',
    'workout_exercises',
    'exercise_sets',
    'workout_templates',
    'workout_template_exercises',
    'workout_template_sets',
  ],
  'Meals': ['meals', 'meal_foods'],
  'Body': ['body_metrics'],
  'Budget': ['accounts', 'fx_rates', 'transactions'],
  'Receipts': ['receipts'],
};

/// Every table the backup can carry, in parents-first import order.
final _tableOrder = <String>[
  for (final tables in _ownership.values) ...tables,
];

dynamic _tableFor(AppDatabase d, String name) => switch (name) {
  'tasks' => d.tasks,
  'task_tags' => d.taskTags,
  'task_goals' => d.taskGoals,
  'task_notes' => d.taskNotes,
  'notes' => d.notes,
  'note_tags' => d.noteTags,
  'goals' => d.goals,
  'goal_tags' => d.goalTags,
  'goal_progress_entries' => d.goalProgressEntries,
  'goal_workouts' => d.goalWorkouts,
  'workouts' => d.workouts,
  'workout_exercises' => d.workoutExercises,
  'exercise_sets' => d.exerciseSets,
  'workout_templates' => d.workoutTemplates,
  'workout_template_exercises' => d.workoutTemplateExercises,
  'workout_template_sets' => d.workoutTemplateSets,
  'meals' => d.meals,
  'meal_foods' => d.mealFoods,
  'body_metrics' => d.bodyMetrics,
  'accounts' => d.accounts,
  'fx_rates' => d.fxRates,
  'transactions' => d.transactions,
  'receipts' => d.receipts,
  _ => throw StateError('Unknown backup table: $name'),
};

String _owningEntity(String tableName) => _ownership.entries
    .firstWhere((e) => e.value.contains(tableName))
    .key;

/// Whole-database export: `VACUUM INTO` writes a fully-consistent copy of the
/// live database (pending WAL pages merged in) without any file race.
Future<File> backupWholeDb(WidgetRef ref) async {
  final stamp = DateTime.now().toIso8601String().split('T').first;
  final tmp = await getTemporaryDirectory();
  final target = p.join(tmp.path, 'fitfat-$stamp.sqlite');
  final database = ref.read(db.databaseProvider);
  await database.customStatement("VACUUM INTO '${target.replaceAll("'", "''")}'");
  return File(target);
}

Future<void> exportWholeDb(BuildContext context, WidgetRef ref) async {
  final copy = await backupWholeDb(ref);
  await SharePlus.instance.share(ShareParams(files: [XFile(copy.path)]));
}

/// Exports the selected entity groups as one JSON document of raw row maps,
/// keyed by table name. Returns the number of rows written.
Future<int> exportJsonPerEntity(
  BuildContext context,
  WidgetRef ref,
  Set<String> entities,
) async {
  final dump = await dumpTables(ref.read(db.databaseProvider), entities);
  final rows = dump.values.fold<int>(
    0,
    (sum, list) => sum + list.length,
  );
  final stamp = DateTime.now().toIso8601String().split('T').first;
  final tmp = await getTemporaryDirectory();
  final path = p.join(tmp.path, 'fitfat-$stamp.json');
  await File(path).writeAsString(jsonEncode(dump));
  await SharePlus.instance.share(
    ShareParams(files: [XFile(path)], text: 'fitfat backup — $rows rows'),
  );
  return rows;
}

/// Reads every table owned by [entities] into a parents-first row-map dump.
Future<Map<String, List<Map<String, Object?>>>> dumpTables(
  AppDatabase database,
  Set<String> entities,
) async {
  final dump = <String, List<Map<String, Object?>>>{};
  for (final name in _tableOrder) {
    if (!entities.contains(_owningEntity(name))) continue;
    final data = await database.customSelect('SELECT * FROM "$name"').get();
    dump[name] = data.map((row) => row.data).toList();
  }
  return dump;
}

/// Upserts the selected groups from a JSON export, parents before children, so
/// restoring a partial selection keeps every row linked to its owner.
Future<int> importJson(
  AppDatabase database,
  Set<String> entities,
  Map<String, dynamic> data,
) async {
  var imported = 0;
  for (final name in _tableOrder) {
    if (!entities.contains(_owningEntity(name))) continue;
    final rawRows = data[name];
    if (rawRows is! List) continue;
    final table = _tableFor(database, name);
    final byName = table.columnsByName;
    for (final row in rawRows) {
      if (row is! Map) continue;
      final values = <String, Object?>{
        for (final e in row.entries)
          if (e.key is String && byName.containsKey(e.key as String))
            e.key as String: e.value,
      };
      if (values.isEmpty) continue;
      final cols = values.keys.map((c) => '"$c"').join(', ');
      final placeholders = values.keys.map((_) => '?').join(', ');
      await database.customStatement(
        'INSERT OR REPLACE INTO "$name" ($cols) VALUES ($placeholders)',
        [...values.values],
      );
      imported++;
    }
  }
  return imported;
}

/// Replaces the live database with [sourcePath] and reopens it on next use —
/// shared by file import and server restore.
Future<void> replaceWholeDb(WidgetRef ref, String sourcePath) async {
  final dir = await getApplicationDocumentsDirectory();
  final dest = p.join(dir.path, 'fitfat.sqlite');
  await ref.read(db.databaseProvider).close();
  // Stale journal files would let SQLite roll the copy back; the imported
  // database is self-contained, so drop them before reopening.
  for (final suffix in ['-wal', '-shm']) {
    final journal = File('$dest$suffix');
    if (await journal.exists()) await journal.delete();
  }
  await File(sourcePath).copy(dest);
  ref.invalidate(db.databaseProvider);
}

Future<void> importBackup(
  BuildContext context,
  WidgetRef ref, {
  required Set<String> entities,
  required bool wholeDb,
}) async {
  final result = await FilePicker.platform.pickFiles(
    allowedExtensions: ['sqlite', 'json', 'db'],
    type: FileType.custom,
  );
  if (result == null || result.files.single.path == null) return;
  final path = result.files.single.path!;
  final isJson = path.endsWith('.json');
  final isSqlite = path.endsWith('.sqlite') || path.endsWith('.db');
  if (wholeDb && isJson) {
    if (context.mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Switch to Selected to import JSON')),
      );
    return;
  }
  if (!wholeDb && isSqlite) {
    if (context.mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Switch to Whole DB to import SQLite')),
      );
    return;
  }
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Replace local data?'),
      content: Text(
        isJson
            ? 'Import JSON will upsert selected entities: ${entities.join(', ')}'
            : 'Import SQLite will replace the whole database.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Continue'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  if (isSqlite) {
    await replaceWholeDb(ref, path);
    if (context.mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Imported whole database — restart to apply'),
        ),
      );
  } else {
    final content = await File(path).readAsString();
    final data = jsonDecode(content) as Map<String, dynamic>;
    final imported = await importJson(
      ref.read(db.databaseProvider),
      entities,
      data,
    );
    if (context.mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported $imported rows')),
      );
  }
}
