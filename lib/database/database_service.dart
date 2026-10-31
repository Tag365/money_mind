import 'package:drift/drift.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/models/AccountType.dart';

/// Sum of all statements in one month (or one year when [month] is null).
class PeriodTotal {
  final int year;
  final int? month;
  final double total;
  final int count;

  const PeriodTotal(this.year, this.month, this.total, this.count);
}

class DatabaseService {
  // Singleton pattern
  DatabaseService._internal();

  static final DatabaseService instance = DatabaseService._internal();

  AppDatabase? _database;

  factory DatabaseService() {
    return instance;
  }

  AppDatabase get database {
    if (_database != null) return _database!;
    _database = AppDatabase();
    return _database!;
  }

  Future<int> addAccount(String name, AccountType type) async {
    return await database
        .into(database.accounts)
        .insert(AccountsCompanion(name: Value(name), type: Value(type)));
  }

  Future<void> deleteAccount(Account account) async {
    await database.delete(database.accounts).delete(account);
  }

  Future<List<Account>> getAccounts() async {
    return await database.select(database.accounts).get();
  }

  Stream<List<Account>> watchAccounts() {
    return database.select(database.accounts).watch();
  }

  Future<Account> getAccountById(int id) async {
    return await (database.select(
      database.accounts,
    )..where((tbl) => tbl.id.equals(id))).getSingle();
  }

  Stream<List<Tag>> watchTags() {
    return (database.select(
      database.tags,
    )..orderBy([(tbl) => OrderingTerm.asc(tbl.name)])).watch();
  }

  Future<void> addTag(String name, int color) async {
    await database
        .into(database.tags)
        .insert(TagsCompanion(name: Value(name), color: Value(color)));
  }

  /// Renaming also renames the tag on every statement that uses it.
  Future<void> updateTag(Tag tag, String name, int color) async {
    await database.transaction(() async {
      await (database.update(database.tags)
            ..where((tbl) => tbl.id.equals(tag.id)))
          .write(TagsCompanion(name: Value(name), color: Value(color)));
      if (name != tag.name) await _replaceTagInStatements(tag.name, name);
    });
  }

  /// Also removes the tag from every statement that uses it.
  Future<void> deleteTag(Tag tag) async {
    await database.transaction(() async {
      await (database.delete(
        database.tags,
      )..where((tbl) => tbl.id.equals(tag.id))).go();
      await _replaceTagInStatements(tag.name, null);
    });
  }

  /// Replaces [oldName] with [newName] in the tags of all statements, or
  /// removes it when [newName] is null.
  Future<void> _replaceTagInStatements(String oldName, String? newName) async {
    // LIKE narrows the rows; the exact match happens on the parsed list.
    final candidates = await (database.select(
      database.statements,
    )..where((tbl) => tbl.tags.like('%$oldName%'))).get();
    for (final statement in candidates) {
      if (!statement.tags.contains(oldName)) continue;
      final tags = {
        for (final t in statement.tags) t == oldName ? newName : t,
      }.nonNulls.toList();
      await (database.update(database.statements)
            ..where((tbl) => tbl.id.equals(statement.id)))
          .write(StatementsCompanion(tags: Value(tags)));
    }
  }

  Future<List<Statement>> getStatementsForAccount(Account account) async {
    return await (database.select(
      database.statements,
    )..where((tbl) => tbl.account.equals(account.id))).get();
  }

  Future<void> addStatement(
    String title,
    double amount,
    int accountId,
    DateTime paymentDate,
    DateTime useDate,
    List<String> tags,
    String notes,
  ) async {
    await addStatements([
      StatementsCompanion(
        title: Value(title),
        createdAt: Value(DateTime.now()),
        paymentDate: Value(paymentDate),
        account: Value(accountId),
        useDate: Value(useDate),
        amount: Value(amount),
        tags: Value(tags),
        note: Value(notes),
      ),
    ]);
  }

  /// Inserts all [statements] in one transaction and updates the balance of
  /// each affected account once.
  Future<void> addStatements(List<StatementsCompanion> statements) async {
    final balanceChanges = <int, double>{};
    for (final statement in statements) {
      final accountId = statement.account.value;
      balanceChanges[accountId] =
          (balanceChanges[accountId] ?? 0) + statement.amount.value;
    }

    await database.transaction(() async {
      await database.batch((batch) {
        batch.insertAll(database.statements, statements);
      });
      for (final MapEntry(key: accountId, value: change)
          in balanceChanges.entries) {
        // Let SQLite add to the current value instead of read-modify-write.
        await (database.update(
          database.accounts,
        )..where((tbl) => tbl.id.equals(accountId))).write(
          AccountsCompanion.custom(
            balance: database.accounts.balance + Variable(change),
          ),
        );
      }
    });
  }

  /// Newest statements first, at most [limit] rows. Emits again whenever the
  /// statements table changes.
  Stream<List<Statement>> watchStatements({required int limit}) {
    return (database.select(database.statements)
          ..orderBy([
            (tbl) => OrderingTerm.desc(tbl.paymentDate),
            (tbl) => OrderingTerm.desc(tbl.id),
          ])
          ..limit(limit))
        .watch();
  }

  /// Totals per month (or per year when [yearly] is true), newest first.
  /// Aggregated by SQLite, so no statement rows are loaded into Dart.
  Stream<List<PeriodTotal>> watchTotals({required bool yearly}) {
    final tbl = database.statements;
    // Group by local time, otherwise late-evening statements on the last day
    // of a month would count towards the next month.
    final localDate = tbl.paymentDate.modify(DateTimeModifier.localTime());
    final year = localDate.year;
    final month = localDate.month;
    final total = tbl.amount.sum();
    final count = tbl.id.count();

    final groupColumns = yearly ? [year] : [year, month];
    final query = database.selectOnly(tbl)
      ..addColumns([...groupColumns, total, count])
      ..groupBy(groupColumns)
      ..orderBy([for (final c in groupColumns) OrderingTerm.desc(c)]);

    return query.watch().map(
      (rows) => [
        for (final row in rows)
          PeriodTotal(
            row.read(year)!,
            yearly ? null : row.read(month),
            row.read(total) ?? 0,
            row.read(count) ?? 0,
          ),
      ],
    );
  }
}
