import 'package:drift/drift.dart';
import 'package:money_mind/database/app_database.dart';

/// v7: app settings.
Future<void> migrateToV7(AppDatabase db, Migrator m) async {
  await m.createTable(db.settings);
}
