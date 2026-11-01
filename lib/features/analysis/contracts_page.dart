import 'package:flutter/material.dart';
import 'package:money_mind/common/donut_chart.dart';
import 'package:money_mind/common/glass_background.dart';
import 'package:money_mind/common/money_text.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/features/analysis/contracts.dart';
import 'package:money_mind/features/analysis/tag_breakdown.dart';
import 'package:money_mind/features/analysis/widgets/contract_section.dart';

/// The recurring statements: what they cost per month in a ring by tag, then
/// the costs grouped by top-level tag, largest first, and the income.
class ContractsPage extends StatefulWidget {
  const ContractsPage({super.key});

  @override
  State<ContractsPage> createState() => _ContractsPageState();
}

class _ContractsPageState extends State<ContractsPage> {
  final DatabaseService databaseService = DatabaseService.instance;

  // Created once so rebuilds don't re-run the queries.
  late final Stream<List<Contract>> _contracts = databaseService
      .watchContracts();
  late final Stream<List<Tag>> _tags = databaseService.watchTags();
  late final Stream<List<Account>> _accounts = databaseService.watchAccounts();

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
        appBar: AppBar(title: const Text("Contracts")),
        body: StreamBuilder(
          stream: _accounts,
          builder: (context, accountsSnapshot) => StreamBuilder(
            stream: _tags,
            builder: (context, tagsSnapshot) => StreamBuilder(
              stream: _contracts,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return _body(
                  snapshot.data!,
                  tagColors(tagsSnapshot.data ?? const []),
                  {for (final a in accountsSnapshot.data ?? []) a.id: a.name},
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(
    List<Contract> contracts,
    Map<String, Color> colors,
    Map<int, String> accountNames,
  ) {
    if (contracts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            "No contracts yet. Make a statement repeat to see it here.",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    // Largest monthly amount first.
    final sorted = [
      ...contracts,
    ]..sort((a, b) => monthlyAmount(b).abs().compareTo(monthlyAmount(a).abs()));
    final costs = sorted.where((c) => monthlyAmount(c) < 0).toList();
    final income = sorted.where((c) => monthlyAmount(c) >= 0).toList();
    final shares = tagBreakdown(monthlyTotals(costs), income: false);
    final total = shares.fold(0.0, (s, e) => s + e.amount);
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Center(
            child: DonutChart(
              [for (final s in shares) (tagColor(colors, s.tag), s.amount)],
              center: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Costs per month", style: text.labelLarge),
                  MoneyText(total, style: text.headlineSmall),
                ],
              ),
            ),
          ),
        ),
        for (final s in shares)
          ContractSection(
            title: s.tag == untagged ? "No tag" : s.tag,
            color: tagColor(colors, s.tag),
            contracts: [
              for (final c in costs)
                if (contractGroup(c) == s.tag) c,
            ],
            accountNames: accountNames,
          ),
        if (income.isNotEmpty)
          ContractSection(
            title: "Income",
            color: incomeColor,
            contracts: income,
            accountNames: accountNames,
          ),
      ],
    );
  }
}
