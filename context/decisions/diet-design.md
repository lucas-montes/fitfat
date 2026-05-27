# Diet Module Design Decisions

This document records the user's current decisions for the diet/ingredients/meals domain.

1) Ingredient metadata
- Add `creatorId` (string) to track who created the ingredient locally. This supports a future shared DB and attribution.
- Add `isArchived` (bool) to allow hiding an ingredient without deleting it. When an ingredient is used in any meal, prefer archiving over deletion.

2) Ingredient types
- Support two logical kinds of ingredient records:
  - Atomic ingredient: single food item (e.g., `Olive oil`, `Chicken breast`).
  - Composite ingredient / Recipe: a named combination of other ingredients with per-component gram amounts (e.g., `Pasta with pesto`).
- Composite ingredients are local-only by default and may be marked non-shareable.

3) Ingredient data model
- Store a broad set of macros per 100g where available: calories, protein, carbs, fat, sodium, fiber, sugars, saturatedFat, cholesterol, and any other common fields. The model should be extensible to add more.
- Composite ingredients will either store `components: List<IngredientPortion>` or a flattened computed per-100g macro summary (or both) to speed UI access.

4) Meal composition UX
- Allow searching across both atomic and composite ingredients and adding an ingredient to a meal with a gram amount.
- Composite ingredients should be selectable like atomic ones; when added they contribute their macros according to their grams.

5) Ingredient deletion policy
- Prevent hard delete when an ingredient is referenced by any existing meal. Instead:
  - If the ingredient is referenced, allow `archive` (set `isArchived=true`) so it disappears from normal pickers but remains intact for historical meals.
  - Allow hard delete only after manual confirmation and only if there are no references or if the developer adds a migration strategy to rewrite past meals.

6) UI & configuration
- Store user preference for which macros to display (e.g., show/hide sodium, fiber, sugars).
- By default show: calories, protein, carbs, fat, and sodium.
- Daily totals remain shown above each day group in the diet tab. The dashboard retains progress visualizations; consider adding a `Graphs` sub-tab to `Diet` later if desired.

7) Meal list and pagination
- The diet list will present a full month when opened and use infinite scroll to load older months as the user scrolls to the end.

8) Shared ingredient database concept
- The app should remain offline-first. A shared supermarket ingredient database is optional and treated as:
- The app should remain offline-first. A shared supermarket ingredient database is optional and treated as:
  - An importable/read-only dataset (download/bundle) that the user can choose to add to their local DB.
  - Sync can later enrich that dataset, but it must remain optional and preserve offline-first behavior.

9) Localization
- Macro names and UI labels must be localizable; the ingredient DB should support locale-specific display names where available.

10) Macro display preferences
- Allow the user to choose which macros are visible in the UI.
- Initial default set can remain calories, protein, carbs, and fat.
- Adding this preference layer is a moderate UI/state feature, not a major architecture change.

11) Creator identifier guidance
- Prefer a locally generated installation UUID or a future single-user profile id for `creatorId`.
- Avoid hardware-based identifiers; they are brittle and often restricted by platform privacy rules.

12) Testing & migration concerns
- Any schema changes (new fields on `Ingredient`, composite handling) should include migrations for existing data.
- Create unit tests for: ingredient macro calculations, composite ingredient expansion, archive vs delete behavior, meal total calculations, and infinite scroll pagination logic.

Acceptance criteria
- Ingredient records include `creatorId` and `isArchived` fields.
- Composite ingredients are supported and selectable in the meal editor.
- UI allows selecting which macros to show; defaults are sensible.
- Meal list loads a month and infinite-scrolls older months.
- Deleting an ingredient archives it if used by meals; hard delete requires no references.
