import 'package:money_mind/database/app_database.dart';

/// Statements that were paid on the same local calendar day.
class DayGroup {
  final DateTime day;
  final List<Statement> statements = [];

  DayGroup(this.day);

  double get total => statements.fold(0, (sum, s) => sum + s.amount);
}

/// Splits [statements], sorted newest first, into one group per day.
List<DayGroup> groupByDay(List<Statement> statements) {
  final groups = <DayGroup>[];
  for (final statement in statements) {
    final date = statement.paymentDate.toLocal();
    final day = DateTime(date.year, date.month, date.day);
    if (groups.isEmpty || groups.last.day != day) groups.add(DayGroup(day));
    groups.last.statements.add(statement);
  }
  return groups;
}
