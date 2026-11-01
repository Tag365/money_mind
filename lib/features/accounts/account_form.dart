import 'package:flutter/material.dart';

import 'package:money_mind/common/amount_expression.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/database/models/account_type.dart';

class AccountForm extends StatefulWidget {
  const AccountForm({super.key});

  @override
  State<AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends State<AccountForm> {
  final _formKey = GlobalKey<FormState>();
  final accountNameController = TextEditingController();
  final balanceController = TextEditingController();
  DatabaseService databaseService = DatabaseService.instance;
  AccountType? accountType = AccountType.debit;
  // Set for good: the sheet closes after saving.
  bool _saving = false;

  void _addAccount() async {
    if (_saving || !_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    final double initialBalance = evaluateAmount(balanceController.text)!;
    int accountId = await databaseService.addAccount(
      accountNameController.text,
      accountType!,
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
                      'Add account',
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
                          TextFormField(
                            controller: balanceController,
                            decoration: InputDecoration(
                              labelText: "Initial balance",
                              helperText:
                                  "Negative if you owe it, e.g. a credit card",
                              prefixIcon: Icon(Icons.euro_sharp),
                            ),
                            // signed: shows a minus key on the number keyboard.
                            keyboardType: const TextInputType.numberWithOptions(
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
                              initialSelection: AccountType.debit,
                              dropdownMenuEntries: AccountType.entries,
                              onSelected: (AccountType? type) {
                                setState(() {
                                  accountType = type;
                                });
                              },
                            ),
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                minimumSize: Size.fromHeight(52),
                              ),
                              onPressed: _saving ? null : _addAccount,
                              child: Text('Add account'),
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
