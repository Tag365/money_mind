import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/database/models/account_type.dart';
import 'package:money_mind/features/statements/statement_list.dart';

void main() {
  final service = DatabaseService.instance;
  late AppDatabase db;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day, 12);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    service.database = db;
  });

  tearDown(() => db.close());

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
    }
  }

  Future<void> open(WidgetTester tester, Map<String, DateTime> rows) async {
    await tester.runAsync(() async {
      final account = await service.addAccount('Cash', AccountType.debit);
      for (final MapEntry(key: title, value: date) in rows.entries) {
        await service.addStatement(title, -1, account, date, date, [], '');
      }
    });
    await tester.pumpWidget(const MaterialApp(home: ListWidget()));
    await settle(tester);
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  }

  // Enough earlier months to fill the screen, so the list can scroll that far.
  Map<String, DateTime> pastMonths() => {
    for (var m = 1; m <= 12; m++)
      'Past $m': DateTime(now.year, now.month - m, 15),
  };

  // Enough rows above today to fill half the screen.
  Map<String, DateTime> tomorrowRows() => {
    for (var i = 0; i < 6; i++)
      'Tomorrow $i': today.add(const Duration(days: 1)),
  };

  void expectTodayInMiddle(WidgetTester tester) {
    final list = tester.getRect(find.byType(CustomScrollView));
    final dayHeader = find.text(
      MaterialLocalizations.of(
        tester.element(find.byType(ListWidget)),
      ).formatMediumDate(today),
    );
    expect(tester.getTopLeft(dayHeader).dy, closeTo(list.center.dy, 20));
  }

  double monthTop(WidgetTester tester, DateTime month) => tester
      .getTopLeft(
        find.text(
          MaterialLocalizations.of(
            tester.element(find.byType(ListWidget)),
          ).formatMonthYear(month),
        ),
      )
      .dy;

  testWidgets('opens at the current month, with future months above it', (
    tester,
  ) async {
    final nextMonth = DateTime(now.year, now.month + 1, 15);
    await open(tester, {
      'Upcoming': nextMonth,
      'Today': today,
      ...pastMonths(),
    });

    final top = tester.getTopLeft(find.byType(CustomScrollView)).dy;
    expect(find.text('Today'), findsOneWidget);
    expect(monthTop(tester, today), greaterThanOrEqualTo(top));

    // The future month is reachable by scrolling up.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 300));
    await settle(tester);
    expect(monthTop(tester, nextMonth), lessThan(monthTop(tester, today)));
    await close(tester);
  });

  testWidgets(
    "opens at today's day, with the month's future days above it",
    (tester) async {
      await open(tester, {...tomorrowRows(), 'Today': today, ...pastMonths()});

      expectTodayInMiddle(tester);
      expect(find.text('Tomorrow 5'), findsOneWidget);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, 300));
      await settle(tester);
      expect(
        tester.getTopLeft(find.text('Tomorrow 0')).dy,
        greaterThanOrEqualTo(
          tester.getTopLeft(find.byType(CustomScrollView)).dy,
        ),
      );
      await close(tester);
    },
    // Tomorrow is in the next month then, which the first test covers.
    skip: today.add(const Duration(days: 1)).month != today.month,
  );

  testWidgets("a list too short to scroll still opens at today's day", (
    tester,
  ) async {
    await open(tester, {...tomorrowRows(), 'Today': today});

    expectTodayInMiddle(tester);
    await close(tester);
  }, skip: today.add(const Duration(days: 1)).month != today.month);

  testWidgets('with few days ahead today sits above the middle', (
    tester,
  ) async {
    await open(tester, {
      'Tomorrow': today.add(const Duration(days: 1)),
      'Today': today,
      ...pastMonths(),
    });

    // The list cannot scroll above its top, so nothing is cut off.
    final top = tester.getTopLeft(find.byType(CustomScrollView)).dy;
    expect(monthTop(tester, today), greaterThanOrEqualTo(top));
    expect(find.text('Tomorrow'), findsOneWidget);
    await close(tester);
  }, skip: today.add(const Duration(days: 1)).month != today.month);

  testWidgets(
    "opens at today's day when a tall month skews the scroll estimate",
    (tester) async {
      await open(tester, {
        ...tomorrowRows(),
        for (var i = 0; i < 20; i++) 'Today $i': today,
        'Last month': DateTime(now.year, now.month - 1, 15),
      });

      expectTodayInMiddle(tester);
      await close(tester);
    },
    skip: today.add(const Duration(days: 1)).month != today.month,
  );

  testWidgets('a page with a header keeps it on top of all months', (
    tester,
  ) async {
    final nextMonth = DateTime(now.year, now.month + 1, 15);
    await tester.runAsync(() async {
      final account = await service.addAccount('Cash', AccountType.debit);
      for (final date in [nextMonth, today]) {
        await service.addStatement('Row', -1, account, date, date, [], '');
      }
    });
    await tester.pumpWidget(
      const MaterialApp(home: ListWidget(header: Text('Header'))),
    );
    await settle(tester);

    expect(
      tester.getTopLeft(find.text('Header')).dy,
      lessThan(monthTop(tester, nextMonth)),
    );
    expect(monthTop(tester, nextMonth), lessThan(monthTop(tester, today)));
    await close(tester);
  });

  testWidgets('with only future months they are still reachable', (
    tester,
  ) async {
    final nextMonth = DateTime(now.year, now.month + 1, 15);
    await open(tester, {'Upcoming': nextMonth});

    await tester.drag(find.byType(CustomScrollView), const Offset(0, 300));
    await settle(tester);
    expect(monthTop(tester, nextMonth), greaterThanOrEqualTo(0));
    await close(tester);
  });
}
