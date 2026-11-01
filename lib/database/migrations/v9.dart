import 'package:drift/drift.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/migrations/add_column.dart';

/// v9: credit cards have a closing day, for settling them.
Future<void> migrateToV9(AppDatabase db, Migrator m) async {
  await addColumnIfMissing(db, m, db.accounts, db.accounts.closingDay);
}
