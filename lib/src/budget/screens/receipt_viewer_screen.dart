import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import '../../ui/widgets/top_banner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../settings/providers/settings.dart';
import '../format.dart' as bf;
import '../models/receipt.dart';
import '../providers/receipts.dart';
import '../providers/services.dart';

/// Receipt detail: image, upload status, parsed OCR data, and the action to
/// upload it (if pending).
final class ReceiptViewerScreen extends ConsumerWidget {
  final String receiptId;

  const ReceiptViewerScreen({super.key, required this.receiptId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final receiptAsync = ref.watch(receiptByIdProvider(receiptId));
    // Retry this receipt if its upload/parse never finished.
    ref.watch(receiptResumeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.receiptAppBar),
        actions: [
          IconButton(
            tooltip: l10n.commonDelete,
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _delete(context, ref),
          ),
        ],
      ),
      body: receiptAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.errorWithMessage('$e'))),
        data: (receipt) {
          if (receipt == null) {
            return Center(child: Text(l10n.receiptNotFound));
          }
          final base = ref.watch(settingsProvider).baseCurrency;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(receipt.localPath),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      const Center(child: Icon(Icons.receipt_long, size: 80)),
                ),
              ),
              const SizedBox(height: 16),
              _StatusRow(receipt: receipt),
              const SizedBox(height: 12),
              // While the server-side parse is running, show progress instead of
              // offering to re-upload an image that is already there.
              if (receipt.status == ReceiptStatus.parsing) ...[
                Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      l10n.receiptParsing,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ] else if (!receipt.parsed ||
                  receipt.status == ReceiptStatus.local ||
                  receipt.status == ReceiptStatus.error)
                FilledButton.icon(
                  onPressed: () => _upload(context, ref, receipt),
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: Text(l10n.receiptUpload),
                ),
              if (receipt.parsed) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.receiptParsedData,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _ParsedData(json: receipt.parsedJson, base: base),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _upload(
    BuildContext context,
    WidgetRef ref,
    Receipt receipt,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref.read(budgetSyncServiceProvider).uploadAndParse(receipt.id);
      // The server parsed it and the phone has forgotten it: nothing left to
      // show here.
      if (context.mounted) {
        ref.invalidate(receiptListProvider);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
        showTopBanner(context, message: l10n.errorWithMessage('$e'));
      }
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.receiptDeleteConfirmTitle),
        content: Text(l10n.receiptDeleteConfirmBody),
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
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(receiptRepositoryProvider).delete(receiptId);
    if (context.mounted) {
      ref.invalidate(receiptListProvider);
      context.pop();
    }
  }
}

final class _StatusRow extends StatelessWidget {
  final Receipt receipt;

  const _StatusRow({required this.receipt});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final label = l10n.receiptStatusLabel(receipt.status.name);
    final color = switch (receipt.status) {
      ReceiptStatus.local => theme.colorScheme.outline,
      ReceiptStatus.uploading => theme.colorScheme.primary,
      ReceiptStatus.parsing => theme.colorScheme.primary,
      ReceiptStatus.uploaded => Colors.green,
      ReceiptStatus.error => theme.colorScheme.error,
    };
    return Row(
      children: [
        Icon(Icons.circle, size: 12, color: color),
        const SizedBox(width: 8),
        Text(label, style: theme.textTheme.titleMedium),
        if (receipt.remotePath != null) ...[
          const Spacer(),
          Expanded(
            child: Text(
              receipt.remotePath!,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ],
    );
  }
}

final class _ParsedData extends StatelessWidget {
  final String? json;
  final String base;

  const _ParsedData({required this.json, required this.base});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (json == null) return const SizedBox.shrink();
    final map = jsonDecode(json!) as Map<String, dynamic>;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: map.entries.map((e) {
            final value = e.value;
            final display = (e.key == 'total' && value is num)
                ? bf.formatMoney(value.toDouble(), base)
                : '$value';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      e.key,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(display, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
