import 'package:flutter/material.dart';
import 'package:money_mind/amount_expression.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/database_service.dart';

/// Bottom sheet that moves money between two of [accounts] (at least two).
class TransferForm extends StatefulWidget {
  final List<Account> accounts;

  const TransferForm({super.key, required this.accounts});

  @override
  State<TransferForm> createState() => _TransferFormState();
}

class _TransferFormState extends State<TransferForm> {
  final _formKey = GlobalKey<FormState>();
  final amountController = TextEditingController();
  late Account from = widget.accounts[0];
  late Account to = widget.accounts[1];
  DateTime date = DateTime.now();
  // Set for good: the sheet closes after saving.
  bool _saving = false;

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

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await DatabaseService.instance.addTransfer(
      from,
      to,
      evaluateAmount(amountController.text)!,
      date,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  Widget _accountField(
    String label,
    Account value,
    ValueChanged<Account> onChanged,
  ) {
    return DropdownButtonFormField<int>(
      initialValue: value.id,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final a in widget.accounts)
          DropdownMenuItem(value: a.id, child: Text(a.name)),
      ],
      onChanged: (id) => setState(
        () => onChanged(widget.accounts.firstWhere((a) => a.id == id)),
      ),
      validator: (_) =>
          from.id == to.id ? 'Choose two different accounts' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          spacing: 20,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Transfer', style: Theme.of(context).textTheme.headlineSmall),
            _accountField('From', from, (a) => from = a),
            _accountField('To', to, (a) => to = a),
            TextFormField(
              controller: amountController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.euro_sharp),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              validator: (value) {
                final amount = evaluateAmount(value ?? '');
                if (amount == null || amount <= 0) {
                  return 'Please enter a positive amount';
                }
                return null;
              },
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today),
                label: Text(date.toIso8601String().substring(0, 10)),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: _saving ? null : _save,
              child: const Text('Transfer'),
            ),
          ],
        ),
      ),
    );
  }
}
