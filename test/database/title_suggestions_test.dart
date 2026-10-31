import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/database/models/account_type.dart';

void main() {
  test(
    'suggests the newest statement of each title, most used first',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      final service = DatabaseService.instance..database = db;
      final bank = await service.addAccount('Bank', AccountType.debit);
      final cash = await service.addAccount('Cash', AccountType.debit);
      Future<void> add(String title, double amount, int account, int day) =>
          service.addStatement(
            title,
            amount,
            account,
            DateTime(2026, 10, day),
            DateTime(2026, 10, day),
            [title],
            '',
          );
      await add('Frühstück', -2.5, bank, 1);
      await add('Frühstück', -2.9, cash, 3);
      await add('Frühstück', -2.7, bank, 2);
      await add('Früchte', -4, bank, 4);
      await add('100% Saft', -1, bank, 5);
      await service.addTransfer(
        await service.getAccountById(bank),
        await service.getAccountById(cash),
        50,
        DateTime(2026, 10, 6),
      );

      // Case is ignored for umlauts too.
      final suggestions = await service.titleSuggestions('FRÜ');
      expect(suggestions.map((s) => s.title), ['Frühstück', 'Früchte']);
      // The newest Frühstück, with its account.
      expect(suggestions.first.amount, -2.9);
      expect(suggestions.first.account, cash);

      // Wildcards in the query are matched literally.
      expect((await service.titleSuggestions('%')).single.title, '100% Saft');
      expect(await service.titleSuggestions('_'), isEmpty);
      // Transfers and auto-generated statements are not suggested.
      expect(await service.titleSuggestions('Transfer'), isEmpty);
      await service.addStatement(
        'Initial Balance',
        10,
        bank,
        DateTime(2026),
        DateTime(2026),
        [DatabaseService.autoTag],
        '',
      );
      expect(await service.titleSuggestions('Initial'), isEmpty);
      await db.close();
    },
  );
}
