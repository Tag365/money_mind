import 'package:flutter_test/flutter_test.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/features/analysis/trend.dart';

void main() {
  PeriodTotal month(int year, int month, double total) =>
      PeriodTotal(year, month, total, 1, 0, 0);

  test('month-end balances are a running sum from the first month', () {
    final totals = [
      month(2026, 12, 50), // later than the last month: left out
      month(2026, 11, -30),
      month(2026, 9, 1000),
    ];
    expect(monthEndBalances(totals, DateTime(2026, 11), 12), [
      (month: DateTime(2026, 9), balance: 1000.0),
      (month: DateTime(2026, 10), balance: 1000.0),
      (month: DateTime(2026, 11), balance: 970.0),
    ]);
    // Months before the window still count towards the balance.
    expect(monthEndBalances(totals, DateTime(2026, 11), 2), [
      (month: DateTime(2026, 10), balance: 1000.0),
      (month: DateTime(2026, 11), balance: 970.0),
    ]);
    expect(monthEndBalances(const [], DateTime(2026, 11), 12), isEmpty);
  });
}
