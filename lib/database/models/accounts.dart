import 'package:drift/drift.dart';
import 'package:money_mind/database/models/account_type.dart';

class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()();

  TextColumn get type => textEnum<AccountType>()();

  RealColumn get balance => real().withDefault(const Constant(0))();

  /// Closed accounts keep their statements but take no new ones.
  BoolColumn get closed => boolean().withDefault(const Constant(false))();

  /// Day of the month a credit card's billing period closes on, clamped to
  /// shorter months; null for the last day.
  IntColumn get closingDay => integer().nullable()();
}
