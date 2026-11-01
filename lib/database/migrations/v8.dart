import 'package:drift/drift.dart';
import 'package:money_mind/database/app_database.dart';

/// v8: index for "newest statement of a series" (upcoming payments,
/// contracts). Without it that lookup scans every statement once per
/// statement, which takes minutes with tens of thousands of them. New
/// databases need it too, so onCreate runs this as well.
Future<void> migrateToV8(AppDatabase db, Migrator m) async {
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_statements_recurrence '
    'ON statements (recurrence, payment_date, id)',
  );
}
