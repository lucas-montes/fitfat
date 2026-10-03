# Diet Module

> **Status note.** This file predates the `restart` rewrite and described several
> features that no longer exist (ingredient seeding, `creatorId`,
> `DietPreferencesNotifier`, a permanent-delete surface, inline localization).
> It has been trimmed to what is true today. Authoritative behaviour lives in
> `context/diet/` — see `ingredient-crud.md` and `meal-crud.md`.

## Composite ingredients

A composite ingredient is a recipe made from other ingredients. Each component has a gram amount; the composite's per-100g macros are computed by summing all component macros at their specified amounts and scaling to 100g.

- Stored in the `ingredient_components` junction table (schema v33); presence of at least one row means the ingredient is composite. `Ingredient.isComposite` is **derived** from that table, not stored.
- Components must be atomic — composites are flat, so a composite can never be a component of another. Archived components and duplicates are rejected.
- The per-100g values are **materialized** into the composite's own `ingredients` row on every save. `meal_ingredients` stores only grams and joins that single row for macros, so nothing downstream needs to expand the recipe.
- The ingredient form has a Simple / Recipe toggle; the recipe mode shows the calculated nutrition and a components editor. The detail screen lists what the recipe is made from.
- `POST/GET /ingredients` round-trips a nested `components[]` array inside the existing aggregate (no new endpoint). The list is the whole recipe on both sides — replace semantics, so removing a part travels by omission rather than a tombstone.

## Archive/restore

Soft-delete mechanism that hides an ingredient without losing historical meal references.

- **Archive**: sets `isArchived = true`. The ingredient disappears from the list and the meal-form picker.
- **Restore**: sets `isArchived = false`. The ingredient reappears.
- **Permanent delete**: does not exist. Ingredients are only ever soft-archived, so a referenced ingredient can never trigger an FK violation.
- Past meals keep rendering archived ingredients: the meal repository joins ingredient rows without an `isArchived` filter.

## Nutriment scope

Sodium (mg), fiber (g) and sugar (g) are **ingredient-only** optional per-100g values. They are not snapshotted onto meal items.

`meal_ingredients` persists only `(id, mealId, ingredientId, grams)` and joins the live `ingredients` row on read. Editing an ingredient's macros — including editing a composite's components — therefore retroactively changes the nutrition of every past meal that used it. This is a known, pre-existing characteristic, not specific to composites.

## Localization

- Generated from `lib/l10n/app_{en,fr,es}.arb` via `flutter gen-l10n` (config in `l10n.yaml`).
- New UI strings must be added to all three ARB files.

## Seed data

There is no bundled ingredient seed. Ingredients arrive either by user entry or by sync/selective import from the server (`GET /ingredients`, `GET /ingredients/catalog`, `GET /ingredients/item/:id`).