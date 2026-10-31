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
    final textTheme = Theme.of(context).textTheme;
    final now = DateTime.now();
    // A card like the account tiles; the open month's days are inside it.
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: period.start == DateTime(now.year, now.month),
        shape: const Border(),
        collapsedShape: const Border(),
        controlAffinity: ListTileControlAffinity.leading,
        title: Text(
          MaterialLocalizations.of(context).formatMonthYear(period.start),
        ),
        // Count and amounts on their own lines, so every month has the same
        // shape and the amounts never squeeze the count.
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${period.count} statement${period.count == 1 ? '' : 's'}"),
            Row(
              spacing: 12,
              children: [
                if (period.income != 0)
                  MoneyText(period.income, style: textTheme.bodySmall),
                if (period.expense != 0)
                  MoneyText(period.expense, style: textTheme.bodySmall),
              ],
            ),
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
      ),
    );
  }
}
