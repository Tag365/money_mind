# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Money Mind is a Flutter personal-finance tracker (accounts + statements) backed by a local SQLite database via Drift. Android is the primary target.

## Commands

```sh
flutter pub get
flutter run
flutter analyze                                  # lints: package:flutter_lints
flutter test                                     # all tests
flutter test test/add_widget_test.dart           # single file
flutter test --plain-name "<test name>"          # single test
dart run build_runner build --delete-conflicting-outputs   # regenerate Drift code
flutter build apk --release
```

`lib/database/app_database.g.dart` is generated but committed (CI does not run build_runner). Regenerate and commit it after any change to the tables in `lib/database/models/` or to `AppDatabase`.

Widget tests swap in an in-memory database: `DatabaseService.instance.database = AppDatabase(NativeDatabase.memory())`. Do DB reads/writes inside `tester.runAsync`, and unmount the widget before `db.close()` so its watch streams are cancelled.

## Architecture

- **UI**: `main.dart` → `TabNavigation.dart`, a `NavigationBar` + `IndexedStack` over three tabs in `lib/tabs/` (Add, Statements, Accounts). Modals live in `lib/modals/`, shared widgets in `lib/components/`. State is plain `StatefulWidget` + `StreamBuilder`; there is no state-management package.
- **Data access**: all DB access goes through the `DatabaseService.instance` singleton (`lib/database/database_service.dart`), which lazily creates `AppDatabase`. Widgets subscribe to Drift `watch...()` streams, so writes refresh the UI automatically, with no manual reloads.
- **Schema** (`lib/database/app_database.dart`): tables `Statements`, `Accounts`, `Tags`. `schemaVersion` is 3; bump it and add an `onUpgrade` step for schema changes. Indexes on `payment_date` / `(account, payment_date)` are created via raw SQL in the migration. The DB file lives in the app support directory.
- **Invariants**:
  - `Accounts.balance` is denormalized. Change statements only via `addStatement`/`addStatements`/`updateStatement`/`deleteStatement`, which adjust balances in the same transaction with an SQL-side increment (`_addToBalance`). Any new write path for statements must do the same.
  - `Statements.tags` is a comma-joined string via `ListConverter`, so tags must not contain commas.
  - Monthly/yearly totals (`watchTotals`) are aggregated in SQLite and grouped by local time, not UTC.
- **Statements list** is an accordion of months (`watchTotals`); an expanded month loads its statements via `watchStatementsBetween` and shows them grouped by day (`groupByDay`).

## CI

`.github/workflows/checks.yml` runs on PRs only: `dart format --set-exit-if-changed lib test` and `flutter analyze --no-fatal-infos`.

`.github/workflows/build-apk.yml` runs `flutter test`, then builds a release APK (Flutter 3.47.9, Java 17) on pushes to `master`, PRs, and manual dispatch, and uploads it as the `money_mind-apk` artifact. Release builds are still signed with debug keys (`android/app/build.gradle.kts`).
