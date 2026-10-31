import 'package:drift/drift.dart';
import 'package:money_mind/database/app_database.dart';

/// v2: indexes for the list (sorted by date) and per-account queries.
/// New databases need them too, so onCreate runs this as well.
Future<void> migrateToV2(AppDatabase db, Migrator m) async {
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_statements_payment_date '
    'ON statements (payment_date)',
  );
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_statements_account_payment_date '
    'ON statements (account, payment_date)',
  );
}
