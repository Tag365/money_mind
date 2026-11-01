import 'package:flutter_test/flutter_test.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/features/analysis/trend.dart';

void main() {
  PeriodTotal month(int year, int month, double income, double expense) =>
      PeriodTotal(year, month, income + expense, 1, income, expense);

  test('fills a 12-month series across the year with empty months', () {
    final totals = [month(2027, 1, 10, -5), month(2026, 11, 20, -8)];
    final series = monthSeries(totals, DateTime(2027, 2), 12);
    expect(series.length, 12);
    expect(series.first.start, DateTime(2026, 3));
    expect(series.last.start, DateTime(2027, 2));
    expect(series.map((p) => p.income).toList().sublist(8), [20, 0, 10, 0]);
  });

  test('averages only count months since the first data', () {
    final totals = [month(2026, 11, 0, -10), month(2026, 10, 0, -20)];
    // Six months before December, but data only since October.
    expect(monthsWithHistory(totals, DateTime(2026, 6), DateTime(2026, 12)), 2);
    expect(monthsWithHistory(totals, DateTime(2027, 1), DateTime(2027, 7)), 6);
    expect(
      monthsWithHistory(const [], DateTime(2026, 6), DateTime(2026, 12)),
      0,
    );

    final history = [
      (tags: ['Food'], income: 0.0, expense: -60.0),
      (tags: ['Car'], income: 0.0, expense: -20.0),
    ];
    final averages = tagAverages(history, 2, income: false);
    expect(averages, {'Food': -30.0, 'Car': -10.0});
    expect(tagAverages(history, 0, income: false), isEmpty);

    expect(versusAverage(-42.3, -30), '12,30 € above Ø');
    expect(versusAverage(-20, -30), '10,00 € below Ø');
    expect(versusAverage(-30, -30), 'as Ø');
    expect(versusAverage(-5, 0), '5,00 € above Ø');
  });
}
