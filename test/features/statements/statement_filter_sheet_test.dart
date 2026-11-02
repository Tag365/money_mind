import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/features/statements/statement_filter.dart';
import 'package:money_mind/features/statements/statement_filter_sheet.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    DatabaseService.instance.database = db;
  });

  tearDown(() => db.close());

  /// Opens the sheet with no filter and returns a getter for what it applied.
  Future<StatementFilter? Function()> open(WidgetTester tester) async {
    StatementFilter? applied;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showModalBottomSheet<StatementFilter>(
              context: context,
              isScrollControlled: true,
              builder: (_) => StatementFilterSheet(
                const StatementFilter(),
                const {1: 'Giro'},
                onChanged: (f) => applied = f,
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Giro'));
    await tester.pump();
    return () => applied;
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
  }

  testWidgets('tapping outside applies the edits', (tester) async {
    final applied = await open(tester);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(applied()?.accounts, {1});
    await unmount(tester);
  });

  testWidgets('Filter applies the edits', (tester) async {
    final applied = await open(tester);
    await tester.tap(find.text('Filter'));
    await tester.pumpAndSettle();
    expect(applied()?.accounts, {1});
    await unmount(tester);
  });

  testWidgets('No filter clears it', (tester) async {
    final applied = await open(tester);
    await tester.tap(find.text('No filter'));
    await tester.pumpAndSettle();
    expect(applied()?.isActive, isFalse);
    await unmount(tester);
  });
}
