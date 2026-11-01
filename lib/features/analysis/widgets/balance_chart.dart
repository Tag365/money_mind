import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:money_mind/common/money_text.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/features/analysis/trend.dart';
import 'package:money_mind/features/statements/statement_filter.dart';

/// The balance of [accounts] (all when empty) at the end of each of the
/// last 12 months, as a line. The current month's point includes statements
/// already created for later this month.
class BalanceChart extends StatefulWidget {
  final Set<int> accounts;

  const BalanceChart({super.key, this.accounts = const {}});

  @override
  State<BalanceChart> createState() => _BalanceChartState();
}

class _BalanceChartState extends State<BalanceChart> {
  // Transfers included: they move money between accounts.
  late final Stream<List<PeriodTotal>> _totals = DatabaseService.instance
      .watchTotals(
        yearly: false,
        filter: StatementFilter(accounts: widget.accounts),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    return StreamBuilder(
      stream: _totals,
      builder: (context, snapshot) {
        final balances = monthEndBalances(
          snapshot.data ?? const [],
          DateTime(now.year, now.month),
          12,
        );
        if (balances.isEmpty) return const SizedBox.shrink();
        final color = theme.colorScheme.primary;
        return Card(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 16,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Balance at month end",
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    MoneyText(balances.last.balance),
                  ],
                ),
                SizedBox(
                  height: 180,
                  child: LineChart(
                    LineChartData(
                      lineBarsData: [
                        LineChartBarData(
                          spots: [
                            for (final (i, b) in balances.indexed)
                              FlSpot(i.toDouble(), b.balance),
                          ],
                          color: color,
                          barWidth: 3,
                          isCurved: true,
                          preventCurveOverShooting: true,
                          belowBarData: BarAreaData(
                            show: true,
                            color: color.withValues(alpha: 0.15),
                          ),
                        ),
                      ],
                      gridData: FlGridData(
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: theme.colorScheme.outlineVariant,
                          strokeWidth: 0.3,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(),
                        rightTitles: const AxisTitles(),
                        // The axis starts near the lowest balance, so small
                        // changes look large without a scale.
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 52,
                            getTitlesWidget: (value, meta) =>
                                // The edges are off the grid and would
                                // crowd the grid labels.
                                value == meta.min || value == meta.max
                                ? const SizedBox.shrink()
                                : SideTitleWidget(
                                    meta: meta,
                                    child: Text(
                                      // Whole euros: "6.564".
                                      formatMoney(
                                        value.roundToDouble(),
                                      ).replaceFirst(',00 €', ''),
                                      style: theme.textTheme.labelSmall,
                                    ),
                                  ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (value, meta) => SideTitleWidget(
                              meta: meta,
                              child: Text(
                                monthAbbreviation(
                                  balances[value.toInt()].month.month,
                                ),
                                style: theme.textTheme.labelSmall,
                              ),
                            ),
                          ),
                        ),
                      ),
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) =>
                              theme.colorScheme.surfaceContainerHighest,
                          getTooltipItems: (spots) => [
                            for (final spot in spots)
                              LineTooltipItem(
                                formatMoney(spot.y),
                                theme.textTheme.labelMedium!.copyWith(
                                  color: color,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
