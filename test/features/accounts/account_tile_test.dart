import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/models/account_type.dart';
import 'package:money_mind/features/accounts/widgets/account_tile.dart';

void main() {
  Account account({required bool closed}) => Account(
    id: 1,
    name: 'Giro',
    type: AccountType.debit,
    balance: 120,
    closed: closed,
  );

  Future<void> show(
    WidgetTester tester,
    Account account,
    VoidCallback onClose, {
    VoidCallback? onEdit,
    VoidCallback? onSettle,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SlidableAutoCloseBehavior(
            child: AccountTile(
              account,
              onEdit: onEdit ?? () {},
              onSettle: onSettle,
              onClose: onClose,
              onTap: () {},
            ),
          ),
        ),
      ),
    );
    await tester.drag(find.byType(AccountTile), const Offset(-300, 0));
    await tester.pumpAndSettle();
  }

  testWidgets('an open account can be swiped to Close', (tester) async {
    var closed = 0;
    await show(tester, account(closed: false), () => closed++);

    expect(find.text('Debit'), findsOneWidget);
    await tester.tap(find.text('Close'));
    expect(closed, 1);
  });

  testWidgets('a closed account is marked and cannot be closed again', (
    tester,
  ) async {
    await show(tester, account(closed: true), () => fail('onClose called'));

    expect(find.text('Debit · Closed'), findsOneWidget);
    expect(find.text('Close'), findsNothing);
    expect(tester.widget<ListTile>(find.byType(ListTile)).enabled, isFalse);
  });

  for (final closed in [false, true]) {
    testWidgets('an account can be swiped to Edit (closed: $closed)', (
      tester,
    ) async {
      var edited = 0;
      await show(
        tester,
        account(closed: closed),
        () {},
        onEdit: () => edited++,
      );

      await tester.tap(find.text('Edit'));
      expect(edited, 1);
    });
  }

  testWidgets('Settle shows only when the tile is given onSettle', (
    tester,
  ) async {
    await show(tester, account(closed: false), () {});
    expect(find.text('Settle'), findsNothing);

    var settled = 0;
    await tester.pumpWidget(const SizedBox());
    await show(
      tester,
      account(closed: false),
      () {},
      onSettle: () => settled++,
    );
    await tester.tap(find.text('Settle'));
    expect(settled, 1);
  });
}
