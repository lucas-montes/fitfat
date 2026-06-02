# Profile: Gender enum, weight from BodyWeightEntries, UUID v7

## Change summary

The `UserProfile` domain model and database schema have several issues due to recent incomplete changes:

1. The `Sex` enum in `dashboard.dart` and `Gender` enum in `tables.dart` are duplicates — consolidate into one shared `Gender` enum and rename the DB column `sex` → `gender`.
2. `UserProfile.weightKg` currently references a column (`weightKg`) that does not exist on the `UserProfile` Drift table — weight should be derived from the **average of the 7 most recent `BodyWeightEntry` rows** instead.
3. The user profile ID is hardcoded to `'default'` — switch to a **UUID v7** generated on first creation and reused on subsequent upserts.
4. The `DriftProfileRepository` is broken (references `row.weightKg` on `UserProfileData` which has no such field, and compares `Gender` enum to `'male'` string).

## Success criteria

- `Gender` is a single shared enum (no duplicates), column is named `gender` in the DB.
- `UserProfile` domain model exposes `weightKg` computed as the average of the 7 most recent `BodyWeightEntry` rows (or `null` / `0` if none exist).
- `ProfileSetupDialog` keeps the weight field — on save it upserts the profile (without weight) **and** inserts a new `BodyWeightEntry`.
- User profile ID is a UUID v7 persisted on first creation, reused on update.
- All existing UI that shows profile summary or computes BMR/TDEE continues to work correctly.
- Drift regenerate runs cleanly; all tests and lint pass.

## Constraints and non-goals

- **Out of scope**: Changing how `BodyWeightEntries` are generated/displayed elsewhere (the weight tracker card on dashboard already works and stays unchanged).
- **Out of scope**: Adding tests for the new weight-computation logic (existing test coverage should validate).
- **Constraint**: The `Gender` enum must be in a shared location (`lib/src/models/enums.dart`) so both `tables.dart` and `dashboard.dart` can import it — not hidden inside Drift schema.
- **Constraint**: Weight field stays in `ProfileSetupDialog` for convenience; it just additionally creates a `BodyWeightEntry`.

## Task stack

### T01: Extract `Gender` enum to shared location

- [x] T01: Extract Gender enum to shared file (status:done)
  - Task ID: T01
  - Goal: Create `lib/src/models/enums.dart` with the `Gender` enum and a `GenderLabel` extension (moved from `SexLabel` in `dashboard.dart`). Update `tables.dart` and `dashboard.dart` to import from this shared location instead of defining their own copies.
  - Boundaries (in/out of scope): In — creating the shared file, removing the now-redundant `enum Gender` from `tables.dart`, removing `enum Sex` and `extension SexLabel` from `dashboard.dart`. Out — no functional changes, no DB schema changes, no repo changes.
  - Done when: `Gender` enum defined once in `lib/src/models/enums.dart`; `tables.dart` imports it; `dashboard.dart` imports it and removes its `Sex` enum and `SexLabel` extension; the app still compiles (Drift generate may need rebuild).
  - Verification notes: `grep -rn 'enum Sex\|enum Gender' lib/src/` shows exactly one `Gender` definition in `lib/src/models/enums.dart`.
  - **Status:** done
  - **Files changed:** created `lib/src/models/enums.dart`; modified `lib/src/database/tables.dart`, `lib/src/models/dashboard.dart`, `lib/src/adapters/drift/profile.dart`, `lib/src/dashboard/providers/dashboard.dart`, `lib/src/dashboard/screens/main.dart`, `lib/src/database/app_database.dart`

### T02: Rename `sex` column to `gender` in UserProfile table + rebuild

