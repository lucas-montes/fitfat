import 'dart:typed_data';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fitfat/src/models/food.dart';
import 'package:fitfat/src/database/app_database.dart' as db;

import 'package:fitfat/src/diet/repositories/food_repository.dart';
import 'package:fitfat/src/diet/repositories/ingredient_repository.dart';
import 'package:fitfat/src/network/api_client.dart';
import 'package:fitfat/src/sync/food_sync_client.dart';
import 'package:fitfat/src/sync/sync_models.dart';
import 'package:fitfat/src/sync/sync_state_store.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake server responses keyed by request path, plus the captured POST bodies.
final class _FakeApi implements ApiClient {
  _FakeApi(this._byPath);

  final Map<String, Object?> _byPath;
  final List<Map<String, Object?>> posts = [];

  Future<Object?> _respond(String path) async {
    final body = _byPath[path];
    if (body == null) throw ApiException(statusCode: 404, body: 'not found');
    return body;
  }

  @override
  Future<Object?> getJson(
    String path, {
    Map<String, String>? query,
    Map<String, String>? headers,
  }) => _respond(path);

  @override
  Future<Object?> postJson(
    String path, {
    Object? body,
    Map<String, String>? query,
    Map<String, String>? headers,
  }) async {
    posts.add((body as Map).cast<String, Object?>());
    return <String, Object?>{'server_time': 1000};
  }

  @override
  Future<Uint8List> getBytes(
    String path, {
    Map<String, String>? headers,
  }) async => Uint8List(0);

  @override
  Future<Object?> postBytes(
    String path, {
    required Uint8List body,
    Map<String, String>? headers,
  }) async => null;

  @override
  Future<Object?> postMultipart(
    String path, {
    required Map<String, String> fields,
    required Map<String, MultipartFilePart> files,
    Map<String, String>? headers,
  }) async => null;

  @override
  Future<Object?> putJson(
    String path, {
    Object? body,
    Map<String, String>? query,
    Map<String, String>? headers,
  }) async => null;

  @override
  Future<Object?> deleteJson(String path, {Map<String, String>? query}) async =>
      null;
}

