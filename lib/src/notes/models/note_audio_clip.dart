/// A single voice clip attached to a [Note]. Each clip maps to one audio file
/// on disk; a note may have zero or more, ordered by [position].
final class NoteAudioClip {
  final String id;
  final String noteId;
  final String audioPath;
  final int durationMs;
  final int position;
  final DateTime createdAt;

  const NoteAudioClip({
    required this.id,
    required this.noteId,
    required this.audioPath,
    this.durationMs = 0,
    this.position = 0,
    required this.createdAt,
  });

  NoteAudioClip copyWith({
    String? id,
    String? noteId,
    String? audioPath,
    int? durationMs,
    int? position,
    DateTime? createdAt,
  }) => NoteAudioClip(
    id: id ?? this.id,
    noteId: noteId ?? this.noteId,
    audioPath: audioPath ?? this.audioPath,
    durationMs: durationMs ?? this.durationMs,
    position: position ?? this.position,
    createdAt: createdAt ?? this.createdAt,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteAudioClip &&
          id == other.id &&
          noteId == other.noteId &&
          audioPath == other.audioPath &&
          durationMs == other.durationMs &&
          position == other.position &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
    id,
    noteId,
    audioPath,
    durationMs,
    position,
    createdAt,
  );
}
