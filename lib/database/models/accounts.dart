import 'package:drift/drift.dart';
import 'package:money_mind/database/models/AccountType.dart';

class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()();

  TextColumn get type => textEnum<AccountType>()();

  RealColumn get balance => real().withDefault(const Constant(0))();

  /// Closed accounts keep their statements but take no new ones.
  BoolColumn get closed => boolean().withDefault(const Constant(false))();
}
