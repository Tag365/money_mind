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

  const PeriodStatements(
    this.period,
    this.accountNames,
    this.filter, {
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _statements,
      builder: (context, snapshot) {
        if (snapshot.hasError) return Text("Error: ${snapshot.error}");
        if (!snapshot.hasData) return const LinearProgressIndicator();
        // shortcut: builds all rows of the period at once (no lazy list), fine
        // for a month; switch to a flat sliver list if yearly groups get slow.
        return Column(
          children: [
            for (final day in groupByDay(snapshot.data!))
              DayGroupView(day, widget.accountNames),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}
