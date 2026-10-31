import 'package:flutter/material.dart';
import 'package:money_mind/common/money_text.dart';
import 'package:money_mind/database/app_database.dart';

/// The sum of all [accounts]' balances.
class TotalBalanceCard extends StatelessWidget {
  final List<Account> accounts;

  const TotalBalanceCard(this.accounts, {super.key});

  @override
  Widget build(BuildContext context) {
    final double total = accounts.fold(0, (sum, a) => sum + a.balance);
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 28),
      child: Column(
        children: [
          Text(
            "Total",
            style: text.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          MoneyText(total, style: text.headlineMedium),
        ],
      ),
    );
  }
}
