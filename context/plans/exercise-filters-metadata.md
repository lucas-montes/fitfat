# Plan: Exercise filters, detail tabs, curated videos, metadata cleanup

## Change Summary

Four user-requested improvements to the exercise catalog experience (decided with the user
2026-08-11; "forget the plans just implement it" — this file records the implemented scope):

1. **Curated video subset** — instead of bundling all ~1,728 videos (2.8 GB, git-ignored source),
   bundle only 16 allowlisted popular exercises (squat / bench / deadlift variants + a few others).
   `tool/video_allowlist.txt` holds the slugs; `tool/prepare_media.sh` prunes non-allowlisted videos
   from `assets/exercises/videos/` and copies only allowlisted ones (360p ffmpeg transcode when
   available, plain copy otherwise). `pubspec.yaml` lists the 16 videos as explicit asset entries
   (a directory entry would bundle everything).
2. **Metadata cleanup** — `tool/build_catalog.dart` now canonicalizes equipment synonyms
   (`Band` → `Resistance Band`, `Olympic barbell` → `Barbell`), widens the cardio heuristic
   (bodyPart ∈ {Cardio, Plyometrics} or name regex v2), and parses the scraped FAQ blobs into
   structured JSON `[{"q":..,"a":..}, ...]` stored in the `faqs` column. `videoPath` is set only for
   allowlisted slugs. Catalog regen: 3,799 exercises, 341 cardio, 16 with video, 3,790 with FAQs.
   The importer now **upserts by id**: existing locked rows are refreshed in place
   (`ExerciseRepository.updateCatalog`) when the import flag is unset; user rows are never touched.
3. **Exercise list search + filters** — `lib/src/exercise/exercise_filter.dart` (pure, unit-tested):
   `splitTags`, `canonicalEquipmentTag`, `ExerciseFilterOptions`/`exerciseFilterOptions`,
   `filterExercises` (query matches name/keywords/muscles; type/body-part/equipment/muscle filters
   AND-ed). `exercise_list.dart` is a `ConsumerStatefulWidget` with a search field + Type/Body part/
   Equipment/Muscle chip row opening a searchable multi-select bottom sheet; results count + Clear all.
4. **Detail screen tabs** — `ExerciseDetailScreen` pins media + name + type/body-part/equipment fact
   chips, then a **History | Details** `TabBar` so metadata AND set history fit without long scrolling.
   History tab keeps PR summary + chart + per-workout cards; Details tab = numbered instructions →
   tips → structured Q/A FAQs → primary/secondary muscle chips. Keywords stay hidden from display but
   remain searchable. `_RichText` renders `**bold**` markdown.

## Success Criteria

- 16 allowlisted videos in `assets/exercises/videos/` (verified on disk: 16); `pubspec.yaml` lists
  exactly those as explicit asset entries.
- Catalog shows 341 cardio / 3,458 weightlifting, equipment canonicalized (Resistance Band 275,
  Barbell 327), FAQs parseable as JSON for 3,790 rows.
- Importer refresh (flag `catalog_imported_v9`) updates locked rows in place and never mutates
  user-created rows (covered by `catalog_importer_test.dart`).
- Exercise list supports search + 4 filter dimensions; `exercise_filter_test.dart` (18 cases) passes.
- Detail screen renders header chips + History/Details tabs; FAQ section renders structured Q/A.
- l10n parity across en/fr/es (313 keys, verified via jq diff); `dart analyze` clean; `flutter test`
  green (28 tests).

## Tasks

- [x] T1 — Curated video allowlist + `prepare_media.sh` prune + pubspec explicit asset entries
- [x] T2 — `build_catalog.dart` normalization + structured FAQs + video allowlist gating; regen DB
- [x] T2b — `updateCatalog` + importer upsert refresh (flag v9)
- [x] T3 — `exercise_filter.dart` pure helpers + list screen search/filter UI + l10n keys
- [x] T4 — Detail screen tabs (header chips, History|Details TabBar, JSON FAQ rendering, `_RichText`)
- [x] Tests — `exercise_filter_test.dart` (18) + importer refresh test (3 total)
- [x] Media prune — `tool/prepare_media.sh` run (1,728 → 16 videos)
- [x] Validation — l10n parity, `dart format`, `dart analyze`, full `flutter test`

## Notes

- No schema change (v8 unchanged, no build_runner run).
- Catalog DB + media remain git-ignored (user decision 2026-08-10); run `tool/build_catalog.dart`
  + `tool/prepare_media.sh` before building.
