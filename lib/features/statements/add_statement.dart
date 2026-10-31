import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';
import 'package:money_mind/common/glass_background.dart';
import 'package:money_mind/common/amount_expression.dart';
import 'package:money_mind/common/date_button.dart';
import 'package:money_mind/common/money_text.dart';
import 'package:money_mind/common/time_button.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/database/models/recurrences.dart';
import 'package:money_mind/features/statements/recurrence_dialog.dart';
import 'package:money_mind/features/statements/widgets/amount_field.dart';
import 'package:money_mind/features/statements/widgets/info_tile.dart';
import 'package:money_mind/features/statements/widgets/title_suggestions.dart';
import 'package:money_mind/features/tags/tag_select_dialog.dart';
import 'package:money_mind/features/tags/widgets/tags_field.dart';

typedef _Repeat = ({RecurrenceUnit unit, int every, bool ahead});

/// "12,50" for -12.5: how the amount field shows a stored amount.
String _amountText(double amount) =>
    amount.abs().toStringAsFixed(2).replaceAll('.', ',');

/// Creates a statement, or edits [statement] when it is given. [copyOf]
/// starts a new statement filled in from that one but dated now. Both are
/// meant to be pushed as their own page, which pops with true after saving.
///
/// The amount field gets the focus whenever [active] turns true, so the
/// Create tab is ready to type into.
class AddWidget extends StatefulWidget {
  final Statement? statement;
  final Statement? copyOf;
  final bool active;

  const AddWidget({
    super.key,
    this.statement,
    this.copyOf,
    this.active = false,
  });

  @override
  State<AddWidget> createState() => _AddWidgetState();
}

class _AddWidgetState extends State<AddWidget> {
  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final amountController = TextEditingController();
  final noteController = TextEditingController();
  final _amountFocus = FocusNode();
  final _titleFocus = FocusNode();
  DatabaseService databaseService = DatabaseService.instance;

  late final Stream<List<Account>> _accounts = databaseService.watchAccounts();
  late final Stream<List<Tag>> _tags = databaseService.watchTags();

  DateTime date = DateTime.now();

  /// Set when the date was picked, so it is kept for the next statement
  /// instead of following the clock.
  bool _datePicked = false;
  int? accountId;
  bool expense = true;
  final Set<String> selectedTags = {};
  _Repeat? _repeat;
  bool _saving = false;

  bool get _editing => widget.statement != null;

