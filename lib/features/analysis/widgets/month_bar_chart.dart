import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:money_mind/common/money_text.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/features/analysis/trend.dart';

/// One bar per month of [months]: with [income] and [expense] both, income
/// up and expenses down; with one of them, its amounts up. Tapping a bar
/// shows its amount.
class MonthBarChart extends StatelessWidget {
  final List<PeriodTotal> months;
  final bool income;
  final bool expense;

  const MonthBarChart(
    this.months, {
    super.key,
    this.income = true,
    this.expense = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // The amounts each bar shows, signed as booked.
    List<(double, Color)> amounts(PeriodTotal p) => [
      if (income) (p.income, incomeColor),
      if (expense) (p.expense, expenseColor),
    ];
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          barGroups: [
            for (final (i, p) in months.indexed)
              BarChartGroupData(
                x: i,
                groupVertically: true,
                barRods: [
                  for (final (value, color) in amounts(p))
                    BarChartRodData(
                      // A single side always grows up.
                      toY: income && expense ? value : value.abs(),
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
                    monthAbbreviation(months[value.toInt()].month!),
                    style: theme.textTheme.labelSmall,
                  ),
                ),
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => theme.colorScheme.surfaceContainerHighest,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final (value, color) = amounts(months[group.x])[rodIndex];
                return BarTooltipItem(
                  formatMoney(value),
                  theme.textTheme.labelMedium!.copyWith(color: color),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
