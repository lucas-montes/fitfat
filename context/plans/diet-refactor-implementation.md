# Diet Module Refactor & Implementation Plan

Goal
-----
Bring the diet module to production-quality: add richer ingredient metadata, support composite recipes, enable safe archival instead of destructive deletes, provide user-selectable macro visibility, implement infinite-scroll month loading, and prepare optional shared-database import/sync — all while keeping the app offline-first, testable, and easy to maintain.

Plan structure
--------------
Tasks are numbered T01..T11. Each task includes scope, boundaries, acceptance criteria (done checks), and verification notes.

T01 — Schema + migration
- **Status:** done
- Scope: Add fields to the `ingredients` and `meal_ingredients` schema as needed: `creator_id TEXT`, `is_archived BOOLEAN`, and any additional macro columns (sodium, fiber, sugars, saturated_fat, cholesterol). Add support for composite ingredients in the data model (either a `components` JSON column or separate `components` table if preferred).
- Boundaries: Only database schema changes and drift model updates. Do not modify UI here.
- Done checks:
  - Drift table definitions updated and generated DB code compiles.
  - Migration added for existing users preserving data.
  - New columns accessible via generated `app_database.g.dart` classes.
- Verification: Run static analysis and a local dev run using `devDatabaseProvider` to confirm DB opens and basic queries work.

T02 — Repository / Adapter updates
- **Status:** done
- **Completed:** 2026-05-28
- **Scope:** Update `lib/src/adapters/drift/ingredient_repository.dart` to read/write new fields, return `Ingredient` domain models with full macros and `isArchived`, and support composite ingredients (resolving components on read).
- **Boundaries:** Keep adapters focused to mapping logic; do not import UI widgets.
- **Done checks:**
  - Adapter CRUD operations (create, read, update, archive, delete) pass for ingredients with all new fields
  - Composite ingredient read returns component list with placeholder ingredients
- **Files changed:** `lib/src/adapters/drift/ingredient_repository.dart`
- **Evidence:** All fields properly mapped, components resolved on read, delete operations remove from junction table first

T03 — Ingredient Editor UI + UX
- Scope: Add `creator` metadata display (read-only for bundled/system items), an `Archive` action, and a components editor to create composite ingredients. Allow the user to mark an ingredient as archived; show a confirmation dialog when archiving.
- Boundaries: Reuse existing ingredient editor screen; keep changes incremental.
- Done checks:
  - Users can create atomic and composite ingredients.
  - Users can archive and restore ingredients via a new archived-items menu.
- Verification: Manual UI flows and widget tests for editor components.

T04 — Meal Editor & Composer
- Scope: Ensure meal creation/editing supports selecting any ingredient (atomic or composite) and entering grams; composite ingredients expand correctly to macros when calculating meal totals.
- Boundaries: Do not change how meals are displayed in lists yet.
- Done checks:
  - Adding ingredients (atomic or composite) correctly updates meal total macros.
  - Saved meals persist with correct meal-ingredient junction rows.
- Verification: Unit tests for meal macro calculations and manual end-to-end create/edit meal scenario.

T05 — Meal List: month view + infinite scroll
- Scope: Update `MealsController` and `MealsTab` to load a full month initially and auto-load previous months as the user scrolls (infinite scroll). Keep in-memory caching and subscribe to DB watcher for the loaded range.
- Boundaries: Keep the existing grouping-by-day UI but enhance the controller to page months.
- Done checks:
  - Opening Diet loads the current month of meals.
  - Scrolling to the end auto-loads the previous month, appending new grouped day cards.
  - DB updates to meals within the loaded months are reflected live.
- Verification: Integration test for pagination and manual UI scrolling test.

T06 — Macro visibility preferences
- Scope: Add a user preference (persisted via `SharedPreferences` or a small DB table) storing visible macros list. Update the diet UI to read this preference and render only selected macro columns; provide a simple settings entry to toggle which macros are shown.
- Boundaries: Keep persistence local; no remote sync for preferences.
- Done checks:
  - Preference UI exists and updates stored preference.
  - Diet list and meal details respect the user's macro visibility choice.
- Verification: Unit tests for preference storage and widget tests verifying rendering behavior.

