import 'package:drift/drift.dart';

/// App settings as key/value pairs, in the database so backups include them.
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
