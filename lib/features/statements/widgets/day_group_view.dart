import 'package:flutter/material.dart';
import 'package:money_mind/common/money_text.dart';
import 'package:money_mind/features/statements/grouping.dart';
import 'package:money_mind/features/statements/widgets/statement_tile.dart';

/// Date header with the day's total, followed by the day's statements in a
/// card.
class DayGroupView extends StatelessWidget {
  final DayGroup group;
  final Map<int, String> accountNames;

  const DayGroupView(this.group, this.accountNames, {super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    MaterialLocalizations.of(
                      context,
                    ).formatMediumDate(group.day),
                    style: textTheme.titleMedium,
                  ),
                ),
                MoneyText(group.total, style: textTheme.bodyMedium),
              ],
            ),
          ),
          Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final s in group.statements)
                  StatementTile(s, accountNames),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
