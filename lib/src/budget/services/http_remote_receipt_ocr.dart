import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../network/api_client.dart';
import 'remote_receipt_ocr.dart';

/// Thrown when a receipt cannot be sent. [message] is safe to surface in the
/// UI; it carries the server's `error` field when one was provided.
class ReceiptOcrException implements Exception {
  const ReceiptOcrException(this.message);

  final String message;

  @override
  String toString() => 'ReceiptOcrException: $message';
}

/// Real backend: uploads the receipt image to the sync server, which reads and
/// matches it in the background. The phone does not wait for that.
///
/// Endpoint layout, derived from the configured `/receipt-pictures` base:
/// ```
/// POST /receipt-pictures/upload        multipart: receiptId, picture -> 202
/// ```
final class HttpRemoteReceiptOcrService implements RemoteReceiptOcrService {
  HttpRemoteReceiptOcrService({
    required ApiClient client,
    required String apiKey,
    required this.baseEndpoint,
    this.requestTimeout = const Duration(seconds: 15),
  }) : _client = client,
       _apiKey = apiKey;

  final ApiClient _client;
  final String _apiKey;

  /// Configured receipts base path, e.g. `/receipt-pictures`.
  final String baseEndpoint;

  /// Bounds each individual HTTP call.
  final Duration requestTimeout;

  @override
  Future<ReceiptUploadResult> upload(String receiptId, String localPath) async {
    final file = File(localPath);
    if (!await file.exists()) {
      throw ReceiptOcrException('receipt image missing at $localPath');
    }
    final bytes = await file.readAsBytes();
    final filename = p.basename(localPath);

    final response = await _client.postMultipart(
      '$baseEndpoint/upload',
      fields: {'receiptId': receiptId},
      files: {'picture': MultipartFilePart.fromFilename(filename, bytes)},
      headers: authHeaders(_apiKey),
    );

    final map = _asMap(response);
    // The server echoes back the id it stored; fall back to ours if the
    // response shape is unexpected rather than losing the link.
    final id = map?['id'] is String ? map!['id'] as String : receiptId;
    final remotePath = map?['remotePath'] is String
        ? map!['remotePath'] as String
        : id;
    return ReceiptUploadResult(remotePath);
  }

  static Map<String, dynamic>? _asMap(Object? value) =>
      value is Map ? value.cast<String, dynamic>() : null;
}
