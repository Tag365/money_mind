import 'package:drift/drift.dart';
import 'package:money_mind/database/app_database.dart';

/// v3: tag colors.
Future<void> migrateToV3(AppDatabase db, Migrator m) async {
  await m.addColumn(db.tags, db.tags.color);
}
