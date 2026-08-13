# Body Metrics

Weight (kg) / height (cm) tracking, one entry per day. Lives in `lib/src/body/`; table `body_metrics` (v3) — see [database/schema.md](../database/schema.md).

## Current state

- `BodyMetricsEntry` domain model (`lib/src/models/body_metrics_entry.dart`)
- `BodyMetricsRepository` (`lib/src/body/repositories/body_metrics_repository.dart`)
- Riverpod providers (`lib/src/body/providers/body_metrics.dart`)
- Body Metrics card on the dashboard (`lib/src/body/screens/body_metrics_card.dart`) + add dialogs (`lib/src/body/screens/body_metric_dialog.dart`)
- Body metrics l10n strings in en/fr/es ARB files (`bodyMetrics*` keys)

## Domain model

`BodyMetricsEntry` (`lib/src/models/body_metrics_entry.dart`):

| Field | Type | Notes |
|-------|------|-------|
| id | String | UUID v7 |
| day | DateTime | start-of-day (stable upsert key) |
| weightKg | double? | optional; null = not recorded for that day |
| heightCm | double? | optional; null = not recorded for that day |
| createdAt | DateTime | |

## Repository API

`BodyMetricsRepository` (`lib/src/body/repositories/body_metrics_repository.dart`):

- `getAll()` — all entries ordered chronologically by day (chart-ready)
- `getLatest()` — most recent entry by day, or `null`
- `upsert(day, {weightKg, heightCm})` — one row per day: a **null** argument means "leave that metric unchanged"; a non-null value writes it. First entry for a day inserts; later saves update the existing row (no duplicates).

## Providers

`lib/src/body/providers/body_metrics.dart`:

- `bodyMetricsRepositoryProvider` — `Provider<BodyMetricsRepository>` on `databaseProvider`
- `bodyMetricsProvider` — `FutureProvider<List<BodyMetricsEntry>>` (chronological)
- `latestBodyMetricsProvider` — `FutureProvider<BodyMetricsEntry?>`

## Dashboard UI

The dashboard **weight-trend card** (`_WeightTrendCard`, private to `lib/src/dashboard/screens/dashboard.dart`) absorbed the old bottom `BodyMetricsCard` (removed in T05) and is the sole weight/height entry point:

- Two **separate** add buttons: "Add weight" and "Add height" (user decision — not one combined form).
- `showBodyMetricDialog` (`body_metric_dialog.dart`) — single value + date picker defaulting to today; value field empty with no default; value required and > 0 (blank/zero rejected). Returns `(DateTime day, double value)` or `null`.
- Latest summary line (`latestBodyMetricsProvider`) when data exists.
- Goal badge: when a body-weight goal is set in Settings (`BodyWeightGoal`), the card header shows a small right-aligned "Goal: …" label (`labelMedium`, `scheme.primary`); hidden when unset (app-polish-batch T02).
- Saving a weight or height entry shows a `commonSaved` SnackBar (T04).
- Weight evolution via a custom-painter `_WeightLineChart` (`_WeightLinePainter`, line + gradient fill): ≥2 points → line chart (date bottom labels, touch tooltip); 1 point → bold value text; 0 points → empty-state text. Days where the metric was not recorded are skipped.

## Semantics

- Saving the same day for the same metric updates the row in place; adding the other metric to an existing day preserves the stored sibling value.
- Units are metric: kg / cm (consistent with the app).

See also: [overview.md](../overview.md), [dashboard.md](../dashboard/dashboard.md), [context-map.md](../context-map.md)
