import 'package:flutter/material.dart';

/// "12.50 €". Rounds to cents first, so float drift never shows "-0.00 €".
String formatMoney(double amount) =>
    "${((amount * 100).round() / 100).toStringAsFixed(2)} €";

/// Amount in euros, green for income and red for expenses.
class MoneyText extends StatelessWidget {
  final double amount;
  final TextStyle? style;

  const MoneyText(this.amount, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    final color = (amount * 100).round() < 0
        ? Colors.red.shade400
        : Colors.green.shade600;
    return Text(
      formatMoney(amount),
      style: (style ?? Theme.of(context).textTheme.titleMedium)?.copyWith(
        color: color,
        fontWeight: FontWeight.w600,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
