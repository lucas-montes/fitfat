import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../database/app_database.dart' as db;
import '../../models/note.dart';
import '../../tags/repositories/tag_repository.dart';
import '../audio/note_audio_path.dart';
import '../models/note_audio_clip.dart';

final class NoteRepository {
  final db.AppDatabase _database;
  const NoteRepository(this._database);

  Future<List<Note>> getAll() async {
    final rows =
        await (_database.select(_database.notes) ..orderBy([
              (t) => OrderingTerm(
                expression: t.updatedAt,
                mode: OrderingMode.desc,
              ),
            ]))
            .get();
    final notes = rows.map(_toDomain).toList();
    return _attachClipCounts(await _attachTags(notes));
  }

  Future<Note?> getById(String id) async {
    final row = await (_database.select(
      _database.notes,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    final notes = await _attachTags([_toDomain(row)]);
    return _attachClipCounts(notes).then((n) => n.first);
  }

  /// Ordered voice clips for a note (by [NoteAudioClip.position]).
  Future<List<NoteAudioClip>> getClips(String noteId) async {
    final rows = await (_database.select(_database.noteAudio)
          ..where((t) => t.noteId.equals(noteId))
          ..orderBy([(t) => OrderingTerm(
            expression: t.position,
            mode: OrderingMode.asc,
          )]))
        .get();
    return rows
        .map(
          (r) => NoteAudioClip(
            id: r.id,
            noteId: r.noteId,
            audioPath: r.audioPath,
            durationMs: r.durationMs,
            position: r.position,
            createdAt: DateTime.fromMillisecondsSinceEpoch(r.createdAt),
          ),
        )
        .toList();
  }

  /// Inserts a single clip row. The audio file is assumed to already exist on
  /// disk at [clip.audioPath].
  Future<void> insertClip(NoteAudioClip clip) async {
    await _database.into(_database.noteAudio).insert(
          db.NoteAudioCompanion.insert(
            id: clip.id,
            noteId: clip.noteId,
            audioPath: clip.audioPath,
            durationMs: Value(clip.durationMs),
            position: Value(clip.position),
            createdAt: clip.createdAt.millisecondsSinceEpoch,
          ),
        );
  }

  /// Persists the full ordered clip list for a note, reconciling rows already
  /// in the database with [clips]: inserts new ones, updates positions, and
  /// deletes (row + file) any previously stored clip not present in [clips].
  /// Call after the note row itself exists (insert/update the note first).
  Future<void> saveClips(String noteId, List<NoteAudioClip> clips) async {
    final existing = await getClips(noteId);
    final keepIds = {for (final c in clips) c.id};
    final ordered = [
      for (var i = 0; i < clips.length; i++)
        clips[i].copyWith(position: i),
    ];

    await _database.transaction(() async {
      for (final clip in existing) {
        if (!keepIds.contains(clip.id)) {
          await deleteClipFile(clip.audioPath);
          await (_database.delete(
            _database.noteAudio,
          )..where((t) => t.id.equals(clip.id))).go();
        }
      }
      for (final clip in ordered) {
        await (_database.update(
          _database.noteAudio,
        )..where((t) => t.id.equals(clip.id))).write(
          db.NoteAudioCompanion(
            audioPath: Value(clip.audioPath),
            durationMs: Value(clip.durationMs),
            position: Value(clip.position),
          ),
        );
        // New clip (no existing row) — insert it.
        final wasExisting = existing.any((e) => e.id == clip.id);
        if (!wasExisting) await insertClip(clip);
      }
    });
  }

  Future<void> insert(Note note) async {
    await _database
        .into(_database.notes)
        .insert(
          db.NotesCompanion.insert(
            id: note.id,
            title: note.title,
            body: Value(note.body),
            updatedAt: note.updatedAt.millisecondsSinceEpoch,
            createdAt: note.createdAt.millisecondsSinceEpoch,
          ),
        );
    if (note.tags != null) {
      await TagRepository(_database).setNoteTags(note.id, note.tags!);
    }
  }

  Future<void> update(Note note) async {
    await (_database.update(
      _database.notes,
    )..where((t) => t.id.equals(note.id))).write(
      db.NotesCompanion(
        title: Value(note.title),
        body: Value(note.body),
        updatedAt: Value(note.updatedAt.millisecondsSinceEpoch),
      ),
    );
    if (note.tags != null) {
      await TagRepository(_database).setNoteTags(note.id, note.tags!);
    }
  }

  Future<void> delete(String id) async {
    // Cascade removes the NoteAudio rows; delete their files first.
    final clips = await getClips(id);
    for (final clip in clips) {
      await deleteClipFile(clip.audioPath);
    }
    await (_database.delete(
      _database.notes,
    )..where((t) => t.id.equals(id))).go();
  }

  Note _toDomain(db.Note row) => Note(
    id: row.id,
    title: row.title,
    body: row.body,
    tags: null,
    clipCount: 0,
    updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
    createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
  );

  /// Populates [Note.clipCount] for a batch of notes in one lookup.
  Future<List<Note>> _attachClipCounts(List<Note> items) async {
    if (items.isEmpty) return items;
    final rows = await (_database.select(_database.noteAudio)
          ..where((t) => t.noteId.isIn(items.map((n) => n.id).toList())))
        .get();
    final counts = <String, int>{};
    for (final r in rows) {
      counts[r.noteId] = (counts[r.noteId] ?? 0) + 1;
    }
    return [
      for (final n in items) n.copyWith(clipCount: counts[n.id] ?? 0),
    ];
  }

  /// Tag (priority) access for this note table.
  TagRepository get _tags => TagRepository(_database);

  /// Populates [Note.tags] for a batch of notes in one lookup.
  Future<List<Note>> _attachTags(List<Note> items) async {
    if (items.isEmpty) return items;
    final map = await _tags.tagNamesForNotes(
      items.map((n) => n.id).toList(),
    );
    return [
      for (final n in items) n.copyWith(tags: map[n.id] ?? const []),
    ];
  }
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
