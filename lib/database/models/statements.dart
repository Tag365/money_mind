import 'package:drift/drift.dart';
import 'package:money_mind/database/models/accounts.dart';
import 'package:money_mind/database/models/list_converter.dart';

class Statements extends Table {
  // Internal
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get createdAt => dateTime()();

  // Characteristics
  TextColumn get title => text()();
  DateTimeColumn get paymentDate => dateTime()();
  IntColumn get account => integer().references(Accounts, #id)();
  DateTimeColumn get useDate => dateTime()();
  RealColumn get amount => real()();
  TextColumn get tags => text().map(const ListConverter<String>())();
  TextColumn get note => text()();

  @override
  String toString() {
    return "[$id] $title: $amount tags: $tags";
  }
}
