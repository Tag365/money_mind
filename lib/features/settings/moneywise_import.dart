import 'package:drift/drift.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/database/models/account_type.dart';

/// Splits CSV [text] into rows of fields; quoted fields may hold commas,
/// line breaks and doubled quotes.
List<List<String>> parseCsv(String text) {
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var quoted = false;
  for (var i = 0; i < text.length; i++) {
    final c = text[i];
    if (quoted) {
      if (c != '"') {
        field.write(c);
      } else if (i + 1 < text.length && text[i + 1] == '"') {
        field.write('"');
        i++;
      } else {
        quoted = false;
      }
    } else if (c == '"') {
      quoted = true;
    } else if (c == ',') {
      row.add(field.toString());
      field.clear();
    } else if (c == '\n' || c == '\r') {
      if (c == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
      row.add(field.toString());
      field.clear();
      rows.add(row);
      row = [];
    } else {
      field.write(c);
    }
  }
  if (field.isNotEmpty || row.isNotEmpty) rows.add(row..add(field.toString()));
  return rows.where((r) => r.length > 1 || r.single.isNotEmpty).toList();
}

/// Imports a MoneyWise CSV export: creates its accounts and tags, then adds
/// every row as a statement. A category becomes a tag of the same name, a
/// sub-category ("Auto : Laden") a child tag of its parent. Accounts created here get an "Initial Balance" statement so their
/// balance ends where MoneyWise's does. Returns the number of rows imported.
///
/// Parses the whole file before writing, so a bad row changes nothing.
Future<int> importMoneyWise(String csv) async {
  final rows = parseCsv(csv.replaceFirst('﻿', ''));
  if (rows.isEmpty) throw const FormatException('The file is empty.');
  final header = rows.first;
  int column(String name) {
    final i = header.indexOf(name);
    if (i < 0) {
      throw FormatException('Not a MoneyWise export: no "$name" column.');
    }
    return i;
  }

  final date = column('Date'), category = column('Category');
  final description = column('Description'), tags = column('Tags');
  final amount = column('Amount in EUR'), account = column('Account');
  final balance = column('Account balance (EUR)'), note = column('Note');
  double money(String s) => double.parse(s.replaceAll(',', '.'));

  final parsed = <({String account, StatementsCompanion statement})>[];
  // MoneyWise lists the newest row first.
  final finalBalances = <String, double>{};
  for (final (i, row) in rows.skip(1).indexed) {
    try {
      final day = DateTime.parse(row[date]);
      final categoryTag = row[category]
          .split(':')
          .map((level) => level.trim())
          .join(DatabaseService.tagSeparator);
      final tagList = {
        switch (categoryTag) {
          'Uncategorized' || '' => null,
          'ATransfer' => DatabaseService.transferTag,
          final name => name,
        },
        for (final tag in row[tags].split(',')) tag.trim(),
      }..removeWhere((t) => t == null || t.isEmpty);
      final title = row[description].trim();
      parsed.add((
        account: row[account],
        statement: StatementsCompanion.insert(
          title: title.isEmpty ? row[category].trim() : title,
          createdAt: DateTime.now(),
          paymentDate: day,
          account: 0, // set once the account exists
          useDate: day,
          amount: money(row[amount]),
          tags: tagList.cast<String>().toList(),
          note: row[note],
        ),
      ));
      finalBalances.putIfAbsent(row[account], () => money(row[balance]));
    } on Object catch (e) {
      throw FormatException('Line ${i + 2}: $e');
    }
  }

  final service = DatabaseService.instance;
  await service.database.transaction(() async {
    final accountIds = {
      for (final a
          in await service.database.select(service.database.accounts).get())
        a.name: a.id,
    };
    final newAccounts = finalBalances.keys.where(
      (name) => !accountIds.containsKey(name),
    );
    for (final name in newAccounts.toList()) {
      accountIds[name] = await service.addAccount(name, AccountType.debit);
      final rowsOfAccount = parsed.where((p) => p.account == name);
      final sum = rowsOfAccount.fold(
        0.0,
        (s, p) => s + p.statement.amount.value,
      );
      final initial = ((finalBalances[name]! - sum) * 100).round() / 100;
      if (initial != 0) {
        final oldest = rowsOfAccount.last.statement.paymentDate.value;
        parsed.add((
          account: name,
          statement: StatementsCompanion.insert(
            title: 'Initial Balance',
            createdAt: DateTime.now(),
            paymentDate: oldest,
            account: 0,
            useDate: oldest,
            amount: initial,
            tags: const [DatabaseService.autoTag],
            note: 'This statement was auto-generated by the MoneyWise import.',
          ),
        ));
      }
    }

    final existingTags = {
      for (final t
          in await service.database.select(service.database.tags).get())
        t.name,
    };
    // A sub-category's parent becomes a tag too, so the picker can nest it.
    final newTags = {
      for (final p in parsed)
        for (final tag in p.statement.tags.value) ...[
          tag,
          if (tag.contains(DatabaseService.tagSeparator))
            tag.substring(0, tag.indexOf(DatabaseService.tagSeparator)),
        ],
    }.difference(existingTags);
    for (final tag in newTags) {
      await service.addTag(tag, 0xFF9E9E9E);
    }

    // Oldest first, so ids keep the order of statements on the same day.
    await service.addStatements([
      for (final p in parsed.reversed)
        p.statement.copyWith(account: Value(accountIds[p.account]!)),
    ]);
  });
  return rows.length - 1;
}
