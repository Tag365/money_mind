import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_mind/features/statements/widgets/amount_field.dart';

void main() {
  final formKey = GlobalKey<FormState>();
  late TextEditingController controller;

  setUp(() => controller = TextEditingController());
  tearDown(() => controller.dispose());

  Future<void> show(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Form(
          key: formKey,
          child: AmountField(controller: controller, color: Colors.red),
        ),
      ),
    ),
  );

  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextFormField), text);
    await tester.pump();
  }

  testWidgets('shows the total only for more than one charge', (tester) async {
    await show(tester);

    await type(tester, '12,50 + 3');
    expect(find.text('= 15.50'), findsOneWidget);

    await type(tester, '-4 - 1');
    expect(find.text('= -5.00'), findsOneWidget);

    await type(tester, '12,50');
    expect(find.textContaining('='), findsNothing);

    await type(tester, '12 + abc');
    expect(find.textContaining('='), findsNothing);
  });

  testWidgets('accepts only a positive amount', (tester) async {
    await show(tester);

    for (final invalid in ['', '0', '3 - 5', 'abc']) {
      await type(tester, invalid);
      expect(formKey.currentState!.validate(), isFalse, reason: invalid);
    }
    await type(tester, '0,01');
    expect(formKey.currentState!.validate(), isTrue);
  });
}
