import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:money_mind/common/glass_background.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/features/accounts/account_form.dart';
import 'package:money_mind/features/accounts/transfer_form.dart';
import 'package:money_mind/features/accounts/widgets/account_tile.dart';
import 'package:money_mind/features/accounts/widgets/no_accounts_hint.dart';
import 'package:money_mind/features/statements/statement_filter.dart';
import 'package:money_mind/features/statements/statement_list.dart';

import 'package:money_mind/database/app_database.dart';

class AccountWidget extends StatefulWidget {
  const AccountWidget({super.key});

  @override
  State<AccountWidget> createState() => _AccountState();
}

class _AccountState extends State<AccountWidget> {
  DatabaseService databaseService = DatabaseService.instance;

  void _openAddAccountModal() {
    showModalBottomSheet(
      isScrollControlled: true,
      showDragHandle: true,
      context: context,
      builder: (BuildContext context) => const AccountForm(),
    );
  }

  Future<void> _closeAccount(Account account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Close "${account.name}"?'),
        content: const Text(
          'Its statements stay in the list, but it cannot get new ones. '
          'Recurring statements stop.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Close account'),
          ),
        ],
      ),
    );
    if (confirmed == true) await databaseService.closeAccount(account);
  }

  // Created once so rebuilds don't re-run the query; updates automatically
  // when accounts or balances change.
  late final Stream<List<Account>> _accounts = databaseService.watchAccounts();

  /// Inserts 10 years of fake statements (~10 per day) in one batch.
  Future<void> _insertSpeedtestStatements(Account account) async {
    final Random rng = Random(0);
    final DateTime now = DateTime.now();
    await databaseService.addStatements([
      for (int i = 0; i < 36_500; i++)
        StatementsCompanion.insert(
          title: "Speedtest transfer $i",
          createdAt: now,
          paymentDate: now.subtract(Duration(minutes: i * 144)),
          account: account.id,
          useDate: now.subtract(Duration(minutes: i * 144)),
          amount: rng.nextDouble() * 10 * (rng.nextBool() ? 1 : -1),
          tags: ["speedtest"],
          note: "",
        ),
    ]);
  }

  List<Widget> _actions(List<Account> accounts) {
    final open = accounts.where((a) => !a.closed).toList();
    return [
      // Dev tool: only offered when there is an account to fill.
      if (kDebugMode && open.isNotEmpty)
        IconButton(
          tooltip: "Insert speedtest statements",
          onPressed: () => _insertSpeedtestStatements(open.first),
          icon: const Icon(Icons.speed),
        ),
      if (open.length >= 2)
        IconButton(
          tooltip: "Transfer",
          onPressed: () => showModalBottomSheet(
            isScrollControlled: true,
            showDragHandle: true,
            context: context,
            builder: (context) => TransferForm(accounts: open),
          ),
          icon: const Icon(Icons.swap_horiz),
        ),
      IconButton(
        tooltip: "Add account",
        onPressed: _openAddAccountModal,
        icon: const Icon(Icons.add),
      ),
    ];
  }

  Widget _body(AsyncSnapshot<List<Account>> asyncSnapshot) {
    if (asyncSnapshot.hasError) {
      return Center(child: Text('Error: ${asyncSnapshot.error}'));
    }
    if (!asyncSnapshot.hasData) {
      // Show a placeholder while loading
      return Center(child: CircularProgressIndicator());
    }
    final accounts = asyncSnapshot.data!;
    if (accounts.isEmpty) return NoAccountsHint(onAdd: _openAddAccountModal);
    return SlidableAutoCloseBehavior(
      child: ListView(
        children: [
          for (final account in accounts)
            AccountTile(
              account,
              onClose: () => _closeAccount(account),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ListWidget(
                    title: account.name,
                    filter: StatementFilter(accounts: {account.id}),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _accounts,
      builder: (context, asyncSnapshot) => GlassBackground(
        child: Scaffold(
          appBar: AppBar(
            title: const Text("Accounts"),
            actions: _actions(asyncSnapshot.data ?? []),
          ),
          body: _body(asyncSnapshot),
        ),
      ),
    );
  }
}
