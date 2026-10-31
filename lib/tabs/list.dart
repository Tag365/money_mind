import 'dart:async';

import 'package:flutter/material.dart';
import 'package:money_mind/components/money_text.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/list/grouping.dart';

class ListWidget extends StatefulWidget {
  const ListWidget({super.key});

  @override
  State<ListWidget> createState() => _ListState();
}

class _ListState extends State<ListWidget> {
  DatabaseService databaseService = DatabaseService.instance;

  // Created once so rebuilding the widget does not run the query again.
  late final Stream<List<PeriodTotal>> _totals = databaseService.watchTotals(
    yearly: false,
  );

  Map<int, String> _accountNames = {};
  late final StreamSubscription<List<Account>> _accountsSubscription;

  @override
  void initState() {
    super.initState();
    _accountsSubscription = databaseService.watchAccounts().listen(
      (accounts) => setState(
        () => _accountNames = {for (final a in accounts) a.id: a.name},
      ),
    );
  }

  @override
  void dispose() {
    _accountsSubscription.cancel();
    super.dispose();
  }

  Widget _totalsList(List<PeriodTotal> totals) {
    final localizations = MaterialLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: totals.length,
      itemBuilder: (context, index) {
        final PeriodTotal period = totals[index];
        final String label = localizations.formatMonthYear(period.start);
        return ExpansionTile(
          // Keeps a period open when the totals stream emits again.
          key: PageStorageKey(period.start),
          initiallyExpanded:
              period.start ==
              DateTime(DateTime.now().year, DateTime.now().month),
          backgroundColor: colors.surfaceContainerHigh,
          collapsedBackgroundColor: colors.surfaceContainerHigh,
          shape: const Border(),
          collapsedShape: Border(bottom: BorderSide(color: colors.surface)),
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(label),
          subtitle: Text("${period.count} statements"),
          trailing: MoneyText(period.total),
          // Collapsed children are disposed, so only open periods are queried.
          children: [_PeriodStatements(period, _accountNames)],
        );
      },
    );
  }

  Widget _snapshotView<T>(
    AsyncSnapshot<List<T>> asyncSnapshot,
    Widget Function(List<T> data) builder,
  ) {
    if (asyncSnapshot.hasError) {
      return Center(child: Text("Error: ${asyncSnapshot.error}"));
    }
    if (!asyncSnapshot.hasData) {
      // Show a placeholder while loading
      return Center(child: CircularProgressIndicator());
    }
    if (asyncSnapshot.data!.isEmpty) {
      return Center(child: Text("No statements found."));
    }
    return builder(asyncSnapshot.data!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: _totals,
        builder: (context, asyncSnapshot) =>
            _snapshotView(asyncSnapshot, (data) => _totalsList(data)),
      ),
    );
  }
}

class _StatementTile extends StatelessWidget {
  final Statement statement;
  final Map<int, String> accountNames;

  const _StatementTile(this.statement, this.accountNames);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(statement.title, overflow: TextOverflow.ellipsis),
      isThreeLine: statement.tags.isNotEmpty,
      subtitle: Text(
        [
          [
            MaterialLocalizations.of(context).formatTimeOfDay(
              TimeOfDay.fromDateTime(statement.paymentDate.toLocal()),
              alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(
                context,
              ),
            ),
            ?accountNames[statement.account],
          ].join(" · "),
          if (statement.tags.isNotEmpty) statement.tags.join(", "),
        ].join("\n"),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: MoneyText(statement.amount),
    );
  }
}

/// Date header with the day's total, followed by the day's statements in a
/// card.
class _DayGroupView extends StatelessWidget {
  final DayGroup group;
  final Map<int, String> accountNames;

  const _DayGroupView(this.group, this.accountNames);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    MaterialLocalizations.of(
                      context,
                    ).formatMediumDate(group.day),
                    style: textTheme.titleMedium,
                  ),
                ),
                MoneyText(group.total, style: textTheme.bodyMedium),
              ],
            ),
          ),
          Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final s in group.statements)
                  _StatementTile(s, accountNames),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Statements of one expanded period. The stream lives in the state so
/// rebuilds do not re-run the query.
class _PeriodStatements extends StatefulWidget {
  final PeriodTotal period;
  final Map<int, String> accountNames;

  const _PeriodStatements(this.period, this.accountNames);

  @override
  State<_PeriodStatements> createState() => _PeriodStatementsState();
}

class _PeriodStatementsState extends State<_PeriodStatements> {
  late final Stream<List<Statement>> _statements = DatabaseService.instance
      .watchStatementsBetween(widget.period.start, widget.period.end);

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
              _DayGroupView(day, widget.accountNames),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}
