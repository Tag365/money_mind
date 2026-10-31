import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/database/models/account_type.dart';

void main() {
  test('a transfer moves the amount between balances', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final service = DatabaseService.instance..database = db;
    final income = await service.addAccount('Income', AccountType.debit);
    final savings = await service.addAccount('Savings', AccountType.debit);
    final date = DateTime(2026, 10, 1);
    await service.addStatement('Salary', 1000, income, date, date, [], '');

    for (var i = 0; i < 2; i++) {
      await service.addTransfer(
        await service.getAccountById(income),
        await service.getAccountById(savings),
        150,
        date,
      );
    }

    expect((await service.getAccountById(income)).balance, 700);
    expect((await service.getAccountById(savings)).balance, 300);
    final transfers = (await db.select(db.statements).get()).skip(1);
    expect(transfers.map((s) => s.title), [
      'Transfer to Savings',
      'Transfer from Income',
      'Transfer to Savings',
      'Transfer from Income',
    ]);
    expect(transfers.every((s) => s.tags.contains('Transfer')), isTrue);
    // The tag is created once, so it shows up in the filter sheet.
    expect((await db.select(db.tags).get()).map((t) => t.name), ['Transfer']);
    await db.close();
  });

  test('editing or deleting one side changes the other', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final service = DatabaseService.instance..database = db;
    final income = await service.addAccount('Income', AccountType.debit);
    final savings = await service.addAccount('Savings', AccountType.debit);
    await service.addTransfer(
      await service.getAccountById(income),
      await service.getAccountById(savings),
      100,
      DateTime(2026, 10, 1),
    );
    final [out, into] = await db.select(db.statements).get();
    expect((out.transfer, into.transfer), (into.id, out.id));

    final later = DateTime(2026, 10, 5);
    await service.updateStatement(
      into.copyWith(amount: 250, paymentDate: later, title: 'Savings'),
    );
    final [newOut, newInto] = await db.select(db.statements).get();
    expect((newOut.amount, newOut.paymentDate), (-250, later));
    expect(newOut.title, 'Transfer to Savings');
    expect((newInto.transfer, newOut.transfer), (out.id, into.id));
    expect((await service.getAccountById(income)).balance, -250);
    expect((await service.getAccountById(savings)).balance, 250);

    // A stale copy still deletes the stored amounts of both sides.
    await service.deleteStatement(out);
    await service.deleteStatement(out);
    expect(await db.select(db.statements).get(), isEmpty);
    expect((await service.getAccountById(income)).balance, 0);
    expect((await service.getAccountById(savings)).balance, 0);
    await db.close();
  });
}
