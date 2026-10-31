import 'dart:async';

import 'package:flutter/material.dart';
import 'package:money_mind/components/money_text.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/list/grouping.dart';
import 'package:money_mind/list/statement_filter.dart';
import 'package:money_mind/modals/statement_details_sheet.dart';
import 'package:money_mind/modals/statement_filter_sheet.dart';

class ListWidget extends StatefulWidget {
  const ListWidget({super.key});

  @override
  State<ListWidget> createState() => _ListState();
}

class _ListState extends State<ListWidget> {
  DatabaseService databaseService = DatabaseService.instance;

  StatementFilter _filter = const StatementFilter();

  // Only replaced when the filter changes, so rebuilding the widget does not
  // run the query again.
  late Stream<List<PeriodTotal>> _totals = databaseService.watchTotals(
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

  void _setFilter(StatementFilter filter) {
    setState(() {
      _filter = filter;
      _totals = databaseService.watchTotals(yearly: false, filter: filter);
    });
  }

  void _openFilter() async {
    final filter = await showModalBottomSheet<StatementFilter>(
      isScrollControlled: true,
      showDragHandle: true,
      context: context,
      builder: (context) => StatementFilterSheet(_filter, _accountNames),
    );
    if (filter != null) _setFilter(filter);
  }

  /// One removable chip per active part of the filter.
  Widget _activeFilters() {
    final f = _filter;
    Widget chip(String label, StatementFilter without) => Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InputChip(
        label: Text(label),
        onDeleted: () => _setFilter(without),
      ),
    );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          for (final id in f.accounts)
            chip(
              _accountNames[id] ?? '?',
              f.copyWith(accounts: {...f.accounts}..remove(id)),
            ),
          for (final tag in f.tags)
            chip(
              f.excludeTags ? 'Not $tag' : tag,
              f.copyWith(tags: {...f.tags}..remove(tag)),
            ),
          if (f.income != f.expense)
            chip(
              f.income ? 'Income' : 'Expense',
              f.copyWith(income: false, expense: false),
            ),
          if (f.text.isNotEmpty) chip('"${f.text}"', f.copyWith(text: '')),
        ],
      ),
    );
  }

  Widget _totalsList(List<PeriodTotal> totals) {
    final localizations = MaterialLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return ListView.builder(
      // Room for the filter button below the last row.
      padding: const EdgeInsets.only(bottom: 88),
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
          subtitle: Row(
            spacing: 8,
            // Different font sizes, so align on the text baseline.
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text("${period.count} statements"),
              if (period.income != 0)
                MoneyText(period.income, style: textTheme.bodySmall),
              if (period.expense != 0)
                MoneyText(period.expense, style: textTheme.bodySmall),
            ],
          ),
          trailing: MoneyText(period.total),
          // Collapsed children are disposed, so only open periods are queried.
          children: [
            _PeriodStatements(
              period,
              _accountNames,
              _filter,
              // A new filter needs a new query.
              key: ValueKey(_filter),
            ),
          ],
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
      if (!_filter.isActive) {
        return Center(child: Text("No statements found."));
      }
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("No statements match the filter."),
            TextButton(
              onPressed: () => _setFilter(const StatementFilter()),
              child: const Text("Clear filter"),
            ),
          ],
        ),
      );
    }
    return builder(asyncSnapshot.data!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        tooltip: 'Filter',
        onPressed: _openFilter,
        child: Badge(
          isLabelVisible: _filter.isActive,
          child: const Icon(Icons.filter_list),
        ),
      ),
      body: Column(
        children: [
          if (_filter.isActive) _activeFilters(),
          Expanded(
            child: StreamBuilder(
              stream: _totals,
              builder: (context, asyncSnapshot) =>
                  _snapshotView(asyncSnapshot, (data) => _totalsList(data)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatementTile extends StatelessWidget {
  final StatementWithBalance row;
  final Map<int, String> accountNames;

  const _StatementTile(this.row, this.accountNames);

  @override
  Widget build(BuildContext context) {
    final statement = row.statement;
    final balance = row.balance;
    return ListTile(
      onTap: () => showModalBottomSheet(
        isScrollControlled: true,
        showDragHandle: true,
        context: context,
        builder: (context) =>
            StatementDetailsSheet(row, accountNames[statement.account]),
      ),
      title: Row(
        spacing: 4,
        children: [
          Flexible(
            child: Text(statement.title, overflow: TextOverflow.ellipsis),
          ),
          if (statement.recurrence != null)
            const Icon(Icons.repeat, size: 16, semanticLabel: 'Recurring'),
        ],
      ),
      isThreeLine: statement.tags.isNotEmpty,
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            [
              MaterialLocalizations.of(context).formatTimeOfDay(
                TimeOfDay.fromDateTime(statement.paymentDate.toLocal()),
                alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(
                  context,
                ),
              ),
              ?accountNames[statement.account],
            ].join(" · "),
            overflow: TextOverflow.ellipsis,
          ),
          if (statement.tags.isNotEmpty)
            Text(statement.tags.join(", "), overflow: TextOverflow.ellipsis),
        ],
      ),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          MoneyText(statement.amount),
          if (balance != null)
            Text(
              formatMoney(balance),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
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
  final StatementFilter filter;

  const _PeriodStatements(
    this.period,
    this.accountNames,
    this.filter, {
    super.key,
  });

  @override
  State<_PeriodStatements> createState() => _PeriodStatementsState();
}

class _PeriodStatementsState extends State<_PeriodStatements> {
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
              _DayGroupView(day, widget.accountNames),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}
