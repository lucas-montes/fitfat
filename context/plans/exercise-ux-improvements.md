# Exercise Module UX Improvements Plan

## Overview
Polish pass on the exercise module based on user feedback. 15 raw ideas consolidated into 10 concrete tasks.

---

### EX01 — Set editing & completion time display
- **Status:** done
- **Completed:** 2026-05-30
- **Scope:** Allow long-press editing of any set (guided or free-form) — fix disabled edit for past/completed sets. Show completion timestamp (`HH:mm`) on every set card, not just guided mode.
- **Files:** `lib/src/exercise/screens/current_seance_screen.dart`
- **Done checks:**
  - ✅ Long-press on any set opens edit dialog
  - ✅ Each set shows its completion time (or "—" if not completed)
- **Evidence:** `_FreeformSetCard` updated with `InkWell` + `onLongPress` callback and timestamp display. `_GuidedSetCard` already had both features from E03/E07.
- **Verification:** 31/31 tests pass, 0 analyze errors

---

### EX02 — History panel & set form reorder
- **Status:** done
- **Completed:** 2026-05-30
- **Scope:** Move "Add Set" form to the **top** of the exercise detail view (above existing sets). Below the existing set list, add a **collapsible panel** showing the last 3-5 sessions' sets for this exercise.
- **Files:** `lib/src/exercise/screens/current_seance_screen.dart`
- **Done checks:**
  - ✅ "Add Set" is above the existing sets list in the detail view
  - ✅ Collapsible "Previous sessions" panel at the bottom (ExpansionTile)
  - ✅ Shows last 5 sessions sorted by date descending
  - ✅ Each history entry shows: date, reps, weight
- **Evidence:** `_PreviousSessionsPanel` ConsumerWidget added at end of detail view, reads from `seanceHistoryProvider` to find past sessions for the current exercise. Takes top 5 completed seances with matching exercise name, displays date + sets per session in an expandable card.
- **Verification:** 31/31 tests pass, 0 analyze errors

---

### EX03 — Exercise library filters
- **Status:** done
- **Completed:** 2026-05-30
- **Scope:** Add category filter chips/tabs to the exercise search screen. Users can filter exercises by muscle group (Chest, Back, Legs, Shoulders, Arms, Core). Keep the existing text search. Show active filter count.
- **Files:** `lib/src/exercise/screens/current_seance_screen.dart` (exercise search in active seance flow)
- **Done checks:**
  - ✅ Category filter chips appear above exercise list (horizontal scrollable FilterChip row)
  - ✅ Multiple categories can be selected simultaneously
  - ✅ Active filters are visually distinct (filled chip style)
  - ✅ Text search + category filters combine correctly (both applied)
- **Evidence:** `_selectedCategories` set tracks active filters. Horizontal `FilterChip` row between search field and results. Results filtered by both text query and selected categories. Categories are dynamically derived from `exerciseListProvider`.
- **Verification:** 31/31 tests pass, 0 analyze errors

---

### EX04 — Dashboard tab: heatmap + quick stats
**Scope:**
- Create/redesign the dashboard tab to serve as the landing screen with first-glance info
- **Calendar heatmap** showing training volume per day (last 30-90 days) — cell color intensity = volume
- **Quick stats row**: total sessions this week/month, total volume, total time
- **Today's activity**: current workout status or last workout summary
- Tap on a heatmap day shows that day's session details

**Files:** `lib/src/exercise/screens/dashboard.dart` (new or major rewrite), `lib/src/exercise/providers/seance.dart` (aggregation queries)

**Done checks:**
- ✅ Dashboard appears as the first tab
- ✅ Calendar heatmap shows training volume for each day
- ✅ Quick stats visible (sessions, volume, time)
- ✅ Water widget present (see EX09)

---

### EX05 — Charts: date axes on history screens
**Scope:**
- Replace current chart X axis (session index numbers 0, 1, 2…) with **session dates** (formatted as `dd/MM`)
- Line charts for volume + e1RM progression remain, but axes now show readable dates
- Consistent date formatting across all history views

**Files:** `lib/src/exercise/screens/exercise_history_screen.dart`

**Done checks:**
- ✅ Chart X axis shows dates instead of session indices
- ✅ Date labels are readable (not overlapping)

---

### EX06 — Strength display: raw weight, PR badges, e1RM in summary
**Scope:**
- Show **raw weight lifted** per set (already done — just verify)
- Add **PR badge** (trophy icon) on any set that beats the personal best for that exercise
- Display **best e1RM** in the exercise summary card (at the bottom of each exercise detail view)
- e1RM = Epley formula: `weight × (1 + reps / 30)`

**Files:** `lib/src/exercise/screens/current_seance_screen.dart`, `lib/src/exercise/services/workout_services.dart` (already has `ProgressionService`)

**Done checks:**
- ✅ PR badge appears on sets that beat previous personal best
- ✅ Exercise summary card shows "Best e1RM: XX.X kg"
- ✅ Raw weight per set clearly displayed

---

