import 'package:drift/drift.dart';

class Tags extends Table {
  Int64Column get id => int64().autoIncrement()();
  TextColumn get name => text().withLength(min: 1)();
  // ARGB, as in Color.toARGB32(). Tags from before v3 get grey.
  IntColumn get color => integer().withDefault(const Constant(0xFF9E9E9E))();
}