  @override
  void initState() {
    super.initState();
    final s = widget.statement ?? widget.copyOf;
    if (s != null) {
      titleController.text = s.title;
      amountController.text = _amountText(s.amount);
      noteController.text = s.note;
      accountId = s.account;
      expense = s.amount < 0;
      selectedTags.addAll(s.tags);
    }
    if (_editing) date = widget.statement!.paymentDate.toLocal();
    if (widget.active) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _activate());
    }
  }

  @override
  void didUpdateWidget(AddWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _activate();
  }

  void _activate() {
    if (!mounted) return;
    // The tab may have been opened hours ago.
    if (!_editing && !_datePicked) setState(() => date = DateTime.now());
    _amountFocus.requestFocus();
  }

  void _pickDate(DateTime picked) {
    setState(() {
      date = picked;
      _datePicked = true;
    });
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

  /// Empties the form; a picked date stays when [keepDate] is set.
  void _clear({bool keepDate = false}) {
    titleController.clear();
    amountController.clear();
    noteController.clear();
    setState(() {
      if (!keepDate || !_datePicked) {
        date = DateTime.now();
        _datePicked = false;
      }
      expense = true;
      selectedTags.clear();
      _repeat = null;
    });
  }

  /// Fills in the form from an earlier statement with the picked title, but
  /// not its amount, which differs most of the time.
  void _fillFrom(Statement s) {
    setState(() {
      accountId = s.account;
      expense = s.amount < 0;
      selectedTags
        ..clear()
        ..addAll(s.tags);
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
    final statement = await databaseService.addStatement(
      titleController.text,
      expense ? -amount : amount,
      accountId!,
      date,
      date,
      selectedTags.toList(),
      noteController.text,
    );
    if (_repeat case final r?) {
      await databaseService.setRecurrence(
        statement,
        r.unit,
        r.every,
        ahead: r.ahead,
      );
    }
    if (!mounted) return;
    if (widget.copyOf != null) {
      Navigator.pop(context, true);
      return;
    }
    _clear(keepDate: true);
    _amountFocus.requestFocus();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Statement saved')));
  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    noteController.dispose();
    _amountFocus.dispose();
    _titleFocus.dispose();
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

  Widget _titleField() {
    return Autocomplete<Statement>(
      textEditingController: titleController,
      focusNode: _titleFocus,
      displayStringForOption: (s) => s.title,
      // Editing keeps the statement's own values, so nothing to fill in.
      optionsBuilder: (value) {
        final query = value.text.trim();
        if (_editing || query.isEmpty) return const <Statement>[];
        return databaseService.titleSuggestions(query);
      },
      onSelected: _fillFrom,
      optionsViewBuilder: (context, onSelected, options) =>
          TitleSuggestions(options: options, onSelected: onSelected),
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) =>
          TextFormField(
            controller: controller,
            focusNode: focusNode,
            onFieldSubmitted: (_) => onSubmitted(),
            style: Theme.of(context).textTheme.titleMedium,
            decoration: const InputDecoration(
              labelText: 'Title',
              prefixIcon: Icon(Icons.short_text),
            ),
            validator: (value) =>
                value == null || value.isEmpty ? 'Please add a Title' : null,
          ),
    );
  }

  Widget _tagsField() {
    return StreamBuilder<List<Tag>>(
      stream: _tags,
      builder: (context, snapshot) {
        final tags = snapshot.data ?? [];
        final original = (widget.statement ?? widget.copyOf)?.tags ?? const [];
        // Drop selections whose tag was renamed or deleted in Manage tags,
        // but keep the edited or copied statement's own tags even if not in
        // the table. Not before the tags have loaded, which would drop all.
        if (snapshot.hasData) {
          selectedTags.retainWhere(
            (name) =>
                tags.any((t) => t.name == name) || original.contains(name),
          );
        }
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

  Future<void> _pickRepeat() async {
    final r = _repeat;
    await showDialog<void>(
      context: context,
      builder: (_) => RecurrenceDialog(
        from: date,
        // Not saved yet, so a series that starts at this statement.
        recurrence: r == null
            ? null
            : Recurrence(
                id: 0,
                start: date,
                unit: r.unit,
                every: r.every,
                generated: 1,
                ahead: r.ahead,
              ),
        onSave: (unit, every, ahead) async =>
            setState(() => _repeat = (unit: unit, every: every, ahead: ahead)),
        onTurnOff: () async => setState(() => _repeat = null),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = expense ? expenseColor : incomeColor;
    // Back, the close button and Cancel all ask before dropping changes.
    return PopScope(
      canPop: !_editing,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _closeEdit();
      },
      child: GlassBackground(child: _form(context, color)),
    );
  }

  Widget _form(BuildContext context, Color color) {
    final pushed = _editing || widget.copyOf != null;
    final repeat = _repeat;
    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Edit statement' : 'New statement'),
      ),
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
                  onPressed: pushed ? _closeEdit : _clear,
                  child: Text(pushed ? 'Cancel' : 'Clear'),
                ),
              ),
              Expanded(
                flex: 2,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: _saving ? null : _save,
                  child: Text(_editing ? 'Save changes' : 'Save'),
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
                  focusNode: _amountFocus,
                  onNext: _titleFocus.requestFocus,
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
                        DateButton(date, onChanged: _pickDate),
                        TimeButton(date, onChanged: _pickDate),
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
                      children: [_titleField(), _tagsField()],
                    ),
                  ),
                ),
                // An edited statement's series is changed in its details.
                if (!_editing)
                  Card(
                    margin: EdgeInsets.zero,
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: InfoTile(
                        Icons.repeat,
                        'Repeats',
                        Text(
                          repeat == null
                              ? 'Never'
                              : describeInterval(repeat.unit, repeat.every),
                        ),
                        onTap: _pickRepeat,
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
