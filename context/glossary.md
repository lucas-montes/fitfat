# Glossary

| Term | Definition |
|------|------------|
| fitfat | The app name. A personal calorie and exercise tracker built with Flutter. |
| Riverpod | Compile-safe state management library for Flutter/Dart. Used for all app state. |
| go_router | Official Flutter routing package. Used for declarative route definitions. |
| Material 3 | Google's latest design system (Material You). Default theme for the app. |
| Meal slot | A time-of-day category for food logging (breakfast, lunch, dinner, snack). |
| Diet | Main tab for meals and ingredients. |
| Ingredient | An item of food with nutrition per 100g; can be composite from other ingredients. |
| Meal | A list of ingredient portions eaten at a specific time, with optional name. |
| Seance | A workout session composed of exercises with reps and weights. |
| Cardio | Timed exercise activities (walking, skateboarding, running) tracked with duration and steps. |
| Weightlifting | Exercise tracked by sets, reps, weight, and rest time between sets. |
| Drift | SQLite ORM for Dart. Planned for Phase 2 local storage. |
| Pedometer | Phone built-in step sensor. Planned for Phase 2. |
| User Profile | Personal data (birthdate, sex, height, weight, activity level) used for TDEE computation. Set when creating a goal. Edit accessible from Goals tab. |
| TDEE | Total Daily Energy Expenditure, computed via Mifflin-St Jeor equation. Used to derive macro targets from goal type. |
| Goal | A sealed type (`StrengthGoal | BodyWeightGoal`) representing the user's fitness objective. Each goal type has different macro computation rules. |
| Strength Goal | Goal type: target a specific exercise weight (e.g. Bench Press → 100 kg). Protein = 2.2g/kg bodyweight. |
| Body Weight Goal | Goal type: gain, lose, or maintain to a target weight. Protein varies by direction (2.0/2.4/1.8 g/kg). |
| Activity Level | 5-level multiplier (Sedentary 1.2 → Very Active 1.9) used in TDEE calculation. |
| Computed Macros | Read-only daily calorie/protein/carbs/fat targets derived from goal type + user profile via TDEE. |
| Planned Set | A single set in a template with reps and optional weight. Stored as `List<PlannedSet>` in `ExerciseTemplate` for multi-set planning like "set 1: 3 reps × 4kg, set 2: 3 reps × 5kg". |
