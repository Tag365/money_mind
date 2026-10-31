import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/models/account_type.dart';
import 'package:money_mind/database/models/recurrences.dart';
import 'package:money_mind/features/statements/statement_filter.dart';

/// Sum of all statements in one month (or one year when [month] is null).
class PeriodTotal {
  final int year;
  final int? month;
  final double total;
  final int count;

  /// Sum of the positive amounts and of the negative amounts.
  final double income;
  final double expense;

  const PeriodTotal(
    this.year,
    this.month,
    this.total,
    this.count,
    this.income,
    this.expense,
  );

  /// Local-time bounds of the period, end exclusive.
  DateTime get start => DateTime(year, month ?? 1);
  DateTime get end =>
      month == null ? DateTime(year + 1) : DateTime(year, month! + 1);
}

typedef StatementWithBalance = ({Statement statement, double? balance});

/// A payment after now. [date] is the statement's payment date, or for a
/// series the date of its next occurrence, which [statement] is the template
/// of.
typedef UpcomingPayment = ({Statement statement, DateTime date});

class DatabaseService {
  // Singleton pattern
  DatabaseService._internal();

  static final DatabaseService instance = DatabaseService._internal();

  AppDatabase? _database;

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

  /// Marks [account] closed: its statements and balance stay, but it takes no
  /// new statements, so the series that would add some stop.
  Future<void> closeAccount(Account account) async {
    await database.transaction(() async {
      await (database.update(database.accounts)
            ..where((tbl) => tbl.id.equals(account.id)))
          .write(const AccountsCompanion(closed: Value(true)));
      await addDueRecurrences();
    });
  }

