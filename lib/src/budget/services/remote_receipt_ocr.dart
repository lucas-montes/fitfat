import 'dart:async';
import 'dart:math';

/// Result of uploading a receipt image to the remote OCR service.
final class ReceiptUploadResult {
  final String remotePath;
  const ReceiptUploadResult(this.remotePath);
}

/// Parsed receipt fields returned by the remote OCR service.
final class ReceiptParseResult {
  final Map<String, Object?> data;
  const ReceiptParseResult(this.data);
}

/// Abstraction over a remote receipt-OCR backend. The app uploads a local
/// image and later fetches the parsed result; the actual OCR runs server-side
/// (never on device). Swapped for a real implementation later via the provider.
abstract class RemoteReceiptOcrService {
  /// Uploads the image at [localPath] and returns its remote identifier/path.
  Future<ReceiptUploadResult> upload(String localPath);

  /// Fetches the parsed result for a previously uploaded receipt.
  Future<ReceiptParseResult> fetchParse(String remoteId);
}

/// Local mock that simulates a remote OCR backend: a short delay, then a
/// canned parsed receipt (merchant, total, date, currency, item count).
final class MockRemoteReceiptOcrService implements RemoteReceiptOcrService {
  final Random _random = Random();

  @override
  Future<ReceiptUploadResult> upload(String localPath) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final name = localPath.split('/').last;
    return ReceiptUploadResult('remote://ocr/$name');
  }

  @override
  Future<ReceiptParseResult> fetchParse(String remoteId) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    final merchants = const ['Walmart', 'Carrefour', 'Amazon', 'Starbucks'];
    final currencies = const ['USD', 'EUR', 'GBP'];
    final merchant = merchants[_random.nextInt(merchants.length)];
    final currency = currencies[_random.nextInt(currencies.length)];
    final total = double.parse(
      (5 + _random.nextDouble() * 95).toStringAsFixed(2),
    );
    final day = 1 + _random.nextInt(27);
    return ReceiptParseResult({
      'merchant': merchant,
      'total': total,
      'currency': currency,
      'date': '2026-08-${day.toString().padLeft(2, '0')}',
      'items': 1 + _random.nextInt(5),
    });
  }
}
