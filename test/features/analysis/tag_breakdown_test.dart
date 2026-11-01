import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/database/models/account_type.dart';
import 'package:money_mind/features/analysis/tag_breakdown.dart';
import 'package:money_mind/features/statements/statement_filter.dart';

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
    await add(-40, ['Car', 'Food']);
    await add(-7, ['Food : Groceries', 'Food : Bakery']);
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

    final top = tagBreakdown(totals, income: false);
    // Each statement once, though the one tagged Car and Food counts for both.
    expect(top.total, -211);
    expect(top.shares, [
      (tag: 'Food', amount: -206.0),
      (tag: 'Car', amount: -40.0),
      (tag: untagged, amount: -5.0),
    ]);
    final food = tagBreakdown(totals, income: false, parent: 'Food');
    expect(food.total, -206);
    expect(food.shares, [
      (tag: 'Food', amount: -149.0),
      (tag: 'Food : Groceries', amount: -57.0),
      (tag: 'Food : Bakery', amount: -7.0),
    ]);
    expect(tagBreakdown(totals, income: true).shares, [
      (tag: 'Salary', amount: 2000.0),
    ]);

    // Each row matches the statements its tap lists.
    Future<double> listed(String tag, {String? parent}) async {
      final months = await service
          .watchTotals(
            yearly: false,
            filter: StatementFilter(
              tags: {tag},
              childTags: tag != parent,
              transfers: false,
              expense: true,
            ),
          )
          .first;
      return months.firstWhere((p) => p.month == 10).expense;
    }

    for (final s in top.shares) {
      expect(await listed(s.tag), s.amount, reason: s.tag);
    }
    for (final s in food.shares) {
      expect(await listed(s.tag, parent: 'Food'), s.amount, reason: s.tag);
    }
    await db.close();
  });
}
