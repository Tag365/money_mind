import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:money_mind/common/money_text.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/models/account_type.dart';

/// One account with its type and balance; tapping it calls [onTap]. A swipe
/// reveals Edit, Settle when [onSettle] is given, and for open accounts
/// Close; closed ones are greyed out.
///
/// Needs a `SlidableAutoCloseBehavior` above it.
class AccountTile extends StatelessWidget {
  final Account account;
  final VoidCallback onEdit;
  final VoidCallback? onSettle;
  final VoidCallback onClose;
  final VoidCallback onTap;

  const AccountTile(
    this.account, {
    super.key,
    required this.onEdit,
    this.onSettle,
    required this.onClose,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final onSettle = this.onSettle;
    final actions = 1 + (onSettle == null ? 0 : 1) + (account.closed ? 0 : 1);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Slidable(
        groupTag: "0",
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 0.25 * actions,
          children: [
            SlidableAction(
              onPressed: (_) => onEdit(),
              backgroundColor: colors.primaryContainer,
              foregroundColor: colors.onPrimaryContainer,
              icon: Icons.edit_outlined,
              label: "Edit",
            ),
            if (onSettle != null)
              SlidableAction(
                onPressed: (_) => onSettle(),
                backgroundColor: colors.secondaryContainer,
                foregroundColor: colors.onSecondaryContainer,
                icon: Icons.price_check,
                label: "Settle",
              ),
            if (!account.closed)
              SlidableAction(
                onPressed: (_) => onClose(),
                backgroundColor: colors.error,
                foregroundColor: colors.onError,
                icon: Icons.block,
                label: "Close",
              ),
          ],
        ),
        // Not the ListTile's onTap: a disabled one ignores taps, but closed
        // accounts still have statements to show.
        child: InkWell(
          onTap: onTap,
          child: ListTile(
            enabled: !account.closed,
            leading: CircleAvatar(
              backgroundColor: colors.secondaryContainer,
              foregroundColor: colors.onSecondaryContainer,
              child: Icon(
                account.type == AccountType.creditCard
                    ? Icons.credit_card
                    : Icons.account_balance_wallet_outlined,
              ),
            ),
            title: Text(account.name),
            subtitle: Text(
              account.closed
                  ? "${account.type.displayName} · Closed"
                  : account.type.displayName,
            ),
            trailing: Opacity(
              opacity: account.closed ? 0.5 : 1,
              child: MoneyText(account.balance),
            ),
          ),
        ),
      ),
    );
  }
}
