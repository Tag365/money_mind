import 'package:flutter/material.dart';

import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/features/statements/add_statement.dart';

/// Opens the Create form in edit mode as its own page.
Future<void> editStatement(BuildContext context, Statement statement) async {
  final messenger = ScaffoldMessenger.of(context);
  final saved = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => AddWidget(statement: statement),
    ),
  );
  if (saved == true) {
    messenger.showSnackBar(const SnackBar(content: Text('Statement updated')));
  }
}

/// Opens the Create form as its own page, filled in from [statement] but
/// dated now.
Future<void> duplicateStatement(
  BuildContext context,
  Statement statement,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final saved = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => AddWidget(copyOf: statement),
    ),
  );
  if (saved == true) {
    messenger.showSnackBar(const SnackBar(content: Text('Statement saved')));
  }
}

/// Asks, then deletes [statement]. Returns whether it was deleted.
Future<bool> deleteStatement(BuildContext context, Statement statement) async {
  final messenger = ScaffoldMessenger.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete statement?'),
      content: Text(
        statement.transfer == null
            ? '"${statement.title}" will be removed and its amount taken '
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
  if (confirmed != true) return false;
  await DatabaseService.instance.deleteStatement(statement);
  messenger.showSnackBar(const SnackBar(content: Text('Statement deleted')));
  return true;
}
