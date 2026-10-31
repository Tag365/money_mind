import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import 'package:money_mind/common/money_text.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/features/statements/add_statement.dart';
import 'package:money_mind/features/statements/recurrence_dialog.dart';
import 'package:money_mind/features/statements/widgets/info_tile.dart';
import 'package:money_mind/features/tags/widgets/tag_labels.dart';

/// Shows all information of one statement, with edit and delete actions.
class StatementDetailsSheet extends StatefulWidget {
  final StatementWithBalance row;
  final String? accountName;

  const StatementDetailsSheet(this.row, this.accountName, {super.key});

  @override
  State<StatementDetailsSheet> createState() => _StatementDetailsSheetState();
}

class _StatementDetailsSheetState extends State<StatementDetailsSheet> {
  late final Stream<Recurrence?> _recurrence = DatabaseService.instance
      .watchRecurrence(_statement.id);

  Statement get _statement => widget.row.statement;

  /// Closes the sheet and opens the Create form in edit mode as its own page.
  Future<void> _edit() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    navigator.pop();
    final saved = await navigator.push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AddWidget(statement: _statement),
      ),
    );
    if (saved == true) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Statement updated')),
      );
    }
  }

  Future<void> _editRecurrence(Recurrence? recurrence) async {
    // The row may be stale: read the current link to the series.
    final statement = _statement.copyWith(recurrence: Value(recurrence?.id));
    final latest = await DatabaseService.instance.latestInSeries(statement);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => RecurrenceDialog(statement, latest, recurrence),
    );
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete statement?'),
        content: Text(
          _statement.transfer == null
              ? '"${_statement.title}" will be removed and its amount taken '
                    'out of the account balance.'
              : 'Both sides of the transfer will be removed and the account '
                    'balances restored.',
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
          InfoTile(
            Icons.event,
            'Payment date',
            // ISO 8601 in local time, to the minute: 2026-10-31 14:00.
            Text(
              paid.toIso8601String().substring(0, 16).replaceFirst('T', ' '),
            ),
          ),
          if (!sameDay)
            InfoTile(
              Icons.event_available,
              'Use date',
              Text(MaterialLocalizations.of(context).formatFullDate(used)),
            ),
          InfoTile(
            Icons.account_balance_wallet_outlined,
            'Account',
            Text(
              [
                widget.accountName ?? 'Deleted account',
                if (balance != null) 'balance after: ${formatMoney(balance)}',
              ].join(' · '),
            ),
          ),
          if (statement.tags.isNotEmpty)
            InfoTile(
              Icons.sell_outlined,
              'Tags',
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: TagLabels(statement.tags),
              ),
            ),
          if (statement.note.isNotEmpty)
            InfoTile(Icons.notes, 'Note', Text(statement.note)),
          // shortcut: a repeated copy would book only one side of a transfer,
          // so transfers cannot repeat until series copy both sides.
          if (statement.transfer == null)
            StreamBuilder(
              stream: _recurrence,
              builder: (context, snapshot) {
                final recurrence = snapshot.data;
                return InfoTile(
                  Icons.repeat,
                  'Repeats',
                  Text(
                    recurrence == null
                        ? 'Never'
                        : describeInterval(recurrence.unit, recurrence.every),
                  ),
                  onTap: snapshot.connectionState == ConnectionState.waiting
                      ? null
                      : () => _editRecurrence(recurrence),
                );
              },
            ),
          const SizedBox(height: 16),
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _edit,
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
