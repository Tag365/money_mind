import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/features/settings/app_settings.dart';
import 'package:money_mind/features/settings/settings_page.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    DatabaseService.instance.database = db;
    PackageInfo.setMockInitialValues(
      appName: 'Money Mind',
      packageName: 'de.jonas.money_mind',
      version: '1.2.3',
      buildNumber: '4',
      buildSignature: '',
    );
  });

  tearDown(() => db.close());

  testWidgets('saves the chosen theme and shows the version', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsPage()));
    await tester.pump();
    expect(find.text('Version 1.2.3 (4)'), findsOneWidget);

    await tester.tap(find.text('Dark'));
    await tester.runAsync(() async {
      expect(await watchThemeMode().first, ThemeMode.dark);
    });
    await tester.pumpWidget(const SizedBox());
    // Drift closes cancelled streams on a zero timer, which only runs once
    // fake time moves.
    await tester.pump(const Duration(milliseconds: 1));
  });
}