  /// Accounts with the balance as of now: statements dated in the future
  /// (e.g. created ahead by a recurrence) are not counted yet.
  Stream<List<Account>> watchAccounts() {
    final accounts = database.accounts;
    final future = database.statements;
    // Only rechecked when a table changes, not when a future date passes.
    final futureSum = subqueryExpression<double>(
      database.selectOnly(future)
        ..addColumns([future.amount.sum()])
        ..where(
          future.account.equalsExp(accounts.id) &
              future.paymentDate.isBiggerThan(currentDateAndTime),
        ),
    );
    final balance =
        accounts.balance - coalesce([futureSum, const Constant(0.0)]);
    final query = database.select(accounts).addColumns([balance]);
    return query.watch().map(
      (rows) => [
        for (final row in rows)
          row.readTable(accounts).copyWith(balance: row.read(balance)),
      ],
    );
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
        await _addToBalance(accountId, change);
      }
    });
  }

  /// Moves [amount] from account [from] to [to] as two linked statements
  /// tagged "Transfer", so the tag can be used to filter transfers out of
  /// totals.
  Future<void> addTransfer(
    Account from,
    Account to,
    double amount,
    DateTime date,
  ) async {
    assert(from.id != to.id && amount > 0);
    StatementsCompanion side(String title, int account, double amount) =>
        StatementsCompanion.insert(
          title: title,
          createdAt: DateTime.now(),
          paymentDate: date,
          account: account,
          useDate: date,
          amount: amount,
          tags: const [transferTag],
          note: '',
        );
    await database.transaction(() async {
      final tagExists = await (database.select(
        database.tags,
      )..where((tbl) => tbl.name.equals(transferTag))).get();
      if (tagExists.isEmpty) await addTag(transferTag, 0xFF607D8B);
      final out = await database
          .into(database.statements)
          .insert(side('Transfer to ${to.name}', from.id, -amount));
      final into = await database
          .into(database.statements)
          .insert(
            side(
              'Transfer from ${from.name}',
              to.id,
              amount,
            ).copyWith(transfer: Value(out)),
          );
      await (database.update(database.statements)
            ..where((tbl) => tbl.id.equals(out)))
          .write(StatementsCompanion(transfer: Value(into)));
      await _addToBalance(from.id, -amount);
      await _addToBalance(to.id, amount);
    });
  }

  static const transferTag = 'Transfer';

  /// Replaces the stored statement with the same id by [updated] and moves the
  /// amount between account balances accordingly. Upcoming statements of its
  /// series (later and in the future) get the same title, amount, account,
  /// tags and note. The other side of a transfer gets the opposite amount and
  /// the same dates.
  Future<void> updateStatement(Statement updated) async {
    await database.transaction(() async {
      // The stored row, not the caller's copy, is what the balances contain.
      final old = await (database.select(
        database.statements,
      )..where((tbl) => tbl.id.equals(updated.id))).getSingleOrNull();
      if (old == null) return;
      final partnerId = old.transfer;
      final partner = partnerId == null
          ? null
          : await (database.select(
              database.statements,
            )..where((tbl) => tbl.id.equals(partnerId))).getSingleOrNull();
      final series = old.recurrence;
      final after = updated.paymentDate.isAfter(DateTime.now())
          ? updated.paymentDate
          : DateTime.now();
      final upcoming = series == null
          ? <Statement>[]
          : await (database.select(database.statements)..where(
                  (tbl) =>
                      tbl.recurrence.equals(series) &
                      tbl.paymentDate.isBiggerThanValue(after) &
                      // Moved to an earlier date, the stored row is "later".
                      tbl.id.isNotValue(old.id),
                ))
                .get();
      for (final (from, to) in [
        // Only setRecurrence/stopRecurrence change the series link.
        (
          old,
          updated.copyWith(
            recurrence: Value(series),
            transfer: Value(partnerId),
          ),
        ),
        if (partner != null)
          (
            partner,
            partner.copyWith(
              amount: -updated.amount,
              paymentDate: updated.paymentDate,
              useDate: updated.useDate,
            ),
          ),
        for (final s in upcoming)
          (
            s,
            s.copyWith(
              title: updated.title,
              amount: updated.amount,
              account: updated.account,
              tags: updated.tags,
              note: updated.note,
            ),
          ),
      ]) {
        await database.update(database.statements).replace(to);
        await _addToBalance(from.account, -from.amount);
        await _addToBalance(to.account, to.amount);
      }
    });
  }

  // Lets SQLite add to the current value instead of read-modify-write.
  Future<void> _addToBalance(int accountId, double change) async {
    await (database.update(
      database.accounts,
    )..where((tbl) => tbl.id.equals(accountId))).write(
      AccountsCompanion.custom(
        balance: database.accounts.balance + Variable(change),
      ),
    );
  }

  /// Deletes [statement], and the other side when it is a transfer, and takes
  /// their amounts back out of the account balances.
  Future<void> deleteStatement(Statement statement) async {
    await database.transaction(() async {
      // The stored rows, not the caller's copy, are what the balances contain.
      final rows =
          await (database.select(database.statements)..where(
                (tbl) =>
                    tbl.id.equals(statement.id) |
                    (statement.transfer == null
                        ? const Constant(false)
                        : tbl.id.equals(statement.transfer!)),
              ))
              .get();
      // Already gone (e.g. tapped twice): the balance was adjusted back then.
      for (final row in rows) {
        await (database.delete(
          database.statements,
        )..where((tbl) => tbl.id.equals(row.id))).go();
        await _addToBalance(row.account, -row.amount);
      }
    });
  }

  /// The recurrence of the statement with [statementId], or null when it does
  /// not repeat.
  Stream<Recurrence?> watchRecurrence(int statementId) {
    final query = database.select(database.statements).join([
      innerJoin(
        database.recurrences,
        database.recurrences.id.equalsExp(database.statements.recurrence),
      ),
    ])..where(database.statements.id.equals(statementId));
    return query.watchSingleOrNull().map(
      (row) => row?.readTable(database.recurrences),
    );
  }

  /// The newest statement of the series [statement] belongs to, or
  /// [statement] itself when it does not repeat. New occurrences copy it.
  Future<Statement> latestInSeries(Statement statement) async {
    final id = statement.recurrence;
    if (id == null) return statement;
    return await _latestOf(id) ?? statement;
  }

  Future<Statement?> _latestOf(int recurrenceId) {
    return (database.select(database.statements)
          ..where((tbl) => tbl.recurrence.equals(recurrenceId))
          ..orderBy([
            (tbl) => OrderingTerm.desc(tbl.paymentDate),
            (tbl) => OrderingTerm.desc(tbl.id),
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Makes [statement] repeat every [every] [unit]s, or changes the interval
  /// of its series, then creates the occurrences that are already due.
  Future<void> setRecurrence(
    Statement statement,
    RecurrenceUnit unit,
    int every, {
    bool ahead = false,
  }) async {
    assert(every > 0);
    await database.transaction(() async {
      final id = statement.recurrence;
      final existing = id == null
          ? null
          : await (database.select(
              database.recurrences,
            )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
      if (existing != null &&
          existing.unit == unit &&
          existing.every == every) {
        await (database.update(database.recurrences)
              ..where((tbl) => tbl.id.equals(existing.id)))
            .write(RecurrencesCompanion(ahead: Value(ahead)));
      } else {
        // A new interval counts from the newest statement of the series.
        final anchor = await latestInSeries(statement);
        final recurrence = RecurrencesCompanion(
          start: Value(anchor.paymentDate),
          unit: Value(unit),
          every: Value(every),
          generated: const Value(1),
          ahead: Value(ahead),
        );
        if (existing != null) {
          await (database.update(
            database.recurrences,
          )..where((tbl) => tbl.id.equals(existing.id))).write(recurrence);
        } else {
          final newId = await database
              .into(database.recurrences)
              .insert(recurrence);
          await (database.update(database.statements)
                ..where((tbl) => tbl.id.equals(statement.id)))
              .write(StatementsCompanion(recurrence: Value(newId)));
        }
      }
      await addDueRecurrences();
    });
  }

  /// Stops the series; its statements stay as they are.
  Future<void> stopRecurrence(int recurrenceId) async {
    await database.transaction(() async {
      await (database.update(database.statements)
            ..where((tbl) => tbl.recurrence.equals(recurrenceId)))
          .write(const StatementsCompanion(recurrence: Value(null)));
      await (database.delete(
        database.recurrences,
      )..where((tbl) => tbl.id.equals(recurrenceId))).go();
    });
  }

  /// Creates every occurrence due by [at] (default: now), copying the newest
  /// statement of each series. Series whose account is closed or gone stop. Series with `ahead` also get the next
  /// occurrence within a month, but never more than one upcoming statement.
  /// Safe to call any number of times: each occurrence is created once.
  Future<void> addDueRecurrences({DateTime? at}) async {
    final now = at ?? DateTime.now();
    await database.transaction(() async {
      final recurrences = await database.select(database.recurrences).get();
      for (final r in recurrences) {
        final template = await _latestOf(r.id);
        if (template == null) {
          // Every statement of the series was deleted.
          await (database.delete(
            database.recurrences,
          )..where((tbl) => tbl.id.equals(r.id))).go();
          continue;
        }
        final account = await (database.select(
          database.accounts,
        )..where((tbl) => tbl.id.equals(template.account))).getSingleOrNull();
        if (account == null || account.closed) {
          // Closed, or deleted before accounts could be closed.
          await stopRecurrence(r.id);
          continue;
        }
        final monthAhead = DateTime(
          now.year,
          now.month + 1,
          now.day,
          now.hour,
          now.minute,
        );
        final useOffset = template.useDate.difference(template.paymentDate);
        final due = <StatementsCompanion>[];
        var latest = template.paymentDate;
        var n = r.generated;
        for (
          var date = r.unit.occurrence(r.start, r.every, n);
          !date.isAfter(now) ||
              (r.ahead && !latest.isAfter(now) && !date.isAfter(monthAhead));
          date = r.unit.occurrence(r.start, r.every, ++n)
        ) {
          latest = date;
          due.add(
            template
                .toCompanion(false)
                .copyWith(
                  id: const Value.absent(),
                  createdAt: Value(DateTime.now()),
                  paymentDate: Value(date),
                  useDate: Value(date.add(useOffset)),
                ),
          );
        }
        if (due.isEmpty) continue;
        await addStatements(due);
        await (database.update(database.recurrences)
              ..where((tbl) => tbl.id.equals(r.id)))
            .write(RecurrencesCompanion(generated: Value(n)));
      }
    });
  }

  /// The next [limit] payments, soonest first: statements dated in the future
  /// and, for each series without one, its next occurrence (not created yet,
  /// so it uses the newest statement of the series as a template).
  Stream<List<UpcomingPayment>> watchUpcoming({int limit = 5}) {
    final tbl = database.statements;
    final latest = database.alias(database.statements, 'latest');
    final recurrences = database.recurrences;
    final latestOfSeries = subqueryExpression<int>(
      database.selectOnly(latest)
        ..addColumns([latest.id])
        ..where(latest.recurrence.equalsExp(tbl.recurrence))
        ..orderBy([
          OrderingTerm.desc(latest.paymentDate),
          OrderingTerm.desc(latest.id),
        ])
        ..limit(1),
    );
    final query =
        database.select(tbl).join([
          leftOuterJoin(recurrences, recurrences.id.equalsExp(tbl.recurrence)),
        ])..where(
          tbl.paymentDate.isBiggerThan(currentDateAndTime) |
              tbl.id.equalsExp(latestOfSeries),
        );
    // Only rechecked when a table changes, not when a date passes.
    return query.watch().map((rows) {
      final now = DateTime.now();
      final upcoming = <UpcomingPayment>[];
      for (final row in rows) {
        final statement = row.readTable(tbl);
        final r = row.readTableOrNull(recurrences);
        final date = statement.paymentDate.isAfter(now) || r == null
            ? statement.paymentDate
            : r.unit.occurrence(r.start, r.every, r.generated);
        // A past due occurrence is created by addDueRecurrences instead.
        if (date.isAfter(now)) upcoming.add((statement: statement, date: date));
      }
      upcoming.sort((a, b) => a.date.compareTo(b.date));
      return upcoming.take(limit).toList();
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
  /// rows are loaded into Dart. Without [transfers], money moved between
  /// accounts counts as neither income nor expense.
  Stream<List<PeriodTotal>> watchTotals({
    required bool yearly,
    StatementFilter filter = const StatementFilter(),
    bool transfers = true,
  }) {
    final tbl = database.statements;
    // Group by local time, otherwise late-evening statements on the last day
    // of a month would count towards the next month.
    final localDate = tbl.paymentDate.modify(DateTimeModifier.localTime());
    final year = localDate.year;
    final month = localDate.month;
    final total = tbl.amount.sum();
    final count = tbl.id.count();
    final income = tbl.amount.total(filter: tbl.amount.isBiggerOrEqualValue(0));
    final expense = tbl.amount.total(filter: tbl.amount.isSmallerThanValue(0));

    final groupColumns = yearly ? [year] : [year, month];
    final query = database.selectOnly(tbl)
      ..addColumns([...groupColumns, total, count, income, expense])
      ..where(
        _matches(filter) &
            (transfers ? const Constant(true) : tbl.transfer.isNull()),
      )
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
            row.read(income)!,
            row.read(expense)!,
          ),
      ],
    );
  }
}
