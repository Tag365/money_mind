import 'package:drift/drift.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/link_transfers.dart';

/// v10: links the transfers the MoneyWise import left unlinked, so they no
/// longer count as expenses and income.
Future<void> migrateToV10(AppDatabase db, Migrator m) async {
  await linkTransfers(db);
}
