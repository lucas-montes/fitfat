# Glossary

- `MealEntry`: one logged eating event with items and macro totals.
- `Ingredient`: food item with per-100g macro values; may be atomic or composite.
  - Fields: `id`, `name`, `creatorId` (nullable — local installation UUID or user/profile ID), `isArchived` (default `false`; hide/archive instead of delete), per-100g macros (calories, protein, carbs, fat, sodium, fiber, sugars, saturatedFat, cholesterol), and `components` (junction table `IngredientComponents` for composite/recipe ingredients).
- `IngredientComponents`: junction table linking an ingredient to its component ingredients with gram amounts. Used for composite/recipe ingredients.
- `IngredientPortion`: an ingredient plus a gram amount.
- `MacroNutrients`: calories, protein, carbs, and fat totals.
- `Seance`: an active or completed workout session.
- `ExerciseEntry`: one exercise inside a seance, with one or more sets.
- `ExerciseSet`: a reps/weight pair that can be marked completed.
- `ExerciseDefinition`: reusable exercise catalog item.
- `SeanceTemplate`: a reusable workout template made of exercise templates.
- `Goal`: either `StrengthGoal` or `BodyWeightGoal`.
- `UserProfile`: birth date, sex, height, weight, and activity level.
- `ComputedMacros`: derived daily calorie and macro targets from profile + goal.
