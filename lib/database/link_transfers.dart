import 'package:drift/drift.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/database_service.dart';

/// Links unlinked statements tagged "Transfer" in pairs, as [addTransfer]
/// would have: same day, opposite amounts, different accounts. Of several
/// matches the one nearest by id wins, as an import adds both sides of a
/// transfer next to each other. A side with no match stays as it is.
/// Returns the number of pairs linked.
///
/// Runs inside the caller's transaction or migration.
Future<int> linkTransfers(AppDatabase db) async {
  final tbl = db.statements;
  // Commas around the joined list make a tag match only whole entries.
  final tagList = const Constant(',') + tbl.tags + const Constant(',');
  final open =
      await (db.select(tbl)
            ..where(
              (s) =>
                  s.transfer.isNull() &
                  tagList.like('%,${DatabaseService.transferTag},%'),
            )
            ..orderBy([(s) => OrderingTerm(expression: s.id)]))
          .get();

  int cents(double amount) => (amount * 100).round();
  bool sameDay(DateTime a, DateTime b) {
    a = a.toLocal();
    b = b.toLocal();
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  final linked = <int>{};
  var pairs = 0;
  for (final out in open.where((s) => s.amount < 0)) {
    Statement? into;
    for (final s in open) {
      if (linked.contains(s.id) ||
          s.account == out.account ||
          cents(s.amount) != -cents(out.amount) ||
          !sameDay(s.paymentDate, out.paymentDate)) {
        continue;
      }
      if (into == null || (s.id - out.id).abs() < (into.id - out.id).abs()) {
        into = s;
      }
    }
    final partner = into;
    if (partner == null) continue;
    linked.add(partner.id);
    await (db.update(tbl)..where((s) => s.id.equals(out.id))).write(
      StatementsCompanion(transfer: Value(partner.id)),
    );
    await (db.update(tbl)..where((s) => s.id.equals(partner.id))).write(
      StatementsCompanion(transfer: Value(out.id)),
    );
    pairs++;
  }
  return pairs;
}