void main() {
  late db.AppDatabase database;
  late IngredientRepository ingredients;
  late FoodRepository foods;
  late MemorySyncStateStore state;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    ingredients = IngredientRepository(database);
    foods = FoodRepository(database);
    state = MemorySyncStateStore();
  });

  tearDown(() => database.close());

  Future<String> seedIngredient(String name, {double calories = 100}) async {
    final ingredient = newIngredient(
      name: name,
      caloriesPer100g: calories,
      proteinPer100g: 10,
      carbsPer100g: 20,
      fatPer100g: 5,
    );
    await ingredients.insert(ingredient);
    return ingredient.id;
  }

  group('parseFood', () {
    test('requires an id and a name', () {
      expect(FoodSyncClient.parseFood(null, 0), isNull);
      expect(FoodSyncClient.parseFood({'name': 'x'}, 0), isNull);
      expect(FoodSyncClient.parseFood({'id': 'a'}, 0), isNull);
      expect(FoodSyncClient.parseFood({'id': '', 'name': 'x'}, 0), isNull);
    });

    test('parses the food and skips malformed components', () {
      final parsed = FoodSyncClient.parseFood({
        'id': 'f1',
        'name': 'Granola',
        'createdAt': 1000,
        'components': [
          {'ingredientId': 'i1', 'amount': 80.0},
          {'ingredientId': 'i2'}, // no amount
          {'ingredientId': 'i3', 'amount': 0}, // non-positive
          {'amount': 10.0}, // no ingredient
          'nonsense',
        ],
      }, 0);

      expect(parsed, isNotNull);
      expect(parsed!.food.name, 'Granola');
      expect(parsed.food.isDerived, isFalse);
      expect(parsed.components, hasLength(1));
      expect(parsed.components.single.ingredientId, 'i1');
    });

    test('reads archivedAt as a nullable timestamp', () {
      expect(
        FoodSyncClient.parseFood({'id': 'f', 'name': 'x'}, 0)!.food.archivedAt,
        isNull,
      );
      final archived = FoodSyncClient.parseFood({
        'id': 'f',
        'name': 'x',
        'archivedAt': 5000,
      }, 0)!;
      expect(archived.food.archivedAt, isNotNull);
    });
  });

  group('shareable', () {
    test('excludes derived foods, which are the ingredient\'s own wrapper', () {
      final all = [
        Food(id: derivedFoodId('i1'), name: 'Oats', createdAt: DateTime.now()),
        Food(id: 'user-1', name: 'Granola', createdAt: DateTime.now()),
        Food(id: 'user-2', name: 'Trail mix', createdAt: DateTime.now()),
      ];
      expect(FoodSyncClient.shareable(all).map((f) => f.name), [
        'Granola',
        'Trail mix',
      ]);
    });
  });

  group('push', () {
    test('nests each recipe with its components', () async {
      final oats = await seedIngredient('Oats', calories: 400);
      final honey = await seedIngredient('Honey', calories: 300);
      final granola = await foods.insertAndReturn(newFood(name: 'Granola'), [
        FoodIngredient(
          foodId: '',
          ingredientId: oats,
          ingredientName: 'Oats',
          amount: 80,
        ),
        FoodIngredient(
          foodId: '',
          ingredientId: honey,
          ingredientName: 'Honey',
          amount: 20,
        ),
      ]);

      final api = _FakeApi(const {});
      final result = await FoodSyncClient(api, database, state).push(
        foods: [granola],
        componentsByFoodId: [await foods.getComponents(granola.id)],
        apiKey: 'k',
      );

      expect(result.ok, isTrue);
      final items = api.posts.single['items']! as List;
      expect(items, hasLength(1));
      final row = items.single as Map;
      expect(row['name'], 'Granola');
      expect(row['components'], hasLength(2));
      final components = row['components']! as List;
      // Read back alphabetically by ingredient name, so Honey precedes Oats.
      expect(components.map((c) => (c as Map)['ingredientId']), [honey, oats]);
      expect((components.first as Map)['amount'], 20.0);
      // Nutrition is never on the wire — foods carry no macros.
      expect(row.containsKey('caloriesPer100g'), isFalse);
    });

    test('pushing nothing is a no-op, not a request', () async {
      final api = _FakeApi(const {});
      final result = await FoodSyncClient(
        api,
        database,
        state,
      ).push(foods: const [], componentsByFoodId: const [], apiKey: 'k');
      expect(result.ok, isTrue);
      expect(api.posts, isEmpty);
    });
  });

  group('pull', () {
    test('applies a recipe and advances the cursor', () async {
      final oats = await seedIngredient('Oats', calories: 400);

      final api = _FakeApi({
        '/foods': {
          'server_time': 5000,
          'items': [
            {
              'id': 'server-1',
              'name': 'Remote granola',
              'createdAt': 1000,
              'components': [
                {'ingredientId': oats, 'amount': 100.0},
              ],
            },
          ],
        },
      });

      final result = await FoodSyncClient(
        api,
        database,
        state,
      ).sync(apiKey: 'k');
      expect(result.ok, isTrue);
      expect(result.updated, 1);
      expect(result.serverTime, 5000);
      expect(state.getLastSyncedAt(SyncResource.foods), 5000);

      final saved = (await foods.getById('server-1'))!;
      expect(saved.name, 'Remote granola');
      expect(saved.components.single.ingredientId, oats);
    });

    test('never accepts a derived id from the wire', () async {
      // A malicious/buggy server claiming to own a derived food must not
      // overwrite the wrapper the local ingredient manages.
      final oats = await seedIngredient('Oats');

      final api = _FakeApi({
        '/foods': {
          'server_time': 5000,
          'items': [
            {
              'id': derivedFoodId(oats),
              'name': 'Hijacked',
              'createdAt': 1000,
              'components': [
                {'ingredientId': oats, 'amount': 100.0},
              ],
            },
          ],
        },
      });

      final result = await FoodSyncClient(
        api,
        database,
        state,
      ).sync(apiKey: 'k');
      expect(result.updated, 0);
      expect((await foods.getById(derivedFoodId(oats)))!.name, 'Oats');
    });

    test('skips components whose ingredient is not present yet', () async {
      final oats = await seedIngredient('Oats', calories: 400);

      final api = _FakeApi({
        '/foods': {
          'server_time': 5000,
          'items': [
            {
              'id': 'server-1',
              'name': 'Remote granola',
              'createdAt': 1000,
              'components': [
                {'ingredientId': oats, 'amount': 80.0},
                {'ingredientId': 'not-here', 'amount': 20.0},
              ],
            },
          ],
        },
      });

      final result = await FoodSyncClient(
        api,
        database,
        state,
      ).sync(apiKey: 'k');
      expect(result.updated, 1);
      // The recipe lands and resolves with the part we do have. Its remaining
      // single component collapses to that ingredient's own per-100g (the 1:1
      // invariant), so this is a partial recipe reporting partial nutrition —
      // not a silently-zeroed one.
      expect((await foods.getComponents('server-1')), hasLength(1));
      final resolved = await foods.resolveNutrition('server-1');
      expect(resolved, isNotNull);
      expect(resolved!.per100g.calories, closeTo(400, 1e-9));
    });

    test('asks the caller to resolve missing ingredients first', () async {
      final oats = await seedIngredient('Oats', calories: 400);

      final api = _FakeApi({
        '/foods': {
          'server_time': 5000,
          'items': [
            {
              'id': 'server-1',
              'name': 'Remote granola',
              'createdAt': 1000,
              'components': [
                {'ingredientId': oats, 'amount': 80.0},
                {'ingredientId': 'not-here', 'amount': 20.0},
              ],
            },
          ],
        },
      });

      final asked = <Set<String>>[];
      await FoodSyncClient(api, database, state).sync(
        apiKey: 'k',
        resolveMissingIngredientIds: (ids) async {
          asked.add(ids);
          // Simulate the catalogue import landing the ingredient.
          await ingredients.insert(
            newIngredient(
              name: 'Honey',
              caloriesPer100g: 300,
              proteinPer100g: 0,
              carbsPer100g: 80,
              fatPer100g: 0,
            ),
          );
          final row = await database.select(database.foodIngredients).get();
          expect(row.any((r) => r.ingredientId == oats), isFalse);
        },
      );

      expect(asked.single, {'not-here'});
    });

    test(
      'a tombstone archives rather than deletes, keeping meals renderable',
      () async {
        final oats = await seedIngredient('Oats', calories: 400);
        final granola = newFood(name: 'Granola');
        await foods.insert(granola, [
          FoodIngredient(
            foodId: granola.id,
            ingredientId: oats,
            ingredientName: 'Oats',
            amount: 100,
          ),
        ]);

        final api = _FakeApi({
          '/foods': {
            'server_time': 5000,
            'items': <Object?>[],
            'deleted': [granola.id],
          },
        });

        final result = await FoodSyncClient(
          api,
          database,
          state,
        ).sync(apiKey: 'k');
        expect(result.deleted, 1);
        expect((await foods.getById(granola.id))!.isArchived, isTrue);
        expect(
          (await foods.getAllWithNutrition()).map((e) => e.food.id),
          isNot(contains(granola.id)),
        );
      },
    );

    test('a failed pull keeps the cursor where it was', () async {
      final api = _FakeApi(const {});
      final result = await FoodSyncClient(
        api,
        database,
        state,
      ).sync(apiKey: 'k');
      expect(result.ok, isFalse);
      expect(state.getLastSyncedAt(SyncResource.foods), 0);
    });
  });
}
