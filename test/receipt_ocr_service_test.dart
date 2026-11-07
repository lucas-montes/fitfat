import 'dart:io';
import 'dart:typed_data';

import 'package:fitfat/src/budget/services/http_remote_receipt_ocr.dart';
import 'package:fitfat/src/network/api_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;

  HttpRemoteReceiptOcrService serviceWith(MockApiClient api) {
    return HttpRemoteReceiptOcrService(
      client: api,
      apiKey: 'test-key',
      baseEndpoint: '/receipt-pictures',
      // Keep the poll loop fast so tests don't sleep for seconds.
      pollInterval: const Duration(milliseconds: 5),
      parseTimeout: const Duration(seconds: 5),
    );
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('receipt_ocr_test');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<File> writeImage(String name, {String content = 'JPEGDATA'}) async {
    final file = File('${tempDir.path}/$name');
    await file.writeAsString(content);
    return file;
  }

  group('upload', () {
    test('posts multipart with receiptId and a named picture part', () async {
      final file = await writeImage('receipt.jpg');
      Map<String, dynamic>? seenBody;
      String? seenPath;

      final api = MockApiClient(
        onRequest: (method, path, body) async {
          expect(method, 'POST');
          seenPath = path;
          seenBody = body! as Map<String, dynamic>;
          return {'id': 'r-1', 'status': 'parsing'};
        },
      );

      final result = await serviceWith(api).upload('r-1', file.path);

      expect(seenPath, '/receipt-pictures/upload');
      expect(result.remotePath, 'r-1');

      final fields = seenBody!['fields'] as Map<String, dynamic>;
      expect(fields['receiptId'], 'r-1');

      // The server's parser matches on the `picture` field name, and axum needs
      // a filename to treat the part as a file rather than text.
      final files = seenBody!['files'] as Map<String, dynamic>;
      expect(files.keys, contains('picture'));
      final part = files['picture'] as Map<String, dynamic>;
      expect(part['filename'], 'receipt.jpg');
      expect(part['contentType'], 'image/jpeg');
      expect(part['length'], 'JPEGDATA'.length);
    });

    test('falls back to the local id when the response has no id', () async {
      final file = await writeImage('receipt.png');
      final api = MockApiClient(onRequest: (_, __, ___) async => <String, dynamic>{});

      final result = await serviceWith(api).upload('r-local', file.path);
      expect(result.remotePath, 'r-local');
    });

    test('throws when the image is missing on disk', () async {
      final api = MockApiClient(
        onRequest: (_, __, ___) async => fail('should not reach the server'),
      );

      await expectLater(
        serviceWith(api).upload('r-1', '${tempDir.path}/nope.jpg'),
        throwsA(isA<ReceiptOcrException>()),
      );
    });
  });

  group('fetchParse', () {
    test('polls until the parse is ready and returns the receipt map', () async {
      var calls = 0;
      final api = MockApiClient(
        onRequest: (method, path, body) async {
          expect(method, 'GET');
          expect(path, '/receipt-pictures/r-9/parse');
          calls++;
          return switch (calls) {
            1 => {'id': 'r-9', 'status': 'pending', 'parsed': null},
            2 => {'id': 'r-9', 'status': 'parsing', 'parsed': null},
            _ => {
              'id': 'r-9',
              'status': 'parsed',
              'parsed': {
                'merchant': 'Carrefour',
                'date': '2026-08-15 14:30:00',
                'total': 42.75,
                'currency': 'EUR',
                'items': [
                  {'name': 'Milk', 'price': 1.2, 'currency': 'EUR'},
                ],
                'discounts': <dynamic>[],
              },
            },
          };
        },
      );

      final result = await serviceWith(api).fetchParse('r-9');

      expect(calls, 3);
      // Keys are exactly what BudgetSyncService._createDraftFromParsed reads.
      expect(result.data['merchant'], 'Carrefour');
      expect(result.data['total'], 42.75);
      expect(result.data['currency'], 'EUR');
      expect(result.data['date'], '2026-08-15 14:30:00');
      expect((result.data['items'] as List).length, 1);
      expect(result.data.containsKey('store'), isFalse);
      expect(result.data.containsKey('products'), isFalse);
    });

    test('returns immediately when already parsed', () async {
      var calls = 0;
      final api = MockApiClient(
        onRequest: (_, __, ___) async {
          calls++;
          return {
            'status': 'parsed',
            'parsed': {'merchant': 'Aldi', 'total': 1.0, 'currency': 'EUR'},
          };
        },
      );

      final result = await serviceWith(api).fetchParse('r-1');
      expect(calls, 1);
      expect(result.data['merchant'], 'Aldi');
    });

    test('surfaces the server error message', () async {
      final api = MockApiClient(
        onRequest: (_, __, ___) async => {
          'status': 'error',
          'error': 'model returned no content',
        },
      );

      await expectLater(
        serviceWith(api).fetchParse('r-1'),
        throwsA(
          isA<ReceiptOcrException>().having(
            (e) => e.message,
            'message',
            contains('model returned no content'),
          ),
        ),
      );
    });

    test('gives up after parseTimeout instead of polling forever', () async {
      final api = MockApiClient(
        onRequest: (_, __, ___) async => {'status': 'parsing', 'parsed': null},
      );

      final service = HttpRemoteReceiptOcrService(
        client: api,
        apiKey: 'k',
        baseEndpoint: '/receipt-pictures',
        pollInterval: const Duration(milliseconds: 5),
        parseTimeout: const Duration(milliseconds: 60),
      );

      await expectLater(
        service.fetchParse('r-1'),
        throwsA(
          isA<ReceiptOcrException>().having(
            (e) => e.message,
            'message',
            contains('timed out'),
          ),
        ),
      );
    });

    test('rejects an unknown status rather than looping', () async {
      final api = MockApiClient(
        onRequest: (_, __, ___) async => {'status': 'banana'},
      );

      await expectLater(
        serviceWith(api).fetchParse('r-1'),
        throwsA(
          isA<ReceiptOcrException>().having(
            (e) => e.message,
            'message',
            contains('banana'),
          ),
        ),
      );
    });

    test('rejects a parsed response carrying no data', () async {
      final api = MockApiClient(
        onRequest: (_, __, ___) async => {'status': 'parsed', 'parsed': null},
      );

      await expectLater(
        serviceWith(api).fetchParse('r-1'),
        throwsA(isA<ReceiptOcrException>()),
      );
    });
  });

  group('contentTypeForExtension', () {
    test('maps known image extensions', () {
      expect(contentTypeForExtension('a.jpg'), 'image/jpeg');
      expect(contentTypeForExtension('a.JPEG'), 'image/jpeg');
      expect(contentTypeForExtension('a.png'), 'image/png');
      expect(contentTypeForExtension('a.webp'), 'image/webp');
      expect(contentTypeForExtension('a.heic'), 'image/heic');
    });

    test('falls back for unknown or absent extensions', () {
      expect(contentTypeForExtension('a.xyz'), 'application/octet-stream');
      expect(contentTypeForExtension('noextension'), isNull);
      expect(contentTypeForExtension('trailing.'), isNull);
    });
  });

  group('MultipartFilePart', () {
    test('fromFilename derives the content type', () {
      final part = MultipartFilePart.fromFilename(
        'receipt.png',
        Uint8List.fromList([1, 2, 3]),
      );
      expect(part.filename, 'receipt.png');
      expect(part.contentType, 'image/png');
      expect(part.bytes.length, 3);
    });
  });
}