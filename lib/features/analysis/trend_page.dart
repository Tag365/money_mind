import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:money_mind/common/glass_background.dart';
import 'package:money_mind/common/money_text.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/features/analysis/trend.dart';

const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

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
    final now = DateTime.now();
    // Full months only: the current one is still running.
    final history = months.where(
      (p) => p.count > 0 && p.start.isBefore(DateTime(now.year, now.month)),
    );
    final theme = Theme.of(context);
    final localizations = MaterialLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        if (history.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                for (final (name, value) in [
                  ("Ø income", history.fold(0.0, (s, p) => s + p.income)),
                  ("Ø expenses", history.fold(0.0, (s, p) => s + p.expense)),
                  ("Ø net", history.fold(0.0, (s, p) => s + p.total)),
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
                        MoneyText(value / history.length),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 24, 16, 8),
          child: SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                barGroups: [
                  for (final (i, p) in months.indexed)
                    BarChartGroupData(
                      x: i,
                      groupVertically: true,
                      barRods: [
                        for (final (value, color) in [
                          (p.income, incomeColor),
                          (p.expense, expenseColor),
                        ])
                          BarChartRodData(
                            toY: value,
                            color: color,
                            width: 12,
                            borderRadius: BorderRadius.circular(3),
                          ),
                      ],
                    ),
                ],
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: theme.colorScheme.outlineVariant,
                    strokeWidth: value == 0 ? 1 : 0.3,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: const AxisTitles(),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => SideTitleWidget(
                        meta: meta,
                        child: Text(
                          _monthNames[months[value.toInt()].month! - 1],
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) =>
                        theme.colorScheme.surfaceContainerHighest,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                        BarTooltipItem(
                          formatMoney(rod.toY),
                          theme.textTheme.labelMedium!.copyWith(
                            color: rod.color,
                          ),
                        ),
                  ),
                ),
              ),
            ),
          ),
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
