import 'package:flutter/material.dart';
import 'package:money_mind/common/money_text.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/features/statements/statement_details_sheet.dart';

/// One statement in the list: title, time, account and tags, with the amount
/// and the account balance after it. Tapping opens the details sheet.
class StatementTile extends StatelessWidget {
  final StatementWithBalance row;
  final Map<int, String> accountNames;

  const StatementTile(this.row, this.accountNames, {super.key});

  @override
  Widget build(BuildContext context) {
    final statement = row.statement;
    final balance = row.balance;
    return ListTile(
      onTap: () => showModalBottomSheet(
        isScrollControlled: true,
        showDragHandle: true,
        context: context,
        builder: (context) =>
            StatementDetailsSheet(row, accountNames[statement.account]),
      ),
      title: Row(
        spacing: 4,
        children: [
          Flexible(
            child: Text(statement.title, overflow: TextOverflow.ellipsis),
          ),
          if (statement.recurrence != null)
            const Icon(Icons.repeat, size: 16, semanticLabel: 'Recurring'),
        ],
      ),
      isThreeLine: statement.tags.isNotEmpty,
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            [
              MaterialLocalizations.of(context).formatTimeOfDay(
                TimeOfDay.fromDateTime(statement.paymentDate.toLocal()),
                alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(
                  context,
                ),
              ),
              ?accountNames[statement.account],
            ].join(" · "),
            overflow: TextOverflow.ellipsis,
          ),
          if (statement.tags.isNotEmpty)
            Text(statement.tags.join(", "), overflow: TextOverflow.ellipsis),
        ],
      ),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          MoneyText(statement.amount),
          if (balance != null)
            Text(
              formatMoney(balance),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
