# Diet Direction

## Confirmed decisions
- Meals are grouped by day and should be browsable across a full month.
- Older meals should load automatically with infinite scroll behavior.
- Meal cards should show calories and the main macros.
- Ingredients need creator metadata and an archive/hide flag.
- The app should support both raw ingredients and user-made recipes.
- Store all macros for ingredients, even if only a subset is shown by default.
- The UI should allow users to choose which macros they want to see.
- Daily totals currently live above each day group; broader graphs can stay in the dashboard for now.

## Open design questions
- Whether ingredient deletion should be blocked, archived, or allowed with historical references preserved.
- Whether recipes should be privately owned by the user while raw ingredients come from a shared catalog.
- Which extra nutrients beyond sodium should be included in the first pass.

## Product implications
- The diet model needs a clear distinction between canonical food data and user-authored composite foods.
- Archive/hide should probably be preferred over hard deletion for used ingredients.
- Macro rendering should be configurable so the UI can stay simple while the data model remains rich.
