import 'package:flutter/material.dart';
import 'package:money_mind/tabs/add.dart';
import 'package:money_mind/tabs/list.dart';
import 'package:money_mind/tabs/account.dart';

class TabNavigation extends StatefulWidget {
  // Icons from the TabController
  final List<Tab> myTabs = [
    Tab(icon: Icon(Icons.add)),
    Tab(icon: Icon(Icons.list)),
    Tab(icon: Icon(Icons.account_balance)),
  ];

  TabNavigation({super.key});

  @override
  State createState() => _TabNavigationState();
}

class _TabNavigationState extends State<TabNavigation>
    with SingleTickerProviderStateMixin {
  int previousTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: widget.myTabs.length,
      child: Builder(
        builder: (BuildContext context) {
          final TabController tabController = DefaultTabController.of(context);
          tabController.addListener(() {
            if (tabController.index != previousTabIndex) {
              previousTabIndex = tabController.index;
            }
          });
          return Scaffold(
            appBar: AppBar(
              bottom: TabBar(tabs: widget.myTabs),
              title: Text("Money Mind"),
            ),
            body: TabBarView(
              controller: tabController,
              children: [AddWidget(), ListWidget(), AccountWidget()],
            ),
          );
        },
      ),
    );
  }
}
