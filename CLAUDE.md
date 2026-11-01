# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Money Mind is a Flutter personal-finance tracker (accounts + statements) backed by a local SQLite database via Drift. Android is the primary target.

## Commands

```sh
flutter pub get
flutter run
flutter analyze                                  # lints: package:flutter_lints
flutter test                                     # all tests
flutter test test/features/statements/add_widget_test.dart   # single file
flutter test --plain-name "<test name>"          # single test
dart run build_runner build --delete-conflicting-outputs   # regenerate Drift code
flutter build apk --release
```

`lib/database/app_database.g.dart` is generated but committed (CI does not run build_runner). Regenerate and commit it after any change to the tables in `lib/database/models/` or to `AppDatabase`.

After every Dart code change, hot reload the running app; for UI changes, also check them on the emulator with screenshots. Both steps are in the `check-app` skill (`.claude/skills/check-app/SKILL.md`).

Widget tests swap in an in-memory database: `DatabaseService.instance.database = AppDatabase(NativeDatabase.memory())`. Do DB reads/writes inside `tester.runAsync`, and unmount the widget before `db.close()` so its watch streams are cancelled, then pump a nonzero duration (or `pumpAndSettle`): Drift closes them on a zero timer, and a bare `pump()` leaves it pending, so `db.close()` in `tearDown` hangs.

## Architecture

- **Layout**: feature-first. `lib/features/{home,analysis,statements,accounts,tags}/` hold each feature's tabs, forms, sheets and dialogs, with the widgets they are built from in a `widgets/` subfolder (one public widget class per file; prefer widget classes over `Widget _buildX()` methods); `lib/common/` holds code shared by several features (`MoneyText`/`formatMoney`, `evaluateAmount`, `GlassBackground`); `lib/database/` is shared by all features. `test/` mirrors `lib/`.
- **UI**: `main.dart` → `app/tab_navigation.dart`, a `NavigationBar` + `IndexedStack` over four tabs, each with its own `Scaffold`/`AppBar` wrapped in `GlassBackground` (gradient, glassy cards): `HomeWidget` (`home/home_tab.dart`, the default), `AddWidget` (`statements/add_statement.dart`), `ListWidget` (`statements/statement_list.dart`), `AccountWidget` (`accounts/accounts_tab.dart`). State is plain `StatefulWidget` + `StreamBuilder`; there is no state-management package.
- **Data access**: all DB access goes through the `DatabaseService.instance` singleton (`lib/database/database_service.dart`), which lazily creates `AppDatabase`. Widgets subscribe to Drift `watch...()` streams, so writes refresh the UI automatically, with no manual reloads.
- **Schema** (`lib/database/app_database.dart`): tables `Statements`, `Accounts`, `Tags`, `Recurrences`, `Settings` (key/value, read and written via `features/settings/app_settings.dart`). `schemaVersion` is 8. For a schema change, bump it and add `lib/database/migrations/v<N>.dart` with a `migrateToV<N>` function, called from `onUpgrade`; add columns with `addColumnIfMissing` (`migrations/add_column.dart`), since a cut-short upgrade may run again. Indexes on `payment_date` / `(account, payment_date)` (`migrations/v2.dart`) and `(recurrence, payment_date, id)` (`migrations/v8.dart`) are created via raw SQL, which `onCreate` also runs. The DB file lives in the app support directory.
- **Invariants**:
  - `Accounts.balance` is denormalized. Change statements only via `addStatement`/`addStatements`/`updateStatement`/`deleteStatement`, which adjust balances in the same transaction with an SQL-side increment (`_addToBalance`). Any new write path for statements must do the same.
  - `Statements.tags` is a comma-joined string via `ListConverter`, so tags must not contain commas. A child tag is named `Parent : Child` (`DatabaseService.tagSeparator`); filtering by a parent matches its children, and the tag picker nests them.
  - Monthly/yearly totals (`watchTotals`) are aggregated in SQLite and grouped by local time, not UTC.
- **Statements list** is an accordion of months (`watchTotals`); an expanded month loads its statements via `watchStatementsBetween` and shows them grouped by day (`groupByDay`).

## Pull requests

Every PR bumps `version` in `pubspec.yaml` (`name+build`, the single source for Android's `versionName`/`versionCode` and the About screen): build number +1 always; minor for features, patch for fixes, e.g. `1.0.0+1` → `1.1.0+2`. Do it in the PR's own branch, in a commit before pushing.

## CI

`.github/workflows/checks.yml` runs on PRs only: `dart format --set-exit-if-changed lib test` and `flutter analyze --no-fatal-infos`.

`.github/workflows/build-apk.yml` runs `flutter test`, then builds a release APK (Flutter 3.47.9, Java 17) on pushes to `master`, PRs, and manual dispatch, and uploads it as the `money_mind-apk` artifact. Release builds are still signed with debug keys (`android/app/build.gradle.kts`).
