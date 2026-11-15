import 'dart:io';

// `Value` is needed for the Drift companions; drift's own `isNull`/`isNotNull`
// would shadow the matcher of the same name.
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:fitfat/src/budget/models/receipt.dart';
import 'package:fitfat/src/budget/services/budget_sync.dart';
import 'package:fitfat/src/budget/services/remote_receipt_ocr.dart';
import 'package:fitfat/src/database/app_database.dart' as db;
import 'package:flutter_test/flutter_test.dart';

/// Scriptable stand-in for the server, recording the lifecycle as it goes.
final class _FakeOcrService implements RemoteReceiptOcrService {
  _FakeOcrService({this.failUpload = false, this.failParse = false});

  final bool failUpload;
  final bool failParse;

  final List<String> uploadIds = [];
  final List<String> parseIds = [];

  @override
  Future<ReceiptUploadResult> upload(String receiptId, String localPath) async {
    uploadIds.add(receiptId);
    if (failUpload) throw Exception('upload boom');
    return ReceiptUploadResult(receiptId);
  }

  @override
  Future<ReceiptParseResult> fetchParse(String remoteId) async {
    parseIds.add(remoteId);
    if (failParse) throw Exception('parse boom');
    return ReceiptParseResult({
      'merchant': 'Carrefour',
      'date': '2026-08-15 14:30:00',
      'total': 42.75,
      'currency': 'EUR',
      'items': [
        {'name': 'Milk', 'price': 1.2, 'currency': 'EUR'},
      ],
      'discounts': <Object?>[],
    });
  }
}

void main() {
  late db.AppDatabase database;
  late Directory tempDir;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    tempDir = Directory.systemTemp.createTempSync('budget_sync_test');
  });

  tearDown(() async {
    await database.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  String writeImage() {
    final f = File('${tempDir.path}/r.png')..writeAsStringSync('PNG');
    return f.path;
  }

  Future<void> insertReceipt(Receipt receipt) async {
    await database.into(database.receipts).insert(
      db.ReceiptsCompanion.insert(
        id: receipt.id,
        localPath: receipt.localPath,
        remotePath: Value(receipt.remotePath),
        uploadStatus: Value(receipt.status.code),
        parsed: Value(receipt.parsed),
        parsedJson: Value(receipt.parsedJson),
        transactionId: Value(receipt.transactionId),
        createdAt: receipt.createdAt.millisecondsSinceEpoch,
      ),
    );
  }

  // Drift generates a row class also called `Receipt`, so the generated
  // classes are referenced through an explicit prefix.
  Future<db.Receipt> rowFor(String id) async {
    return (await (database.select(database.receipts)
              ..where((t) => t.id.equals(id)))
            .getSingle());
  }

  group('uploadAndParse', () {
    test('once the server has parsed it, the phone forgets the receipt', () async {
      final receipt = newReceipt(localPath: writeImage());
      await insertReceipt(receipt);
      final ocr = _FakeOcrService();

      await BudgetSyncService(database, ocr).uploadAndParse(receipt.id);

      // The receipt id is sent to the server so both sides agree on the row id.
      expect(ocr.uploadIds, [receipt.id]);
      expect(ocr.parseIds, [receipt.id]);

      // The server holds the picture and the parse; the phone keeps neither.
      // No row at all, not a tombstone: a tombstone is pushed, and would
      // delete the server's copy.
      expect(
        await (database.select(
          database.receipts,
        )..where((t) => t.id.equals(receipt.id))).get(),
        isEmpty,
      );
      expect(File(receipt.localPath).existsSync(), isFalse);
      // And no transaction is made from it.
      expect(await database.select(database.transactions).get(), isEmpty);
    });

    test('marks the row as error and rethrows when the upload fails', () async {
      final receipt = newReceipt(localPath: writeImage());
      await insertReceipt(receipt);

      await expectLater(
        BudgetSyncService(database, _FakeOcrService(failUpload: true))
            .uploadAndParse(receipt.id),
        throwsA(anything),
      );

      final row = await rowFor(receipt.id);
      expect(row.uploadStatus, ReceiptStatus.error.code);
      expect(row.parsed, isFalse);
      // A failed send keeps the picture, to be sent again.
      expect(File(receipt.localPath).existsSync(), isTrue);
    });

    test('marks the row as error when the parse fails', () async {
      final receipt = newReceipt(localPath: writeImage());
      await insertReceipt(receipt);

      await expectLater(
        BudgetSyncService(database, _FakeOcrService(failParse: true))
            .uploadAndParse(receipt.id),
        throwsA(anything),
      );

      final row = await rowFor(receipt.id);
      expect(row.uploadStatus, ReceiptStatus.error.code);
      expect(row.parsed, isFalse);
      // A failed send keeps the picture, to be sent again.
      expect(File(receipt.localPath).existsSync(), isTrue);
      expect(row.transactionId, isNull);
    });

    test('is a no-op for an unknown receipt id', () async {
      final ocr = _FakeOcrService();
      await BudgetSyncService(database, ocr).uploadAndParse('does-not-exist');
      expect(ocr.uploadIds, isEmpty);
    });
  });
}