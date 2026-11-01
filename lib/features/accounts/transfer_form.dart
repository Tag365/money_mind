import 'package:flutter/material.dart';
import 'package:money_mind/common/amount_expression.dart';
import 'package:money_mind/common/date_button.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/database_service.dart';

/// Bottom sheet that moves money between two of [accounts] (at least two).
/// [from], [to] and [amount] fill it in; with a [title] it is the sheet's
/// heading and the title of both statements.
class TransferForm extends StatefulWidget {
  final List<Account> accounts;
  final Account? from;
  final Account? to;
  final double? amount;
  final String? title;

  /// Shown below the amount, e.g. where it comes from.
  final String? amountHelper;

  const TransferForm({
    super.key,
    required this.accounts,
    this.from,
    this.to,
    this.amount,
    this.title,
    this.amountHelper,
  });

  @override
  State<TransferForm> createState() => _TransferFormState();
}

class _TransferFormState extends State<TransferForm> {
  final _formKey = GlobalKey<FormState>();
  late final amountController = TextEditingController(
    text: widget.amount?.toStringAsFixed(2).replaceAll('.', ','),
  );
  late Account from = widget.from ?? widget.accounts[0];
  late Account to = widget.to ?? widget.accounts[1];
  DateTime date = DateTime.now();
  // Set for good: the sheet closes after saving.
  bool _saving = false;

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await DatabaseService.instance.addTransfer(
      from,
      to,
      evaluateAmount(amountController.text)!,
      date,
      title: widget.title,
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
      decoration: InputDecoration(labelText: label),
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
            Text(
              widget.title ?? 'Transfer',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            _accountField('From', from, (a) => from = a),
            _accountField('To', to, (a) => to = a),
            TextFormField(
              controller: amountController,
              autofocus: widget.amount == null,
              decoration: InputDecoration(
                labelText: 'Amount',
                helperText: widget.amountHelper,
                prefixIcon: const Icon(Icons.euro_sharp),
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
              child: DateButton(
                date,
                onChanged: (d) => setState(() => date = d),
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
