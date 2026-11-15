import 'dart:async';

/// Result of uploading a receipt image to the server.
final class ReceiptUploadResult {
  final String remotePath;
  const ReceiptUploadResult(this.remotePath);
}

/// Abstraction over the server's receipt intake.
///
/// The phone only sends a picture. The server reads it, matches it and keeps
/// it; the phone never asks for the reading. Two implementations exist:
/// [HttpRemoteReceiptOcrService] (the real backend) and
/// [MockRemoteReceiptOcrService] (offline/dev/tests). Wired in via
/// `remoteReceiptOcrProvider`.
abstract class RemoteReceiptOcrService {
  /// Uploads the image at [localPath] for the receipt [receiptId] and returns
  /// its server-side identifier, once the server has accepted it.
  ///
  /// [receiptId] is sent so the row id stays identical on both sides.
  Future<ReceiptUploadResult> upload(String receiptId, String localPath);
}

/// Local mock that simulates the server accepting an upload after a delay.
final class MockRemoteReceiptOcrService implements RemoteReceiptOcrService {
  @override
  Future<ReceiptUploadResult> upload(String receiptId, String localPath) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final name = localPath.split('/').last;
    return ReceiptUploadResult(receiptId.isEmpty ? 'remote://ocr/$name' : receiptId);
  }
}
