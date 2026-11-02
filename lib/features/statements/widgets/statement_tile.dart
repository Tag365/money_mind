import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:money_mind/common/money_text.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/features/statements/statement_actions.dart';
import 'package:money_mind/features/statements/statement_details_sheet.dart';

/// One statement in the list: title, time, account and tags, with the amount
/// and the account balance after it, highlighted on the account's newest
/// statement up to now. Tapping opens the details sheet; a swipe
/// reveals Edit and Delete.
///
/// Needs a `SlidableAutoCloseBehavior` above it.
class StatementTile extends StatelessWidget {
  final StatementWithBalance row;
  final Map<int, String> accountNames;

  const StatementTile(this.row, this.accountNames, {super.key});

  @override
  Widget build(BuildContext context) {
    final statement = row.statement;
    final balance = row.balance;
    final colors = Theme.of(context).colorScheme;
    return Slidable(
      groupTag: "statements",
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.5,
        children: [
          SlidableAction(
            onPressed: (context) => editStatement(context, statement),
            backgroundColor: colors.primaryContainer,
            foregroundColor: colors.onPrimaryContainer,
            icon: Icons.edit_outlined,
            label: "Edit",
          ),
          SlidableAction(
            onPressed: (context) => deleteStatement(context, statement),
            backgroundColor: colors.error,
            foregroundColor: colors.onError,
            icon: Icons.delete_outline,
            label: "Delete",
          ),
        ],
      ),
      child: ListTile(
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
            if (balance != null && row.current)
              // The account's balance today, so it can be found at a glance.
              // Shifted by its padding, so the text lines up with the amount.
              Container(
                transform: Matrix4.translationValues(6, 0, 0),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  // primaryContainer barely shows on the glassy card.
                  color: colors.primary.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  formatMoney(balance),
                  semanticsLabel: 'Current balance ${formatMoney(balance)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else if (balance != null)
              Text(
                formatMoney(balance),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
          ],
        ),
      ),
    );
  }
}
