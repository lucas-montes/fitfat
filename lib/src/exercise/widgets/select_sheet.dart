import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

final class DisplayItem {
  final String id;
  final String name;
  final String? imagePath;
  final String? subtitle;
  const DisplayItem({required this.id, required this.name, this.imagePath, this.subtitle});
}

Future<Set<String>?> showSelectSheet(
  BuildContext context, {
  required List<DisplayItem> items,
  required Set<String> initialSelected,
  String? title,
  String? hint,
}) {
  return showModalBottomSheet<Set<String>>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _SelectSheetContent(items: items, initialSelected: initialSelected, title: title, hint: hint),
  );
}

final class _SelectSheetContent extends StatefulWidget {
  final List<DisplayItem> items;
  final Set<String> initialSelected;
  final String? title;
  final String? hint;
  const _SelectSheetContent({required this.items, required this.initialSelected, this.title, this.hint});
  @override
  State<_SelectSheetContent> createState() => _SelectSheetContentState();
}

final class _SelectSheetContentState extends State<_SelectSheetContent> {
  final _searchCtrl = TextEditingController();
  final Set<String> _selected = {};
  String _query = '';
  Timer? _debounce;

  @override
  void initState() { super.initState(); _selected.addAll(widget.initialSelected); }
  @override
  void dispose() { _searchCtrl.dispose(); _debounce?.cancel(); super.dispose(); }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () { if (mounted) setState(() => _query = v); });
  }

  Widget _buildThumbnail(DisplayItem item) {
    if (item.imagePath != null && item.imagePath!.isNotEmpty) {
      return Image.file(File(item.imagePath!), fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallbackIcon());
    }
    return _fallbackIcon();
  }

  Widget _fallbackIcon() {
    final theme = Theme.of(context);
    return Icon(Icons.image_outlined, color: theme.colorScheme.onSurfaceVariant, size: 28);
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty ? widget.items : widget.items.where((it) => it.name.toLowerCase().contains(q) || (it.subtitle ?? '').toLowerCase().contains(q)).toList();
    return DraggableScrollableSheet(initialChildSize: 0.9, minChildSize: 0.5, maxChildSize: 0.95, expand: false, builder: (ctx, scrollController) {
      return Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 16, 8, 8), child: Row(children: [Expanded(child: Text(widget.title ?? 'Select', style: Theme.of(context).textTheme.titleMedium)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)) ])),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: TextField(controller: _searchCtrl, autofocus: true, decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: widget.hint ?? 'Search', isDense: true), onChanged: _onSearchChanged)),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Row(children: [Text('${filtered.length} items'), const Spacer(), TextButton(onPressed: () => setState(() { if (_selected.length == filtered.length) _selected.clear(); else _selected.addAll(filtered.map((e) => e.id)); }), child: Text(_selected.length == filtered.length ? 'Clear' : 'Select all'))])),
        Expanded(child: ListView.builder(controller: scrollController, itemCount: filtered.length, itemBuilder: (_, i) {
          final it = filtered[i];
          return ListTile(
            leading: SizedBox(width: 48, height: 48, child: _buildThumbnail(it)),
            title: Text(it.name),
            subtitle: it.subtitle != null ? Text(it.subtitle!) : null,
            trailing: _selected.contains(it.id) ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary) : const Icon(Icons.add_circle_outline),
            onTap: () => setState(() { if (_selected.contains(it.id)) _selected.remove(it.id); else _selected.add(it.id); }),
          );
        })),
        SafeArea(child: Padding(padding: const EdgeInsets.all(16), child: FilledButton(onPressed: () => Navigator.pop(ctx, _selected), child: Text('Sync selected (${_selected.length})')))),
      ]);
    });
  }
}
