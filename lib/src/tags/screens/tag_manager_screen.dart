import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../models/tag.dart';
import '../providers/tags.dart';

/// A small curated palette for assigning explicit priority colors.
const List<Color> _kPalette = [
  Color(0xFF1E88E5), // blue
  Color(0xFF43A047), // green
  Color(0xFFFB8C00), // orange
  Color(0xFFE53935), // red
  Color(0xFF8E24AA), // purple
  Color(0xFF00ACC1), // cyan
  Color(0xFF6D4C41), // brown
  Color(0xFF546E7A), // blue grey
];

/// Manage the shared "priorities" vocabulary: reorder (rank), color, rename
/// and delete tags. Renames/deletes propagate to every tagged task, note,
/// goal and experiment.
final class TagManagerScreen extends ConsumerStatefulWidget {
  const TagManagerScreen({super.key});

  @override
  ConsumerState<TagManagerScreen> createState() => _TagManagerScreenState();
}

final class _TagManagerScreenState extends ConsumerState<TagManagerScreen> {
  void _invalidate() {
    ref.invalidate(tagListProvider);
    ref.invalidate(tagNamesProvider);
    ref.invalidate(tagUsageCountsProvider);
  }

  Future<void> _addTag() async {
    final l10n = AppLocalizations.of(context)!;
    final name = await _promptName(title: l10n.prioritiesAdd, initialName: '');
    if (name == null || !mounted) return;
    await ref.read(tagRepositoryProvider).saveTag(name: name, color: null);
    _invalidate();
  }

  Future<void> _renameTag(Tag tag) async {
    final l10n = AppLocalizations.of(context)!;
    final name = await _promptName(
      title: l10n.prioritiesRename,
      initialName: tag.name,
    );
    if (name == null || name == tag.name || !mounted) return;
    await ref.read(tagRepositoryProvider).renameTag(tag.name, name);
    _invalidate();
  }

  Future<String?> _promptName({
    required String title,
    required String initialName,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: initialName);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: l10n.prioritiesNameLabel),
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
  }

  Future<void> _pickColor(Tag tag) async {
    final l10n = AppLocalizations.of(context)!;
    final selected = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.prioritiesColor),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final color in _kPalette)
                  InkWell(
                    onTap: () => Navigator.of(ctx).pop(color.toARGB32()),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: tag.color == color.toARGB32()
                            ? Border.all(width: 3, color: Colors.black54)
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    if (selected == null || !mounted) return;
    await ref
        .read(tagRepositoryProvider)
        .saveTag(name: tag.name, color: selected, id: tag.id);
    _invalidate();
  }

  Future<void> _deleteTag(Tag tag) async {
    final l10n = AppLocalizations.of(context)!;
    final counts = await ref.read(tagRepositoryProvider).usageCounts();
    if (!mounted) return;
    final usages = counts[tag.name] ?? 0;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.prioritiesDeleteConfirmTitle),
        content: Text(l10n.prioritiesDeleteConfirmBody(usages, tag.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(tagRepositoryProvider).deleteTag(tag.name);
    _invalidate();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tagsAsync = ref.watch(tagListProvider);
    final countsAsync = ref.watch(tagUsageCountsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.prioritiesTitle)),
      body: tagsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (tags) {
          if (tags.isEmpty) {
            return Center(child: Text(l10n.prioritiesEmpty));
          }
          final counts = countsAsync.value ?? const <String, int>{};
          return ReorderableListView.builder(
            itemCount: tags.length,
            onReorder: (oldIndex, newIndex) async {
              setState(() {
                if (newIndex > oldIndex) newIndex -= 1;
                final moved = tags.removeAt(oldIndex);
                tags.insert(newIndex, moved);
              });
              await ref
                  .read(tagRepositoryProvider)
                  .reorder(tags.map((t) => t.name).toList());
              _invalidate();
            },
            itemBuilder: (context, index) {
              final tag = tags[index];
              return ListTile(
                key: ValueKey(tag.id),
                leading: InkWell(
                  onTap: () => _pickColor(tag),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: tag.color != null ? Color(tag.color!) : null,
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: tag.color == null
                        ? Icon(
                            Icons.palette_outlined,
                            size: 16,
                            color: Theme.of(context).hintColor,
                          )
                        : null,
                  ),
                ),
                title: Text(tag.name),
                subtitle: Text(
                  l10n.prioritiesUsageCount(counts[tag.name] ?? 0),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: l10n.prioritiesRename,
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _renameTag(tag),
                    ),
                    IconButton(
                      tooltip: l10n.commonDelete,
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _deleteTag(tag),
                    ),
                    ReorderableDragStartListener(
                      index: index,
                      child: const Icon(Icons.drag_handle),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.prioritiesAdd,
        onPressed: _addTag,
        child: const Icon(Icons.add),
      ),
    );
  }
}
