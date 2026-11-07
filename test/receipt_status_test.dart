import 'package:fitfat/src/budget/models/receipt.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReceiptStatus', () {
    test('round-trips every code, including the original ones', () {
      // 0-3 predate the server-side parse pipeline and must keep their values,
      // since existing rows in the Drift table already store them.
      expect(ReceiptStatus.local.code, 0);
      expect(ReceiptStatus.uploading.code, 1);
      expect(ReceiptStatus.uploaded.code, 2);
      expect(ReceiptStatus.error.code, 3);
      expect(ReceiptStatus.parsing.code, 4);

      for (final status in ReceiptStatus.values) {
        expect(ReceiptStatus.fromCode(status.code), status);
      }
    });

    test('maps raw codes back to statuses', () {
      expect(ReceiptStatus.fromCode(0), ReceiptStatus.local);
      expect(ReceiptStatus.fromCode(1), ReceiptStatus.uploading);
      expect(ReceiptStatus.fromCode(2), ReceiptStatus.uploaded);
      expect(ReceiptStatus.fromCode(3), ReceiptStatus.error);
      expect(ReceiptStatus.fromCode(4), ReceiptStatus.parsing);
    });

    test('unknown codes fall back to local', () {
      expect(ReceiptStatus.fromCode(5), ReceiptStatus.local);
      expect(ReceiptStatus.fromCode(-1), ReceiptStatus.local);
      expect(ReceiptStatus.fromCode(999), ReceiptStatus.local);
    });

    test('isPending covers in-flight work only', () {
      expect(ReceiptStatus.uploading.isPending, isTrue);
      expect(ReceiptStatus.parsing.isPending, isTrue);
      expect(ReceiptStatus.local.isPending, isFalse);
      expect(ReceiptStatus.uploaded.isPending, isFalse);
      expect(ReceiptStatus.error.isPending, isFalse);
    });
  });

  group('newReceipt', () {
    test('starts local and unparsed', () {
      final receipt = newReceipt(localPath: '/tmp/a.jpg');
      expect(receipt.status, ReceiptStatus.local);
      expect(receipt.parsed, isFalse);
      expect(receipt.remotePath, isNull);
      expect(receipt.parsedJson, isNull);
      expect(receipt.transactionId, isNull);
      expect(receipt.localPath, '/tmp/a.jpg');
      expect(receipt.id, isNotEmpty);
    });
  });
}