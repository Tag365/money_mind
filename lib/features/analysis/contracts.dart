import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/features/analysis/tag_breakdown.dart';

/// What [contract] pays (negative) or earns per average month.
double monthlyAmount(Contract contract) {
  final r = contract.recurrence;
  return contract.statement.amount * r.unit.perMonth / r.every;
}

/// The monthly amounts of [contracts] in the shape [tagBreakdown] takes.
List<TagTotal> monthlyTotals(Iterable<Contract> contracts) => [
  for (final c in contracts)
    (
      tags: c.statement.tags,
      income: monthlyAmount(c) >= 0 ? monthlyAmount(c) : 0.0,
      expense: monthlyAmount(c) < 0 ? monthlyAmount(c) : 0.0,
    ),
];

/// The tag [contract] is grouped under, as in [tagBreakdown].
String contractGroup(Contract contract) =>
    topLevelTag(contract.statement.tags.firstOrNull ?? untagged);
