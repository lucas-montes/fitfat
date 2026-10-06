# Calories, macros and phases

Split the calorie derivation into named steps, make the optional nutriments
mandatory, let the user configure cutting / bulking / maintenance separately, and
rebuild the dashboard card on one uniform row shape.

Split into stages because the risk profile differs sharply: A' is a behaviour-neutral
refactor, A is a schema migration crossing three tiers, B changes the user's actual
numbers, and C is the visible part. Each stage is independently verifiable.

## Decisions taken (2026-10-07)

| Decision | Choice |
|---|---|
| Nutriment nullability | All three (sodium, fiber, sugar) become non-null, default `0`, end to end |
| Macro derivation | Protein from g/kg bodyweight, fat from %, carbs is the remainder |
| Protein + fat exceed calories | Clamp carbs to `0`, warn in settings |
| Fiber target | A fixed number of grams per phase |
| Phases | Three cards; tapping one makes it active. Built on the existing `BodyWeightGoal` (lose/maintain/gain), relabelled Cutting/Bulking/Maintenance |
| Protein default | `2.0 g/kg` — accepted that this shifts macros on upgrade |
| Fiber missing data | Eliminated by making fiber non-null, so this question no longer arises |
| BMR shown | Both settings and dashboard |
| BMR formula | Labelled when it is Katch-McArdle; Mifflin-St Jeor is the default and needs no label |
| BMR editable | No — always derived |
| Macros when over calories | Red fill at 100%, no tick, no headroom |
| Old single calorie adjustment | Seeds the three phases: cutting −500, bulking +500, maintenance 0 |

**Accepted consequence:** protein at 2.0 g/kg changes the numbers on upgrade. At
2500 kcal, 70 kg: today 187.5 g protein / 250 g carbs / 83 g fat becomes
140 g / 297 g / 83 g.

**Accepted consequence:** a nutriment that was never recorded now reads `0` rather
than "unknown". Correct per the decision, but the fiber row will read `0 g of 30 g`
until ingredients are backfilled.

---

## Stage A' — split BMR from TDEE

Behaviour-preserving. No dashboard number moves. Done first so the rest is readable
and so a regression here is unambiguously a refactor fault rather than a changed value.

### Derivation

```
weight, height, age, gender, body fat
        │
        ▼
   ① BMR ────► bmrFor()   →  { bmr, formula }
        │
        ▼
   ② TDEE ───► tdeeFrom() →  bmr + activityKcal  (computed mode)
        │                    bmr × PAL multiplier (static mode)
        ▼
   ③ target = TDEE + phaseAdjustment
```

### Changes

- **New `lib/src/models/bmr_formula.dart`** — `enum BmrFormula { mifflinStJeor, katchMcArdle }`.
  Lives in `models/` with `activity_level.dart`, `gender.dart`, `body_weight_goal.dart`.
- **`diet/providers/calories.dart`**
  - `bmrFor({gender, weightKg, heightCm, age, bodyFatPercent, trackBodyFat})` →
    `({double bmr, BmrFormula formula})`. Katch-McArdle only when
    `trackBodyFat && bodyFatPercent != null`.
  - `tdeeFrom({bmr, level, activityKcal})` → `double`.
  - `bmrMetaProvider` → `({double bmr, BmrFormula formula, bool isEstimated})`
  - `tdeeProvider` → `double`
  - `CalorieTargetMeta` grows `bmr`, `tdee`, `formula`; `calorieTargetMetaProvider`
    composes the three.
  - Delete `macroTargetsMetaProvider` — no consumers.
  - `adjustForGoal` stays until Stage B.
- **New `test/calorie_math_test.dart`** — first coverage for this file.
  - `mifflinBmr`: male 80/180/30 → 1780, female → 1614
  - `katchMcardleBmr`: 80 kg at 20 % → 1752.4 (lean mass 64)
  - formula selection, including tracking on but percentage unset
  - `tdeeFrom` in both modes
  - missing inputs still yield a number, `isEstimated` true
  - **regression pin**: the composed chain's target is unchanged for fixed inputs

