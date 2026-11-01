import 'package:flutter/material.dart';
import 'package:money_mind/common/glass_background.dart';
import 'package:money_mind/common/money_text.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/features/analysis/trend.dart';
import 'package:money_mind/features/analysis/widgets/month_bar_chart.dart';

/// Income and expenses of the 12 months up to [month] as bars, their monthly
/// average, and each month's net. Tapping a month pops the page with it.
class TrendPage extends StatefulWidget {
  final DateTime month;

  const TrendPage({super.key, required this.month});

  @override
  State<TrendPage> createState() => _TrendPageState();
}

class _TrendPageState extends State<TrendPage> {
  late final Stream<List<PeriodTotal>> _totals = DatabaseService.instance
      .watchTotals(yearly: false, transfers: false);

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
        appBar: AppBar(title: const Text("Trend")),
        body: StreamBuilder(
          stream: _totals,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return _body(snapshot.data!);
          },
        ),
      ),
    );
  }

  Widget _body(List<PeriodTotal> totals) {
    final months = monthSeries(totals, widget.month, 12);
    double? average(double Function(PeriodTotal) side) =>
        monthlyAverage(months, totals, side);
    final theme = Theme.of(context);
    final localizations = MaterialLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        if (average((p) => p.total) != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                for (final (name, value) in [
                  ("Ø income", average((p) => p.income)!),
                  ("Ø expenses", average((p) => p.expense)!),
                  ("Ø net", average((p) => p.total)!),
                ])
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        MoneyText(value),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 24, 16, 8),
          child: MonthBarChart(months),
        ),
        for (final p in months.reversed)
          if (p.count > 0)
            ListTile(
              title: Text(localizations.formatMonthYear(p.start)),
              subtitle: Text(
                "${formatMoney(p.income)} · ${formatMoney(p.expense)}",
              ),
              trailing: MoneyText(p.total),
              onTap: () => Navigator.pop(context, p.start),
            ),
      ],
    );
  }
}
