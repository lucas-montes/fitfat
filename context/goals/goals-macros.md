# Goals & Macros System

How fitfat computes daily macro targets from the user's fitness goal and profile.

## Data flow

```mermaid
flowchart LR
    Profile["UserProfile<br/>(age, sex, height,<br/>weight, activity)"]
    BWGoal["BodyWeightGoal<br/>(one only)"]
    SGoals["StrengthGoals<br/>(N, one per exercise)"]
    TDEE["TDEE<br/>Mifflin-St Jeor<br/>× activity factor"]
    CalTarget["Caloric Target<br/>(TDEE ± adjustment<br/>per direction)"]
    Macros["ComputedMacros<br/>(calories, protein,<br/>carbs, fat)"]

    Profile --> TDEE
    BWGoal --> CalTarget
    TDEE --> CalTarget
    CalTarget --> Macros
    Profile --> Macros
    BWGoal --> Macros
    SGoals --> |Chart progress bar|StrengthTrend["Strength Trend Chart"]
```

## Goal model

`GoalsData` holds all user goals:
- `bodyWeightGoal` — at most one `BodyWeightGoal`, drives macro computation
- `strengthGoals` — N `StrengthGoal`s, one per exercise, drive strength chart progress bars

### BodyWeightGoal
- Fields: `targetWeightKg`, `direction` (gain/lose/maintain), `targetDate` (optional)
- Caloric target: TDEE +300 (gain), TDEE −500 (lose), TDEE (maintain)
- Protein: 2.0 g/kg (gain), 2.4 g/kg (lose), 1.8 g/kg (maintain)
- Fat: 25% of total calories
- Carbs: remaining calories

### StrengthGoal
- Fields: `exerciseName`, `targetWeightKg`, `targetDate` (optional)
- Does NOT affect macro computation (only bodyweight goal does)
- Used for strength chart progress bars
- Protein: 2.2 g/kg bodyweight

## User profile

Fields: birthDate (DateTime), sex (Male/Female), height (cm), weight (kg), activity level. Age is computed from birthDate.

### Activity levels

| Level | Factor | Description |
|-------|--------|-------------|
| Sedentary | 1.2 | Little/no exercise |
| Light | 1.375 | 1–3 days/week |
| Moderate | 1.55 | 3–5 days/week |
| Active | 1.725 | 6–7 days/week |
| Very Active | 1.9 | Twice daily / physical job |

## BMR formula (Mifflin-St Jeor)

```
Male:   BMR = 10 × weight + 6.25 × height − 5 × age + 5
Female: BMR = 10 × weight + 6.25 × height − 5 × age − 161
```

TDEE = BMR × activity factor.

## Dashboard tabs

The Dashboard is split into two `TabBar` tabs:
1. **Overview** — `DailyNutritionCard`, `StrengthTrendChart`, `BodyweightTrendChart`
2. **Goals** — `_GoalsTab` with bodyweight goal card (editable, shows computed macros) + strength goal list (one tile per exercise with edit/delete)

## Providers

| Provider | Type | Purpose |
|----------|------|---------|
| `userProfileProvider` | `NotifierProvider<UserProfileNotifier, UserProfile?>` | Holds user profile (null until set) |
| `goalsProvider` | `NotifierProvider<GoalsNotifier, GoalsData>` | Holds bodyweight goal + strength goals list |
| `computedMacrosProvider` | `Provider<ComputedMacros>` | Derived: computes macros from profile + bodyweight goal |
| `legacyNutritionGoalProvider` | `Provider<NutritionGoal>` | Wraps ComputedMacros into old shape (removed in T09) |

## Key files

- `lib/src/models/dashboard_models.dart` — `GoalsData`, sealed `Goal`, `UserProfile`, enums, `ComputedMacros`
- `lib/src/providers/dashboard_providers.dart` — TDEE logic, `GoalsNotifier` with add/update/remove per goal type
- `lib/src/screens/dashboard/dashboard_screen.dart` — `_OverviewTab`, `_GoalsTab`, `BodyWeightGoalDialog`, `StrengthGoalDialog`, `ProfileSetupDialog`, `DailyNutritionCard`

See also: [overview.md](../overview.md)
