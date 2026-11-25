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
      final api = MockApiClient(
        onRequest: (_, _, _) async => <String, dynamic>{},
      );

      final result = await serviceWith(api).upload('r-local', file.path);
      expect(result.remotePath, 'r-local');
    });

    test('throws when the image is missing on disk', () async {
      final api = MockApiClient(
        onRequest: (_, _, _) async => fail('should not reach the server'),
      );

      await expectLater(
        serviceWith(api).upload('r-1', '${tempDir.path}/nope.jpg'),
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
