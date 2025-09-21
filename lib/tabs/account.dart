import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fluttericon/iconic_icons.dart';

class AccountWidget extends StatefulWidget {
  const AccountWidget({super.key});

  @override
  State<AccountWidget> createState() => _AccountState();
}

class _AccountState extends State<AccountWidget> {
  int itemCount = 10;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _list(),
          Align(
            alignment: Alignment.bottomCenter,
            child: _actionBar(),
          ),
        ],
      ),
    );
  }

  Widget _list() {
    if (itemCount == 0) {
      return Center(
        child: Text("No accounts available.\nPlease add an account via bellow button."),
      );
    }
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: ((context, index) {
        return ListTile(
          leading: Icon(Icons.account_balance_wallet),
          title: Text("Account $index"),
          subtitle: Text("Balance: \$${(index + 1) * 100}"),
        );
      }),
    );
  }

  Widget _actionBar() {
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
                setState(() {
                  itemCount++;
                });
                print("Add account");
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
                setState(() {
                  itemCount = max(0, itemCount - 1);
                });
                print("Transfer");
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
}
