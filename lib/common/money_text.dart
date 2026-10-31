import 'package:flutter/material.dart';

/// Colors for income and expenses, used everywhere an amount is shown.
/// Muted, so they read on both the light and the dark theme.
const Color incomeColor = Color(0xFF6B9E7D);
const Color expenseColor = Color(0xFFC86B67);

/// "1.234,50 €", German style like the amount input. Rounds to cents first,
/// so float drift never shows "-0,00 €".
String formatMoney(double amount) {
  final cents = (amount * 100).round();
  final euros = (cents.abs() ~/ 100).toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+$)'),
    (_) => '.',
  );
  final rest = (cents.abs() % 100).toString().padLeft(2, '0');
  return "${cents < 0 ? '-' : ''}$euros,$rest €";
}

/// Amount in euros, green for income and red for expenses.
class MoneyText extends StatelessWidget {
  final double amount;
  final TextStyle? style;

  const MoneyText(this.amount, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    final color = (amount * 100).round() < 0 ? expenseColor : incomeColor;
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
