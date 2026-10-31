import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_mind/features/statements/statement_filter.dart';
import 'package:money_mind/features/statements/widgets/active_filter_chips.dart';

void main() {
  const filter = StatementFilter(
    accounts: {1, 2},
    tags: {'Food'},
    expense: true,
    text: 'pizza',
  );

  /// Shows the chips for [filter], removes the chip labelled [label] and
  /// returns the filter passed to onChanged.
  Future<StatementFilter?> remove(
    WidgetTester tester,
    String label, {
    StatementFilter filter = filter,
  }) async {
    StatementFilter? changed;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActiveFilterChips(
            filter: filter,
            accountNames: const {1: 'Giro', 2: 'Cash'},
            onChanged: (f) => changed = f,
          ),
        ),
      ),
    );
    final chip = find.ancestor(
      of: find.text(label),
      matching: find.byType(InputChip),
    );
    await tester.tap(
      find.descendant(of: chip, matching: find.byTooltip('Delete')),
    );
    return changed;
  }

  testWidgets('removing an account chip keeps the rest', (tester) async {
    final f = (await remove(tester, 'Giro'))!;
    expect(f.accounts, {2});
    expect(f.tags, {'Food'});
    expect(f.expense, isTrue);
    expect(f.text, 'pizza');
  });

  testWidgets('removing a tag chip keeps exclude mode', (tester) async {
    final f = (await remove(
      tester,
      'Not Food',
      filter: const StatementFilter(
        tags: {'Food', 'Travel'},
        excludeTags: true,
      ),
    ))!;
    expect(f.tags, {'Travel'});
    expect(f.excludeTags, isTrue);
  });

  testWidgets('removing the expense chip shows all again', (tester) async {
    final f = (await remove(tester, 'Expense'))!;
    expect(f.income || f.expense, isFalse);
    expect(f.accounts, {1, 2});
  });

  testWidgets('removing the search chip clears the text', (tester) async {
    final f = (await remove(tester, '"pizza"'))!;
    expect(f.text, isEmpty);
    expect(f.isActive, isTrue);
  });
}
