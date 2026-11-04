import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/database/models/account_type.dart';

void main() {
  late AppDatabase db;
  final service = DatabaseService.instance;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    service.database = db;
  });

  tearDown(() => db.close());

  Future<Tag> tagNamed(String name) =>
      (db.select(db.tags)..where((t) => t.name.equals(name))).getSingle();

  Future<List<String>> tagNames() async =>
      (await db.select(db.tags).get()).map((t) => t.name).toList()..sort();

  Future<void> addStatement(String title, List<String> tags) async {
    final account = await service.addAccount('Giro', AccountType.debit);
    final date = DateTime(2026, 9, 1);
    await service.addStatement(title, -1, account, date, date, tags, '');
  }

  Future<List<String>> tagsOf(String title) async => (await (db.select(
    db.statements,
  )..where((s) => s.title.equals(title))).getSingle()).tags;

  test('deleting a parent makes its sub-tags top-level', () async {
    await service.addTag('Food', 1);
    await service.addTag('Food : Bakery', 2);
    await service.addTag('Foodie', 3);
    await addStatement('Bread', ['Food', 'Food : Bakery']);

    await service.deleteTag(await tagNamed('Food'));

    expect(await tagNames(), ['Bakery', 'Foodie']);
    expect((await tagNamed('Bakery')).color, 2);
    expect(await tagsOf('Bread'), ['Bakery']);
  });

  test('a sub-tag merges into a top-level tag of the same name', () async {
    await service.addTag('Food', 1);
    await service.addTag('Food : Bakery', 2);
    await service.addTag('bakery', 3);
    await addStatement('Bread', ['Food : Bakery']);
    await addStatement('Both', ['Food : Bakery', 'bakery']);

    await service.deleteTag(await tagNamed('Food'));

    expect(await tagNames(), ['bakery']);
    expect((await tagNamed('bakery')).color, 3);
    expect(await tagsOf('Bread'), ['bakery']);
    expect(await tagsOf('Both'), ['bakery']);
  });

  test('deleting a sub-tag leaves the others alone', () async {
    await service.addTag('Food', 1);
    await service.addTag('Food : Bakery', 2);
    await service.addTag('Food : Market', 3);

    await service.deleteTag(await tagNamed('Food : Bakery'));

    expect(await tagNames(), ['Food', 'Food : Market']);
  });
}
