import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:money_mind/components/drag_indicator.dart';
import 'package:money_mind/database/DatabaseService.dart';
import 'package:money_mind/database/models/AccountType.dart';
import 'package:money_mind/database/models/account.dart';
import 'package:money_mind/database/models/statement.dart';

class AccountForm extends StatefulWidget {
  const AccountForm({super.key});

  @override
  State<AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends State<AccountForm> {
  final _formKey = GlobalKey<FormState>();
  final accountNameController = TextEditingController();
  final balanceController = TextEditingController();
  final typeController = TextEditingController();
  DatabaseService databaseService = DatabaseService.instance;
  AccountType? accountType = AccountType.debit;

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    accountNameController.dispose();
    balanceController.dispose();
    typeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery
            .of(context)
            .viewInsets
            .bottom),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DragIndicator(),
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      'Add account',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 20),
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
                              border: OutlineInputBorder(),
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
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.euro_sharp),
                            ),
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.allow(
                                RegExp(
                                    r'([1-9]+\d*[.,]?\d{0,2})|(0[.,]?\d{0,2})'),
                              ),
                            ],
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter an initial balance';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: DropdownMenu(
                              controller: typeController,
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
                            child: ElevatedButton(
                              onPressed: () {
                                if (!_formKey.currentState!.validate()) {
                                  return;
                                }
                                Account newAccount = Account(
                                  name: accountNameController.text,
                                  type: accountType!,
                                );
                                databaseService.addAccount(newAccount);

                                Statement statement = Statement(
                                    createdAt: DateTime.timestamp(),
                                    title: "Initial Balance",
                                    paymentDate: DateTime.timestamp(),
                                    useDate: DateTime.timestamp(),
                                    amount: double.parse(
                                        balanceController.text),
                                    isExpense: false,
                                    tags: ["Auto-generated"]);
                                newAccount.statements.add(statement);
                                databaseService.addStatement(statement, newAccount);
                                Navigator.pop(context, newAccount);
                              },
                              child: Text('Add account'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 50,)
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
