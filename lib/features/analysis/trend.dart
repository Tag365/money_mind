import 'package:money_mind/common/money_text.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/features/analysis/tag_breakdown.dart';

/// The [count] months up to and including [last], oldest first, from the
/// monthly [totals]; months without statements are zero.
List<PeriodTotal> monthSeries(
  List<PeriodTotal> totals,
  DateTime last,
  int count,
) {
  final byStart = {for (final p in totals) p.start: p};
  return [
    for (var i = count - 1; i >= 0; i--)
      byStart[DateTime(last.year, last.month - i)] ??
          PeriodTotal(
            DateTime(last.year, last.month - i).year,
            DateTime(last.year, last.month - i).month,
            0,
            0,
            0,
            0,
          ),
  ];
}

/// How many months of [start, end) lie after the first month in the monthly
/// [totals], so an average does not count months before any data as zero.
int monthsWithHistory(List<PeriodTotal> totals, DateTime start, DateTime end) {
  if (totals.isEmpty) return 0;
  final first = totals
      .map((p) => p.start)
      .reduce((a, b) => a.isBefore(b) ? a : b);
  final from = first.isAfter(start) ? first : start;
  final months = (end.year - from.year) * 12 + end.month - from.month;
  return months < 0 ? 0 : months;
}

/// The monthly average per tag of [history], which spans [months] months,
/// grouped as [tagBreakdown] does; empty without history.
Map<String, double> tagAverages(
  List<TagTotal> history,
  int months, {
  required bool income,
  String? parent,
}) => months == 0
    ? const {}
    : {
        for (final s in tagBreakdown(history, income: income, parent: parent))
          s.tag: s.amount / months,
      };

/// How [amount] compares to [average], e.g. "12,30 € above Ø"; both have the
/// same sign, so "above" means more spent or more earned.
String versusAverage(double amount, double average) {
  final diff = amount.abs() - average.abs();
  if ((diff * 100).round() == 0) return "as Ø";
  return "${formatMoney(diff.abs())} ${diff > 0 ? 'above' : 'below'} Ø";
}
