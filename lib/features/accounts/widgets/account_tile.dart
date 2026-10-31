import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:money_mind/common/money_text.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/models/account_type.dart';

/// One account with its type and balance. Open accounts can be swiped to
/// reveal a Close action; closed ones are greyed out.
///
/// Needs a `SlidableAutoCloseBehavior` above it.
class AccountTile extends StatelessWidget {
  final Account account;
  final VoidCallback onClose;

  const AccountTile(this.account, {super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Slidable(
        groupTag: "0",
        endActionPane: account.closed
            ? null
            : ActionPane(
                motion: const ScrollMotion(),
                extentRatio: 0.25,
                children: [
                  SlidableAction(
                    onPressed: (_) => onClose(),
                    backgroundColor: colors.error,
                    foregroundColor: colors.onError,
                    icon: Icons.block,
                    label: "Close",
                  ),
                ],
              ),
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
    );
  }
}
