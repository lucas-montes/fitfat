import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:fitfat/src/database/app_database.dart';
import 'package:fitfat/src/diet/repositories/ingredient_repository.dart';
import 'package:fitfat/src/exercise/repositories/exercise_repository.dart';
import 'package:fitfat/src/network/api_client.dart';
import 'package:fitfat/src/sync/catalog_sync_client.dart';
import 'package:fitfat/src/sync/repositories/catalog_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late CatalogSyncClient catalog;

  Object? script(String method, String path, Object? body) {
    if (path == '/exercises/catalog') {
      return {
        'server_time': 1000,
        'items': [
          {'id': 'e1', 'name': 'Squat'},
          {'id': 'e2', 'name': 'Bench'},
        ],
      };
    }
    if (path == '/ingredients/catalog') {
      return {
        'server_time': 1000,
        'items': [
          {'id': 'i1', 'name': 'Oats', 'barcode': '123'},
        ],
      };
    }
    if (path == '/exercises/item/e1') {
      return {
        'id': 'e1',
        'name': 'Squat',
        'exerciseType': 'weightlifting',
        'updated_at': 1000,
        'hasImage': false,
        'hasVideo': false,
      };
    }
    if (path == '/exercises/item/e2') {
      return {
        'id': 'e2',
        'name': 'Bench',
        'exerciseType': 'weightlifting',
        'updated_at': 1000,
        'hasImage': false,
        'hasVideo': false,
      };
    }
    if (path == '/ingredients/item/i1') {
      return {
        'id': 'i1',
        'name': 'Oats',
        'caloriesPer100g': 100,
        'proteinPer100g': 10,
        'carbsPer100g': 20,
        'fatPer100g': 5,
        'barcode': '123',
        'updated_at': 1000,
        'pictures': [
          {
            'id': 'p1',
            'ingredientId': 'i1',
            'imagePath': '/tmp/a.jpg',
            'sortOrder': 0,
            'updated_at': 1000,
          },
        ],
      };
    }
    if (path.endsWith('.jpg') || path.endsWith('.mp4')) {
      return Uint8List.fromList(const [1, 2, 3]);
    }
    throw ApiException(statusCode: 404, body: 'not found');
  }

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    final api = MockApiClient(onRequest: (m, p, b) async => script(m, p, b));
    catalog = CatalogSyncClient(
      api,
      ExerciseCatalogRepository(database),
      IngredientCatalogRepository(database),
      ExerciseRepository(database),
      IngredientRepository(database),
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('refresh fills catalog without touching user tables', () async {
    final exCount = await catalog.refreshExercises(apiKey: 'k');
    final ingCount = await catalog.refreshIngredients(apiKey: 'k');
    expect(exCount, 2);
    expect(ingCount, 1);
    expect(await database.select(database.exercises).get(), isEmpty);
    expect(await database.select(database.ingredients).get(), isEmpty);
    expect(
      (await database.select(database.exerciseCatalog).get()).length,
      2,
    );
  });

  test('importSelectedExercises upserts only chosen ids', () async {
    await catalog.refreshExercises(apiKey: 'k');
    final result = await catalog.importExercises(ids: {'e2'}, apiKey: 'k');
    expect(result.ok, isTrue);
    expect(result.updated, 1);
    final rows = await database.select(database.exercises).get();
    expect(rows.map((r) => r.id).toSet(), {'e2'});
  });

  test('importSelectedIngredients stores minimal aggregate', () async {
    await catalog.refreshIngredients(apiKey: 'k');
    final result = await catalog.importIngredients(ids: {'i1'}, apiKey: 'k');
    expect(result.ok, isTrue);
    expect(result.updated, 1);
    final rows = await database.select(database.ingredients).get();
    expect(rows.map((r) => r.id).toSet(), {'i1'});
    expect(rows.single.barcode, '123');
    final pictures = await database.select(database.ingredientPictures).get();
    expect(pictures.length, 1);
    expect(await database.select(database.ingredientPrices).get(), isEmpty);
  });

  test('missing ids are skipped without error', () async {
    final result = await catalog.importExercises(
      ids: {'nope'},
      apiKey: 'k',
    );
    expect(result.ok, isTrue);
    expect(result.updated, 0);
  });
}
