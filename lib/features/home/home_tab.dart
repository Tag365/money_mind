import 'package:flutter/material.dart';
import 'package:money_mind/common/glass_background.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/features/home/widgets/total_balance_card.dart';
import 'package:money_mind/features/home/widgets/month_summary_card.dart';
import 'package:money_mind/features/home/widgets/upcoming_card.dart';

/// Overview at a glance: total balance, this month so far and what is due
/// next.
class HomeWidget extends StatefulWidget {
  const HomeWidget({super.key});

  @override
  State<HomeWidget> createState() => _HomeState();
}

class _HomeState extends State<HomeWidget> {
  final DatabaseService databaseService = DatabaseService.instance;

  // Created once so rebuilds don't re-run the queries.
  late final Stream<List<Account>> _accounts = databaseService.watchAccounts();
  late final Stream<List<PeriodTotal>> _totals = databaseService.watchTotals(
    yearly: false,
    transfers: false,
  );
  late final Stream<List<UpcomingPayment>> _upcoming = databaseService
      .watchUpcoming();

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
        appBar: AppBar(title: const Text("Home")),
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
            TotalBalanceCard(accounts),
            StreamBuilder(
              stream: _totals,
              builder: (context, snapshot) {
                final now = DateTime.now();
                // Totals may also hold later months with statements created
                // ahead, so look the current one up.
                final month = snapshot.data
                    ?.where((p) => p.start == DateTime(now.year, now.month))
                    .firstOrNull;
                return MonthSummaryCard(month);
              },
            ),
            StreamBuilder(
              stream: _upcoming,
              builder: (context, snapshot) =>
                  UpcomingCard(snapshot.data ?? const [], accountNames),
            ),
          ],
        );
      },
    );
  }
}
