import 'package:flutter/material.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/database_service.dart';

/// The breakdown entry of statements without tags.
const untagged = '';

typedef TagShare = ({String tag, double amount});

/// The amounts of [totals] per top-level tag, or with [parent] per tag of
/// that family (the parent itself included), largest first. Expenses unless
/// [income] is set.
List<TagShare> tagBreakdown(
  List<TagTotal> totals, {
  required bool income,
  String? parent,
}) {
  final sums = <String, double>{};
  for (final t in totals) {
    final amount = income ? t.income : t.expense;
    if (amount == 0) continue;
    // shortcut: a statement with several tags counts towards its first one
    // only; split its amount if multi-tag statements become common.
    final tag = t.tags.firstOrNull ?? untagged;
    final top = topLevelTag(tag);
    if (parent != null && top != parent) continue;
    final key = parent == null ? top : tag;
    sums[key] = (sums[key] ?? 0) + amount;
  }
  return [for (final e in sums.entries) (tag: e.key, amount: e.value)]
    ..sort((a, b) => b.amount.abs().compareTo(a.amount.abs()));
}

String topLevelTag(String tag) => tag.split(DatabaseService.tagSeparator).first;

/// The color of each tag by name, for [tagColor].
Map<String, Color> tagColors(List<Tag> tags) => {
  for (final t in tags) t.name: Color(t.color),
};

/// Grey for untagged statements and tags without a color.
Color tagColor(Map<String, Color> colors, String tag) =>
    colors[tag] ?? Colors.grey;
