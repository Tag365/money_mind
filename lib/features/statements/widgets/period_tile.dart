import 'package:flutter/material.dart';
import 'package:money_mind/common/money_text.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/features/statements/statement_filter.dart';
import 'package:money_mind/features/statements/widgets/period_statements.dart';

/// One month of the statements list: its totals as a header that expands
/// to the month's statements. The current month starts expanded.
///
/// Give it a `PageStorageKey` so it stays open when the totals stream emits
/// again.
class PeriodTile extends StatelessWidget {
  final PeriodTotal period;
  final Map<int, String> accountNames;
  final StatementFilter filter;

  const PeriodTile({
    super.key,
    required this.period,
    required this.accountNames,
    required this.filter,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final now = DateTime.now();
    return ExpansionTile(
      initiallyExpanded: period.start == DateTime(now.year, now.month),
      backgroundColor: colors.surfaceContainerHigh,
      collapsedBackgroundColor: colors.surfaceContainerHigh,
      shape: const Border(),
      collapsedShape: Border(bottom: BorderSide(color: colors.surface)),
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(
        MaterialLocalizations.of(context).formatMonthYear(period.start),
      ),
      subtitle: Row(
        spacing: 8,
        // Different font sizes, so align on the text baseline.
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text("${period.count} statements"),
          if (period.income != 0)
            MoneyText(period.income, style: textTheme.bodySmall),
          if (period.expense != 0)
            MoneyText(period.expense, style: textTheme.bodySmall),
        ],
      ),
      trailing: MoneyText(period.total),
      // Collapsed children are disposed, so only open periods are queried.
      children: [
        PeriodStatements(
          period,
          accountNames,
          filter,
          // A new filter needs a new query.
          key: ValueKey(filter),
        ),
      ],
    );
  }
}
