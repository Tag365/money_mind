import 'package:flutter/material.dart';
import 'package:money_mind/common/money_text.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/database/models/recurrences.dart';
import 'package:money_mind/features/analysis/contracts.dart';
import 'package:money_mind/features/statements/recurrence_dialog.dart';
import 'package:money_mind/features/statements/statement_details_sheet.dart';

/// [title] with the monthly sum of [contracts], then each contract with its
/// amount and interval; tapping one shows its newest statement.
class ContractSection extends StatelessWidget {
  final String title;
  final Color color;
  final List<Contract> contracts;
  final Map<int, String> accountNames;

  const ContractSection({
    super.key,
    required this.title,
    required this.color,
    required this.contracts,
    required this.accountNames,
  });

  @override
  Widget build(BuildContext context) {
    final monthly = contracts.fold(0.0, (s, c) => s + monthlyAmount(c));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            spacing: 8,
            children: [
              Icon(Icons.circle, size: 10, color: color),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              MoneyText(monthly),
            ],
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final c in contracts)
                ListTile(
                  title: Text(c.statement.title),
                  subtitle: Text(
                    [
                      describeInterval(c.recurrence.unit, c.recurrence.every),
                      if (c.recurrence.unit != RecurrenceUnit.month ||
                          c.recurrence.every > 1)
                        "${formatMoney(monthlyAmount(c))} per month",
                    ].join(" · "),
                  ),
                  trailing: MoneyText(c.statement.amount),
                  onTap: () => showModalBottomSheet(
                    isScrollControlled: true,
                    showDragHandle: true,
                    context: context,
                    builder: (context) => StatementDetailsSheet((
                      statement: c.statement,
                      balance: null,
                    ), accountNames[c.statement.account]),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
