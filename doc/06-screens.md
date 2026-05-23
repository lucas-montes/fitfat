# Screens & User Interface

## Bottom navigation

```mermaid
flowchart LR
    BottomNav["Bottom Navigation Bar"] --> Diet["🍽 Diet"]
    BottomNav --> Dashboard["📊 Dashboard"]  
    BottomNav --> Exercise["💪 Exercise"]
```

The app has 3 tabs accessible via the bottom navigation bar. A 4th screen (Current Seance) appears as a full-screen overlay when a seance is active.

---

## Diet tab

```mermaid
flowchart TD
    Diet["Diet Screen"] -->|TabBar| MealsTab["Meals"]
    Diet -->|TabBar| IngredientsTab["Ingredients"]
    
    MealsTab -->|list of| MealCards["Meal cards"]
    MealCards -->|each shows| MealName["Meal name"]
    MealCards -->|each shows| MealMacros["Total macros"]
    
    IngredientsTab -->|list of| IngredientCards["Ingredient cards"]
    IngredientCards -->|each shows| IngName["Name"]
    IngredientCards -->|each shows| IngMacros["Calories/100g"]
    
    MealsTab -->|FAB "Add Meal"| AddMeal["Add Meal Screen"]
    IngredientsTab -->|FAB "Add Ingredient"| AddIngredient["Add Ingredient Screen"]
    
    AddMeal -->|search & select| IngredientPicker["Ingredient picker"]
    AddMeal -->|set| Grams["Grams per ingredient"]
    
    AddIngredient -->|fields| IngForm["Name, calories, protein, carbs, fat"]
```

**Key files:** `lib/src/screens/diet/diet_screen.dart`, `lib/src/screens/food/add_meal_screen.dart`, `lib/src/screens/food/custom_ingredient_screen.dart`

---

## Exercise tab

```mermaid
flowchart TD
    Exercise["Exercise Screen"] -->|TabBar| SeancesTab["Seances"]
    Exercise -->|TabBar| ExercisesTab["Exercises"]
    
    SeancesTab -->|top card| NewSeance["New Seance or Running Seance"]
    SeancesTab -->|section| Templates["Templates (horizontal scroll)"]
    SeancesTab -->|section| History["Completed seances"]
    
    NewSeance -->|when no seance| StartBlank["Start Blank Seance button"]
    NewSeance -->|when seance running| RunningCard["Running Seance card"]
    RunningCard --> View["View button → /current-seance"]
    RunningCard --> Stop["Stop button → cancel seance"]
    
    Templates -->|tap| StartTemplate["Start seance from template"]
    Templates -->|⋮ menu| EditTemplate["Edit template"]
    Templates -->|⋮ menu| CloneTemplate["Clone template"]
    Templates -->|⋮ menu| DeleteTemplate["Delete template"]
    
    History -->|tap ⋮| CreateTemplateFrom["Create template from this seance"]
    
    ExercisesTab -->|list of| ExerciseCards["Exercise cards"]
    ExerciseCards -->|tap| ExerciseHistory["Exercise History Screen"]
```

**Key files:** `lib/src/screens/exercise/exercise_screen.dart`, `lib/src/screens/exercise/seance_library_screen.dart`, `lib/src/screens/exercise/create_seance_screen.dart`, `lib/src/screens/exercise/exercise_history_screen.dart`, `lib/src/screens/exercise/current_seance_screen.dart`

### Current Seance Screen (full-screen overlay)

```mermaid
flowchart TD
    CSS["Current Seance Screen"] -->|two views| ListView["Exercise List"]
    CSS -->|two views| DetailView["Sets Detail"]
    
    ListView --> Added["Added exercises (tap to enter)"]
    ListView --> Search["Search bar → add exercises"]
    ListView --> Complete["Complete Seance button"]
    
    DetailView --> Sets["Sets with checkboxes"]
    DetailView --> AddSetForm["Add Set (reps × weight)"]
    DetailView --> Summary["Summary (total reps, total weight)"]
    DetailView --> BackArrow["Back to list"]
    
    Sets --> Toggle["Checkbox → completed/incomplete"]
    Sets --> Edit["Tap → edit reps/weight"]
    Sets --> Time["HH:mm completion timestamp"]
```

---

## Dashboard tab

```mermaid
flowchart TD
    Dashboard["Dashboard Screen"] -->|TabBar| Overview["Overview"]
    Dashboard -->|TabBar| Goals["Goals"]
    Dashboard -->|TabBar| Settings["Settings"]
    
    Overview --> DailyCard["Daily Nutrition Card"]
    Overview --> StrengthChart["Strength Trend (fl_chart LineChart)"]
    Overview --> WeightChart["Bodyweight Trend (bars)"]
    
    DailyCard --> Calories["Calories: eaten / target"]
    DailyCard --> Protein["Protein: eaten / target"]
    DailyCard --> Carbs["Carbs: eaten / target"]
    DailyCard --> Fat["Fat: eaten / target"]
    
    StrengthChart --> PeriodSelector["7/30/90 day selector"]
    StrengthChart --> PerExercise["One line per exercise"]
    StrengthChart --> ProgressBar["Progress bar per strength goal"]
    
    Goals --> BWGoal["Bodyweight goal card"]
    Goals --> SGGoals["Strength goals list"]
    
    BWGoal --> EditBW["Edit/delete bodyweight goal"]
    SGGoals --> AddSG["Add strength goal"]
    SGGoals --> EditSG["Edit/delete per strength goal"]
    
    Settings --> ExportDB["Export database (share .db file)"]
    Settings --> DeleteDB["Delete all data"]
```

**Key files:** `lib/src/screens/dashboard/dashboard_screen.dart`

---

## Floating pill

When a seance is running, a floating `SeanceFloatingPill` widget appears at the bottom-right of every screen. It shows the elapsed time and is tappable to open the seance screen.

```dart
// Rendered in AppShell (app_router.dart)
body: Stack(children: [
  navigationShell,
  const Positioned(right: 16, bottom: 16, child: SeanceFloatingPill()),
]),
```

The pill:
- Uses `primaryContainer` theme color
- Shows 6px elevation shadow
- Updates every second via a periodic Timer
- Returns `SizedBox.shrink()` when no seance is active
