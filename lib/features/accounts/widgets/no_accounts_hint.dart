import 'package:flutter/material.dart';

/// Shown on the Accounts tab before the first account exists, with a big
/// button since the app bar's add icon is easy to miss there.
class NoAccountsHint extends StatelessWidget {
  final VoidCallback onAdd;

  const NoAccountsHint({super.key, required this.onAdd});

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
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text("Add account"),
          ),
        ],
      ),
    );
  }
}
