import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/common/date_button.dart';
import 'package:money_mind/database/models/account_type.dart';
import 'package:money_mind/database/models/recurrences.dart';
import 'package:money_mind/features/statements/add_statement.dart';

void main() {
  final service = DatabaseService.instance;
  late AppDatabase db;
  late int accountId;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    service.database = db;
  });

  tearDown(() => db.close());

  /// Seeds an account, two tags and whatever [seed] adds, then shows the Add
  /// form.
  Future<void> openForm(
    WidgetTester tester, {
    Future<void> Function()? seed,
  }) async {
    await tester.runAsync(() async {
      accountId = await service.addAccount('Giro', AccountType.debit);
      await service.addTag('Food', 0xFFFF9800);
      await service.addTag('Travel', 0xFF2962FF);
      await seed?.call();
    });
    await tester.pumpWidget(const MaterialApp(home: AddWidget()));
    await tester.pumpAndSettle();
  }

  Future<void> enterStatement(
    WidgetTester tester, {
    String title = 'Groceries',
    String amount = '12,50',
  }) async {
    await tester.enterText(find.widgetWithText(TextFormField, 'Title'), title);
    await tester.enterText(find.widgetWithText(TextFormField, '0,00'), amount);
    await tester.pump();
  }

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
  }

  Future<List<Statement>> statements(WidgetTester tester) async =>
      (await tester.runAsync(() => db.select(db.statements).get()))!;

  /// Unmounts the form so its database streams are cancelled before the
  /// database is closed.
  Future<void> closeForm(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  }

  testWidgets('saves a summed expense and updates the balance', (tester) async {
    await openForm(tester);
    await enterStatement(tester, amount: '12,50 + 3');
    expect(find.text('= 15,50 €'), findsOneWidget);

    await save(tester);

    final saved = await statements(tester);
    expect(saved.single.title, 'Groceries');
    expect(saved.single.amount, -15.5);
    expect(saved.single.account, accountId);
    final account = await tester.runAsync(
      () => service.getAccountById(accountId),
    );
    expect(account!.balance, -15.5);
    await closeForm(tester);
  });

  testWidgets('closed accounts cannot be picked', (tester) async {
    await tester.runAsync(() async {
      final old = await service.addAccount('Old', AccountType.debit);
      await service.closeAccount(await service.getAccountById(old));
    });
    await openForm(tester);
    await tester.tap(find.text('Giro'));
    await tester.pumpAndSettle();

    expect(find.text('Old'), findsNothing);
    await closeForm(tester);
  });

  testWidgets('income is stored as a positive amount', (tester) async {
    await openForm(tester);
    await tester.tap(find.text('Expense'));
    await tester.pump();
    expect(find.text('Income'), findsOneWidget);

    await enterStatement(tester, amount: '100');
    await save(tester);

    expect((await statements(tester)).single.amount, 100);
    await closeForm(tester);
  });

  testWidgets('invalid input shows errors and saves nothing', (tester) async {
    await openForm(tester);
    await enterStatement(tester, title: '', amount: '12+');
    await save(tester);

    expect(find.text('Please add a Title'), findsOneWidget);
    expect(find.text('Please enter a positive amount'), findsOneWidget);
    expect(await statements(tester), isEmpty);
    await closeForm(tester);
  });

  testWidgets('selected tags are saved with the statement', (tester) async {
    await openForm(tester);
    await enterStatement(tester);

    await tester.tap(find.text('Tags'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Food'));
    await tester.tap(find.text('Travel'));
    await tester.pump();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await save(tester);

    expect((await statements(tester)).single.tags, ['Food', 'Travel']);
    await closeForm(tester);
  });

  /// Seeds an expense with an "Auto" tag that is not in the Tags table and
  /// opens it in edit mode.
  Future<Statement> openEditForm(WidgetTester tester) async {
    final statement = (await tester.runAsync(() async {
      accountId = await service.addAccount('Giro', AccountType.debit);
      await service.addTag('Food', 0xFFFF9800);
      final date = DateTime(2026, 9, 15, 12, 30);
      await service.addStatement('Lunch', -12.5, accountId, date, date, [
        'Food',
        'Auto',
      ], 'note');
      return (await db.select(db.statements).get()).single;
    }))!;
    await tester.pumpWidget(MaterialApp(home: AddWidget(statement: statement)));
    await tester.pumpAndSettle();
    return statement;
  }

  testWidgets('edit mode shows the statement and saves changes', (
    tester,
  ) async {
    await openEditForm(tester);
    expect(find.text('Edit statement'), findsOneWidget);
    expect(find.text('Lunch'), findsOneWidget);
    expect(find.text('12,50'), findsOneWidget);
    expect(find.text('Auto'), findsOneWidget);

    await enterStatement(tester, title: 'Dinner', amount: '20');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    final saved = (await statements(tester)).single;
    expect(saved.title, 'Dinner');
    expect(saved.amount, -20);
    // The tag outside the Tags table survives the edit.
    expect(saved.tags, ['Food', 'Auto']);
    final account = await tester.runAsync(
      () => service.getAccountById(accountId),
    );
    expect(account!.balance, -20);
    await closeForm(tester);
  });

  testWidgets('cancel asks before discarding changes', (tester) async {
    await openEditForm(tester);
    await enterStatement(tester, title: 'Dinner');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);

    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.text('Dinner'), findsOneWidget);
    expect((await statements(tester)).single.title, 'Lunch');
    await closeForm(tester);
  });

  testWidgets('a picked title suggestion fills in the form', (tester) async {
    late int wallet;
    // Before the form opens: writes while its streams run would deadlock.
    await openForm(
      tester,
      seed: () async {
        wallet = await service.addAccount('Wallet', AccountType.debit);
        final date = DateTime(2026, 9, 1);
        await service.addStatement('Salary', 2000, wallet, date, date, [
          'Travel',
        ], '');
      },
    );
    expect(find.text('Giro'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, '0,00'), '9');
    await tester.enterText(find.widgetWithText(TextFormField, 'Title'), 'sal');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salary').last);
    await tester.pumpAndSettle();

    await save(tester);

    final saved = (await statements(tester)).last;
    expect(saved.title, 'Salary');
    // Income from the suggestion, the amount as typed.
    expect(saved.amount, 9);
    expect(saved.tags, ['Travel']);
    expect(saved.account, wallet);
    await closeForm(tester);
  });

  testWidgets('a repeat picked when creating starts a series', (tester) async {
    await openForm(tester);
    await enterStatement(tester);
    await tester.tap(find.text('Repeats'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Every month'), findsOneWidget);

    await save(tester);

    final recurrences = await tester.runAsync(
      () => db.select(db.recurrences).get(),
    );
    expect(recurrences!.single.unit, RecurrenceUnit.month);
    expect((await statements(tester)).single.recurrence, recurrences.single.id);
    expect(find.text('Never'), findsOneWidget);
    await closeForm(tester);
  });

  testWidgets('a picked date stays for the next statement', (tester) async {
    await openForm(tester);
    final day = DateTime.now().day == 15 ? 16 : 15;
    await tester.tap(find.byType(DateButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('$day'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await enterStatement(tester);
    await save(tester);

    await enterStatement(tester, title: 'Bakery');
    await save(tester);

    final saved = await statements(tester);
    expect(saved.map((s) => s.paymentDate.day), [day, day]);
    expect(saved.last.paymentDate, saved.first.paymentDate);
    await closeForm(tester);
  });

  testWidgets('a copy keeps the tags and saves a new statement', (
    tester,
  ) async {
    final original = (await tester.runAsync(() async {
      accountId = await service.addAccount('Giro', AccountType.debit);
      await service.addTag('Food', 0xFFFF9800);
      final date = DateTime(2026, 9, 15);
      return service.addStatement('Lunch', -12.5, accountId, date, date, [
        'Food',
      ], '');
    }))!;
    await tester.pumpWidget(MaterialApp(home: AddWidget(copyOf: original)));
    await tester.pumpAndSettle();
    // The tags load after the first build; they must not be dropped then.
    expect(find.text('Food'), findsOneWidget);

    await save(tester);

    final saved = await statements(tester);
    expect(saved, hasLength(2));
    expect(saved.last.tags, ['Food']);
    expect(saved.last.amount, -12.5);
    expect(saved.last.paymentDate.isAfter(original.paymentDate), isTrue);
    await closeForm(tester);
  });

  testWidgets('form is empty again after saving', (tester) async {
    await openForm(tester);
    await enterStatement(tester);
    await save(tester);

    expect(find.text('Groceries'), findsNothing);
    expect(find.text('12,50'), findsNothing);
    await closeForm(tester);
  });
}
