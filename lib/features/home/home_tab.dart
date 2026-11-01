import 'package:flutter/material.dart';
import 'package:money_mind/common/glass_background.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/features/home/widgets/total_balance_card.dart';
import 'package:money_mind/features/home/widgets/contracts_overview.dart';
import 'package:money_mind/features/home/widgets/month_overview.dart';
import 'package:money_mind/features/home/widgets/upcoming_card.dart';
import 'package:money_mind/features/settings/settings_page.dart';

/// Overview at a glance: total balance, a month by tag, what is due next and
/// what recurring statements cost per month.
/// Tapping the total calls [onOpenTab] with the index of the Accounts tab.
class HomeWidget extends StatefulWidget {
  final ValueChanged<int> onOpenTab;

  const HomeWidget({super.key, required this.onOpenTab});

  @override
  State<HomeWidget> createState() => _HomeState();
}

class _HomeState extends State<HomeWidget> {
  final DatabaseService databaseService = DatabaseService.instance;

  // Created once so rebuilds don't re-run the queries.
  late final Stream<List<Account>> _accounts = databaseService.watchAccounts();
  late final Stream<List<UpcomingPayment>> _upcoming = databaseService
      .watchUpcoming();

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Home"),
          actions: [
            IconButton(
              tooltip: "Settings",
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsPage())),
            ),
          ],
        ),
        body: _body(),
      ),
    );
  }

  Widget _body() {
    return StreamBuilder(
      stream: _accounts,
      builder: (context, accountsSnapshot) {
        if (accountsSnapshot.hasError) {
          return Center(child: Text('Error: ${accountsSnapshot.error}'));
        }
        if (!accountsSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final accounts = accountsSnapshot.data!;
        final accountNames = {for (final a in accounts) a.id: a.name};
        return ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            TotalBalanceCard(accounts, onTap: () => widget.onOpenTab(3)),
            const MonthOverview(),
            StreamBuilder(
              stream: _upcoming,
              builder: (context, snapshot) =>
                  UpcomingCard(snapshot.data ?? const [], accountNames),
            ),
            const ContractsOverview(),
          ],
        );
      },
    );
  }
}
