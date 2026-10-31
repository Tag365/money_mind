import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primaryContainer, colors.surface],
        ),
      ),
      // Transparent, so the gradient shows through.
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text("Home"),
          backgroundColor: Colors.transparent,
          // Transparent reads as dark, which would give white status bar
          // icons in light mode.
          systemOverlayStyle: Theme.of(context).brightness == Brightness.dark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark,
        ),
        // Glassy cards: translucent with a faint edge, so the gradient shows
        // through.
        body: Theme(
          data: Theme.of(context).copyWith(
            cardTheme: Theme.of(context).cardTheme.copyWith(
              // Glass lightens what is behind it, also in dark mode.
              color: colors.brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.06)
                  : colors.surface.withValues(alpha: 0.35),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: colors.onSurface.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),
          child: _body(),
        ),
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
