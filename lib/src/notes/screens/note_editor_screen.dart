import 'package:flutter/material.dart';
import '../../ui/widgets/top_banner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../l10n/app_localizations.dart';
import '../../models/note.dart';
import '../../tags/widgets/tag_picker.dart';
import '../../tags/providers/tags.dart';
import '../audio/note_audio_path.dart';
import '../models/note_audio_clip.dart';
import '../providers/notes.dart';
import '../widgets/voice_notes_field.dart';

/// Create/edit screen for a single [Note]. Saving inserts (new) or updates
/// (existing) and pops `true`; editing also offers a destructive delete.
final class NoteEditorScreen extends ConsumerStatefulWidget {
  final Note? note;

  const NoteEditorScreen({super.key, this.note});

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

final class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _bodyCtrl;
  late final String _noteId;
  List<String> _tags = [];
  List<NoteAudioClip> _clips = [];
  bool _saving = false;
  bool _saved = false;

  bool get _isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();
    _noteId = widget.note?.id ?? const Uuid().v7();
    _titleCtrl = TextEditingController(text: widget.note?.title ?? '');
    _bodyCtrl = TextEditingController(text: widget.note?.body ?? '');
    _tags = List<String>.from(widget.note?.tags ?? const []);
    if (_isEditing) {
      ref.read(noteRepositoryProvider).getClips(_noteId).then((clips) {
        if (mounted) setState(() => _clips = clips);
      });
    }
  }

  @override
  void dispose() {
    // For an unsaved (new) note, drop any clips recorded during this session.
    if (!_saved && !_isEditing) {
      for (final clip in _clips) {
        deleteClipFile(clip.audioPath);
      }
    }
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final repo = ref.read(noteRepositoryProvider);
      final title = _titleCtrl.text.trim();
      final body = _bodyCtrl.text.trim();

      if (_isEditing) {
        final existing = widget.note!;
        await repo.update(
          existing.copyWith(
            title: title,
            body: body,
            tags: _tags.isEmpty ? null : _tags,
            updatedAt: DateTime.now(),
          ),
        );
      } else {
        await repo.insert(
          Note(
            id: _noteId,
            title: title,
            body: body,
            tags: _tags.isEmpty ? null : _tags,
            updatedAt: DateTime.now(),
            createdAt: DateTime.now(),
          ),
        );
      }
      await repo.saveClips(_noteId, _clips);

      // New tags typed here must surface in the Tags vocabulary.
      ref.invalidate(tagListProvider);
      ref.invalidate(tagNamesProvider);
      _saved = true;
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        showTopBanner(context, message: l10n.errorWithMessage('$e'));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.notesDeleteConfirmTitle),
        content: Text(l10n.notesDeleteConfirmBody(widget.note!.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.notesDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await ref.read(noteRepositoryProvider).delete(widget.note!.id);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? l10n.notesEditorEditTitle : l10n.notesEditorNewTitle,
        ),
        actions: [
          if (_isEditing)
            IconButton(
              tooltip: l10n.notesDelete,
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleCtrl,
              autofocus: true,
              decoration: InputDecoration(labelText: l10n.notesTitleLabel),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.notesTitleRequired
                  : null,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bodyCtrl,
              minLines: 6,
              maxLines: null,
              decoration: InputDecoration(
                labelText: l10n.notesBodyLabel,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            TagPicker(
              tags: _tags,
              onChanged: (tags) => setState(() => _tags = tags),
            ),
            const SizedBox(height: 24),
            VoiceNotesField(
              noteId: _noteId,
              clips: _clips,
              onChanged: (clips) => setState(() => _clips = clips),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? l10n.notesEditing : l10n.notesSave),
            ),
          ],
        ),
      ),
    );
  }
}
