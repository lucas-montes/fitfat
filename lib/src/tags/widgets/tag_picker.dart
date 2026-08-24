import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../models/tag.dart';
import '../../ui/tag_colors.dart';
import '../providers/tags.dart';

/// Resolves a tag's display colors `(background, foreground)`: an explicit
/// vocabulary color wins, otherwise the deterministic hash palette.
(Color, Color) tagDisplayColors(String name, Map<String, int> explicit) {
  final argb = explicit[name];
  if (argb != null) {
    final color = Color(argb);
    // Pick a readable foreground: dark text on light fills, light on dark.
    final fg = color.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;
    return (color, fg);
  }
  return TagColors.forTag(name);
}

/// Explicit vocabulary colors keyed by tag name, from [tagListProvider] data.
Map<String, int> explicitColorsFrom(List<Tag> tags) => {
  for (final t in tags)
    if (t.color != null) t.name: t.color!,
};

/// A read-only chip rendering [name] with its vocabulary color.
final class TagChip extends ConsumerWidget {
  final String name;
  final VoidCallback? onTap;

  const TagChip({super.key, required this.name, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = explicitColorsFrom(
      ref.watch(tagListProvider).value ?? const [],
    );
    final (bg, fg) = tagDisplayColors(name, colors);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          name,
          style: TextStyle(
            color: fg,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Multi-select tag input used by the task, note, goal and experiment forms.
/// Controlled: pass the current selection and receive updates via [onChanged].
/// Suggestions come from the shared vocabulary plus every free-form tag still
/// referenced anywhere, ordered by priority rank.
final class TagPicker extends ConsumerStatefulWidget {
  final List<String> tags;
  final ValueChanged<List<String>> onChanged;
  final String? labelText;
  final String? hintText;

  const TagPicker({
    super.key,
    required this.tags,
    required this.onChanged,
    this.labelText,
    this.hintText,
  });

  @override
  ConsumerState<TagPicker> createState() => _TagPickerState();
}

final class _TagPickerState extends ConsumerState<TagPicker> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add(String rawName) {
    final name = rawName.trim();
    _controller.clear();
    if (name.isEmpty || widget.tags.contains(name)) return;
    widget.onChanged([...widget.tags, name]);
  }

  void _remove(String name) =>
      widget.onChanged(widget.tags.where((t) => t != name).toList());

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final vocab = ref.watch(tagListProvider).value ?? const <Tag>[];
    final knownNames = ref.watch(tagNamesProvider).value ?? const <String>[];

    final selected = {...widget.tags};
    // Suggestion order: registered priority order first, then the rest.
    final vocabNames = vocab.map((t) => t.name).toSet();
    final suggestions = <String>[
      ...vocab.map((t) => t.name),
      ...knownNames.where((n) => !vocabNames.contains(n)),
    ].where((n) => !selected.contains(n)).toSet().toList();

    final colors = explicitColorsFrom(vocab);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          textCapitalization: TextCapitalization.none,
          decoration: InputDecoration(
            labelText: widget.labelText ?? l10n.plannerTagsLabel,
            hintText: widget.hintText ?? l10n.plannerTagsHint,
            suffixIcon: IconButton(
              icon: const Icon(Icons.add),
              tooltip: l10n.plannerTagsAdd,
              onPressed: () => _add(_controller.text),
            ),
          ),
          onSubmitted: _add,
        ),
        const SizedBox(height: 8),
        if (widget.tags.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final tag in widget.tags)
                Builder(
                  builder: (_) {
                    final (bg, fg) = tagDisplayColors(tag, colors);
                    return InputChip(
                      label: Text(tag),
                      backgroundColor: bg,
                      deleteIconColor: fg,
                      onDeleted: () => _remove(tag),
                    );
                  },
                ),
            ],
          ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final tag in suggestions)
                ActionChip(
                  label: Text(tag),
                  backgroundColor: colors.containsKey(tag)
                      ? tagDisplayColors(tag, colors).$1
                      : null,
                  onPressed: () => _add(tag),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
