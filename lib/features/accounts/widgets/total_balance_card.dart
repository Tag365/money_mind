import 'package:flutter/material.dart';
import 'package:money_mind/common/money_text.dart';
import 'package:money_mind/database/app_database.dart';

/// Highlighted card with the sum of all [accounts]' balances.
class TotalBalanceCard extends StatelessWidget {
  final List<Account> accounts;

  const TotalBalanceCard(this.accounts, {super.key});

  @override
  Widget build(BuildContext context) {
    final double total = accounts.fold(0, (sum, a) => sum + a.balance);
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Card(
      color: colors.primaryContainer,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Total balance",
              style: text.labelLarge?.copyWith(
                color: colors.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 4),
            MoneyText(total, style: text.headlineMedium),
          ],
        ),
      ),
    );
  }
}
