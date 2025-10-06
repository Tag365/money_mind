import 'dart:math';

import 'package:flutter/material.dart';
import 'package:money_mind/database/database_service.dart';

class AddWidget extends StatefulWidget {
  const AddWidget({super.key});

  @override
  State<AddWidget> createState() => _AddWidgetState();
}

class _AddWidgetState extends State<AddWidget> {
  DatabaseService databaseService = DatabaseService.instance;

  void addStatement() {
    Random rng = Random(0);
    databaseService.addStatement(
      "Test transfer",
      rng.nextDouble() * 10 * (rng.nextBool() ? 1 : -1),
      2,
      DateTime.timestamp(),
      DateTime.timestamp(),
      ["speedtest"],
      "",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Add Tab"),

            TextButton(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all<Color>(
                  Colors.blueAccent,
                ),
                fixedSize: WidgetStateProperty.all<Size>(Size(5, 5)),
              ),
              onPressed: addStatement,
              child: Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }
}
