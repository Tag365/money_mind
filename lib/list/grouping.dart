import 'package:money_mind/database/database_service.dart';

/// Statements that were paid on the same local calendar day.
class DayGroup {
  final DateTime day;
  final List<StatementWithBalance> statements = [];

  DayGroup(this.day);

  double get total => statements.fold(0, (sum, s) => sum + s.statement.amount);
}

/// Splits [statements], sorted newest first, into one group per day.
List<DayGroup> groupByDay(List<StatementWithBalance> statements) {
  final groups = <DayGroup>[];
  for (final row in statements) {
    final date = row.statement.paymentDate.toLocal();
    final day = DateTime(date.year, date.month, date.day);
    if (groups.isEmpty || groups.last.day != day) groups.add(DayGroup(day));
    groups.last.statements.add(row);
  }
  return groups;
}
