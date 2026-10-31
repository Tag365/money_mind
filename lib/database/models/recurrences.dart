import 'dart:math';

import 'package:drift/drift.dart';

enum RecurrenceUnit {
  day("Day"),
  week("Week"),
  month("Month"),
  year("Year");

  const RecurrenceUnit(this.displayName);

  final String displayName;

  /// The [n]th date after [start], counted in [every] units. Month and year
  /// steps keep the day of [start] and clamp it to shorter months, so a
  /// series starting on Jan 31 continues Feb 28, Mar 31, ...
  DateTime occurrence(DateTime start, int every, int n) {
    final s = start.toLocal();
    final k = every * n;
    DateTime at(int year, int month, int day) =>
        DateTime(year, month, day, s.hour, s.minute, s.second);
    switch (this) {
      case day:
        return at(s.year, s.month, s.day + k);
      case week:
        return at(s.year, s.month, s.day + 7 * k);
      case month:
      case year:
        final first = DateTime(s.year, s.month + (this == year ? 12 : 1) * k);
        // Day 0 of the next month is the last day of this one.
        final daysInMonth = DateTime(first.year, first.month + 1, 0).day;
        return at(first.year, first.month, min(s.day, daysInMonth));
    }
  }
}

/// A series of statements repeated every [every] [unit]s. Each new statement
/// copies the latest statement of the series, so editing that one changes
/// what comes next.
class Recurrences extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Payment date of occurrence 0; occurrence n is `unit.occurrence(start,
  /// every, n)`. Counting from a fixed start avoids drift from clamped days.
  DateTimeColumn get start => dateTime()();
  TextColumn get unit => textEnum<RecurrenceUnit>()();
  IntColumn get every => integer()();

  /// Occurrences already created, i.e. the index of the next one.
  IntColumn get generated => integer()();

  /// Create the next statement up to a month before it is due (only one).
  BoolColumn get ahead => boolean().withDefault(const Constant(false))();
}
