import 'package:flutter/material.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/features/analysis/tag_breakdown.dart';
import 'package:money_mind/features/analysis/tag_breakdown_page.dart';
import 'package:money_mind/features/analysis/trend_page.dart';
import 'package:money_mind/features/home/widgets/breakdown_card.dart';
import 'package:money_mind/features/home/widgets/net_card.dart';

/// Expenses and income of a month by tag, and the net, starting with the
/// current month; arrows step through months. Tapping the net opens the
/// trend, and a month picked there shows here.
class MonthOverview extends StatefulWidget {
  const MonthOverview({super.key});

  @override
  State<MonthOverview> createState() => _MonthOverviewState();
}

class _MonthOverviewState extends State<MonthOverview> {
  final DatabaseService databaseService = DatabaseService.instance;

  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  // Only replaced when the month changes, so rebuilds don't re-run the query.
  late Stream<List<TagTotal>> _totals = _watch();
  late final Stream<List<Tag>> _tags = databaseService.watchTags();

  Stream<List<TagTotal>> _watch() => databaseService.watchTagTotals(
    _month,
    DateTime(_month.year, _month.month + 1),
  );

  void _step(int months) => setState(() {
    _month = DateTime(_month.year, _month.month + months);
    _totals = _watch();
  });

  Future<void> _openTrend() async {
    final month = await Navigator.of(context).push<DateTime>(
      MaterialPageRoute(builder: (_) => TrendPage(month: _month)),
    );
    if (month != null) {
      setState(() {
        _month = month;
        _totals = _watch();
      });
    }
  }

  void _openBreakdown({required bool income}) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => TagBreakdownPage(month: _month, income: income),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: StreamBuilder(
        stream: _tags,
        builder: (context, tagsSnapshot) => StreamBuilder(
          stream: _totals,
          builder: (context, snapshot) {
            final colors = tagColors(tagsSnapshot.data ?? const []);
            final totals = snapshot.data ?? const <TagTotal>[];
            final income = totals.fold(0.0, (s, t) => s + t.income);
            final expense = totals.fold(0.0, (s, t) => s + t.expense);
            return Column(
              spacing: 12,
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: "Previous month",
                      onPressed: () => _step(-1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Text(
                        MaterialLocalizations.of(
                          context,
                        ).formatMonthYear(_month),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      tooltip: "Next month",
                      onPressed: () => _step(1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                BreakdownCard(
                  title: "Expenses",
                  total: expense,
                  shares: tagBreakdown(totals, income: false),
                  colors: colors,
                  onTap: () => _openBreakdown(income: false),
                ),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 12,
                    children: [
                      Expanded(
                        child: BreakdownCard(
                          title: "Income",
                          total: income,
                          shares: tagBreakdown(totals, income: true),
                          colors: colors,
                          onTap: () => _openBreakdown(income: true),
                        ),
                      ),
                      Expanded(
                        child: NetCard(
                          income: income,
                          expense: expense,
                          onTap: _openTrend,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
