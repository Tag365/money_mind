import 'package:flutter/material.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/features/analysis/contracts.dart';
import 'package:money_mind/features/analysis/contracts_page.dart';
import 'package:money_mind/features/analysis/tag_breakdown.dart';
import 'package:money_mind/features/home/widgets/breakdown_card.dart';

/// What the recurring statements cost per month, by tag; opens
/// [ContractsPage].
class ContractsOverview extends StatefulWidget {
  const ContractsOverview({super.key});

  @override
  State<ContractsOverview> createState() => _ContractsOverviewState();
}

class _ContractsOverviewState extends State<ContractsOverview> {
  // Created once so rebuilds don't re-run the queries.
  late final Stream<List<Contract>> _contracts = DatabaseService.instance
      .watchContracts();
  late final Stream<List<Tag>> _tags = DatabaseService.instance.watchTags();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: StreamBuilder(
        stream: _tags,
        builder: (context, tagsSnapshot) => StreamBuilder(
          stream: _contracts,
          builder: (context, snapshot) {
            final totals = monthlyTotals(snapshot.data ?? const []);
            return BreakdownCard(
              title: "Contracts per month",
              total: totals.fold(0.0, (s, t) => s + t.expense),
              shares: tagBreakdown(totals, income: false),
              colors: tagColors(tagsSnapshot.data ?? const []),
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ContractsPage())),
            );
          },
        ),
      ),
    );
  }
}
