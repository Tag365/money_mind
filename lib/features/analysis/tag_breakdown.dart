import 'package:flutter/material.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/database_service.dart';

/// The breakdown entry of statements without tags.
const untagged = '';

typedef TagShare = ({String tag, double amount});

/// The amounts of [totals] per top-level tag, or with [parent] per tag of
/// that family (the parent itself included), largest first, and their
/// [total]. Expenses unless [income] is set.
///
/// A statement counts fully towards each of its tags, as the tag filter
/// matches it, but once towards [total]; so shares can add up to more.
({double total, List<TagShare> shares}) tagBreakdown(
  List<TagTotal> totals, {
  required bool income,
  String? parent,
}) {
  var total = 0.0;
  final sums = <String, double>{};
  for (final t in totals) {
    final amount = income ? t.income : t.expense;
    if (amount == 0) continue;
    final keys = t.tags.isEmpty
        ? {if (parent == null) untagged}
        : {
            for (final tag in t.tags)
              if (parent == null)
                topLevelTag(tag)
              else if (topLevelTag(tag) == parent)
                tag,
          };
    if (keys.isNotEmpty) total += amount;
    for (final key in keys) {
      sums[key] = (sums[key] ?? 0) + amount;
    }
  }
  final shares = [for (final e in sums.entries) (tag: e.key, amount: e.value)]
    ..sort((a, b) => b.amount.abs().compareTo(a.amount.abs()));
  return (total: total, shares: shares);
}

String topLevelTag(String tag) => tag.split(DatabaseService.tagSeparator).first;

/// The color of each tag by name, for [tagColor].
Map<String, Color> tagColors(List<Tag> tags) => {
  for (final t in tags) t.name: Color(t.color),
};

/// Grey for untagged statements and tags without a color.
Color tagColor(Map<String, Color> colors, String tag) =>
    colors[tag] ?? Colors.grey;
