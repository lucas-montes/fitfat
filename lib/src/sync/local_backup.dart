import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import '../app/app_restart.dart';
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

// ---------------------------------------------------------------------------
// Whole-database import
// ---------------------------------------------------------------------------

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
enum BackupFormat { sqlite, json, unknown }

const _sqliteMagic = 'SQLite format 3\u0000';

/// Sniffs [head] (the first bytes of a file) for a SQLite header or a JSON
/// document. JSON is detected by its first non-whitespace byte so a UTF-8 BOM
/// or leading newline does not hide it.
BackupFormat detectBackupFormat(List<int> head) {
  if (head.length >= 16 &&
      String.fromCharCodes(head.take(16)) == _sqliteMagic) {
    return BackupFormat.sqlite;
  }
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

/// Returns a user-facing error when [file] is not a FitFat SQLite database this
/// build can open, or `null` when it looks safe to migrate.
///
/// Runs against the raw file (before Drift touches it) so a rejected backup can
/// never have its schema rewritten.
Future<String?> validateSqliteBackup(
  File file, {
  required int maxSchemaVersion,
}) async {
  sqlite.Database raw;
  try {
    raw = sqlite.sqlite3.open(file.path, mode: sqlite.OpenMode.readOnly);
  } catch (_) {
    return 'That file is not a SQLite database.';
  }
  try {
    final integrity = raw.select('PRAGMA integrity_check');
    final verdict = integrity.isEmpty
        ? ''
        : '${integrity.first.values.first}';
    if (verdict != 'ok') {
      return 'That database is damaged ($verdict).';
    }

    final versionRows = raw.select('PRAGMA user_version');
    final version = versionRows.isEmpty
        ? 0
        : (versionRows.first.values.first as int? ?? 0);
    if (version <= 0) {
      return 'That file is not a FitFat backup (no schema version).';
    }
    if (version > maxSchemaVersion) {
      return 'That backup was made by a newer app version '
          '(schema $version, this app supports $maxSchemaVersion).';
    }

    final tables = <String>{
      for (final row in raw.select(
        "SELECT name FROM sqlite_master WHERE type='table'",
      ))
        if (row['name'] is String) row['name'] as String,
    };
    const required = ['tasks', 'workouts', 'exercises'];
    final missing = required.where((t) => !tables.contains(t)).toList();
    if (missing.isNotEmpty) {
      return 'That file is not a FitFat backup '
          '(missing ${missing.join(', ')}).';
    }
    return null;
  } catch (e) {
    return 'Could not read that database: $e';
  } finally {
    raw.dispose();
  }
}

String _sqlString(String value) => value.replaceAll("'", "''");

Future<void> _deleteIfPresent(File file) async {
  try {
    if (await file.exists()) await file.delete();
  } catch (_) {
    // Best effort: a leftover temp file must never fail an import.
  }
}

/// Copies [source] into [tempDir], proves the copy can be opened and migrated,
/// and returns a clean `VACUUM INTO` snapshot of the migrated database.
///
/// The original file is never touched. Nothing is installed until this
/// succeeds, so a bad pick cannot replace the live database.
Future<File> prepareWholeDbImport(
  File source, {
  required int maxSchemaVersion,
  Directory? tempDir,
}) async {
  final dir = tempDir ?? await getTemporaryDirectory();
  final stamp = DateTime.now().microsecondsSinceEpoch;
  final candidate = File(p.join(dir.path, 'fitfat-import-$stamp.sqlite'));
  final ready = File(p.join(dir.path, 'fitfat-import-$stamp-ready.sqlite'));
  await source.copy(candidate.path);
  try {
    final error = await validateSqliteBackup(
      candidate,
      maxSchemaVersion: maxSchemaVersion,
    );
    if (error != null) throw BackupException(error);

    // Opening with Drift runs the real migration chain in isolation. Every
    // table the app reads must resolve afterwards, otherwise the swap would
    // produce an app that opens and then crashes on its first query.
    final probe = AppDatabase.forTesting(NativeDatabase(candidate));
    try {
      for (final table in _tableOrder) {
        await probe.customSelect('SELECT * FROM "$table" LIMIT 0').get();
      }
      await probe.customStatement(
        "VACUUM INTO '${_sqlString(ready.path)}'",
      );
    } finally {
      await probe.close();
    }
    return ready;
  } catch (_) {
    await _deleteIfPresent(ready);
    rethrow;
  } finally {
    await _deleteIfPresent(candidate);
    await _deleteIfPresent(File('${candidate.path}-wal'));
    await _deleteIfPresent(File('${candidate.path}-shm'));
  }
}

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

/// Replaces the live database with [sourcePath] and returns the safety copy of
/// the previous file.
///
/// The source is validated and migrated on a temp copy first (see
/// [prepareWholeDbImport]), then the current database is snapshotted next to
/// the live file. Only after both steps does the swap happen. If anything goes
/// wrong mid-swap the snapshot is restored, so a failed import can never brick
/// the app. Callers must restart afterwards: every provider still holds the
/// closed handle.
Future<File> replaceWholeDb(WidgetRef ref, String sourcePath) async {
  final database = ref.read(db.databaseProvider);
  final ready = await prepareWholeDbImport(
    File(sourcePath),
    maxSchemaVersion: database.schemaVersion,
  );
  final dir = await getApplicationDocumentsDirectory();
  final dest = p.join(dir.path, 'fitfat.sqlite');
  final stamp = DateTime.now()
      .toIso8601String()
      .replaceAll(RegExp(r'[:.]'), '-');
  final backup = File(
    p.join(dir.path, 'fitfat-before-import-$stamp.sqlite'),
  );

  try {
    await database.customStatement(
      "VACUUM INTO '${_sqlString(backup.path)}'",
    );
    await database.close();
    await _deleteJournals(dest);
    await ready.copy(dest);
    ref.invalidate(db.databaseProvider);
    await _pruneImportBackups(dir);
    return backup;
  } catch (e) {
    // Put the previous database back so a failed swap cannot leave the app
    // pointing at a half-written file.
    try {
      await _deleteJournals(dest);
      if (await backup.exists()) await backup.copy(dest);
      ref.invalidate(db.databaseProvider);
    } catch (_) {
      // Nothing more we can do; the snapshot is still on disk for recovery.
    }
    rethrow;
  } finally {
    await _deleteIfPresent(ready);
  }
}

Future<void> _deleteJournals(String dest) async {
  for (final suffix in ['-wal', '-shm']) {
    final journal = File('$dest$suffix');
    if (await journal.exists()) await journal.delete();
  }
}

/// Keeps the three most recent pre-import snapshots; older ones are dead
/// weight once a swap has succeeded.
Future<void> _pruneImportBackups(Directory dir) async {
  try {
    final backups = <File>[
      await for (final entry in dir.list())
        if (entry is File &&
            p.basename(entry.path).startsWith('fitfat-before-import-'))
          entry,
    ]..sort((a, b) => b.path.compareTo(a.path));
    for (final old in backups.skip(3)) {
      await old.delete();
    }
  } catch (_) {
    // Pruning is housekeeping; never fail an otherwise good import over it.
  }
}

Future<void> importBackup(
  BuildContext context,
  WidgetRef ref, {
  required Set<String> entities,
  required bool wholeDb,
}) async {
  // `FileType.any` is required: WhatsApp delivers documents without a suffix
  // and file_picker's custom filter silently drops them.
  final result = await FilePicker.platform.pickFiles(type: FileType.any);
  final path = result?.files.single.path;
  if (path == null) return;

  final format = await detectBackupFile(File(path));
  if (format == BackupFormat.unknown) {
    throw const BackupException(
      'Unsupported file — expected a FitFat SQLite database or JSON export.',
    );
  }
  final isJson = format == BackupFormat.json;
  if (wholeDb && isJson) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Switch to Selected to import JSON')),
      );
    }
    return;
  }
  if (!wholeDb && !isJson) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Switch to Whole DB to import SQLite')),
      );
    }
    return;
  }

  if (!context.mounted) return;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Replace local data?'),
      content: Text(
        isJson
            ? 'Import JSON will upsert selected entities: ${entities.join(', ')}'
            : 'Import SQLite will replace the whole database. A copy of the '
                  'current database is kept first.',
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

  if (isJson) {
    final content = await File(path).readAsString();
    final Object? decoded = jsonDecode(content);
    if (decoded is! Map<String, dynamic>) {
      throw const BackupException('That JSON file is not a backup export.');
    }
    final imported = await importJson(
      ref.read(db.databaseProvider),
      entities,
      decoded,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported $imported rows')),
      );
    }
    return;
  }

  // Whole database: validate/migrate a copy, snapshot the live file, swap, and
  // restart so every provider reopens against the imported data.
  await replaceWholeDb(ref, path);
  restartApp();
}
