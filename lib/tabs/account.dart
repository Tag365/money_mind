import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:money_mind/components/money_text.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/database/models/AccountType.dart';
import 'package:money_mind/modals/account_form.dart';
import 'package:money_mind/modals/transfer_form.dart';

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
    final Stopwatch stopwatch = Stopwatch()..start();
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
    print("Inserted 36500 statements in ${stopwatch.elapsedMilliseconds} ms");
  }

  Widget _totalCard(List<Account> accounts) {
    final double total = accounts.fold(0, (sum, a) => sum + a.balance);
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Card(
      color: colors.primaryContainer,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Total balance",
              style: text.labelLarge?.copyWith(
                color: colors.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 4),
            MoneyText(total, style: text.headlineMedium),
          ],
        ),
      ),
    );
  }

  Widget _list(List<Account> accounts) {
    if (accounts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            const Text("No accounts yet"),
            const SizedBox(height: 4),
            const Text("Tap \"Add account\" to create your first one."),
          ],
        ),
      );
    }
    final colors = Theme.of(context).colorScheme;
    return SlidableAutoCloseBehavior(
      child: ListView.builder(
        // Leave room so the last card isn't hidden behind the buttons.
        padding: const EdgeInsets.only(bottom: 140),
        itemCount: accounts.length + 1,
        itemBuilder: ((context, index) {
          if (index == 0) return _totalCard(accounts);
          final Account account = accounts[index - 1];
          return Card(
            clipBehavior: Clip.antiAlias,
            child: Slidable(
              groupTag: "0",
              endActionPane: account.closed
                  ? null
                  : ActionPane(
                      motion: ScrollMotion(),
                      extentRatio: 0.25,
                      children: [
                        SlidableAction(
                          onPressed: (_) => _closeAccount(account),
                          backgroundColor: colors.error,
                          foregroundColor: colors.onError,
                          icon: Icons.block,
                          label: "Close",
                        ),
                      ],
                    ),
              child: ListTile(
                enabled: !account.closed,
                leading: CircleAvatar(
                  backgroundColor: colors.secondaryContainer,
                  foregroundColor: colors.onSecondaryContainer,
                  child: Icon(
                    account.type == AccountType.creditCard
                        ? Icons.credit_card
                        : Icons.account_balance_wallet_outlined,
                  ),
                ),
                title: Text(account.name),
                subtitle: Text(
                  account.closed
                      ? "${account.type.displayName} · Closed"
                      : account.type.displayName,
                ),
                trailing: Opacity(
                  opacity: account.closed ? 0.5 : 1,
                  child: MoneyText(account.balance),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _actions(List<Account> accounts) {
    final open = accounts.where((a) => !a.closed).toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      spacing: 12,
      children: [
        // Dev tool: only offered when there is an account to fill.
        if (kDebugMode && open.isNotEmpty)
          FloatingActionButton.small(
            heroTag: "speedtest",
            tooltip: "Insert speedtest statements",
            onPressed: () => _insertSpeedtestStatements(open.first),
            child: const Icon(Icons.speed),
          ),
        if (open.length >= 2)
          FloatingActionButton.extended(
            heroTag: "transfer",
            onPressed: () => showModalBottomSheet(
              isScrollControlled: true,
              showDragHandle: true,
              context: context,
              builder: (context) => TransferForm(accounts: open),
            ),
            icon: const Icon(Icons.swap_horiz),
            label: const Text("Transfer"),
          ),
        FloatingActionButton.extended(
          heroTag: "add",
          onPressed: _openAddAccountModal,
          icon: const Icon(Icons.add),
          label: const Text("Add account"),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _accounts,
      builder: (context, asyncSnapshot) {
        if (asyncSnapshot.hasError) {
          return Center(child: Text('Error: ${asyncSnapshot.error}'));
        }
        if (!asyncSnapshot.hasData) {
          // Show a placeholder while loading
          return Center(child: CircularProgressIndicator());
        }
        return Scaffold(
          body: _list(asyncSnapshot.data!),
          floatingActionButton: _actions(asyncSnapshot.data!),
        );
      },
    );
  }
}
