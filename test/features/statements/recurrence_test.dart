import 'package:drift/drift.dart' show OrderingTerm;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/database/models/account_type.dart';
import 'package:money_mind/database/models/recurrences.dart';

void main() {
  test('monthly steps clamp to short months without drifting', () {
    final start = DateTime(2026, 1, 31, 9, 30);
    final dates = [
      for (var n = 0; n < 4; n++) RecurrenceUnit.month.occurrence(start, 1, n),
    ];
    expect(dates, [
      DateTime(2026, 1, 31, 9, 30),
      DateTime(2026, 2, 28, 9, 30),
      DateTime(2026, 3, 31, 9, 30),
      DateTime(2026, 4, 30, 9, 30),
    ]);
    expect(
      RecurrenceUnit.year.occurrence(DateTime(2028, 2, 29), 1, 1),
      DateTime(2029, 2, 28),
    );
    expect(
      RecurrenceUnit.week.occurrence(start, 2, 1),
      DateTime(2026, 2, 14, 9, 30),
    );
  });

  test('creates due occurrences once and keeps balances right', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final service = DatabaseService.instance..database = db;
    final bank = await service.addAccount('Bank', AccountType.debit);
    final paid = DateTime(2026, 8, 15, 8);
    await service.addStatement('Rent', -800, bank, paid, paid, ['Home'], '');
    final rent = (await db.select(db.statements).get()).single;

    await service.setRecurrence(rent, RecurrenceUnit.month, 1);
    // Runs again with the real clock; must not duplicate anything.
    await service.addDueRecurrences(at: DateTime(2026, 10, 31));
    await service.addDueRecurrences(at: DateTime(2026, 10, 31));

    final all = await (db.select(
      db.statements,
    )..orderBy([(t) => OrderingTerm.asc(t.paymentDate)])).get();
    // setRecurrence used DateTime.now(), so at least Sep and Oct exist.
    final until = all.where((s) => !s.paymentDate.isAfter(DateTime(2026, 11)));
    expect(until.map((s) => s.paymentDate), [
      paid,
      DateTime(2026, 9, 15, 8),
      DateTime(2026, 10, 15, 8),
    ]);
    expect(all.map((s) => s.paymentDate).toSet(), hasLength(all.length));
    expect(
      all.every((s) => s.recurrence != null && s.tags.single == 'Home'),
      isTrue,
    );
    expect((await service.getAccountById(bank)).balance, -800.0 * all.length);

    await service.stopRecurrence(all.first.recurrence!);
    await service.addDueRecurrences(at: DateTime(2030));
    expect(await db.select(db.statements).get(), hasLength(all.length));
    expect(await db.select(db.recurrences).get(), isEmpty);
    await db.close();
  });

  test('editing a statement updates the upcoming ones of its series', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final service = DatabaseService.instance..database = db;
    final bank = await service.addAccount('Bank', AccountType.debit);
    final cash = await service.addAccount('Cash', AccountType.debit);
    final now = DateTime.now();
    final paid = DateTime(now.year, now.month - 2, now.day);
    await service.addStatement('Rent', -800, bank, paid, paid, [], '');
    final rent = (await db.select(db.statements).get()).single;
    // Past occurrences plus one created a month ahead.
    await service.setRecurrence(rent, RecurrenceUnit.month, 1);
    final before = await db.select(db.statements).get();
    final pastCount = before.where((s) => !s.paymentDate.isAfter(now)).length;
    final futureCount = before.length - pastCount;
    expect(futureCount, greaterThan(0));

    await service.updateStatement(
      rent.copyWith(title: 'Rent new', amount: -900, account: cash),
    );

    final after = await db.select(db.statements).get();
    final future = after.where((s) => s.paymentDate.isAfter(now));
    expect(
      future.every((s) => s.title == 'Rent new' && s.amount == -900),
      isTrue,
    );
    expect(future.every((s) => s.account == cash), isTrue);
    // Past occurrences other than the edited one stay as they were.
    expect(after.where((s) => s.title == 'Rent'), hasLength(pastCount - 1));
    expect(
      (await service.getAccountById(cash)).balance,
      -900.0 * (futureCount + 1),
    );
    expect(
      (await service.getAccountById(bank)).balance,
      -800.0 * (pastCount - 1),
    );
    await db.close();
  });

  test('moving an upcoming statement earlier counts it once', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final service = DatabaseService.instance..database = db;
    final bank = await service.addAccount('Bank', AccountType.debit);
    final now = DateTime.now();
    final paid = DateTime(now.year, now.month, now.day + 20, 8);
    await service.addStatement('Rent', -800, bank, paid, paid, [], '');
    final rent = (await db.select(db.statements).get()).single;
    await service.setRecurrence(rent, RecurrenceUnit.month, 1);

    final earlier = paid.subtract(const Duration(days: 10));
    await service.updateStatement(
      rent.copyWith(amount: -850, paymentDate: earlier),
    );

    final stored = (await db.select(db.statements).get()).single;
    expect(stored.paymentDate, earlier);
    expect(stored.amount, -850);
    expect((await service.getAccountById(bank)).balance, -850);
    await db.close();
  });

  test('closing an account stops its series but keeps statements', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final service = DatabaseService.instance..database = db;
    final bank = await service.addAccount('Bank', AccountType.debit);
    final paid = DateTime(2026, 8, 15, 8);
    await service.addStatement('Rent', -800, bank, paid, paid, [], '');
    final rent = (await db.select(db.statements).get()).single;
    await service.setRecurrence(rent, RecurrenceUnit.month, 1);
    final count = (await db.select(db.statements).get()).length;

    await service.closeAccount(await service.getAccountById(bank));
    await service.addDueRecurrences(at: DateTime(2030));

    final closed = await service.getAccountById(bank);
    expect(closed.closed, isTrue);
    expect(closed.balance, -800.0 * count);
    expect(await db.select(db.statements).get(), hasLength(count));
    expect(await db.select(db.recurrences).get(), isEmpty);
    await db.close();
  });

  test('a statement of a closed account cannot start a series', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final service = DatabaseService.instance..database = db;
    final bank = await service.addAccount('Bank', AccountType.debit);
    final paid = DateTime(2026, 8, 15, 8);
    await service.addStatement('Rent', -800, bank, paid, paid, [], '');
    await service.closeAccount(await service.getAccountById(bank));
    final rent = (await db.select(db.statements).get()).single;

    await service.setRecurrence(rent, RecurrenceUnit.month, 1);

    expect(await db.select(db.statements).get(), hasLength(1));
    expect(await db.select(db.recurrences).get(), isEmpty);
    await db.close();
  });

  test('creates only one upcoming statement', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final service = DatabaseService.instance..database = db;
    final bank = await service.addAccount('Bank', AccountType.debit);
    final now = DateTime.now();
    final paid = DateTime(now.year, now.month, now.day - 10);
    await service.addStatement('Lunch', -10, bank, paid, paid, [], '');
    final lunch = (await db.select(db.statements).get()).single;

    await service.setRecurrence(lunch, RecurrenceUnit.week, 1);
    await service.addDueRecurrences();

    final all = await db.select(db.statements).get();
    // Day -10 and -3 are due; +4 is the single upcoming one, +11 is not.
    expect(all, hasLength(3));
    expect(all.where((s) => s.paymentDate.isAfter(now)), hasLength(1));
    await db.close();
  });

  test('the v4 upgrade can run again after being cut short', () async {
    final db = AppDatabase(NativeDatabase.memory());
    await db.select(db.recurrences).get(); // opens and creates v4
    // ignore: invalid_use_of_protected_member
    await db.migration.onUpgrade(db.createMigrator(), 3, 4);
    await db.close();
  });

  test('editing a stale copy keeps the series link', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final service = DatabaseService.instance..database = db;
    final bank = await service.addAccount('Bank', AccountType.debit);
    final paid = DateTime.now();
    await service.addStatement('Gym', -30, bank, paid, paid, [], '');
    final stale = (await db.select(db.statements).get()).single;
    await service.setRecurrence(stale, RecurrenceUnit.year, 1);

    await service.updateStatement(stale.copyWith(amount: -35));

    final stored = (await db.select(db.statements).get()).single;
    expect(stored.amount, -35);
    expect(stored.recurrence, isNotNull);
    await db.close();
  });
}
