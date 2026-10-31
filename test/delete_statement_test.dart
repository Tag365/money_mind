import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/database/models/AccountType.dart';

void main() {
  test('deleting a statement takes its amount out of the balance', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final service = DatabaseService.instance..database = db;
    final account = await service.addAccount('Cash', AccountType.values.first);
    final date = DateTime(2026, 9, 15);
    await service.addStatement('Salary', 100, account, date, date, [], '');
    await service.addStatement('Lunch', -12.5, account, date, date, [], '');

    final lunch = (await db.select(db.statements).get()).last;
    await service.deleteStatement(lunch);
    // A second delete of the same statement must not change the balance again.
    await service.deleteStatement(lunch);

    expect((await service.getAccountById(account)).balance, 100);
    expect((await db.select(db.statements).get()).map((s) => s.title), [
      'Salary',
    ]);
    await db.close();
  });
}
