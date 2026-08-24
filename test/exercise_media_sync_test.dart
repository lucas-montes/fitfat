import 'dart:io';
import 'dart:typed_data';

import 'package:fitfat/src/network/api_client.dart';
import 'package:fitfat/src/sync/exercise_media_sync.dart';
import 'package:fitfat/src/sync/exercise_sync_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late ExerciseMediaDownloader downloader;
  late MockApiClient api;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('exercise_media_test');
    api = MockApiClient();
    downloader = ExerciseMediaDownloader(api, mediaDir: () async => tempDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ExerciseMediaDownloader', () {
    test('localPath keys files by id and format', () async {
      final image = await downloader.localPath('id-1', ExerciseMediaKind.image);
      final video = await downloader.localPath('id-1', ExerciseMediaKind.video);
      expect(image.endsWith('/id-1.jpg'), isTrue);
      expect(video.endsWith('/id-1.mp4'), isTrue);
      expect(
        image.substring(0, image.length - '/id-1.jpg'.length),
        video.substring(0, video.length - '/id-1.mp4'.length),
      );
    });

    test('download writes bytes and returns the local path', () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4]);
      api = MockApiClient(
        onRequest: (method, path, body) async {
          expect(method, 'GET');
          expect(path, '/exercises/id-1.jpg');
          return bytes;
        },
      );
      downloader = ExerciseMediaDownloader(api, mediaDir: () async => tempDir);

      final path = await downloader.download(
        exerciseId: 'id-1',
        kind: ExerciseMediaKind.image,
        apiKey: 'key',
      );

      expect(path, isNotNull);
      expect(File(path!).readAsBytesSync(), bytes);
      expect(await downloader.exists('id-1', ExerciseMediaKind.image), isTrue);
    });

    test('download maps video requests to .mp4', () async {
      api = MockApiClient(
        onRequest: (method, path, body) async => Uint8List.fromList([9]),
      );
      downloader = ExerciseMediaDownloader(api, mediaDir: () async => tempDir);

      await downloader.download(
        exerciseId: 'id-1',
        kind: ExerciseMediaKind.video,
        apiKey: 'key',
      );

      expect(
        await File(
          await downloader.localPath('id-1', ExerciseMediaKind.video),
        ).exists(),
        isTrue,
      );
    });

    test('download returns null on 404 without writing a file', () async {
      api = MockApiClient(
        onRequest: (method, path, body) =>
            throw const ApiException(statusCode: 404, body: 'nope'),
      );
      downloader = ExerciseMediaDownloader(api, mediaDir: () async => tempDir);

      final path = await downloader.download(
        exerciseId: 'id-1',
        kind: ExerciseMediaKind.image,
        apiKey: 'key',
      );

      expect(path, isNull);
      expect(await downloader.exists('id-1', ExerciseMediaKind.image), isFalse);
    });

    test('download rethrows other HTTP failures', () async {
      api = MockApiClient(
        onRequest: (method, path, body) =>
            throw const ApiException(statusCode: 500, body: 'boom'),
      );
      downloader = ExerciseMediaDownloader(api, mediaDir: () async => tempDir);

      expect(
        () => downloader.download(
          exerciseId: 'id-1',
          kind: ExerciseMediaKind.image,
          apiKey: 'key',
        ),
        throwsA(isA<ApiException>()),
      );
    });

    test(
      'remove deletes an existing file and tolerates a missing one',
      () async {
        final path = await downloader.localPath(
          'id-1',
          ExerciseMediaKind.image,
        );
        await File(path).writeAsBytes([1]);

        await downloader.remove('id-1', ExerciseMediaKind.image);
        expect(await File(path).exists(), isFalse);

        // Removing again (file already gone) must not throw.
        await downloader.remove('id-1', ExerciseMediaKind.image);
      },
    );
  });

  group('ExerciseSyncClient.parseExercise', () {
    final serverTime = 1755850000000;

    Map<Object?, Object?> raw({
      String id = 'id-1',
      bool? hasImage,
      bool? hasVideo,
      String? imagePath,
      String? videoPath,
    }) => {
      'id': id,
      'name': 'Squat',
      'updated_at': 1755850000000,
      'hasImage': ?hasImage,
      'hasVideo': ?hasVideo,
      'imagePath': ?imagePath,
      'videoPath': ?videoPath,
    };

    test('parses media presence flags', () {
      final parsed = ExerciseSyncClient.parseExercise(
        raw(hasImage: true, hasVideo: false),
        serverTime,
      );
      expect(parsed, isNotNull);
      final (exercise, hasImage, hasVideo) = parsed!;
      expect(exercise.id, 'id-1');
      expect(hasImage, isTrue);
      expect(hasVideo, isFalse);
    });

    test('flags default to false when absent', () {
      final (_, hasImage, hasVideo) = ExerciseSyncClient.parseExercise(
        raw(),
        serverTime,
      )!;
      expect(hasImage, isFalse);
      expect(hasVideo, isFalse);
    });

    test('ignores media paths in the payload (client-local state)', () {
      final (exercise, _, _) = ExerciseSyncClient.parseExercise(
        raw(imagePath: '/srv/asset.jpg', videoPath: '/srv/asset.mp4'),
        serverTime,
      )!;
      expect(exercise.imagePath, isNull);
      expect(exercise.videoPath, isNull);
    });

    test('returns null without id or name', () {
      expect(
        ExerciseSyncClient.parseExercise({'name': 'x'}, serverTime),
        isNull,
      );
      expect(ExerciseSyncClient.parseExercise({'id': 'x'}, serverTime), isNull);
    });
  });
}
