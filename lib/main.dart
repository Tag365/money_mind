import 'package:flutter/material.dart';
import 'package:money_mind/TabNavigation.dart';
import 'package:flutter/rendering.dart';

void main() {
  debugPaintSizeEnabled = false;
  runApp(const MoneyMind());
}

class MoneyMind extends StatelessWidget {
  const MoneyMind({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Money Mind',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black26),
      ),
      home: TabNavigation(),
    );
  }
}
