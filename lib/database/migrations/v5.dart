import 'package:drift/drift.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/migrations/add_column.dart';

/// v5: transfers link their two statements.
Future<void> migrateToV5(AppDatabase db, Migrator m) async {
  await addColumnIfMissing(db, m, db.statements, db.statements.transfer);
}
