# Plan: Food group redesign — meal history, meal editor, recipes, ingredients (Phase FG)

**Status:** in progress (2026-11-27)

## Change Summary

Rebuild the Food tab and its screens on the design system in
`context/ui/design-system.md` (proposals: https://claude.ai/artifact/SjcVZMs4L9oVqCTm9sSTmm,
rounds 11–13):

1. **Meal history** (the Food tab root) — styled like the weekly workout
   history: month chips + Range, one card per day, meal rows that open to list
   their foods, ↻ to log a meal again.
2. **Meal editor** — totals pinned on top, foods with gram fields, inline
   search at the end of the list. No meal name.
3. **Recipes** — cards with the macro bar and an eaten bar, sorted, tap to see
   the ingredients. No detail view: the form is the only other screen.
4. **Recipe form** — an editable table with a cooked-weight row and the per-100 g
   row it produces.
5. **Ingredients** — cards with six nutrient columns, search, the existing sync
   menu; **ingredient detail** with photo + Nutrition / Prices tabs.

## Direction (user feedback, rounds 11–13, 2026-11-27)

- The Food tab stays the **full meal history**, not a single-day view.
- **Meal names are never filled**: rows show no title; the editor has no name
  field (the column stays, written as an empty string).
- Macros everywhere are **one colored bar with the numbers inside**, always in
  the order **protein · carbs · fat · fiber · sodium**, with no per-number
  labels (a header names them once).
- **Small titles** in the top bar on every screen; no large titles.
- Receipts stay under Money (no change).

## Decisions

| # | Question | Status |
|---|---|---|
| D1 | Meal history | **decided: round 13 A** — card per day: tinted header with date, kcal, grams and the five macros in labeled columns; rows: time · kcal · grams · N foods · chevron · ↻, then the macro bar sized by calories (fiber/sodium get a minimum width); an opened meal lists each food with name, grams, kcal and a thinner bar |
| D2 | Meal editor | **decided: round 12 E, revised** — title is the date · time (tap to change); totals strip (kcal, grams, day total vs target, macro bar) pinned on top; foods as rows with a grams field; search inline at the end of the list, suggesting as you type with the last amount used; barcode button in the field; Delete = danger row at the bottom |
| D3 | Recipe list | **decided: round 13 A** — card: name, kcal / 100 g, date · ingredients · cooked weight, macro bar (per 100 g), eaten bar (grams eaten vs left); tap opens the ingredient list; sort Newest / Name / kcal; search |
| D4 | Recipe form | **decided: round 12 B** — name, then a table (ingredient · g · kcal · P · C · F) with editable grams, an inline "type an ingredient" row, the raw total row, an editable cooked-weight row and the resulting per-100 g row |
| D5 | Ingredient list | **decided: round 12 A** — card: photo, name, brand, kcal; protein, carbs, fat, fiber, sugar, sodium in six columns; search (barcode in the field); sync menu (Sync all / Select…) behind the cloud icon |
| D6 | Ingredient detail | **decided: round 11 C** — photo on top, then Nutrition / Prices tabs |
| D7 | Receipts | **decided: stay under Money** |

## Data

No schema change. `foods.cooked_weight` already exists (the per-100 g
denominator). "Grams eaten" per recipe is `SUM(meal_foods.amount)` over meals
that are not deleted.

## Tasks

### T01 — Shared: macro bar, date filter
- [ ] `lib/src/ui/widgets/macro_bar.dart`: `MacroValues` (P, C, F, fiber,
      sodium) from `Nutrition`; `MacroBar` (numbers inside, segment width by
      calories with a minimum, fixed order); `MacroColors.of(context)`
      (P primary, C blue, F warning, fiber success, sodium muted, blended over
      the surface).
- [ ] `lib/src/ui/widgets/date_filter_chips.dart`: month chips + Range sheet,
      extracted from `WorkoutHistoryScreen` and reused there.

### T02 — Meal history (Food tab)
- [ ] `meal_list.dart` rewritten: small title "Food" with Recipes and
      Ingredients actions and search (food names); filter chips; `_DayCard` +
      `_MealRow` (expand / collapse, ↻, Edit inside the opened meal).
- [ ] ↻ logs the same foods and grams now (live profiles), with Undo.
- [ ] Meal names no longer shown anywhere in the list.

### T03 — Meal editor
- [ ] `meal_form.dart` rewritten on `FormScaffold`: date·time title, totals
      strip, food rows with gram fields (swipe to remove), inline search with
      the last amount per food, barcode lookup, danger-row delete with Undo.
- [ ] `food_picker_sheet.dart` and `meal_item_editor_sheet.dart` removed when
      unused.

### T04 — Recipe list
- [ ] `food_list.dart` rewritten: small title, search, sort chips, recipe
      cards with the macro bar and eaten bar, tap to open the ingredients,
      Edit opens the form.
- [ ] `FoodRepository.eatenGrams()` → grams logged per food.

### T05 — Recipe form
- [ ] `food_form.dart` rewritten as the table; Duplicate in ⋮; Archive as the
      danger row.

### T06 — Ingredient list + detail
- [ ] `ingredient_list.dart`: cards with six columns, first photo, search with
      barcode, sync menu.
- [ ] `ingredient_detail_screen.dart`: photo header + Nutrition / Prices tabs;
      Edit and push in ⋮; archive as the danger row.

### T07 — Tests, l10n, docs
- [ ] Update the meal/food tests; add tests for the day grouping, ↻, eaten
      grams, the editor's inline add.
- [ ] en/es/fr strings; `context/diet/*.md`, `context/ui/design-system.md`.

## Acceptance

- Analyzer clean, all tests pass.
- The Food tab shows day cards with the chosen filters; ↻ logs a meal again.
- A meal can be created and edited without a name; totals update live.
- Recipes show cooked weight and grams eaten; the form edits by table.
- Ingredients list as cards; the detail has Nutrition / Prices tabs.
