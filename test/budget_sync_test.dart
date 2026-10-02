import 'dart:io';

// `Value` is needed for the Drift companions; drift's own `isNull`/`isNotNull`
// would shadow the matcher of the same name.
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:fitfat/src/budget/models/receipt.dart';
import 'package:fitfat/src/budget/models/transaction.dart';
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

  Future<db.Transaction?> txnFor(String id) async {
    return (await (database.select(database.transactions)
              ..where((t) => t.id.equals(id)))
        .getSingleOrNull());
  }

  group('uploadAndParse', () {
    test('stores the parse, links a draft, and lands on uploaded', () async {
      final receipt = newReceipt(localPath: writeImage());
      await insertReceipt(receipt);
      final ocr = _FakeOcrService();

      await BudgetSyncService(database, ocr).uploadAndParse(
        receipt.id,
        baseCurrency: 'EUR',
        ratesToBase: const {'EUR': 1.0},
      );

      // The receipt id is sent to the server so both sides agree on the row id.
      expect(ocr.uploadIds, [receipt.id]);
      expect(ocr.parseIds, [receipt.id]);

      final row = await rowFor(receipt.id);
      expect(row.parsed, isTrue);
      expect(row.uploadStatus, ReceiptStatus.uploaded.code);
      expect(row.remotePath, receipt.id);
      expect(row.parsedJson, contains('"merchant":"Carrefour"'));

      // A draft expense is created from the parsed fields.
      expect(row.transactionId, isNotNull);
      final txn = await txnFor(row.transactionId!);
      expect(txn, isNotNull);
      expect(txn!.type, TransactionType.expense.name);
      expect(txn.isDraft, isTrue);
      expect(txn.receiptId, receipt.id);
      expect(txn.category, 'Carrefour');
      expect(txn.currencyCode, 'EUR');
      expect(txn.amount, 42.75);
      expect(txn.accountId, isNull);
    });

    test('converts to the base currency using the supplied rates', () async {
      final receipt = newReceipt(localPath: writeImage());
      await insertReceipt(receipt);
      final ocr = _FakeOcrService();

      await BudgetSyncService(database, ocr).uploadAndParse(
        receipt.id,
        baseCurrency: 'EUR',
        ratesToBase: const {'EUR': 1.0, 'USD': 0.5},
      );

      final row = await rowFor(receipt.id);
      final txn = await txnFor(row.transactionId!);
      expect(txn!.currencyCode, 'EUR');
      expect(txn.amountBase, closeTo(42.75, 0.001));
    });

    test('does not create a second draft on re-upload', () async {
      final receipt = newReceipt(localPath: writeImage());
      await insertReceipt(receipt);
      final service = BudgetSyncService(database, _FakeOcrService());

      await service.uploadAndParse(
        receipt.id,
        baseCurrency: 'EUR',
        ratesToBase: const {'EUR': 1.0},
      );
      final firstTxnId = (await rowFor(receipt.id)).transactionId;

      await service.uploadAndParse(
        receipt.id,
        baseCurrency: 'EUR',
        ratesToBase: const {'EUR': 1.0},
      );
      final secondTxnId = (await rowFor(receipt.id)).transactionId;

      expect(secondTxnId, firstTxnId);
      final count = await database.select(database.transactions).get();
      expect(count.length, 1);
    });

    test('marks the row as error and rethrows when the upload fails', () async {
      final receipt = newReceipt(localPath: writeImage());
      await insertReceipt(receipt);

      await expectLater(
        BudgetSyncService(database, _FakeOcrService(failUpload: true))
            .uploadAndParse(
              receipt.id,
              baseCurrency: 'EUR',
              ratesToBase: const {'EUR': 1.0},
            ),
        throwsA(anything),
      );

      final row = await rowFor(receipt.id);
      expect(row.uploadStatus, ReceiptStatus.error.code);
      expect(row.parsed, isFalse);
    });

    test('marks the row as error when the parse fails', () async {
      final receipt = newReceipt(localPath: writeImage());
      await insertReceipt(receipt);

      await expectLater(
        BudgetSyncService(database, _FakeOcrService(failParse: true))
            .uploadAndParse(
              receipt.id,
              baseCurrency: 'EUR',
              ratesToBase: const {'EUR': 1.0},
            ),
        throwsA(anything),
      );

      final row = await rowFor(receipt.id);
      expect(row.uploadStatus, ReceiptStatus.error.code);
      expect(row.parsed, isFalse);
      expect(row.transactionId, isNull);
    });

    test('is a no-op for an unknown receipt id', () async {
      final ocr = _FakeOcrService();
      await BudgetSyncService(database, ocr).uploadAndParse(
        'does-not-exist',
        baseCurrency: 'EUR',
        ratesToBase: const {'EUR': 1.0},
      );
      expect(ocr.uploadIds, isEmpty);
    });
  });
}