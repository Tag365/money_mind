import 'package:flutter/material.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/features/statements/add_statement.dart';
import 'package:money_mind/features/statements/statement_list.dart';
import 'package:money_mind/features/accounts/accounts_tab.dart';
import 'package:money_mind/features/home/home_tab.dart';

class TabNavigation extends StatefulWidget {
  const TabNavigation({super.key});

  @override
  State createState() => _TabNavigationState();
}

class _TabNavigationState extends State<TabNavigation> {
  int _index = 0;

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

  void _select(int index) {
    // A field focused in the tab left behind would keep the keyboard open.
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Each tab has its own app bar, with that tab's secondary actions.
      // IndexedStack keeps each tab (and its scroll position) alive.
      body: IndexedStack(
        index: _index,
        children: [
          HomeWidget(onOpenTab: _select),
          AddWidget(active: _index == 1),
          const ListWidget(),
          const AccountWidget(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: "Home",
          ),
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
