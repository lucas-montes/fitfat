import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../database/app_database.dart' as db;
import '../../models/tag.dart';

typedef _TagLoader = Future<Map<String, List<String>?>> Function();
typedef _TagWriter = Future<void> Function(Map<String, List<String>?>);
typedef _TagRenamer = Future<void> Function(String oldName, String newName);

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
  /// can both funnel through here.
  Future<void> saveTag({required String name, int? color, String? id}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final existing = id != null
        ? await (_database.select(
            _database.tags,
          )..where((t) => t.id.equals(id))).getSingleOrNull()
        : await (_database.select(
            _database.tags,
          )..where((t) => t.name.equals(name))).getSingleOrNull();
    if (existing == null) {
      // New tags land at the bottom of the priority order.
      final maxOrder = await (_database.select(
        _database.tags,
      )..orderBy([(t) => OrderingTerm.desc(t.sortOrder)])).getSingleOrNull();
      await _database
          .into(_database.tags)
          .insert(
            db.TagsCompanion.insert(
              id: const Uuid().v7(),
              name: name,
              color: Value(color),
              sortOrder: Value((maxOrder?.sortOrder ?? -1) + 1),
              createdAt: now,
              updatedAt: now,
            ),
          );
    } else {
      await (_database.update(
        _database.tags,
      )..where((t) => t.id.equals(existing.id))).write(
        db.TagsCompanion(
          name: Value(name),
          color: Value(color),
          updatedAt: Value(now),
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

  /// Renames a tag everywhere: the vocabulary row plus every JSON string[]
  /// reference across planner items (tasks + experiments), notes and goals.
  Future<void> renameTag(String oldName, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty || trimmed == oldName) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    await _database.transaction(() async {
      await (_database.update(_database.tags)
            ..where((t) => t.name.equals(oldName)))
          .write(db.TagsCompanion(name: Value(trimmed), updatedAt: Value(now)));
      for (final updated in [
        _mapRenameWith(_loadPlannerItemsTags, _writePlannerItemsTags),
        _mapRenameWith(_loadNotesTags, _writeNotesTags),
        _mapRenameWith(_loadGoalsTags, _writeGoalsTags),
      ]) {
        await updated(oldName, trimmed);
      }
    });
  }

  /// Deletes a tag from the vocabulary and strips every reference to it from
  /// planner items, notes and goals. Returns the number of usages removed.
  Future<int> deleteTag(String name) async {
    var removed = 0;
    await _database.transaction(() async {
      removed = await _stripFrom(
        name,
        _loadPlannerItemsTags,
        _writePlannerItemsTags,
      );
      removed += await _stripFrom(name, _loadNotesTags, _writeNotesTags);
      removed += await _stripFrom(name, _loadGoalsTags, _writeGoalsTags);
      await (_database.delete(
        _database.tags,
      )..where((t) => t.name.equals(name))).go();
    });
    return removed;
  }

  /// Every known tag name — the registered vocabulary plus any free-form name
  /// still referenced by an entity. Powers autocomplete suggestions.
  Future<List<String>> distinctTagNames() async {
    final names = <String>{};
    for (final row in await _database.select(_database.tags).get()) {
      names.add(row.name);
    }
    for (final row in await _database.select(_database.plannerItems).get()) {
      names.addAll(_decode(row.tags) ?? const []);
    }
    for (final row in await _database.select(_database.notes).get()) {
      names.addAll(_decode(row.tags) ?? const []);
    }
    for (final row in await _database.select(_database.goals).get()) {
      names.addAll(_decode(row.tags) ?? const []);
    }
    return names.toList()..sort();
  }

  /// Usage count per tag name across all tagged entity types.
  Future<Map<String, int>> usageCounts() async {
    final counts = <String, int>{};
    void count(List<String>? tags) {
      for (final t in tags ?? const <String>[]) {
        counts.update(t, (c) => c + 1, ifAbsent: () => 1);
      }
    }

    for (final row in await _database.select(_database.plannerItems).get()) {
      count(_decode(row.tags));
    }
    for (final row in await _database.select(_database.notes).get()) {
      count(_decode(row.tags));
    }
    for (final row in await _database.select(_database.goals).get()) {
      count(_decode(row.tags));
    }
    return counts;
  }

  Tag _toDomain(db.Tag row) => Tag(
    id: row.id,
    name: row.name,
    color: row.color,
    sortOrder: row.sortOrder,
    createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
  );

  _TagRenamer _mapRenameWith(_TagLoader load, _TagWriter write) =>
      (oldName, newName) async {
        final rows = await load();
        final changed = <String, List<String>?>{};
        rows.forEach((id, tags) {
          if (tags == null || !tags.contains(oldName)) return;
          changed[id] = tags.map((t) => t == oldName ? newName : t).toList();
        });
        if (changed.isNotEmpty) await write(changed);
      };

  Future<int> _stripFrom(String name, _TagLoader load, _TagWriter write) async {
    final rows = await load();
    var removed = 0;
    final changed = <String, List<String>?>{};
    rows.forEach((id, tags) {
      if (tags == null || !tags.contains(name)) return;
      removed += tags.where((t) => t == name).length;
      final next = tags.where((t) => t != name).toList();
      changed[id] = next.isEmpty ? null : next;
    });
    if (changed.isNotEmpty) await write(changed);
    return removed;
  }

  Future<Map<String, List<String>?>> _loadPlannerItemsTags() async {
    final rows = await _database.select(_database.plannerItems).get();
    return {for (final r in rows) r.id: _decode(r.tags)};
  }

  Future<void> _writePlannerItemsTags(Map<String, List<String>?> rows) =>
      _database.batch((batch) {
        rows.forEach((id, tags) {
          batch.update(
            _database.plannerItems,
            db.PlannerItemsCompanion(tags: Value(_encode(tags))),
            where: (db.$PlannerItemsTable t) => t.id.equals(id),
          );
        });
      });

  Future<Map<String, List<String>?>> _loadNotesTags() async {
    final rows = await _database.select(_database.notes).get();
    return {for (final r in rows) r.id: _decode(r.tags)};
  }

  Future<void> _writeNotesTags(Map<String, List<String>?> rows) =>
      _database.batch((batch) {
        rows.forEach((id, tags) {
          batch.update(
            _database.notes,
            db.NotesCompanion(tags: Value(_encode(tags))),
            where: (db.$NotesTable t) => t.id.equals(id),
          );
        });
      });

  Future<Map<String, List<String>?>> _loadGoalsTags() async {
    final rows = await _database.select(_database.goals).get();
    return {for (final r in rows) r.id: _decode(r.tags)};
  }

  Future<void> _writeGoalsTags(Map<String, List<String>?> rows) =>
      _database.batch((batch) {
        rows.forEach((id, tags) {
          batch.update(
            _database.goals,
            db.GoalsCompanion(tags: Value(_encode(tags))),
            where: (db.$GoalsTable t) => t.id.equals(id),
          );
        });
      });

  static String? _encode(List<String>? values) {
    if (values == null || values.isEmpty) return null;
    return jsonEncode(values);
  }

  static List<String>? _decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded.cast<String>();
    } catch (_) {}
    return null;
  }
}
