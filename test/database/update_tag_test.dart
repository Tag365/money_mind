import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/database/models/account_type.dart';

void main() {
  test('renaming a parent tag renames its children', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final service = DatabaseService.instance..database = db;
    for (final name in ['Auto', 'Auto : Laden', 'Autobahn : Maut']) {
      await service.addTag(name, 0xFF9E9E9E);
    }
    final bank = await service.addAccount('Bank', AccountType.debit);
    final date = DateTime(2026, 10, 1);
    await service.addStatement('Jet', -20, bank, date, date, [
      'Auto : Laden',
      'Einmalig',
    ], '');
    await service.addStatement('Toll', -9, bank, date, date, [
      'Autobahn : Maut',
    ], '');

    final auto = (await service.watchTags().first).firstWhere(
      (t) => t.name == 'Auto',
    );
    await service.updateTag(auto, 'Car', auto.color);

    expect((await service.watchTags().first).map((t) => t.name), [
      'Autobahn : Maut',
      'Car',
      'Car : Laden',
    ]);
    final tags = {
      for (final s in await db.select(db.statements).get()) s.title: s.tags,
    };
    expect(tags['Jet'], ['Car : Laden', 'Einmalig']);
    expect(tags['Toll'], ['Autobahn : Maut']);
    await db.close();
  });
}
