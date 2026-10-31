import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_mind/app/app_lock.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/features/settings/app_settings.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    DatabaseService.instance.database = db;
  });

  tearDown(() => db.close());

  /// Pumps the lock with a prompt that answers from [answers] in turn, and
  /// returns how often it was shown.
  Future<int Function()> show(
    WidgetTester tester, {
    required bool enabled,
    List<bool?> answers = const [],
  }) async {
    var prompts = 0;
    await tester.runAsync(() => setAppLock(enabled));
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => AppLock(
          authenticate: () async => answers[prompts++],
          child: child!,
        ),
        home: const Text('content'),
      ),
    );
    // Let the setting load from the database.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    return () => prompts;
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    // Drift closes cancelled streams on a zero timer, which only runs once
    // fake time moves.
    await tester.pump(const Duration(milliseconds: 1));
  }

  testWidgets('off: shows the app without asking', (tester) async {
    final prompts = await show(tester, enabled: false);
    expect(find.text('content'), findsOneWidget);
    expect(prompts(), 0);
    await unmount(tester);
  });

  testWidgets('on: stays locked until the prompt succeeds', (tester) async {
    final prompts = await show(tester, enabled: true, answers: [false, true]);
    expect(prompts(), 1);
    expect(find.text('content'), findsNothing);

    await tester.tap(find.text('Unlock'));
    await tester.pump();
    expect(prompts(), 2);
    expect(find.text('content'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('on, but the device has no screen lock: opens', (tester) async {
    await show(tester, enabled: true, answers: [null]);
    expect(find.text('content'), findsOneWidget);
    await unmount(tester);
  });
}
