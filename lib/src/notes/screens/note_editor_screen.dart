import 'package:flutter/material.dart';
import '../../ui/widgets/top_banner.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
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
  bool _showPreview = false;

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

  /// Wraps the current selection in [prefix]/[suffix] (or inserts an empty
  /// pair at the cursor when nothing is selected), leaving the cursor right
  /// after the inserted/wrapped text.
  void _wrapSelection(String prefix, String suffix) {
    final text = _bodyCtrl.text;
    final selection = _bodyCtrl.selection;
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;
    final inner = text.substring(start, end);
    final replacement = '$prefix$inner$suffix';
    _bodyCtrl.value = TextEditingValue(
      text: text.replaceRange(start, end, replacement),
      selection: TextSelection.collapsed(offset: start + replacement.length),
    );
  }

  /// Inserts [prefix] at the start of the line the cursor is on — for markers
  /// like `## ` or `- ` that belong at the front of a line rather than
  /// wrapped around a selection.
  void _prefixLine(String prefix) {
    final text = _bodyCtrl.text;
    final selection = _bodyCtrl.selection;
    final cursor = selection.isValid ? selection.start : text.length;
    final lineStart = text.lastIndexOf('\n', cursor - 1) + 1;
    _bodyCtrl.value = TextEditingValue(
      text: text.replaceRange(lineStart, lineStart, prefix),
      selection: TextSelection.collapsed(offset: cursor + prefix.length),
    );
  }

  /// Raw markdown body (monospace) with a preview toggle. The toolbar only
  /// shows while editing — there is nothing to insert into a read-only
  /// preview.
  Widget _buildBodyField(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.notesBodyLabel, style: Theme.of(context).textTheme.labelLarge),
            IconButton(
              key: const ValueKey('notesBodyPreviewToggle'),
              icon: Icon(
                _showPreview ? Icons.edit_outlined : Icons.visibility_outlined,
              ),
              tooltip: _showPreview
                  ? l10n.notesBodyEditTooltip
                  : l10n.notesBodyPreviewTooltip,
              onPressed: () => setState(() => _showPreview = !_showPreview),
            ),
          ],
        ),
        if (_showPreview)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(4),
            ),
            // An empty body renders an empty box — no placeholder text is
            // needed, since the edit toggle is one tap away.
            child: MarkdownBody(data: _bodyCtrl.text, selectable: true),
          )
        else ...[
          _buildMarkdownToolbar(l10n),
          TextFormField(
            key: const ValueKey('notesBodyField'),
            controller: _bodyCtrl,
            minLines: 6,
            maxLines: null,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontFamily: 'monospace',
            ),
            decoration: const InputDecoration(alignLabelWithHint: true),
          ),
        ],
      ],
    );
  }

  /// Tiny toolbar inserting markdown markers at the cursor: bold, italic,
  /// heading, list. Not a full formatting bar — just the handful of markers
  /// tedious enough to type by hand on a phone keyboard.
  Widget _buildMarkdownToolbar(AppLocalizations l10n) {
    return Row(
      children: [
        IconButton(
          key: const ValueKey('notesToolbarBold'),
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.format_bold),
          tooltip: l10n.notesToolbarBold,
          onPressed: () => _wrapSelection('**', '**'),
        ),
        IconButton(
          key: const ValueKey('notesToolbarItalic'),
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.format_italic),
          tooltip: l10n.notesToolbarItalic,
          onPressed: () => _wrapSelection('_', '_'),
        ),
        IconButton(
          key: const ValueKey('notesToolbarHeading'),
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.title),
          tooltip: l10n.notesToolbarHeading,
          onPressed: () => _prefixLine('## '),
        ),
        IconButton(
          key: const ValueKey('notesToolbarList'),
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.format_list_bulleted),
          tooltip: l10n.notesToolbarList,
          onPressed: () => _prefixLine('- '),
        ),
      ],
    );
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
          // Save is the primary action, so it lives here in both new and edit
          // mode. It mirrors the state the bottom button used to carry:
          // disabled while saving, with the in-flight label.
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? l10n.notesEditing : l10n.notesSave),
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
            _buildBodyField(context, l10n),
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
            // Delete takes the slot save vacated, at the bottom and well away
            // from the app bar, so a destructive action is not one stray tap from
            // the primary one. Still guarded by the confirmation dialog.
            if (_isEditing) ...[
              const Divider(),
              TextButton.icon(
                onPressed: _delete,
                icon: const Icon(Icons.delete_outline),
                label: Text(l10n.notesDelete),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
