import 'package:flutter/material.dart';
import 'package:money_mind/common/money_text.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/features/analysis/trend.dart';
import 'package:money_mind/features/analysis/widgets/month_bar_chart.dart';
import 'package:money_mind/features/statements/statement_filter.dart';

/// The 12 months up to [month] of what [filter] matches, income or expenses
/// as it selects, as bars with their average per full month.
class TagTrend extends StatefulWidget {
  final StatementFilter filter;
  final DateTime month;

  const TagTrend({super.key, required this.filter, required this.month});

  @override
  State<TagTrend> createState() => _TagTrendState();
}

class _TagTrendState extends State<TagTrend> {
  // Created once so rebuilds don't re-run the queries.
  late final Stream<List<PeriodTotal>> _matching = DatabaseService.instance
      .watchTotals(yearly: false, filter: widget.filter);
  // When the data starts, so earlier months don't count as zero.
  late final Stream<List<PeriodTotal>> _all = DatabaseService.instance
      .watchTotals(yearly: false, transfers: false);

  @override
  Widget build(BuildContext context) {
    final income = widget.filter.income && !widget.filter.expense;
    final theme = Theme.of(context);
    return StreamBuilder(
      stream: _all,
      builder: (context, allSnapshot) => StreamBuilder(
        stream: _matching,
        builder: (context, snapshot) {
          final months = monthSeries(snapshot.data ?? [], widget.month, 12);
          final average = monthlyAverage(
            months,
            allSnapshot.data ?? [],
            (p) => income ? p.income : p.expense,
          );
          return Card(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 16,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          average == null
                              ? "No full month to average yet"
                              : "Ø per month",
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (average != null) MoneyText(average),
                    ],
                  ),
                  MonthBarChart(months, income: income, expense: !income),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
