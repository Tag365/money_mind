import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/features/tags/tag_select_dialog.dart';

void main() {
  final tags = [
    Tag(id: BigInt.one, name: 'Food', color: 0xFFFF9800),
    Tag(id: BigInt.two, name: 'Travel', color: 0xFF2962FF),
  ];

  /// Opens the dialog with Food selected and returns a getter for what it
  /// popped with.
  Future<Set<String>? Function()> open(WidgetTester tester) async {
    Set<String>? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await showDialog<Set<String>>(
              context: context,
              builder: (_) => TagSelectDialog(tags: tags, selected: {'Food'}),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return () => result;
  }

  Future<void> tap(WidgetTester tester, String text) async {
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  testWidgets('OK returns the checked tags', (tester) async {
    final result = await open(tester);
    await tap(tester, 'Travel');
    await tap(tester, 'OK');
    expect(result(), {'Food', 'Travel'});
  });

  testWidgets('Clear unchecks everything', (tester) async {
    final result = await open(tester);
    await tap(tester, 'Clear');
    await tap(tester, 'OK');
    expect(result(), isEmpty);
  });

  testWidgets('dismissing returns null', (tester) async {
    final result = await open(tester);
    await tap(tester, 'Travel');
    await tester.tapAt(const Offset(10, 10)); // outside the dialog
    await tester.pumpAndSettle();
    expect(result(), isNull);
  });
}
