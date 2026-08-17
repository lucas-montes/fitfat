import 'dart:io';

import 'package:flutter/material.dart';
import '../../ui/widgets/top_banner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../l10n/app_localizations.dart';
import '../../settings/providers/settings.dart';
import '../format.dart' as bf;
import '../models/receipt.dart';
import '../models/transaction.dart';
import '../providers/accounts.dart';
import '../providers/budget_overview.dart';
import '../providers/fx_rates.dart';
import '../providers/receipts.dart';
import '../providers/services.dart';
import '../providers/transactions.dart';
import '../services/currency.dart';

const _commonCurrencies = [
  'USD',
  'EUR',
  'GBP',
  'JPY',
  'CAD',
  'CHF',
  'AUD',
];

/// Create / edit a transaction (income, expense, or transfer). Also supports
/// editing a draft produced from a parsed receipt, and attaching a receipt
/// image (camera or gallery) which is uploaded + parsed in the background.
final class TransactionFormScreen extends ConsumerStatefulWidget {
  final String? transactionId;
  final String? initialType;
  final String? initialAccountId;

  const TransactionFormScreen({
    super.key,
    this.transactionId,
    this.initialType,
    this.initialAccountId,
  });

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

final class _TransactionFormScreenState
    extends ConsumerState<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _picker = ImagePicker();

  TransactionType _type = TransactionType.expense;
  String _currency = 'USD';
  String? _accountId;
  String? _toAccountId;
  DateTime _date = DateTime.now();
  String? _receiptId;
  String? _receiptLocalPath;
  bool _saving = false;
  bool _isDraft = false;

  bool get _isEditing => widget.transactionId != null;

  @override
  void initState() {
    super.initState();
    _type = TransactionType.fromName(widget.initialType);
    _currency = ref.read(settingsProvider).baseCurrency;
    _accountId = widget.initialAccountId;
    if (_isEditing) _loadExisting();
  }

