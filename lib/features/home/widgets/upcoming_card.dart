import 'package:flutter/material.dart';
import 'package:money_mind/common/money_text.dart';
import 'package:money_mind/database/database_service.dart';

/// The next payments with their date and account, recurring ones marked.
class UpcomingCard extends StatelessWidget {
  final List<UpcomingPayment> upcoming;
  final Map<int, String> accountNames;

  const UpcomingCard(this.upcoming, this.accountNames, {super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              "Upcoming",
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (upcoming.isEmpty)
            const ListTile(title: Text("Nothing scheduled")),
          for (final (:statement, :date) in upcoming)
            ListTile(
              title: Row(
                spacing: 4,
                children: [
                  Flexible(
                    child: Text(
                      statement.title,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (statement.recurrence != null)
                    const Icon(
                      Icons.repeat,
                      size: 16,
                      semanticLabel: 'Recurring',
                    ),
                ],
              ),
              subtitle: Text(
                [
                  localizations.formatMediumDate(date.toLocal()),
                  ?accountNames[statement.account],
                ].join(" · "),
                overflow: TextOverflow.ellipsis,
              ),
              trailing: MoneyText(statement.amount),
            ),
        ],
      ),
    );
  }
}
