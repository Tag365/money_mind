import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/models/AccountType.dart';
import 'package:money_mind/list/statement_filter.dart';

/// Sum of all statements in one month (or one year when [month] is null).
class PeriodTotal {
  final int year;
  final int? month;
  final double total;
  final int count;

  const PeriodTotal(this.year, this.month, this.total, this.count);

  /// Local-time bounds of the period, end exclusive.
  DateTime get start => DateTime(year, month ?? 1);
  DateTime get end =>
      month == null ? DateTime(year + 1) : DateTime(year, month! + 1);
}

typedef StatementWithBalance = ({Statement statement, double? balance});

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

  @visibleForTesting
  set database(AppDatabase db) => _database = db;

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

  /// SQL condition for statements that pass [filter].
  Expression<bool> _matches(StatementFilter filter) {
    final tbl = database.statements;
    // Escape LIKE wildcards so user input is matched literally.
    String literal(String s) =>
        s.replaceAllMapped(RegExp(r'[\\%_]'), (m) => '\\${m[0]}');
    // Commas around the joined list make a tag match only whole entries.
    final tagList = const Constant(',') + tbl.tags + const Constant(',');
    final hasTag = Expression.or([
      for (final tag in filter.tags)
        tagList.like('%,${literal(tag)},%', escapeChar: '\\'),
    ]);
    final text = '%${literal(filter.text)}%';

    return Expression.and([
      if (filter.accounts.isNotEmpty) tbl.account.isIn(filter.accounts),
      if (filter.tags.isNotEmpty) filter.excludeTags ? hasTag.not() : hasTag,
      if (filter.expense && !filter.income) tbl.amount.isSmallerThanValue(0),
      if (filter.income && !filter.expense) tbl.amount.isBiggerOrEqualValue(0),
      if (filter.text.isNotEmpty)
        tbl.title.like(text, escapeChar: '\\') |
            tbl.note.like(text, escapeChar: '\\'),
    ]);
  }

  /// Statements with a payment date in [start, end) that pass [filter],
  /// newest first, each with its account's balance right after it (null when
  /// the account no longer exists).
  Stream<List<StatementWithBalance>> watchStatementsBetween(
    DateTime start,
    DateTime end, {
    StatementFilter filter = const StatementFilter(),
  }) {
    final tbl = database.statements;
    final later = database.alias(database.statements, 'later');
    final accounts = database.accounts;
    // Balance after a statement = current balance minus everything the account
    // booked after it. Recent months have few later rows, so this stays cheap
    // (uses the (account, payment_date) index), and it ignores the filter.
    final laterSum = subqueryExpression<double>(
      database.selectOnly(later)
        ..addColumns([later.amount.sum()])
        ..where(
          later.account.equalsExp(tbl.account) &
              (later.paymentDate.isBiggerThan(tbl.paymentDate) |
                  (later.paymentDate.equalsExp(tbl.paymentDate) &
                      later.id.isBiggerThan(tbl.id))),
        ),
    );
    final balance =
        subqueryExpression<double>(
          database.selectOnly(accounts)
            ..addColumns([accounts.balance])
            ..where(accounts.id.equalsExp(tbl.account)),
        ) -
        coalesce([laterSum, const Constant(0.0)]);

    final query =
        (database.select(tbl)
              ..where(
                (tbl) =>
                    tbl.paymentDate.isBiggerOrEqualValue(start) &
                    tbl.paymentDate.isSmallerThanValue(end) &
                    _matches(filter),
              )
              ..orderBy([
                (tbl) => OrderingTerm.desc(tbl.paymentDate),
                (tbl) => OrderingTerm.desc(tbl.id),
              ]))
            .addColumns([balance]);
    return query.watch().map(
      (rows) => [
        for (final row in rows)
          (statement: row.readTable(tbl), balance: row.read(balance)),
      ],
    );
  }

  /// Totals per month (or per year when [yearly] is true) of the statements
  /// that pass [filter], newest first. Aggregated by SQLite, so no statement
  /// rows are loaded into Dart.
  Stream<List<PeriodTotal>> watchTotals({
    required bool yearly,
    StatementFilter filter = const StatementFilter(),
  }) {
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
      ..where(_matches(filter))
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
