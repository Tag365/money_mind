import 'package:flutter/material.dart';

class AddWidget extends StatefulWidget {
  const AddWidget({super.key});

  @override
  State<AddWidget> createState() => _AddWidgetState();
}

class _AddWidgetState extends State<AddWidget> {
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
              onPressed: () {
                print("test");
              },
              child: Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }
}
