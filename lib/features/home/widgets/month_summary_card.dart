import 'package:flutter/material.dart';
import 'package:money_mind/common/money_text.dart';
import 'package:money_mind/database/database_service.dart';

/// Income, expenses and net of the current month; zeros when [month] is null
/// (no statements yet). Tapping it calls [onTap].
class MonthSummaryCard extends StatelessWidget {
  final PeriodTotal? month;
  final VoidCallback onTap;

  const MonthSummaryCard(this.month, {super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final label = text.labelMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    final now = DateTime.now();
    final values = [
      ("Income", month?.income ?? 0),
      ("Expenses", month?.expense ?? 0),
      ("Net", month?.total ?? 0),
    ];
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Text(
                MaterialLocalizations.of(
                  context,
                ).formatMonthYear(DateTime(now.year, now.month)),
                style: text.titleMedium,
              ),
              Row(
                children: [
                  for (final (name, amount) in values)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: label),
                          MoneyText(amount),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
