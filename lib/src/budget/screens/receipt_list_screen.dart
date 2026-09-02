import 'dart:io';

import 'package:flutter/material.dart';
import '../../ui/widgets/top_banner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../l10n/app_localizations.dart';
import '../../settings/providers/settings.dart';
import '../models/receipt.dart';
import '../providers/fx_rates.dart';
import '../providers/receipts.dart';
import '../providers/services.dart';

/// Standalone receipt capture + gallery. Capturing uploads + parses the
/// receipt in the background and creates a draft expense from the result.
final class ReceiptListScreen extends ConsumerWidget {
  const ReceiptListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final receiptsAsync = ref.watch(receiptListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.receiptListAppBar)),
      floatingActionButton: FloatingActionButton(heroTag: null, 
        tooltip: l10n.receiptCapture,
        onPressed: () => _capture(context, ref),
        child: const Icon(Icons.add_a_photo_outlined),
      ),
      body: receiptsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.errorWithMessage('$e'))),
        data: (receipts) {
          if (receipts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.receiptEmptyBody, textAlign: TextAlign.center),
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: receipts.length,
            itemBuilder: (context, i) {
              final r = receipts[i];
              return _ReceiptCard(
                receipt: r,
                onTap: () => context.push('/budget/receipt/${r.id}'),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _capture(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(l10n.receiptTakePhoto),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.receiptPickGallery),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !context.mounted) return;

    final picked = await ImagePicker().pickImage(source: source);
    if (picked == null || !context.mounted) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final receiptsDir = Directory(p.join(dir.path, 'receipts'));
      await receiptsDir.create(recursive: true);
      final ext = p.extension(picked.path);
      final name = '${const Uuid().v7()}$ext';
      final saved = await File(
        picked.path,
      ).copy(p.join(receiptsDir.path, name));
      final receipt = newReceipt(localPath: saved.path);
      await ref.read(receiptRepositoryProvider).insert(receipt);

      final base = ref.read(settingsProvider).baseCurrency;
      final rates = Map<String, double>.from(
        ref.read(fxRatesProvider).value ?? {},
      );
      rates[base] = 1.0;
      () async {
        try {
          await ref
              .read(budgetSyncServiceProvider)
              .uploadAndParse(
                receipt.id,
                baseCurrency: base,
                ratesToBase: rates,
              );
          if (context.mounted) ref.invalidate(receiptListProvider);
        } catch (_) {}
      }();
      if (context.mounted) {
        ref.invalidate(receiptListProvider);
      }
    } catch (e) {
      if (context.mounted) {
        showTopBanner(context, message: l10n.errorWithMessage('$e'));
      }
    }
  }
}

final class _ReceiptCard extends StatelessWidget {
  final Receipt receipt;
  final VoidCallback onTap;

  const _ReceiptCard({required this.receipt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Image.file(
                File(receipt.localPath),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    const Center(child: Icon(Icons.receipt_long_outlined)),
              ),
            ),
            Container(
              color: theme.colorScheme.surfaceContainerHighest,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.receiptStatusShort(receipt.status.name),
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (receipt.parsed)
                    Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
