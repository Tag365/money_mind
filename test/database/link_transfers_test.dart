import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/database/link_transfers.dart';
import 'package:money_mind/database/models/account_type.dart';

void main() {
  test('links matching transfer sides, nearest first', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final service = DatabaseService.instance..database = db;
    final bank = await service.addAccount('Bank', AccountType.debit);
    final card = await service.addAccount('Card', AccountType.debit);
    final day = DateTime(2026, 10, 5);
    const transfer = [DatabaseService.transferTag];
    Future<void> add(
      String title,
      double amount,
      int account, [
      DateTime? on,
    ]) => service.addStatement(
      title,
      amount,
      account,
      on ?? day,
      on ?? day,
      title.startsWith('plain') ? const [] : transfer,
      '',
    );
    await add('out 1', -50, bank);
    await add('in 1', 50, card);
    await add('out 2', -50, bank);
    await add('in 2', 50, card);
    await add('same account', 20, bank);
    await add('same account out', -20, bank);
    await add('other day', 30, card, DateTime(2026, 10, 6));
    await add('other day out', -30, bank);
    await add('plain', 10, card);
    await add('plain out', -10, bank);

    expect(await linkTransfers(db), 2);

    final byTitle = {
      for (final s in await db.select(db.statements).get()) s.title: s,
    };
    int? partner(String title) => byTitle[title]!.transfer;
    expect(partner('out 1'), byTitle['in 1']!.id);
    expect(partner('in 1'), byTitle['out 1']!.id);
    expect(partner('out 2'), byTitle['in 2']!.id);
    for (final title in [
      'same account',
      'same account out',
      'other day',
      'other day out',
      'plain',
      'plain out',
    ]) {
      expect(partner(title), isNull, reason: title);
    }
    // Already linked ones stay as they are.
    expect(await linkTransfers(db), 0);
    await db.close();
  });
}
