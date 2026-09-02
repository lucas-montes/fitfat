import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../models/store.dart';
import '../providers/ingredients.dart';
import '../repositories/ingredient_repository.dart';

final class StoreManagerScreen extends ConsumerWidget {
  const StoreManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final storesAsync = ref.watch(storesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.storeManagerTitle)),
      floatingActionButton: FloatingActionButton(heroTag: null, 
        onPressed: () => _addStore(context, ref),
        child: const Icon(Icons.add),
      ),
      body: storesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.errorWithMessage('$e'))),
        data: (stores) => stores.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    l10n.storeManagerEmpty,
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ListView.builder(
                itemCount: stores.length,
                itemBuilder: (_, i) => ListTile(
                  leading: const Icon(Icons.storefront_outlined),
                  title: Text(stores[i].name),
                  trailing: const Icon(Icons.edit_outlined, size: 18),
                  onTap: () => _renameStore(context, ref, stores[i]),
                ),
              ),
      ),
    );
  }

  Future<void> _addStore(BuildContext context, WidgetRef ref) async {
    final name = await promptStoreName(context);
    if (name == null) return;
    await ref
        .read(ingredientRepositoryProvider)
        .insertStore(newStore(name: name));
    ref.invalidate(storesProvider);
  }

  Future<void> _renameStore(
    BuildContext context,
    WidgetRef ref,
    Store store,
  ) async {
    final name = await promptStoreName(context, initial: store.name);
    if (name == null || name == store.name) return;
    await ref
        .read(ingredientRepositoryProvider)
        .updateStore(
          Store(id: store.id, name: name, createdAt: store.createdAt),
        );
    ref.invalidate(storesProvider);
  }
}

/// Name prompt used by the store manager and the price sheet's inline
/// "add store" action; returns the trimmed name or null when cancelled.
///
/// The text controller is owned by [_StoreNameDialog]'s state so the framework
/// disposes it only after the route (including its exit animation) is fully
/// torn down — disposing eagerly on pop rebuilds the animating dialog with a
/// disposed controller.
Future<String?> promptStoreName(BuildContext context, {String? initial}) =>
    showDialog<String>(
      context: context,
      builder: (_) => _StoreNameDialog(initial: initial),
    );

final class _StoreNameDialog extends StatefulWidget {
  final String? initial;

  const _StoreNameDialog({this.initial});

  @override
  State<_StoreNameDialog> createState() => _StoreNameDialogState();
}

final class _StoreNameDialogState extends State<_StoreNameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial ?? '',
  );
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(
        widget.initial == null ? l10n.storeManagerAddTile : l10n.commonEdit,
      ),
      content: Form(
        key: _formKey,
        child: TextFormField(
          autofocus: true,
          controller: _controller,
          decoration: InputDecoration(labelText: l10n.storeNameLabel),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? l10n.storeNameRequired : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(_controller.text.trim());
            }
          },
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}
