import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/database/models/AccountType.dart';
import 'package:money_mind/list/statement_filter.dart';

void main() {
  late AppDatabase db;
  late DatabaseService service;
  late int cash;
  late int bank;
  final start = DateTime(2026, 9);
  final end = DateTime(2026, 10);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    service = DatabaseService.instance..database = db;
    cash = await service.addAccount('Cash', AccountType.values.first);
    bank = await service.addAccount('Bank', AccountType.values.first);
    final date = DateTime(2026, 9, 15);
    Future<void> add(
      String title,
      double amount,
      int account,
      List<String> tags, [
      String note = '',
    ]) => service.addStatement(title, amount, account, date, date, tags, note);
    await add('Breakfast', -3, cash, ['Einkauf']);
    await add('Salary', 3000, bank, ['Einkommen']);
    await add('Plaster', -5, cash, ['Ein', 'Gesundheit']);
    await add('100% refund', 10, bank, [], 'from shop');
  });

  tearDown(() => db.close());

  Future<List<String>> titles(StatementFilter filter) async {
    final statements = await service
        .watchStatementsBetween(start, end, filter: filter)
        .first;
    return [for (final s in statements) s.title]..sort();
  }

  test('no filter shows everything', () async {
    expect(await titles(const StatementFilter()), hasLength(4));
  });

  test('accounts', () async {
    expect(await titles(StatementFilter(accounts: {bank})), [
      '100% refund',
      'Salary',
    ]);
  });

  test('tags match whole entries only', () async {
    expect(await titles(const StatementFilter(tags: {'Ein'})), ['Plaster']);
    expect(await titles(const StatementFilter(tags: {'Ein', 'Einkommen'})), [
      'Plaster',
      'Salary',
    ]);
  });

  test('excluded tags', () async {
    expect(
      await titles(const StatementFilter(tags: {'Ein'}, excludeTags: true)),
      ['100% refund', 'Breakfast', 'Salary'],
    );
  });

  test('income or expense', () async {
    expect(await titles(const StatementFilter(expense: true)), [
      'Breakfast',
      'Plaster',
    ]);
    expect(await titles(const StatementFilter(income: true)), [
      '100% refund',
      'Salary',
    ]);
    expect(
      await titles(const StatementFilter(income: true, expense: true)),
      hasLength(4),
    );
  });

  test('text search in title and note, wildcards literal', () async {
    expect(await titles(const StatementFilter(text: 'salary')), ['Salary']);
    expect(await titles(const StatementFilter(text: 'shop')), ['100% refund']);
    expect(await titles(const StatementFilter(text: '0%')), ['100% refund']);
    expect(await titles(const StatementFilter(text: '_')), isEmpty);
  });

  test('monthly totals use the filter', () async {
    final totals = await service
        .watchTotals(yearly: false, filter: StatementFilter(accounts: {cash}))
        .first;
    expect(totals.single.total, -8);
    expect(totals.single.count, 2);
  });
}
