import 'package:flutter/material.dart';
import 'package:money_mind/amount_expression.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/screens/manage_tags.dart';

class AddWidget extends StatefulWidget {
  const AddWidget({super.key});

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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    // Keep the time of day, only the calendar day changes.
    setState(() {
      date = DateTime(
        picked.year,
        picked.month,
        picked.day,
        date.hour,
        date.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(date),
    );
    if (picked == null) return;
    setState(() {
      date = DateTime(
        date.year,
        date.month,
        date.day,
        picked.hour,
        picked.minute,
      );
    });
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

  /// "= 19.70" below the field while it holds more than one charge.
  String? _amountTotal() {
    final text = amountController.text.trim();
    if (!text.substring(text.isEmpty ? 0 : 1).contains(RegExp('[+-]'))) {
      return null;
    }
    final total = evaluateAmount(text);
    return total == null ? null : '= ${total.toStringAsFixed(2)}';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || accountId == null) return;
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
        final accounts = snapshot.data ?? [];
        if (accounts.isEmpty) {
          return const Text('Create an account first.');
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
        // Drop selections whose tag was renamed or deleted in Manage tags.
        selectedTags.retainWhere((name) => tags.any((t) => t.name == name));
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _selectTags(tags),
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Tags',
              prefixIcon: Icon(Icons.label_outline),
              suffixIcon: Icon(Icons.arrow_drop_down),
            ),
            isEmpty: selectedTags.isEmpty,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final tag in tags)
                  if (selectedTags.contains(tag.name)) _tagLabel(tag),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectTags(List<Tag> tags) async {
    final selection = {...selectedTags};
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Select tags'),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          content: SizedBox(
            width: double.maxFinite,
            child: tags.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text('No tags yet. Add them in Manage tags.'),
                  )
                : ListView(
                    shrinkWrap: true,
                    children: [
                      for (final tag in tags)
                        CheckboxListTile(
                          title: _tagLabel(tag, expand: true),
                          value: selection.contains(tag.name),
                          onChanged: (checked) => setDialogState(() {
                            checked!
                                ? selection.add(tag.name)
                                : selection.remove(tag.name);
                          }),
                        ),
                    ],
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  this.context,
                  MaterialPageRoute(builder: (_) => const ManageTagsScreen()),
                );
              },
              child: const Text('Manage tags'),
            ),
            TextButton(
              onPressed: () => setDialogState(selection.clear),
              child: const Text('Clear'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, selection),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
    if (result == null) return;
    setState(() {
      selectedTags
        ..clear()
        ..addAll(result);
    });
  }

  /// Tag name on its color, full width in the dialog and compact in the field.
  Widget _tagLabel(Tag tag, {bool expand = false}) {
    final color = Color(tag.color);
    // Dark text on light colors (yellow, cyan), white text otherwise.
    final textColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.light
        ? Colors.black
        : Colors.white;
    return Container(
      width: expand ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(tag.name, style: TextStyle(color: textColor)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Same colors as MoneyText.
    final color = expense ? Colors.red.shade400 : Colors.green.shade600;
    final total = _amountTotal();
    return Scaffold(
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
                  onPressed: _clear,
                  child: const Text('Clear'),
                ),
              ),
              Expanded(
                flex: 2,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _save,
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
      // Filled fields without outline; a primary border marks focus.
      body: Theme(
        data: Theme.of(context).copyWith(
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Column(
                spacing: 20,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        // Same width for both labels.
                        minimumSize: const Size(110, 40),
                        backgroundColor: Colors.grey.shade200,
                        foregroundColor: color,
                      ),
                      onPressed: () => setState(() => expense = !expense),
                      child: Text(expense ? 'Expense' : 'Income'),
                    ),
                  ),
                  Column(
                    children: [
                      TextFormField(
                        controller: amountController,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                        decoration: InputDecoration(
                          hintText: '0,00',
                          filled: false,
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.euro_sharp, color: color),
                          suffixIcon: IconButton(
                            tooltip: 'Add another charge',
                            icon: const Icon(Icons.add),
                            onPressed: () =>
                                setState(() => amountController.text += ' + '),
                          ),
                        ),
                        // signed: shows a minus key on the number keyboard.
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (value) {
                          final amount = evaluateAmount(value ?? '');
                          if (amount == null || amount <= 0) {
                            return 'Please enter a positive amount';
                          }
                          return null;
                        },
                      ),
                      if (total != null)
                        Text(
                          total,
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(color: color),
                        ),
                    ],
                  ),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          TextButton.icon(
                            onPressed: _pickDate,
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              date.toIso8601String().substring(0, 10),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _pickTime,
                            icon: const Icon(Icons.schedule),
                            label: Text(
                              MaterialLocalizations.of(context).formatTimeOfDay(
                                TimeOfDay.fromDateTime(date),
                                alwaysUse24HourFormat: true,
                              ),
                            ),
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
      ),
    );
  }
}
