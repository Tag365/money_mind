import 'package:flutter/material.dart';

import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/features/statements/statement_filter.dart';

/// Edits a [StatementFilter]. Pops with the new filter, or null when
/// dismissed.
class StatementFilterSheet extends StatefulWidget {
  final StatementFilter filter;
  final Map<int, String> accountNames;

  const StatementFilterSheet(this.filter, this.accountNames, {super.key});

  @override
  State<StatementFilterSheet> createState() => _StatementFilterSheetState();
}

class _StatementFilterSheetState extends State<StatementFilterSheet> {
  late final Stream<List<Tag>> _tags = DatabaseService.instance.watchTags();
  late final Set<int> _accounts = {...widget.filter.accounts};
  late final Set<String> _selectedTags = {...widget.filter.tags};
  late bool _excludeTags = widget.filter.excludeTags;
  late bool _income = widget.filter.income;
  late bool _expense = widget.filter.expense;
  late final _text = TextEditingController(text: widget.filter.text);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _toggle<T>(Set<T> set, T value, bool selected) =>
      setState(() => selected ? set.add(value) : set.remove(value));

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(text, style: Theme.of(context).textTheme.titleSmall),
  );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter statements',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          _label('Accounts'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final MapEntry(key: id, value: name)
                  in widget.accountNames.entries)
                FilterChip(
                  label: Text(name),
                  selected: _accounts.contains(id),
                  onSelected: (s) => _toggle(_accounts, id, s),
                ),
            ],
          ),
          Row(
            children: [
              Expanded(child: _label('Tags')),
              const Text('Exclude'),
              Checkbox(
                value: _excludeTags,
                onChanged: (v) => setState(() => _excludeTags = v!),
              ),
            ],
          ),
          StreamBuilder(
            stream: _tags,
            builder: (context, snapshot) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in snapshot.data ?? <Tag>[])
                  FilterChip(
                    label: Text(tag.name),
                    selected: _selectedTags.contains(tag.name),
                    onSelected: (s) => _toggle(_selectedTags, tag.name, s),
                  ),
              ],
            ),
          ),
          _label('Income or expense'),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('Expense'),
                selected: _expense,
                onSelected: (s) => setState(() => _expense = s),
              ),
              FilterChip(
                label: const Text('Income'),
                selected: _income,
                onSelected: (s) => setState(() => _income = s),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _text,
            decoration: const InputDecoration(
              labelText: 'Search title and note',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            spacing: 8,
            children: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(context, const StatementFilter()),
                child: const Text('No filter'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(
                  context,
                  StatementFilter(
                    accounts: _accounts,
                    tags: _selectedTags,
                    excludeTags: _excludeTags,
                    // Not in the sheet; kept from the page that opened it.
                    childTags: widget.filter.childTags,
                    transfers: widget.filter.transfers,
                    income: _income,
                    expense: _expense,
                    text: _text.text.trim(),
                  ),
                ),
                child: const Text('Filter'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
