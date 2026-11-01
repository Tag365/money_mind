import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/database_service.dart';

/// A copy of the whole database as an SQLite file.
Future<Uint8List> exportBackup() async {
  final dir = await Directory.systemTemp.createTemp('backup');
  try {
    final file = File('${dir.path}/backup.sqlite');
    await DatabaseService.instance.database.customStatement('VACUUM INTO ?', [
      file.path,
    ]);
    return await file.readAsBytes();
  } finally {
    await dir.delete(recursive: true);
  }
}

/// Replaces all data with that of a backup from [exportBackup], migrating a
/// backup from an older app version first. Throws [FormatException] for a
/// file that is not a Money Mind backup, leaving the data unchanged.
Future<void> restoreBackup(Uint8List bytes) async {
  const header = 'SQLite format 3\x00';
  if (bytes.length < header.length ||
      String.fromCharCodes(bytes.take(header.length)) != header) {
    throw const FormatException('Not a Money Mind backup.');
  }
  final db = DatabaseService.instance.database;
  final dir = await Directory.systemTemp.createTemp('restore');
  try {
    final file = File('${dir.path}/restore.sqlite');
    await file.writeAsBytes(bytes);

    final version = await _attached(db, file, () async {
      final row = await db
          .customSelect('PRAGMA backup.user_version')
          .getSingle();
      return row.read<int>('user_version');
    });
    // 0 is a database Money Mind never created.
    if (version == 0 || version > db.schemaVersion) {
      throw FormatException(
        version == 0
            ? 'Not a Money Mind backup.'
            : 'The backup is from a newer version of Money Mind.',
      );
    }
    if (version < db.schemaVersion) {
      final old = AppDatabase(NativeDatabase(file));
      await old.customSelect('SELECT 1').get(); // opening runs the migrations
      await old.close();
    }

    await _attached(
      db,
      file,
      () => db.transaction(() async {
        for (final table in db.allTables) {
          final name = table.actualTableName;
          final columns = table.$columns.map((c) => '"${c.name}"').join(', ');
          await db.customStatement('DELETE FROM main."$name"');
          // Named columns, as migrations may have added them in another order.
          await db.customStatement(
            'INSERT INTO main."$name" ($columns) '
            'SELECT $columns FROM backup."$name"',
          );
        }
      }),
    );
    db.notifyUpdates({for (final t in db.allTables) TableUpdate.onTable(t)});
  } finally {
    await dir.delete(recursive: true);
  }
}

Future<T> _attached<T>(
  AppDatabase db,
  File file,
  Future<T> Function() body,
) async {
  await db.customStatement('ATTACH DATABASE ? AS backup', [file.path]);
  try {
    return await body();
  } finally {
    await db.customStatement('DETACH DATABASE backup');
  }
}
