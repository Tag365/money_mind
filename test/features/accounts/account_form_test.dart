import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/database/models/account_type.dart';
import 'package:money_mind/features/accounts/account_form.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    DatabaseService.instance.database = db;
  });

  tearDown(() => db.close());

  /// Opens the form in a bottom sheet, like the Accounts tab does.
  Future<void> openForm(WidgetTester tester, [Account? account]) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showModalBottomSheet(
              isScrollControlled: true,
              context: context,
              builder: (_) => AccountForm(account: account),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> submit(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, 'Add account'));
    await tester.pumpAndSettle();
  }

  testWidgets('creates the account with an initial balance statement', (
    tester,
  ) async {
    await openForm(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Account name'),
      'Giro',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Initial balance'),
      '250,5',
    );
    await submit(tester);

    expect(find.byType(AccountForm), findsNothing);
    await tester.runAsync(() async {
      final account = (await db.select(db.accounts).get()).single;
      expect(account.name, 'Giro');
      expect(account.type, AccountType.debit);
      expect(account.balance, 250.5);
      final statement = (await db.select(db.statements).get()).single;
      expect(statement.title, 'Initial Balance');
      expect(statement.amount, 250.5);
      expect(statement.account, account.id);
    });
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('takes a negative balance, e.g. for a credit card', (
    tester,
  ) async {
    await openForm(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Account name'),
      'Visa',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Initial balance'),
      '-1200,50',
    );
    await submit(tester);

    expect(find.byType(AccountForm), findsNothing);
    final account = await tester.runAsync(
      () => db.select(db.accounts).getSingle(),
    );
    expect(account!.balance, -1200.5);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('missing fields show errors and save nothing', (tester) async {
    await openForm(tester);
    await submit(tester);

    expect(find.text('Please enter an account name'), findsOneWidget);
    expect(find.text('Please enter an initial balance'), findsOneWidget);
    final accounts = await tester.runAsync(() => db.select(db.accounts).get());
    expect(accounts, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('edits name and type, but not the balance', (tester) async {
    final account = await tester.runAsync(() async {
      final id = await DatabaseService.instance.addAccount(
        'Giro',
        AccountType.debit,
      );
      return DatabaseService.instance.getAccountById(id);
    });
    await openForm(tester, account);

    expect(find.text('Edit account'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Initial balance'), findsNothing);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Account name'),
      'Visa',
    );
    await tester.tap(find.byType(DropdownMenu<AccountType>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Credit card').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.byType(AccountForm), findsNothing);
    final edited = await tester.runAsync(
      () => db.select(db.accounts).getSingle(),
    );
    expect(edited!.name, 'Visa');
    expect(edited.type, AccountType.creditCard);
    expect(
      await tester.runAsync(() => db.select(db.statements).get()),
      isEmpty,
    );
    await tester.pumpWidget(const SizedBox());
  });
}
