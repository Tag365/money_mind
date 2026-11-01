import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/database/models/account_type.dart';
import 'package:money_mind/database/models/recurrences.dart';

void main() {
  test('upcoming lists future statements and next occurrences', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final service = DatabaseService.instance..database = db;
    final bank = await service.addAccount('Bank', AccountType.debit);
    final now = DateTime.now();
    final lastWeek = now.subtract(const Duration(days: 7));
    final inThreeDays = now.add(const Duration(days: 3));
    await service.addStatement('Coffee', -3, bank, lastWeek, lastWeek, [], '');
    await service.addStatement(
      'Insurance',
      -50,
      bank,
      inThreeDays,
      inThreeDays,
      [],
      '',
    );
    await service.addStatement('Gym', -30, bank, lastWeek, lastWeek, [], '');
    final gym = (await db.select(db.statements).get()).firstWhere(
      (s) => s.title == 'Gym',
    );
    // Its next occurrence is within a month, so it is created ahead.
    await service.setRecurrence(gym, RecurrenceUnit.month, 1);

    final upcoming = await service.watchUpcoming().first;
    expect(upcoming.map((u) => u.statement.title), ['Insurance', 'Gym']);
    expect(upcoming.last.date, RecurrenceUnit.month.occurrence(lastWeek, 1, 1));
    // A real statement, not the template projected forward.
    expect(upcoming.last.statement.paymentDate, upcoming.last.date);
    await db.close();
  });
}
