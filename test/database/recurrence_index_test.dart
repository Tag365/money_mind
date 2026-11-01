import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_mind/database/app_database.dart';

void main() {
  Future<bool> hasIndex(AppDatabase db) async =>
      (await db
              .customSelect(
                "SELECT 1 FROM sqlite_master WHERE name = 'idx_statements_recurrence'",
              )
              .get())
          .isNotEmpty;

  test('new and upgraded databases index statements by series', () async {
    final db = AppDatabase(NativeDatabase.memory());
    expect(await hasIndex(db), isTrue);

    await db.customStatement('DROP INDEX idx_statements_recurrence');
    // ignore: invalid_use_of_protected_member
    await db.migration.onUpgrade(db.createMigrator(), 7, 8);
    expect(await hasIndex(db), isTrue);
    // A cut-short upgrade may run again.
    // ignore: invalid_use_of_protected_member
    await db.migration.onUpgrade(db.createMigrator(), 7, 8);

    // The newest-of-series lookup searches the index instead of scanning.
    final plan = await db
        .customSelect(
          'EXPLAIN QUERY PLAN SELECT id FROM statements l '
          'WHERE l.recurrence = 1 ORDER BY l.payment_date DESC, l.id DESC '
          'LIMIT 1',
        )
        .get();
    expect(
      plan.map((r) => r.read<String>('detail')).join(' '),
      contains('idx_statements_recurrence'),
    );
    await db.close();
  });
}
