import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

final class DisplayItem {
  final String id;
  final String name;
  final String? imagePath;
  final Map<String, String>? imageHeaders;
  final String? subtitle;
  const DisplayItem({
    required this.id,
    required this.name,
    this.imagePath,
    this.imageHeaders,
    this.subtitle,
  });
}

Future<Set<String>?> showSelectSheet(
  BuildContext context, {
  required List<DisplayItem> items,
  required Set<String> initialSelected,
  String? title,
  String? hint,
  String? refreshTooltip,
  Future<List<DisplayItem>?> Function()? onRefresh,
}) {
  return showModalBottomSheet<Set<String>>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _SelectSheetContent(items: items, initialSelected: initialSelected, title: title, hint: hint, refreshTooltip: refreshTooltip, onRefresh: onRefresh),
  );
}

final class _SelectSheetContent extends StatefulWidget {
  final List<DisplayItem> items;
  final Set<String> initialSelected;
  final String? title;
  final String? hint;
  final String? refreshTooltip;
  final Future<List<DisplayItem>?> Function()? onRefresh;
  const _SelectSheetContent({required this.items, required this.initialSelected, this.title, this.hint, this.refreshTooltip, this.onRefresh});
  @override
  State<_SelectSheetContent> createState() => _SelectSheetContentState();
}

final class _SelectSheetContentState extends State<_SelectSheetContent> {
  final _searchCtrl = TextEditingController();
  final Set<String> _selected = {};
  late List<DisplayItem> _items;
  String _query = '';
  Timer? _debounce;
  bool _refreshing = false;

  @override
  void initState() { super.initState(); _selected.addAll(widget.initialSelected); _items = widget.items; }
  @override
  void dispose() { _searchCtrl.dispose(); _debounce?.cancel(); super.dispose(); }

  Future<void> _doRefresh() async {
    final refresh = widget.onRefresh;
    if (refresh == null || _refreshing) return;
    setState(() => _refreshing = true);
    try {
      final fresh = await refresh();
      if (!mounted) return;
      if (fresh != null) {
        setState(() {
          _items = fresh;
          _selected.removeWhere((id) => !fresh.any((d) => d.id == id));
        });
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () { if (mounted) setState(() => _query = v); });
  }

  Widget _buildThumbnail(DisplayItem item) {
    final path = item.imagePath;
    if (path != null && path.isNotEmpty) {
      if (path.startsWith('http')) {
        return Image.network(
          path,
          headers: item.imageHeaders,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackIcon(),
        );
      }
      return Image.file(File(path), fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallbackIcon());
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
    final filtered = q.isEmpty ? _items : _items.where((it) => it.name.toLowerCase().contains(q) || (it.subtitle ?? '').toLowerCase().contains(q)).toList();
    return DraggableScrollableSheet(initialChildSize: 0.9, minChildSize: 0.5, maxChildSize: 0.95, expand: false, builder: (ctx, scrollController) {
      return Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 16, 8, 8), child: Row(children: [Expanded(child: Text(widget.title ?? 'Select', style: Theme.of(context).textTheme.titleMedium)), if (widget.onRefresh != null) (_refreshing ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))) : IconButton(tooltip: widget.refreshTooltip, icon: const Icon(Icons.refresh), onPressed: _doRefresh)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)) ])),
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
