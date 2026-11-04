import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/features/tags/tag_dialog.dart';

void main() {
  final food = Tag(id: BigInt.one, name: 'Food', color: 0xFFFF9800);
  final bakery = Tag(id: BigInt.two, name: 'Food : Bakery', color: 0xFF9E9E9E);
  final travel = Tag(id: BigInt.from(3), name: 'Travel', color: 0xFF2962FF);
  final orphan = Tag(id: BigInt.from(4), name: 'Gone : Kid', color: 0xFF9E9E9E);
  final tags = [food, bakery, travel, orphan];

  /// Opens the dialog and returns a getter for what it popped with.
  Future<(String, Color)? Function()> open(
    WidgetTester tester, {
    Tag? tag,
    String? parent,
  }) async {
    (String, Color)? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await showDialog<(String, Color)>(
              context: context,
              builder: (_) => TagDialog(tag: tag, tags: tags, parent: parent),
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

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
  }

  Future<void> pickParent(WidgetTester tester, String name) async {
    await tester.tap(find.byType(DropdownMenu<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(name).last);
    await tester.pumpAndSettle();
  }

  Finder nameField() => find.widgetWithText(TextField, 'Name');

  String nameText(WidgetTester tester) =>
      tester.widget<TextField>(nameField()).controller!.text;

  DropdownMenu<String> parentMenu(WidgetTester tester) =>
      tester.widget(find.byType(DropdownMenu<String>));

  testWidgets('a picked parent builds the full name and sets the color', (
    tester,
  ) async {
    final result = await open(tester);
    await tester.enterText(nameField(), 'Market');
    await pickParent(tester, 'Food');
    await save(tester);

    expect(result()!.$1, 'Food : Market');
    expect(result()!.$2, Color(food.color));
  });

  testWidgets('without a parent the tag is top-level', (tester) async {
    final result = await open(tester);
    await tester.enterText(nameField(), 'Market');
    await save(tester);

    expect(result()!.$1, 'Market');
  });

  testWidgets('a preselected parent is used with its color', (tester) async {
    final result = await open(tester, parent: 'Travel');
    await tester.enterText(nameField(), 'Hotel');
    await save(tester);

    expect(result()!.$1, 'Travel : Hotel');
    expect(result()!.$2, Color(travel.color));
  });

  testWidgets('editing shows only the name and can move the sub-tag', (
    tester,
  ) async {
    final result = await open(tester, tag: bakery);
    expect(nameText(tester), 'Bakery');

    await pickParent(tester, 'Travel');
    await save(tester);

    expect(result()!.$1, 'Travel : Bakery');
    // A moved tag keeps its color.
    expect(result()!.$2, Color(bakery.color));
  });

  testWidgets('None makes a sub-tag top-level', (tester) async {
    final result = await open(tester, tag: bakery);
    await pickParent(tester, 'None');
    await save(tester);

    expect(result()!.$1, 'Bakery');
  });

  testWidgets('saving a sub-tag of a deleted parent changes nothing', (
    tester,
  ) async {
    final result = await open(tester, tag: orphan);
    expect(nameText(tester), 'Kid');
    await save(tester);

    expect(result()!.$1, 'Gone : Kid');
  });

  testWidgets('a tag with sub-tags cannot get a parent', (tester) async {
    await open(tester, tag: food);

    expect(find.textContaining('cannot have a parent'), findsOneWidget);
    expect(parentMenu(tester).enabled, isFalse);
  });

  testWidgets('only other top-level tags can be picked', (tester) async {
    await open(tester, tag: travel);

    expect(parentMenu(tester).dropdownMenuEntries.map((e) => e.label), [
      'None',
      'Food',
    ]);
  });

  testWidgets('a typed separator is refused', (tester) async {
    final result = await open(tester);
    await tester.enterText(nameField(), 'Food : Market');
    await save(tester);

    expect(find.textContaining('instead of typing'), findsOneWidget);
    expect(result(), isNull);
  });

  testWidgets('the same name is only refused under the same parent', (
    tester,
  ) async {
    final result = await open(tester, parent: 'Food');
    await tester.enterText(nameField(), 'bakery');
    await save(tester);
    expect(find.text('Tag already exists'), findsOneWidget);

    await pickParent(tester, 'Travel');
    await save(tester);

    expect(result()!.$1, 'Travel : bakery');
  });
}