  Future<void> _loadExisting() async {
    final txn = await ref
        .read(transactionRepositoryProvider)
        .getById(widget.transactionId!);
    if (txn == null || !mounted) return;
    _type = txn.type;
    _amountCtrl.text = txn.amount.toString();
    _categoryCtrl.text = txn.category ?? '';
    _noteCtrl.text = txn.note ?? '';
    _currency = txn.currencyCode;
    _accountId = txn.accountId;
    _toAccountId = txn.toAccountId;
    _date = txn.date;
    _receiptId = txn.receiptId;
    _isDraft = txn.isDraft;
    if (_receiptId != null) {
      final receipt = await ref
          .read(receiptRepositoryProvider)
          .getById(_receiptId!);
      _receiptLocalPath = receipt?.localPath;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _categoryCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Map<String, double> _rates() {
    final base = ref.read(settingsProvider).baseCurrency;
    final map = Map<String, double>.from(
      ref.read(fxRatesProvider).value ?? {},
    );
    map[base] = 1.0;
    return map;
  }

  double get _convertedAmount {
    final amount = double.tryParse(_amountCtrl.text) ?? 0.0;
    final base = ref.read(settingsProvider).baseCurrency;
    final (converted, _) = convertToBase(amount, _currency, base, _rates());
    return converted;
  }

  Future<void> _pickImage(ImageSource source) async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await _picker.pickImage(source: source);
    if (picked == null || !mounted) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final receiptsDir = Directory(p.join(dir.path, 'receipts'));
      await receiptsDir.create(recursive: true);
      final ext = p.extension(picked.path);
      final name = '${const Uuid().v7()}$ext';
      final saved = await File(picked.path).copy(
        p.join(receiptsDir.path, name),
      );
      final receipt = newReceipt(localPath: saved.path);
      await ref.read(receiptRepositoryProvider).insert(receipt);
      setState(() {
        _receiptId = receipt.id;
        _receiptLocalPath = receipt.localPath;
      });
      if (!mounted) return;
      // Best-effort background upload + parse.
      final base = ref.read(settingsProvider).baseCurrency;
      () async {
        try {
          await ref.read(budgetSyncServiceProvider).uploadAndParse(
                receipt.id,
                baseCurrency: base,
                ratesToBase: _rates(),
              );
          if (mounted) ref.invalidate(receiptListProvider);
        } catch (_) {}
      }();
      showTopBanner(context, message: l10n.receiptUploadStarted);
    } catch (e) {
      if (mounted) {
        showTopBanner(context, message: l10n.errorWithMessage('$e'));
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;
    final base = ref.read(settingsProvider).baseCurrency;
    final amount = double.tryParse(_amountCtrl.text) ?? 0.0;
    if (amount <= 0) {
      showTopBanner(context, message: l10n.transactionAmountPositive);
      return;
    }
    if (_type != TransactionType.transfer && _accountId == null) {
      showTopBanner(context, message: l10n.transactionAccountRequired);
      return;
    }
    if (_type == TransactionType.transfer) {
      if (_accountId == null || _toAccountId == null) {
        showTopBanner(context, message: l10n.transactionTransferAccountsRequired);
        return;
      }
      if (_accountId == _toAccountId) {
        showTopBanner(context, message: l10n.transactionTransferSameAccount);
        return;
      }
    }

    setState(() => _saving = true);
    try {
      final rates = _rates();
      final (amountBase, rateUsed) = convertToBase(amount, _currency, base, rates);
      final repo = ref.read(transactionRepositoryProvider);
      final category = _categoryCtrl.text.trim();
      final note = _noteCtrl.text.trim();

      if (_isEditing) {
        final existing = await repo.getById(widget.transactionId!);
        if (existing == null) {
          if (mounted) Navigator.of(context).pop(true);
          return;
        }
        await repo.update(
          existing.copyWith(
            type: _type,
            amount: amount,
            currencyCode: _currency,
            amountBase: amountBase,
            rateUsed: rateUsed,
            accountId: _accountId,
            toAccountId: _type == TransactionType.transfer ? _toAccountId : null,
            clearCategory: category.isEmpty,
            category: category.isEmpty ? null : category,
            date: _date,
            note: note.isEmpty ? null : note,
            clearNote: note.isEmpty,
            receiptId: _receiptId,
            clearReceiptId: _receiptId == null,
            isDraft: false,
          ),
        );
      } else {
        final txn = newTransaction(
          type: _type,
          amount: amount,
          currencyCode: _currency,
          amountBase: amountBase,
          rateUsed: rateUsed,
          accountId: _accountId,
          toAccountId: _type == TransactionType.transfer ? _toAccountId : null,
          category: category.isEmpty ? null : category,
          date: _date,
          note: note.isEmpty ? null : note,
          receiptId: _receiptId,
          isDraft: false,
        );
        await repo.insert(txn);
      }
      if (mounted) {
        ref.invalidate(transactionListProvider);
        ref.invalidate(budgetOverviewProvider);
        ref.invalidate(recentTransactionsProvider);
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        showTopBanner(context, message: l10n.errorWithMessage('$e'));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final base = ref.watch(settingsProvider).baseCurrency;
    final accountsAsync = ref.watch(accountListProvider);
    final accounts = accountsAsync.value ?? [];

    final currencyOptions = {
      base,
      ..._commonCurrencies,
      ..._rates().keys,
    }.toList()
      ..sort();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing
              ? l10n.transactionFormEditTitle
              : switch (_type) {
                  TransactionType.income => l10n.transactionFormNewIncomeTitle,
                  TransactionType.transfer =>
                    l10n.transactionFormTransferTitle,
                  _ => l10n.transactionFormNewExpenseTitle,
                },
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<TransactionType>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: TransactionType.expense,
                  label: Text(l10n.transactionTypeExpense),
                  icon: const Icon(Icons.arrow_upward),
                ),
                ButtonSegment(
                  value: TransactionType.income,
                  label: Text(l10n.transactionTypeIncome),
                  icon: const Icon(Icons.arrow_downward),
                ),
                ButtonSegment(
                  value: TransactionType.transfer,
                  label: Text(l10n.transactionTypeTransfer),
                  icon: const Icon(Icons.swap_horiz),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l10n.transactionAmountLabel,
              ),
              onChanged: (_) => setState(() {}),
              validator: (v) =>
                  (v == null || v.trim().isEmpty || double.tryParse(v) == null)
                      ? l10n.transactionAmountInvalid
                      : null,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.transactionConvertedLabel(
                bf.formatMoney(_convertedAmount, base),
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: ValueKey(_currency),
              initialValue: _currency,
              decoration: InputDecoration(
                labelText: l10n.transactionCurrencyLabel,
              ),
              items: currencyOptions
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _currency = v!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: ValueKey(_accountId),
              initialValue: _accountId,
              decoration: InputDecoration(
                labelText: l10n.transactionAccountLabel,
              ),
              items: accounts
                  .map(
                    (a) => DropdownMenuItem(value: a.id, child: Text(a.name)),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _accountId = v),
            ),
            if (_type == TransactionType.transfer) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: ValueKey(_toAccountId),
                initialValue: _toAccountId,
                decoration: InputDecoration(
                  labelText: l10n.transactionToAccountLabel,
                ),
                items: accounts
                    .map(
                      (a) => DropdownMenuItem(value: a.id, child: Text(a.name)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _toAccountId = v),
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _categoryCtrl,
              decoration: InputDecoration(
                labelText: l10n.transactionCategoryLabel,
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.transactionDateLabel),
              subtitle: Text(
                '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _noteCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.transactionNoteLabel,
              ),
            ),
            const SizedBox(height: 16),
            _ReceiptPicker(
              localPath: _receiptLocalPath,
              onCamera: () => _pickImage(ImageSource.camera),
              onGallery: () => _pickImage(ImageSource.gallery),
            ),
            if (_isDraft) ...[
              const SizedBox(height: 8),
              Text(
                l10n.transactionDraftHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
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

final class _ReceiptPicker extends StatelessWidget {
  final String? localPath;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  const _ReceiptPicker({
    required this.localPath,
    required this.onCamera,
    required this.onGallery,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onCamera,
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text(l10n.receiptTakePhoto),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onGallery,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(l10n.receiptPickGallery),
              ),
            ),
          ],
        ),
        if (localPath != null) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(localPath!),
              height: 160,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ],
    );
  }
}
