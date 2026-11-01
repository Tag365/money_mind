import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/database/models/account_type.dart';
import 'package:money_mind/features/settings/backup.dart';

void main() {
  late AppDatabase db;
  final service = DatabaseService.instance;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    service.database = db;
  });

  tearDown(() => db.close());

  test(
    'restoring a backup brings back its data and drops newer data',
    () async {
      await service.addAccount('Giro', AccountType.values.first);
      await service.setSetting('theme', 'dark');
      final backup = await exportBackup();

      await service.addAccount('Cash', AccountType.values.first);
      await service.setSetting('theme', 'light');
      final accounts = service.watchAccounts();
      await restoreBackup(backup);

      expect((await accounts.first).map((a) => a.name), ['Giro']);
      expect(await service.watchSetting('theme').first, 'dark');
    },
  );

  test('rejects a file that is not a backup, changing nothing', () async {
    await service.addAccount('Giro', AccountType.values.first);
    await expectLater(
      restoreBackup(Uint8List.fromList('not a database'.codeUnits)),
      throwsFormatException,
    );
    expect((await service.watchAccounts().first).map((a) => a.name), ['Giro']);
  });
}
