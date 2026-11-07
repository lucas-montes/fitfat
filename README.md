# fitfat

## Regenerate generated files

When you change localization files in `lib/l10n/*.arb`, regenerate the Flutter
localization code with:

```bash
flutter gen-l10n
```

When you change Drift database tables or schema files in `lib/src/database/`,
regenerate the database code with:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

https://drift.simonbinder.eu/dart_api/tables/
