import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_mind/common/date_button.dart';

void main() {
  testWidgets('picking a day keeps the time of day', (tester) async {
    DateTime? picked;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DateButton(
            DateTime(2026, 10, 31, 14, 5),
            onChanged: (d) => picked = d,
          ),
        ),
      ),
    );
    expect(find.text('2026-10-31'), findsOneWidget);

    await tester.tap(find.byType(DateButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('15'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(picked, DateTime(2026, 10, 15, 14, 5));
  });

  testWidgets('cancelling the picker changes nothing', (tester) async {
    var called = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DateButton(
            DateTime(2026, 10, 31),
            onChanged: (_) => called = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(DateButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(called, isFalse);
  });
}
