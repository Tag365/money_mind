import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:money_mind/database/models/account_type.dart';
import 'package:money_mind/database/models/list_converter.dart';
import 'package:money_mind/database/models/recurrences.dart';
import 'package:money_mind/database/migrations/v2.dart';
import 'package:money_mind/database/migrations/v3.dart';
import 'package:money_mind/database/migrations/v4.dart';
import 'package:money_mind/database/migrations/v5.dart';
import 'package:money_mind/database/migrations/v6.dart';
import 'package:money_mind/database/migrations/v7.dart';
import 'package:money_mind/database/migrations/v8.dart';

import 'models/accounts.dart';
import 'models/statements.dart';
import 'models/settings.dart';
import 'models/tags.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Statements, Accounts, Tags, Recurrences, Settings])
class AppDatabase extends _$AppDatabase {
  // Tests pass NativeDatabase.memory().
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      // Indexes are not part of the tables.
      await migrateToV2(this, m);
      await migrateToV8(this, m);
    },
    // One file per version in migrations/.
    onUpgrade: (m, from, to) async {
      if (from < 2) await migrateToV2(this, m);
      if (from < 3) await migrateToV3(this, m);
      if (from < 4) await migrateToV4(this, m);
      if (from < 5) await migrateToV5(this, m);
      if (from < 6) await migrateToV6(this, m);
      if (from < 7) await migrateToV7(this, m);
      if (from < 8) await migrateToV8(this, m);
    },
  );

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
