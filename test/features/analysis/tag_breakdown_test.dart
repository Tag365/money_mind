import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/database/models/account_type.dart';
import 'package:money_mind/features/analysis/tag_breakdown.dart';

void main() {
  test('breaks a month down by top-level tag and by child', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final service = DatabaseService.instance..database = db;
    final cash = await service.addAccount('Cash', AccountType.values.first);
    final bank = await service.addAccount('Bank', AccountType.values.first);

    Future<void> add(double amount, List<String> tags, [int day = 5]) =>
        service.addStatement(
          't',
          amount,
          cash,
          DateTime(2026, 10, day),
          DateTime(2026, 10, day),
          tags,
          '',
        );
    await add(-30, ['Food : Groceries']);
    await add(-20, ['Food : Groceries']);
    await add(-10, ['Food']);
    await add(-40, ['Car', 'Food']); // first tag counts
    await add(-5, []);
    await add(2000, ['Salary']);
    await add(-99, ['Food'], 31); // October 31 is still in range
    await service.addStatement(
      'next month',
      -1,
      cash,
      DateTime(2026, 11),
      DateTime(2026, 11),
      ['Food'],
      '',
    );
    await service.addTransfer(
      await service.getAccountById(cash),
      await service.getAccountById(bank),
      100,
      DateTime(2026, 10, 6),
    );

    final totals = await service
        .watchTagTotals(DateTime(2026, 10), DateTime(2026, 11))
        .first;

    expect(tagBreakdown(totals, income: false), [
      (tag: 'Food', amount: -159.0),
      (tag: 'Car', amount: -40.0),
      (tag: untagged, amount: -5.0),
    ]);
    expect(tagBreakdown(totals, income: false, parent: 'Food'), [
      (tag: 'Food', amount: -109.0),
      (tag: 'Food : Groceries', amount: -50.0),
    ]);
    expect(tagBreakdown(totals, income: true), [
      (tag: 'Salary', amount: 2000.0),
    ]);
    await db.close();
  });
}
