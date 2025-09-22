import 'package:json_annotation/json_annotation.dart';
import 'package:money_mind/database/models/AccountType.dart';
import 'package:money_mind/database/models/statement.dart';
import 'package:money_mind/database/ID.dart';

part 'account.g.dart';

@JsonSerializable(explicitToJson: true)
class Account {
  @JsonKey(name: 'id')
  final String id;
  @JsonKey(name: 'name')
  final String name;
  @JsonKey(name: 'type')
  final AccountType type;
  @JsonKey(name: 'statements', includeToJson: false)
  final List<Statement> statements;

  Map<String, Object?> toJson() => _$AccountToJson(this);

  Account({
    required this.name,
    required this.type,
    String? id,
    List<Statement>? statements,
  }) : id = id ?? ID.generate(),
       statements = statements ?? [];

  factory Account.fromJson(Map<String, dynamic> json) =>
      _$AccountFromJson(json);

  @override
  String toString() {
    return "[$id] $name: ${statements.length} statements";
  }

  double get totalBalance {
    double balance = 0.0;
    for (var statement in statements) {
      balance += statement.isExpense ? -statement.amount : statement.amount;
    }
    return balance;
  }
}

