import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../database/app_database.dart' as db;
import '../../models/tag.dart';

/// Thrown when creating or renaming a priority would collide with an
/// existing vocabulary entry (names are unique). The UI surfaces this as a
/// friendly message instead of a raw database error.
final class DuplicateTagException implements Exception {
  final String name;
  const DuplicateTagException(this.name);

  @override
  String toString() => 'DuplicateTagException: $name';
}

/// Normalizes a priority name: trims the edges and collapses internal runs
/// of whitespace so "Leg  day" and " leg day " all store as "Leg day".
String normalizeTagName(String raw) => raw.trim().replaceAll(RegExp(r'\s+'), ' ');

final class TagRepository {
  final db.AppDatabase _database;
  const TagRepository(this._database);

  /// All registered tags ordered by manual priority, then name.
  Future<List<Tag>> listTags() async {
    final rows =
        await (_database.select(_database.tags)..orderBy([
              (t) => OrderingTerm(expression: t.sortOrder),
              (t) => OrderingTerm(expression: t.name.collate(Collate.noCase)),
            ]))
            .get();
    return rows.map(_toDomain).toList();
  }

  Future<Tag?> getByName(String name) async {
    final row = await (_database.select(
      _database.tags,
    )..where((t) => t.name.equals(name))).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  /// Creates or updates a vocabulary entry. When [id] is null the tag is
  /// looked up by [name] (creating it if unknown) so the picker and manager
  /// can both funnel through here. The name is normalized (trimmed, internal
  /// whitespace collapsed); blank names throw [ArgumentError] and a colliding
  /// name throws [DuplicateTagException].
  Future<void> saveTag({required String name, int? color, String? id}) async {
    final clean = normalizeTagName(name);
    if (clean.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Priority name is blank');
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final existing = id != null
        ? await (_database.select(
            _database.tags,
          )..where((t) => t.id.equals(id))).getSingleOrNull()
        : await (_database.select(
            _database.tags,
          )..where((t) => t.name.equals(clean))).getSingleOrNull();
    if (existing == null && id == null) {
      // New tags land at the bottom of the priority order.
      final maxOrderExp = _database.tags.sortOrder.max();
      final row = await (_database.selectOnly(
        _database.tags,
      )..addColumns([maxOrderExp])).getSingleOrNull();
      final nextOrder = (row?.read(maxOrderExp) ?? -1) + 1;
      await _database
          .into(_database.tags)
          .insert(
            db.TagsCompanion.insert(
              id: const Uuid().v7(),
              name: clean,
              color: Value(color),
              sortOrder: Value(nextOrder),
              createdAt: now,
              updatedAt: now,
            ),
          );
    } else if (existing != null) {
      await (_database.update(
        _database.tags,
      )..where((t) => t.id.equals(existing.id))).write(
        db.TagsCompanion(
          name: Value(clean),
          color: Value(color),
          updatedAt: Value(now),
        ),
      );
    } else {
      // id given but no such row — treat as a create that must not collide.
      final clash = await getByName(clean);
      if (clash != null) throw DuplicateTagException(clean);
      await _database
          .into(_database.tags)
          .insert(
            db.TagsCompanion.insert(
              id: id!,
              name: clean,
              color: Value(color),
              sortOrder: Value(0),
              createdAt: now,
              updatedAt: now,
            ),
          );
    }
  }

  /// Persists a new left-to-right priority order (names must be unique).
  Future<void> reorder(List<String> orderedNames) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _database.batch((batch) {
      for (var i = 0; i < orderedNames.length; i++) {
        batch.update(
          _database.tags,
          db.TagsCompanion(sortOrder: Value(i), updatedAt: Value(now)),
          where: (db.$TagsTable t) => t.name.equals(orderedNames[i]),
        );
      }
    });
  }

  /// Ensures a priority with [name] exists in the vocabulary and returns its
  /// id. Used by the entity tag setters so a free-form name typed in a form
  /// is registered on first use, matching the old behavior where the v28
  /// backfill later promoted names into the vocabulary.
  Future<String> ensureTag(String name) async {
    final clean = normalizeTagName(name);
    if (clean.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Priority name is blank');
    }
    final existing = await (_database.select(
      _database.tags,
    )..where((t) => t.name.equals(clean))).getSingleOrNull();
    if (existing != null) return existing.id;
    final maxOrderExp = _database.tags.sortOrder.max();
    final row = await (_database.selectOnly(
      _database.tags,
    )..addColumns([maxOrderExp])).getSingleOrNull();
    final nextOrder = (row?.read(maxOrderExp) ?? -1) + 1;
    final id = const Uuid().v7();
    final now = DateTime.now().millisecondsSinceEpoch;
    await _database
        .into(_database.tags)
        .insert(
          db.TagsCompanion.insert(
            id: id,
            name: clean,
            sortOrder: Value(nextOrder),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  /// Renames a priority. Join rows reference the tag by id, so no entity
  /// rewrite is required — the links follow the rename automatically.
  /// Throws [DuplicateTagException] when another entry already uses the
  /// normalized target name.
  Future<void> renameTag(String oldName, String newName) async {
    final clean = normalizeTagName(newName);
    if (clean.isEmpty || clean == normalizeTagName(oldName)) return;
    final clash = await getByName(clean);
    if (clash != null && clash.name != oldName) {
      throw DuplicateTagException(clean);
    }
    await (_database.update(_database.tags)
          ..where((t) => t.name.equals(oldName)))
        .write(
          db.TagsCompanion(
            name: Value(clean),
            updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );
  }

  /// Deletes a priority and (via ON DELETE CASCADE) every link to it. Returns
  /// the number of linked entities removed.
  Future<int> deleteTag(String name) async {
    final tag = await getByName(name);
    if (tag == null) return 0;
    final removed = await usageForTagId(tag.id);
    await (_database.delete(
      _database.tags,
    )..where((t) => t.id.equals(tag.id))).go();
    return removed;
  }

  /// Every known tag name — the registered vocabulary (now the sole source of
  /// tag names, since every referenced name is a `tags` row). Powers
  /// autocomplete.
  Future<List<String>> distinctTagNames() async {
    final rows = await _database.select(_database.tags).get();
    final names = rows.map((r) => r.name).toList()..sort();
    return names;
  }

  /// Usage count per tag name across all tagged entity types.
  Future<Map<String, int>> usageCounts() async {
    final tags = await _database.select(_database.tags).get();
    final nameById = {for (final t in tags) t.id: t.name};
    final counts = <String, int>{};
    void bump(String tagId) {
      final name = nameById[tagId];
      if (name == null) return;
      counts.update(name, (c) => c + 1, ifAbsent: () => 1);
    }

    for (final row in await _database.select(_database.taskTags).get()) {
      bump(row.tagId);
    }
    for (final row in await _database.select(_database.experimentTags).get()) {
      bump(row.tagId);
    }
    for (final row in await _database.select(_database.goalTags).get()) {
      bump(row.tagId);
    }
    for (final row in await _database.select(_database.noteTags).get()) {
      bump(row.tagId);
    }
    return counts;
  }

  /// Usage count for a single tag id (used by [deleteTag]).
  Future<int> usageForTagId(String tagId) async {
    final tag = await (_database.select(
      _database.tags,
    )..where((t) => t.id.equals(tagId))).getSingleOrNull();
    if (tag == null) return 0;
    return usageCounts().then((c) => c[tag.name] ?? 0);
  }

  // --- Per-entity reads (ordered by priority rank, then name) -------------

  Future<List<String>> tagsForTask(String id) =>
      _namesFor('task_tags', 'task_id', id);

  Future<List<String>> tagsForExperiment(String id) =>
      _namesFor('experiment_tags', 'experiment_id', id);

  Future<List<String>> tagsForGoal(String id) =>
      _namesFor('goal_tags', 'goal_id', id);

  Future<List<String>> tagsForNote(String id) =>
      _namesFor('note_tags', 'note_id', id);

  /// Batched variant: returns id → tag names for a batch of entity ids.
  Future<Map<String, List<String>>> tagNamesForTasks(List<String> ids) =>
      _namesMap('task_tags', 'task_id', ids);

  Future<Map<String, List<String>>> tagNamesForExperiments(List<String> ids) =>
      _namesMap('experiment_tags', 'experiment_id', ids);

  Future<Map<String, List<String>>> tagNamesForGoals(List<String> ids) =>
      _namesMap('goal_tags', 'goal_id', ids);

  Future<Map<String, List<String>>> tagNamesForNotes(List<String> ids) =>
      _namesMap('note_tags', 'note_id', ids);

  // --- Per-entity writes (replace all links for an entity) ----------------

  Future<void> setTaskTags(String taskId, List<String> names) async {
    final tagIds = await _resolveTagIds(names);
    await _database.transaction(() async {
      await (_database.delete(
        _database.taskTags,
      )..where((t) => t.taskId.equals(taskId))).go();
      for (final tagId in tagIds) {
        await _database.into(_database.taskTags).insert(
              db.TaskTagsCompanion.insert(tagId: tagId, taskId: taskId),
              onConflict: DoNothing(),
            );
      }
    });
  }

  Future<void> setExperimentTags(String experimentId, List<String> names) async {
    final tagIds = await _resolveTagIds(names);
    await _database.transaction(() async {
      await (_database.delete(
        _database.experimentTags,
      )..where((t) => t.experimentId.equals(experimentId))).go();
      for (final tagId in tagIds) {
        await _database.into(_database.experimentTags).insert(
              db.ExperimentTagsCompanion.insert(
                tagId: tagId,
                experimentId: experimentId,
              ),
              onConflict: DoNothing(),
            );
      }
    });
  }

  Future<void> setGoalTags(String goalId, List<String> names) async {
    final tagIds = await _resolveTagIds(names);
    await _database.transaction(() async {
      await (_database.delete(
        _database.goalTags,
      )..where((t) => t.goalId.equals(goalId))).go();
      for (final tagId in tagIds) {
        await _database.into(_database.goalTags).insert(
              db.GoalTagsCompanion.insert(tagId: tagId, goalId: goalId),
              onConflict: DoNothing(),
            );
      }
    });
  }

  Future<void> setNoteTags(String noteId, List<String> names) async {
    final tagIds = await _resolveTagIds(names);
    await _database.transaction(() async {
      await (_database.delete(
        _database.noteTags,
      )..where((t) => t.noteId.equals(noteId))).go();
      for (final tagId in tagIds) {
        await _database.into(_database.noteTags).insert(
              db.NoteTagsCompanion.insert(tagId: tagId, noteId: noteId),
              onConflict: DoNothing(),
            );
      }
    });
  }

  // --- Internals -----------------------------------------------------------

  Future<List<String>> _resolveTagIds(List<String> names) async {
    final out = <String>[];
    for (final name in names) {
      final clean = normalizeTagName(name);
      if (clean.isEmpty) continue;
      out.add(await ensureTag(clean));
    }
    return out;
  }

  Future<List<String>> _namesFor(
    String linkTable,
    String idColumn,
    String entityId,
  ) async {
    final result = await _database.customSelect(
      'SELECT t.name AS name FROM tags t '
      'INNER JOIN $linkTable l ON l.tag_id = t.id '
      'WHERE l.$idColumn = ? '
      'ORDER BY t.sort_order, t.name COLLATE NOCASE',
      variables: [Variable<String>(entityId)],
    ).get();
    return result.map((r) => r.read<String>('name')).toList();
  }

  Future<Map<String, List<String>>> _namesMap(
    String linkTable,
    String idColumn,
    List<String> ids,
  ) async {
    final map = <String, List<String>>{for (final id in ids) id: <String>[]};
    if (ids.isEmpty) return map;
    final placeholders = List.filled(ids.length, '?').join(',');
    final result = await _database.customSelect(
      'SELECT l.$idColumn AS eid, t.name AS name FROM tags t '
      'INNER JOIN $linkTable l ON l.tag_id = t.id '
      'WHERE l.$idColumn IN ($placeholders) '
      'ORDER BY t.sort_order, t.name COLLATE NOCASE',
      variables: [for (final id in ids) Variable<String>(id)],
    ).get();
    for (final row in result) {
      final eid = row.read<String>('eid');
      (map[eid] ??= []).add(row.read<String>('name'));
    }
    return map;
  }

  Tag _toDomain(db.Tag row) => Tag(
        id: row.id,
        name: row.name,
        color: row.color,
        sortOrder: row.sortOrder,
        createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
      );
}
