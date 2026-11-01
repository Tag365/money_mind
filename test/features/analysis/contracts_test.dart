import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/database/models/account_type.dart';
import 'package:money_mind/database/models/recurrences.dart';
import 'package:money_mind/features/analysis/contracts.dart';
import 'package:money_mind/features/analysis/tag_breakdown.dart';

void main() {
  test('lists each series once, with its monthly amount', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final service = DatabaseService.instance..database = db;
    final bank = await service.addAccount('Bank', AccountType.debit);

    Future<void> repeat(
      String title,
      double amount,
      List<String> tags,
      RecurrenceUnit unit,
      int every,
    ) async {
      final paid = DateTime(2026, 8, 15);
      final s = await service.addStatement(
        title,
        amount,
        bank,
        paid,
        paid,
        tags,
        '',
      );
      await service.setRecurrence(s, unit, every);
    }

    await repeat('Rent', -800, ['Home'], RecurrenceUnit.month, 1);
    await repeat(
      'Insurance',
      -120,
      ['Home : Insurance'],
      RecurrenceUnit.year,
      1,
    );
    await repeat('Gym', -14, ['Sport'], RecurrenceUnit.week, 2);
    await repeat('Salary', 3000, ['Salary'], RecurrenceUnit.month, 1);
    final once = DateTime(2026, 8, 20);
    await service.addStatement('Once', -50, bank, once, once, ['Home'], '');

    final contracts = await service.watchContracts().first;
    final byTitle = {for (final c in contracts) c.statement.title: c};
    expect(
      byTitle.keys,
      unorderedEquals(['Rent', 'Insurance', 'Gym', 'Salary']),
    );

    // The newest occurrence stands for the series.
    final rents = (await db.select(db.statements).get()).where(
      (s) => s.title == 'Rent',
    );
    expect(rents.length, greaterThan(1));
    expect(
      byTitle['Rent']!.statement.paymentDate,
      rents.map((s) => s.paymentDate).reduce((a, b) => a.isAfter(b) ? a : b),
    );

    expect(monthlyAmount(byTitle['Rent']!), -800);
    expect(monthlyAmount(byTitle['Insurance']!), -10);
    expect(monthlyAmount(byTitle['Gym']!), closeTo(-30.44, 0.01));
    expect(monthlyAmount(byTitle['Salary']!), 3000);

    final totals = monthlyTotals(contracts);
    final shares = tagBreakdown(totals, income: false);
    expect(shares.map((s) => s.tag), ['Home', 'Sport']);
    expect(shares.first.amount, -810);
    expect(shares.last.amount, closeTo(-30.44, 0.01));
    expect(contractGroup(byTitle['Insurance']!), 'Home');
    await db.close();
  });
}
