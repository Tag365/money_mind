import 'package:drift/drift.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/models/AccountType.dart';

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

  Future<int> addAccount(
    String name,
    AccountType type,
    double initialValue,
  ) async {
    return await database
        .into(database.accounts)
        .insert(
          AccountsCompanion(
            name: Value(name),
            type: Value(type),
            balance: Value(initialValue),
          ),
        );
  }

  void deleteAccount(Account account) async {
    database.delete(database.accounts).delete(account);
  }

  Future<List<Account>> getAccounts() async {
    return await database.select(database.accounts).get();
  }

  Future<Account> getAccountById(int id) async {
    return await (database.select(
      database.accounts,
    )..where((tbl) => tbl.id.equals(id))).getSingle();
  }

  Future<List<Statement>> getStatementsForAccount(Account account) async {
    return await (database.select(
      database.statements,
    )..where((tbl) => tbl.account.equals(account.id))).get();
  }

  void addStatement(
    String title,
    double amount,
    int accountId,
    DateTime paymentDate,
    DateTime useDate,
    List<String> tags,
    String notes,
  ) async {
    await database.transaction(() async {
      await database
          .into(database.statements)
          .insert(
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
          )
          .onError((error, stackTrace) {
            throw Exception(error);
          });
      Account account = await getAccountById(accountId);
      final double newBalance = account.balance + amount;
      await (database.update(database.accounts)
            ..where((tbl) => tbl.id.equals(accountId)))
          .write(AccountsCompanion(balance: Value(newBalance)));
    });
  }

  Future<List<Statement>> getAllStatements() async {
    return await database.select(database.statements).get();
  }
}
