import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:money_mind/database/models/AccountType.dart';
import 'package:money_mind/database/models/list_converter.dart';

import 'models/accounts.dart';
import 'models/statements.dart';
import 'models/tags.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Statements, Accounts, Tags])
class AppDatabase extends _$AppDatabase {
  // Tests pass NativeDatabase.memory().
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _createIndexes();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) await _createIndexes();
      if (from < 3) await m.addColumn(tags, tags.color);
    },
  );

  // Indexes for the list (sorted by date) and per-account queries.
  Future<void> _createIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_statements_payment_date '
      'ON statements (payment_date)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_statements_account_payment_date '
      'ON statements (account, payment_date)',
    );
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'my_database',
      native: const DriftNativeOptions(
        // By default, `driftDatabase` from `package:drift_flutter` stores the
        // database files in `getApplicationDocumentsDirectory()`.
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }
}
