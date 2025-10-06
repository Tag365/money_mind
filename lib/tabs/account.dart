import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:fluttericon/iconic_icons.dart';
import 'package:money_mind/database/database_service.dart';
import 'package:money_mind/database/models/AccountType.dart';
import 'package:money_mind/modals/account_form.dart';

import 'package:money_mind/database/app_database.dart';

class AccountWidget extends StatefulWidget {
  const AccountWidget({super.key});

  @override
  State<AccountWidget> createState() => _AccountState();
}

class _AccountState extends State<AccountWidget> {
  DatabaseService databaseService = DatabaseService.instance;

  void _openAddAccountModal() async {
    final result = await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) => const AccountForm(),
    );
    if (result == null || result is! Account) return;
  }

  Widget _list(List<Account> accounts) {
    if (accounts.isEmpty) {
      return Center(
        child: Text(
          "No accounts available.\nPlease add an account via bellow button.",
        ),
      );
    }
    return SlidableAutoCloseBehavior(
      child: ListView.builder(
        itemCount: accounts.length,
        itemBuilder: ((context, index) {
          final Account account = accounts[index];
          return Slidable(
            groupTag: "0",
            endActionPane: ActionPane(
              motion: ScrollMotion(),
              extentRatio: 0.25,
              children: [
                SlidableAction(
                  onPressed: ((_) {
                    setState(() {
                      databaseService.deleteAccount(accounts[index]);
                      accounts.removeAt(index);
                    });
                  }),
                  backgroundColor: Colors.red,
                  icon: Icons.delete,
                  label: "Delete",
                ),
              ],
            ),
            child: ListTile(
              leading: Icon(
                account.type == AccountType.creditCard
                    ? Icons.credit_card
                    : Icons.wallet,
              ),
              title: Text(account.name),
              subtitle: Text(
                "Balance: ${account.balance.toStringAsFixed(2)}€",
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _actionBar(List<Account> accounts) {
    return Container(
      height: 60,
      width: MediaQuery.of(context).size.width * 0.8,
      decoration: BoxDecoration(
        color: Colors.blueGrey,
        borderRadius: BorderRadius.all(Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            blurStyle: BlurStyle.outer,
          ),
        ],
      ),
      margin: EdgeInsets.only(bottom: 30, left: 20, right: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: IconButton(
              onPressed: () {
                print("Add account");
                _openAddAccountModal();
              },
              icon: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: Colors.white),
                  Text(
                    "Add",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

          VerticalDivider(
            color: Colors.white,
            thickness: 2,
            indent: 3,
            endIndent: 3,
            radius: BorderRadiusGeometry.all(Radius.circular(20)),
          ),

          Expanded(
            child: IconButton(
              onPressed: () {
                print("Transfer");
                Random rng = Random(0);
                for (int i = 0; i < 10_000; i++) {
                  Account account = accounts[0];
                  databaseService.addStatement(
                    "Speedtest transfer $i",
                    rng.nextDouble() * 10 * (rng.nextBool() ? 1 : -1),
                    account.id,
                    DateTime.timestamp(),
                    DateTime.timestamp(),
                    ["speedtest"],
                    "",
                  );
                }
              },
              icon: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconic.exchange, color: Colors.white),
                  Text(
                    "Transfer",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: databaseService.getAccounts(),
        builder: (context, asyncSnapshot) {
          if (!asyncSnapshot.hasData) {
            // Show a placeholder while loading
            return Center(child: CircularProgressIndicator());
          }
          if (asyncSnapshot.hasError) {
            return Center(child: Text('Error: ${asyncSnapshot.error}'));
          }
          return Stack(
            children: [
              _list(asyncSnapshot.data!),
              Align(
                alignment: Alignment.bottomCenter,
                child: _actionBar(asyncSnapshot.data!),
              ),
            ],
          );
        },
      ),
    );
  }
}
