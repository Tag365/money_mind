import 'package:flutter/material.dart';
import 'package:money_mind/common/money_text.dart';
import 'package:money_mind/features/statements/grouping.dart';
import 'package:money_mind/features/statements/widgets/statement_tile.dart';

/// Date header with the day's total, followed by the day's statements.
class DayGroupView extends StatelessWidget {
  final DayGroup group;
  final Map<int, String> accountNames;

  const DayGroupView(this.group, this.accountNames, {super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          // The inner card's margin plus ListTile's insets, so the day total
          // lines up with the amounts below.
          padding: const EdgeInsetsDirectional.fromSTEB(24, 12, 32, 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  MaterialLocalizations.of(context).formatMediumDate(group.day),
                  style: textTheme.titleMedium,
                ),
              ),
              MoneyText(group.total, style: textTheme.bodyMedium),
            ],
          ),
        ),
        // Glass on the month card's glass, so each day stands out as a group.
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final s in group.statements) StatementTile(s, accountNames),
            ],
          ),
        ),
      ],
    );
  }
}
