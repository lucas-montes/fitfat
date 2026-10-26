import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../database/app_database.dart';
import '../database/database_provider.dart' as db;
import 'sync_refresh.dart';

/// Which tables belong to which backup entity, parents always before their
/// children. The same map drives export order, import order and the reverse
/// order used to clear a group before a restore.
const _ownership = <String, List<String>>{
  'Tags': ['tags'],
  'Exercises': ['exercises'],
  'Ingredients': [
    'stores',
    'ingredients',
    'ingredient_prices',
    'ingredient_pictures',
  ],
  'Foods': ['foods', 'food_ingredients'],
  'Workouts': [
    'workouts',
    'workout_exercises',
    'exercise_sets',
    'workout_templates',
    'workout_template_exercises',
    'workout_template_sets',
  ],
  'Meals': ['meals', 'meal_foods'],
  'Tasks': ['tasks', 'task_tags', 'task_goals', 'task_notes'],
  'Notes': ['notes', 'note_tags', 'note_workouts', 'note_audio'],
  'Goals': [
    'goals',
    'goal_tags',
    'goal_progress_entries',
    'goal_workouts',
    'goal_notes',
  ],
  'Body': ['body_metrics'],
  'Budget': ['accounts', 'fx_rates', 'transactions'],
  'Receipts': ['receipts'],
};

/// Groups offered by the backup UI, ordered like the app's tabs rather than by
/// table dependency (that order lives in [_ownership]).
const backupEntityGroups = <String>[
  'Tasks',
  'Notes',
  'Goals',
  'Workouts',
  'Meals',
  'Body',
  'Budget',
  'Receipts',
  'Tags',
  'Exercises',
  'Foods',
  'Ingredients',
];

/// Every group, i.e. a full logical backup.
final Set<String> allBackupEntities = backupEntityGroups.toSet();

/// Groups whose rows reference another group's ids. Importing a child without
/// its parents would leave dangling references (a workout without its exercise,
/// a task without its tag), so [expandEntities] pulls the parents in.
const _parentGroups = <String, Set<String>>{
  'Tasks': {'Tags'},
  'Notes': {'Tags'},
  'Goals': {'Tags'},
  'Workouts': {'Exercises'},
  'Meals': {'Foods'},
  'Foods': {'Ingredients'},
};

/// Expands [entities] with every parent group they reference, transitively.
Set<String> expandEntities(Iterable<String> entities) {
  final result = <String>{...entities};
  final pending = <String>[...result];
  while (pending.isNotEmpty) {
    for (final parent in _parentGroups[pending.removeLast()] ?? const {}) {
      if (result.add(parent)) pending.add(parent);
    }
  }
  return result;
}

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
  'note_workouts' => d.noteWorkouts,
  'note_audio' => d.noteAudio,
  'goals' => d.goals,
  'goal_tags' => d.goalTags,
  'goal_progress_entries' => d.goalProgressEntries,
  'goal_workouts' => d.goalWorkouts,
  'goal_notes' => d.goalNotes,
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
  'tags' => d.tags,
  'exercises' => d.exercises,
  'foods' => d.foods,
  'food_ingredients' => d.foodIngredients,
  'stores' => d.stores,
  'ingredients' => d.ingredients,
  'ingredient_prices' => d.ingredientPrices,
  'ingredient_pictures' => d.ingredientPictures,
  _ => throw StateError('Unknown backup table: $name'),
};

String _owningEntity(String tableName) => _ownership.entries
    .firstWhere((e) => e.value.contains(tableName))
    .key;

