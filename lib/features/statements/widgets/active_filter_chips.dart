import 'package:flutter/material.dart';
import 'package:money_mind/features/statements/statement_filter.dart';

/// One removable chip per active part of [filter]. Removing a chip calls
/// [onChanged] with the filter without that part.
class ActiveFilterChips extends StatelessWidget {
  final StatementFilter filter;
  final Map<int, String> accountNames;
  final ValueChanged<StatementFilter> onChanged;

  const ActiveFilterChips({
    super.key,
    required this.filter,
    required this.accountNames,
    required this.onChanged,
  });

  Widget _chip(String label, StatementFilter without) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: InputChip(label: Text(label), onDeleted: () => onChanged(without)),
  );

  @override
  Widget build(BuildContext context) {
    final f = filter;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          for (final id in f.accounts)
            _chip(
              accountNames[id] ?? '?',
              f.copyWith(accounts: {...f.accounts}..remove(id)),
            ),
          for (final tag in f.tags)
            _chip(
              f.excludeTags ? 'Not $tag' : tag,
              f.copyWith(tags: {...f.tags}..remove(tag)),
            ),
          if (f.income != f.expense)
            _chip(
              f.income ? 'Income' : 'Expense',
              f.copyWith(income: false, expense: false),
            ),
          if (f.text.isNotEmpty) _chip('"${f.text}"', f.copyWith(text: '')),
        ],
      ),
    );
  }
}
