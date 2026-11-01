import 'package:flutter/material.dart';
import 'package:money_mind/common/money_text.dart';

/// Income minus expenses of a month, with both as bars to compare. Tapping
/// it calls [onTap].
class NetCard extends StatelessWidget {
  final double income;
  final double expense;
  final VoidCallback onTap;

  const NetCard({
    super.key,
    required this.income,
    required this.expense,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final largest = income.abs() > expense.abs() ? income.abs() : expense.abs();
    Widget bar(Color color, double value) => Container(
      height: 8,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: largest == 0 ? 0 : value.abs() / largest,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Row(
                children: [
                  Text(
                    "Net",
                    style: theme.textTheme.labelLarge?.copyWith(color: muted),
                  ),
                  Icon(Icons.chevron_right, size: 18, color: muted),
                ],
              ),
              MoneyText(income + expense),
              const Spacer(),
              bar(incomeColor, income),
              bar(expenseColor, expense),
            ],
          ),
        ),
      ),
    );
  }
}
