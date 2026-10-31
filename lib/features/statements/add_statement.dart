import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';
import 'package:money_mind/common/glass_background.dart';
import 'package:money_mind/common/amount_expression.dart';
import 'package:money_mind/common/date_button.dart';
import 'package:money_mind/common/money_text.dart';
import 'package:money_mind/common/time_button.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/features/statements/widgets/amount_field.dart';
import 'package:money_mind/features/tags/tag_select_dialog.dart';
import 'package:money_mind/features/tags/widgets/tags_field.dart';

/// Creates a statement, or edits [statement] when it is given. In edit mode it
/// is meant to be pushed as its own page and pops with true after saving.
class AddWidget extends StatefulWidget {
  final Statement? statement;

  const AddWidget({super.key, this.statement});

  @override
  State<AddWidget> createState() => _AddWidgetState();
}

class _AddWidgetState extends State<AddWidget> {
  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final amountController = TextEditingController();
  final noteController = TextEditingController();
  DatabaseService databaseService = DatabaseService.instance;

  late final Stream<List<Account>> _accounts = databaseService.watchAccounts();
  late final Stream<List<Tag>> _tags = databaseService.watchTags();

  DateTime date = DateTime.now();
  int? accountId;
  bool expense = true;
  final Set<String> selectedTags = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.statement;
    if (s == null) return;
    titleController.text = s.title;
    amountController.text = s.amount
        .abs()
        .toStringAsFixed(2)
        .replaceAll('.', ',');
    noteController.text = s.note;
    date = s.paymentDate.toLocal();
    accountId = s.account;
    expense = s.amount < 0;
    selectedTags.addAll(s.tags);
  }

  /// The amount as stored: negative for expenses, null while invalid.
  double? _signedAmount() {
    final amount = evaluateAmount(amountController.text);
    if (amount == null) return null;
    return expense ? -amount : amount;
  }

  bool get _hasChanges {
    final s = widget.statement;
    if (s == null) return false;
    return titleController.text != s.title ||
        noteController.text != s.note ||
        _signedAmount() != s.amount ||
        date != s.paymentDate.toLocal() ||
        accountId != s.account ||
        !setEquals(selectedTags, s.tags.toSet());
  }

  Future<void> _closeEdit() async {
    final discard =
        !_hasChanges ||
        await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Discard changes?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Keep editing'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Discard'),
                  ),
                ],
              ),
            ) ==
            true;
    if (discard && mounted) Navigator.pop(context, false);
  }

  void _clear() {
    titleController.clear();
    amountController.clear();
    noteController.clear();
    setState(() {
      date = DateTime.now();
      expense = true;
      selectedTags.clear();
    });
  }

  // A second tap while the first save runs would save twice.
  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await _write();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _write() async {
    if (!_formKey.currentState!.validate() || accountId == null) return;
    final edited = widget.statement;
    if (edited != null) {
      // copyWith keeps the fields this form does not show (use date, ...).
      await databaseService.updateStatement(
        edited.copyWith(
          title: titleController.text,
          amount: _signedAmount(),
          account: accountId,
          paymentDate: date,
          tags: selectedTags.toList(),
          note: noteController.text,
        ),
      );
      if (mounted) Navigator.pop(context, true);
      return;
    }
    final double amount = evaluateAmount(amountController.text)!;
    await databaseService.addStatement(
      titleController.text,
      expense ? -amount : amount,
      accountId!,
      date,
      date,
      selectedTags.toList(),
      noteController.text,
    );
    if (!mounted) return;
    _clear();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Statement saved')));
  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Widget _accountField() {
    return StreamBuilder<List<Account>>(
      stream: _accounts,
      builder: (context, snapshot) {
        // An edited statement keeps its account even when it is closed.
        final accounts = [
          for (final a in snapshot.data ?? <Account>[])
            if (!a.closed || a.id == widget.statement?.account) a,
        ];
        if (accounts.isEmpty) {
          return const Text('No open account. Add one in Accounts.');
        }
        if (!accounts.any((a) => a.id == accountId)) {
          accountId = accounts.first.id;
        }
        return DropdownButton<int>(
          value: accountId,
          isExpanded: true,
          underline: const SizedBox.shrink(),
          items: [
            for (final a in accounts)
              DropdownMenuItem(value: a.id, child: Text(a.name)),
          ],
          onChanged: (id) => setState(() => accountId = id),
        );
      },
    );
  }

  Widget _tagsField() {
    return StreamBuilder<List<Tag>>(
      stream: _tags,
      builder: (context, snapshot) {
        final tags = snapshot.data ?? [];
        final original = widget.statement?.tags ?? const [];
        // Drop selections whose tag was renamed or deleted in Manage tags,
        // but keep the edited statement's own tags even if not in the table.
        selectedTags.retainWhere(
          (name) => tags.any((t) => t.name == name) || original.contains(name),
        );
        return TagsField(
          tags: tags,
          selected: selectedTags,
          onTap: () => _selectTags(tags),
        );
      },
    );
  }

  Future<void> _selectTags(List<Tag> tags) async {
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (_) => TagSelectDialog(tags: tags, selected: selectedTags),
    );
    if (result == null) return;
    setState(() {
      selectedTags
        ..clear()
        ..addAll(result);
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = expense ? expenseColor : incomeColor;
    final editing = widget.statement != null;
    // Back, the close button and Cancel all ask before dropping changes.
    return PopScope(
      canPop: !editing,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _closeEdit();
      },
      child: GlassBackground(child: _form(context, color, editing)),
    );
  }

  Widget _form(BuildContext context, Color color, bool editing) {
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Edit statement' : 'New statement')),
      // Pinned above the keyboard and the tab bar.
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            spacing: 12,
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: editing ? _closeEdit : _clear,
                  child: Text(editing ? 'Cancel' : 'Clear'),
                ),
              ),
              Expanded(
                flex: 2,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: _saving ? null : _save,
                  child: Text(editing ? 'Save changes' : 'Save'),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Column(
              spacing: 20,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AmountField(
                  controller: amountController,
                  color: color,
                  trailing: FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      // Same width for both labels.
                      minimumSize: const Size(110, 40),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      foregroundColor: color,
                    ),
                    onPressed: () => setState(() => expense = !expense),
                    child: Text(expense ? 'Expense' : 'Income'),
                  ),
                ),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        DateButton(
                          date,
                          onChanged: (d) => setState(() => date = d),
                        ),
                        TimeButton(
                          date,
                          onChanged: (d) => setState(() => date = d),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.account_balance_wallet_outlined),
                        const SizedBox(width: 8),
                        Expanded(child: _accountField()),
                      ],
                    ),
                  ),
                ),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      spacing: 12,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: titleController,
                          style: Theme.of(context).textTheme.titleMedium,
                          decoration: const InputDecoration(
                            labelText: 'Title',
                            prefixIcon: Icon(Icons.short_text),
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Please add a Title'
                              : null,
                        ),
                        _tagsField(),
                      ],
                    ),
                  ),
                ),
                // Optional, so plain and below the card.
                TextFormField(
                  controller: noteController,
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: const InputDecoration(
                    hintText: 'Write a note (optional)',
                    prefixIcon: Icon(Icons.notes),
                    filled: false,
                    border: InputBorder.none,
                  ),
                  maxLines: null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
