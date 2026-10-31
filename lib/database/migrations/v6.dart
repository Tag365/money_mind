import 'package:drift/drift.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/migrations/add_column.dart';

/// v6: accounts can be closed instead of deleted.
Future<void> migrateToV6(AppDatabase db, Migrator m) async {
  await addColumnIfMissing(db, m, db.accounts, db.accounts.closed);
}
