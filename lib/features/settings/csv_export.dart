import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:money_mind/database/database_service.dart';

/// All statements, oldest first, as a CSV file for spreadsheets. Transfers
/// appear once per side, and dates are local time.
Future<Uint8List> exportCsv() async {
  final db = DatabaseService.instance.database;
  final accounts = {
    for (final a in await db.select(db.accounts).get()) a.id: a.name,
  };
  final statements =
      await (db.select(db.statements)..orderBy([
            (s) => OrderingTerm(expression: s.paymentDate),
            (s) => OrderingTerm(expression: s.id),
          ]))
          .get();
  final rows = [
    ['Date', 'Title', 'Amount', 'Account', 'Tags', 'Note'],
    for (final s in statements)
      [
        s.paymentDate
            .toLocal()
            .toIso8601String()
            .substring(0, 16)
            .replaceFirst('T', ' '),
        _text(s.title),
        s.amount.toStringAsFixed(2),
        _text(accounts[s.account]!),
        _text(s.tags.join(', ')),
        _text(s.note),
      ],
  ];
  // The byte order mark makes Excel read the file as UTF-8.
  return utf8.encode(
    '﻿${rows.map((row) => '${row.map(_quoted).join(',')}\r\n').join()}',
  );
}

/// Free text, kept from running as a formula when a spreadsheet opens it.
String _text(String value) =>
    value.startsWith(RegExp(r'[=+\-@\t\r]')) ? "'$value" : value;

String _quoted(String field) => field.contains(RegExp('[",\r\n]'))
    ? '"${field.replaceAll('"', '""')}"'
    : field;
