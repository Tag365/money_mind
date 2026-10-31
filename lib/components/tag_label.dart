import 'package:flutter/material.dart';

/// Tag name on its color, full width when [expand] is set.
class TagLabel extends StatelessWidget {
  final String name;
  final Color color;
  final bool expand;

  const TagLabel(this.name, this.color, {super.key, this.expand = false});

  @override
  Widget build(BuildContext context) {
    // Dark text on light colors (yellow, cyan), white text otherwise.
    final textColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.light
        ? Colors.black
        : Colors.white;
    return Container(
      width: expand ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(name, style: TextStyle(color: textColor)),
    );
  }
}
