import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/database/models/account_type.dart';
import 'package:money_mind/features/accounts/settle.dart';

void main() {
  test('the last billing period ends the day after the closing day', () {
    // Closes on the 15th: on Nov 15 that period is still running.
    expect(lastPeriodEnd(15, DateTime(2026, 11, 1)), DateTime(2026, 10, 16));
    expect(
      lastPeriodEnd(15, DateTime(2026, 11, 15, 12)),
      DateTime(2026, 10, 16),
    );
    expect(lastPeriodEnd(15, DateTime(2026, 11, 16)), DateTime(2026, 11, 16));
    expect(lastPeriodEnd(15, DateTime(2026, 1, 5)), DateTime(2025, 12, 16));
    // Null is the last day, and a day past a month's end clamps to it.
    expect(lastPeriodEnd(null, DateTime(2026, 11, 1, 13)), DateTime(2026, 11));
    expect(lastPeriodEnd(31, DateTime(2026, 3, 10)), DateTime(2026, 3));
  });

  test('the amount due leaves out later charges but not payments', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final service = DatabaseService.instance..database = db;
    final giro = await service.addAccount('Giro', AccountType.debit);
    final card = await service.addAccount(
      'Visa',
      AccountType.creditCard,
      closingDay: 15,
    );
    final before = DateTime(2026, 10, 10);
    final after = DateTime(2026, 10, 20);
    final periodEnd = DateTime(2026, 10, 16);
    await service.addStatement('Shop', -100, card, before, before, [], '');
    await service.addStatement('Train', -30, card, after, after, [], '');
    expect(await service.lastTransferSource(card), isNull);

    final accounts = {
      for (final a in await db.select(db.accounts).get()) a.id: a,
    };
    await service.addTransfer(accounts[giro]!, accounts[card]!, 40, after);

    expect(await service.amountDue(card, periodEnd), 60);
    expect(await service.lastTransferSource(card), giro);
    expect(accounts[card]!.closingDay, 15);
    await db.close();
  });

  test('the v9 upgrade can run again after being cut short', () async {
    final db = AppDatabase(NativeDatabase.memory());
    await db.select(db.accounts).get(); // opens and creates v9
    // ignore: invalid_use_of_protected_member
    await db.migration.onUpgrade(db.createMigrator(), 8, 9);
    await db.close();
  });
}
