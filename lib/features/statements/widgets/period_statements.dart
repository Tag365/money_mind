import 'package:flutter/material.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/features/statements/grouping.dart';
import 'package:money_mind/features/statements/statement_filter.dart';
import 'package:money_mind/features/statements/widgets/day_group_view.dart';

/// Statements of one expanded period, grouped by day. The stream lives in
/// the state so rebuilds do not re-run the query.
class PeriodStatements extends StatefulWidget {
  final PeriodTotal period;
  final Map<int, String> accountNames;
  final StatementFilter filter;

  /// Told once where the newest day up to today is, if days lie ahead of it.
  final ValueChanged<BuildContext>? onToday;

  const PeriodStatements(
    this.period,
    this.accountNames,
    this.filter, {
    this.onToday,
    super.key,
  });

  @override
  State<PeriodStatements> createState() => _PeriodStatementsState();
}

class _PeriodStatementsState extends State<PeriodStatements> {
  late final Stream<List<StatementWithBalance>> _statements = DatabaseService
      .instance
      .watchStatementsBetween(
        widget.period.start,
        widget.period.end,
        filter: widget.filter,
      );

  final _todayKey = GlobalKey();
  late ValueChanged<BuildContext>? _onToday = widget.onToday;

  /// The newest day up to today, if days lie ahead of it.
  DateTime? _todayGroup;

  void _findToday(List<DayGroup> days) {
    final onToday = _onToday;
    if (onToday == null) return;
    _onToday = null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final index = days.indexWhere((d) => !d.day.isAfter(today));
    if (index < 1) return;
    _todayGroup = days[index].day;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _todayKey.currentContext;
      if (context != null) onToday(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _statements,
      builder: (context, snapshot) {
        if (snapshot.hasError) return Text("Error: ${snapshot.error}");
        if (!snapshot.hasData) return const LinearProgressIndicator();
        // shortcut: builds all rows of the period at once (no lazy list), fine
        // for a month; switch to a flat sliver list if yearly groups get slow.
        final days = groupByDay(snapshot.data!);
        _findToday(days);
        return Column(
          children: [
            for (final day in days)
              DayGroupView(
                day,
                widget.accountNames,
                key: day.day == _todayGroup ? _todayKey : null,
              ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}
