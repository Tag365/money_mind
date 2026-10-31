import 'package:drift/drift.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/migrations/add_column.dart';

/// v4: recurring statements.
Future<void> migrateToV4(AppDatabase db, Migrator m) async {
  await m.createTable(db.recurrences);
  await addColumnIfMissing(db, m, db.statements, db.statements.recurrence);
}
