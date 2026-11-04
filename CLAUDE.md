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
- **Schema** (`lib/database/app_database.dart`): tables `Statements`, `Accounts`, `Tags`, `Recurrences`, `Settings` (key/value, read and written via `features/settings/app_settings.dart`). `schemaVersion` is 9. For a schema change, bump it and add `lib/database/migrations/v<N>.dart` with a `migrateToV<N>` function, called from `onUpgrade`; add columns with `addColumnIfMissing` (`migrations/add_column.dart`), since a cut-short upgrade may run again. Indexes on `payment_date` / `(account, payment_date)` (`migrations/v2.dart`) and `(recurrence, payment_date, id)` (`migrations/v8.dart`) are created via raw SQL, which `onCreate` also runs. The DB file lives in the app support directory.
- **Invariants**:
  - `Accounts.balance` is denormalized. Change statements only via `addStatement`/`addStatements`/`updateStatement`/`deleteStatement`, which adjust balances in the same transaction with an SQL-side increment (`_addToBalance`). Any new write path for statements must do the same.
  - `Statements.tags` is a comma-joined string via `ListConverter`, so tags must not contain commas. A child tag is named `Parent : Child` (`DatabaseService.tagSeparator`), one level deep; the tag dialog builds that name from a parent dropdown, so users never type the separator. Filtering by a parent matches its children, the tag picker and Manage tags nest them, and deleting a parent makes its children top-level.
  - Monthly/yearly totals (`watchTotals`) are aggregated in SQLite and grouped by local time, not UTC.
- **Statements list** is an accordion of months (`watchTotals`); an expanded month loads its statements via `watchStatementsBetween` and shows them grouped by day (`groupByDay`). Without a `month` or `header`, it opens at today: future months sit above the center sliver of its `CustomScrollView`, and it scrolls today's date to mid-screen once the current month's days load.

## Pull requests

Every PR bumps `version` in `pubspec.yaml` (Android's `versionName` and the About screen): minor for features, patch for fixes, e.g. `1.0.0` → `1.1.0`. It has no `+build` part; CI sets the build number (`versionCode`) to the run number. Do it in the PR's own branch, in a commit before pushing, on top of the version of the PR it is based on.

PRs are stacked with GitHub stacked PRs (`gh stack`, the `github/gh-stack` extension). Before starting a change, check the open PRs (`gh pr list`, `gh stack view`): with an open stack, `gh stack top`, then `gh stack add <branch>` for the new change, commit, and `gh stack submit --auto --open`; with none, `gh stack init <branch>` from an up-to-date `master`. After a PR of the stack merges or `master` moves, `gh stack sync` rebases the rest and force-pushes it. `gh stack merge` merges the stack bottom-up in one go, only when the user says so (like `gh pr merge`, it always asks). The working tree may hold the user's uncommitted changes; leave them out of commits.

### Screenshots

A PR with a visible change (feature or bug fix) shows it in its description, under `## Screenshots`, noting that the data is invented. A bug fix shows before and after, running the same test on the base branch too. Skip it for changes with nothing to see.

The repo is public and the emulator holds the user's data, so never publish emulator screenshots. Render them from invented data instead:

1. Write a temporary widget test, `test/pr_screenshots_test.dart`, that seeds an in-memory database with invented data, pumps `MoneyMind`, navigates to the change and captures each state. Do not commit it. Read every PNG to check it before publishing.

   ```dart
   // Tests render the Ahem font unless the real ones are loaded, before pumping.
   // They are in <flutter root>/bin/cache/artifacts/material_fonts.
   Future<void> font(String family, List<String> files) async {
     final loader = FontLoader(family);
     for (final f in files) {
       final bytes = await File('$fonts/$f').readAsBytes();
       loader.addFont(Future.value(ByteData.sublistView(bytes)));
     }
     await loader.load();
   }
   // In tester.runAsync: font('Roboto', ['roboto-regular.ttf', 'roboto-medium.ttf',
   // 'roboto-bold.ttf', 'roboto-light.ttf']), font('MaterialIcons',
   // ['materialicons-regular.otf']), setThemeMode(ThemeMode.dark).
   // Set debugDisableShadows = false (back to true before the test ends),
   // tester.view.physicalSize = const Size(720, 1616), devicePixelRatio = 1.75.

   Future<void> shot(String name) async {
     final layer = tester.binding.renderView.debugLayer! as OffsetLayer;
     await tester.runAsync(() async {
       final image = await layer.toImage(tester.binding.renderView.paintBounds);
       final png = await image.toByteData(format: ui.ImageByteFormat.png);
       await File('$out/$name.png').writeAsBytes(png!.buffer.asUint8List());
     });
   }
   ```

   Before each `shot`, alternate `tester.runAsync(() => Future<void>.delayed(...))` with `tester.pump(...)` a few times, so database streams and animations settle. Save the PNGs to the scratchpad.

2. Publish to the `pr-screenshots` branch, which has only images and never merges, so they stay out of `master` and its history:

   ```sh
   git fetch origin pr-screenshots:pr-screenshots
   git worktree add <scratchpad>/pr-shots pr-screenshots
   # copy the PNGs to <scratchpad>/pr-shots/<pr number>/, then commit and push from there
   git worktree remove <scratchpad>/pr-shots
   ```

3. Add them to the description with `gh pr edit`, at a fixed width so they line up. Link the pushed commit (`git rev-parse pr-screenshots`), not the branch: the branch URL can serve a cached 404, or an old image after a replacement:

   ```html
   <img src="https://raw.githubusercontent.com/Tag365/money_mind/<commit sha>/<pr number>/<name>.png" width="240" alt="...">
   ```

The PR number exists only after `gh stack submit`, so this comes after it. `gh stack submit` can rewrite the description, so check that the images are still there at the end.

Do not enable auto-merge when creating a PR; there may still be work to do. Only once the user says the PR is done, run `gh pr merge <number> --auto --squash` (`.claude/settings.json` makes `gh pr merge` always ask). The "PR Required Checks" ruleset on `master` holds it until the `build` and `checks` jobs pass.

## CI

`.github/workflows/checks.yml` runs on PRs only: `dart format --set-exit-if-changed lib test` and `flutter analyze --no-fatal-infos`.

`.github/workflows/build-apk.yml` runs `flutter test`, then builds a release APK (Flutter 3.47.9, Java 17) on pushes to `master`, PRs, and manual dispatch, and uploads it as the `money_mind-apk` artifact. It signs with the keystore from the `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_PASSWORD` and `KEY_ALIAS` secrets, written to `android/key.properties` and read in `android/app/build.gradle.kts` (without that file the debug key is used, so fork PRs still build), with `github.run_number` as the build number. On `master` it publishes the APK as a GitHub Release tagged `v<version>+<run_number>`, for Obtainium. A push to `master` first runs the `promote` job: when the merged PR (from this repo, not a fork) was built from the same tree, it publishes that PR run's APK, tagged with that run's number, and the `build` job is skipped; otherwise `build` builds and publishes as before.
