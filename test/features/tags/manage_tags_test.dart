import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/features/tags/manage_tags.dart';

void main() {
  final service = DatabaseService.instance;
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    service.database = db;
  });

  tearDown(() => db.close());

  Future<void> settleDb(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> open(WidgetTester tester) async {
    await tester.runAsync(() async {
      await service.addTag('Food', 0xFFFF9800);
      await service.addTag('Food : Bakery', 0xFFFF9800);
      await service.addTag('Travel', 0xFF2962FF);
    });
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ManageTagsSheet())),
    );
    await settleDb(tester);
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  }

  testWidgets('sub-tags are listed by their own name under the parent', (
    tester,
  ) async {
    await open(tester);

    expect(find.text('Food : Bakery'), findsNothing);
    double top(String text) => tester.getTopLeft(find.text(text)).dy;
    expect(top('Food'), lessThan(top('Bakery')));
    expect(top('Bakery'), lessThan(top('Travel')));
    await close(tester);
  });

  testWidgets('+ on a tag adds a sub-tag to it', (tester) async {
    await open(tester);
    // Only the two top-level tags offer it.
    expect(find.byTooltip('Add sub-tag'), findsNWidgets(2));

    await tester.tap(find.byTooltip('Add sub-tag').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Market');
    await tester.tap(find.text('Save'));
    await tester.pump();
    await settleDb(tester);

    expect(find.text('Market'), findsOneWidget);
    final added = await tester.runAsync(() => db.select(db.tags).get());
    expect(added!.map((t) => t.name), contains('Food : Market'));
    await close(tester);
  });

  testWidgets('deleting a parent says its sub-tags stay', (tester) async {
    await open(tester);
    await tester.tap(find.byTooltip('Delete').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('sub-tags stay'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pump();
    await settleDb(tester);

    expect(find.text('Food'), findsNothing);
    expect(find.text('Bakery'), findsOneWidget);
    await close(tester);
  });

  testWidgets('deleting a tag without sub-tags does not mention them', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.byTooltip('Delete').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('sub-tags'), findsNothing);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await close(tester);
  });
}
