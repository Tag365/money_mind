import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:money_mind/common/glass_background.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/features/statements/statement_filter.dart';
import 'package:money_mind/features/statements/statement_filter_sheet.dart';
import 'package:money_mind/features/statements/widgets/active_filter_chips.dart';
import 'package:money_mind/features/statements/widgets/period_tile.dart';

/// The Statements tab. Pushed as its own page with a [title] and a [filter],
/// e.g. to show one account's statements, and optionally only one [month],
/// opened, with a [header] above it.
class ListWidget extends StatefulWidget {
  final String title;
  final StatementFilter filter;
  final DateTime? month;
  final Widget? header;

  const ListWidget({
    super.key,
    this.title = 'Statements',
    this.filter = const StatementFilter(),
    this.month,
    this.header,
  });

  @override
  State<ListWidget> createState() => _ListState();
}

class _ListState extends State<ListWidget> {
  DatabaseService databaseService = DatabaseService.instance;

  // Kept: rebuilds of the page pass a new, equal filter object.
  late final StatementFilter _initialFilter = widget.filter;
  late StatementFilter _filter = _initialFilter;

  // Only replaced when the filter changes, so rebuilding the widget does not
  // run the query again.
  late Stream<List<PeriodTotal>> _totals = _watchTotals(_filter);

  Stream<List<PeriodTotal>> _watchTotals(StatementFilter filter) {
    final totals = databaseService.watchTotals(yearly: false, filter: filter);
    final month = widget.month;
    if (month == null) return totals;
    return totals.map((t) => [...t.where((p) => p.start == month)]);
  }

  static const _currentMonths = ValueKey('currentMonths');
  double _todayFiller = 0;

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

  /// Whether the filter differs from the one the page opened with, which its
  /// title already names.
  bool get _filtered => _filter.isActive && !identical(_filter, _initialFilter);

  void _setFilter(StatementFilter filter) {
    setState(() {
      _todayFiller = 0;
      _filter = filter;
      _totals = _watchTotals(filter);
    });
  }

  void _openFilter() => showModalBottomSheet<StatementFilter>(
    isScrollControlled: true,
    showDragHandle: true,
    context: context,
    builder: (context) =>
        StatementFilterSheet(_filter, _accountNames, onChanged: _setFilter),
  );

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
      if (!_filtered) {
        return Center(child: Text("No statements found."));
      }
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("No statements match the filter."),
            TextButton(
              onPressed: () => _setFilter(_initialFilter),
              child: const Text("Clear filter"),
            ),
          ],
        ),
      );
    }
    return builder(asyncSnapshot.data!);
  }

  /// Moves [today] to the top, with blank space below a list too short for it.
  ///
  /// Retries because the scroll range is an estimate until the months below
  /// are built, which only happens on the way there.
  void _scrollToToday(BuildContext today, {int tries = 5}) {
    if (!mounted || !today.mounted || tries == 0) return;
    final position = Scrollable.of(today).position;
    final box = today.findRenderObject()!;
    final target = RenderAbstractViewport.of(
      box,
    ).getOffsetToReveal(box, 0).offset;
    final missing = target - position.maxScrollExtent;
    if (missing > 0) {
      setState(() => _todayFiller += missing);
    } else if ((position.pixels - target).abs() < 1) {
      return;
    } else {
      position.jumpTo(target);
    }
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollToToday(today, tries: tries - 1),
    );
  }

  /// Future months go above the center sliver, so the list opens at the
  /// current month and scrolling up reaches them.
  Widget _periods(List<PeriodTotal> totals) {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    final firstCurrent = totals.indexWhere((p) => !p.start.isAfter(thisMonth));
    // A header stays on top, and with a month there is nothing to skip.
    final header = widget.header;
    final startAtToday = header == null && widget.month == null;
    final futureCount = !startAtToday
        ? 0
        : firstCurrent < 0
        ? totals.length
        : firstCurrent;

    Widget tile(PeriodTotal period) => PeriodTile(
      // Keeps a period open when the totals stream emits again.
      key: PageStorageKey(period.start),
      period: period,
      accountNames: _accountNames,
      filter: _filter,
      open: widget.month != null,
      onToday: startAtToday ? _scrollToToday : null,
    );

    return CustomScrollView(
      center: _currentMonths,
      slivers: [
        SliverList.builder(
          itemCount: futureCount,
          // Above the center, index 0 is the lowest item.
          itemBuilder: (context, index) =>
              tile(totals[futureCount - 1 - index]),
        ),
        SliverPadding(
          key: _currentMonths,
          padding: const EdgeInsets.symmetric(vertical: 4),
          sliver: SliverList.builder(
            itemCount: totals.length - futureCount + (header == null ? 0 : 1),
            itemBuilder: (context, index) {
              if (header != null) {
                if (index == 0) return header;
                index--;
              }
              return tile(totals[futureCount + index]);
            },
          ),
        ),
        // Fills a short list to the viewport, so that the filler adds exactly
        // its height to the scroll range.
        SliverLayoutBuilder(
          builder: (context, constraints) => SliverToBoxAdapter(
            child: SizedBox(
              height:
                  math.max(
                    0,
                    constraints.viewportMainAxisExtent -
                        constraints.precedingScrollExtent,
                  ) +
                  _todayFiller,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          actions: [
            IconButton(
              tooltip: 'Filter',
              onPressed: _openFilter,
              icon: Badge(
                isLabelVisible: _filtered,
                child: const Icon(Icons.filter_list),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            if (_filtered)
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
                  (totals) =>
                      SlidableAutoCloseBehavior(child: _periods(totals)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
