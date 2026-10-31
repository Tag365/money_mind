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
  static const int _pageSize = 100;

  DatabaseService databaseService = DatabaseService.instance;

  GroupingOption? selectedGrouping = GroupingOption.none;

  // Streams are created once and only replaced when the page size or grouping
  // changes, so rebuilding the widget does not run the query again.
  int _limit = _pageSize;
  late Stream<List<Statement>> _statements;
  Stream<List<PeriodTotal>>? _totals;

  @override
  void initState() {
    super.initState();
    _statements = databaseService.watchStatements(limit: _limit);
  }

  void _loadMore() {
    setState(() {
      _limit += _pageSize;
      _statements = databaseService.watchStatements(limit: _limit);
    });
  }

  void _selectGrouping(GroupingOption? value) {
    setState(() {
      selectedGrouping = value;
      _totals = switch (value) {
        GroupingOption.monthly => databaseService.watchTotals(yearly: false),
        GroupingOption.yearly => databaseService.watchTotals(yearly: true),
        _ => null,
      };
    });
  }

  Widget _list(List<Statement> statements) {
    final bool hasMore = statements.length >= _limit;
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Fetch the next page shortly before reaching the end of the list.
        if (hasMore && notification.metrics.extentAfter < 500) {
          _loadMore();
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: statements.length,
        itemBuilder: (context, index) {
          final Statement statement = statements[index];
          final bool income = statement.amount >= 0;
          final colors = Theme.of(context).colorScheme;
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: income
                  ? colors.primaryContainer
                  : colors.errorContainer,
              foregroundColor: income
                  ? colors.onPrimaryContainer
                  : colors.onErrorContainer,
              child: Icon(income ? Icons.south_west : Icons.north_east),
            ),
            title: Text(statement.title, overflow: TextOverflow.ellipsis),
            subtitle: Text(
              MaterialLocalizations.of(
                context,
              ).formatMediumDate(statement.paymentDate),
            ),
            trailing: MoneyText(statement.amount),
          );
        },
      ),
    );
  }

  Widget _totalsList(List<PeriodTotal> totals) {
    final localizations = MaterialLocalizations.of(context);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: totals.length,
      itemBuilder: (context, index) {
        final PeriodTotal period = totals[index];
        final String label = period.month == null
            ? "${period.year}"
            : localizations.formatMonthYear(
                DateTime(period.year, period.month!),
              );
        return Card(
          child: ListTile(
            title: Text(label),
            subtitle: Text("${period.count} statements"),
            trailing: MoneyText(period.total),
          ),
        );
      },
    );
  }

  Widget _content() {
    final totals = _totals;
    if (totals != null) {
      return StreamBuilder(
        stream: totals,
        builder: (context, asyncSnapshot) => _snapshotView(
          asyncSnapshot,
          (data) => _totalsList(data),
        ),
      );
    }
    return StreamBuilder(
      stream: _statements,
      builder: (context, asyncSnapshot) =>
          _snapshotView(asyncSnapshot, (data) => _list(data)),
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<GroupingOption>(
                showSelectedIcon: false,
                segments: [
                  for (final option in GroupingOption.values)
                    ButtonSegment(value: option, label: Text(option.displayName)),
                ],
                selected: {selectedGrouping ?? GroupingOption.none},
                onSelectionChanged: (selection) =>
                    _selectGrouping(selection.first),
              ),
            ),
          ),
          Expanded(child: _content()),
        ],
      ),
    );
  }
}
