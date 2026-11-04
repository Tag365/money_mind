import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/database/models/account_type.dart';
import 'package:money_mind/features/settings/csv_export.dart';
import 'package:money_mind/features/settings/moneywise_import.dart';

void main() {
  late AppDatabase db;
  final service = DatabaseService.instance;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    service.database = db;
  });

  tearDown(() => db.close());

  test('writes every statement oldest first, readable as CSV', () async {
    final giro = await service.addAccount('Giro, main', AccountType.debit);
    final newer = DateTime(2026, 9, 15, 12, 30);
    final older = DateTime(2026, 8, 1, 8, 5);
    await service.addStatement('Lunch', -12.5, giro, newer, newer, [
      'Food',
      'Food : Out',
    ], 'said "hi"\nand left');
    await service.addStatement('Salary', 2000, giro, older, older, [], '');

    final bytes = await exportCsv();

    // utf8.decode drops the byte order mark, so look for it in the bytes.
    expect(bytes.take(3), [0xEF, 0xBB, 0xBF]);
    expect(parseCsv(utf8.decode(bytes)), [
      ['Date', 'Title', 'Amount', 'Account', 'Tags', 'Note'],
      ['2026-08-01 08:05', 'Salary', '2000.00', 'Giro, main', '', ''],
      [
        '2026-09-15 12:30',
        'Lunch',
        '-12.50',
        'Giro, main',
        'Food, Food : Out',
        'said "hi"\nand left',
      ],
    ]);
  });

  test('neutralizes formulas in text but keeps negative amounts', () async {
    final giro = await service.addAccount('Giro', AccountType.debit);
    final date = DateTime(2026, 9, 15);
    await service.addStatement('=1+1', -5, giro, date, date, [], '@SUM(A1)');

    final row = parseCsv(utf8.decode(await exportCsv())).last;

    expect(row[1], "'=1+1");
    expect(row[2], '-5.00');
    expect(row[5], "'@SUM(A1)");
  });

  test('an empty database gives just the header', () async {
    final rows = parseCsv(utf8.decode(await exportCsv()));
    expect(rows.single.first, 'Date');
  });
}
