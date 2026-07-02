# FitFat — Glossary

| Term | Definition |
|------|------------|
| **Drift** | SQLite ORM for Dart/Flutter used as the persistence layer. |
| **@DataClass** | Drift annotation that generates a data class (row class) with `copyWith`, `toCompanion`, etc. |
| **Companion** | Drift-generated class for insert/update operations on a table row. |
| **StatefulShellRoute** | GoRouter route type that preserves child state when switching between branches (tabs). |
| **StatefulNavigationShell** | GoRouter widget that renders the current branch of a `StatefulShellRoute` and provides tab-switching methods. |
| **AppDatabase** | Central database class (`lib/src/database/app_database.dart`), annotated with `@DriftDatabase` listing all 7 tables. |
