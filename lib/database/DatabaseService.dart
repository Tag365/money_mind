import 'package:money_mind/database/models/account.dart';
import 'package:money_mind/database/models/statement.dart';
import 'package:money_mind/database/models/tag.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  // Singleton pattern
  DatabaseService._internal();

  static final DatabaseService instance = DatabaseService._internal();

  Database? _database;

  factory DatabaseService() {
    return instance;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await getDatabase();
    return _database!;
  }

  Future<Database> getDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'money_mind.db');

    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        // Create tables here
        await db.execute('''
          CREATE TABLE accounts (
            id TEXT PRIMARY KEY,
            name TEXT,
            type TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE statements (
            id TEXT PRIMARY KEY,
            createdAt DATE,
            title TEXT,
            paymentDate DATE,
            useDate DATE,
            amount REAL,
            isExpense INTEGER,
            accountId TEXT,
            tags TEXT,
            note TEXT,
            FOREIGN KEY (accountId) REFERENCES accounts (id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE tags (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE statement_tags (
            statementId TEXT,
            tagId INTEGER,
            PRIMARY KEY (statementId, tagId),
            FOREIGN KEY (statementId) REFERENCES statements (id) ON DELETE CASCADE,
            FOREIGN KEY (tagId) REFERENCES tags (id) ON DELETE CASCADE
          )
        ''');

        // Indexes for performance
        await db.execute('CREATE INDEX idx_accountId ON statements (accountId)');
        await db.execute('CREATE INDEX idx_statementId ON statement_tags (statementId)');
        await db.execute('CREATE INDEX idx_tagId ON statement_tags (tagId)');
      },
    );
  }

  void addAccount(Account account) async {
    final db = await database;
    await db.insert(
      'accounts',
      account.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  void deleteAccount(Account account) async {
    final db = await database;
    await db.delete('accounts', where: 'id = ?', whereArgs: [account.id]);
  }

  Future<List<Account>> getAccounts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('accounts');

    List<Account> accounts = [];
    for (var map in maps) {
      Account account = Account.fromJson(map);

      List<Statement> statements = await getStatementsForAccount(account);
      account.statements.addAll(statements);
      accounts.add(account);
    }

    return accounts;
  }

  Future<List<Statement>> getStatementsForAccount(Account account) async {
    final db = await database;
    var start = DateTime.now().millisecondsSinceEpoch;
    print("Fetching statements for account ${account.id} ${DateTime.fromMillisecondsSinceEpoch(start)}");
    final List<Map<String, dynamic>> maps = await db.query(
      'statements',
      where: 'accountId = ?',
      whereArgs: [account.id],
    );

    print("Took ${DateTime.now().millisecondsSinceEpoch - start} milliseconds to fetch statements");
    List<Statement> statements = [];
    start = DateTime.now().millisecondsSinceEpoch;

    for (var map in maps) {
      var copy = Map<String, dynamic>.from(map);
      copy['account'] = account;
      copy['isExpense'] = copy['isExpense'] == 1;
      statements.add(Statement.fromJson(copy));
    }
    print(statements[0]);
    print("Took ${DateTime.now().millisecondsSinceEpoch - start} milliseconds to assign stuff");

    return statements;
  }

  void addStatement(Statement statement, Account account) async {
    final db = await database;
    await db.insert('statements', {
      ...statement.toJson(),
      'accountId': account.id,
      'isExpense': statement.isExpense ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
