import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/database_provider.dart';
import '../../models/note.dart';
import '../repositories/note_repository.dart';

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepository(ref.watch(databaseProvider));
});

// ---------------------------------------------------------------------------
// Notes list provider (newest first)
// ---------------------------------------------------------------------------

final noteListProvider = FutureProvider<List<Note>>((ref) async {
  return ref.watch(noteRepositoryProvider).getAll();
});
