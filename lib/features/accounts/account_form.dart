import 'package:flutter/material.dart';

import 'package:money_mind/common/amount_expression.dart';
import 'package:money_mind/database/app_database.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/database/models/account_type.dart';

/// Adds an account, or renames [account] and changes its type when given.
/// Its balance only changes through statements, so editing has no balance
/// field.
class AccountForm extends StatefulWidget {
  final Account? account;

  const AccountForm({super.key, this.account});

  @override
  State<AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends State<AccountForm> {
  final _formKey = GlobalKey<FormState>();
  late final accountNameController = TextEditingController(
    text: widget.account?.name,
  );
  final balanceController = TextEditingController();
  late final closingDayController = TextEditingController(
    text: widget.account?.closingDay?.toString(),
  );
  DatabaseService databaseService = DatabaseService.instance;
  late AccountType? accountType = widget.account?.type ?? AccountType.debit;

  bool get _creditCard => accountType == AccountType.creditCard;

  /// Null for the last day of the month, and for accounts that are no card.
  int? get _closingDay =>
      _creditCard ? int.tryParse(closingDayController.text) : null;
  // Set for good: the sheet closes after saving.
  bool _saving = false;

  bool get _editing => widget.account != null;

  void _save() async {
    if (_saving || !_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    if (widget.account case final account?) {
      await databaseService.updateAccount(
        account,
        accountNameController.text,
        accountType!,
        closingDay: _closingDay,
      );
      if (mounted) Navigator.pop(context, account.id);
      return;
    }
    final double initialBalance = evaluateAmount(balanceController.text)!;
    int accountId = await databaseService.addAccount(
      accountNameController.text,
      accountType!,
      closingDay: _closingDay,
    );

    await databaseService.addStatement(
      "Initial Balance",
      initialBalance,
      accountId,
      DateTime.timestamp(),
      DateTime.timestamp(),
      [DatabaseService.autoTag],
      "This statement was auto-generated when the account was created.",
    );
    if (!mounted) return;
    Navigator.pop(context, accountId);
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    accountNameController.dispose();
    balanceController.dispose();
    closingDayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      _editing ? 'Edit account' : 'Add account',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: 20),
                    Form(
                      key: _formKey,
                      child: Column(
                        spacing: 20,
                        children: [
                          TextFormField(
                            controller: accountNameController,
                            decoration: InputDecoration(
                              labelText: 'Account name',
                              prefixIcon: Icon(Icons.account_box),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter an account name';
                              }
                              return null;
                            },
                          ),
                          if (!_editing)
                            TextFormField(
                              controller: balanceController,
                              decoration: InputDecoration(
                                labelText: "Initial balance",
                                helperText:
                                    "Negative if you owe it, e.g. a credit card",
                                prefixIcon: Icon(Icons.euro_sharp),
                              ),
                              // signed: shows a minus key on the number keyboard.
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                    signed: true,
                                  ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter an initial balance';
                                }
                                if (evaluateAmount(value) == null) {
                                  return 'Please enter a valid number';
                                }
                                return null;
                              },
                            ),
                          SizedBox(
                            width: double.infinity,
                            child: DropdownMenu(
                              expandedInsets: EdgeInsets.zero,
                              label: Text('Account type'),
                              initialSelection: accountType,
                              dropdownMenuEntries: AccountType.entries,
                              onSelected: (AccountType? type) {
                                setState(() {
                                  accountType = type;
                                });
                              },
                            ),
                          ),
                          if (_creditCard)
                            TextFormField(
                              controller: closingDayController,
                              decoration: const InputDecoration(
                                labelText: 'Closing day',
                                helperText:
                                    'Day of the month the bill closes; '
                                    'empty for the last day',
                                prefixIcon: Icon(Icons.event_outlined),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return null;
                                }
                                final day = int.tryParse(value);
                                if (day == null || day < 1 || day > 31) {
                                  return 'Please enter a day from 1 to 31';
                                }
                                return null;
                              },
                            ),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                minimumSize: Size.fromHeight(52),
                              ),
                              onPressed: _saving ? null : _save,
                              child: Text(_editing ? 'Save' : 'Add account'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 50),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
