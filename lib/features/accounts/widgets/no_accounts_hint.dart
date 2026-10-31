import 'package:flutter/material.dart';

/// Shown on the Accounts tab before the first account exists.
class NoAccountsHint extends StatelessWidget {
  const NoAccountsHint({super.key});

  @override
  Widget build(BuildContext context) {
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
}
