# Diet Module

> **Status note.** This file predates the `restart` rewrite and described several
> features that no longer exist (ingredient seeding, `creatorId`,
> `DietPreferencesNotifier`, a permanent-delete surface, inline localization).
> It has been trimmed to what is true today. Authoritative behaviour lives in
> `context/diet/` — see `ingredient-crud.md` and `meal-crud.md`.

## Meals log foods, not ingredients

The chain is `meal → food → ingredient`. A **food** is a named recipe: a set of
ingredients with amounts. Meals reference foods, so a recipe can be corrected
later without rewriting what was already eaten.

- `foods` (schema v34) holds a name and an archive flag and **no nutrition of its own**. Nutrition is resolved live through `foods → food_ingredients → ingredients`, so editing an ingredient is immediately visible in every food built from it.
- `food_per100g = Σ(ingredient.per100g × amount) / Σ(amount)`. Amounts are absolute amounts in the batch and their sum is the denominator — there is no separate yield input.
- `meal_foods` stores the amount eaten **plus a snapshot of that portion** (calories, protein, carbs, fat; sodium/fiber/sugar nullable). Reading a meal replays the snapshot, so editing an ingredient or recipe cannot restate history. The food name is joined live, so a rename shows up everywhere.
- Resolution is **all-or-nothing**: a food missing one ingredient reports no nutrition rather than summing whatever is present. Half a recipe would under-report calories and would drop that part from the weight denominator, inflating the rest.
- Every ingredient gets an auto-created 1:1 **derived food** (`id = "i:" + ingredientId`, one component at `amount = 100`) so it stays individually loggable. `IngredientRepository` is the only writer; `FoodRepository` rejects derived ids.
- Components have no sort order — they are presented alphabetically by ingredient name.
- Foods sync as their own resource (`GET/POST /foods`) with composition nested inside each food. Only user-created foods are pushed; derived ones mirror an ingredient.

## Archive/restore

Soft-delete mechanism that hides an ingredient without losing historical meal references.

- **Archive**: sets `isArchived = true`. The ingredient disappears from the list and the meal-form picker.
- **Restore**: sets `isArchived = false`. The ingredient reappears.
- **Permanent delete**: does not exist. Ingredients are only ever soft-archived, so a referenced ingredient can never trigger an FK violation.
- Past meals keep rendering archived ingredients: the meal repository joins ingredient rows without an `isArchived` filter.

## Nutriment scope

Sodium (mg), fiber (g) and sugar (g) are **ingredient-only** optional per-100g values. They carry through a food's composition and are snapshotted onto `meal_foods` alongside the macros, but stay null unless some component actually provided a value — components that omit them count as zero rather than nulling the total.

An ingredient's macros are the only place they are stored. There is no per-100g copy on a food, so nothing can go stale between an ingredient edit and the foods built from it.

## Localization

- Generated from `lib/l10n/app_{en,fr,es}.arb` via `flutter gen-l10n` (config in `l10n.yaml`).
- New UI strings must be added to all three ARB files.

## Seed data

There is no bundled ingredient seed. Ingredients arrive either by user entry or by sync/selective import from the server (`GET /ingredients`, `GET /ingredients/catalog`, `GET /ingredients/item/:id`).