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
        // ListTile's insets, so the total lines up with the balances below.
        padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 24, 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                "Total balance",
                style: text.titleMedium?.copyWith(
                  color: colors.onPrimaryContainer,
                ),
              ),
            ),
            MoneyText(total, style: text.titleLarge),
          ],
        ),
      ),
    );
  }
}
