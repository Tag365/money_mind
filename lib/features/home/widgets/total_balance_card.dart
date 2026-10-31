import 'package:flutter/material.dart';
import 'package:money_mind/common/money_text.dart';
import 'package:money_mind/database/app_database.dart';

/// The sum of all [accounts]' balances. Tapping it calls [onTap].
class TotalBalanceCard extends StatelessWidget {
  final List<Account> accounts;
  final VoidCallback onTap;

  const TotalBalanceCard(this.accounts, {super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final double total = accounts.fold(0, (sum, a) => sum + a.balance);
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
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
      ),
    );
  }
}
