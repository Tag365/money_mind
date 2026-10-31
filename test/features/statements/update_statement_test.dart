import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/database/models/account_type.dart';

void main() {
  test('editing moves the amount between account balances', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final service = DatabaseService.instance..database = db;
    final cash = await service.addAccount('Cash', AccountType.values.first);
    final bank = await service.addAccount('Bank', AccountType.values.first);
    final paid = DateTime(2026, 9, 15);
    final used = DateTime(2026, 9, 1);
    await service.addStatement('Lunch', -12.5, cash, paid, used, [], '');
    final lunch = (await db.select(db.statements).get()).single;

    await service.updateStatement(
      lunch.copyWith(title: 'Dinner', amount: -30, account: bank),
    );

    final stored = (await db.select(db.statements).get()).single;
    expect(stored.title, 'Dinner');
    expect(stored.useDate, used);
    expect((await service.getAccountById(cash)).balance, 0);
    expect((await service.getAccountById(bank)).balance, -30);

    // Saving again from the stale copy uses the stored row for the balances.
    await service.updateStatement(lunch);
    expect((await service.getAccountById(cash)).balance, -12.5);
    expect((await service.getAccountById(bank)).balance, 0);
    await db.close();
  });
}
