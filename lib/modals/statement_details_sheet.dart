import 'package:flutter/material.dart';

import 'package:money_mind/components/money_text.dart';
import 'package:money_mind/components/tag_label.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/database_service.dart';

/// Shows all information of one statement, with edit and delete actions.
class StatementDetailsSheet extends StatefulWidget {
  final StatementWithBalance row;
  final String? accountName;

  const StatementDetailsSheet(this.row, this.accountName, {super.key});

  @override
  State<StatementDetailsSheet> createState() => _StatementDetailsSheetState();
}

class _StatementDetailsSheetState extends State<StatementDetailsSheet> {
  late final Stream<List<Tag>> _tags = DatabaseService.instance.watchTags();

  Statement get _statement => widget.row.statement;

  Widget _info(IconData icon, String label, Widget value) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon),
    title: Text(label, style: Theme.of(context).textTheme.labelMedium),
    subtitle: DefaultTextStyle.merge(
      style: Theme.of(context).textTheme.bodyLarge,
      child: value,
    ),
  );

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete statement?'),
        content: Text(
          '"${_statement.title}" will be removed and its amount taken out of '
          'the account balance.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    await DatabaseService.instance.deleteStatement(_statement);
    if (!mounted) return;
    Navigator.pop(context);
    messenger.showSnackBar(const SnackBar(content: Text('Statement deleted')));
  }

  @override
  Widget build(BuildContext context) {
    final statement = _statement;
    final balance = widget.row.balance;
    final paid = statement.paymentDate.toLocal();
    final used = statement.useDate.toLocal();
    final sameDay = DateUtils.isSameDay(paid, used);
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(statement.title, style: textTheme.headlineSmall),
          const SizedBox(height: 4),
          MoneyText(statement.amount, style: textTheme.headlineMedium),
          const SizedBox(height: 8),
          _info(
            Icons.event,
            'Payment date',
            // ISO 8601 in local time, to the minute: 2026-10-31 14:00.
            Text(
              paid.toIso8601String().substring(0, 16).replaceFirst('T', ' '),
            ),
          ),
          if (!sameDay)
            _info(
              Icons.event_available,
              'Use date',
              Text(MaterialLocalizations.of(context).formatFullDate(used)),
            ),
          _info(
            Icons.account_balance_wallet_outlined,
            'Account',
            Text(
              [
                widget.accountName ?? 'Deleted account',
                if (balance != null)
                  'balance after: ${balance.toStringAsFixed(2)} €',
              ].join(' · '),
            ),
          ),
          if (statement.tags.isNotEmpty)
            _info(
              Icons.sell_outlined,
              'Tags',
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: StreamBuilder(
                  stream: _tags,
                  builder: (context, snapshot) {
                    final colors = {
                      for (final t in snapshot.data ?? <Tag>[])
                        t.name: Color(t.color),
                    };
                    return Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final tag in statement.tags)
                          TagLabel(
                            tag,
                            // Tags not in the Tags table (e.g. "Auto-generated").
                            colors[tag] ??
                                Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          if (statement.note.isNotEmpty)
            _info(Icons.notes, 'Note', Text(statement.note)),
          const SizedBox(height: 16),
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  // Editing is not designed yet.
                  onPressed: null,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
              ),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
