import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fitfat/src/database/app_database.dart' as db;
import 'package:fitfat/src/diet/repositories/ingredient_repository.dart';
import 'package:fitfat/src/diet/services/food_nutrition.dart';
import 'package:fitfat/src/models/food.dart';
import 'package:flutter_test/flutter_test.dart';

/// The derived-food contract: an ingredient and its auto-created 1:1 food are
/// always in sync, and only [IngredientRepository] writes that pair.
void main() {
  late db.AppDatabase database;
  late IngredientRepository repo;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    repo = IngredientRepository(database);
  });

  tearDown(() => database.close());

  Future<db.Food?> foodRow(String foodId) => (database.select(
    database.foods,
  )..where((t) => t.id.equals(foodId))).getSingleOrNull();

  Future<List<db.FoodIngredient>> componentsOf(String foodId) =>
      (database.select(
        database.foodIngredients,
      )..where((t) => t.foodId.equals(foodId))).get();

  Future<String> seed(
    String name, {
    double calories = 100,
    double protein = 10,
    bool archived = false,
  }) async {
    final ingredient = newIngredient(
      name: name,
      caloriesPer100g: calories,
      proteinPer100g: protein,
      carbsPer100g: 20,
      fatPer100g: 5,
    );
    await repo.insert(ingredient);
    if (archived) await repo.archive(ingredient.id);
    return ingredient.id;
  }

  group('derived food creation', () {
    test('insert creates a 1:1 food with a deterministic id', () async {
      final id = await seed('Chicken breast');

      final food = await foodRow(derivedFoodId(id));
      expect(food, isNotNull);
      expect(food!.name, 'Chicken breast');
      expect(food.archivedAt, isNull);

      final components = await componentsOf(food.id);
      expect(components, hasLength(1));
      expect(components.single.ingredientId, id);
      expect(
        components.single.amount,
        IngredientRepository.derivedFoodAmountGrams,
      );
    });

    test('the derived id is a pure function of the ingredient id', () {
      expect(derivedFoodId('abc'), 'i:abc');
      expect(isDerivedFoodId(derivedFoodId('abc')), isTrue);
      expect(isDerivedFoodId('a-uuid-v7'), isFalse);
    });

    test(
      're-applying the same ingredient does not duplicate the food',
      () async {
        final ingredient = newIngredient(
          name: 'Oats',
          caloriesPer100g: 400,
          proteinPer100g: 13,
          carbsPer100g: 60,
          fatPer100g: 7,
        );
        // insert → update → upsert (which updates again): the food row must stay
        // singular and its composition must not grow.
        await repo.insert(ingredient);
        await repo.update(ingredient);
        await repo.upsert(ingredient);

        expect(await foodRow(derivedFoodId(ingredient.id)), isNotNull);
        expect(await componentsOf(derivedFoodId(ingredient.id)), hasLength(1));
        expect(await database.select(database.foods).get(), hasLength(1));
        expect(
          await database.select(database.foodIngredients).get(),
          hasLength(1),
        );
      },
    );
  });

  group('the pair stays in sync', () {
    test('renaming the ingredient renames its food', () async {
      final id = await seed('Oats');

      await repo.update(
        (await repo.getById(id))!.copyWith(name: 'Rolled oats'),
      );

      expect((await foodRow(derivedFoodId(id)))!.name, 'Rolled oats');
    });

    test(
      'archiving the ingredient archives its food, restoring reverses it',
      () async {
        final id = await seed('Honey');

        await repo.archive(id);
        var food = await foodRow(derivedFoodId(id));
        expect(food!.archivedAt, isNotNull);

        await repo.restore(id);
        food = await foodRow(derivedFoodId(id));
        expect(food!.archivedAt, isNull);
      },
    );

    test('archiving does not disturb the name', () async {
      final id = await seed('Honey');

      await repo.archive(id);

      expect((await foodRow(derivedFoodId(id)))!.name, 'Honey');
    });

    test('upsert keeps the pair in sync', () async {
      final id = await seed('Rice');

      await repo.upsert((await repo.getById(id))!.copyWith(name: 'Brown rice'));

      expect((await foodRow(derivedFoodId(id)))!.name, 'Brown rice');
    });
  });

  group('ingredients are purely atomic now', () {
    test('no composition API remains on the ingredient model', () async {
      final id = await seed('Plain');

      // An ingredient holds only its own facts — there is no isComposite, and
      // the only food that references it is the derived 1:1 wrapper.
      expect((await repo.getById(id))!.isArchived, isFalse);
      final referencing = await database
          .customSelect(
            'SELECT food_id FROM food_ingredients WHERE ingredient_id = ?',
            variables: [Variable<String>(id)],
          )
          .get();
      expect(referencing.length, 1);
      expect(referencing.single.read<String>('food_id'), derivedFoodId(id));
    });

    test('a derived food resolves to exactly its ingredient', () async {
      final id = await seed('Oats', calories: 400, protein: 13);
      final ingredient = (await repo.getById(id))!;

      // The invariant that removes any need for a special case.
      final resolved = resolveFoodPer100g([
        (
          caloriesPer100g: ingredient.caloriesPer100g,
          proteinPer100g: ingredient.proteinPer100g,
          carbsPer100g: ingredient.carbsPer100g,
          fatPer100g: ingredient.fatPer100g,
          sodiumPer100g: ingredient.sodiumPer100g,
          fiberPer100g: ingredient.fiberPer100g,
          sugarPer100g: ingredient.sugarPer100g,
          amount: 100,
        ),
      ]);
      expect(resolved.per100g.calories, 400);
      expect(resolved.per100g.protein, 13);
      expect(resolved.totalAmount, 100);
    });

    test(
      'getAll returns only ingredients, unfiltered by composition',
      () async {
        await seed('A');
        await seed('B');
        expect(await repo.getAll(), hasLength(2));
      },
    );
  });

  group('stores, pictures and prices still work', () {
    test('archived ingredients hide from getAll but keep their row', () async {
      final id = await seed('Ghost');
      expect(await repo.getAll(), hasLength(1));

      await repo.archive(id);
      expect(await repo.getAll(), isEmpty);
      // Still resolvable so past meals keep rendering it.
      expect((await repo.getById(id))!.isArchived, isTrue);
    });
  });
}
