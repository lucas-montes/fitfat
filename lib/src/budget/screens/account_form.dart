import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../settings/providers/settings.dart';
import '../models/account.dart';
import '../providers/accounts.dart';
import '../providers/budget_overview.dart';
import '../repositories/account_repository.dart';
import '../widgets/account_type_meta.dart';

/// Create / edit an [Account].
final class AccountFormScreen extends ConsumerStatefulWidget {
  final String? accountId;

  const AccountFormScreen({super.key, this.accountId});

  @override
  ConsumerState<AccountFormScreen> createState() => _AccountFormScreenState();
}

final class _AccountFormScreenState extends ConsumerState<AccountFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _openingCtrl = TextEditingController();
  AccountType _type = AccountType.cash;
  bool _saving = false;
  Account? _existing;

  bool get _isEditing => widget.accountId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) _loadExisting();
  }

  Future<void> _loadExisting() async {
    final acc = await ref
        .read(accountRepositoryProvider)
        .getById(widget.accountId!);
    if (acc == null || !mounted) return;
    _existing = acc;
    _nameCtrl.text = acc.name;
    _openingCtrl.text = acc.openingBalance.toString();
    _type = acc.type;
    setState(() {});
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _openingCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(accountRepositoryProvider);
      final name = _nameCtrl.text.trim();
      final opening = double.tryParse(_openingCtrl.text.trim()) ?? 0.0;
      if (_isEditing) {
        await repo.update(
          _existing!.copyWith(
            name: name,
            type: _type,
            openingBalance: opening,
          ),
        );
      } else {
        await repo.insert(
          newAccountFrom(
            name: name,
            type: _type,
            openingBalance: opening,
          ),
        );
      }
      if (mounted) {
        ref.invalidate(accountListProvider);
        ref.invalidate(budgetOverviewProvider);
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorWithMessage('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context)!;
    final count = await ref
        .read(accountRepositoryProvider)
        .usageCount(widget.accountId!);
    if (count > 0) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.accountDeleteBlockedTitle),
          content: Text(l10n.accountDeleteBlockedBody(count)),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.commonOk),
            ),
          ],
        ),
      );
      return;
    }
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.accountDeleteConfirmTitle),
        content: Text(l10n.accountDeleteConfirmBody(_existing!.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.accountDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(accountRepositoryProvider).delete(widget.accountId!);
    if (mounted) {
      ref.invalidate(accountListProvider);
      ref.invalidate(budgetOverviewProvider);
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final base = ref.watch(settingsProvider).baseCurrency;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? l10n.accountFormEditTitle : l10n.accountFormNewTitle,
        ),
        actions: [
          if (_isEditing)
            IconButton(
              tooltip: l10n.accountDelete,
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
            Text(
              l10n.accountFormIntro,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameCtrl,
              autofocus: true,
              decoration: InputDecoration(labelText: l10n.accountFormNameLabel),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.accountFormNameRequired : null,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            Text(l10n.accountFormTypeLabel, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AccountType.values.map((type) {
                final selected = type == _type;
                return FilterChip(
                  selected: selected,
                  label: Text(accountTypeLabel(l10n, type)),
                  avatar: Icon(accountTypeIcon(type), size: 18),
                  onSelected: (_) => setState(() => _type = type),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _openingCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l10n.accountFormOpeningLabel,
                suffixText: base,
                helperText: l10n.accountFormOpeningHelper,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? l10n.commonSaving : l10n.commonSave),
            ),
          ],
        ),
      ),
    );
  }
}
