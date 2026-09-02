import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../models/note.dart';
import '../../ui/date_formats.dart';
import '../../ui/widgets/empty_state.dart';
import '../providers/notes.dart';
import 'note_editor_screen.dart';

/// Notes tab (schema v9): a simple chronological list of free-form notes,
/// newest first. Tapping a note opens the editor; the FAB creates a new one.
final class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref,
    Note? note,
  ) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => NoteEditorScreen(note: note)),
    );
    if (saved == true) ref.invalidate(noteListProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final notesAsync = ref.watch(noteListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.notesAppBar)),
      floatingActionButton: FloatingActionButton(heroTag: null, 
        tooltip: l10n.notesFab,
        onPressed: () => _openEditor(context, ref, null),
        child: const Icon(Icons.add),
      ),
      body: notesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.errorWithMessage('$e'))),
        data: (notes) {
          if (notes.isEmpty) {
            return EmptyState(
              icon: Icons.note_alt_outlined,
              title: l10n.notesEmptyTitle,
              description: l10n.notesEmptyBody,
              ctaLabel: l10n.notesFab,
              onCtaPressed: () => _openEditor(context, ref, null),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notes.length,
            itemBuilder: (context, i) => _NoteTile(
              note: notes[i],
              onTap: () => _openEditor(context, ref, notes[i]),
            ),
          );
        },
      ),
    );
  }
}

final class _NoteTile extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;

  const _NoteTile({required this.note, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final preview = note.body.trim();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: onTap,
        title: Text(
          note.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (preview.isNotEmpty)
              Text(
                preview,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            if (note.clipCount > 0) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.graphic_eq,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    l10n.notesVoiceCount(note.clipCount),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Text(
              DateFormats.formatDate(context, note.updatedAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
