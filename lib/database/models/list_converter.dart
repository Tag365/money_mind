import 'package:drift/drift.dart';


class ListConverter<T> extends TypeConverter<List<T>, String> {
  const ListConverter();

  @override
  List<T> fromSql(String fromDb) {
    if (fromDb.isEmpty) {
      return [];
    }
    return fromDb.split(',').map((e) => e.trim() as T).toList();
  }

  @override
  String toSql(List<T> value) {
    return value.join(',');
  }

}