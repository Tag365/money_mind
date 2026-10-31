import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import 'package:money_mind/common/money_text.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/features/statements/recurrence_dialog.dart';
import 'package:money_mind/features/statements/statement_actions.dart';
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

  /// Closes the sheet, then runs [action] on the page below it.
  void _closeAnd(Future<void> Function(BuildContext, Statement) action) {
    final navigator = Navigator.of(context);
    navigator.pop();
    action(navigator.context, _statement);
  }

  Future<void> _editRecurrence(Recurrence? recurrence) async {
    // The row may be stale: read the current link to the series.
    final statement = _statement.copyWith(recurrence: Value(recurrence?.id));
    final service = DatabaseService.instance;
    final latest = await service.latestInSeries(statement);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => RecurrenceDialog(
        from: latest.paymentDate,
        recurrence: recurrence,
        onSave: (unit, every, ahead) =>
            service.setRecurrence(statement, unit, every, ahead: ahead),
        onTurnOff: () => service.stopRecurrence(recurrence!.id),
      ),
    );
  }

  Future<void> _delete() async {
    if (await deleteStatement(context, _statement) && mounted) {
      Navigator.pop(context);
    }
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
      // Clear of the system gesture bar.
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.viewPaddingOf(context).bottom,
      ),
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
                  onPressed: () => _closeAnd(editStatement),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
              ),
              // The Create form cannot make transfers.
              if (statement.transfer == null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _closeAnd(duplicateStatement),
                    icon: const Icon(Icons.copy_outlined),
                    label: const Text('Copy'),
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
