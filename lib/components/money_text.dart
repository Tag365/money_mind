import 'package:flutter/material.dart';

/// Amount in euros, green for income and red for expenses.
class MoneyText extends StatelessWidget {
  final double amount;
  final TextStyle? style;

  const MoneyText(this.amount, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    final color = amount < 0 ? Colors.red.shade400 : Colors.green.shade600;
    return Text(
      "${amount.toStringAsFixed(2)} €",
      style: (style ?? Theme.of(context).textTheme.titleMedium)?.copyWith(
        color: color,
        fontWeight: FontWeight.w600,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
