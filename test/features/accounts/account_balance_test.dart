import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/database/models/account_type.dart';

void main() {
  test('account balances leave out future statements', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final service = DatabaseService.instance..database = db;
    final cash = await service.addAccount('Cash', AccountType.debit);
    final empty = await service.addAccount('Empty', AccountType.debit);
    final past = DateTime.now().subtract(const Duration(days: 1));
    final future = DateTime.now().add(const Duration(days: 3));
    await service.addStatement('Salary', 1000, cash, past, past, [], '');
    await service.addStatement('Rent', -800, cash, future, future, [], '');

    final balances = {
      for (final a in await service.watchAccounts().first) a.id: a.balance,
    };
    expect(balances, {cash: 1000, empty: 0});
    // The stored balance still contains everything booked.
    expect((await service.getAccountById(cash)).balance, 200);
    await db.close();
  });

  test('recheckDates reruns the balances once a statement falls due', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final service = DatabaseService.instance..database = db;
    final cash = await service.addAccount('Cash', AccountType.debit);
    // Stored in whole seconds, so due within about two.
    final soon = DateTime.now().add(const Duration(seconds: 1));
    await service.addStatement('Salary', 1000, cash, soon, soon, [], '');

    final emitted = <double>[];
    final subscription = service.watchAccounts().listen(
      (accounts) => emitted.add(accounts.single.balance),
    );
    await Future<void>.delayed(const Duration(milliseconds: 2100));
    service.recheckDates();
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(emitted, [0, 1000]);
    await subscription.cancel();
    await db.close();
  });
}
