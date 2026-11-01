import 'package:money_mind/common/money_text.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/features/analysis/tag_breakdown.dart';

const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// "Jan" for 1, like the rest of the app's English labels.
String monthAbbreviation(int month) => _monthNames[month - 1];

typedef MonthBalance = ({DateTime month, double balance});

/// The balance at the end of each of the up to [count] months up to [last],
/// oldest first, starting no earlier than the first month in the monthly
/// [totals]. Balances are the sum of all statements, so this is a running
/// sum of the monthly totals.
List<MonthBalance> monthEndBalances(
  List<PeriodTotal> totals,
  DateTime last,
  int count,
) {
  if (totals.isEmpty) return const [];
  final byStart = {for (final p in totals) p.start: p.total};
  final first = byStart.keys.reduce((a, b) => a.isBefore(b) ? a : b);
  var start = DateTime(last.year, last.month - count + 1);
  if (first.isAfter(start)) start = first;
  var balance = 0.0;
  for (final p in totals) {
    if (p.start.isBefore(start)) balance += p.total;
  }
  return [
    for (
      var month = start;
      !month.isAfter(last);
      month = DateTime(month.year, month.month + 1)
    )
      (month: month, balance: balance += byStart[month] ?? 0),
  ];
}

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

/// The average per month of [side] over the full months of [months] (a
/// [monthSeries]) since the data in [all] starts, or null when there is none.
/// The month of [now] is still running, so it does not count.
double? monthlyAverage(
  List<PeriodTotal> months,
  List<PeriodTotal> all,
  double Function(PeriodTotal) side, {
  DateTime? now,
}) {
  now ??= DateTime.now();
  final last = months.last.start;
  final next = DateTime(last.year, last.month + 1);
  final current = DateTime(now.year, now.month);
  final end = next.isAfter(current) ? current : next;
  final count = monthsWithHistory(all, months.first.start, end);
  if (count == 0) return null;
  final from = DateTime(end.year, end.month - count);
  return months
          .where((p) => !p.start.isBefore(from) && p.start.isBefore(end))
          .fold(0.0, (s, p) => s + side(p)) /
      count;
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
