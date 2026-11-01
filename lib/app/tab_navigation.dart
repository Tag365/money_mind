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
  final _pages = PageController();

  // Recurring statements fall due while the app is closed or in background.
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () {
        DatabaseService.instance.recheckDates();
        DatabaseService.instance.addDueRecurrences();
      },
    );
    DatabaseService.instance.addDueRecurrences();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _pages.dispose();
    super.dispose();
  }

  void _select(int index) => _pages.animateToPage(
    index,
    duration: const Duration(milliseconds: 250),
    curve: Curves.easeOut,
  );

  void _onPageChanged(int index) {
    // A field focused in the tab left behind would keep the keyboard open.
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Each tab has its own app bar, with that tab's secondary actions.
      // Swipe between tabs; _KeepAlive keeps each one (and its scroll
      // position) alive while off screen.
      body: PageView(
        controller: _pages,
        onPageChanged: _onPageChanged,
        children: [
          _KeepAlive(HomeWidget(onOpenTab: _select)),
          _KeepAlive(AddWidget(active: _index == 1)),
          const _KeepAlive(ListWidget()),
          const _KeepAlive(AccountWidget()),
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

class _KeepAlive extends StatefulWidget {
  const _KeepAlive(this.child);

  final Widget child;

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
