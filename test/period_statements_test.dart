import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/database/models/AccountType.dart';
import 'package:money_mind/list/grouping.dart';

void main() {
  test('period statements match the monthly totals at month edges', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final service = DatabaseService.instance..database = db;
    final account = await service.addAccount('Cash', AccountType.values.first);

    Future<void> add(String title, DateTime date) =>
        service.addStatement(title, -1, account, date, date, const [], '');
    await add('last second of Sept', DateTime(2026, 9, 30, 23, 59, 59));
    await add('first of Oct', DateTime(2026, 10, 1));
    await add('first of Sept', DateTime(2026, 9, 1));

    final totals = await service.watchTotals(yearly: false).first;
    final sept = totals.firstWhere((p) => p.month == 9);
    final statements = await service
        .watchStatementsBetween(sept.start, sept.end)
        .first;

    expect(statements.map((s) => s.title), [
      'last second of Sept',
      'first of Sept',
    ]);
    expect(statements.length, sept.count);

    await add('also Sept 30', DateTime(2026, 9, 30, 8));
    final days = groupByDay(
      await service.watchStatementsBetween(sept.start, sept.end).first,
    );
    expect(days.map((d) => d.day), [DateTime(2026, 9, 30), DateTime(2026, 9)]);
    expect(days.map((d) => d.statements.length), [2, 1]);
    expect(days.first.total, -2);

    final year = (await service.watchTotals(yearly: true).first).single;
    expect(year.month, isNull);
    expect(
      (await service.watchStatementsBetween(year.start, year.end).first).length,
      4,
    );
    await db.close();
  });
}
