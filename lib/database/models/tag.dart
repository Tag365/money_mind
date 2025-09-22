import 'package:json_annotation/json_annotation.dart';
part 'tag.g.dart';

@JsonSerializable()
class Tag {
  @JsonKey(name: 'id')
  final int id;
  @JsonKey(name: 'name')
  final String name;

  Tag({required this.id, required this.name});

  factory Tag.fromJson(Map<String, dynamic> json) => _$TagFromJson(json);

  Map<String, dynamic> toJson() => _$TagToJson(this);
}