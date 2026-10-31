import 'package:drift/drift.dart';

/// Adds [column] to [table] unless it is already there. Upgrades are not
/// transactional: a run cut short (e.g. by a restart) may have added the
/// column without storing the new version.
Future<void> addColumnIfMissing(
  GeneratedDatabase db,
  Migrator m,
  TableInfo table,
  GeneratedColumn column,
) async {
  final columns = await db
      .customSelect('PRAGMA table_info(${table.actualTableName})')
      .get();
  if (!columns.any((c) => c.read<String>('name') == column.name)) {
    await m.addColumn(table, column);
  }
}
