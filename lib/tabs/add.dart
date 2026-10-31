import 'package:flutter/material.dart';
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || accountId == null) return;
    final double amount = double.parse(
      amountController.text.replaceAll(',', '.'),
    );
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
        return DropdownMenu<int>(
          expandedInsets: EdgeInsets.zero,
          label: const Text('Account'),
          initialSelection: accountId,
          dropdownMenuEntries: [
            for (final a in accounts)
              DropdownMenuEntry(value: a.id, label: a.name),
          ],
          onSelected: (id) => setState(() => accountId = id),
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
          onTap: () => _selectTags(tags),
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Tags',
              border: OutlineInputBorder(),
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
    return Scaffold(
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Column(
              spacing: 20,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    MaterialLocalizations.of(context).formatMediumDate(date),
                  ),
                ),
                _accountField(),
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter a description'
                      : null,
                ),
                _tagsField(),
                Row(
                  spacing: 12,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: amountController,
                        decoration: const InputDecoration(
                          labelText: 'Amount',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.euro_sharp),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          final amount = double.tryParse(
                            (value ?? '').replaceAll(',', '.'),
                          );
                          if (amount == null || amount <= 0) {
                            return 'Please enter a positive amount';
                          }
                          return null;
                        },
                      ),
                    ),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: true, label: Text('Expense')),
                        ButtonSegment(value: false, label: Text('Income')),
                      ],
                      selected: {expense},
                      onSelectionChanged: (s) =>
                          setState(() => expense = s.first),
                    ),
                  ],
                ),
                TextFormField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: null,
                ),
                Row(
                  spacing: 12,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _clear,
                        child: const Text('Clear'),
                      ),
                    ),
                    Expanded(
                      child: FilledButton(
                        onPressed: _save,
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
