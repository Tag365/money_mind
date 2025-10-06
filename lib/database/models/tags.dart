import 'package:drift/drift.dart';

class Tags extends Table {
  Int64Column get id => int64().autoIncrement()();
  TextColumn get name => text().withLength(min: 1)();
}