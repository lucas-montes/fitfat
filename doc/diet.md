# Diet Module

## Composite ingredients

A composite ingredient is a recipe made from other ingredients. Each component has a gram amount; the composite's per-100g macros are computed by summing all component macros at their specified amounts and scaling to 100g.

- Defined by non-empty `components` list on `Ingredient`.
- Stored in the `IngredientComponents` junction table.
- Created via the "Build from ingredients" toggle in the ingredient editor.
- `Ingredient.fromComponents()` computes per-100g values at construction.
- Selectable in the meal editor like any atomic ingredient.

## Archive/restore

Soft-delete mechanism that hides an ingredient without losing historical meal references.

- **Archive**: sets `isArchived = true`. The ingredient disappears from normal pickers.
- **Restore**: sets `isArchived = false`. The ingredient reappears.
- **Permanent delete**: only available from the "Archived Ingredients" view. Removes the row from the database.
- Ingredient pickers filter to `isArchived = false` (or include archived when viewing the archived tab).

## Macro visibility preferences

Users can toggle which macros appear in the UI (e.g., hide sodium, show fiber).

- Persisted via `SharedPreferences` (key: `macro_display_preference`), serialized as JSON.
- Managed by `DietPreferencesNotifier` at `lib/src/diet/providers/diet_preferences.dart`.
- Default visible macros: calories, protein, carbs, fat.
- `toggleMacro(key)` updates state and persists immediately.

## Localization

- Manual localization class at `lib/src/l10n/app_localizations.dart`.
- Three languages: English (`en`), French (`fr`), Spanish (`es`).
- Simple `_t()` switch on `localeName`.
- No `.arb` files or code generation. Strings are maintained inline.

## Dataset import flow

1. On first launch, `AppDatabase._seedIngredients()` inserts bundled ingredients (name + 4 core macros).
2. Bundled ingredients have `creatorId = null` (vs. user-created ingredients tagged with a local installation UUID).
3. No CSV/JSON import/export in the current version.
4. A future shared/common ingredient database (optional download/sync) is planned but not yet implemented.