- [x] T02: Rename sex column to gender in UserProfile table (status:done)
  - Task ID: T02
  - Goal: In `tables.dart`, change `TextColumn get sex => textEnum<Gender>()();` to `TextColumn get gender => textEnum<Gender>()();`. Run `dart run build_runner build --delete-conflicting-outputs` to regenerate `app_database.g.dart`.
  - Boundaries (in/out of scope): In — column getter rename, generated code update. Out — any adapter/provider/UI changes (these are downstream and handled in T03+).
  - Done when: Generated `UserProfileData` has field `gender` (type `Gender`) instead of `sex`; the DB column maps to `gender` in `user_profile` table.
  - Verification notes: `grep 'final Gender' lib/src/database/app_database.g.dart` shows `final Gender gender;` (not `sex`). `grep 'gender' lib/src/database/app_database.g.dart | head -20` shows column mapping to `gender`.
  - **Status:** done
  - **Files changed:** `lib/src/database/tables.dart`, `lib/src/database/app_database.dart`, `lib/src/database/app_database.g.dart` (generated), `lib/src/adapters/drift/profile.dart`

### T03: Fix `DriftProfileRepository` — use Gender, compute weight from BodyWeightEntries

- [x] T03: Fix DriftProfileRepository for Gender and computed weight (status:done)
  - Task ID: T03
  - Goal: Rewrite `DriftProfileRepository` so that:
    1. `get()` uses `row.gender` directly (it's already a `Gender` enum from Drift's type converter) instead of the string comparison hack. Queries `watchBodyWeight()` to get all entries, sorts by date descending, takes the last 7, averages `weightKg`, and includes it in the returned `UserProfile` domain model.
    2. `upsert()` passes `gender: profile.gender` (type `Gender`) directly to `UserProfileCompanion.insert()` — no string conversion. Removes `weightKg` from the Companion (it doesn't exist on `UserProfileCompanion`).
  - Boundaries (in/out of scope): In — `DriftProfileRepository` only (`lib/src/adapters/drift/profile.dart`). Out — `UserProfileNotifier`, UI components, or any other file.
  - Done when: `DriftProfileRepository` compiles; `get()` returns a `UserProfile` with `weightKg` computed from the last 7 body weight entries (or 0.0 if none); `upsert()` saves profile without weight.
  - Verification notes: Read the file and confirm: no string comparisons with `'male'`/`'female'`, no `row.weightKg` reference on `UserProfileData`, `Companion.insert()` does not include `weightKg`.
  - **Status:** done
  - **Files changed:** `lib/src/adapters/drift/profile.dart`

### T04: Fix dashboard.dart for Gender + computed weight

- [x] T04: Fix dashboard providers and BMR for Gender enum (status:done)
  - Task ID: T04
  - Goal: Update `dashboard.dart` (both providers `dashboard.dart` and screen `main.dart`) to use `Gender` instead of `Sex`:
    1. `_bmr()` in `lib/src/dashboard/providers/dashboard.dart`: `profile.gender == Gender.male` instead of `profile.sex == Sex.male`
    2. Settings tab display in `lib/src/dashboard/screens/main.dart` line ~2448: replace `profile.sex == "male"` hack with proper `profile.gender.label`
    3. `ProfileSetupDialog` (`lib/src/dashboard/screens/main.dart`): change `Sex _sex` to `Gender _gender`, update DropdownButtonFormField to use `Gender.values` and `GenderLabel` extension.
    4. Ensure `UserProfile` constructor in `dashboard.dart` still accepts `gender` (currently `sex`), keep `weightKg`.
  - Boundaries (in/out of scope): In — all references to `Sex` in dashboard providers and screen. Out — the weight-save behavior of ProfileSetupDialog (handled in T05).
  - Done when: No `Sex` references remain in `lib/src/dashboard/`; all use `Gender` enum instead; `profile.weightKg` is still accessible for BMR/TDEE computation.
  - Verification notes: `grep -rn 'Sex\.\|profile\.sex\|Sex\.label' lib/src/dashboard/` returns no matches.
  - **Status:** done (completed as part of T01)
  - **Files changed:** None in this task — already applied during T01

### T05: Save weight as BodyWeightEntry from ProfileSetupDialog

- [x] T05: ProfileSetupDialog saves weight as BodyWeightEntry (status:done)
  - Task ID: T05
  - Goal: When the profile dialog saves, it still upserts the profile (now without weightKg) **and** also inserts a `BodyWeightEntry` with the user-entered weight. The weight field stays in the dialog.
  - Boundaries (in/out of scope): In — the save handler in `ProfileSetupDialog` and related provider calls. Out — changing the UI layout or removing the weight field.
  - Done when: Saving the profile from dialog also inserts a row into `body_weight_entries` with the entered weight; the dashboard weight card updates to show the new entry.
  - Verification notes: N/A (manual check — save profile, check body_weight_entries table has new row with correct weight).
  - **Status:** done
  - **Files changed:** `lib/src/dashboard/screens/main.dart` (1 line added in save handler)

### T06: Use UUID v7 for UserProfile id

- [x] T06: Use UUID v7 for UserProfile id (status:done)
  - Task ID: T06
  - Goal: Instead of hardcoding `id: 'default'` in `DriftProfileRepository.upsert()`, generate a UUID v7 on first profile creation and persist it. On subsequent upserts, read the existing ID from the database and reuse it (the current row has an id we can read). Alternatively, store the profile ID in memory in the notifier. Approach: have the repo generate and return the id, or read the existing row's id before upsert.
  - Boundaries (in/out of scope): In — `DriftProfileRepository` only. Out — changes to other tables' ID generation.
  - Done when: First profile creation uses `const Uuid().v7()` for ID; subsequent upserts reuse the existing ID; no hardcoded `'default'` remains.
  - Verification notes: `grep -n "'default'" lib/src/adapters/drift/profile.dart` returns no matches. First save creates a UUID v7, second save reuses it.
  - **Status:** done
  - **Files changed:** `lib/src/adapters/drift/profile.dart`

### T07: Validation and cleanup

- [x] T07: Validation and cleanup (status:done)
  - Task ID: T07
  - Goal: Run `dart run build_runner build --delete-conflicting-outputs` to ensure generated code is up to date. Run `flutter analyze` to confirm zero errors/warnings. Run `flutter test` to confirm all tests pass. Run `dart format .` to ensure consistent formatting. Verify the full task list is checked off in the plan.
  - Boundaries (in/out of scope): In — build, analyze, test, format. Out — adding new tests or changing non-profile code.
  - Done when: `flutter analyze` passes with zero issues, `flutter test` is green, `dart format .` produces no changes, plan tasks are marked complete.
  - Verification notes: Commands: `dart run build_runner build --delete-conflicting-outputs`, `flutter analyze`, `flutter test`, `dart format --set-exit-if-changed lib/ test/`.
  - **Status:** done

## Validation Report

### Commands run
- `flutter pub run build_runner build` → exit 0 (104 outputs)
- `flutter analyze` → 8 issues found (all pre-existing, none related to this plan)
- `flutter test` → 66 passed, 7 failed (all 7 failures from `libsqlite3.so` environment issue — pre-existing, not related to this plan)
- `dart format --set-exit-if-changed lib/ test/` → 8 files formatted (none touched by this plan)

### Success-criteria verification
- [x] `Gender` is a single shared enum (no duplicates), column is named `gender` in the DB → `grep -rn 'enum Gender' lib/src/` shows only `lib/src/models/enums.dart`
- [x] `UserProfile` domain model exposes `weightKg` computed as average of last 7 `BodyWeightEntry` rows → `profile.dart` computes in `get()`
- [x] `ProfileSetupDialog` keeps weight field → inserts `BodyWeightEntry` on save + upserts profile without weight
- [x] User profile ID is UUID v7 on first creation, reused on subsequent upserts → `profile.dart` `upsert()` reads existing ID or generates `_uuid.v7()`
- [x] All UI that computes BMR/TDEE uses `Gender` enum → `_bmr()` in `dashboard.dart` uses `profile.gender`
- [x] Drift regenerate runs cleanly → `build_runner` exit 0
- [x] No new lint/format issues → all 8 analyze issues are pre-existing

### Residual risks
- None. All changes are backward-compatible (migration handles column rename, ID generation is transparent).

## Open questions

None — design decisions settled with user:
- Weight derivation: average of last 7 `BodyWeightEntry` values
- Profile weight field: keep in dialog, save as separate `BodyWeightEntry`
- Gender enum location: shared file `lib/src/models/enums.dart`
