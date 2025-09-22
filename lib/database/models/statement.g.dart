// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'statement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Statement _$StatementFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'id',
      'createdAt',
      'title',
      'paymentDate',
      'useDate',
      'amount',
      'isExpense',
      'tags',
      'note',
    ],
  );
  return Statement(
    id: json['id'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    title: json['title'] as String,
    paymentDate: DateTime.parse(json['paymentDate'] as String),
    useDate: DateTime.parse(json['useDate'] as String),
    amount: (json['amount'] as num).toDouble(),
    isExpense: json['isExpense'] as bool,
    tags: Statement.tagsFromJson(json['tags'] as String),
    note: json['note'] as String? ?? "",
  );
}

Map<String, dynamic> _$StatementToJson(Statement instance) => <String, dynamic>{
  'id': instance.id,
  'createdAt': instance.createdAt.toIso8601String(),
  'title': instance.title,
  'paymentDate': instance.paymentDate.toIso8601String(),
  'useDate': instance.useDate.toIso8601String(),
  'amount': instance.amount,
  'isExpense': instance.isExpense,
  'tags': Statement.tagsToJson(instance.tags),
  'note': instance.note,
};
