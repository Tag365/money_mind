import 'package:flutter/material.dart';
import 'package:money_mind/common/amount_expression.dart';
import 'package:money_mind/common/money_text.dart';

/// Big centered amount input. Accepts sums like "12,50 + 3" and shows the
/// result ("= 15,50 €") below while it holds more than one charge.
class AmountField extends StatelessWidget {
  final TextEditingController controller;

  /// Red for expenses, green for income; colors the typed amount and the sum.
  final Color color;

  /// Shown at the end of the field, opposite the € sign.
  final Widget? trailing;

  /// Called by the keyboard's Next key.
  final VoidCallback? onNext;

  const AmountField({
    super.key,
    required this.controller,
    required this.color,
    this.trailing,
    this.onNext,
  });

  /// "= 19,70 €" while [text] holds more than one charge, else null.
  static String? _total(String text) {
    text = text.trim();
    if (!text.substring(text.isEmpty ? 0 : 1).contains(RegExp('[+-]'))) {
      return null;
    }
    final total = evaluateAmount(text);
    return total == null ? null : '= ${formatMoney(total)}';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        TextFormField(
          controller: controller,
          textInputAction: onNext == null ? null : TextInputAction.next,
          onEditingComplete: onNext,
          textAlign: TextAlign.center,
          style: textTheme.displaySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: '0,00',
            filled: false,
            border: InputBorder.none,
            prefixIcon: const Icon(Icons.euro_sharp),
            suffixIcon: trailing,
          ),
          // signed: shows a minus key on the number keyboard.
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          validator: (value) {
            final amount = evaluateAmount(value ?? '');
            if (amount == null || amount <= 0) {
              return 'Please enter a positive amount';
            }
            return null;
          },
        ),
        // Rebuilds only the total line on each keystroke.
        ValueListenableBuilder(
          valueListenable: controller,
          builder: (context, value, _) {
            final total = _total(value.text);
            if (total == null) return const SizedBox.shrink();
            return Text(
              total,
              style: textTheme.titleMedium?.copyWith(color: color),
            );
          },
        ),
      ],
    );
  }
}
