import 'package:json_annotation/json_annotation.dart';
import 'package:money_mind/database/ID.dart';
import 'package:money_mind/database/models/tag.dart';

part 'statement.g.dart';

@JsonSerializable(explicitToJson: true)
class Statement {
  // Internal
  @JsonKey(name: 'id', required: true)
  final String id;
  @JsonKey(name: 'createdAt', required: true)
  final DateTime createdAt;

  // Characteristics
  @JsonKey(name: 'title', required: true)
  final String title;
  @JsonKey(name: 'paymentDate', required: true)
  final DateTime paymentDate;
  @JsonKey(name: 'useDate', required: true)
  final DateTime useDate;
  @JsonKey(name: 'amount', required: true)
  final double amount;
  @JsonKey(name: 'isExpense', required: true)
  final bool isExpense;
  @JsonKey(name: 'tags', required: true, toJson: tagsToJson, fromJson: tagsFromJson )
  final List<String> tags;
  @JsonKey(name: 'note', required: true)
  final String note;

  Statement({
    String? id,
    required this.createdAt,
    required this.title,
    required this.paymentDate,
    required this.useDate,
    required this.amount,
    required this.isExpense,
    required this.tags,
    this.note = "",
  }) : id = id ?? ID.generate();

  Map<String, dynamic> toJson() => _$StatementToJson(this);

  factory Statement.fromJson(Map<String, dynamic> json) => _$StatementFromJson(json);

  @override
  String toString() {
    return "[$id] $title: ${isExpense ? '-' : ''}\$$amount tags: ${tags.join(', ')}";
  }

  static String tagsToJson(List<String> tags) {
    return tags.join(',');
  }
  static List<String> tagsFromJson(String tags) {
    if (tags.isEmpty) return [];
    return tags.split(',').map((e) => e.trim()).toList();
  }
}
