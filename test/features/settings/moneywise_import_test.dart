import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/features/settings/moneywise_import.dart';

const _csv =
    '﻿id,Date,Category,Description,Tags,Type,Amount,Currency,Account,Account balance (EUR),Cleared,Amount in EUR,Note\r\n'
    '4522,2026-10-14,"Uncategorized","Amex Abrechnung Oktober ","Amex, Transfer",Expense,"-1106,21",EUR,"C24 Bank","3843,69",Yes,"-1106,21",""\r\n'
    '4421,2026-10-14,"monatliche Kosten","Netflix Abo","Überweisung, Girokarte",Expense,"-15,99",EUR,"Amex","-1122,20",Yes,"-15,99",""\r\n'
    '4549,2026-10-11,"Auto : Laden/Spritt","Auto Laden Jet","",Expense,"-19,73",EUR,"Trade Republic","3874,41",Yes,"-19,73","Jet, ""A7""\nKassel"\r\n'
    '4514,2026-10-05,"ATransfer","Transfer","",Income,"1000,00",EUR,"Trade Republic","4011,10",Yes,"1000,00",""\r\n'
    '4513,2026-10-05,"ATransfer","Transfer","",Expense,"-1000,00",EUR,"C24 Bank","4996,61",Yes,"-1000,00",""\r\n'
    '4512,2026-10-05,"Einkauf","Ionity Subscription","Einmalige Kosten",Expense,"-11,99",EUR,"Trade Republic","3011,10",Yes,"-11,99",""\r\n';

void main() {
  late AppDatabase db;
  setUp(
    () => DatabaseService.instance.database = db = AppDatabase(
      NativeDatabase.memory(),
    ),
  );
  tearDown(() => db.close());

  test('imports accounts, tags and statements', () async {
    expect(await importMoneyWise(_csv), 6);

    final accounts = {
      for (final a in await db.select(db.accounts).get()) a.name: a.balance,
    };
    expect(accounts.keys, {'C24 Bank', 'Amex', 'Trade Republic'});
    expect(accounts['C24 Bank'], closeTo(3843.69, 0.001));
    expect(accounts['Amex'], closeTo(-1122.20, 0.001));
    expect(accounts['Trade Republic'], closeTo(3874.41, 0.001));

    final colors = {
      for (final t in await db.select(db.tags).get()) t.name: t.color,
    };
    expect(colors['Auto : Laden/Spritt'], colors['Auto']);
    expect(colors.keys.toSet(), {
      'Amex',
      'Transfer',
      'monatliche Kosten',
      'Überweisung',
      'Girokarte',
      'Auto', // parent of the sub-category, though no row uses it alone
      'Auto : Laden/Spritt',
      'Einkauf',
      'Einmalige Kosten',
      DatabaseService.autoTag,
    });

    final statements = await db.select(db.statements).get();
    expect(statements, hasLength(6 + 3));
    final jet = statements.singleWhere((s) => s.title == 'Auto Laden Jet');
    expect(jet.tags, ['Auto : Laden/Spritt']);
    expect(jet.note, 'Jet, "A7"\nKassel');
    expect(jet.paymentDate, DateTime(2026, 10, 11));
    final amexBill = statements.singleWhere((s) => s.title.startsWith('Amex'));
    expect(amexBill.title, 'Amex Abrechnung Oktober');
    expect(amexBill.tags, ['Amex', 'Transfer']);
    // Same day: the older row gets the lower id.
    final ionity = statements.singleWhere((s) => s.title.startsWith('Ionity'));
    final transferIn = statements.singleWhere((s) => s.amount == 1000);
    expect(ionity.id, lessThan(transferIn.id));
    expect(transferIn.tags, [DatabaseService.transferTag]);
  });

  test('a bad row imports nothing', () async {
    final bad = _csv.replaceFirst(
      '"-15,99",EUR,"Amex","-1122,20",Yes,"-15,99"',
      '"x",EUR,"Amex","-1122,20",Yes,"x"',
    );
    await expectLater(importMoneyWise(bad), throwsFormatException);
    expect(await db.select(db.accounts).get(), isEmpty);
  });

  test('accepts the balance column without currency', () async {
    final csv = _csv.replaceFirst('Account balance (EUR)', 'Account balance');
    expect(await importMoneyWise(csv), 6);
    final c24 = (await db.select(db.accounts).get()).firstWhere(
      (a) => a.name == 'C24 Bank',
    );
    expect(c24.balance, closeTo(3843.69, 0.001));
  });

  test('rejects other CSV files', () async {
    await expectLater(importMoneyWise('a,b\n1,2\n'), throwsFormatException);
  });
}