/// Thrown for a picked file that is not a backup this app can import. The
/// message is user-facing.
final class BackupException implements Exception {
  const BackupException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// What a picked file actually contains. The extension is deliberately ignored:
/// WhatsApp hands documents over with names like `DOC-20261023-WA0002.` (no
/// suffix at all) and the picker's custom-type filter rejects them before we
/// ever see them.
enum BackupFormat { json, jsonGzip, unknown }

bool _isGzip(List<int> head) =>
    head.length >= 2 && head[0] == 0x1F && head[1] == 0x8B;

/// Sniffs [head] (the first bytes of a file) for gzip-compressed JSON or a
/// plain JSON document. JSON is detected by its first non-whitespace byte so a
/// UTF-8 BOM or leading newline does not hide it.
BackupFormat detectBackupFormat(List<int> head) {
  if (_isGzip(head)) return BackupFormat.jsonGzip;
  var i = 0;
  if (head.length >= 3 &&
      head[0] == 0xEF &&
      head[1] == 0xBB &&
      head[2] == 0xBF) {
    i = 3;
  }
  while (i < head.length) {
    final byte = head[i];
    if (byte != 0x20 && byte != 0x09 && byte != 0x0A && byte != 0x0D) break;
    i++;
  }
  if (i < head.length && (head[i] == 0x7B || head[i] == 0x5B)) {
    return BackupFormat.json;
  }
  return BackupFormat.unknown;
}

Future<BackupFormat> detectBackupFile(File file) async {
  final reader = await file.open();
  try {
    return detectBackupFormat(await reader.read(64));
  } finally {
    await reader.close();
  }
}

/// Encodes a backup dump as a gzip-compressed JSON document.
///
/// Compression matters here: the row maps repeat every column name and the
/// catalog text is verbose, and gzip shrinks the archive several-fold without
/// changing what it contains.
Uint8List encodeBackup(Map<String, Object?> dump) {
  final text = jsonEncode(dump);
  return Uint8List.fromList(gzip.encode(utf8.encode(text)));
}

/// Decodes a backup archive, plain JSON or gzip-compressed JSON.
Map<String, dynamic> decodeBackupBytes(List<int> bytes) {
  final Object? decoded;
  try {
    final raw = _isGzip(bytes) ? gzip.decode(bytes) : bytes;
    var text = utf8.decode(raw);
    if (text.isNotEmpty && text.codeUnitAt(0) == 0xFEFF) {
      text = text.substring(1);
    }
    decoded = jsonDecode(text);
  } on FormatException {
    throw const BackupException('That file is not a FitFat backup export.');
  }
  if (decoded is! Map<String, dynamic>) {
    throw const BackupException('That file is not a FitFat backup export.');
  }
  return decoded;
}

/// Builds the gzipped JSON archive for [entities] (parents included) without
/// writing it to disk. Used by both the share sheet and the server copy.
Future<Uint8List> buildBackupArchive(
  WidgetRef ref,
  Set<String> entities,
) async {
  final dump = await dumpTables(
    ref.read(db.databaseProvider),
    expandEntities(entities),
  );
  return encodeBackup(dump);
}

/// Exports the selected entity groups as one compressed JSON document of raw
/// row maps, keyed by table name. Returns the number of rows written.
Future<int> exportJsonPerEntity(
  BuildContext context,
  WidgetRef ref,
  Set<String> entities,
) async {
  final groups = expandEntities(entities);
  final dump = await dumpTables(ref.read(db.databaseProvider), groups);
  final rows = dump.values.fold<int>(0, (sum, list) => sum + list.length);
  final stamp = DateTime.now()
      .toIso8601String()
      .replaceAll(RegExp(r'[:.]'), '-');
  final tmp = await getTemporaryDirectory();
  final path = p.join(tmp.path, 'fitfat-$stamp.json.gz');
  await File(path).writeAsBytes(encodeBackup(dump), flush: true);
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(path, mimeType: 'application/gzip')],
      text: 'fitfat backup — $rows rows',
    ),
  );
  return rows;
}

/// Reads every table owned by [entities] into a parents-first row-map dump.
/// Parent groups are pulled in automatically, so a dump can always be imported
/// back without dangling references.
Future<Map<String, List<Map<String, Object?>>>> dumpTables(
  AppDatabase database,
  Set<String> entities,
) async {
  final groups = expandEntities(entities);
  final dump = <String, List<Map<String, Object?>>>{};
  for (final name in _tableOrder) {
    if (!groups.contains(_owningEntity(name))) continue;
    final data = await database.customSelect('SELECT * FROM "$name"').get();
    dump[name] = data.map((row) => row.data).toList();
  }
  return dump;
}

/// Applies a backup dump to [database], parents before children.
///
/// With [replace] the selected groups are cleared first, so the result matches
/// the backup exactly: rows deleted on the device the backup came from do not
/// survive. Without it the import is an upsert, leaving untouched rows alone.
Future<int> importJson(
  AppDatabase database,
  Set<String> entities,
  Map<String, dynamic> data, {
  bool replace = false,
}) async {
  final groups = expandEntities(entities);
  return database.transaction(() async {
    if (replace) {
      // Clear only the groups the caller asked for. Parents pulled in as
      // dependencies (tags for a task, ingredients for a food) are upserted
      // instead, so a partial restore never deletes a tag another group still
      // references. Children before parents, and dependent groups before the
      // groups they reference.
      for (final name in _tableOrder.reversed) {
        if (!entities.contains(_owningEntity(name))) continue;
        await database.customStatement('DELETE FROM "$name"');
      }
    }
    var imported = 0;
    for (final name in _tableOrder) {
      if (!groups.contains(_owningEntity(name))) continue;
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
  });
}

/// Restores an in-memory archive (the server copy, or bytes handed to the app).
/// Clears the selected groups first, then refreshes the UI.
Future<int> importBackupArchive(
  WidgetRef ref,
  List<int> bytes, {
  Set<String>? entities,
}) async {
  final data = decodeBackupBytes(bytes);
  final imported = await importJson(
    ref.read(db.databaseProvider),
    entities ?? allBackupEntities,
    data,
    replace: true,
  );
  invalidateAllData(ref);
  return imported;
}

/// Picks a JSON backup (plain or `.json.gz`) and replaces the selected groups
/// with its contents.
Future<void> importBackup(
  BuildContext context,
  WidgetRef ref, {
  required Set<String> entities,
}) async {
  // `FileType.any` is required: WhatsApp delivers documents without a suffix
  // and file_picker's custom filter silently drops them.
  final result = await FilePicker.platform.pickFiles(type: FileType.any);
  final path = result?.files.single.path;
  if (path == null) return;

  final bytes = await File(path).readAsBytes();
  final head = bytes.length > 64 ? bytes.sublist(0, 64) : bytes;
  if (detectBackupFormat(head) == BackupFormat.unknown) {
    throw const BackupException(
      'Unsupported file — expected a FitFat JSON backup (.json or .json.gz).',
    );
  }

  final groups = expandEntities(entities);
  if (!context.mounted) return;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Replace local data?'),
      content: Text(
        'Importing will delete the existing rows in these groups and restore '
        'the backup: ${_labels(groups)}.',
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

  final imported = await importBackupArchive(ref, bytes, entities: entities);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Restored $imported rows')),
  );
}

String _labels(Set<String> groups) =>
    backupEntityGroups.where(groups.contains).join(', ');
