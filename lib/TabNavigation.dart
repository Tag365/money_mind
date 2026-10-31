import 'package:flutter/material.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/tabs/add.dart';
import 'package:money_mind/tabs/list.dart';
import 'package:money_mind/tabs/account.dart';

class TabNavigation extends StatefulWidget {
  const TabNavigation({super.key});

  @override
  State createState() => _TabNavigationState();
}

class _TabNavigationState extends State<TabNavigation> {
  static const List<String> _titles = [
    "Statement Form",
    "Statements",
    "Accounts",
  ];

  int _index = 1;

  // Recurring statements fall due while the app is closed or in background.
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: DatabaseService.instance.addDueRecurrences,
    );
    DatabaseService.instance.addDueRecurrences();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      // IndexedStack keeps each tab (and its scroll position) alive.
      body: IndexedStack(
        index: _index,
        children: const [AddWidget(), ListWidget(), AccountWidget()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: "Create",
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: "Statements",
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: "Accounts",
          ),
        ],
      ),
    );
  }
}
