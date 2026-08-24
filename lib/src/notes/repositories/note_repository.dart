import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../database/app_database.dart' as db;
import '../../models/note.dart';

final class NoteRepository {
  final db.AppDatabase _database;
  const NoteRepository(this._database);

  Future<List<Note>> getAll() async {
    final rows =
        await (_database.select(_database.notes)..orderBy([
              (t) => OrderingTerm(
                expression: t.updatedAt,
                mode: OrderingMode.desc,
              ),
            ]))
            .get();
    return rows.map(_toDomain).toList();
  }

  Future<Note?> getById(String id) async {
    final row = await (_database.select(
      _database.notes,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return _toDomain(row);
  }

  Future<void> insert(Note note) async {
    await _database
        .into(_database.notes)
        .insert(
          db.NotesCompanion.insert(
            id: note.id,
            title: note.title,
            body: Value(note.body),
            tags: Value(_encodeTags(note.tags)),
            updatedAt: note.updatedAt.millisecondsSinceEpoch,
            createdAt: note.createdAt.millisecondsSinceEpoch,
          ),
        );
  }

  Future<void> update(Note note) async {
    await (_database.update(
      _database.notes,
    )..where((t) => t.id.equals(note.id))).write(
      db.NotesCompanion(
        title: Value(note.title),
        body: Value(note.body),
        tags: Value(_encodeTags(note.tags)),
        updatedAt: Value(note.updatedAt.millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> delete(String id) async {
    await (_database.delete(
      _database.notes,
    )..where((t) => t.id.equals(id))).go();
  }

  Note _toDomain(db.Note row) => Note(
    id: row.id,
    title: row.title,
    body: row.body,
    tags: _decodeTags(row.tags),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
    createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
  );
}

/// All notes, newest first.
String? _encodeTags(List<String>? values) {
  if (values == null || values.isEmpty) return null;
  return jsonEncode(values);
}

List<String>? _decodeTags(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is List) return decoded.cast<String>();
  } catch (_) {}
  return null;
}

/// Creates a new [Note] with a fresh UUID v7 and the current timestamp.
Note newNote({required String title, String body = '', List<String>? tags}) =>
    Note(
      id: const Uuid().v7(),
      title: title,
      body: body,
      tags: tags,
      updatedAt: DateTime.now(),
      createdAt: DateTime.now(),
    );
