import 'dart:async';

import 'package:flutter/material.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/features/statements/statement_filter.dart';
import 'package:money_mind/features/statements/statement_filter_sheet.dart';
import 'package:money_mind/features/statements/widgets/active_filter_chips.dart';
import 'package:money_mind/features/statements/widgets/period_tile.dart';

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
      appBar: AppBar(
        title: const Text('Statements'),
        actions: [
          IconButton(
            tooltip: 'Filter',
            onPressed: _openFilter,
            icon: Badge(
              isLabelVisible: _filter.isActive,
              child: const Icon(Icons.filter_list),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_filter.isActive)
            ActiveFilterChips(
              filter: _filter,
              accountNames: _accountNames,
              onChanged: _setFilter,
            ),
          Expanded(
            child: StreamBuilder(
              stream: _totals,
              builder: (context, asyncSnapshot) => _snapshotView(
                asyncSnapshot,
                (totals) => ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: totals.length,
                  itemBuilder: (context, index) => PeriodTile(
                    // Keeps a period open when the totals stream emits again.
                    key: PageStorageKey(totals[index].start),
                    period: totals[index],
                    accountNames: _accountNames,
                    filter: _filter,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