### EX07 — Seance completion summary view
- **Status:** done
- **Completed:** 2026-05-30
- **Scope:** When user taps "Complete Seance", redirect to a **new summary screen** instead of going straight to the exercise tab
- Summary shows:
  - Seance name + duration
  - Per-exercise breakdown: sets, reps, total weight, best set
  - PRs detected during the session (highlighted with trophy icon)
  - Total volume, total rest time
  - "Finish" button to dismiss and return to exercise tab
- **Files:** `lib/src/exercise/screens/current_seance_screen.dart` (added `SeanceSummaryScreen` class)
- **Done checks:**
  - ✅ Summary screen appears after completing a seance
  - ✅ All key metrics displayed (duration, volume, sets, PRs, rest time)
  - ✅ "Finish" button dismisses and returns to exercise tab
- **Evidence:** SeanceSummaryScreen widget renders seance name, duration, total volume, and per-exercise breakdown with completion stats and best sets. Finish button pops back to exercise tab.
- **Verification:** 0 analyze errors

---

### EX08 — Timer: auto-switch format + icon-only mode badge
**Scope:**
- Auto-switch seance timer from `mm:ss` to `hh:mm:ss` after 60 minutes
- Replace Guided/Free-form chip with an **icon-only indicator**:
  - Guided: `Icons.list_alt` (list icon)
  - Free-form: `Icons.playlist_add` (add icon)
- No text label, no interaction — purely visual

**Files:** `lib/src/exercise/screens/current_seance_screen.dart`

**Done checks:**
- ✅ Timer shows `mm:ss` for < 60 min, `hh:mm:ss` for ≥ 60 min
- ✅ Mode chip replaced with icon-only indicator in app bar

---

### EX09 — Notification: i18n + seance/exercise name
- **Scope:**
- Update `SeanceForegroundService` notification to add:
  - **Localized title**: "Active Workout" (en), "Entraînement actif" (fr), "Entrenamiento activo" (es)
  - **Body**: "[Last exercise name] — [Seance name]"
  - Keep all existing notification functionality (rest timer stays in-app only, not in notification)
- Pass the seance state snapshot to the service so it can read the latest exercise name and seance name
- Update notification whenever a new exercise is started or set is completed

- **Status:** done
- **Completed:** 2026-05-31
- **Files:** `lib/src/services/seance_foreground_service.dart`, `lib/src/exercise/providers/seance.dart`, `lib/src/exercise/screens/current_seance_screen.dart`, `lib/src/exercise/screens/seance_library_screen.dart`, `lib/src/exercise/screens/main.dart`

**Done checks:**
- ✅ Notification shows localized "Active Workout" title (wired via `AppLocalizations.activeWorkout`)
- ✅ Body shows current exercise name + seance name
- ✅ Notification updates when exercise changes or when a set is completed
- ✅ Existing elapsed/rest display preserved

**Evidence:**
- Added `activeWorkout` getter to `AppLocalizations` and saved localized title when starting/updating the foreground service.
- `SeanceForegroundService` now accepts `notificationTitle` and `exerciseName` and persists them for the task handler to read.
- Active seance UI (`current_seance_screen.dart`) synchronizes the localized notification title when the screen opens and updates the current exercise name when the user selects an exercise.
- Template start flows (`seance_library_screen.dart`, exercise templates in `main.dart`) now set the localized notification title when starting a seance.

---

### EX10 — Water intake tracking (dashboard widget)
**Scope:**
- Simple water intake system living on the dashboard tab
- Store daily totals in SharedPreferences (keyed by date): `{ "2026-05-30": 1500, "2026-05-29": 2000, … }`
- **Dashboard widget** shows:
  - Current intake / daily goal (e.g. "💧 1.5L / 2.5L")
  - Tap buttons: +250ml, +500ml
  - Quick visual progress bar
- **History view**: accessible from the widget, shows last 7 days as a simple bar chart or list
- Daily goal configurable (default 2.5L, stored in SharedPreferences)

**Files:** `lib/src/widgets/water_tracker.dart` (new widget), `lib/src/exercise/providers/water.dart` (new), `lib/src/exercise/screens/dashboard.dart` (water widget embedded)

**Done checks:**
- ✅ Water counter visible on dashboard tab
- ✅ Tap +250ml / +500ml buttons work
- ✅ Progress bar shows progress toward daily goal
- ✅ Daily goal configurable (default 2.5L)
- ✅ History view available showing last 7 days

---

## Prioritization & Execution Order

| Task | Effort | Depends On |
|------|--------|------------|
| **EX01** — Set editing + timestamps | 0.5d | — |
| **EX02** — History panel + form reorder | 1d | — |
| **EX03** — Exercise library filters | 0.5d | — |
| **EX04** — Dashboard tab: heatmap + stats | 1.5d | — |
| **EX05** — Chart date axes | 0.5d | — |
| **EX06** — PR badges + e1RM summary | 0.5d | EX01 |
| **EX07** — Seance completion summary | 1d | EX01 |
| **EX08** — Timer format + mode icon | 0.5d | — |
| **EX09** — Notification i18n + names | 0.5d | — |
| **EX10** — Water intake dashboard widget | 1d | EX04 |

**Estimated total: ~7.5 days**

**Suggested order:** EX01 → EX03 + EX08 (parallel) → EX02 → EX05 → EX06 + EX09 (parallel) → EX04 + EX10 (parallel, shared dashboard) → EX07
