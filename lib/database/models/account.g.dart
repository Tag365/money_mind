// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Account _$AccountFromJson(Map<String, dynamic> json) => Account(
  name: json['name'] as String,
  type: $enumDecode(_$AccountTypeEnumMap, json['type']),
  id: json['id'] as String?,
  statements: (json['statements'] as List<dynamic>?)
      ?.map((e) => Statement.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$AccountToJson(Account instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'type': _$AccountTypeEnumMap[instance.type]!,
};

const _$AccountTypeEnumMap = {
  AccountType.debit: 'debit',
  AccountType.creditCard: 'creditCard',
};
