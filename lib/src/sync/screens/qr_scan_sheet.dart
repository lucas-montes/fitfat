import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../l10n/app_localizations.dart';

Future<({String url, String apiKey})?> showQrScanSheet(
  BuildContext context,
) async {
  return showModalBottomSheet<({String url, String apiKey})>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _QrScanSheet(),
  );
}

final class _QrScanSheet extends StatefulWidget {
  const _QrScanSheet();
  @override
  State<_QrScanSheet> createState() => _QrScanSheetState();
}

final class _QrScanSheetState extends State<_QrScanSheet> {
  final _controller = MobileScannerController();
  bool _handled = false;
  String? _error;

  static const _payloadShape = '{"url","apiKey","version":1}';

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;
    final parsed = _parsePayload(raw);
    if (parsed == null) {
      setState(
        () =>
            _error = AppLocalizations.of(context)!.syncQrInvalid(_payloadShape),
      );
      return;
    }
    _handled = true;
    Navigator.of(context).pop(parsed);
  }

  static ({String url, String apiKey})? _parsePayload(String raw) {
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final url = data['url'] as String?;
      final apiKey = data['apiKey'] as String?;
      final version = data['version'];
      if (url == null || apiKey == null || version != 1) return null;
      final uri = Uri.tryParse(url);
      if (uri == null || !(uri.isScheme('http') || uri.isScheme('https')))
        return null;
      if (apiKey.isEmpty) return null;
      return (url: url, apiKey: apiKey);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      expand: false,
      builder: (_, ctrl) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  AppLocalizations.of(context)!.syncScanQr,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.flash_on),
                  onPressed: () => _controller.toggleTorch(),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: MobileScanner(
                controller: _controller,
                onDetect: _onDetect,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              AppLocalizations.of(context)!.syncQrHint(_payloadShape),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