T07 — Archived ingredients management UI
- Scope: Add an `Archived Ingredients` list accessible from the ingredients screen or dashboard settings. Provide `Restore` and `Permanently Delete` actions (permanent delete only allowed if there are no meal references).
- Boundaries: Permanently deleting should still be guarded by checks to avoid breaking historical meals.
- Done checks:
  - Archived view lists archived items and allows restore.
  - Permanent delete is disabled (or warns) when ingredient is referenced by meals.
- Verification: Tests for archive/restore logic and DB referential checks.

T08 — Shared dataset import & sync scaffold
- Scope: Implement an import flow for a downloadable supermarket ingredient dataset (e.g., from a JSON/CSV file). Mark imported items with `creatorId='__system__'` or similar. Add a sync scaffold (background job & mock endpoints) later — for now expose sync as an optional feature flag and UI entry.
- Boundaries: No remote server required for v1; sync is scaffolded but disabled by default.
- Done checks:
  - Import flow can ingest a dataset and deduplicate by name/id.
  - Imported items marked as system/bundled.
- Verification: Manual import test and unit tests for dedupe logic.

T09 — Localization readiness
- Scope: Ensure macro labels, ingredient type labels, and UI copy for archive/restore are localizable. Add skeleton `en`, `fr`, and `es` ARB or i18n resource files and wire the Diet screens to use localized strings.
- Boundaries: Do not translate content data (ingredient names) automatically — support locale-specific display names if present in imported DB.
- Done checks:
  - UI strings in diet flows are localized for `en`, `fr`, and `es`.
  - Locale switching shows translated labels.
- Verification: Visual smoke tests with locale overrides.

T10 — Tests & migrations
- Scope: Add unit tests and widget tests for the above features; add DB migration tests. Ensure CI runs static analysis and tests.
- Boundaries: Keep tests focused on the diet feature — do not change other modules.
- Done checks:
  - New tests covering adapters, controllers, and major widgets pass locally.
  - Migrations verified on a copy of an example pre-change DB.
- Verification: CI green and local runs.

T11 — Docs & cleanup
- Scope: Update `context/` documentation (glossary, decisions) with final field names, add developer notes for migration steps, and update README or doc/diet.md with the new flows.
- Done checks:
  - Context files updated and reflect final implementation.
  - Developer migration checklist present.
- Verification: Review and sign-off.

T12 — Business logic isolation (architecture)
- Scope: Refactor controllers, services, and adapters so that business/domain logic is isolated from IO (database, shared preferences, filesystem) and UI widgets. Use small, pure domain services and plain Dart classes where possible, and keep Drift adapters and repositories limited to data access and mapping.
- Boundaries: This task focuses on code organization and testability; it does not change external behavior or UI flows.
- Done checks:
  - Domain logic (meal macro calculations, composite expansions, archive rules, pagination logic) is implemented in pure Dart classes with no Flutter or DB dependencies.
  - Repositories/adapters expose minimal interfaces and are injected (via Riverpod providers) into controllers.
  - Unit tests exercise domain services without mocking the DB or UI.
- Verification: Unit test suite includes focused tests for domain logic classes; code review confirms DI/separation patterns are applied.

Prioritization and dependencies
--------------------------------
- High priority: T01, T02, T05, T10, T12 — schema, adapters, pagination, tests, and business-logic isolation.
- Medium priority: T03, T04, T06, T07 — UI and UX updates for ingredients, meals, macro prefs, archive management.
- Low priority: T08, T09, T11 — shared dataset import, localization scaffolding, and docs.

Definition of done
------------------
- All tasks T01..T11 marked completed, tests added and passing, migrations in place, and context/docs updated. The diet module should be functionally equivalent to the design doc and ready for user QA.

Estimated effort (rough)
-----------------------
- T01: 1–2 days
- T02: 1–2 days
- T03: 2–3 days
- T04: 1–2 days
- T05: 2–3 days
- T06: 1 day
- T07: 1–2 days
- T08: 2–4 days (depending on dataset size)
- T09: 1–2 days
- T10: 2–3 days (parallelize with dev)
- T11: 0.5–1 day

Next step
---------
Confirm the plan and prioritization. After confirmation I will convert the highest-priority tasks into an implementation todo list, wire the DB schema changes, and create the first patch to the Drift schema and adapters.