### Done when
`flutter analyze lib` clean; `flutter test` green (199 existing unchanged, new tests added).

---

## Stage A — nutriments non-null (schema v35)

`sodium_per100g`, `fiber_per100g`, `sugar_per100g` → `NOT NULL DEFAULT 0`,
backfilled with `COALESCE(col, 0)`. No data lost; unknown becomes an explicit zero.

- `Nutrition`, `ComponentNutrition`, `FoodNutrition`, `Ingredient`, `MealFood` lose
  their nullable members. The `copyWith` sentinel on `MealFood` exists only for these
  three, so it goes.
- `resolveFoodPer100g` loses the `sawSodium`/`sawFiber`/`sawSugar` tracking — the
  "null only when no component provided it" rule is no longer expressible.
- `meal_foods` snapshot columns become non-null; the server `COALESCE`s pushed nulls
  so an older client cannot break the endpoint.
- Desktop `resolve_food_nutrition` simplifies the same way.

### Files
Schema: `tables.dart`, `app_database.dart`. Models: `ingredient.dart`, `food.dart`,
`meal_food.dart`, `meal_entry.dart`. Math: `food_nutrition.dart`. Repos: `food_`,
`meal_`, `ingredient_`, `meal_resnapshot`. Sync: `ingredient_sync_client.dart`,
`data_push_service.dart`, `catalog_repository.dart`. Server: `db.rs`, `push.rs`,
`pull.rs`, `read.rs`, `lookup.rs`, `openfoodfacts.rs`. Desktop: `lib.rs`.
Tests: `food_nutrition_test`, `food_repository_test`, `meal_repository_test`,
`meal_resnapshot_test`, `food_sync_test`.

---

## Stage B — per-phase settings

Twelve new prefs. Three cards over the existing `BodyWeightGoal`; tapping selects the
active phase and expands its four knobs.

```
targetKcal  = tdee + adjustment          // negative = deficit
proteinG    = proteinPerKg × bodyweight
proteinKcal = proteinG × 4
fatKcal     = targetKcal × fatPct/100
carbsKcal   = max(0, targetKcal − proteinKcal − fatKcal)
```

`proteinKcal + fatKcal > targetKcal` clamps carbs to `0` and warns in settings.
Seeded cutting −500 / bulking +500 / maintenance 0, which reproduces today's targets
exactly. `adjustForGoal` is replaced by `tdee + signedAdjustment`; `macroTargetsFor`
gains a fiber target.

Also extends `MealEntry` with `totalFiber`.

---

## Stage C — dashboard

Five uniform rows (Calories, Protein, Carbs, Fat, Fiber) in the existing
`_MacroTargetRow` shape: label left, consumed/target right, bar below. The big
headline, the target tick and `CalorieBar` all go. Calorie fill reaches the end of the
track and turns red past 100%; macros keep the simple clamped fill.

```
Daily calorie target
Calories      1760 / 3000 kcal
▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬░░░░░░░░░░░░░░░░
Protein       120 / 140 g
Carbs         180 / 297 g
Fat            60 / 83 g
Fiber          18 / 30 g

BMR 1,650  ·  TDEE 2,100        [Katch-McArdle]
```

Settings → Nutrition shows the same BMR/TDEE line above the phase cards.

Deletes `test/calorie_bar_test.dart` (14 tests) with the widget; adds a small test
that `_MacroTargetRow` fills red past 100%.

---

## Notes editor (unrelated, small)

Pure swap: Save becomes the app bar action in a labelled `TextButton`, present in
both new and edit mode, disabled while saving. The bottom filled Save is removed and
Delete moves into its slot — edit mode only, as a full-width `TextButton.icon` in
`colorScheme.error`. `_save` and `_delete` are untouched, so the delete confirmation
dialog still guards it. All three strings already exist in every locale.

Diverges from `budget/screens/account_form.dart`, which uses the same app-bar delete
icon. Left alone to keep this change minimal.